# agent-skills

A suite of modular coding agent skill packages that form a repeatable, durable software development workflow and visual craft standard across AI coding agents.

The suite is organized into **independent, composable packages** that can be installed together or cherry-picked per project:

- **[`dev-workflow`](packages/dev-workflow/)**: The end-to-end software development lifecycle (Spec-Driven Development, Architecture RFCs, ADRs, Design Tokens, 6-Stage Pre-Commit Review, Session Memory, and Loop Recovery).
- **[`frontend-design`](packages/frontend-design/SKILL.md)**: Standalone visual design & UI craft direction (distinctive aesthetic character, fluid scaling across mobile and 4K displays, light/dark mode parity, and anti-AI tropes).
- **[`windows-vm-twin`](packages/windows-vm-twin/SKILL.md)**: Windows VM Configuration Cloning & Twin Generator (100% read-only discovery, IIS sites/AppPools, SMB shares, NTFS ACLs, installed Windows features, IIS 6.0 SMTP, and SMTPSVC auto-restart/recovery actions).

Works out of the box with **Claude Code, Cursor, Gemini CLI, OpenAI Codex CLI, GitHub Copilot, Antigravity**, and any tool that reads markdown instructions or complies with the [Agent Plugins 1.0](https://github.com/agentplugins/agent-plugins-spec) specification.

---

## The Packages

### 1. `dev-workflow` Package

The core engineering lifecycle engine for any project (frontend, backend, fullstack, or CLI):

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
│design-system │  semantic tokens + component inventory contract
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

| Skill | Purpose | Output Location |
|---|---|---|
| [`spec`](packages/dev-workflow/spec/SKILL.md) | Authors feature specifications, PRDs, and checkable acceptance criteria. | `docs/specs/<feature-slug>.md` |
| [`architect`](packages/dev-workflow/architect/SKILL.md) | Designs system architecture, module boundaries, data models, and API contracts. | `docs/architecture/system-overview.md` & `docs/adr/` |
| [`design-system`](packages/dev-workflow/design-system/SKILL.md) | Standardizes semantic design tokens and a component inventory contract. | `docs/architecture/design-system.md` + code tokens |
| [`review`](packages/dev-workflow/review/SKILL.md) | Audits pending diffs against specs, architecture, duplication, and tokens before commit. | Formatted pre-commit audit report |
| [`remember`](packages/dev-workflow/remember/SKILL.md) | Writes Architectural Decision Records (ADRs), curates gotchas, and formats handoffs/PRs. | `docs/adr/YYYY-MM-DD-*.md`, `docs/learnings.md`, `docs/handoff.md` |
| [`recover`](packages/dev-workflow/recover/SKILL.md) | Loop-breaker circuit breaker: clears workspace debris, audits assumptions vs evidence. | Minimal reproduction & diagnosis |

---

### 2. `frontend-design` Package

A standalone creative director skill for high-craft user interfaces:

| Skill | Purpose | Target Use Cases |
|---|---|---|
| [`frontend-design`](packages/frontend-design/SKILL.md) | Distinctive visual craft, fluid 4K/mobile spatial scaling, light/dark theme parity, anti-AI tropes. | Designing UI pages, styling components, theming, interactive layouts |

#### Key Capabilities of `frontend-design`:
- **Large Monitor & 4K Scaling**: Uses fluid `clamp()` sizing so text and controls scale proportionally rather than rendering as tiny 14px islands. Expands layouts progressively into multi-column grids instead of leaving vast empty dead space.
- **Mobile Responsiveness**: Strictly prevents horizontal overflow (`overflow-x: clip`, `box-sizing: border-box`), enforces $\ge 44\text{px}$ touch targets, and converts desktop drawers into mobile bottom sheets.
- **Light & Dark Theme Parity**: Multi-layered depth in light mode (tinted canvases, soft diffuse shadows, crisp hairline borders) so light themes look just as rich and polished as dark themes.
- **Strict Anti-AI Tropes**: Bans generic purple-on-dark glows, unneeded `01/02/03` numbered pills, icon-stuffed bento clutter, and robotic corporate copy.

---

### 3. `windows-vm-twin` Package

A Windows-specific configuration cloning and twin provisioning engine:

| Skill | Purpose | Output Location |
|---|---|---|
| [`windows-vm-twin`](packages/windows-vm-twin/SKILL.md) | 100% read-only discovery, deterministic JSON manifests, target provisioning engine, and drift verification. | `VM-Twin-Export/` & `VM-Twin-Blueprint/` |

#### Key Capabilities of `windows-vm-twin`:
- **Zero-Mutation Source Discovery**: 100% read-only discovery using safe PowerShell cmdlets, ADSI readers, and `sc.exe qfailure`. No writes or service changes on the source VM.
- **Complete Subsystem Coverage**: IIS 7+ Sites, AppPools (identities, recycling, 32-bit), SMB Network Shares, NTFS ACLs (SDDL fidelity), IIS 6.0 SMTP Server (`SmtpSvc/1` metabase & relay lists), and SMTPSVC auto-restart/recovery actions on failure.
- **Automated & Manual Replay**: Includes parameterized target templates (`twin-parameters.json`) and automated replay scripts (`Apply-TargetVmTwin.ps1`) for AI agents or systems engineers.
- **Drift & Parity Audit**: Automated post-migration verification (`Test-TargetVmTwin.ps1`) generating a markdown scorecard.

---

## Installation & Setup

### Option 1: Universal CLI Installer (`install.sh`)

Clone this repo and install any package or individual skill:

```bash
git clone https://github.com/spencer-voorhees/agent-skills
cd your-project

# Install everything (dev-workflow + frontend-design + windows-vm-twin) and scaffold docs/:
path/to/agent-skills/install.sh agents . all --init-docs

# Or install only windows-vm-twin:
path/to/agent-skills/install.sh agents . windows-vm-twin

# Or install only frontend-design:
path/to/agent-skills/install.sh agents . frontend-design

# Or install only dev-workflow:
path/to/agent-skills/install.sh agents . dev-workflow
```

| Flavor | Target Tool | Destination |
|---|---|---|
| `agents` *(default)* | Universal (Cursor, Gemini CLI, Antigravity, etc.) | `.agents/skills/` |
| `claude` | Claude Code | `.claude/skills/` |
| `cursor` | Cursor | `.cursor/skills/` |
| `gemini` | Gemini CLI | `.gemini/skills/` |
| `codex` | OpenAI Codex CLI | `.codex/skills/` |
| `copilot` | GitHub Copilot | `.github/skills/` |
| `agentsmd` | Fallback for any agent reading `AGENTS.md` | Appends trigger rules to `AGENTS.md` |

---

### Option 2: Claude Code Plugin Marketplace

Install directly as a plugin without cloning or vendoring files:

```bash
/plugin marketplace add spencer-voorhees/agent-skills

# Install the packages you need:
/plugin install dev-workflow@agent-skills
/plugin install frontend-design@agent-skills
/plugin install windows-vm-twin@agent-skills
```

---

### Option 3: Universal `AGENTS.md` / `.cursorrules`

For tools that read instruction files, append [`templates/agents-md-snippet.md`](templates/agents-md-snippet.md) to your project's `AGENTS.md` or `.cursorrules`.

---

## The Docs-as-Code Repository Layout

When `dev-workflow` is installed, the project uses this git-safe structure:

```
docs/
├── specs/                          # Feature Specs / PRDs (owned by spec)
│   ├── _template.md
│   └── 2026-08-oauth-login.md
├── architecture/                   # System Blueprints & Contracts
│   ├── system-overview.md          # Stack, modules, API strategy (owned by architect)
│   └── design-system.md            # Semantic tokens & component inventory (owned by design-system)
├── adr/                            # Architectural Decision Records (one file per decision)
│   ├── 0000-template.md
│   ├── 0001-stack-selection.md     # (owned by architect and remember)
│   └── 0002-sqlite-single-user.md
├── learnings.md                    # Curated gotchas & team runbook (15-minute rule)
└── handoff.md                      # Active session handoff (git-ignored)
```

- **Zero Git Merge Conflicts**: Discrete ADR files in `docs/adr/` and feature specs in `docs/specs/` merge seamlessly across concurrent PRs.
- **Git Safety**: `docs/handoff.md` is automatically ignored in `.gitignore` so local session continuity never pollutes the git history of `main`.
- **Union Merge Drivers**: Pre-configured `.gitattributes` automatically merges concurrent log appends without conflict markers.
