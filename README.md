# Rimecraft

> Frost crystallizing into form — a carefully crafted AI-collaboration toolkit.

Claude Code plugin for project lifecycle management and AI-assisted development workflows.

## What's inside

### Skills

| Name | Description |
| ---- | ----------- |
| [rime-init](skills/rime-init/) | Project bootstrapping and legacy migration (scaffolding / toolchain setup) |
| [rime-flow](skills/rime-flow/) | Day-to-day lifecycle management (task status transitions / phase management / subagent + model dispatch) |
| [rime-sdd](skills/rime-sdd/) | Subagent orchestration for large tasks (per-task review gate + final whole-branch review) |
| [rime-css](skills/rime-css/) | CSS architecture methodology (CUBE CSS / BEM / Tailwind) |
| [rime-design](skills/rime-design/) | UI design quality enforcement + external design skill routing |
| [rime-scan](skills/rime-scan/) | Extract design language from reference sites/screenshots (programmatic tokens + AI visual analysis) |
| [rime-imagen](skills/rime-imagen/) | Image generation prompt authoring (gpt-image-2 / Nano Banana Pro — outputs prompt text only) |
| [rime-js](skills/rime-js/) | JS/TS general ruleset (21 rules: Type Safety / Module / Error & Async / Performance) |
| [rime-react](skills/rime-react/) | React component development ruleset (21 rules) |

### Commands

| Name | Description |
| ---- | ----------- |
| [rime-backlog](commands/rime-backlog.md) | Quickly add a task to .rime/tasks.json |
| [rime-task](commands/rime-task.md) | Alias of rime-backlog (shorter to type) |
| [rime-dashboard](commands/rime-dashboard.md) | Open the .rime/ data visualization dashboard |
| [rime-git](commands/rime-git.md) | Analyze changes and generate a well-formed commit message (supports multi-commit splitting) |
| [rime-tweet](commands/rime-tweet.md) | Read X/Twitter post content |

### Hooks

| Event | Description |
| ----- | ----------- |
| SessionStart | Automatically inject project context (current phase, active tasks, last session summary) |
| SessionEnd | Automatically summarize the session, update task statuses, and record lessons learned |

## Ecosystem

rime-craft is designed to be combined with external skills, each handling its own domain.

| Scenario | rime-craft | External skill |
| -------- | ---------- | -------------- |
| New project kickoff | `rime-init` scaffolding | — |
| Task design and scoping | `rime-flow` manages tasks.json | `grill-me` / `grill-with-docs` for deep questioning |
| Executing a large task | `rime-flow` status tracking | `rime-sdd` subagent orchestration |
| Test-driven development | `rime-flow` task status transitions | `tdd` red-green cycle |
| Code review | `rime-backlog` converts findings into tasks | `review` dual-axis review (Standards + Spec) |
| CSS architecture | `rime-css` methodology | `agent-browser` responsive verification |
| UI design quality | `rime-design` baseline rules | `impeccable` suite / `emil-design-eng` |
| UI motion / transitions | `rime-design` motion baseline + routing | `transitions-dev` (CSS recipes) / `gsap` (JS timelines, scroll-driven) / `text-to-lottie` (vector) / `emil-design-eng` (decisions & review) |
| Design language extraction | `rime-scan` structured scan JSON | `agent-browser` programmatic extraction + AI visual analysis |
| Image generation prompts | `rime-imagen` authors prompt text | External tools: ChatGPT Web / Gemini / AI Studio (copy and use) |
| JS/TS development | `rime-js` ruleset | `typescript-eslint` |
| React development | `rime-react` ruleset | `react-doctor` |

**Core interface**: `tasks.json` — skills like `grill-me` / `tdd` / `review` excel at deep single-session execution; rime-flow excels at cross-session state tracking; rime-sdd excels at subagent orchestration for large tasks.

## Requirements

- **Node.js 18+** — Required for the dashboard server (`rime-dashboard` command)

## Setup

Install as a Claude Code plugin:

```bash
# 1. Add marketplace
/plugin marketplace add josui/rime-craft

# 2. Install
/plugin install rime-craft@rime-marketplace
```

For development / testing:

```bash
claude --plugin-dir /path/to/rime-craft
```

## Philosophy

Every tool is like a frost crystal — lightweight, precise, and formed exactly where it's needed most.

- **Minimal** — Small, focused tools that do one thing well
- **Composable** — Mix and match across different AI assistants
- **Personal** — Opinionated defaults shaped by daily use

## Author

**Bing** — Product Designer & Frontend Developer at [m3.com](https://m3.com)

## License

MIT
