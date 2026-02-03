#!/usr/bin/env bash
#
# Based Claude - One-Line Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/claude-code-sdk/main/install.sh | bash
#
# Or with options:
#   curl -fsSL ... | bash -s -- --global
#   curl -fsSL ... | bash -s -- --project
#
set -euo pipefail

VERSION="1.0.0"
# GitHub repository URL
REPO_URL="${CLAUDE_SDK_REPO:-https://github.com/aldinsmoresalient/based-claude}"
INSTALL_DIR="${CLAUDE_SDK_HOME:-$HOME/.claude-code-sdk}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}INFO${NC} $*"; }
success() { echo -e "${GREEN}OK${NC} $*"; }
warn() { echo -e "${YELLOW}WARN${NC} $*"; }
error() { echo -e "${RED}ERROR${NC} $*" >&2; }

#───────────────────────────────────────────────────────────────────────────────
# Main
#───────────────────────────────────────────────────────────────────────────────

main() {
    local install_type="global"

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
            --help|-h)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Based Claude Installer v${VERSION}                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Download SDK
    download_sdk

    # Run installation
    if [[ "$install_type" == "global" ]]; then
        install_global
    else
        install_project
    fi

    # Print next steps
    print_next_steps "$install_type"
}

usage() {
    cat <<EOF
Based Claude Installer

USAGE:
    curl -fsSL <url> | bash
    curl -fsSL <url> | bash -s -- [options]

OPTIONS:
    --global    Install globally to ~/.claude-code-sdk (default)
    --project   Install to current project's .claude-sdk/
    --help      Show this help

EXAMPLES:
    # Global install (default)
    curl -fsSL <url> | bash

    # Project install
    curl -fsSL <url> | bash -s -- --project

EOF
}

check_prerequisites() {
    info "Checking prerequisites..."

    # Check for required commands
    local missing=()

    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    if ! command -v bash &>/dev/null; then
        missing+=("bash")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing[*]}"
        exit 1
    fi

    # Check for recommended commands
    if ! command -v jq &>/dev/null; then
        warn "jq not installed (recommended for full functionality)"
    fi

    success "Prerequisites OK"
}

download_sdk() {
    info "Downloading SDK..."

    # Create temp directory
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # Check if we're running from the repo already
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$script_dir/bin/claude-sdk" ]]; then
        # Running from local copy
        INSTALL_DIR="$script_dir"
        info "Using local SDK at $INSTALL_DIR"
    else
        # Download from GitHub
        if command -v git &>/dev/null; then
            git clone --depth 1 "$REPO_URL" "$tmp_dir/sdk" 2>/dev/null || {
                error "Failed to clone repository"
                exit 1
            }
            INSTALL_DIR="$tmp_dir/sdk"
        else
            error "git is required to download the SDK"
            exit 1
        fi
    fi

    success "SDK ready"
}

install_global() {
    info "Installing globally..."

    local target_dir="$HOME/.claude-code-sdk"

    # Create directory
    mkdir -p "$target_dir"

    # Copy SDK files
    cp -r "$INSTALL_DIR/bin" "$target_dir/"
    cp -r "$INSTALL_DIR/cli" "$target_dir/"
    cp -r "$INSTALL_DIR/skills" "$target_dir/"
    cp -r "$INSTALL_DIR/subagents" "$target_dir/"
    cp -r "$INSTALL_DIR/templates" "$target_dir/"
    cp -r "$INSTALL_DIR/scripts" "$target_dir/"

    # Make executable
    chmod +x "$target_dir/bin/claude-sdk"
    chmod +x "$target_dir/scripts/"*.sh 2>/dev/null || true

    # Add to PATH suggestion
    local shell_rc=""
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_rc="$HOME/.bashrc"
    fi

    success "Installed to $target_dir"

    # Create symlink or suggest PATH update
    if [[ -d "$HOME/.local/bin" ]]; then
        ln -sf "$target_dir/bin/claude-sdk" "$HOME/.local/bin/claude-sdk"
        success "Symlinked to ~/.local/bin/claude-sdk"
    elif [[ -n "$shell_rc" ]]; then
        echo ""
        warn "Add to your PATH by running:"
        echo "  echo 'export PATH=\"\$HOME/.claude-code-sdk/bin:\$PATH\"' >> $shell_rc"
        echo "  source $shell_rc"
    fi
}

install_project() {
    info "Installing to current project..."

    local project_dir
    project_dir=$(pwd)
    local target_dir="$project_dir/.claude-sdk"

    # Run the SDK's init command
    "$INSTALL_DIR/bin/claude-sdk" init --all

    success "Initialized project at $project_dir"
}

print_next_steps() {
    local install_type="$1"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    if [[ "$install_type" == "global" ]]; then
        cat <<EOF
Next steps:

  1. Navigate to your project:
     cd your-project

  2. Initialize the memory layer:
     claude-sdk init

  3. Build the repo atlas:
     claude-sdk atlas build

  4. Verify installation:
     claude-sdk doctor

EOF
    else
        cat <<EOF
Next steps:

  1. Build the repo atlas:
     claude-sdk atlas build

  2. Edit CONTRACT.md to customize permissions

  3. Start using Claude Code - it will automatically
     read CLAUDE.md for instructions!

EOF
    fi

    echo "Documentation: $REPO_URL#readme"
    echo ""
}

main "$@"
