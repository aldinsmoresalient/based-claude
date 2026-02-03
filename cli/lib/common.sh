#!/usr/bin/env bash
#
# Common utilities for Claude Code SDK CLI
#

#───────────────────────────────────────────────────────────────────────────────
# Colors and formatting
#───────────────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    DIM=''
    NC=''
fi

#───────────────────────────────────────────────────────────────────────────────
# Logging functions
#───────────────────────────────────────────────────────────────────────────────
info() {
    echo -e "${BLUE}INFO${NC} $*"
}

success() {
    echo -e "${GREEN}OK${NC} $*"
}

warn() {
    echo -e "${YELLOW}WARN${NC} $*" >&2
}

error() {
    echo -e "${RED}ERROR${NC} $*" >&2
}

debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${DIM}DEBUG${NC} $*" >&2
    fi
}

# Print a step with a number
step() {
    local num="$1"
    shift
    echo -e "${CYAN}[$num]${NC} $*"
}

# Print a header
header() {
    echo ""
    echo -e "${BOLD}$*${NC}"
    echo -e "${DIM}$(printf '─%.0s' $(seq 1 ${#1}))${NC}"
}

# Print in dry-run mode
dry_run_msg() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
}

#───────────────────────────────────────────────────────────────────────────────
# Path utilities
#───────────────────────────────────────────────────────────────────────────────
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CLAUDE_SDK_MANIFEST="$CLAUDE_HOME/.sdk-manifest.json"

# Get project root (where .git is, or current dir)
get_project_root() {
    local dir="${1:-$(pwd)}"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    # No git root found, use current directory
    pwd
}

# Get the .claude-sdk directory for a project
get_project_sdk_dir() {
    local project_root
    project_root="$(get_project_root)"
    echo "$project_root/.claude-sdk"
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# File operations
#───────────────────────────────────────────────────────────────────────────────

# Check if file exists and is not empty
file_exists() {
    [[ -f "$1" && -s "$1" ]]
}

# Safe copy with backup
safe_copy() {
    local src="$1"
    local dest="$2"
    local backup_dir="${3:-}"

    if [[ -f "$dest" ]]; then
        if [[ -n "$backup_dir" ]]; then
            ensure_dir "$backup_dir"
            local backup_name
            backup_name="$(basename "$dest").$(date +%Y%m%d_%H%M%S).bak"
            cp "$dest" "$backup_dir/$backup_name"
            debug "Backed up $dest to $backup_dir/$backup_name"
        fi
    fi

    cp "$src" "$dest"
}

# Merge JSON files (simple append to arrays)
merge_json_array() {
    local base="$1"
    local addition="$2"
    local key="$3"

    if command -v jq &>/dev/null; then
        jq -s ".[0].$key + .[1].$key | unique" "$base" "$addition"
    else
        warn "jq not installed, cannot merge JSON"
        return 1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Manifest operations
#───────────────────────────────────────────────────────────────────────────────

# Initialize manifest
init_manifest() {
    local manifest_path="$1"
    local install_type="$2"  # "global" or "project"
    local target_path="$3"

    ensure_dir "$(dirname "$manifest_path")"

    cat > "$manifest_path" <<EOF
{
    "version": "$SDK_VERSION",
    "install_type": "$install_type",
    "install_path": "$target_path",
    "install_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "files_installed": [],
    "backups_created": [],
    "settings_modified": []
}
EOF
}

# Add file to manifest
manifest_add_file() {
    local manifest_path="$1"
    local file_path="$2"
    local file_type="$3"  # "skill", "subagent", "template", "config"

    if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg path "$file_path" --arg type "$file_type" \
            '.files_installed += [{"path": $path, "type": $type}]' \
            "$manifest_path" > "$tmp" && mv "$tmp" "$manifest_path"
    fi
}

# Add backup to manifest
manifest_add_backup() {
    local manifest_path="$1"
    local original_path="$2"
    local backup_path="$3"

    if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg orig "$original_path" --arg backup "$backup_path" \
            '.backups_created += [{"original": $orig, "backup": $backup}]' \
            "$manifest_path" > "$tmp" && mv "$tmp" "$manifest_path"
    fi
}

# Read manifest
read_manifest() {
    local manifest_path="$1"
    if [[ -f "$manifest_path" ]]; then
        cat "$manifest_path"
    else
        echo "{}"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Validation utilities
#───────────────────────────────────────────────────────────────────────────────

# Check if jq is available (optional but recommended)
check_jq() {
    if ! command -v jq &>/dev/null; then
        warn "jq not installed - some features will be limited"
        return 1
    fi
    return 0
}

# Check if git is available
check_git() {
    command -v git &>/dev/null
}

# Check if in a git repository
is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null 2>&1
}

# Get current git commit hash (short)
get_git_hash() {
    if is_git_repo; then
        git rev-parse --short HEAD 2>/dev/null || echo "unknown"
    else
        echo "not-a-repo"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# User interaction
#───────────────────────────────────────────────────────────────────────────────

# Confirm action (returns 0 for yes, 1 for no)
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"

    local yn
    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [Y/n] " yn
        yn="${yn:-y}"
    else
        read -r -p "$prompt [y/N] " yn
        yn="${yn:-n}"
    fi

    case "$yn" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# Summary printing
#───────────────────────────────────────────────────────────────────────────────

# Print installation summary
print_install_summary() {
    local install_type="$1"
    local target_path="$2"
    local skills_count="$3"
    local subagents_count="$4"

    header "Installation Summary"
    echo ""
    echo "  Type:       $install_type"
    echo "  Location:   $target_path"
    echo "  Skills:     $skills_count installed"
    echo "  Subagents:  $subagents_count installed"
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""

    if [[ "$install_type" == "global" ]]; then
        echo "Next steps:"
        echo "  1. Navigate to your project: cd your-project"
        echo "  2. Initialize the memory layer: claude-sdk init"
        echo "  3. Build the repo atlas: claude-sdk atlas build"
        echo ""
    else
        echo "What was created:"
        echo "  - CLAUDE.md: Agent instructions (Claude Code reads this automatically)"
        echo "  - .claude-sdk/: Memory layer (atlas, decisions, invariants, tasks)"
        echo ""
        echo "Next steps:"
        echo "  1. Run 'claude-sdk atlas build' to generate the Repo Atlas"
        echo "  2. Edit CONTRACT.md to customize agent permissions"
        echo "  3. Start using Claude Code - it will read CLAUDE.md automatically!"
        echo ""
    fi
}
