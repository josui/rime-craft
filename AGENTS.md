# AGENTS.md

## 项目性质

纯文本仓库，存放 AI 协作工具（skills、commands）和 aiflow 规划文档。
无代码构建、无依赖、无 dev server。

## 目录结构

```
skills/          → Claude Code skill（每个子目录含 SKILL.md）
commands/        → Claude Code slash command（单文件 .md）
docs/            → 规划文档（PRD、调研、计划）
```

## 工作规则

- 这是内容仓库，改动以文本编辑为主
- `docs/` 不入库（在 `.gitignore` 中）
- `docs/plans/` 放临时计划，完成后可清理
- `docs/researches/` 放调研记录
- Skill / command 修改后在其他项目中通过软链生效，注意兼容性

## Git

- 用户要求时才 commit
- 禁止 co-authored-by
