#!/usr/bin/env bash
# Install the dev-workflow skills into a project, for any agent flavor.
#
#   ./install.sh [flavor] [target-project-dir]
#
# flavor (default: agents):
#   agents    .agents/skills/      vendor-neutral; read by Cursor, Gemini CLI, and others
#   claude    .claude/skills/      Claude Code
#   codex     .codex/skills/       OpenAI Codex CLI
#   gemini    .gemini/skills/      Gemini CLI
#   copilot   .github/skills/      GitHub Copilot
#   cursor    .cursor/skills/      Cursor
#   agentsmd  AGENTS.md            appends the trigger-table snippet (for agents
#                                  without SKILL.md support)
#
# The SKILL.md files are identical for every flavor — only the directory the
# tool reads from differs.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
FLAVOR="${1:-agents}"
TARGET="${2:-.}"

if [ ! -d "$SRC/skills" ]; then
  echo "error: no skills/ directory next to install.sh" >&2
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
    echo "Appended workflow snippet to $TARGET/AGENTS.md"
    echo "Now edit it and replace <SKILLS_PATH> with the path to the skills"
    echo "(e.g. $SRC/skills, or wherever you vendor them)."
    exit 0
    ;;
  -h|--help|help)
    sed -n '2,17p' "$0"; exit 0 ;;
  *)
    echo "error: unknown flavor '$FLAVOR' (agents|claude|codex|gemini|copilot|cursor|agentsmd)" >&2
    exit 1
    ;;
esac

mkdir -p "$TARGET/$DEST"
count=0
for skill in "$SRC"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "${TARGET:?}/$DEST/$name"
  cp -R "$skill" "$TARGET/$DEST/$name"
  count=$((count + 1))
done

echo "Installed $count skills to $TARGET/$DEST/"
