# Rimecraft — Product Requirements Document

## 概述

个人 AI 协作工具集。统一管理 skills、commands、hooks 等资产，各项目通过 plugin 安装引用。
目标：让 aiflow 可复用、可迭代、可追溯。

## 核心理念

- **轻量** — 纯文本，零依赖，plugin install 即用
- **可组合** — 每个 skill/command 独立，按需组合
- **单一来源** — 所有工具集中在此仓库，其他项目通过 plugin 引用
- **自动化** — hooks 实现 session 接续、状态追踪等自动化流程

## 用户画像

个人开发者，日常使用 Claude Code 进行 AI 辅助开发。需要跨项目复用 AI 协作规则、工作流模板和自动化脚本，避免每个项目重复配置。

## 核心流程

```
# 其他项目安装 rime-craft plugin
claude mcp add-from-claude-plugin rime-craft

# 使用 skill
/rime-flow         ← 项目文档与生命周期管理
/rime-css          ← CSS 架构方法论
/rime-backlog      ← 快速添加 backlog 条目
/rime-dashboard    ← 数据可视化

# hooks 自动触发
SessionStart → 注入上次 session context
SessionEnd   → 提取 cautions、生成 anchor
```

## 功能规划

> 任务状态由 `.rime/tasks.json` 管理。
> 已完成阶段归档至 [archive.md](archive.md)。

### 后续方向

- skill 间依赖管理和版本兼容性
- plugin marketplace 自动发布 CI
- 更多 skill 开发（git-commit、agent-browser 等已由外部 plugin 覆盖）

## 不做的事

- 不做 CLI 工具 / npm 包，保持纯文本 + 轻量脚本
- 不管理第三方 skill（agent-browser、vercel-* 等留在原位）
- 不替代 CLAUDE.md 全局配置

## 相关文档

| 文档 | 内容 |
|------|------|
| .rime/tasks.json | 任务状态（source of truth） |
| archive.md | 已完成阶段归档 |
| docs/superpowers/ | 设计文档和实施计划 |
