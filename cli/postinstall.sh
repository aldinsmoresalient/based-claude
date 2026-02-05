#!/usr/bin/env bash
#
# Based Claude - Post-install message
#

# Make binary executable
chmod +x ./bin/claude-sdk 2>/dev/null || true

# Print welcome message
cat << 'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Based Claude - Context-anchored memory for Claude Code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Keeps Claude oriented with three anchors:
  • CLAUDE.md - Auto-loaded atlas with domains & invariants
  • Generated Skills - Domain-specific checklists
  • @claude Headers - Blast radius tracking (USED_BY)

  Learn more: https://github.com/aldinsmoresalient/based-claude

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
