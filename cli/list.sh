#!/usr/bin/env bash
#
# Based Claude v2 - List Command
# Shows installed skills and their status
#

list_help() {
    cat <<EOF
based-claude list - Show installed skills

USAGE:
    based-claude list [options]

OPTIONS:
    --verbose       Show full descriptions
    -h, --help      Show this help

EOF
}

cmd_list() {
    local verbose=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                list_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                list_help
                return 1
                ;;
        esac
    done

    local project_root
    project_root=$(get_project_root)
    local skills_dir="$project_root/.claude/skills"

    if [[ ! -d "$skills_dir" ]]; then
        warn "No skills directory found"
        echo "Run 'based-claude init' first"
        return 1
    fi

    local count=0

    _list_skill() {
        local _dir="$1"
        local _file="$2"
        local _name="$3"

        local name desc status
        if validate_skill_file "$_file"; then
            name=$(read_skill_field "$_file" "name")
            desc=$(read_skill_field "$_file" "description")
            status="${GREEN}valid${NC}"
        else
            name="$_name"
            desc="(invalid or missing frontmatter)"
            status="${RED}invalid${NC}"
        fi

        if $verbose; then
            echo -e "  ${BOLD}$name${NC}  $status"
            echo -e "    ${DIM}$desc${NC}"
            echo ""
        else
            # Truncate description to 60 chars
            if [[ ${#desc} -gt 60 ]]; then
                desc="${desc:0:57}..."
            fi
            printf "  %-25s %s\n" "$name" "$desc"
        fi
        count=$((count + 1))
    }

    header "Installed Skills"
    echo ""

    for_each_skill "$skills_dir" _list_skill

    if [[ $count -eq 0 ]]; then
        echo "  (none)"
        echo ""
        echo "Skills are generated when you tell Claude to 'annotate this codebase'."
    else
        echo ""
        echo "$count skill(s) installed in .claude/skills/"
    fi
}
