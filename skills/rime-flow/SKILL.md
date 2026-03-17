---
name: rimeflow
description: 项目文档与产品生命周期管理。初创项目时创建文档骨架（PRD/archive）、.rime/ 数据层、AGENTS.md；开发项目额外配置工具链。过程中管理 tasks.json 状态流转（todo → doing → done）和 phase 生命周期。触发场景：初始化项目、创建/更新文档、任务管理、阶段归档、迁移旧项目。
---

# 项目工作流

根据当前场景选择对应流程。

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
- `.rime/anchors/`（session 记录不入库）

`docs/` 是否入库由用户决定（默认不入库）。

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

## 场景 B：过程中更新

不涉及 AGENTS.md 修改。

### 什么时候更新

| 时机 | 更新内容 |
|------|----------|
| 完成一项工作 | 更新 `.rime/tasks.json` 中对应 item/subtask 的 status |
| 发现改善点 / 新想法 | 用 `/rime-backlog` 添加到 tasks.json（status: todo） |
| 阶段完成，开始下一阶段 | 触发 phase 关闭流程（见下方） |
| 新增依赖 / 改技术选型 `[开发]` | 更新 techstack.md |
| 交互行为变更 `[开发]` | 更新 interaction.md 对应章节 |
| 数据结构变更 `[开发]` | 更新 schema.md |
| 用户说"更新文档" | 更新 README.md + docs/ 根目录核心文档（不含子目录） |

### 任务生命周期

```
用户定义功能 → tasks.json (status: todo)
    ↓ AI 开始工作
tasks.json (status: doing, AI 拆出 subtasks)
    ↓ 所有 subtask 完成（SessionEnd hook 自动检测）
tasks.json (status: done)
    ↓ Phase 关闭时
archive.md 写入阶段总结 + tasks.json 回收 done items
```

### 写入约束

**所有路径**（AI 手动更新、`/rime-backlog` command、SessionEnd hook）向 tasks.json 写入 item 时，必须包含以下必填字段：

| 字段 | 格式 | 说明 |
|------|------|------|
| id | `#0001`（4 位补零） | 由 nextId 生成 |
| title | 非空字符串 | — |
| status | `todo` / `doing` / `done` | — |
| priority | `high` / `medium` / `low` | 不确定时询问用户 |
| createdAt | `YYYY-MM-DD` | — |
| phase | `P0`, `P1`, ... | 从 phase.json current 获取 |

缺失必填字段时**中止写入并报错**，不允许写入不完整的 item。

### 文件职责

| 文件 | 职责 | 内容 |
|------|------|------|
| `.rime/tasks.json` | 任务状态 source of truth | todo/doing/done items + subtasks |
| `.rime/phase.json` | 阶段信息 | 当前 phase、历史 phases |
| `.rime/cautions.json` | 踩坑记录 | append-only，SessionEnd hook 自动提取 |
| `.rime/anchors/` | session 记录 | 每次 session 结束自动生成，gitignore |
| `docs/prd.md` | 产品定位和规格 | 叙事文档，用 #ID 引用 tasks.json |
| `docs/archive.md` | 阶段叙事归档 | phase 关闭时写入总结 |

### 编号规则

所有功能项使用**全局递增编号** `#001`、`#002`...：

- 编号由 `tasks.json` 的 `nextId` 自增生成，补零 3 位
- 编号全局唯一，不回收不复用
- 用 `/rime-backlog` 添加新 item 时自动分配编号

### 怎么更新

- **tasks.json 状态更新**：完成 subtask 时标记 `status: "done"`，开始新工作时标记 `status: "doing"`
- **PRD 叙事更新**：功能规划变更时更新引用列表，砍掉的加到"不做的事"
- **archive 归档**：整个 phase 完成后写入阶段总结
- **techstack.md Phase checklist** `[开发]`：完成项打 `[x]`，新阶段直接追加
- 调研内容放 `docs/researches/`，设计内容放 `docs/designs/`，不放根目录
- 详细仕様放 `docs/product/`，PRD 保持概要级别并链接过去

### Phase 关闭流程

当一个 phase 内所有 tasks 的 status 都变为 `done` 时：

1. 提示用户是否关闭该 phase
2. 用户确认后：
   - `phase.json`: 该 phase 的 status → `done`，记录 `completedAt`
   - `archive.md`: 追加阶段叙事总结
   - `tasks.json`: 删除该 phase 中 `status: done` 的 items
   - `anchors/`: 删除旧 anchor 文件，全局只保留最近 10 个
   - `prd.md`: 移除已归档阶段的内容
3. 如需开始新 phase：用户在 prd.md 中定义，AI 同步更新 phase.json

### docs/ 目录规则

- `docs/` 默认在 `.gitignore` 中不入库（用户可覆盖）
- 根目录放核心文档（prd, archive, techstack 等）
- 子目录名用**复数形式**（researches, designs, plans）
- `plans/` 仅放临时计划
- `product/` 放详细仕様書（复杂功能的讨论结果）

---

## 场景 C：迁移旧项目

对已在使用旧版 rimeflow（markdown 表格管理状态）的项目执行一次性迁移。

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
9. **更新 .gitignore**：添加 `.rime/anchors/`

由 AI 执行，每步确认。迁移完成后确认无误再删除 `docs/.migration-backup/`。
