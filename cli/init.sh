#!/usr/bin/env bash
#
# Based Claude v2 - Init Command
# Creates CLAUDE.md with atlas structure and skill generation instructions
#

init_help() {
    cat <<EOF
based-claude init - Initialize Based Claude in current project

USAGE:
    based-claude init [options]

OPTIONS:
    --dry-run       Preview changes
    --force         Overwrite existing files
    -h, --help      Show this help

DESCRIPTION:
    Creates CLAUDE.md with:
    - Atlas structure (domains, cross-references)
    - Invariants section
    - Skills index
    - Annotation workflow instructions

    After init, ask Claude to "annotate this codebase" to:
    1. Build the import graph (discover USED_BY)
    2. Add @claude headers to key files
    3. Generate domain-specific skills
    4. Complete the atlas

EXAMPLES:
    based-claude init
    based-claude init --dry-run
    based-claude init --force

EOF
}

cmd_init() {
    local dry_run=false
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
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

    local project_root
    project_root=$(get_project_root)
    local claude_file="$project_root/CLAUDE.md"
    local skills_dir="$project_root/.claude/skills"

    # Welcome message
    echo ""
    echo -e "${BOLD}Based Claude${NC} - Context-anchored memory for Claude Code"
    echo ""
    echo "  Keeps Claude oriented with three anchors:"
    echo "  • CLAUDE.md - Auto-loaded atlas with domains & invariants"
    echo "  • Generated Skills - Domain-specific checklists"
    echo "  • @claude Headers - Blast radius tracking (USED_BY)"
    echo ""
    header "Initializing"
    echo ""
    echo "Project: $project_root"
    echo ""

    if $dry_run; then
        echo -e "${YELLOW}DRY-RUN MODE${NC}"
        echo ""
    fi

    # Check existing
    if [[ -f "$claude_file" ]] && ! $force; then
        warn "CLAUDE.md already exists"
        echo "Use --force to overwrite"
        return 1
    fi

    if $dry_run; then
        dry_run_msg "Create $claude_file"
        dry_run_msg "Create $skills_dir/"
        dry_run_msg "Create $skills_dir/skill-creator.md"
        echo ""
        echo "Would create CLAUDE.md, .claude/skills/, and default skill"
    else
        # Create CLAUDE.md
        create_claude_md "$claude_file" "$project_root"

        # Create skills directory
        ensure_dir "$skills_dir"

        # Copy default skill-creator skill (as directory with SKILL.md)
        local default_skills_dir="$SDK_ROOT/cli/skills"
        if [[ -d "$default_skills_dir/skill-creator" ]]; then
            cp -r "$default_skills_dir/skill-creator" "$skills_dir/"
        fi

        success "Created CLAUDE.md"
        success "Created .claude/skills/"
        success "Installed skill: skill-creator/"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${BOLD}Next Step:${NC} Open Claude Code and say:"
        echo ""
        echo -e "  ${CYAN}\"annotate this codebase\"${NC}"
        echo ""
        echo "Claude will then:"
        echo "  • Explore your codebase structure"
        echo "  • Add @claude headers to key files"
        echo "  • Generate domain-specific skills"
        echo "  • Complete the atlas in CLAUDE.md"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
}

create_claude_md() {
    local file="$1"
    local project_root="$2"
    local project_name
    project_name=$(basename "$project_root")

    cat > "$file" << 'CLAUDEMD'
<!--
IMPORTANT FOR CLAUDE: Check the BUILT field at the bottom of this file.
If it says "not-yet-annotated", proactively tell the user:

"I see this codebase uses Based Claude but hasn't been annotated yet.
Would you like me to annotate it now? This will:
• Add @claude headers to key files (for blast radius tracking)
• Generate domain-specific skills
• Complete the atlas in this file

Just say 'yes' or 'annotate this codebase' to get started."
-->

# Project Name

> Brief description: what does this system do?

## Quick Start

| Action | Command |
|--------|---------|
| Install | `npm install` |
| Dev | `npm run dev` |
| Test | `npm test` |
| Build | `npm run build` |

## Entry Points

- `src/index.ts` - Main entry point
- `package.json` - Dependencies and scripts

## Domains

| Domain | Path | Risk | Description |
|--------|------|------|-------------|
| | | | *Run "annotate this codebase" to populate* |

## Cross-References (Blast Radius)

When modifying code, check what depends on it:

| When Modifying | Also Check | Why |
|----------------|------------|-----|
| | | *Generated during annotation* |

## Invariants

System-wide rules that must NEVER be violated:

| ID | Rule | Scope |
|----|------|-------|
| | *Discovered during annotation* | |

## Skills

Generated skills for this codebase:

| Skill | When to Use | Risk |
|-------|-------------|------|
| | *Generated during annotation* | |

## Current Work

*Track multi-session tasks here*

---

# For Claude: How This Works

## First Time Setup

If the tables above are empty, the user needs to say **"annotate this codebase"**.

When they do, follow the annotation workflow below to:
1. Add @claude headers to key files
2. Generate domain-specific skills
3. Fill in the atlas tables above

## @claude Header Format

Add this to key files (entry points, critical code, high-risk areas):

```
/**
 * @claude
 * PURPOSE: [One line - what this file does]
 * RISK: low | medium | high | critical
 * INVARIANT: [File-specific rule, if any]
 * USED_BY: [Files that import/depend on this - CRITICAL for blast radius]
 * DEPENDS: [Key imports this file relies on]
 */
```

**USED_BY is the key insight** - it tells you what might break when you modify this file.

## Annotation Workflow

When user says **"annotate this codebase"**:

### Phase 1: Explore & Map

```bash
# 1. Understand structure
ls -la
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || cat go.mod 2>/dev/null

# 2. Find all source files
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) | grep -v node_modules | grep -v dist | grep -v __pycache__

# 3. Identify domains (top-level src folders)
ls src/ 2>/dev/null || ls app/ 2>/dev/null || ls lib/ 2>/dev/null
```

### Phase 2: Build Import Graph

For each key file, discover:
- **DEPENDS**: What it imports (read the imports)
- **USED_BY**: What imports it (grep for the filename)

```bash
# Find what imports a file (USED_BY)
grep -r "from './auth'" src/ --include="*.ts"
grep -r "import.*login" src/ --include="*.ts"
```

### Phase 3: Classify Risk

| Risk | Criteria |
|------|----------|
| critical | Auth, payments, security, secrets, encryption |
| high | Database, external APIs, data mutations, PII |
| medium | Business logic, API routes, services |
| low | Utilities, helpers, types, constants |

### Phase 4: Annotate Key Files (10-30 files)

Add @claude headers to:
- Entry points (index, main, app)
- API routes/endpoints
- Auth/security code
- Database/data layer
- Core business logic
- Shared utilities used by many files

**Skip**: Tests, type-only files, generated code, configs, node_modules

### Phase 5: Generate Skills

For each CRITICAL or HIGH risk domain, create a skill directory.

**Skill structure** (skills are directories, not single files):
```
.claude/skills/
└── modify-[domain]/
    └── SKILL.md
```

**SKILL.md format**:
```markdown
---
name: modify-[domain]
description: Use when modifying any code in [path]. This is [RISK] risk code. Handles [what it does].
---

# Modifying [Domain] Code

## Risk Level: [CRITICAL/HIGH]

[Why this domain is sensitive]

## Files in This Domain

| File | Purpose | USED_BY |
|------|---------|---------|
| [file.ts] | [purpose] | [consumers] |

## Invariants

- [Rule 1]
- [Rule 2]

## Before Making Changes

1. Read the @claude header for USED_BY
2. Understand what depends on your changes

## After Making Changes

1. Run tests: `[test command]`
2. Verify consumers still work: [list USED_BY files]

## Common Patterns

### [Pattern name]
[Steps]
```

### Phase 6: Update This File (CLAUDE.md)

1. Fill in the **Domains** table at the top
2. Fill in the **Cross-References** table from USED_BY data
3. Add discovered **Invariants**
4. Update **Skills** table with generated skills
5. Update the project name and description
6. Update metadata at bottom (BUILT, COMMIT, counts)

### Phase 7: Report to User

Tell the user:
- How many files annotated
- What domains found
- What skills generated
- Any concerns discovered (security issues, missing tests, etc.)
- Suggest they review the invariants

---

## Ongoing Usage

### When Working on Tasks

1. **Read this file** (you're doing that now - it's auto-loaded)
2. **Check the Skills table** - is there a skill for this domain?
3. **If yes, read the skill** at `.claude/skills/[skill-name]/SKILL.md`
4. **Before modifying a file**, check its @claude header for USED_BY
5. **After changes**, verify files in USED_BY still work

**Tip**: Use the skill-creator skill for guidance on creating well-structured skills:
`.claude/skills/skill-creator/SKILL.md`

### When User Says "refresh the atlas"

1. Check what files changed since last annotation (compare COMMIT)
2. Rebuild import graph for changed files
3. Update USED_BY in affected headers
4. Regenerate cross-references table
5. Update skills if domain structure changed
6. Update BUILT timestamp and COMMIT

---

BUILT: not-yet-annotated
COMMIT: unknown
FILES_ANNOTATED: 0
SKILLS_GENERATED: 0
CLAUDEMD
}
