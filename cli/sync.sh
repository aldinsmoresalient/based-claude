#!/usr/bin/env bash
#
# Based Claude v2 - Sync Command
# Installs skills from a team skillfile (.claude-skills.json)
#

SKILLFILE_NAME=".claude-skills.json"

sync_help() {
    cat <<EOF
based-claude sync - Install skills from team skillfile

USAGE:
    based-claude sync [options]

OPTIONS:
    --dry-run       Preview changes without installing
    -h, --help      Show this help

DESCRIPTION:
    Reads $SKILLFILE_NAME from the project root and installs
    any listed skills into .claude/skills/.

    Team members commit $SKILLFILE_NAME to the repo so
    everyone stays in sync.

SKILLFILE FORMAT:
    {
      "skills": [
        { "name": "modify-auth", "path": "./team-skills/modify-auth" },
        { "name": "modify-db",   "url": "https://github.com/org/skills.git#modify-db" }
      ]
    }

    Supported sources:
      path  - Local directory (relative to project root)
      url   - Git repository URL (cloned, with optional #subdirectory)

EXAMPLES:
    based-claude sync
    based-claude sync --dry-run

SEE ALSO:
    based-claude sync init   Create a starter $SKILLFILE_NAME

EOF
}

cmd_sync() {
    local dry_run=false
    local subcmd=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            init)
                subcmd="init"
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                sync_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                sync_help
                return 1
                ;;
        esac
    done

    local project_root
    project_root=$(get_project_root)

    if [[ "$subcmd" == "init" ]]; then
        _sync_init "$project_root" "$dry_run"
        return $?
    fi

    _sync_install "$project_root" "$dry_run"
}

_sync_init() {
    local project_root="$1"
    local dry_run="$2"
    local skillfile="$project_root/$SKILLFILE_NAME"

    if [[ -f "$skillfile" ]]; then
        warn "$SKILLFILE_NAME already exists"
        return 1
    fi

    if $dry_run; then
        dry_run_msg "Would create $skillfile"
        return 0
    fi

    cat > "$skillfile" << 'EOF'
{
  "skills": [
  ]
}
EOF

    success "Created $SKILLFILE_NAME"
    echo ""
    echo "Add skills to the list, then run 'based-claude sync' to install them."
    echo "Commit $SKILLFILE_NAME to your repo so teammates can sync too."
}

_sync_install() {
    local project_root="$1"
    local dry_run="$2"
    local skillfile="$project_root/$SKILLFILE_NAME"
    local skills_dir="$project_root/.claude/skills"

    if [[ ! -f "$skillfile" ]]; then
        warn "$SKILLFILE_NAME not found in $project_root"
        echo ""
        echo "Create one with: based-claude sync init"
        return 1
    fi

    header "Syncing Team Skills"
    echo ""

    # Parse skillfile - works with or without jq
    if command -v jq &>/dev/null; then
        _sync_with_jq "$skillfile" "$skills_dir" "$project_root" "$dry_run"
    else
        error "jq is required for sync (install with: brew install jq / apt install jq)"
        return 1
    fi
}

_sync_with_jq() {
    local skillfile="$1"
    local skills_dir="$2"
    local project_root="$3"
    local dry_run="$4"

    local skill_count
    skill_count=$(jq '.skills | length' "$skillfile" 2>/dev/null)

    if [[ -z "$skill_count" ]] || [[ "$skill_count" == "null" ]] || [[ "$skill_count" -eq 0 ]]; then
        info "No skills listed in $SKILLFILE_NAME"
        echo "Add entries to the \"skills\" array and run sync again."
        return 0
    fi

    local installed=0
    local skipped=0
    local failed=0

    for i in $(seq 0 $((skill_count - 1))); do
        local name path url
        name=$(jq -r ".skills[$i].name" "$skillfile")
        path=$(jq -r ".skills[$i].path // empty" "$skillfile")
        url=$(jq -r ".skills[$i].url // empty" "$skillfile")

        if [[ -z "$name" ]] || [[ "$name" == "null" ]]; then
            warn "Skill at index $i has no name, skipping"
            failed=$((failed + 1))
            continue
        fi

        local dest="$skills_dir/$name"

        # Skip if already installed
        if [[ -d "$dest" ]] && [[ -f "$dest/SKILL.md" ]]; then
            if $dry_run; then
                dry_run_msg "Skip $name (already installed)"
            else
                debug "Skip $name (already installed)"
            fi
            skipped=$((skipped + 1))
            continue
        fi

        if [[ -n "$path" ]]; then
            _sync_from_path "$name" "$path" "$dest" "$project_root" "$dry_run" && installed=$((installed + 1)) || failed=$((failed + 1))
        elif [[ -n "$url" ]]; then
            _sync_from_url "$name" "$url" "$dest" "$dry_run" && installed=$((installed + 1)) || failed=$((failed + 1))
        else
            warn "Skill '$name' has no path or url, skipping"
            failed=$((failed + 1))
        fi
    done

    echo ""
    echo "─────────────────────────────────────"
    if $dry_run; then
        echo "Dry run: would install $installed, skip $skipped, fail $failed"
    else
        success "Installed: $installed  Skipped: $skipped  Failed: $failed"
    fi
}

_sync_from_path() {
    local name="$1"
    local path="$2"
    local dest="$3"
    local project_root="$4"
    local dry_run="$5"

    # Resolve relative paths from project root
    local src
    if [[ "$path" == /* ]]; then
        src="$path"
    else
        src="$project_root/$path"
    fi

    if [[ ! -d "$src" ]]; then
        # Try as a directory containing SKILL.md
        if [[ -f "$src/SKILL.md" ]]; then
            src="$src"
        else
            warn "  $name: source not found at $src"
            return 1
        fi
    fi

    if [[ ! -f "$src/SKILL.md" ]]; then
        warn "  $name: no SKILL.md in $src"
        return 1
    fi

    if $dry_run; then
        dry_run_msg "Install $name from $path"
        return 0
    fi

    ensure_dir "$dest"
    cp -r "$src/"* "$dest/"
    success "  Installed $name (from $path)"
}

_sync_from_url() {
    local name="$1"
    local url="$2"
    local dest="$3"
    local dry_run="$4"

    # Parse git URL with optional #subdirectory
    local repo_url="$url"
    local subdir=""
    if [[ "$url" == *"#"* ]]; then
        repo_url="${url%%#*}"
        subdir="${url#*#}"
    fi

    if $dry_run; then
        dry_run_msg "Install $name from $repo_url (subdir: ${subdir:-root})"
        return 0
    fi

    if ! command -v git &>/dev/null; then
        warn "  $name: git required for URL sources"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" RETURN

    if ! git clone --quiet --depth 1 "$repo_url" "$tmp_dir/repo" 2>/dev/null; then
        warn "  $name: failed to clone $repo_url"
        return 1
    fi

    local src="$tmp_dir/repo"
    if [[ -n "$subdir" ]]; then
        src="$src/$subdir"
    fi

    if [[ ! -f "$src/SKILL.md" ]]; then
        warn "  $name: no SKILL.md found in cloned repo${subdir:+ at $subdir}"
        return 1
    fi

    ensure_dir "$dest"
    cp -r "$src/"* "$dest/"
    success "  Installed $name (from $repo_url)"
}
