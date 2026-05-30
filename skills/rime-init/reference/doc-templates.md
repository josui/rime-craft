# 文档模板

每种文档的模板和写法要点。按需查阅对应文件。

## 通用文档

| 模板 | 说明 |
|------|------|
| [template-prd.md](template-prd.md) | PRD — 当前阶段需求、编号追踪 |
| [template-backlog.md](template-backlog.md) | Backlog — 改善点和 Feature Ideas 池 |
| [template-archive.md](template-archive.md) | Archive — 已完成功能归档 |
| [template-cautions.md](template-cautions.md) | 踩坑记录、关键约束 |

## 开发项目追加

| 模板 | 说明 |
|------|------|
| [template-techstack.md](template-techstack.md) | 技术选型、项目结构、阶段计划 |
| [template-interaction.md](template-interaction.md) | 交互设计、页面状态、操作流程 |
| [template-schema.md](template-schema.md) | 数据结构定义 |

## 设计阶段（spec）

medium / large 任务 grill 收敛后产出 spec，固化决策 + 理由 + 边界：

| 格式 | 说明 |
|------|------|
| Markdown（自由格式） | 非 UI spec —— 决策记录 + 交互 + 边界，放 `docs/.../specs/*.md` |
| [template-spec.html](template-spec.html) | UI spec —— sidebar 编号导航 + 决策表 + phone/desktop 双 mock 框，dashboard `/file` 原生渲染 |
