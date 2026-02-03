#!/usr/bin/env bash
#
# Initialize Memory Files Script
# Creates the memory system files with templates
#
set -euo pipefail

main() {
    local project_root="${1:-.}"
    local sdk_dir="$project_root/.claude-sdk"

    echo "Initializing Memory System"
    echo "=========================="
    echo ""

    # Create directories
    mkdir -p "$sdk_dir/memory"
    mkdir -p "$sdk_dir/atlas"

    # Create DECISIONS.md if not exists
    if [[ ! -f "$sdk_dir/memory/DECISIONS.md" ]]; then
        create_decisions_file "$sdk_dir/memory/DECISIONS.md"
        echo "✓ Created memory/DECISIONS.md"
    else
        echo "• memory/DECISIONS.md exists"
    fi

    # Create INVARIANTS.md if not exists
    if [[ ! -f "$sdk_dir/memory/INVARIANTS.md" ]]; then
        create_invariants_file "$sdk_dir/memory/INVARIANTS.md"
        echo "✓ Created memory/INVARIANTS.md"
    else
        echo "• memory/INVARIANTS.md exists"
    fi

    # Create TASKS.md if not exists
    if [[ ! -f "$sdk_dir/memory/TASKS.md" ]]; then
        create_tasks_file "$sdk_dir/memory/TASKS.md"
        echo "✓ Created memory/TASKS.md"
    else
        echo "• memory/TASKS.md exists"
    fi

    # Create CONTRACT.md if not exists
    if [[ ! -f "$sdk_dir/CONTRACT.md" ]]; then
        create_contract_file "$sdk_dir/CONTRACT.md"
        echo "✓ Created CONTRACT.md"
    else
        echo "• CONTRACT.md exists"
    fi

    # Create ATLAS.md placeholder if not exists
    if [[ ! -f "$sdk_dir/ATLAS.md" ]]; then
        create_atlas_placeholder "$sdk_dir/ATLAS.md"
        echo "✓ Created ATLAS.md (placeholder)"
    else
        echo "• ATLAS.md exists"
    fi

    echo ""
    echo "Memory system initialized!"
    echo ""
    echo "Next steps:"
    echo "  1. Run 'claude-sdk atlas build' to generate the atlas"
    echo "  2. Edit CONTRACT.md to set agent permissions"
    echo "  3. Add invariants to INVARIANTS.md"
}

create_decisions_file() {
    local file="$1"
    cat > "$file" <<'EOF'
# Decision Memory (ADRs)
# Lightweight Architecture Decision Records

## Active Decisions

<!-- Add decisions using this format:

### ADR-001: [Title]

STATUS: accepted
DATE: YYYY-MM-DD
CONTEXT: [Why this decision was needed]
DECISION: [What was decided]
ALTERNATIVES: [What else was considered]
CONSTRAINTS: [What limitations affected the decision]
REVISIT_IF: [Conditions that would trigger reconsideration]

---

-->

## Decision Index

# Quick lookup:
# ADR: 001 - [Title] - STATUS

EOF
}

create_invariants_file() {
    local file="$1"
    cat > "$file" <<'EOF'
# Invariants & Guardrails Registry
# Safety constraints that agents must respect

## Critical Invariants

# Add invariants using this format:
# INVARIANT: [ID] [Description]
# REASON: [Why this matters]
# ENFORCED_BY: [How it's enforced]

## Protected Paths

# PROTECTED: path/to/sensitive/  # Reason

## Soft Constraints

# PREFER: [Preferred approach]
# INSTEAD_OF: [Anti-pattern]
# BECAUSE: [Reasoning]

EOF
}

create_tasks_file() {
    local file="$1"
    cat > "$file" <<'EOF'
# Task & Progress Memory
# Multi-session task tracking

## Active Tasks

<!-- Add tasks using this format:

### TASK-001: [Title]

STATUS: pending
GOAL: [What needs to be accomplished]
STARTED: YYYY-MM-DD

FILES_TOUCHED:
- [file1]

PROGRESS:
- [ ] Step 1

NEXT_STEPS:
- [What to do next]

---

-->

## Task Index

# Quick lookup:
# TASK: 001 - [Title] - STATUS

## Session Log

# SESSION: YYYY-MM-DD HH:MM
# WORKED_ON: TASK-XXX
# SUMMARY: [What was accomplished]

EOF
}

create_contract_file() {
    local file="$1"
    cat > "$file" <<'EOF'
# Claude Contract
# Explicit agreement between humans and agents

## Permissions

### Autonomous Actions (Claude may do without asking)
ALLOW: Read any file in the repository
ALLOW: Run tests
ALLOW: Run linters and formatters

### Requires Confirmation
CONFIRM: Delete files
CONFIRM: Modify configuration files
CONFIRM: Run commands affecting external systems

### Prohibited
DENY: Commit directly to main branch
DENY: Modify .env or secrets files

## Style Preferences

STYLE: Follow existing patterns in the codebase
STYLE: Prefer explicit over clever

## Safety Rules

SAFETY: Always create backups before destructive operations
SAFETY: Run tests before marking tasks complete
SAFETY: Review INVARIANTS.md before modifying protected paths

EOF
}

create_atlas_placeholder() {
    local file="$1"
    cat > "$file" <<'EOF'
# REPO ATLAS
# Run 'claude-sdk atlas build' to generate

BUILT: not-yet-built
COMMIT: unknown
TYPE: unknown

## OVERVIEW

PROJECT: [Project name]
PURPOSE: [Run atlas build to auto-detect]

## ENTRY POINTS

# Run atlas build to populate

## MAJOR DOMAINS

# Run atlas build to populate

EOF
}

main "$@"
