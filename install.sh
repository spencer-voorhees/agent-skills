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
#   all                         Installs every package
#   engineering-workflow        Installs all 9 workflow skills
#   scandipwa-hyva-migration    Installs the migration skill
#   <skill-name>                Installs one skill (e.g. write-spec, migrate-scandipwa-to-hyva)
#
# Options:
#   --force           Replaces an already-installed skill directory
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_DIR="$SRC/packages/engineering-workflow"
MIGRATION_DIR="$SRC/packages/scandipwa-hyva-migration"
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
      sed -n '2,26p' "$0"; exit 0
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

append_agents_snippet() {
  local snippet="$1"
  local heading="$2"
  local label="$3"
  if [ -f "$TARGET/AGENTS.md" ] && grep -Fq "$heading" "$TARGET/AGENTS.md"; then
    echo "✔ $label snippet already present in $TARGET/AGENTS.md"
  else
    cat "$snippet" >> "$TARGET/AGENTS.md"
    echo "✔ Appended $label snippet to $TARGET/AGENTS.md"
  fi
}

case "$FLAVOR" in
  agents|antigravity|agy) DEST=".agents/skills" ;;
  claude)                 DEST=".claude/skills" ;;
  codex)                  DEST=".codex/skills" ;;
  gemini)                 DEST=".gemini/skills" ;;
  copilot)                DEST=".github/skills" ;;
  cursor)                 DEST=".cursor/skills" ;;
  agentsmd)
    mkdir -p "$TARGET"
    case "$PACKAGE" in
      all)
        append_agents_snippet "$WORKFLOW_DIR/scaffolds/agents-md-snippet.md" "## Development workflow skills" "workflow"
        append_agents_snippet "$MIGRATION_DIR/scaffolds/agents-md-snippet.md" "## ScandiPWA-to-Hyvä migration skill" "migration"
        ;;
      engineering-workflow|workflow)
        append_agents_snippet "$WORKFLOW_DIR/scaffolds/agents-md-snippet.md" "## Development workflow skills" "workflow"
        ;;
      scandipwa-hyva-migration|migration|migrate-scandipwa-to-hyva)
        append_agents_snippet "$MIGRATION_DIR/scaffolds/agents-md-snippet.md" "## ScandiPWA-to-Hyvä migration skill" "migration"
        ;;
      *)
        if [ -d "$WORKFLOW_DIR/skills/$PACKAGE" ]; then
          append_agents_snippet "$WORKFLOW_DIR/scaffolds/agents-md-snippet.md" "## Development workflow skills" "workflow"
        elif [ -d "$MIGRATION_DIR/skills/$PACKAGE" ]; then
          append_agents_snippet "$MIGRATION_DIR/scaffolds/agents-md-snippet.md" "## ScandiPWA-to-Hyvä migration skill" "migration"
        else
          echo "error: unknown package or skill '$PACKAGE'" >&2
          exit 1
        fi
        ;;
    esac
    echo "  (Edit AGENTS.md and replace the path placeholder(s) for the selected package)."
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

  install_package_skills() {
    local package_dir="$1"
    for skill in "$package_dir"/skills/*/; do
      if [ -d "$skill" ]; then
        local name
        name="$(basename "$skill")"
        install_skill_dir "$skill" "$name"
      fi
    done
  }

  case "$PACKAGE" in
    all)
      install_package_skills "$WORKFLOW_DIR"
      install_package_skills "$MIGRATION_DIR"
      ;;
    engineering-workflow|workflow)
      install_package_skills "$WORKFLOW_DIR"
      ;;
    scandipwa-hyva-migration|migration)
      install_package_skills "$MIGRATION_DIR"
      ;;
    *)
      skill_matches=()
      for package_dir in "$SRC"/packages/*; do
        candidate="$package_dir/skills/$PACKAGE"
        if [ -d "$candidate" ]; then
          skill_matches+=("$candidate")
        fi
      done
      if [ ${#skill_matches[@]} -eq 1 ]; then
        install_skill_dir "${skill_matches[0]}" "$PACKAGE"
      elif [ ${#skill_matches[@]} -gt 1 ]; then
        echo "error: skill '$PACKAGE' exists in multiple packages; install a package explicitly" >&2
        exit 1
      else
        echo "error: unknown package or skill '$PACKAGE'" >&2
        exit 1
      fi
      ;;
  esac

  echo "✔ Installed $count skill(s) ($PACKAGE) to $TARGET/$DEST/"
fi
