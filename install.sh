#!/usr/bin/env bash
# Install agent skills into a project by package or individual skill.
#
# Usage:
#   ./install.sh [flavor] [target-dir] [package-or-skill] [--force]
#
# Flavors (default: agents):
#   agents      .agents/skills/      Vendor-neutral (Cursor, Gemini CLI, Antigravity, etc.)
#   claude      .claude/skills/      Claude Code
#   codex       .codex/skills/       OpenAI Codex CLI
#   gemini      .gemini/skills/      Gemini CLI
#   copilot     .github/skills/      GitHub Copilot
#   cursor      .cursor/skills/      Cursor
#   agentsmd    AGENTS.md            Appends trigger-table snippet (for agents without native SKILL.md)
#
# Packages / Skills (default: all):
#   all                    Installs the engineering-workflow package
#   engineering-workflow   Installs all 9 workflow skills
#   <skill-name>           Installs an individual skill (e.g. write-spec, review-code)
#
# Options:
#   --force           Replaces an already-installed skill directory
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_DIR="$SRC/packages/engineering-workflow"
FLAVOR="agents"
TARGET="."
PACKAGE="all"
FORCE=false

POSITIONAL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=true
      ;;
    -h|--help|help)
      sed -n '2,24p' "$0"; exit 0
      ;;
    *)
      POSITIONAL_ARGS+=("$arg")
      ;;
  esac
done

if [ ${#POSITIONAL_ARGS[@]} -ge 1 ]; then
  FLAVOR="${POSITIONAL_ARGS[0]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -ge 2 ]; then
  TARGET="${POSITIONAL_ARGS[1]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -ge 3 ]; then
  PACKAGE="${POSITIONAL_ARGS[2]}"
fi

if [ ! -d "$SRC/packages" ]; then
  echo "error: no packages/ directory found next to install.sh" >&2
  exit 1
fi

case "$FLAVOR" in
  agents|antigravity|agy) DEST=".agents/skills" ;;
  claude)                 DEST=".claude/skills" ;;
  codex)                  DEST=".codex/skills" ;;
  gemini)                 DEST=".gemini/skills" ;;
  copilot)                DEST=".github/skills" ;;
  cursor)                 DEST=".cursor/skills" ;;
  agentsmd)
    mkdir -p "$TARGET"
    if [ -f "$TARGET/AGENTS.md" ] && grep -Fq "## Development workflow skills" "$TARGET/AGENTS.md"; then
      echo "✔ Workflow snippet already present in $TARGET/AGENTS.md"
    else
      cat "$WORKFLOW_DIR/scaffolds/agents-md-snippet.md" >> "$TARGET/AGENTS.md"
      echo "✔ Appended workflow snippet to $TARGET/AGENTS.md"
    fi
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

  install_skill_dir() {
    local skill_src="$1"
    local skill_name="$2"
    if [ -e "$TARGET/$DEST/$skill_name" ]; then
      if [ "$FORCE" != true ]; then
        echo "error: $TARGET/$DEST/$skill_name already exists (use --force to replace it)" >&2
        exit 1
      fi
      rm -rf "${TARGET:?}/$DEST/$skill_name"
    fi
    mkdir -p "$TARGET/$DEST/$skill_name"
    if [ -f "$skill_src/SKILL.md" ]; then
      cp "$skill_src/SKILL.md" "$TARGET/$DEST/$skill_name/SKILL.md"
    fi
    for resource_dir in agents assets references scripts templates; do
      if [ -d "$skill_src/$resource_dir" ]; then
        cp -r "$skill_src/$resource_dir" "$TARGET/$DEST/$skill_name/"
      fi
    done
    count=$((count + 1))
  }

  case "$PACKAGE" in
    all)
      for skill in "$WORKFLOW_DIR"/skills/*/; do
        if [ -d "$skill" ]; then
          name="$(basename "$skill")"
          install_skill_dir "$skill" "$name"
        fi
      done
      ;;
    engineering-workflow|workflow)
      for skill in "$WORKFLOW_DIR"/skills/*/; do
        if [ -d "$skill" ]; then
          name="$(basename "$skill")"
          install_skill_dir "$skill" "$name"
        fi
      done
      ;;
    *)
      if [ -d "$WORKFLOW_DIR/skills/$PACKAGE" ]; then
        install_skill_dir "$WORKFLOW_DIR/skills/$PACKAGE" "$PACKAGE"
      else
        echo "error: unknown package or skill '$PACKAGE'" >&2
        exit 1
      fi
      ;;
  esac

  echo "✔ Installed $count skill(s) ($PACKAGE) to $TARGET/$DEST/"
fi
