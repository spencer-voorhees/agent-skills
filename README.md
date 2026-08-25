# agent-skills

A package of composable skills for coding agents to deliver engineering changes from
requirements through implementation, review, and durable documentation.

## Engineering workflow

The repository currently contains one package:

```text
packages/engineering-workflow/
├── .claude-plugin/
├── skills/
│   ├── deliver-change/
│   ├── write-spec/
│   ├── design-architecture/
│   ├── frontend-design/
│   ├── maintain-design-system/
│   ├── implement-spec/
│   ├── review-code/
│   ├── capture-decisions/
│   └── debug-systematically/
└── scaffolds/
    └── agents-md-snippet.md
```

| Skill | Purpose |
|---|---|
| [`deliver-change`](packages/engineering-workflow/skills/deliver-change/SKILL.md) | Selects and coordinates the minimum useful end-to-end workflow for a substantial change. |
| [`write-spec`](packages/engineering-workflow/skills/write-spec/SKILL.md) | Produces bounded requirements, acceptance criteria, constraints, non-goals, and open questions. |
| [`design-architecture`](packages/engineering-workflow/skills/design-architecture/SKILL.md) | Designs consequential system boundaries, data, APIs, migrations, risks, testing strategy, and implementation slices. |
| [`frontend-design`](packages/engineering-workflow/skills/frontend-design/SKILL.md) | Gives a new or substantially revised interface a brief-specific visual and interaction direction. |
| [`maintain-design-system`](packages/engineering-workflow/skills/maintain-design-system/SKILL.md) | Discovers and evolves tokens, themes, reusable components, variants, DTCG sources, and optional Storybook catalogs. |
| [`implement-spec`](packages/engineering-workflow/skills/implement-spec/SKILL.md) | Implements a scoped change, reuses established patterns, adds proportionate tests, and verifies the result. |
| [`review-code`](packages/engineering-workflow/skills/review-code/SKILL.md) | Performs a read-only, evidence-based review of a specified change. |
| [`capture-decisions`](packages/engineering-workflow/skills/capture-decisions/SKILL.md) | Selectively records ADRs, costly learnings, and handoff context. |
| [`debug-systematically`](packages/engineering-workflow/skills/debug-systematically/SKILL.md) | Breaks persistent debugging loops through verified assumptions and discriminating experiments. |

`deliver-change` does not require every stage. A clear local fix may need only
implementation and verification; a greenfield feature may use the complete sequence.

## Frontend-design resources

`frontend-design` keeps brief inference, design direction, system fit, and critique in
its main workflow, then routes to focused references for:

- Accessibility and reduced-motion behavior
- Responsive decisions for wide, dense, and multi-column layouts
- Loading, empty, error, partial, and async interaction states
- Screenshot-based visual verification and refinement

Its creative-direction approach is inspired by Anthropic's
[`frontend-design`](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design/skills/frontend-design)
skill. Its audit modes, variance/motion/density calibration, and preflight concepts also
draw from [`taste-skill`](https://github.com/Leonxlnx/taste-skill), adapted here as
qualitative and framework-neutral guidance.

## Design-system resources

`maintain-design-system` includes optional resources for:

- A design-system overview and ownership contract
- A reusable component inventory and gap log
- A DTCG-compatible starter token source
- Portable design-token adoption guidance
- Storybook component-state guidance and a CSF example

These resources standardize the logical contract without imposing one universal source
layout or migrating an existing token system unnecessarily.

## Installation

Clone the repository, then install the package or one skill into a project:

```bash
# Install all workflow skills for Codex
path/to/agent-skills/install.sh codex . engineering-workflow

# Install one skill
path/to/agent-skills/install.sh codex . review-code

# Install all skills
path/to/agent-skills/install.sh codex . all
```

| Flavor | Destination |
|---|---|
| `agents` | `.agents/skills/` |
| `claude` | `.claude/skills/` |
| `codex` | `.codex/skills/` |
| `cursor` | `.cursor/skills/` |
| `gemini` | `.gemini/skills/` |
| `copilot` | `.github/skills/` |
| `agentsmd` | Appends the packaged trigger table to `AGENTS.md` |

The installer copies each skill's `SKILL.md` and any skill-local `agents/`, `assets/`,
`references/`, `scripts/`, or `templates/` resources. The package-level `scaffolds/`
directory contains only the optional AGENTS routing snippet.

## Claude Code marketplace

```bash
/plugin marketplace add spencer-voorhees/agent-skills
/plugin install engineering-workflow@agent-skills
```

The skills discover and preserve each repository's established requirements,
architecture, decision, and handoff conventions rather than scaffolding a universal
documentation layout. Installing the package does not configure artifact destinations.
When no explicit path, repository instruction, or unambiguous convention exists, a skill
asks before persisting a requested document or returns the result without adding a file.
