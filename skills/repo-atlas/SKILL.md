---
name: repo-atlas
description: Build and maintain the Repo Atlas - a grep-friendly codebase index for rapid agent orientation. Use when you need to understand a new codebase, refresh your understanding after context loss, or help onboard other agents/developers. The atlas helps answer "what is this system?" and "where should I look?"
---

# Repo Atlas Builder

Build and maintain a persistent, grep-friendly codebase index.

## What is the Repo Atlas?

A human-readable, agent-readable index that captures:
- What the system does (purpose)
- How it's organized (structure)
- Where to look for things (navigation)
- What's important (hot paths, risks)
- What must not break (invariants)

## Atlas Structure

### Root Index (.claude-sdk/ATLAS.md)

```markdown
# REPO ATLAS

BUILT: 2024-01-15T10:30:00Z
COMMIT: abc123
TYPE: node | python | go | rust | mixed

## OVERVIEW
PROJECT: [Name]
PURPOSE: [One line]

## ENTRY POINTS
ENTRY: src/index.ts        # Main entry
ENTRY: src/api/routes.ts   # API routes
ENTRY: src/cli/main.ts     # CLI entry

## MAJOR DOMAINS
DOMAIN: src/api/      # REST API handlers
DOMAIN: src/core/     # Business logic
DOMAIN: src/db/       # Database layer
DOMAIN: src/utils/    # Shared utilities

## ARCHITECTURE
[Key architectural decisions and patterns]

## SEARCH ANCHORS
GREP: "export.*function" - Find exports
GREP: "@route|router\." - Find routes
GREP: "class.*Service" - Find services
```

### Folder Maps (.claude-sdk/atlas/*.atlas.md)

```markdown
# FOLDER: src/api

PURPOSE: REST API route handlers
LAYER: presentation
RISK: medium

## KEY FILES
FILE: routes.ts        # Route definitions
FILE: middleware.ts    # Auth, logging
FILE: validators.ts    # Input validation

## EXPORTS
EXPORT: registerRoutes(app)
EXPORT: authMiddleware

## DEPENDENCIES
DEPENDS_ON: src/core/  # Business logic
DEPENDS_ON: src/db/    # Data access

## PATTERNS
PATTERN: All routes go through authMiddleware
PATTERN: Validation before handler execution

## SEARCH ANCHORS
GREP: "router\.(get|post|put|delete)" - Find routes
GREP: "validate.*Schema" - Find validators
```

## Building the Atlas

### Automatic Build

Run: `claude-sdk atlas build`

This analyzes:
1. Project structure and file organization
2. Entry points (package.json, main files)
3. Export patterns
4. Import relationships
5. Common patterns (routes, services, models)

### Manual Enhancement

After auto-generation, enhance with:
- Domain knowledge
- Risk assessments
- Architectural context
- Team conventions

## Using the Atlas

### For Orientation

When starting work on unfamiliar code:
1. Read ATLAS.md for overview
2. Check relevant folder maps
3. Use search anchors to explore

### For Search

```bash
# Find all routes
grep -r "router\." src/

# Find all services
grep -r "class.*Service" src/

# Find uses of a function
grep -r "functionName" --include="*.ts"
```

### For Safety

Before modifying code:
1. Check INVARIANTS.md for constraints
2. Check folder map for RISK level
3. Note DEPENDS_ON for impact assessment

## Maintenance

### Refresh After Changes

Run: `claude-sdk atlas refresh`

Updates:
- File lists
- Export lists
- Timestamps

Preserves:
- Manual annotations
- Domain descriptions
- Architecture notes

### Drift Detection

The atlas warns when:
- Files changed significantly
- New folders appeared
- Exports changed

## Output Formats

### Grep-Friendly Prefixes

```
BUILT:      Build timestamp
COMMIT:     Git commit hash
TYPE:       Project type
PROJECT:    Project name
PURPOSE:    Description
ENTRY:      Entry point file
DOMAIN:     Major domain/folder
FILE:       Key file
EXPORT:     Exported symbol
DEPENDS_ON: Dependency
PATTERN:    Code pattern
RISK:       Risk level
GREP:       Search pattern
TAG:        Category tag
```

## Guidelines

- Keep descriptions concise (one line)
- Use consistent terminology
- Update after significant changes
- Link to ADRs for context

## Guardrails

- NEVER include secrets or credentials
- NEVER include full file contents
- Respect .gitignore (exclude dependencies, builds)
- Limit depth to avoid noise
