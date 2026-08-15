# agent-skills

A suite of vendor-neutral agent skills that form a repeatable, durable software development workflow across AI coding agents. 

The workflow is built on three practical principles:
1. **Spec-Driven Development**: Requirements, user stories (`R1..Rn`), and checkable acceptance criteria are defined before implementation begins.
2. **Docs-as-Code & ADRs**: Technical designs and architectural decisions live in the repository as discrete, version-controlled markdown documents (Architectural Decision Records).
3. **Multi-Developer & Git-Safe**: Context is organized into discrete files per feature and decision, ensuring multiple engineers and autonomous agents can work and merge PRs concurrently with **zero git merge conflicts**.

Each skill is a standalone `SKILL.md` with YAML frontmatter conforming to the [Agent Plugins 1.0](https://github.com/agentplugins/agent-plugins-spec) specification. Works out-of-the-box with **Claude Code, Cursor, Gemini CLI, OpenAI Codex CLI, GitHub Copilot, Antigravity**, and any tool that reads markdown instructions.

---

## The Workflow

```
┌──────────────┐
│     spec     │  PRD, user stories (R1, R2), checkable acceptance criteria
└──────┬───────┘
       ▼
┌──────────────┐
│  architect   │  system RFC, module boundaries, API strategy, initial ADRs
└──────┬───────┘
       ▼
┌──────────────┐
│design-system │  W3C semantic tokens + component inventory (for UI)
└──────┬───────┘
       ▼
  build milestone ──▶ ┌──────────┐
       │              │  review  │  6-stage audit: correctness, spec alignment,
       │              └──────────┘  arch drift, duplication, tokens, tests
       ▼
┌──────────────┐
│   remember   │  record ADRs, curate runbook, generate handoff / PR draft
└──────────────┘
       │
       ▼  next session or reviewer picks up handoff / PR description

  (recover — triggered automatically when stuck in a debugging loop)
```

---

## The Skills

| Skill | Purpose | Output Location |
|---|---|---|
| [`spec`](skills/spec/SKILL.md) | Authors feature specifications, PRDs, and checkable acceptance criteria. | `docs/specs/<feature-slug>.md` |
| [`architect`](skills/architect/SKILL.md) | Designs system architecture, module boundaries, data models, and API contracts. | `docs/architecture/system-overview.md` & `docs/adr/` |
| [`design-system`](skills/design-system/SKILL.md) | Creates semantic design tokens and a component inventory. | `docs/architecture/design-system.md` + code tokens |
| [`review`](skills/review/SKILL.md) | Audits pending diffs against specs, architecture, duplication, and tokens before commit. | Formatted pre-commit audit report |
| [`remember`](skills/remember/SKILL.md) | Writes Architectural Decision Records (ADRs), curates gotchas, and formats handoffs/PRs. | `docs/adr/YYYY-MM-DD-*.md`, `docs/learnings.md`, `docs/handoff.md` |
| [`recover`](skills/recover/SKILL.md) | Loop-breaker circuit breaker: clears workspace debris, audits assumptions vs evidence. | Minimal reproduction & diagnosis |

---

## The Docs-as-Code Repository Layout

The skills enforce this standard layout in target projects:

```
docs/
├── specs/                          # Feature Specs / PRDs (owned by spec)
│   ├── _template.md
│   └── 2026-08-oauth-login.md
├── architecture/                   # System Blueprints & Contracts
│   ├── system-overview.md          # Stack, modules, API strategy (owned by architect)
│   └── design-system.md            # Semantic tokens & component inventory (owned by design-system)
├── adr/                            # Architectural Decision Records (MADR standard)
│   ├── 0000-template.md
│   ├── 0001-stack-selection.md     # (owned by architect and remember)
│   └── 0002-sqlite-single-user.md
├── learnings.md                    # Curated gotchas & team runbook (15-minute rule)
└── handoff.md                      # Active session handoff (git-ignored / branch-scoped)
```

### Why This Prevents Merge Conflicts
- **Discrete Decision Files (`docs/adr/`)**: Each decision is its own immutable file. Two developers creating decisions on different branches never collide at EOF.
- **Feature-Scoped Specs (`docs/specs/`)**: Parallel feature branches maintain their own spec documents.
- **Isolated Handoffs (`docs/handoff.md`)**: Handoffs are kept local or used as PR bodies, keeping the `main` branch git history clean.
- **Union Merge Drivers**: Pre-configured `.gitattributes` automatically merges concurrent log appends.

---

## Installation & Setup

### Option 1: Fast Install via `install.sh`

Clone this repo and install the skills directly into your project:

```bash
git clone https://github.com/spencer-voorhees/agent-skills
cd your-project

# Install skills and scaffold the standard docs/ directory
path/to/agent-skills/install.sh <flavor> . --init-docs
```

| Flavor | Target Agent / Tool | Destination |
|---|---|---|
| `agents` *(default)* | Universal (Cursor, Gemini CLI, etc.) | `.agents/skills/` |
| `claude` | Claude Code | `.claude/skills/` |
| `cursor` | Cursor | `.cursor/skills/` |
| `gemini` | Gemini CLI | `.gemini/skills/` |
| `codex` | OpenAI Codex CLI | `.codex/skills/` |
| `copilot` | GitHub Copilot | `.github/skills/` |
| `agentsmd` | Fallback for any agent reading `AGENTS.md` | Appends trigger rules to `AGENTS.md` |

---

### Option 2: Claude Code Plugin Marketplace

For Claude Code, install directly as a plugin without vendoring files:

```bash
/plugin marketplace add spencer-voorhees/agent-skills
/plugin install dev-workflow@agent-skills
```

---

### Option 3: Universal `AGENTS.md` / `.cursorrules`

For tools that read instruction files, append [`templates/agents-md-snippet.md`](templates/agents-md-snippet.md) to your project's `AGENTS.md` or `.cursorrules`.

---

## A Typical Project Lifecycle

1. **Feature Kickoff**: `spec` scopes requirements into `docs/specs/<feature>.md` with numbered user stories (`R1`, `R2`) and checkable acceptance criteria.
2. **Technical Design**: `architect` creates `docs/architecture/system-overview.md` (defining module boundaries and API contracts) and logs contested choices in `docs/adr/`.
3. **UI Foundations (if UI)**: `design-system` produces `docs/architecture/design-system.md` and generates live semantic tokens (e.g. `src/styles/tokens.css`).
4. **Milestone Implementation**: Implementation sessions build each milestone against the spec.
5. **Pre-Commit Audit**: `review` audits `git diff` against acceptance criteria, architecture, duplication, and design tokens before any commit.
6. **Session Checkpoint**: `remember` writes any new architectural decisions to `docs/adr/`, records gotchas in `docs/learnings.md`, and generates a PR description.
7. **When Stuck**: If an agent loops $\ge 3$ times, `recover` halts thrashing, cleans speculative workspace edits, and audits assumptions against direct evidence.
