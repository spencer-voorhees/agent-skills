<!--
Append this section to the AGENTS.md of any project where you want the
workflow, then set SKILLS_PATH to wherever the skills live relative to the
project root (e.g. `vendor/agent-skills/skills` if you vendored this repo,
or an absolute path to a clone).

  cat scaffolds/agents-md-snippet.md >> /path/to/project/AGENTS.md

Agents that read AGENTS.md (Codex, Cursor, Gemini CLI, Amp, and others)
will pick these rules up automatically. Agents with native SKILL.md
support (e.g. Claude Code) don't need this snippet — they trigger skills
from the frontmatter descriptions directly (see README).
-->

## Development workflow skills

This project uses a skill-driven development workflow.
Each skill is a markdown instruction file; when a trigger below matches the
task at hand, read the skill file completely and follow it. The skills share
one contract: `docs/` is the durable source of truth (Specs, Architecture,
ADRs, Design Tokens), kept currently-true and git-safe for multi-dev teams.

Set `SKILLS_PATH` = `<SKILLS_PATH>` (adjust to this project's layout).

| When | Read and follow |
|---|---|
| Delivering a substantial change through the full workflow | `SKILLS_PATH/deliver-change/SKILL.md` |
| Defining or clarifying requirements, scope, acceptance criteria, constraints, or non-goals | `SKILLS_PATH/write-spec/SKILL.md` |
| Designing architecture, module boundaries, schema, APIs, migrations, or a technical RFC | `SKILLS_PATH/design-architecture/SKILL.md` |
| Designing visual identity, high-craft UI layouts, mobile & 4K display scaling, light/dark parity | `SKILLS_PATH/frontend-design/SKILL.md` |
| Establishing or evolving tokens, themes, reusable components, variants, or component inventory | `SKILLS_PATH/maintain-design-system/SKILL.md` |
| Implementing an approved feature, bug fix, or refactor from clear requirements | `SKILLS_PATH/implement-spec/SKILL.md` |
| Reviewing a diff, pull request, or completed change for correctness and readiness | `SKILLS_PATH/review-code/SKILL.md` |
| Recording an ADR, expensive learning, checkpoint, or handoff | `SKILLS_PATH/capture-decisions/SKILL.md` |
| The same error has survived repeated attempts, progress has stalled, or systematic diagnosis is needed | `SKILLS_PATH/debug-systematically/SKILL.md` |

Session habits, always in force:

- At session start, check `docs/handoff.md` (if present) and skim recent ADRs in `docs/adr/`.
- Never guess on architecture or tokens — follow `docs/architecture/` and use defined design tokens.
- Use `review-code` when an independent readiness assessment is requested.
- Use `capture-decisions` selectively for durable decisions, costly learnings, or an actual handoff.
