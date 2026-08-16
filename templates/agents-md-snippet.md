<!--
Append this section to the AGENTS.md of any project where you want the
workflow, then set SKILLS_PATH to wherever the skills live relative to the
project root (e.g. `vendor/agent-skills/skills` if you vendored this repo,
or an absolute path to a clone).

  cat templates/agents-md-snippet.md >> /path/to/project/AGENTS.md

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
| Starting a project/feature; writing a spec or PRD; capturing user stories & acceptance criteria | `SKILLS_PATH/spec/SKILL.md` |
| Choosing the stack, designing architecture, module boundaries, schema, API contracts, or system RFCs | `SKILLS_PATH/architect/SKILL.md` |
| Designing visual identity, high-craft UI layouts, mobile & 4K display scaling, light/dark parity | `SKILLS_PATH/frontend-design/SKILL.md` |
| Building/styling UI, semantic tokens, typography/spacing scales, component inventory | `SKILLS_PATH/design-system/SKILL.md` |
| Before any commit, PR, or merge; after finishing a milestone; auditing diffs against specs | `SKILLS_PATH/review/SKILL.md` |
| Ending a session, "wrap up" / "checkpoint", logging an Architectural Decision Record (ADR), recording gotchas | `SKILLS_PATH/remember/SKILL.md` |
| The same error has survived ~3 fix attempts, progress has stalled, or when stuck | `SKILLS_PATH/recover/SKILL.md` |

Session habits, always in force:

- At session start, check `docs/handoff.md` (if present) and skim recent ADRs in `docs/adr/`.
- Never guess on architecture or tokens — follow `docs/architecture/` and use defined design tokens.
- Review diffs (`review`) before committing to maintain acceptance criteria and code quality.
- At session wrap-up, run `remember` to record decisions in `docs/adr/`, gotchas in `docs/learnings.md`, and generate a handoff / PR draft.
