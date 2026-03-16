# AGENTS.md

## 项目性质

Claude Code plugin，提供项目生命周期管理（rimeflow skill）、session 自动接续（hooks）、和辅助工具（commands）。

## 目录结构

```
.claude-plugin/  → Plugin manifest
skills/          → Claude Code skill（每个子目录含 SKILL.md）
commands/        → Claude Code slash command（单文件 .md）
hooks/           → Hook 脚本（session 生命周期自动化）
  hooks.json     → Hook 事件定义
  scripts/       → Hook 脚本实现
.rime/           → 本项目自身的结构化数据（tasks.json 等）
docs/            → 规划文档（PRD、调研、计划）
```

## 工作规则

- 这是内容仓库，改动以文本编辑为主
- `docs/` 不入库（在 `.gitignore` 中）
- `.rime/anchors/` 不入库（在 `.gitignore` 中）
- `.rime/tasks.json`、`.rime/phase.json`、`.rime/cautions.json` 入库
- `docs/plans/` 放临时计划，完成后可清理
- `docs/researches/` 放调研记录
- Hook 脚本修改后需要测试：`echo '{"cwd":"..."}' | bash hooks/scripts/session-start.sh`

## 安装方式

作为 plugin 安装到其他项目：
- 开发测试：`claude --plugin-dir /path/to/rime-craft`
- 正式安装：通过 marketplace

## Git

- 用户要求时才 commit
- 禁止 co-authored-by
