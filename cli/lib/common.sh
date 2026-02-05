#!/usr/bin/env bash
#
# Common utilities for Based Claude CLI
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
# Skill utilities
#───────────────────────────────────────────────────────────────────────────────

# Read a field from SKILL.md YAML frontmatter
# Usage: read_skill_field /path/to/SKILL.md "name"
read_skill_field() {
    local skill_file="$1"
    local field="$2"
    grep "^${field}:" "$skill_file" 2>/dev/null | sed "s/^${field}:[[:space:]]*//" | sed 's/^["'\'']//' | sed 's/["'\'']*$//'
}

# Validate a single SKILL.md file, returns 0 if valid
validate_skill_file() {
    local skill_file="$1"
    [[ -f "$skill_file" && -s "$skill_file" ]] || return 1
    head -1 "$skill_file" | grep -q "^---$" || return 1
    grep -q "^name:" "$skill_file" && grep -q "^description:" "$skill_file"
}

# Iterate over all installed skills (directory-based and flat .md)
# Calls the provided callback with: skill_dir skill_file skill_name
for_each_skill() {
    local skills_dir="$1"
    local callback="$2"

    # Directory-based skills: skill-name/SKILL.md
    for dir in "$skills_dir"/*/; do
        [[ -d "$dir" ]] || continue
        local skill_file="$dir/SKILL.md"
        if [[ -f "$skill_file" ]]; then
            local skill_name
            skill_name=$(basename "$dir")
            "$callback" "$dir" "$skill_file" "$skill_name"
        fi
    done

    # Flat .md skills (legacy): skill-name.md
    for skill_file in "$skills_dir"/*.md; do
        [[ -f "$skill_file" ]] || continue
        local skill_name
        skill_name=$(basename "$skill_file" .md)
        "$callback" "$(dirname "$skill_file")" "$skill_file" "$skill_name"
    done
}
