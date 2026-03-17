---
name: rime-init
description: 项目初创 + 旧项目迁移。创建 .rime/ 数据层、docs/ 文档骨架、AGENTS.md，配置开发工具链。触发场景：初始化新项目、迁移旧格式项目。
---

# 项目初创与迁移

新项目初始化或旧项目迁移到 rime 工作流。日常管理请使用 `rime-flow`。

---

## 场景 A：初创项目

项目刚建立，需要搭建文档骨架和 AI 协作规则。

### A1. 判断项目类型

| 类型 | 特征 | 示例 |
|------|------|------|
| 开发项目 | 有代码构建、依赖管理、技术栈 | Web app、CLI 工具、库 |
| 内容项目 | 以文本/配置为主，无构建流程 | 工具集、文档站、prompt 仓库 |

后续步骤根据类型有所不同，标注 `[开发]` 的步骤内容项目跳过。

### A2. 创建 AGENTS.md

项目根目录，定义 AI 协作规则。

- 模板和字段说明 → [reference/agents-md.md](reference/agents-md.md)
- 询问用户是否入库（入库 = 团队共享；加入 `.gitignore` = 不公开）
- 创建后不在日常中修改，除非协作规则本身需要调整

### A3. 配置 .gitignore

确保包含：
- `.worktrees/`
- `.rime/`（数据层默认不入库，用户可覆盖）
- `docs/`（文档层默认不入库，用户可覆盖）

`.rime/` 和 `docs/` 深度绑定，入库策略应保持一致。

### A4. 创建 .rime/ 数据层

项目根目录创建结构化数据目录：

```
.rime/
├── tasks.json      ← 任务状态 source of truth
├── phase.json      ← 当前阶段信息
├── cautions.json   ← 踩坑记录（append-only）
└── anchors/        ← session 记录（自动生成，gitignore）
```

初始文件模板 → [reference/template-tasks-json.md](reference/template-tasks-json.md)

### A5. 创建 docs/ 文档骨架

根据项目规模和类型选择需要的文档。

**通用文档：**

| 文档 | 内容 | 适用 |
|------|------|------|
| prd | 产品定位、目标、功能规划（叙事） | 所有项目 |
| archive | 已完成阶段的叙事归档 | 所有项目 |

**开发项目追加：**

| 文档 | 内容 | 优先级 |
|------|------|--------|
| techstack | 技术选型、项目结构、阶段计划 | 推荐 |
| interaction | 交互设计、页面状态、操作流程 | 中型以上 |
| schema | 数据结构定义 | 中型以上 |

文件命名 `{project}-{type}.md`。模板 → [reference/doc-templates.md](reference/doc-templates.md)

**PRD 优先**：先写 PRD 再动手。

### A6. 配置开发工具链 `[开发]`

前端 / Node.js 项目适用。Go、Swift 等非 JS/TS 项目跳过。

详细配置流程 → [reference/dev-tooling.md](reference/dev-tooling.md)

**代码质量工具：**

| 工具 | 用途 | 优先级 |
|------|------|--------|
| Prettier | 代码格式化 | 必选 |
| ESLint | 代码质量检查 | 必选 |
| Husky | Git hooks 管理 | 必选 |
| lint-staged | 暂存文件检查 | 必选 |
| EditorConfig | 编辑器配置统一 | 推荐 |
| commitlint | 提交信息规范 | 可选 |

配置文件模板在 `assets/` 目录。

**组件库选型（有 UI 需求时）：**

询问用户是否需要组件库，常见选项：

| 库 | 特点 | 适用场景 |
|------|------|----------|
| shadcn/ui | 复制源码、可完全自定义、Tailwind | 需要高度定制的项目 |
| Radix UI | 无样式 primitives、Accessibility 优先 | 自己写样式、重视 a11y |
| Base UI | MUI 团队出品、无样式、hooks 驱动 | 需要底层控制 |
| coss ui | 复制源码、Tailwind、轻量 | shadcn 替代方案 |

不需要组件库时跳过。选定后记录到 `techstack.md`。

### A7. 创建 README.md

面向用户，入库。

---

## 场景 C：迁移旧项目

对已在使用旧版 rime-flow（markdown 表格管理状态）的项目执行一次性迁移。

### 判断是否需要迁移

检查是否存在以下旧格式：
- `backlog.md` 含状态表格（`❌` / `✅`）
- `prd.md` 含功能需求状态表格
- 无 `.rime/` 目录

### 迁移流程

1. **备份**：将 `prd.md`、`backlog.md`、`archive.md`、`cautions.md` 复制到 `docs/.migration-backup/`
2. **提取 items**：扫描所有文档中的 `#xxx` 条目 → 生成 `tasks.json`
   - archive 里的 → `status: done`
   - prd 里 ✅ 的 → `status: done`
   - prd 里 ❌ 的 → `status: doing`
   - backlog 里的 → `status: todo`
3. **创建 phase.json**：从 prd 的 P0/P1 标题推断阶段信息
4. **转换 cautions**：如有 cautions.md → 转换为 `cautions.json`
5. **重写 prd.md**：保留叙事部分，表格替换为引用列表
6. **重写 archive.md**：表格替换为阶段叙事
7. **删除废弃文件**：`backlog.md`、`cautions.md`
8. **创建 `.rime/` 结构**：目录 + `anchors/`
9. **更新 .gitignore**：添加 `.rime/` 和 `docs/`（默认不入库）

由 AI 执行，每步确认。迁移完成后确认无误再删除 `docs/.migration-backup/`。

---

## 初创完成后

项目初创完成后，日常管理（任务状态更新、阶段归档、文档维护）由 `rime-flow` skill 自动接管。
