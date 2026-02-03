#!/usr/bin/env bash
#
# Claude Code SDK - Install Command
#

install_help() {
    cat <<EOF
claude-sdk install - Install the SDK

USAGE:
    claude-sdk install [options]

OPTIONS:
    --global        Install globally to ~/.claude (user-level)
    --project       Install to current project's .claude-sdk directory
    --dry-run       Preview changes without applying them
    --force         Overwrite existing files (creates backups first)
    -h, --help      Show this help

DESCRIPTION:
    Installs the Claude Code Starter SDK, including:
    - Skills (spec-generator, code-review, debugging-playbook, repo-atlas, search-helper)
    - Subagents (planner, reviewer, indexer)
    - Configuration templates

    Global install makes SDK available to all projects.
    Project install keeps SDK artifacts within the repository.

EXAMPLES:
    # Install globally
    claude-sdk install --global

    # Install to current project
    claude-sdk install --project

    # Preview what would be installed
    claude-sdk install --project --dry-run

EOF
}

cmd_install() {
    local install_type=""
    local dry_run=false
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --global)
                install_type="global"
                shift
                ;;
            --project)
                install_type="project"
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            -h|--help)
                install_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                install_help
                return 1
                ;;
        esac
    done

    # Require install type
    if [[ -z "$install_type" ]]; then
        error "Must specify --global or --project"
        echo ""
        install_help
        return 1
    fi

    # Determine target path
    local target_path
    local backup_dir
    local manifest_path

    if [[ "$install_type" == "global" ]]; then
        target_path="$CLAUDE_HOME"
        backup_dir="$CLAUDE_HOME/.sdk-backups"
        manifest_path="$CLAUDE_HOME/.sdk-manifest.json"
    else
        target_path="$(get_project_sdk_dir)"
        backup_dir="$target_path/.backups"
        manifest_path="$target_path/.manifest.json"
    fi

    header "Claude Code SDK Installer"
    echo ""
    echo "Install type: $install_type"
    echo "Target path:  $target_path"
    echo ""

    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN MODE - No changes will be made${NC}"
        echo ""
    fi

    # Check for existing installation
    if [[ -f "$manifest_path" ]] && ! $force; then
        warn "SDK already installed at $target_path"
        echo "Use --force to reinstall (backups will be created)"
        return 1
    fi

    # Create directories
    step 1 "Creating directories..."
    local dirs_to_create=(
        "$target_path"
        "$target_path/skills"
        "$target_path/subagents"
        "$backup_dir"
    )

    for dir in "${dirs_to_create[@]}"; do
        if $dry_run; then
            dry_run_msg "mkdir -p $dir"
        else
            ensure_dir "$dir"
        fi
    done

    # Initialize manifest
    if ! $dry_run; then
        init_manifest "$manifest_path" "$install_type" "$target_path"
    fi

    # Install skills
    step 2 "Installing skills..."
    local skills_installed=0
    local skills_dir="$SDK_ROOT/skills"

    for skill_dir in "$skills_dir"/*/; do
        local skill_name
        skill_name="$(basename "$skill_dir")"
        local dest_skill="$target_path/skills/$skill_name"

        if $dry_run; then
            dry_run_msg "cp -r $skill_dir -> $dest_skill"
        else
            # Backup existing if force mode
            if [[ -d "$dest_skill" ]] && $force; then
                local backup_name="${skill_name}.$(date +%Y%m%d_%H%M%S)"
                cp -r "$dest_skill" "$backup_dir/$backup_name"
                manifest_add_backup "$manifest_path" "$dest_skill" "$backup_dir/$backup_name"
            fi

            cp -r "$skill_dir" "$dest_skill"
            manifest_add_file "$manifest_path" "$dest_skill" "skill"
        fi

        info "  $skill_name"
        ((skills_installed++))
    done

    # Install subagents
    step 3 "Installing subagents..."
    local subagents_installed=0
    local subagents_dir="$SDK_ROOT/subagents"

    for agent_dir in "$subagents_dir"/*/; do
        local agent_name
        agent_name="$(basename "$agent_dir")"
        local dest_agent="$target_path/subagents/$agent_name"

        if $dry_run; then
            dry_run_msg "cp -r $agent_dir -> $dest_agent"
        else
            if [[ -d "$dest_agent" ]] && $force; then
                local backup_name="${agent_name}.$(date +%Y%m%d_%H%M%S)"
                cp -r "$dest_agent" "$backup_dir/$backup_name"
                manifest_add_backup "$manifest_path" "$dest_agent" "$backup_dir/$backup_name"
            fi

            cp -r "$agent_dir" "$dest_agent"
            manifest_add_file "$manifest_path" "$dest_agent" "subagent"
        fi

        info "  $agent_name"
        ((subagents_installed++))
    done

    # Install templates
    step 4 "Installing templates..."
    local templates_dir="$SDK_ROOT/templates"
    local dest_templates="$target_path/templates"

    if $dry_run; then
        dry_run_msg "cp -r $templates_dir -> $dest_templates"
    else
        if [[ -d "$dest_templates" ]] && $force; then
            local backup_name="templates.$(date +%Y%m%d_%H%M%S)"
            cp -r "$dest_templates" "$backup_dir/$backup_name"
            manifest_add_backup "$manifest_path" "$dest_templates" "$backup_dir/$backup_name"
        fi

        cp -r "$templates_dir" "$dest_templates"
        manifest_add_file "$manifest_path" "$dest_templates" "template"
    fi

    # Install scripts
    step 5 "Installing scripts..."
    local scripts_dir="$SDK_ROOT/scripts"
    local dest_scripts="$target_path/scripts"

    if $dry_run; then
        dry_run_msg "cp -r $scripts_dir -> $dest_scripts"
    else
        cp -r "$scripts_dir" "$dest_scripts"
        chmod +x "$dest_scripts"/*.sh 2>/dev/null || true
        manifest_add_file "$manifest_path" "$dest_scripts" "script"
    fi

    # For global install, update Claude settings
    if [[ "$install_type" == "global" ]]; then
        step 6 "Updating Claude settings..."
        update_claude_settings "$target_path" "$backup_dir" "$manifest_path" $dry_run
    fi

    # For project install, also initialize the memory layer
    if [[ "$install_type" == "project" ]]; then
        step 6 "Initializing memory layer..."

        local project_root
        project_root=$(get_project_root)

        # Source init.sh to get the template functions
        source "$SDK_ROOT/cli/init.sh"

        # Create CLAUDE.md in project root
        local claude_file="$project_root/CLAUDE.md"
        if [[ ! -f "$claude_file" ]] || $force; then
            if $dry_run; then
                dry_run_msg "Create $claude_file"
            else
                create_claude_instructions "$claude_file"
                manifest_add_file "$manifest_path" "$claude_file" "config"
                info "  Created: CLAUDE.md (agent instructions)"
            fi
        else
            info "  CLAUDE.md exists"
        fi

        # Create memory files
        local memory_dir="$target_path/memory"
        if $dry_run; then
            dry_run_msg "mkdir -p $memory_dir"
        else
            ensure_dir "$memory_dir"
        fi

        # ATLAS.md
        local atlas_file="$target_path/ATLAS.md"
        if [[ ! -f "$atlas_file" ]] || $force; then
            if $dry_run; then
                dry_run_msg "Create $atlas_file"
            else
                create_atlas_template "$atlas_file" "$project_root"
                manifest_add_file "$manifest_path" "$atlas_file" "memory"
                info "  Created: ATLAS.md"
            fi
        fi

        # CONTRACT.md
        local contract_file="$target_path/CONTRACT.md"
        if [[ ! -f "$contract_file" ]] || $force; then
            if $dry_run; then
                dry_run_msg "Create $contract_file"
            else
                create_contract_template "$contract_file"
                manifest_add_file "$manifest_path" "$contract_file" "memory"
                info "  Created: CONTRACT.md"
            fi
        fi

        # DECISIONS.md
        local decisions_file="$memory_dir/DECISIONS.md"
        if [[ ! -f "$decisions_file" ]] || $force; then
            if $dry_run; then
                dry_run_msg "Create $decisions_file"
            else
                create_decisions_template "$decisions_file"
                manifest_add_file "$manifest_path" "$decisions_file" "memory"
                info "  Created: memory/DECISIONS.md"
            fi
        fi

        # INVARIANTS.md
        local invariants_file="$memory_dir/INVARIANTS.md"
        if [[ ! -f "$invariants_file" ]] || $force; then
            if $dry_run; then
                dry_run_msg "Create $invariants_file"
            else
                create_invariants_template "$invariants_file"
                manifest_add_file "$manifest_path" "$invariants_file" "memory"
                info "  Created: memory/INVARIANTS.md"
            fi
        fi

        # TASKS.md
        local tasks_file="$memory_dir/TASKS.md"
        if [[ ! -f "$tasks_file" ]] || $force; then
            if $dry_run; then
                dry_run_msg "Create $tasks_file"
            else
                create_tasks_template "$tasks_file"
                manifest_add_file "$manifest_path" "$tasks_file" "memory"
                info "  Created: memory/TASKS.md"
            fi
        fi

        # Create atlas directory
        local atlas_dir="$target_path/atlas"
        if $dry_run; then
            dry_run_msg "mkdir -p $atlas_dir"
        else
            ensure_dir "$atlas_dir"
        fi
    fi

    # Print summary
    if ! $dry_run; then
        print_install_summary "$install_type" "$target_path" "$skills_installed" "$subagents_installed"
    else
        echo ""
        echo -e "${YELLOW}DRY-RUN complete. Run without --dry-run to apply changes.${NC}"
    fi
}

# Update Claude's settings.json to register skills
update_claude_settings() {
    local target_path="$1"
    local backup_dir="$2"
    local manifest_path="$3"
    local dry_run="$4"

    local settings_file="$CLAUDE_HOME/settings.json"

    # Create settings.json if it doesn't exist
    if [[ ! -f "$settings_file" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            dry_run_msg "Create $settings_file with SDK configuration"
        else
            cat > "$settings_file" <<EOF
{
    "permissions": {
        "allow": [],
        "deny": []
    }
}
EOF
        fi
    else
        # Backup existing settings
        if [[ "$dry_run" == "true" ]]; then
            dry_run_msg "Backup $settings_file"
        else
            local backup_name="settings.json.$(date +%Y%m%d_%H%M%S).bak"
            cp "$settings_file" "$backup_dir/$backup_name"
            manifest_add_backup "$manifest_path" "$settings_file" "$backup_dir/$backup_name"
            info "  Backed up settings.json"
        fi
    fi
}
