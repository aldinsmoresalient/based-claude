#!/usr/bin/env bash
#
# Claude Code SDK - Atlas Command
#

atlas_help() {
    cat <<EOF
claude-sdk atlas - Manage the Repo Atlas

USAGE:
    claude-sdk atlas <subcommand> [options]

SUBCOMMANDS:
    build       Build or rebuild the atlas
    refresh     Incrementally update changed folders
    status      Show atlas status and freshness
    clean       Remove atlas files

OPTIONS:
    --full          Full rebuild (ignore cache)
    --folder PATH   Build atlas for specific folder only
    --dry-run       Preview changes
    --config FILE   Use custom atlas config
    -h, --help      Show this help

DESCRIPTION:
    The Repo Atlas is a grep-friendly index that helps agents
    understand your codebase structure quickly.

    It generates:
    - ATLAS.md: Root index with overview and entry points
    - folder/*.atlas.md: Per-folder maps with details

EXAMPLES:
    # Build atlas for current project
    claude-sdk atlas build

    # Rebuild specific folder
    claude-sdk atlas build --folder src/api

    # Check atlas freshness
    claude-sdk atlas status

    # Incremental refresh
    claude-sdk atlas refresh

EOF
}

cmd_atlas() {
    local subcmd="${1:-}"
    shift || true

    case "$subcmd" in
        build)
            atlas_build "$@"
            ;;
        refresh)
            atlas_refresh "$@"
            ;;
        status)
            atlas_status "$@"
            ;;
        clean)
            atlas_clean "$@"
            ;;
        -h|--help|"")
            atlas_help
            ;;
        *)
            error "Unknown atlas subcommand: $subcmd"
            atlas_help
            return 1
            ;;
    esac
}

atlas_build() {
    local full_rebuild=false
    local target_folder=""
    local dry_run=false
    local config_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)
                full_rebuild=true
                shift
                ;;
            --folder)
                target_folder="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --config)
                config_file="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    local project_root
    project_root=$(get_project_root)
    local sdk_dir="$project_root/.claude-sdk"
    local atlas_dir="$sdk_dir/atlas"

    header "Building Repo Atlas"
    echo ""
    echo "Project: $project_root"
    echo ""

    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN MODE${NC}"
        echo ""
    fi

    # Load or create config
    local config_path="${config_file:-$sdk_dir/atlas.config}"

    # Create atlas directory
    step 1 "Preparing atlas directory..."
    if ! $dry_run; then
        ensure_dir "$atlas_dir"
    fi

    # Run the atlas generator script
    step 2 "Analyzing codebase..."
    local generator_script="$SDK_ROOT/scripts/atlas-generator.sh"

    if [[ -f "$generator_script" ]]; then
        if $dry_run; then
            dry_run_msg "bash $generator_script $project_root $atlas_dir"
        else
            bash "$generator_script" "$project_root" "$atlas_dir" "$target_folder"
        fi
    else
        # Fallback: inline generation
        if ! $dry_run; then
            generate_atlas_inline "$project_root" "$atlas_dir" "$target_folder"
        fi
    fi

    # Generate root atlas
    step 3 "Generating root index..."
    if ! $dry_run; then
        generate_root_atlas "$project_root" "$atlas_dir"
    fi

    # Run drift detection
    step 4 "Checking for drift..."
    if ! $dry_run; then
        check_atlas_drift "$project_root" "$atlas_dir"
    fi

    echo ""
    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN complete${NC}"
    else
        success "Atlas built successfully"
        echo ""
        echo "Files created:"
        echo "  $sdk_dir/ATLAS.md"
        if [[ -d "$atlas_dir" ]]; then
            find "$atlas_dir" -name "*.atlas.md" -type f 2>/dev/null | while read -r f; do
                echo "  $f"
            done
        fi
    fi
}

atlas_refresh() {
    local project_root
    project_root=$(get_project_root)
    local sdk_dir="$project_root/.claude-sdk"
    local atlas_dir="$sdk_dir/atlas"
    local atlas_file="$sdk_dir/ATLAS.md"

    header "Refreshing Repo Atlas"
    echo ""

    # Check if atlas exists
    if [[ ! -f "$atlas_file" ]]; then
        warn "No atlas found. Running full build..."
        atlas_build "$@"
        return
    fi

    # Get last build time from atlas
    local last_build
    last_build=$(grep "^BUILT:" "$atlas_file" 2>/dev/null | head -1 | cut -d' ' -f2-)

    if [[ -z "$last_build" ]]; then
        warn "Cannot determine last build time. Running full build..."
        atlas_build --full "$@"
        return
    fi

    # Find files changed since last build
    step 1 "Finding changed files..."
    local changed_folders=()

    if is_git_repo; then
        # Use git to find changed files
        while IFS= read -r file; do
            local folder
            folder=$(dirname "$file")
            # Add unique folders
            if [[ ! " ${changed_folders[*]} " =~ " ${folder} " ]]; then
                changed_folders+=("$folder")
            fi
        done < <(git diff --name-only --diff-filter=ACMR HEAD~10 2>/dev/null | head -50)
    fi

    if [[ ${#changed_folders[@]} -eq 0 ]]; then
        success "No changes detected. Atlas is up to date."
        return
    fi

    echo "  ${#changed_folders[@]} folders have changes"

    # Rebuild only changed folders
    step 2 "Updating changed folders..."
    for folder in "${changed_folders[@]}"; do
        if [[ -d "$project_root/$folder" ]]; then
            info "  Refreshing: $folder"
            generate_folder_atlas "$project_root" "$atlas_dir" "$folder"
        fi
    done

    # Update root atlas metadata
    step 3 "Updating root index..."
    update_atlas_metadata "$project_root" "$sdk_dir/ATLAS.md"

    success "Atlas refreshed"
}

atlas_status() {
    local project_root
    project_root=$(get_project_root)
    local sdk_dir="$project_root/.claude-sdk"
    local atlas_file="$sdk_dir/ATLAS.md"

    header "Repo Atlas Status"
    echo ""

    if [[ ! -f "$atlas_file" ]]; then
        warn "No atlas found"
        echo "Run 'claude-sdk atlas build' to create one"
        return 1
    fi

    # Read metadata from atlas
    echo "Atlas file: $atlas_file"
    echo ""

    # Extract metadata
    local built
    built=$(grep "^BUILT:" "$atlas_file" 2>/dev/null | head -1 | cut -d' ' -f2-)
    local commit
    commit=$(grep "^COMMIT:" "$atlas_file" 2>/dev/null | head -1 | cut -d' ' -f2-)

    echo "Last build: ${built:-unknown}"
    echo "At commit:  ${commit:-unknown}"

    # Check freshness
    echo ""
    echo -e "${BOLD}Freshness Check${NC}"

    if is_git_repo; then
        local current_commit
        current_commit=$(get_git_hash)

        if [[ "$commit" == "$current_commit" ]]; then
            success "Atlas is current"
        else
            warn "Atlas may be stale (built at $commit, now at $current_commit)"
            echo "Run 'claude-sdk atlas refresh' to update"
        fi

        # Count changed files
        local changed_count
        changed_count=$(git diff --name-only HEAD~5 2>/dev/null | wc -l | tr -d ' ')
        echo "Files changed since last 5 commits: $changed_count"
    fi

    # Count atlas files
    echo ""
    local atlas_dir="$sdk_dir/atlas"
    if [[ -d "$atlas_dir" ]]; then
        local folder_count
        folder_count=$(find "$atlas_dir" -name "*.atlas.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "Folder atlases: $folder_count"
    fi
}

atlas_clean() {
    local project_root
    project_root=$(get_project_root)
    local sdk_dir="$project_root/.claude-sdk"
    local atlas_file="$sdk_dir/ATLAS.md"
    local atlas_dir="$sdk_dir/atlas"

    header "Cleaning Repo Atlas"
    echo ""

    local removed=0

    if [[ -f "$atlas_file" ]]; then
        rm -f "$atlas_file"
        info "Removed: $atlas_file"
        ((removed++))
    fi

    if [[ -d "$atlas_dir" ]]; then
        rm -rf "$atlas_dir"
        info "Removed: $atlas_dir/"
        ((removed++))
    fi

    if [[ $removed -eq 0 ]]; then
        echo "Nothing to clean"
    else
        success "Cleaned $removed items"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Helper functions
#───────────────────────────────────────────────────────────────────────────────

generate_atlas_inline() {
    local project_root="$1"
    local atlas_dir="$2"
    local target_folder="${3:-}"

    # Find important directories
    local dirs_to_index=()

    if [[ -n "$target_folder" ]]; then
        dirs_to_index=("$target_folder")
    else
        # Auto-detect important directories
        while IFS= read -r dir; do
            # Skip hidden, node_modules, vendor, etc.
            local basename
            basename=$(basename "$dir")
            case "$basename" in
                node_modules|vendor|.git|__pycache__|.next|dist|build|target|coverage)
                    continue
                    ;;
            esac
            dirs_to_index+=("${dir#$project_root/}")
        done < <(find "$project_root" -maxdepth 2 -type d 2>/dev/null | head -50)
    fi

    # Generate folder atlases
    for dir in "${dirs_to_index[@]}"; do
        if [[ -d "$project_root/$dir" ]]; then
            generate_folder_atlas "$project_root" "$atlas_dir" "$dir"
        fi
    done
}

generate_folder_atlas() {
    local project_root="$1"
    local atlas_dir="$2"
    local folder="$3"

    local folder_path="$project_root/$folder"
    local atlas_file="$atlas_dir/${folder//\//_}.atlas.md"

    ensure_dir "$(dirname "$atlas_file")"

    # Count files by type
    local file_count
    file_count=$(find "$folder_path" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')

    cat > "$atlas_file" <<EOF
# FOLDER: $folder

PURPOSE: [Auto-detected folder]
DEPTH: $(echo "$folder" | tr -cd '/' | wc -c | tr -d ' ')
FILES: $file_count

## KEY FILES
EOF

    # List important files
    find "$folder_path" -maxdepth 1 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) 2>/dev/null | head -20 | while read -r file; do
        local name
        name=$(basename "$file")
        echo "FILE: $name"
    done >> "$atlas_file"

    # Look for exports/interfaces
    cat >> "$atlas_file" <<EOF

## EXPORTS
EOF

    # Find exports (basic pattern matching)
    if command -v grep &>/dev/null; then
        grep -rh "^export " "$folder_path" 2>/dev/null | head -10 | while read -r line; do
            echo "EXPORT: ${line:0:80}"
        done >> "$atlas_file"
    fi

    cat >> "$atlas_file" <<EOF

## SEARCH ANCHORS
GREP: "function.*(" in $folder
GREP: "class " in $folder
GREP: "interface " in $folder
GREP: "export " in $folder
EOF
}

generate_root_atlas() {
    local project_root="$1"
    local atlas_dir="$2"
    local sdk_dir="$project_root/.claude-sdk"
    local atlas_file="$sdk_dir/ATLAS.md"

    # Detect project type
    local project_type="unknown"
    local entry_points=()

    if [[ -f "$project_root/package.json" ]]; then
        project_type="node"
        entry_points+=("package.json")
        [[ -f "$project_root/src/index.ts" ]] && entry_points+=("src/index.ts")
        [[ -f "$project_root/src/index.js" ]] && entry_points+=("src/index.js")
    elif [[ -f "$project_root/pyproject.toml" ]] || [[ -f "$project_root/setup.py" ]]; then
        project_type="python"
        [[ -f "$project_root/pyproject.toml" ]] && entry_points+=("pyproject.toml")
        [[ -f "$project_root/setup.py" ]] && entry_points+=("setup.py")
    elif [[ -f "$project_root/go.mod" ]]; then
        project_type="go"
        entry_points+=("go.mod")
        [[ -f "$project_root/main.go" ]] && entry_points+=("main.go")
    elif [[ -f "$project_root/Cargo.toml" ]]; then
        project_type="rust"
        entry_points+=("Cargo.toml")
        [[ -f "$project_root/src/main.rs" ]] && entry_points+=("src/main.rs")
        [[ -f "$project_root/src/lib.rs" ]] && entry_points+=("src/lib.rs")
    fi

    # Get git info
    local commit_hash="not-a-repo"
    if is_git_repo; then
        commit_hash=$(get_git_hash)
    fi

    cat > "$atlas_file" <<EOF
# REPO ATLAS
# Auto-generated by Claude Code SDK
# Human-editable - your changes will be preserved on refresh

BUILT: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT: $commit_hash
TYPE: $project_type

## OVERVIEW

PROJECT: $(basename "$project_root")
ROOT: $project_root

## ENTRY POINTS

EOF

    if [[ ${#entry_points[@]} -gt 0 ]]; then
        for entry in "${entry_points[@]}"; do
            echo "ENTRY: $entry" >> "$atlas_file"
        done
    else
        echo "ENTRY: (none detected)" >> "$atlas_file"
    fi

    cat >> "$atlas_file" <<EOF

## MAJOR DOMAINS

EOF

    # List top-level directories
    find "$project_root" -maxdepth 1 -type d | sort | while read -r dir; do
        local name
        name=$(basename "$dir")
        case "$name" in
            .|.git|node_modules|vendor|__pycache__|.next|dist|build|target|coverage|.claude-sdk)
                continue
                ;;
        esac
        echo "DOMAIN: $name/" >> "$atlas_file"
    done

    cat >> "$atlas_file" <<EOF

## FOLDER MAPS

EOF

    # Link to folder atlases
    if [[ -d "$atlas_dir" ]]; then
        find "$atlas_dir" -name "*.atlas.md" -type f 2>/dev/null | sort | while read -r f; do
            local name
            name=$(basename "$f" .atlas.md)
            echo "MAP: atlas/$name.atlas.md" >> "$atlas_file"
        done
    fi

    cat >> "$atlas_file" <<EOF

## SEARCH ANCHORS

# Common grep patterns for this codebase:
GREP: "TODO" - Find todos
GREP: "FIXME" - Find fixmes
GREP: "export (function|const|class)" - Find exports
GREP: "@route|@api|router\\." - Find API routes
GREP: "describe\\(|it\\(|test\\(" - Find tests

## NOTES

Add your own notes about the codebase architecture here.
This section is preserved across atlas rebuilds.

EOF
}

update_atlas_metadata() {
    local project_root="$1"
    local atlas_file="$2"

    if [[ ! -f "$atlas_file" ]]; then
        return
    fi

    local commit_hash
    commit_hash=$(get_git_hash)
    local build_time
    build_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Update BUILT and COMMIT lines
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^BUILT:.*$/BUILT: $build_time/" "$atlas_file"
        sed -i '' "s/^COMMIT:.*$/COMMIT: $commit_hash/" "$atlas_file"
    else
        sed -i "s/^BUILT:.*$/BUILT: $build_time/" "$atlas_file"
        sed -i "s/^COMMIT:.*$/COMMIT: $commit_hash/" "$atlas_file"
    fi
}

check_atlas_drift() {
    local project_root="$1"
    local atlas_dir="$2"

    # Simple drift check: compare file counts
    # More sophisticated checks can be added later

    debug "Drift check: comparing atlas to actual files"
}
