# agent-skills

A suite of agent skills that form a repeatable development workflow — for
Claude Code, Codex, Cursor, Gemini CLI, or any coding agent that can read a
markdown file. The core idea: agent sessions are ephemeral, so the workflow
revolves around a durable **context package** — a `docs/context/` directory
of markdown files that every skill reads from and writes back to. Sessions
come and go; the context compounds.

Each skill is a plain-markdown `SKILL.md` (instructions plus a name and a
"when to use" description in frontmatter). Nothing in the skill bodies
assumes a particular agent, model, or vendor — an agent just needs to read
the file and follow it.

## The workflow

```
┌──────────────────┐
│ /context-package │  capture what, who, why, constraints
└────────┬─────────┘
         ▼
┌──────────────────┐
│    /architect    │  stack, modules, data model, API strategy
└────────┬─────────┘
         ▼
┌──────────────────┐
│  /design-system  │  tokens + component inventory (for UI projects)
└────────┬─────────┘
         ▼
   build a milestone ──▶ ┌───────────┐
         │               │  /review  │  check the diff against the context
         │               └───────────┘
         ▼
┌──────────────────┐
│    /remember     │  persist decisions, learnings, handoff state
└──────────────────┘
         │
         ▼  next session picks up 90-handoff.md and continues

  (/recover — any time an agent is stuck in a loop)
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

## Installation

### Claude Code

As a plugin (recommended — gets all six skills at once, with automatic
triggering):

```
/plugin marketplace add spencer-voorhees/agent-skills
/plugin install dev-workflow@agent-skills
```

Or copy individual skills into a project (`.claude/skills/`) or your user
profile (`~/.claude/skills/`):

```bash
cp -r skills/architect /path/to/project/.claude/skills/
```

### Any other agent (Codex, Cursor, Gemini CLI, Amp, …)

The skills are plain markdown, so the only thing to wire up is *triggering*
— telling your agent when to go read which skill. For agents that read
`AGENTS.md` (most do), vendor or clone this repo somewhere your agent can
reach, then append the provided snippet to the project's `AGENTS.md` and
set the path inside it:

```bash
git clone https://github.com/spencer-voorhees/agent-skills vendor/agent-skills
cat vendor/agent-skills/templates/agents-md-snippet.md >> AGENTS.md
```

The snippet maps each trigger ("before any commit…", "when stuck…") to the
skill file to read, and adds the session habits (read the handoff file at
session start, run remember at session end).

For agents with their own rules mechanism (e.g. Cursor rules), the same
snippet content works there. And with any agent at all, zero setup also
works: point it at a skill directly — *"Read vendor/agent-skills/skills/architect/SKILL.md
and follow it."*

## A typical project, day by day

1. **Day 1**: `/context-package` interviews you and writes the brief,
   requirements, and constraints. `/architect` turns those into a buildable
   plan with milestones. For UI projects, `/design-system` locks in tokens.
2. **Build sessions**: each session reads `90-handoff.md`, builds the next
   milestone, runs `/review` on the diff before committing, and ends with
   `/remember`.
3. **When things go sideways**: `/recover` stops the flailing, audits
   assumptions, and either finds the false belief or escalates to you with
   a real diagnosis instead of "I'm stuck".
