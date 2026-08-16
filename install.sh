#!/usr/bin/env bash
# Install agent skills into a project by package or individual skill.
#
# Usage:
#   ./install.sh [flavor] [target-dir] [package-or-skill] [--init-docs]
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
#   all               Installs both dev-workflow and frontend-design
#   dev-workflow      Installs the 6 lifecycle skills (spec, architect, design-system, review, remember, recover)
#   frontend-design   Installs the standalone visual design & UI craft skill
#   <skill-name>      Installs any individual skill by name (e.g. spec, review, frontend-design)
#
# Options:
#   --init-docs       Scaffolds standard docs/ (specs, architecture, adr), .gitattributes, and .gitignore
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
FLAVOR="agents"
TARGET="."
PACKAGE="all"
INIT_DOCS=false

POSITIONAL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --init-docs)
      INIT_DOCS=true
      ;;
    -h|--help|help)
      sed -n '2,22p' "$0"; exit 0
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

  install_skill_dir() {
    local skill_src="$1"
    local skill_name="$2"
    rm -rf "${TARGET:?}/$DEST/$skill_name"
    mkdir -p "$TARGET/$DEST/$skill_name"
    if [ -f "$skill_src/SKILL.md" ]; then
      cp "$skill_src/SKILL.md" "$TARGET/$DEST/$skill_name/SKILL.md"
    fi
    count=$((count + 1))
  }

  case "$PACKAGE" in
    all)
      # Install dev-workflow skills
      for skill in "$SRC"/packages/dev-workflow/*/; do
        if [ -d "$skill" ]; then
          name="$(basename "$skill")"
          install_skill_dir "$skill" "$name"
        fi
      done
      # Install frontend-design
      if [ -d "$SRC/packages/frontend-design" ]; then
        install_skill_dir "$SRC/packages/frontend-design" "frontend-design"
      fi
      ;;
    dev-workflow|workflow)
      for skill in "$SRC"/packages/dev-workflow/*/; do
        if [ -d "$skill" ]; then
          name="$(basename "$skill")"
          install_skill_dir "$skill" "$name"
        fi
      done
      ;;
    frontend-design|frontend)
      if [ -d "$SRC/packages/frontend-design" ]; then
        install_skill_dir "$SRC/packages/frontend-design" "frontend-design"
      fi
      ;;
    *)
      # Check if individual skill in dev-workflow
      if [ -d "$SRC/packages/dev-workflow/$PACKAGE" ]; then
        install_skill_dir "$SRC/packages/dev-workflow/$PACKAGE" "$PACKAGE"
      elif [ "$PACKAGE" = "frontend-design" ] && [ -d "$SRC/packages/frontend-design" ]; then
        install_skill_dir "$SRC/packages/frontend-design" "frontend-design"
      else
        echo "error: unknown package or skill '$PACKAGE'" >&2
        exit 1
      fi
      ;;
  esac

  echo "✔ Installed $count skill(s) ($PACKAGE) to $TARGET/$DEST/"
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
