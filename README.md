# Rimecraft

> 霜凝成形，精心打造的 AI 协作工具集。

Claude Code plugin for project lifecycle management and AI-assisted development workflows.

## What's inside

### Skills

| Name | Description |
| ---- | ----------- |
| [rime-init](skills/rime-init/) | 项目初创 + 旧项目迁移（scaffolding / 工具链配置） |
| [rime-flow](skills/rime-flow/) | 日常生命周期管理（task 状态流转 / phase 管理） |
| [rime-css](skills/rime-css/) | CSS 架构方法论（CUBE CSS / BEM / Tailwind） |

### Commands

| Name | Description |
| ---- | ----------- |
| [rime-backlog](commands/rime-backlog.md) | 快速添加任务到 .rime/tasks.json |
| [rime-dashboard](commands/rime-dashboard.md) | 打开 .rime/ 数据可视化 dashboard |
| [rime-tweet](commands/rime-tweet.md) | 读取 X/Twitter 推文内容 |

### Hooks

| Event | Description |
| ----- | ----------- |
| SessionStart | 自动注入项目上下文（phase、活跃任务、上次 session 摘要） |
| SessionEnd | 自动总结对话、更新任务状态、记录踩坑点 |

## Ecosystem

rime-craft 与外部 skill 组合使用，各司其职。

| 场景 | rime-craft | 外部 skill |
| ---- | ---------- | ---------- |
| 新项目启动 | `rime-init` scaffolding | — |
| 任务拆分与规划 | `rime-flow` 管理 tasks.json | `superpowers:brainstorming` 产出设计 |
| 执行大型 task | `rime-flow` 状态追踪 | `superpowers:writing-plans` → `executing-plans` |
| 日常开发 | `rime-flow` task 状态流转 | `superpowers:test-driven-development` |
| Code review | `rime-backlog` 转化发现为 task | `superpowers:requesting-code-review` |
| CSS 架构 | `rime-css` 方法论 | `agent-browser` 响应式验证 |
| React 开发 | — | `vercel-react-best-practices` / `react-doctor` |

**核心接口**：`tasks.json` — superpowers 擅长单次 session 深度执行，rime-flow 擅长跨 session 状态追踪。

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

每一个工具都像霜晶一样——轻量、精确、凝结在最需要的地方。

- **Minimal** — Small, focused tools that do one thing well
- **Composable** — Mix and match across different AI assistants
- **Personal** — Opinionated defaults shaped by daily use

## Author

**Bing** — Product Designer & Frontend Developer at [m3.com](https://m3.com)

## License

MIT
