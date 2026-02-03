# CLI Reference

Complete reference for the `claude-sdk` command-line interface.

## Global Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-v, --version` | Show version |
| `--dry-run` | Preview without making changes |

## Commands

### install

Install the SDK globally or to a project.

```bash
claude-sdk install [options]
```

**Options:**
- `--global` - Install to `~/.claude` (user-level)
- `--project` - Install to current project's `.claude-sdk/`
- `--force` - Overwrite existing files (creates backups)
- `--dry-run` - Preview changes

**Examples:**
```bash
# Global installation
claude-sdk install --global

# Project installation
claude-sdk install --project

# Preview what would be installed
claude-sdk install --project --dry-run

# Reinstall with backups
claude-sdk install --global --force
```

**What gets installed:**
- Skills (5 engineering skills)
- Subagents (3 agent configurations)
- Templates (atlas, memory file templates)
- Scripts (atlas generator, drift detector)

---

### uninstall

Remove SDK installation.

```bash
claude-sdk uninstall [options]
```

**Options:**
- `--global` - Uninstall from `~/.claude`
- `--project` - Uninstall from current project
- `--restore` - Restore backed-up files
- `--keep-memory` - Keep memory files (DECISIONS, TASKS, etc.)
- `--dry-run` - Preview changes

**Examples:**
```bash
# Uninstall from project
claude-sdk uninstall --project

# Uninstall and restore original settings
claude-sdk uninstall --global --restore

# Uninstall but keep memory
claude-sdk uninstall --project --keep-memory
```

---

### doctor

Validate installation and configuration.

```bash
claude-sdk doctor [options]
```

**Options:**
- `--global` - Check global installation
- `--project` - Check project installation
- `--verbose` - Show detailed results

**Examples:**
```bash
# Check both global and project
claude-sdk doctor

# Verbose project check
claude-sdk doctor --project --verbose
```

**Checks performed:**
- Manifest file exists
- Skills installed correctly
- Subagents installed correctly
- Templates available
- Memory files initialized
- System dependencies (jq, git)

---

### init

Initialize memory files in current project.

```bash
claude-sdk init [options]
```

**Options:**
- `--all` - Initialize everything (default)
- `--atlas` - Atlas structure only
- `--memory` - Memory files only
- `--contract` - Contract file only
- `--force` - Overwrite existing files
- `--dry-run` - Preview changes

**Examples:**
```bash
# Initialize all memory files
claude-sdk init

# Initialize only memory files
claude-sdk init --memory

# Preview what would be created
claude-sdk init --dry-run
```

**Files created:**
- `.claude-sdk/ATLAS.md` - Repo atlas (placeholder)
- `.claude-sdk/CONTRACT.md` - Agent contract
- `.claude-sdk/memory/DECISIONS.md` - ADR file
- `.claude-sdk/memory/INVARIANTS.md` - Invariants registry
- `.claude-sdk/memory/TASKS.md` - Task tracking

---

### atlas

Manage the Repo Atlas.

```bash
claude-sdk atlas <subcommand> [options]
```

#### atlas build

Build or rebuild the atlas.

```bash
claude-sdk atlas build [options]
```

**Options:**
- `--full` - Full rebuild (ignore cache)
- `--folder PATH` - Build specific folder only
- `--config FILE` - Use custom config
- `--dry-run` - Preview changes

**Examples:**
```bash
# Build full atlas
claude-sdk atlas build

# Rebuild specific folder
claude-sdk atlas build --folder src/api

# Full rebuild
claude-sdk atlas build --full
```

#### atlas refresh

Incrementally update changed folders.

```bash
claude-sdk atlas refresh
```

Uses git history to identify changed folders and updates only those.

#### atlas status

Show atlas status and freshness.

```bash
claude-sdk atlas status
```

Shows:
- Last build time
- Build commit vs current commit
- Number of folder atlases
- Drift warnings

#### atlas clean

Remove atlas files.

```bash
claude-sdk atlas clean
```

Removes `ATLAS.md` and `atlas/` directory.

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAUDE_HOME` | Claude config directory | `~/.claude` |
| `DEBUG` | Enable debug output | `0` |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |
| `2` | Warning (non-fatal) |

## Configuration Files

### Manifest

Location: `~/.claude/.sdk-manifest.json` (global) or `.claude-sdk/.manifest.json` (project)

Tracks installed files for clean uninstallation.

### Atlas Config

Location: `.claude-sdk/atlas.config`

Configure atlas generation (folders, patterns, exclusions).
