# Customization Guide

How to customize the Claude Code Starter SDK for your project.

## Customizing the Contract

The Claude Contract (`.claude-sdk/CONTRACT.md`) defines agent permissions.

### Permission Levels

```markdown
## Permissions

### Autonomous Actions (ALLOW)
# Actions Claude can take without asking

ALLOW: Read any file
ALLOW: Run tests
ALLOW: Run formatters

### Requires Confirmation (CONFIRM)
# Actions that need explicit approval

CONFIRM: Delete files
CONFIRM: Modify config files
CONFIRM: Push to remote

### Prohibited (DENY)
# Actions Claude must never take

DENY: Commit to main
DENY: Modify .env files
```

### Adding Project-Specific Rules

```markdown
## Project-Specific Rules

# Example: API versioning rule
RULE: All new endpoints must include version in path (/v1/, /v2/)

# Example: Testing requirement
RULE: All new functions require unit tests

# Example: Documentation requirement
RULE: Public APIs require JSDoc comments
```

## Customizing Invariants

The Invariants Registry (`.claude-sdk/memory/INVARIANTS.md`) captures safety constraints.

### Adding Invariants

```markdown
## Critical Invariants

INVARIANT: AUTH-001 All authentication routes in src/auth/
REASON: Security audit scope, centralized control
ENFORCED_BY: Architectural tests, code review

INVARIANT: DB-001 No raw SQL outside src/db/
REASON: Prevent SQL injection, ensure parameterization
ENFORCED_BY: Linting rule, code review
```

### Protected Paths

```markdown
## Protected Paths

PROTECTED: src/auth/           # Requires security review
PROTECTED: src/billing/        # Requires finance review
PROTECTED: migrations/         # Requires DBA approval
```

### Soft Constraints

```markdown
## Soft Constraints

PREFER: Composition over inheritance
INSTEAD_OF: Deep class hierarchies
BECAUSE: Easier testing, more flexible

PREFER: Named exports
INSTEAD_OF: Default exports
BECAUSE: Better refactoring support
```

## Customizing the Atlas

### Manual Annotations

The `## NOTES` section in atlas files is preserved across rebuilds:

```markdown
## NOTES

This folder handles all third-party integrations.
Key gotchas:
- Stripe webhooks must be verified before processing
- OAuth tokens expire after 1 hour
- Rate limiting applies to all external calls
```

### Overriding Auto-Detection

Replace auto-generated descriptions:

```markdown
# Before (auto-generated)
PURPOSE: [Auto-detected folder]

# After (manual)
PURPOSE: Core business logic for order processing
```

### Adding Architecture Context

```markdown
## ARCHITECTURE

This codebase follows hexagonal architecture:
- src/core/ contains domain logic (no external dependencies)
- src/adapters/ contains implementations of ports
- src/ports/ contains interfaces

Event sourcing is used for audit-critical operations.
```

### Custom Search Anchors

Add project-specific grep patterns:

```markdown
## SEARCH ANCHORS

GREP: "@Injectable" - Find DI services
GREP: "@Controller" - Find API controllers
GREP: "createSlice" - Find Redux slices
GREP: "useQuery" - Find React Query hooks
```

## Customizing Skills

### Extending Existing Skills

Create modified versions in your project:

```
your-project/
└── .claude-sdk/
    └── skills/
        └── code-review/
            └── SKILL.md    # Your customized version
```

### Creating Project Skills

Create new skills specific to your project:

```markdown
---
name: project-deploy
description: Deploy this specific project. Use when user wants to deploy to staging or production.
---

# Project Deploy Skill

## Staging Deploy

1. Run tests: `npm test`
2. Build: `npm run build`
3. Deploy: `./scripts/deploy-staging.sh`

## Production Deploy

Requires manual approval in CONTRACT.md.

1. Create release tag
2. Run `./scripts/deploy-prod.sh`
3. Monitor dashboards for 15 minutes
```

## Customizing Atlas Generation

### Configuration File

Create `.claude-sdk/atlas.config`:

```bash
# Folders to always include (comma-separated)
INCLUDE_FOLDERS=src,lib,packages

# Additional folders to exclude
EXCLUDE_FOLDERS=generated,mocks

# File patterns to analyze
INCLUDE_PATTERNS=*.ts,*.tsx,*.js,*.jsx

# Maximum folder depth to index
MAX_DEPTH=5

# Maximum files per folder
MAX_FILES_PER_FOLDER=100

# Enable/disable features
DETECT_EXPORTS=true
DETECT_DEPENDENCIES=true
DETECT_ROUTES=true
```

### Custom Layer Detection

Add patterns for your architecture:

```bash
# Layer detection patterns
LAYER_PATTERNS="
api:presentation
controller:presentation
service:business
repository:data
adapter:infrastructure
"
```

## Environment-Specific Settings

### Per-Environment Contracts

```markdown
## Environment: Development

ALLOW: Access localhost services
ALLOW: Use test credentials

## Environment: Production

DENY: Access databases directly
DENY: Use test credentials
CONFIRM: Any external API call
```

### CI/CD Integration

Run atlas checks in CI:

```yaml
# .github/workflows/atlas.yml
- name: Check Atlas Freshness
  run: |
    claude-sdk atlas status
    if [ $? -ne 0 ]; then
      echo "Atlas is stale. Run 'claude-sdk atlas refresh'"
      exit 1
    fi
```

## Team Conventions

### Documenting Conventions

Add to ATLAS.md:

```markdown
## TEAM CONVENTIONS

CONVENTION: Feature branches named feature/TICKET-description
CONVENTION: Commits follow Conventional Commits format
CONVENTION: PRs require 2 approvals for src/core/
```

### Shared Invariants

For monorepos, share invariants:

```markdown
## Cross-Package Invariants

INVARIANT: MONO-001 Packages must not have circular dependencies
INVARIANT: MONO-002 Shared types live in @company/types
INVARIANT: MONO-003 Each package has its own README
```
