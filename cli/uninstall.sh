#!/usr/bin/env bash
#
# Claude Code SDK - Uninstall Command
#

uninstall_help() {
    cat <<EOF
claude-sdk uninstall - Remove SDK installation

USAGE:
    claude-sdk uninstall [options]

OPTIONS:
    --global        Uninstall from ~/.claude
    --project       Uninstall from current project
    --restore       Restore backups after uninstalling
    --dry-run       Preview changes without applying them
    --keep-memory   Keep memory files (ADR, tasks, etc.)
    -h, --help      Show this help

DESCRIPTION:
    Removes SDK-installed files using the manifest created during installation.
    This ensures only SDK files are removed, not user data.

    With --restore, original files are restored from backups.

EXAMPLES:
    # Uninstall from current project
    claude-sdk uninstall --project

    # Uninstall globally and restore original settings
    claude-sdk uninstall --global --restore

    # Preview what would be removed
    claude-sdk uninstall --project --dry-run

EOF
}

cmd_uninstall() {
    local uninstall_type=""
    local dry_run=false
    local restore=false
    local keep_memory=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --global)
                uninstall_type="global"
                shift
                ;;
            --project)
                uninstall_type="project"
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --restore)
                restore=true
                shift
                ;;
            --keep-memory)
                keep_memory=true
                shift
                ;;
            -h|--help)
                uninstall_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                uninstall_help
                return 1
                ;;
        esac
    done

    # Require uninstall type
    if [[ -z "$uninstall_type" ]]; then
        error "Must specify --global or --project"
        echo ""
        uninstall_help
        return 1
    fi

    # Determine paths
    local target_path
    local manifest_path
    local backup_dir

    if [[ "$uninstall_type" == "global" ]]; then
        target_path="$CLAUDE_HOME"
        manifest_path="$CLAUDE_HOME/.sdk-manifest.json"
        backup_dir="$CLAUDE_HOME/.sdk-backups"
    else
        target_path="$(get_project_sdk_dir)"
        manifest_path="$target_path/.manifest.json"
        backup_dir="$target_path/.backups"
    fi

    header "Claude Code SDK Uninstaller"
    echo ""
    echo "Uninstall type: $uninstall_type"
    echo "Target path:    $target_path"
    echo ""

    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN MODE - No changes will be made${NC}"
        echo ""
    fi

    # Check for manifest
    if [[ ! -f "$manifest_path" ]]; then
        error "No SDK installation found at $target_path"
        echo "Manifest not found: $manifest_path"
        return 1
    fi

    # Read manifest
    local manifest
    manifest=$(cat "$manifest_path")

    # Get installed files
    local files_to_remove=()

    if command -v jq &>/dev/null; then
        while IFS= read -r file_path; do
            if [[ -n "$file_path" ]]; then
                files_to_remove+=("$file_path")
            fi
        done < <(echo "$manifest" | jq -r '.files_installed[].path // empty')
    else
        warn "jq not available - using fallback removal"
        files_to_remove=(
            "$target_path/skills"
            "$target_path/subagents"
            "$target_path/templates"
            "$target_path/scripts"
        )
    fi

    # Remove installed files
    step 1 "Removing installed files..."
    local removed_count=0

    for file_path in "${files_to_remove[@]}"; do
        if [[ -e "$file_path" ]]; then
            if $dry_run; then
                dry_run_msg "rm -rf $file_path"
            else
                rm -rf "$file_path"
                info "  Removed: $file_path"
            fi
            ((removed_count++))
        fi
    done

    echo "  $removed_count items removed"

    # Restore backups if requested
    if $restore && [[ -d "$backup_dir" ]]; then
        step 2 "Restoring backups..."

        if command -v jq &>/dev/null; then
            while IFS= read -r backup_entry; do
                local original
                local backup
                original=$(echo "$backup_entry" | jq -r '.original')
                backup=$(echo "$backup_entry" | jq -r '.backup')

                if [[ -e "$backup" ]]; then
                    if $dry_run; then
                        dry_run_msg "cp -r $backup -> $original"
                    else
                        cp -r "$backup" "$original"
                        info "  Restored: $original"
                    fi
                fi
            done < <(echo "$manifest" | jq -c '.backups_created[]? // empty')
        fi
    fi

    # Remove manifest (but not memory files unless specified)
    step 3 "Cleaning up..."

    if $dry_run; then
        dry_run_msg "rm $manifest_path"
        if [[ -d "$backup_dir" ]]; then
            dry_run_msg "rm -rf $backup_dir"
        fi
    else
        rm -f "$manifest_path"
        if [[ -d "$backup_dir" ]]; then
            rm -rf "$backup_dir"
        fi
    fi

    # For project uninstall, optionally remove the whole .claude-sdk directory
    if [[ "$uninstall_type" == "project" ]] && ! $keep_memory; then
        if [[ -d "$target_path" ]]; then
            # Check if directory is empty (except hidden files)
            local remaining
            remaining=$(find "$target_path" -mindepth 1 -not -name ".*" 2>/dev/null | wc -l)

            if [[ "$remaining" -eq 0 ]]; then
                if $dry_run; then
                    dry_run_msg "rm -rf $target_path"
                else
                    rm -rf "$target_path"
                    info "  Removed empty SDK directory"
                fi
            fi
        fi
    fi

    # Summary
    echo ""
    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN complete. Run without --dry-run to apply changes.${NC}"
    else
        success "Uninstall complete"
        if $restore; then
            echo "Original files have been restored from backups."
        fi
    fi
}
