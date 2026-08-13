# agent-skills

A suite of agent skills that form a repeatable development workflow, usable
by any coding agent that can read a markdown file. The core idea: agent
sessions are ephemeral, so the workflow revolves around a durable **context
package** — a `docs/context/` directory of markdown files that every skill
reads from and writes back to. Sessions come and go; the context compounds.

Each skill is a plain-markdown `SKILL.md`: instructions plus a name and a
"when to use" description in frontmatter. Nothing in the skills assumes a
particular agent, model, or vendor — an agent just needs to read the file
and follow it. Because all durable state lives in the target project's
`docs/context/`, the workflow is also agent-interoperable: one session can
end in one tool and the next can resume from the handoff file in another.

## The workflow

```
┌─────────────────┐
│ context-package │  capture what, who, why, constraints
└────────┬────────┘
         ▼
┌─────────────────┐
│    architect    │  stack, modules, data model, API strategy
└────────┬────────┘
         ▼
┌─────────────────┐
│  design-system  │  tokens + component inventory (for UI projects)
└────────┬────────┘
         ▼
   build a milestone ──▶ ┌──────────┐
         │               │  review  │  check the diff against the context
         │               └──────────┘
         ▼
┌─────────────────┐
│    remember     │  persist decisions, learnings, handoff state
└─────────────────┘
         │
         ▼  next session picks up 90-handoff.md and continues

  (recover — any time an agent is stuck in a loop)
```

## The skills

| Skill | What it does |
|---|---|
| [`context-package`](skills/context-package/SKILL.md) | Builds the source-of-truth markdown files: brief, requirements, constraints. |
| [`architect`](skills/architect/SKILL.md) | Designs the technical architecture from the context package — so the API strategy is never undefined. |
| [`design-system`](skills/design-system/SKILL.md) | Creates semantic tokens and a component inventory — so buttons never drift. |
| [`review`](skills/review/SKILL.md) | Reviews diffs against the context: correctness, requirement alignment, architecture drift, duplication, token violations. |
| [`remember`](skills/remember/SKILL.md) | Writes session decisions, learnings, and working state back into the package — so context survives between sessions. |
| [`recover`](skills/recover/SKILL.md) | Breaks stuck loops: halt, audit assumptions against evidence, re-ground in context, pick a discriminating next step. |

## The context package contract

All skills share one on-disk contract in the target project:

```
docs/context/
├── 00-brief.md          # what, who, why, success criteria      (context-package)
├── 10-requirements.md   # features, acceptance criteria         (context-package)
├── 20-constraints.md    # stack constraints, non-goals          (context-package)
├── 30-architecture.md   # stack, modules, data, API strategy    (architect)
├── 40-design-system.md  # tokens, scales, component inventory   (design-system)
├── 50-decisions.md      # append-only decision log              (any skill appends)
├── 60-learnings.md      # curated gotchas & conventions         (remember)
└── 90-handoff.md        # current working state, next steps     (remember)
```

Each file has one owning skill (the decision log accepts appends from all
of them); every skill may read all of them. The
package must always read as *currently true* — history lives in the
decision log, not in stale sections.

## Using the skills

`SKILL.md` is now a cross-agent standard: the major tools all read the same
format, each from its own directory. This repo is also a valid
[Agent Plugins 1.0](https://github.com/agentplugins/agent-plugins-spec)
package (`plugin.json` + `skills/`), the vendor-neutral format backed by
Amazon, Cursor, Google, Microsoft, OpenAI, and Vercel — clients that
support it can install the repo directly.

For everything else, `install.sh` copies the skills into the directory
your tool reads:

```bash
git clone https://github.com/spencer-voorhees/agent-skills
cd your-project
path/to/agent-skills/install.sh <flavor>
```

| Flavor | Tool | Installs to |
|---|---|---|
| `agents` (default) | vendor-neutral — read by Cursor, Gemini CLI, and others | `.agents/skills/` |
| `claude` | Claude Code | `.claude/skills/` |
| `codex` | OpenAI Codex CLI | `.codex/skills/` |
| `gemini` | Gemini CLI | `.gemini/skills/` |
| `copilot` | GitHub Copilot | `.github/skills/` |
| `cursor` | Cursor | `.cursor/skills/` |
| `agentsmd` | anything that reads `AGENTS.md` | appends the trigger snippet |

The files are identical in every flavor — only the location differs. In
all the skill-aware tools, triggering is automatic from the frontmatter
descriptions.

Extras for specific tools:

- **Claude Code** can alternatively install via its plugin system
  (`/plugin marketplace add spencer-voorhees/agent-skills`, then
  `/plugin install dev-workflow@agent-skills`) — that's what
  `.claude-plugin/` is for.
- **Cursor** also reads `.agents/`, `.claude/`, and `.codex/` skill
  directories, so any of those installs covers it too.
- **Agents without skill support**: the `agentsmd` flavor appends
  [`templates/agents-md-snippet.md`](templates/agents-md-snippet.md) to
  your `AGENTS.md` — a table mapping each trigger ("before any commit…",
  "when stuck…") to the skill file to read, plus the session habits. The
  same content works in any other rules mechanism.
- **Zero setup**, works with any agent at all: point it at a skill
  directly — *"Read agent-skills/skills/architect/SKILL.md and follow it."*

## A typical project, day by day

1. **Day 1**: `context-package` interviews you and writes the brief,
   requirements, and constraints. `architect` turns those into a buildable
   plan with milestones. For UI projects, `design-system` locks in tokens.
2. **Build sessions**: each session reads `90-handoff.md`, builds the next
   milestone, runs `review` on the diff before committing, and ends with
   `remember`.
3. **When things go sideways**: `recover` stops the flailing, audits
   assumptions, and either finds the false belief or escalates to you with
   a real diagnosis instead of "I'm stuck".

Commit `docs/context/` changes together with the code they describe — the
package is only trustworthy if it moves in lockstep with the repo.
