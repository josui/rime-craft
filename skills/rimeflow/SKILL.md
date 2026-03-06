---
name: rimeflow
description: 项目文档与产品生命周期管理。初创项目时创建文档骨架（PRD/backlog/archive）、AGENTS.md；开发项目额外配置工具链。过程中管理 backlog → PRD → archive 流转。触发场景：初始化项目、创建/更新文档、backlog 管理、阶段归档。
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

确保包含 `.worktrees/`。
`docs/` 是否入库由用户决定（默认不入库）。

### A4. 创建 docs/ 文档骨架

根据项目规模和类型选择需要的文档。

**通用文档：**

| 文档 | 内容 | 适用 |
|------|------|------|
| prd | 需求、目标、当前阶段需求（带编号） | 所有项目 |
| backlog | 待评估的改善点和 Feature Ideas | 所有项目 |
| archive | 已完成功能归档 | 所有项目 |
| cautions | 踩坑记录、关键约束 | 所有项目 |

**开发项目追加：**

| 文档 | 内容 | 优先级 |
|------|------|--------|
| techstack | 技术选型、项目结构、阶段计划 | 推荐 |
| interaction | 交互设计、页面状态、操作流程 | 中型以上 |
| schema | 数据结构定义 | 中型以上 |

文件命名 `{project}-{type}.md`。模板 → [reference/doc-templates.md](reference/doc-templates.md)

**PRD 优先**：先写 PRD 再动手。

### A5. 配置开发工具链 `[开发]`

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

### A6. 创建 README.md

面向用户，入库。

---

## 场景 B：过程中更新文档

不涉及 AGENTS.md 修改。

### 什么时候更新

| 时机 | 更新内容 |
|------|----------|
| 完成一项工作 | PRD 状态 ❌ → ✅，完成整个阶段后移入 archive |
| 发现改善点 / 新想法 | 追加到 backlog（用 `/add-backlog` command 快速添加） |
| 阶段完成，开始下一阶段 | 已完成阶段整体移入 archive，PRD 只保留当前阶段 |
| 踩坑 / 发现关键约束 | 追加到 cautions.md（编号小节） |
| 新增依赖 / 改技术选型 `[开发]` | 更新 techstack.md |
| 交互行为变更 `[开发]` | 更新 interaction.md 对应章节 |
| 数据结构变更 `[开发]` | 更新 schema.md |
| 用户说"更新文档" | 更新 README.md + docs/ 根目录核心文档（不含子目录） |

### 文档生命周期

```
想法/发现 → backlog（/add-backlog 快速添加）
    ↓ 评估后纳入
backlog → PRD 当前阶段（分配编号、开始实施）
    ↓ 完成
PRD → archive（阶段性归档）
```

**三个文档的职责：**

| 文档 | 职责 | 内容 |
|------|------|------|
| **prd** | 当前阶段的活跃需求 | 只保留正在做和即将做的 |
| **backlog** | 待评估的池子 | 改善点、Feature Ideas、从 PRD 降级的需求 |
| **archive** | 已完成的记录 | 从 PRD 归档的已完成功能 |

### 编号规则

所有功能项使用**全局递增编号** `#001`、`#002`...，跨文档唯一：

- archive 中的已完成项保留原编号
- PRD 当前阶段的项延续编号
- backlog 新增项取最大编号 +1
- 项从 backlog 提升到 PRD 时保留原编号

### 怎么更新

- **就地更新**，不另建文件。文档是活的，保持单一来源
- **PRD 状态追踪**：做完改 ✅，新需求加行，砍掉的加到"不做的事"
- **backlog 管理**：用 `/add-backlog` command 快速添加，定期评估优先级后纳入 PRD
- **archive 归档**：整个阶段完成后，将该阶段从 PRD 移入 archive
- **cautions.md 只追加**：新坑新编号，格式：问题 → 解决方案 → 参考文件
- **techstack.md Phase checklist** `[开发]`：完成项打 `[x]`，新阶段直接追加
- 调研内容放 `docs/researches/`，设计内容放 `docs/designs/`，不放根目录
- 详细仕様放 `docs/product/`，PRD 保持概要级别并链接过去

### docs/ 目录规则

- `docs/` 默认在 `.gitignore` 中不入库（用户可覆盖）
- 根目录放核心文档（prd, backlog, archive, cautions, techstack 等）
- 子目录名用**复数形式**（researches, designs, plans）
- `plans/` 仅放临时计划
- `product/` 放详细仕様書（复杂功能的讨论结果）
