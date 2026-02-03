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
        ensure_dir "$sdk_dir/prompts"
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

    # Initialize prompts
    step 4 "Initializing prompts..."

    local build_prompt="$sdk_dir/prompts/BUILD_ATLAS.md"
    if [[ ! -f "$build_prompt" ]] || $force; then
        if $dry_run; then
            dry_run_msg "Create $build_prompt"
        else
            create_build_atlas_prompt "$build_prompt"
            info "  Created: prompts/BUILD_ATLAS.md"
            ((created_count++))
        fi
    else
        info "  BUILD_ATLAS.md exists"
    fi

    local refresh_prompt="$sdk_dir/prompts/REFRESH_ATLAS.md"
    if [[ ! -f "$refresh_prompt" ]] || $force; then
        if $dry_run; then
            dry_run_msg "Create $refresh_prompt"
        else
            create_refresh_atlas_prompt "$refresh_prompt"
            info "  Created: prompts/REFRESH_ATLAS.md"
            ((created_count++))
        fi
    else
        info "  REFRESH_ATLAS.md exists"
    fi

    # Initialize CLAUDE.md (agent instructions) in project root
    step 5 "Initializing agent instructions..."
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

This project uses **Based Claude** - a memory layer that helps you persist understanding across sessions.

---

## On Session Start

1. **Read `.claude-sdk/ATLAS.md`** - Orient yourself to the codebase
2. **Check `.claude-sdk/memory/TASKS.md`** - Any in-progress work?
3. **Review `.claude-sdk/CONTRACT.md`** - What are your permissions?

If the ATLAS.md says "not-yet-built", offer to build it (see below).

---

## Building the Atlas

When asked to **"build the atlas"** or **"generate the atlas"**:

1. Read `.claude-sdk/prompts/BUILD_ATLAS.md` for detailed instructions
2. Explore the codebase structure
3. Generate `.claude-sdk/ATLAS.md` (root index)
4. Generate `.claude-sdk/atlas/*.atlas.md` (folder maps)

The Atlas answers:
- "What is this system?"
- "Where should I look?"
- "What matters?"
- "What must NOT be broken?"

When asked to **"refresh the atlas"**:
1. Read `.claude-sdk/prompts/REFRESH_ATLAS.md`
2. Update only what changed (preserve NOTES sections)

---

## Before Modifying Code

1. **Check `.claude-sdk/memory/INVARIANTS.md`** for safety constraints
2. Respect all `INVARIANT:` and `PROTECTED:` entries
3. If touching a high-risk path, mention it explicitly

---

## During Work

### Task Tracking

Update `.claude-sdk/memory/TASKS.md`:
- Set STATUS to `in_progress` when starting
- Add files to `FILES_TOUCHED` as you modify them
- Update `PROGRESS` checkboxes
- Set STATUS to `completed` when done
- For multi-session work, add a `SESSION:` log entry

### Decision Recording

For architectural decisions, add to `.claude-sdk/memory/DECISIONS.md`:
```
### ADR-XXX: [Title]
STATUS: accepted
DATE: YYYY-MM-DD
CONTEXT: [Why needed]
DECISION: [What decided]
ALTERNATIVES: [What else considered]
```

### Discovering Invariants

If you discover rules like "all auth goes through X" or "never write directly to Y":
- Add them to `.claude-sdk/memory/INVARIANTS.md`
- Reference them in the relevant Atlas folder map

---

## Permissions (from CONTRACT.md)

**Autonomous** (no confirmation needed):
- Read any file
- Run tests and linters
- Edit files for requested changes

**Requires confirmation**:
- Deleting files
- Modifying configuration
- Changes to PROTECTED paths
- Large refactors

**Prohibited**:
- Direct commits to main
- Modifying .env or secrets
- Violating INVARIANTS.md

---

## Quick Reference

```
.claude-sdk/
├── ATLAS.md              # Codebase overview (READ FIRST)
├── CONTRACT.md           # Your permissions
├── atlas/                # Per-folder maps
├── memory/
│   ├── DECISIONS.md      # Architecture decisions (ADRs)
│   ├── INVARIANTS.md     # Safety constraints (CHECK BEFORE EDITS)
│   └── TASKS.md          # Task tracking
└── prompts/
    ├── BUILD_ATLAS.md    # How to generate the atlas
    └── REFRESH_ATLAS.md  # How to update the atlas
```

---

## Commands

| User says | You do |
|-----------|--------|
| "build the atlas" | Read BUILD_ATLAS.md prompt, generate atlas |
| "refresh the atlas" | Read REFRESH_ATLAS.md prompt, incremental update |
| "what is this codebase?" | Read ATLAS.md, summarize |
| "check for drift" | Compare ATLAS.md commit to current, report changes |
EOF
}

create_build_atlas_prompt() {
    local file="$1"

    cat > "$file" <<'EOF'
# Build Repo Atlas

You are generating a **Repo Atlas** - a persistent, grep-friendly codebase index that helps agents (including yourself) re-orient quickly after context loss.

## Core Purpose

The Atlas answers these questions in SECONDS:
1. **"What is this system?"** - Overview, purpose, architecture
2. **"Where should I look?"** - Entry points, domains, folder purposes
3. **"What matters?"** - Critical paths, hot files, integration points
4. **"What must NOT be broken?"** - High-risk areas, invariants, protected paths

This is NOT a search index. It's an ORIENTATION document.

---

## Step 1: Explore the Codebase

```bash
# Understand structure (ignore node_modules, dist, etc.)
ls -la
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) | grep -v node_modules | grep -v dist | head -50

# Find entry points
cat package.json 2>/dev/null | head -30
ls src/ 2>/dev/null
```

Read key files to understand what this codebase DOES, not just what files exist.

---

## Step 2: Generate Root Atlas

Create `.claude-sdk/ATLAS.md` with this EXACT format:

```markdown
# REPO ATLAS
# Generated by Claude - Human-editable
# Re-run "build the atlas" to refresh (preserves NOTES section)

BUILT: [ISO timestamp]
COMMIT: [git hash or "not-a-repo"]
TYPE: [node|python|go|rust|java|mixed]

## OVERVIEW

PROJECT: [name]
PURPOSE: [One sentence - what does this system DO?]
ARCHITECTURE: [One sentence - key architectural pattern]

## ENTRY POINTS

# Where to start reading this codebase:
ENTRY: [file] # [why this is an entry point]

## MAJOR DOMAINS

# Top-level organization - what are the major subsystems?
DOMAIN: [path/] # [one-line purpose]

## CRITICAL PATHS

# Code that is high-risk, load-bearing, or frequently changed:
CRITICAL: [path] # [why - e.g., "auth logic", "payment processing"]

## CROSS-CUTTING CONCERNS

# Where does logging, auth, error handling, etc. live?
CONCERN: auth -> [path]
CONCERN: logging -> [path]
CONCERN: errors -> [path]

## EXTERNAL INTEGRATIONS

# What external services/APIs does this connect to?
EXTERNAL: [service] # [where handled]

## SEARCH ANCHORS

# Grep patterns for navigating this codebase:
GREP: "[pattern]" # [what it finds]

## RELATED MEMORY

DECISIONS: .claude-sdk/memory/DECISIONS.md
INVARIANTS: .claude-sdk/memory/INVARIANTS.md
TASKS: .claude-sdk/memory/TASKS.md
CONTRACT: .claude-sdk/CONTRACT.md

## NOTES

[Add architectural notes, gotchas, tribal knowledge here.
This section is preserved across rebuilds.]
```

---

## Step 3: Generate Folder Maps

For each MAJOR folder, create `.claude-sdk/atlas/[folder-name].atlas.md`:

```markdown
# FOLDER: [path]

PURPOSE: [1-2 sentences - what does this folder DO?]
LAYER: [presentation|business|data|infrastructure|test|config]
RISK: [low|medium|high|critical]

## KEY FILES

FILE: [name] # [one-line purpose]

## PUBLIC INTERFACE

EXPORT: [symbol] # [what it does]
ROUTE: [path] [METHOD] # [handler] (if applicable)

## DEPENDENCIES

DEPENDS_ON: [path] # [why]

## INVARIANTS

INVARIANT: [rule that must not be violated]

## SEARCH ANCHORS

GREP: "[pattern]" # [what it finds]

## NOTES

[Folder-specific notes]
```

---

## Risk Assessment

Mark as high-risk if involves:
- **Authentication/Authorization** - RISK: critical
- **Payment/Billing** - RISK: critical
- **Data mutations** - RISK: high
- **External APIs** - RISK: high
- **Database schemas** - RISK: high

---

## Exclusions (NEVER index)

- node_modules/, vendor/, .venv/
- dist/, build/, target/
- .git/, coverage/
- .env, *.pem, *.key

---

## Format Rules

1. **One concept per line** - No paragraphs
2. **Deterministic prefixes** - ENTRY:, DOMAIN:, FILE:, EXPORT:, etc.
3. **Grep-friendly** - `grep "^ROUTE:" ATLAS.md` should work
4. **Minimal prose** - Save explanations for NOTES

---

## After Generation

Tell the user:
1. Atlas created at `.claude-sdk/ATLAS.md`
2. Folder maps at `.claude-sdk/atlas/`
3. Review and edit the NOTES sections
4. Run "refresh the atlas" after major changes
EOF
}

create_refresh_atlas_prompt() {
    local file="$1"

    cat > "$file" <<'EOF'
# Refresh Repo Atlas

Perform an INCREMENTAL update to the Repo Atlas.

## Step 1: Check What Changed

```bash
# Get atlas build commit
grep "^COMMIT:" .claude-sdk/ATLAS.md

# Get current commit
git rev-parse --short HEAD

# Find changed files
git diff --name-only [atlas-commit]..HEAD
```

## Step 2: Update Affected Folders

For each folder with changes:
1. Read existing `.claude-sdk/atlas/[folder].atlas.md`
2. Re-analyze the folder
3. Update FILE:, EXPORT:, ROUTE: entries
4. **PRESERVE the NOTES section**

## Step 3: Update Root Atlas

1. Update BUILT: timestamp
2. Update COMMIT: hash
3. Add/remove DOMAIN: entries if needed
4. **PRESERVE the NOTES section**

## Step 4: Report Drift

Warn if:
- Folders in atlas no longer exist
- New folders appeared
- File counts changed dramatically

## Format

Keep all existing format rules - one concept per line, deterministic prefixes.
EOF
}
