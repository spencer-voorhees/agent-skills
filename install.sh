#!/usr/bin/env bash
# Install the dev-workflow skills and optional Docs-as-Code scaffold into a project.
#
# Usage:
#   ./install.sh [flavor] [target-project-dir] [--init-docs]
#
# Flavors (default: agents):
#   agents      .agents/skills/      Vendor-neutral (Cursor, Gemini CLI, and others)
#   claude      .claude/skills/      Claude Code
#   codex       .codex/skills/       OpenAI Codex CLI
#   gemini      .gemini/skills/      Gemini CLI
#   copilot     .github/skills/      GitHub Copilot
#   cursor      .cursor/skills/      Cursor
#   agentsmd    AGENTS.md            Appends trigger-table snippet (for agents without native SKILL.md)
#
# Options:
#   --init-docs                      Scaffolds standard docs/ (specs, architecture, adr) and .gitattributes
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
FLAVOR="agents"
TARGET="."
INIT_DOCS=false

for arg in "$@"; do
  case "$arg" in
    --init-docs)
      INIT_DOCS=true
      ;;
    -h|--help|help)
      sed -n '2,18p' "$0"; exit 0
      ;;
    *)
      if [ -z "${FLAVOR_SET:-}" ]; then
        FLAVOR="$arg"
        FLAVOR_SET=true
      elif [ -z "${TARGET_SET:-}" ]; then
        TARGET="$arg"
        TARGET_SET=true
      fi
      ;;
  esac
done

if [ ! -d "$SRC/skills" ]; then
  echo "error: no skills/ directory found next to install.sh" >&2
  exit 1
fi

case "$FLAVOR" in
  agents)  DEST=".agents/skills" ;;
  claude)  DEST=".claude/skills" ;;
  codex)   DEST=".codex/skills" ;;
  gemini)  DEST=".gemini/skills" ;;
  copilot) DEST=".github/skills" ;;
  cursor)  DEST=".cursor/skills" ;;
  agentsmd)
    mkdir -p "$TARGET"
    cat "$SRC/templates/agents-md-snippet.md" >> "$TARGET/AGENTS.md"
    echo "✔ Appended workflow snippet to $TARGET/AGENTS.md"
    echo "  (Edit AGENTS.md and replace <SKILLS_PATH> with the path to your vendored skills directory)."
    DEST=""
    ;;
  *)
    echo "error: unknown flavor '$FLAVOR' (agents|claude|codex|gemini|copilot|cursor|agentsmd)" >&2
    exit 1
    ;;
esac

if [ -n "$DEST" ]; then
  mkdir -p "$TARGET/$DEST"
  count=0
  for skill in "$SRC"/skills/*/; do
    name="$(basename "$skill")"
    rm -rf "${TARGET:?}/$DEST/$name"
    cp -R "$skill" "$TARGET/$DEST/$name"
    count=$((count + 1))
  done
  echo "✔ Installed $count skills to $TARGET/$DEST/"
fi

if [ "$INIT_DOCS" = true ]; then
  mkdir -p "$TARGET/docs/specs" "$TARGET/docs/architecture" "$TARGET/docs/adr"
  
  if [ ! -f "$TARGET/docs/specs/_template.md" ]; then
    cp "$SRC/templates/docs-skeleton/specs/_template.md" "$TARGET/docs/specs/_template.md"
  fi
  if [ ! -f "$TARGET/docs/architecture/system-overview.md" ]; then
    cp "$SRC/templates/docs-skeleton/architecture/system-overview.md" "$TARGET/docs/architecture/system-overview.md"
  fi
  if [ ! -f "$TARGET/docs/adr/0000-template.md" ]; then
    cp "$SRC/templates/docs-skeleton/adr/0000-template.md" "$TARGET/docs/adr/0000-template.md"
  fi
  if [ ! -f "$TARGET/docs/learnings.md" ]; then
    cp "$SRC/templates/docs-skeleton/learnings.md" "$TARGET/docs/learnings.md"
  fi
  
  if [ -f "$SRC/templates/gitattributes-snippet.txt" ]; then
    cat "$SRC/templates/gitattributes-snippet.txt" >> "$TARGET/.gitattributes"
    echo "✔ Configured .gitattributes union merge drivers for docs"
  fi
  if [ -f "$SRC/templates/gitignore-snippet.txt" ]; then
    cat "$SRC/templates/gitignore-snippet.txt" >> "$TARGET/.gitignore"
    echo "✔ Added docs/handoff.md to .gitignore"
  fi
  echo "✔ Scaffolded standard Docs-as-Code structure in $TARGET/docs/"
fi
