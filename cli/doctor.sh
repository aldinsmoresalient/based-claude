#!/usr/bin/env bash
#
# Based Claude v2 - Doctor Command
# Validates installation and checks for drift
#

doctor_help() {
    cat <<EOF
based-claude doctor - Validate installation and check health

USAGE:
    based-claude doctor [options]

OPTIONS:
    --verbose       Show detailed output
    -h, --help      Show this help

CHECKS:
    1. CLAUDE.md exists and has been annotated
    2. .claude/skills/ directory with valid skills
    3. @claude headers found in codebase
    4. USED_BY present in headers (blast radius tracking)
    5. No obvious drift (deleted files still referenced)

EOF
}

cmd_doctor() {
    local verbose=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                doctor_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                doctor_help
                return 1
                ;;
        esac
    done

    local project_root
    project_root=$(get_project_root)

    header "Based Claude Health Check"
    echo ""
    echo "Project: $project_root"
    echo ""

    local issues=0
    local warnings=0

    # Check 1: CLAUDE.md exists
    step 1 "Checking CLAUDE.md..."
    if [[ -f "$project_root/CLAUDE.md" ]]; then
        success "  CLAUDE.md exists"

        # Check if annotated
        if grep -q "not-yet-annotated" "$project_root/CLAUDE.md"; then
            warn "  Not yet annotated"
            echo "  → Tell Claude: 'annotate this codebase'"
            warnings=$((warnings + 1))
        else
            local files_annotated
            files_annotated=$(grep "^FILES_ANNOTATED:" "$project_root/CLAUDE.md" 2>/dev/null | awk '{print $2}' || echo "?")
            local skills_generated
            skills_generated=$(grep "^SKILLS_GENERATED:" "$project_root/CLAUDE.md" 2>/dev/null | awk '{print $2}' || echo "?")
            success "  Annotated: $files_annotated files, $skills_generated skills"

            if $verbose; then
                local commit
                commit=$(grep "^COMMIT:" "$project_root/CLAUDE.md" 2>/dev/null | awk '{print $2}' || echo "unknown")
                local built
                built=$(grep "^BUILT:" "$project_root/CLAUDE.md" 2>/dev/null | cut -d' ' -f2- || echo "unknown")
                echo "    Commit: $commit"
                echo "    Built: $built"
            fi
        fi
    else
        error "  CLAUDE.md not found"
        echo "  → Run: based-claude init"
        issues=$((issues + 1))
    fi

    # Check 2: .claude/skills/ directory
    step 2 "Checking generated skills..."
    local skills_dir="$project_root/.claude/skills"
    if [[ -d "$skills_dir" ]]; then
        local valid_skills=0
        local invalid_skills=0

        _doctor_check_skill() {
            local _dir="$1"
            local _file="$2"
            local _name="$3"

            if validate_skill_file "$_file"; then
                valid_skills=$((valid_skills + 1))
                if $verbose; then
                    local name
                    name=$(read_skill_field "$_file" "name")
                    echo "    ✓ $_name (name: $name)"
                fi
            else
                invalid_skills=$((invalid_skills + 1))
                warn "    Invalid: $_name (missing frontmatter or name/description)"
            fi
        }

        for_each_skill "$skills_dir" _doctor_check_skill

        local total_skills=$((valid_skills + invalid_skills))
        if [[ $total_skills -gt 0 ]]; then
            success "  Found $total_skills skill(s) ($valid_skills valid)"
            if [[ $invalid_skills -gt 0 ]]; then
                warn "  $invalid_skills invalid skill(s)"
                warnings=$((warnings + 1))
            fi

            # Check skill references (files mentioned in skill bodies)
            if $verbose; then
                for dir in "$skills_dir"/*/; do
                    [[ -d "$dir" ]] || continue
                    local refs_dir="$dir/references"
                    if [[ -d "$refs_dir" ]]; then
                        local missing_refs=0
                        for ref_file in "$refs_dir"/*; do
                            [[ -e "$ref_file" ]] || continue
                            if [[ ! -s "$ref_file" ]]; then
                                warn "    Empty reference: $ref_file"
                                missing_refs=$((missing_refs + 1))
                            fi
                        done
                        if [[ $missing_refs -gt 0 ]]; then
                            warnings=$((warnings + 1))
                        fi
                    fi
                done
            fi
        else
            warn "  No skills generated yet"
            echo "  → Skills are created during annotation"
            warnings=$((warnings + 1))
        fi
    else
        warn "  .claude/skills/ not found"
        echo "  → Run: based-claude init"
        warnings=$((warnings + 1))
    fi

    # Check 3: @claude headers in codebase
    step 3 "Checking @claude headers..."

    # Find source files, excluding common directories
    local header_files
    header_files=$(grep -rl "@claude" "$project_root" \
        --include="*.ts" --include="*.tsx" \
        --include="*.js" --include="*.jsx" \
        --include="*.py" \
        --include="*.go" \
        --include="*.rs" \
        --include="*.java" \
        --include="*.rb" \
        2>/dev/null | grep -v node_modules | grep -v dist | grep -v __pycache__ | grep -v ".git" || true)

    local header_count=0
    if [[ -n "$header_files" ]]; then
        header_count=$(echo "$header_files" | wc -l | tr -d ' ')
    fi

    if [[ "$header_count" -gt 0 ]]; then
        success "  Found $header_count file(s) with @claude headers"

        if $verbose; then
            echo "$header_files" | while read -r f; do
                echo "    $f"
            done | head -10
            if [[ $header_count -gt 10 ]]; then
                echo "    ... and $((header_count - 10)) more"
            fi
        fi

        # Check for USED_BY (the key feature)
        local used_by_count=0
        if [[ -n "$header_files" ]]; then
            used_by_count=$(echo "$header_files" | xargs grep -l "USED_BY:" 2>/dev/null | wc -l | tr -d ' ')
        fi

        if [[ "$used_by_count" -gt 0 ]]; then
            success "  $used_by_count header(s) have USED_BY (blast radius)"
        else
            warn "  No USED_BY found in headers"
            echo "  → USED_BY tracks what depends on each file"
            echo "  → Re-run annotation to add blast radius info"
            warnings=$((warnings + 1))
        fi
    else
        warn "  No @claude headers found"
        echo "  → Headers are added during annotation"
        warnings=$((warnings + 1))
    fi

    # Check 4: Drift detection
    step 4 "Checking for drift..."
    if [[ -f "$project_root/CLAUDE.md" ]]; then
        local drift_found=false

        # Check if referenced source files still exist
        local referenced_paths
        referenced_paths=$(grep -oE '`(src|app|lib)/[^`]+\.(ts|js|py|go|rs)`' "$project_root/CLAUDE.md" 2>/dev/null | tr -d '`' | sort -u || true)

        if [[ -n "$referenced_paths" ]]; then
            local missing_count=0
            while IFS= read -r ref_path; do
                if [[ -n "$ref_path" ]] && [[ ! -e "$project_root/$ref_path" ]]; then
                    if $verbose; then
                        warn "    Missing: $ref_path"
                    fi
                    missing_count=$((missing_count + 1))
                    drift_found=true
                fi
            done <<< "$referenced_paths"

            if $drift_found; then
                warn "  $missing_count referenced file(s) no longer exist"
                echo "  → Tell Claude: 'refresh the atlas'"
                warnings=$((warnings + 1))
            else
                success "  No drift detected"
            fi
        else
            success "  No source files referenced (or not yet annotated)"
        fi

        # Check if current git commit differs from annotation commit
        if command -v git &>/dev/null && [[ -d "$project_root/.git" ]]; then
            local annotated_commit
            annotated_commit=$(grep "^COMMIT:" "$project_root/CLAUDE.md" 2>/dev/null | awk '{print $2}' || echo "unknown")
            local current_commit
            current_commit=$(git -C "$project_root" rev-parse --short HEAD 2>/dev/null || echo "unknown")

            if [[ "$annotated_commit" != "unknown" ]] && [[ "$current_commit" != "unknown" ]]; then
                if [[ "$annotated_commit" != "$current_commit" ]]; then
                    local commits_behind
                    commits_behind=$(git -C "$project_root" rev-list "$annotated_commit".."$current_commit" --count 2>/dev/null || echo "?")
                    warn "  $commits_behind commit(s) since last annotation"
                    if $verbose; then
                        echo "    Annotated at: $annotated_commit"
                        echo "    Current: $current_commit"
                    fi
                else
                    success "  At annotated commit"
                fi
            fi
        fi
    fi

    # Check 5: System dependencies
    step 5 "Checking dependencies..."
    echo -n "  git: "
    if command -v git &>/dev/null; then
        success "$(git --version | head -1 | cut -d' ' -f3)"
    else
        warn "not found"
    fi

    echo -n "  grep: "
    if command -v grep &>/dev/null; then
        success "available"
    else
        error "not found (required)"
        issues=$((issues + 1))
    fi

    # Summary
    echo ""
    echo "─────────────────────────────────────"
    if [[ $issues -eq 0 ]] && [[ $warnings -eq 0 ]]; then
        success "All checks passed!"
        echo ""
        echo "Your codebase is ready for context-anchored work."
    elif [[ $issues -eq 0 ]]; then
        warn "$warnings warning(s)"
        echo ""
        echo "Based Claude is functional but could be improved."
    else
        error "$issues issue(s), $warnings warning(s)"
        echo ""
        echo "Run 'based-claude init' to set up."
        return 1
    fi
}
