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
└── templates/
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

# Install all skills and optionally initialize the docs-as-code templates
path/to/agent-skills/install.sh codex . all --init-docs
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

The installer copies each skill's `SKILL.md` and any `agents/`, `assets/`,
`references/`, `scripts/`, or `templates/` resources.

## Claude Code marketplace

```bash
/plugin marketplace add spencer-voorhees/agent-skills
/plugin install engineering-workflow@agent-skills
```

## Optional docs-as-code layout

`--init-docs` can initialize this convention when the user explicitly wants it:

```text
docs/
├── specs/
├── architecture/
├── adr/
└── learnings.md
```

Existing repositories keep their established requirements, architecture, and decision
locations; the skills should discover and preserve those conventions.
