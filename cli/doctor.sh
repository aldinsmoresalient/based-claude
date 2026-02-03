#!/usr/bin/env bash
#
# Claude Code SDK - Doctor Command (validation/health check)
#

doctor_help() {
    cat <<EOF
claude-sdk doctor - Validate installation and configuration

USAGE:
    claude-sdk doctor [options]

OPTIONS:
    --global        Check global installation
    --project       Check project installation
    --verbose       Show detailed check results
    -h, --help      Show this help

DESCRIPTION:
    Validates the SDK installation by checking:
    - Directory structure
    - Required files
    - Skill configurations
    - Subagent configurations
    - Template availability
    - Atlas status (if initialized)

EXAMPLES:
    # Check global installation
    claude-sdk doctor --global

    # Check project installation
    claude-sdk doctor --project

    # Verbose output
    claude-sdk doctor --project --verbose

EOF
}

cmd_doctor() {
    local check_type=""
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --global)
                check_type="global"
                shift
                ;;
            --project)
                check_type="project"
                shift
                ;;
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

    # Default to checking both if none specified
    if [[ -z "$check_type" ]]; then
        check_type="both"
    fi

    header "Claude Code SDK Health Check"
    echo ""

    local total_checks=0
    local passed_checks=0
    local warnings=0

    # Check global installation
    if [[ "$check_type" == "global" || "$check_type" == "both" ]]; then
        echo -e "${BOLD}Global Installation${NC}"
        check_installation "global" "$CLAUDE_HOME" $verbose
        local result=$?
        if [[ $result -eq 0 ]]; then
            ((passed_checks++))
        elif [[ $result -eq 2 ]]; then
            ((warnings++))
        fi
        ((total_checks++))
        echo ""
    fi

    # Check project installation
    if [[ "$check_type" == "project" || "$check_type" == "both" ]]; then
        local project_path
        project_path="$(get_project_sdk_dir)"

        echo -e "${BOLD}Project Installation${NC}"
        check_installation "project" "$project_path" $verbose
        local result=$?
        if [[ $result -eq 0 ]]; then
            ((passed_checks++))
        elif [[ $result -eq 2 ]]; then
            ((warnings++))
        fi
        ((total_checks++))
        echo ""
    fi

    # Check system dependencies
    echo -e "${BOLD}System Dependencies${NC}"
    check_dependencies $verbose

    # Check memory files (project only)
    if [[ "$check_type" == "project" || "$check_type" == "both" ]]; then
        echo ""
        echo -e "${BOLD}Memory Files${NC}"
        check_memory_files $verbose
    fi

    # Summary
    echo ""
    header "Summary"
    echo ""
    if [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}$warnings warnings found${NC}"
    fi

    if [[ $passed_checks -eq $total_checks ]] && [[ $warnings -eq 0 ]]; then
        echo -e "${GREEN}All checks passed!${NC}"
        return 0
    elif [[ $passed_checks -gt 0 ]]; then
        echo -e "${YELLOW}Some checks passed with warnings${NC}"
        return 0
    else
        echo -e "${RED}Some checks failed${NC}"
        return 1
    fi
}

# Check a specific installation
# Returns: 0=pass, 1=fail, 2=warning
check_installation() {
    local install_type="$1"
    local target_path="$2"
    local verbose="$3"

    local manifest_path
    if [[ "$install_type" == "global" ]]; then
        manifest_path="$CLAUDE_HOME/.sdk-manifest.json"
    else
        manifest_path="$target_path/.manifest.json"
    fi

    # Check if installed
    if [[ ! -f "$manifest_path" ]]; then
        echo -e "  ${DIM}Not installed${NC}"
        return 1
    fi

    # Check manifest
    echo -n "  Manifest: "
    if [[ -f "$manifest_path" ]]; then
        success "found"
        if $verbose; then
            local version
            version=$(jq -r '.version // "unknown"' "$manifest_path" 2>/dev/null)
            local install_date
            install_date=$(jq -r '.install_date // "unknown"' "$manifest_path" 2>/dev/null)
            echo "    Version: $version"
            echo "    Installed: $install_date"
        fi
    else
        error "missing"
        return 1
    fi

    # Check skills directory
    echo -n "  Skills: "
    local skills_dir="$target_path/skills"
    if [[ -d "$skills_dir" ]]; then
        local skill_count
        skill_count=$(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        success "$skill_count installed"

        if $verbose; then
            for skill in "$skills_dir"/*/; do
                if [[ -d "$skill" ]]; then
                    local skill_name
                    skill_name=$(basename "$skill")
                    if [[ -f "$skill/SKILL.md" ]]; then
                        echo "    $skill_name: OK"
                    else
                        echo -e "    $skill_name: ${YELLOW}missing SKILL.md${NC}"
                    fi
                fi
            done
        fi
    else
        warn "directory missing"
        return 2
    fi

    # Check subagents directory
    echo -n "  Subagents: "
    local agents_dir="$target_path/subagents"
    if [[ -d "$agents_dir" ]]; then
        local agent_count
        agent_count=$(find "$agents_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        success "$agent_count installed"

        if $verbose; then
            for agent in "$agents_dir"/*/; do
                if [[ -d "$agent" ]]; then
                    local agent_name
                    agent_name=$(basename "$agent")
                    if [[ -f "$agent/AGENT.md" ]]; then
                        echo "    $agent_name: OK"
                    else
                        echo -e "    $agent_name: ${YELLOW}missing AGENT.md${NC}"
                    fi
                fi
            done
        fi
    else
        warn "directory missing"
        return 2
    fi

    # Check templates
    echo -n "  Templates: "
    local templates_dir="$target_path/templates"
    if [[ -d "$templates_dir" ]]; then
        success "found"
    else
        warn "missing"
        return 2
    fi

    return 0
}

# Check system dependencies
check_dependencies() {
    local verbose="$1"

    # jq (optional but recommended)
    echo -n "  jq: "
    if command -v jq &>/dev/null; then
        local jq_version
        jq_version=$(jq --version 2>&1 | head -1)
        success "$jq_version"
    else
        warn "not installed (optional)"
    fi

    # git
    echo -n "  git: "
    if command -v git &>/dev/null; then
        local git_version
        git_version=$(git --version | head -1)
        success "$git_version"
    else
        warn "not installed"
    fi

    # Claude Code (check for ~/.claude)
    echo -n "  Claude Code: "
    if [[ -d "$CLAUDE_HOME" ]]; then
        success "detected"
    else
        warn "~/.claude not found"
    fi
}

# Check memory files in current project
check_memory_files() {
    local verbose="$1"
    local project_root
    project_root=$(get_project_root)

    local memory_files=(
        ".claude-sdk/ATLAS.md"
        ".claude-sdk/memory/DECISIONS.md"
        ".claude-sdk/memory/INVARIANTS.md"
        ".claude-sdk/memory/TASKS.md"
        ".claude-sdk/CONTRACT.md"
    )

    local found=0
    local total=${#memory_files[@]}

    for file in "${memory_files[@]}"; do
        local full_path="$project_root/$file"
        local name
        name=$(basename "$file")

        echo -n "  $name: "
        if [[ -f "$full_path" ]]; then
            success "found"
            ((found++))
        else
            echo -e "${DIM}not initialized${NC}"
        fi
    done

    echo ""
    echo "  $found/$total memory files initialized"

    if [[ $found -lt $total ]]; then
        echo "  Run 'claude-sdk init' to create missing files"
    fi
}
