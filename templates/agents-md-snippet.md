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

This project uses a skill-driven workflow. Each skill is a markdown
instruction file; when a trigger below matches the task at hand, read the
skill file completely and follow it. The skills share one contract: the
`docs/context/` directory is the durable source of truth, and it must
always be kept currently-true.

Set `SKILLS_PATH` = `<SKILLS_PATH>` (adjust to this project's layout).

| When | Read and follow |
|---|---|
| Starting a project/feature; writing a brief, PRD, or requirements; no `docs/context/` exists yet | `SKILLS_PATH/context-package/SKILL.md` |
| Choosing the stack, designing the API or data model, planning the technical approach — before implementing anything major | `SKILLS_PATH/architect/SKILL.md` |
| Building or styling UI, adding components, theming, or when colors/spacing/buttons have drifted | `SKILLS_PATH/design-system/SKILL.md` |
| Before any commit, PR, or merge; after finishing a milestone; the user asks for a review | `SKILLS_PATH/review/SKILL.md` |
| Ending a working session, "wrap up" / "checkpoint", after a significant decision or hard-won discovery | `SKILLS_PATH/remember/SKILL.md` |
| The same error has survived ~3 fix attempts, progress has stalled, or the user says you're stuck or going in circles | `SKILLS_PATH/recover/SKILL.md` |

Session habits, always in force:

- At session start, read `docs/context/90-handoff.md` (if it exists) before
  doing anything else, and skim the rest of `docs/context/`.
- At session end, run the remember skill — unwritten context dies with the
  session.
- Commit `docs/context/` changes together with the code they describe.
