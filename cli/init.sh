#!/usr/bin/env bash
#
# Claude Code SDK - Init Command
# Initialize memory files in current project
#

init_help() {
    cat <<EOF
claude-sdk init - Initialize memory files in current project

USAGE:
    claude-sdk init [options]

OPTIONS:
    --all           Initialize all memory files
    --atlas         Initialize atlas structure only
    --memory        Initialize memory files only
    --contract      Initialize Claude contract only
    --dry-run       Preview changes
    --force         Overwrite existing files
    -h, --help      Show this help

DESCRIPTION:
    Initializes the project memory system:
    - CLAUDE.md - Agent instructions (project root)
    - .claude-sdk/ATLAS.md - Repo atlas (auto-generated)
    - .claude-sdk/memory/DECISIONS.md - Decision records (ADRs)
    - .claude-sdk/memory/INVARIANTS.md - Safety invariants
    - .claude-sdk/memory/TASKS.md - Task tracking
    - .claude-sdk/CONTRACT.md - Agent behavior contract

    Existing files are never overwritten without --force.

EXAMPLES:
    # Initialize everything
    claude-sdk init --all

    # Initialize just memory files
    claude-sdk init --memory

    # Preview what would be created
    claude-sdk init --all --dry-run

EOF
}

cmd_init() {
    local init_all=false
    local init_atlas=false
    local init_memory=false
    local init_contract=false
    local dry_run=false
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                init_all=true
                shift
                ;;
            --atlas)
                init_atlas=true
                shift
                ;;
            --memory)
                init_memory=true
                shift
                ;;
            --contract)
                init_contract=true
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
                init_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                init_help
                return 1
                ;;
        esac
    done

    # Default to all if nothing specified
    if ! $init_all && ! $init_atlas && ! $init_memory && ! $init_contract; then
        init_all=true
    fi

    if $init_all; then
        init_atlas=true
        init_memory=true
        init_contract=true
    fi

    local project_root
    project_root=$(get_project_root)
    local sdk_dir="$project_root/.claude-sdk"

    header "Initializing Project Memory"
    echo ""
    echo "Project: $project_root"
    echo ""

    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN MODE${NC}"
        echo ""
    fi

    local created_count=0

    # Create SDK directory
    if ! $dry_run; then
        ensure_dir "$sdk_dir"
        ensure_dir "$sdk_dir/memory"
        ensure_dir "$sdk_dir/atlas"
    fi

    # Initialize atlas structure
    if $init_atlas; then
        step 1 "Initializing atlas..."
        local atlas_file="$sdk_dir/ATLAS.md"

        if [[ -f "$atlas_file" ]] && ! $force; then
            info "  ATLAS.md exists (use --force to overwrite)"
        else
            if $dry_run; then
                dry_run_msg "Create $atlas_file"
            else
                create_atlas_template "$atlas_file" "$project_root"
                info "  Created: ATLAS.md"
                ((created_count++))
            fi
        fi
    fi

    # Initialize memory files
    if $init_memory; then
        step 2 "Initializing memory files..."

        # DECISIONS.md (ADR)
        local decisions_file="$sdk_dir/memory/DECISIONS.md"
        if [[ -f "$decisions_file" ]] && ! $force; then
            info "  DECISIONS.md exists"
        else
            if $dry_run; then
                dry_run_msg "Create $decisions_file"
            else
                create_decisions_template "$decisions_file"
                info "  Created: memory/DECISIONS.md"
                ((created_count++))
            fi
        fi

        # INVARIANTS.md
        local invariants_file="$sdk_dir/memory/INVARIANTS.md"
        if [[ -f "$invariants_file" ]] && ! $force; then
            info "  INVARIANTS.md exists"
        else
            if $dry_run; then
                dry_run_msg "Create $invariants_file"
            else
                create_invariants_template "$invariants_file"
                info "  Created: memory/INVARIANTS.md"
                ((created_count++))
            fi
        fi

        # TASKS.md
        local tasks_file="$sdk_dir/memory/TASKS.md"
        if [[ -f "$tasks_file" ]] && ! $force; then
            info "  TASKS.md exists"
        else
            if $dry_run; then
                dry_run_msg "Create $tasks_file"
            else
                create_tasks_template "$tasks_file"
                info "  Created: memory/TASKS.md"
                ((created_count++))
            fi
        fi
    fi

    # Initialize contract
    if $init_contract; then
        step 3 "Initializing Claude contract..."
        local contract_file="$sdk_dir/CONTRACT.md"

        if [[ -f "$contract_file" ]] && ! $force; then
            info "  CONTRACT.md exists"
        else
            if $dry_run; then
                dry_run_msg "Create $contract_file"
            else
                create_contract_template "$contract_file"
                info "  Created: CONTRACT.md"
                ((created_count++))
            fi
        fi
    fi

    # Initialize CLAUDE.md (agent instructions) in project root
    step 4 "Initializing agent instructions..."
    local claude_file="$project_root/CLAUDE.md"

    if [[ -f "$claude_file" ]] && ! $force; then
        info "  CLAUDE.md exists (use --force to overwrite)"
    else
        if $dry_run; then
            dry_run_msg "Create $claude_file"
        else
            create_claude_instructions "$claude_file"
            info "  Created: CLAUDE.md (agent instructions)"
            ((created_count++))
        fi
    fi

    # Create .gitignore for SDK directory
    local gitignore_file="$sdk_dir/.gitignore"
    if [[ ! -f "$gitignore_file" ]] && ! $dry_run; then
        cat > "$gitignore_file" <<EOF
# Claude Code SDK
# By default, memory files are NOT ignored (they should be versioned)
# Uncomment below to exclude specific files from version control

# .backups/
# *.bak
EOF
    fi

    # Summary
    echo ""
    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN complete${NC}"
    else
        if [[ $created_count -gt 0 ]]; then
            success "Created $created_count files"
            echo ""
            echo "Next steps:"
            echo "  1. Edit CONTRACT.md to set agent permissions"
            echo "  2. Run 'claude-sdk atlas build' to generate the atlas"
            echo "  3. Start recording decisions in DECISIONS.md"
        else
            echo "No new files created (all exist)"
        fi
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Template creation functions
#───────────────────────────────────────────────────────────────────────────────

create_atlas_template() {
    local file="$1"
    local project_root="$2"

    cat > "$file" <<'EOF'
# REPO ATLAS
# Human-editable codebase index for agent orientation
# Run 'claude-sdk atlas build' to auto-generate, or edit manually

BUILT: not-yet-built
COMMIT: unknown
TYPE: unknown

## OVERVIEW

PROJECT: [Project name]
PURPOSE: [One-line description]

## ENTRY POINTS

# Primary entry points for understanding this codebase:
ENTRY: [main entry file]

## MAJOR DOMAINS

# Top-level organization:
DOMAIN: src/           # [description]

## ARCHITECTURE

# Key architectural decisions:
# - [Decision 1]
# - [Decision 2]

## SEARCH ANCHORS

# Useful grep patterns:
GREP: "TODO|FIXME" - Find todos
GREP: "export (function|const|class)" - Find exports

## NOTES

Add architectural notes, gotchas, or important context here.
This section is preserved across atlas rebuilds.
EOF
}

create_decisions_template() {
    local file="$1"

    cat > "$file" <<'EOF'
# Decision Memory (ADRs)
# Lightweight Architecture Decision Records
# Format: grep-friendly, human-editable

## Active Decisions

### ADR-001: [Title]

STATUS: proposed | accepted | deprecated | superseded
DATE: YYYY-MM-DD
CONTEXT: [Why this decision was needed]
DECISION: [What was decided]
ALTERNATIVES: [What else was considered]
CONSTRAINTS: [What limitations affected the decision]
REVISIT_IF: [Conditions that would trigger reconsideration]

---

## Decision Index

# Quick reference for all decisions:
ADR: 001 - [Title] - STATUS

## Templates

<!-- Copy this template for new decisions:

### ADR-XXX: [Title]

STATUS: proposed
DATE: YYYY-MM-DD
CONTEXT:
DECISION:
ALTERNATIVES:
CONSTRAINTS:
REVISIT_IF:

-->
EOF
}

create_invariants_template() {
    local file="$1"

    cat > "$file" <<'EOF'
# Invariants & Guardrails Registry
# Safety constraints that agents must respect
# Format: explicit, simple language, grep-friendly

## Critical Invariants

# These MUST NOT be violated by any agent action:

INVARIANT: [ID] [Description]
REASON: [Why this matters]
ENFORCED_BY: [How it's enforced - tests, CI, manual review]

### Example Invariants

INVARIANT: AUTH-001 All authentication logic lives in src/auth/
REASON: Security audit scope, single point of control
ENFORCED_BY: Code review, architectural tests

INVARIANT: DB-001 Database writes must go through repository layer
REASON: Transaction management, audit logging
ENFORCED_BY: Linting rules, code review

INVARIANT: API-001 All external API calls must include timeout
REASON: Prevent cascade failures
ENFORCED_BY: Custom lint rule

## Soft Constraints

# Strong preferences that can be overridden with justification:

PREFER: [Description]
INSTEAD_OF: [Anti-pattern]
BECAUSE: [Reasoning]

## Protected Paths

# Files/directories that require extra scrutiny before modification:

PROTECTED: src/auth/          # Security-critical
PROTECTED: src/billing/       # Financial logic
PROTECTED: migrations/        # Database schema

## Guardrail Index

# Quick reference:
GUARD: AUTH-001 - Auth in src/auth/ only
GUARD: DB-001 - Writes through repository
GUARD: API-001 - Timeouts on external calls
EOF
}

create_tasks_template() {
    local file="$1"

    cat > "$file" <<'EOF'
# Task & Progress Memory
# Multi-session task tracking for agents
# Format: grep-friendly, agent-updatable, human-editable

## Active Tasks

### TASK-001: [Title]

STATUS: pending | in_progress | blocked | completed
GOAL: [What needs to be accomplished]
STARTED: YYYY-MM-DD
UPDATED: YYYY-MM-DD

FILES_TOUCHED:
- [file1]
- [file2]

PROGRESS:
- [x] Step 1
- [ ] Step 2
- [ ] Step 3

BLOCKERS:
- [Any blocking issues]

OPEN_QUESTIONS:
- [Questions needing answers]

NEXT_STEPS:
- [Immediate next actions]

---

## Task Index

# Quick reference:
TASK: 001 - [Title] - STATUS

## Completed Tasks

# Move completed tasks here for reference

---

## Session Log

# Brief notes from each work session:

SESSION: YYYY-MM-DD HH:MM
WORKED_ON: TASK-XXX
SUMMARY: [What was accomplished]
NEXT: [What to do next]

EOF
}

create_contract_template() {
    local file="$1"

    cat > "$file" <<'EOF'
# Claude Contract
# Explicit agreement between humans and agents
# Referenced by skills and subagents

## Permissions

### Autonomous Actions

# Claude MAY do these without asking:
ALLOW: Read any file in the repository
ALLOW: Run tests
ALLOW: Run linters and formatters
ALLOW: Create files in designated directories
ALLOW: Edit files to fix bugs or implement requested features

### Requires Confirmation

# Claude MUST ask before doing these:
CONFIRM: Delete files
CONFIRM: Modify configuration files
CONFIRM: Run commands that affect external systems
CONFIRM: Make breaking API changes
CONFIRM: Modify security-related code
CONFIRM: Push to remote repositories

### Prohibited Actions

# Claude must NEVER do these:
DENY: Commit directly to main branch
DENY: Modify .env or secrets files
DENY: Run destructive database commands
DENY: Access external services without explicit permission

## Style Preferences

### Code Style

STYLE: Follow existing patterns in the codebase
STYLE: Prefer explicit over clever
STYLE: Add comments only when logic isn't self-evident
STYLE: Match existing formatting conventions

### Communication Style

COMM: Be concise
COMM: Explain reasoning for non-obvious decisions
COMM: Ask before large refactors
COMM: Summarize changes after completing tasks

## Safety Preferences

SAFETY: Always create backups before destructive operations
SAFETY: Run tests before marking tasks complete
SAFETY: Review INVARIANTS.md before modifying protected paths
SAFETY: Check for breaking changes in public APIs

## Project-Specific Rules

# Add custom rules for this project:
# RULE: [Description]

EOF
}

create_claude_instructions() {
    local file="$1"

    cat > "$file" <<'EOF'
# Claude Code Instructions

This project uses the **Based Claude** memory layer.

## On Session Start

1. **Read `.claude-sdk/ATLAS.md`** to orient yourself to the codebase
2. **Check `.claude-sdk/memory/TASKS.md`** for any in-progress work
3. **Review `.claude-sdk/CONTRACT.md`** for permissions and constraints

## Before Modifying Code

1. **Check `.claude-sdk/memory/INVARIANTS.md`** for safety constraints
2. Respect all `INVARIANT:` and `PROTECTED:` entries
3. If touching a protected path, mention it explicitly

## During Work

### Task Tracking

When working on tasks, update `.claude-sdk/memory/TASKS.md`:
- Set STATUS to `in_progress` when starting
- Add files to `FILES_TOUCHED` as you modify them
- Update `PROGRESS` checkboxes as you complete steps
- Set STATUS to `completed` when done
- For multi-session work, add a `SESSION:` log entry

### Decision Recording

When making architectural decisions, add an ADR to `.claude-sdk/memory/DECISIONS.md`:
- Use format: `ADR-XXX: [Title]`
- Include STATUS, CONTEXT, DECISION, ALTERNATIVES

### Atlas Maintenance

After significant structural changes:
- Note that atlas may need refresh
- Run `claude-sdk atlas refresh` if available

## Permissions (from CONTRACT.md)

**Autonomous** (no confirmation needed):
- Read any file
- Run tests and linters
- Edit files for requested changes

**Requires confirmation**:
- Deleting files
- Modifying configuration
- Changes to PROTECTED paths

**Prohibited**:
- Direct commits to main
- Modifying .env or secrets
- Violating INVARIANTS.md

## Quick Reference

```
.claude-sdk/
├── ATLAS.md              # READ FIRST - codebase overview
├── CONTRACT.md           # Your permissions
├── atlas/                # Per-folder details
└── memory/
    ├── DECISIONS.md      # Record decisions here
    ├── INVARIANTS.md     # CHECK BEFORE EDITS
    └── TASKS.md          # Track work here
```

## Available Skills

- **spec-generator**: Create specs/PRDs before implementation
- **code-review**: Risk-aware code review
- **debugging-playbook**: Systematic bug investigation
- **repo-atlas**: Build/refresh codebase atlas
- **search-helper**: Grep-based code navigation
EOF
}
