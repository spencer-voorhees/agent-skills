# agent-skills

A repository of focused skill packages for engineering delivery and Magento storefront
migration.

## Packages

The repository contains two independently installable packages:

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

packages/scandipwa-hyva-migration/
├── .claude-plugin/
├── .codex-plugin/
├── skills/
│   └── migrate-scandipwa-to-hyva/
└── scaffolds/
    └── agents-md-snippet.md
```

### Engineering workflow

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

## ScandiPWA-to-Hyvä migration resources

The separate `scandipwa-hyva-migration` package contains
[`migrate-scandipwa-to-hyva`](packages/scandipwa-hyva-migration/skills/migrate-scandipwa-to-hyva/SKILL.md)
and focused guidance for:

- Preserving and extending an existing rebuild/adapt/omit migration map
- Operating narrowly on one component or broadly across a migration program
- Tracing customer behavior across ScandiPWA, GraphQL, and Magento modules
- Selecting target-native Magento, PHTML, Alpine, Tailwind, and compatibility patterns
- Routing bounded target work to the relevant installed Hyvä AI skills
- Requiring source-versus-target evidence before migration items are complete
- Keeping deployment, traffic cutover, and source retirement outside the skill's scope

## Installation

Clone the repository, then install the package or one skill into a project:

```bash
# Install all workflow skills for Codex
path/to/agent-skills/install.sh codex . engineering-workflow

# Install the ScandiPWA-to-Hyvä migration package
path/to/agent-skills/install.sh codex . scandipwa-hyva-migration

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
| `agentsmd` | Appends the selected package's routing snippet to `AGENTS.md` |

The installer copies each skill's `SKILL.md` and any skill-local `agents/`, `assets/`,
`references/`, `scripts/`, or `templates/` resources. The package-level `scaffolds/`
directory contains only the optional AGENTS routing snippet.

## Claude Code marketplace

```bash
/plugin marketplace add spencer-voorhees/agent-skills
/plugin install engineering-workflow@agent-skills
/plugin install scandipwa-hyva-migration@agent-skills
```

The engineering skills discover and preserve each repository's established requirements,
architecture, decision, and handoff conventions rather than scaffolding a universal
documentation layout. The migration package preserves the project's approved scope map,
supports focused and program-wide implementation, and stops at evidence-backed target
verification. Installing either package does not configure artifact destinations.
