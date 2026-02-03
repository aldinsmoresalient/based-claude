# Based Claude - Quickstart

Get productive with the SDK in under 5 minutes.

## What is this?

The Based Claude provides a **repo-owned memory layer** that helps AI agents:
- Re-orient quickly after context loss
- Understand codebase architecture
- Respect safety invariants
- Track multi-session work

## Installation

### One-Command Install

```bash
# Navigate to the SDK directory
cd path/to/claude-code-sdk

# Make CLI executable
chmod +x bin/claude-sdk

# Install globally (recommended for first-time setup)
./bin/claude-sdk install --global

# OR install for current project only
./bin/claude-sdk install --project
```

### Verify Installation

```bash
./bin/claude-sdk doctor --global
```

## Initialize Your Project

```bash
# Navigate to your project
cd your-project

# Initialize memory files
claude-sdk init --all

# Build the repo atlas
claude-sdk atlas build
```

This creates:
```
your-project/
└── .claude-sdk/
    ├── ATLAS.md           # Codebase overview
    ├── CONTRACT.md        # Agent permissions
    ├── atlas/             # Per-folder maps
    └── memory/
        ├── DECISIONS.md   # Architecture decisions
        ├── INVARIANTS.md  # Safety constraints
        └── TASKS.md       # Task tracking
```

## Quick Commands

| Command | Description |
|---------|-------------|
| `claude-sdk install --global` | Install SDK globally |
| `claude-sdk install --project` | Install SDK to project |
| `claude-sdk init` | Initialize memory files |
| `claude-sdk atlas build` | Generate repo atlas |
| `claude-sdk atlas refresh` | Update atlas incrementally |
| `claude-sdk atlas status` | Check atlas freshness |
| `claude-sdk doctor` | Validate installation |
| `claude-sdk uninstall` | Remove SDK |

## Using with Claude Code

Once installed, the SDK provides:

### Skills

Invoke skills by mentioning them:
- "Use the spec-generator skill to create a PRD for..."
- "Use code-review to review this PR..."
- "Use debugging-playbook to investigate..."
- "Use search-helper to find where..."

### Subagents

Reference subagents for specific roles:
- **Planner**: High-level task decomposition
- **Reviewer**: Risk-focused code review
- **Indexer**: Atlas maintenance

### Memory Files

Claude will automatically reference:
- `ATLAS.md` for codebase orientation
- `INVARIANTS.md` for safety constraints
- `CONTRACT.md` for permission boundaries
- `TASKS.md` for work tracking

## Example Workflow

1. **Start a new feature**
   ```
   > Use spec-generator to create a spec for user authentication
   ```

2. **Claude reads ATLAS.md** to understand codebase structure

3. **Claude checks INVARIANTS.md** for constraints

4. **Claude creates spec** following the template

5. **After implementation**, run:
   ```bash
   claude-sdk atlas refresh
   ```

## Next Steps

- Read [CLI.md](./CLI.md) for full command reference
- Read [ATLAS.md](./ATLAS.md) for atlas format details
- Read [CUSTOMIZATION.md](./CUSTOMIZATION.md) for configuration options

## Troubleshooting

### Atlas build fails
```bash
# Check for permission issues
ls -la .claude-sdk/

# Try with verbose output
DEBUG=1 claude-sdk atlas build
```

### Skills not loading
```bash
# Verify installation
claude-sdk doctor --verbose

# Check skill files exist
ls -la ~/.claude/skills/
```

### Uninstall and reinstall
```bash
claude-sdk uninstall --global --restore
claude-sdk install --global
```
