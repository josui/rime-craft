---
name: rime-init
description: Use when initializing a new project or migrating an old project to the rime workflow. New-project scaffolding + legacy migration — create the .rime/ data layer, docs/ skeleton, and AGENTS.md, and configure the dev toolchain. Triggers: initializing a new project, migrating a legacy-format project.
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

### A2. 创建 AGENTS.md + CLAUDE.md

项目根目录，定义 AI 协作规则。完整生成指南和模板 → [reference/agents-md.md](reference/agents-md.md)

流程：

1. **前置检测**：检测 rime 工作流依赖的外部 skill 是否安装，未安装则提醒（不阻断，详见 [reference/agents-md.md](reference/agents-md.md) 的前置检测）
2. **入库选择**：询问用户（入库 = 团队共享；加入 `.gitignore` = 不公开）
3. **可选交互**：一次展示语言设置（AI 沟通 / 代码注释 / UI 文案）+ 验证方式，用户逐一回答或跳过
4. **技术栈 Skill 自动映射** `[开发]`：扫描 package.json + 配置文件，自动写入对应 skill 规则
5. **生成 AGENTS.md**：固定内容 + 用户选择/检测结果的动态内容
6. **CLAUDE.md 桥接**：Claude Code 只读 `CLAUDE.md` 不读 `AGENTS.md`，必须建桥。无 `CLAUDE.md` → 新建含一行 `@AGENTS.md`；已有 → 顶部去重追加（不动原内容）。详见 [reference/agents-md.md](reference/agents-md.md)

创建后不在日常中修改，除非协作规则本身需要调整

### A3. 配置 .gitignore

确保包含：
- `.worktrees/`
- `.rime/`（**必须**，不由用户覆盖）
- `docs/`（文档层默认不入库，用户可覆盖）

`.rime/` 的不入库是**硬要求**：它是项目全局的可变状态，入库会导致 `.rime/*.json` 合并冲突、worktree 拿到陈旧快照，以及**切分支时状态无声漂移**（在 feature 分支标 done，切回 main 又变回 doing）。权威说明见 rime-flow 的 [data-contract.md](../rime-flow/data-contract.md)「存储位置与解析顺序」。

`docs/` 的入库策略与 `.rime/` **无关**，各自独立决定——`.rime/` 是可变状态，`docs/`（spec / prd）是文档产物。

`CLAUDE.md` 跟随 `AGENTS.md` 的入库决定（同入库或同 gitignore）：若 AGENTS.md 进 `.gitignore` 而 CLAUDE.md 入库，协作者 clone 后 `@AGENTS.md` 会断链。

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
| DESIGN.md | 设计系统（token + rationale，[google-labs/design.md](https://github.com/google-labs-code/design.md) 格式） | 有 UI 的项目 |

文件命名 `{project}-{type}.md`。例外：`DESIGN.md` 采用 [google-labs/design.md](https://github.com/google-labs-code/design.md) 标准格式名，不加 project prefix。模板 → [reference/doc-templates.md](reference/doc-templates.md)（DESIGN.md 的模板与生成流程在 `rime-design` skill）

> DESIGN.md 是团队共享的设计契约。若 `docs/` 默认进 `.gitignore`（见 A3），有团队协作时建议单独 `git add -f docs/DESIGN.md` 或将其移出忽略范围，否则协作者 clone 后拿不到设计系统。

**PRD 优先**：先写 PRD 再动手。

创建文档后，将「文档地图」写入 AGENTS.md 底部（仅列实际创建的文档）。详见 [reference/agents-md.md](reference/agents-md.md)

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
9. **更新 .gitignore**：添加 `.rime/`（必须，见 A3）和 `docs/`（默认不入库）。若旧项目已把 `.rime/` 入库，追加 `git rm -r --cached .rime` 取消跟踪（文件留在原地，无需移动）

由 AI 执行，每步确认。迁移完成后确认无误再删除 `docs/.migration-backup/`。

---

## 初创完成后

项目初创完成后，日常管理（任务状态更新、阶段归档、文档维护）由 `rime-flow` skill 自动接管。
