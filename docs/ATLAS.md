# Repo Atlas Guide

The Repo Atlas is the core differentiator of the Based Claude.
It provides persistent, grep-friendly codebase understanding.

## Purpose

The Atlas helps agents answer:
- "What is this system?"
- "Where should I look?"
- "What matters here?"
- "What must not be broken?"

Unlike retrieval-focused tools (embeddings, indexes), the Atlas optimizes
for **orientation** - helping agents quickly understand structure, intent,
and constraints.

## Structure

### Root Atlas (ATLAS.md)

The root atlas lives at `.claude-sdk/ATLAS.md` and provides:

```markdown
# REPO ATLAS

BUILT: 2024-01-15T10:30:00Z    # When atlas was generated
COMMIT: abc123                  # Git commit at build time
TYPE: node                      # Project type (node, python, go, etc.)

## OVERVIEW
PROJECT: my-app                 # Project name
PURPOSE: API for managing...    # One-line description

## ENTRY POINTS
ENTRY: src/index.ts            # Main entry point
ENTRY: src/api/routes.ts       # API routes

## MAJOR DOMAINS
DOMAIN: src/api/               # API handlers
DOMAIN: src/core/              # Business logic
DOMAIN: src/db/                # Data access

## ARCHITECTURE
[Key patterns, decisions, conventions]

## SEARCH ANCHORS
GREP: "export.*function" - Find exports
GREP: "@route|router\." - Find routes
```

### Folder Maps (atlas/*.atlas.md)

Each important folder gets its own map:

```markdown
# FOLDER: src/api

PURPOSE: REST API route handlers
LAYER: presentation
RISK: medium
FILES: 12

## KEY FILES
FILE: routes.ts        # Route definitions
FILE: middleware.ts    # Auth middleware

## EXPORTS
EXPORT: registerRoutes(app)
EXPORT: authMiddleware

## DEPENDENCIES
DEPENDS_ON: src/core/
DEPENDS_ON: src/db/

## PATTERNS
PATTERN: All routes use authMiddleware
PATTERN: Validation before handler

## SEARCH ANCHORS
GREP: "router\.(get|post)" - Find routes
```

## Format Principles

### Grep-Friendly

Every line uses a deterministic prefix:

| Prefix | Meaning |
|--------|---------|
| `BUILT:` | Build timestamp |
| `COMMIT:` | Git commit |
| `TYPE:` | Project type |
| `PROJECT:` | Project name |
| `PURPOSE:` | Description |
| `ENTRY:` | Entry point file |
| `DOMAIN:` | Major domain/folder |
| `FOLDER:` | Folder being described |
| `FILE:` | Key file |
| `EXPORT:` | Exported symbol |
| `DEPENDS_ON:` | Dependency |
| `DEPENDED_BY:` | Reverse dependency |
| `PATTERN:` | Code pattern |
| `RISK:` | Risk level |
| `LAYER:` | Architecture layer |
| `GREP:` | Search pattern |
| `TAG:` | Category tag |

### One Concept Per Line

Good:
```
FILE: auth.ts        # Authentication logic
FILE: session.ts     # Session management
```

Bad:
```
Key files include auth.ts for authentication and session.ts for session management
```

### Minimal Prose

Atlas is for navigation, not documentation. Keep descriptions to one line.

## Human-Editable

The Atlas is designed for human editing:

1. **Add notes**: The `## NOTES` section is preserved across rebuilds
2. **Correct purpose**: Override auto-detected descriptions
3. **Add context**: Include architectural decisions
4. **Mark risks**: Annotate high-risk areas

## Maintenance

### Building

```bash
# Initial build
claude-sdk atlas build

# Full rebuild
claude-sdk atlas build --full

# Single folder
claude-sdk atlas build --folder src/api
```

### Refreshing

```bash
# Incremental update
claude-sdk atlas refresh
```

Refresh:
- Updates only changed folders (using git history)
- Preserves manual annotations
- Updates timestamps

### Drift Detection

```bash
# Check for drift
claude-sdk atlas status
```

Warns when:
- Atlas is stale (commits since build)
- File counts changed significantly
- New folders appeared

## Configuration

Create `.claude-sdk/atlas.config` to customize:

```bash
# Folders to always include
INCLUDE_FOLDERS=src,lib,api

# Folders to exclude
EXCLUDE_FOLDERS=node_modules,dist,coverage

# File patterns to index
INCLUDE_PATTERNS=*.ts,*.js,*.py

# Maximum depth
MAX_DEPTH=4

# Maximum files per folder
MAX_FILES_PER_FOLDER=50
```

## Best Practices

1. **Build after major changes**: Rebuild after adding new domains
2. **Review before committing**: Check atlas for accuracy
3. **Add context**: Enrich with architectural knowledge
4. **Keep current**: Run refresh regularly
5. **Version control**: Commit atlas files

## Integration with Other Memory

The Atlas connects to:

- **INVARIANTS.md**: Links to safety constraints
- **DECISIONS.md**: Links to ADRs explaining architecture
- **CONTRACT.md**: Defines what agents can do with the codebase
