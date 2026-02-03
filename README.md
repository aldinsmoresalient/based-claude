# Based Claude

A repo-owned, agent-native memory layer for Claude Code and similar agentic coding tools.

## The Problem

AI coding assistants lose understanding across:
- Context compactions
- Session restarts
- Agent switching
- Long-running projects

Existing tools optimize for *retrieval*, not *persistent understanding*.

## The Solution

The Claude Code Starter SDK provides:

- **CLAUDE.md**: Agent instructions that Claude Code reads automatically
- **Repo Atlas**: Grep-friendly codebase index for rapid re-orientation
- **Decision Memory**: Lightweight ADRs capturing architectural decisions
- **Invariants Registry**: Safety constraints agents must respect
- **Task Memory**: Multi-session work tracking
- **Claude Contract**: Explicit permissions and boundaries

All artifacts are human-readable, version-controllable, and repo-owned.

## Installation

### Option 1: One-Line Install (Recommended)

```bash
# Clone and install globally
git clone https://github.com/aldinsmoresalient/based-claude.git
cd claude-code-sdk
chmod +x bin/claude-sdk install.sh
./install.sh --global
```

### Option 2: Direct Use

```bash
# Clone the SDK
git clone https://github.com/aldinsmoresalient/based-claude.git

# Initialize in your project
cd your-project
/path/to/claude-code-sdk/bin/claude-sdk init
```

### Option 3: Claude Code Plugin (Skills Only)

```bash
# In Claude Code:
/plugin marketplace add aldinsmoresalient/based-claude
/plugin install engineering-skills@claude-code-sdk
```

## Quick Start

```bash
# 1. Initialize your project
cd your-project
claude-sdk init

# 2. Build the repo atlas
claude-sdk atlas build

# 3. Start using Claude Code
# Claude will automatically read CLAUDE.md!
```

## What Gets Created

After `claude-sdk init`, your project has:

```
your-project/
├── CLAUDE.md                 # Agent instructions (Claude reads this!)
└── .claude-sdk/
    ├── ATLAS.md              # Codebase overview
    ├── CONTRACT.md           # Agent permissions
    ├── atlas/                # Per-folder maps
    └── memory/
        ├── DECISIONS.md      # Architecture decisions (ADRs)
        ├── INVARIANTS.md     # Safety constraints
        └── TASKS.md          # Task tracking
```

## How It Works

### CLAUDE.md (The Key)

The `CLAUDE.md` file in your project root is automatically read by Claude Code. It instructs Claude to:

1. **On session start**: Read the Atlas and check for in-progress tasks
2. **Before modifying code**: Check invariants and protected paths
3. **During work**: Update task progress and record decisions
4. **After changes**: Note if atlas needs refresh

### Memory Files

| File | Purpose | Updated By |
|------|---------|------------|
| `ATLAS.md` | Codebase structure overview | `claude-sdk atlas build` |
| `CONTRACT.md` | Permissions and boundaries | Human |
| `DECISIONS.md` | Architecture decisions | Human + Agent |
| `INVARIANTS.md` | Safety constraints | Human |
| `TASKS.md` | Work tracking | Human + Agent |

## Skills Included

| Skill | Description |
|-------|-------------|
| `spec-generator` | Create structured specs and PRDs |
| `code-review` | Risk-aware code review |
| `debugging-playbook` | Systematic debugging approaches |
| `repo-atlas` | Build and maintain codebase atlas |
| `search-helper` | Grep-oriented code navigation |

## Subagents Included

| Agent | Role | Tools |
|-------|------|-------|
| `planner` | Task decomposition | Read, Search |
| `reviewer` | Risk-focused review | Read, Search |
| `indexer` | Atlas maintenance | Read, Search, Write to .claude-sdk/ |

## CLI Commands

```bash
claude-sdk init               # Initialize project (creates CLAUDE.md + memory)
claude-sdk atlas build        # Build repo atlas
claude-sdk atlas refresh      # Incremental update
claude-sdk atlas status       # Check freshness
claude-sdk doctor             # Validate installation
claude-sdk install --global   # Install SDK globally
claude-sdk uninstall          # Remove installation
```

## Deployment Options

### For Teams

1. **Include in your repo**: Commit `.claude-sdk/` and `CLAUDE.md` to version control
2. **Share templates**: Customize `CONTRACT.md` and `INVARIANTS.md` for your team's standards
3. **CI integration**: Run `claude-sdk atlas status` to catch stale indexes

### For Distribution

1. **GitHub**: Publish the SDK repo, users clone and run `install.sh`
2. **Plugin Marketplace**: Skills available via Claude Code plugin system
3. **npm** (coming soon): `npx claude-code-sdk init`

## Documentation

- [Quickstart](docs/QUICKSTART.md) - Get started in 5 minutes
- [CLI Reference](docs/CLI.md) - Full command documentation
- [Atlas Guide](docs/ATLAS.md) - Understanding the Repo Atlas
- [Customization](docs/CUSTOMIZATION.md) - Configure for your project

## Design Principles

1. **Agent-aware**: CLAUDE.md gives agents instructions automatically
2. **Repo-owned**: All artifacts in version control, not hidden indexes
3. **Human-readable**: Plain markdown, grep-friendly format
4. **Safe by default**: Backups, invariants, protected paths
5. **Session-resilient**: Memory survives context loss

## Requirements

- macOS or Linux
- Bash 4.0+
- jq (recommended)
- git (for atlas freshness tracking)

## License

Apache 2.0
