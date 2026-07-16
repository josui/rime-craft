---
name: rime-flow
description: Use when starting or executing a task from tasks.json, updating task status, closing a phase, or maintaining project docs. Daily lifecycle management — tasks.json status flow (todo → doing → done), phase lifecycle, and doc-update rules. Triggers: executing or starting a tasks.json task, updating task status, archiving a phase, maintaining docs.
---

# 日常生命周期管理

管理 .rime/ 数据层的日常状态流转。初创项目请使用 `/rime-init`。

---

## 任务生命周期

```
用户定义功能 → /rime-backlog（别名 /rime-task）→ tasks.json (status: todo)
    ↓ 用户说「做 #xxx」「执行 #xxx」「grill #xxx」等（没有对应 task 则先建 task，见下方步骤 0）
tasks.json (status: doing)  ← 进入设计/grill 阶段即算开始
    ↓ 根据 difficulty 决定执行方式
    ├─ trivial → 主线程直接实现（唯一例外，判据见 dispatch.md）
    ├─ small  → 派 1 个 implementer subagent 一次完成（模型按 dispatch.md）
    ├─ medium → grill-me 收敛设计 → spec → 按 subtasks 派发 implementer 实施（subtasks 当活计划，边做边改）
    └─ large  → grill-me → spec（含 ## Task N 段落）→ rime-sdd 编排执行（subagent per task + per-task review）
    ⚠ spec 锁设计意图；tasks.json subtasks 是自适应执行清单，发现偏离预期就直接增删
    ⚠ 执行分配（subagent + model）规则见 dispatch.md：主线程只做调度，实现工作派 subagent 并显式指定模型档位
    ⚠ 产出 spec 文件后，将路径写入 task 的 docs 字段
    ↓ 完成后，用户确认 OK
tasks.json (status: done, completedAt: 今天)
    ↓ Phase 关闭时
archives/tasks.P{n}.json 归档 → archive.md 叙事总结 → tasks.json 移除已归档 items
```

## 设计阶段：grill-me

medium / large 任务动手前先收敛设计、产出 **spec**。默认用 grill-me 式逐题逼问：

> Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.
>
> Ask the questions one at a time.
>
> If a question can be answered by exploring the codebase, explore the codebase instead.

> grill-me 原文取自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT License）。

- **grill-me（收敛）是默认**：用户带着方向来时，逼问钉死决策树的每个分支。需要同时产出 ADR / glossary 时用 `grill-with-docs`。
- 收敛结束写 **spec**，固化关键决策 + 理由 + 放弃的方案——spec 比 implementation plan 更耐久。
- **逼问中冒出视觉问题**（光靠文字说不清的 layout / UI 外观 / 方案对比）：**先问用户**要不要启用 **HTML 格式 spec** 把 mock 画出来讨论，用户同意可创建 HTML spec（详见下方「spec 格式」）。

### spec 格式

- 默认 **Markdown**，落点为与 `plansDirectory` 同级的 `specs/`（默认 `docs/specs/*.md`，详见下方「实施 › 文档落点」）。
- 涉及 **UI** 的 spec 用 **HTML**：可画 wireframe、嵌可运行 mock。模板见 `rime-init` 的 `reference/template-spec.html`（sidebar 编号导航 + 决策表 + phone/desktop 双 mock 框）。dashboard `/file` 原生渲染 `.html`，点开即所见。正文字体按 spec 语言指定：中文 `'Noto Sans CJK SC', system-ui`，日文 `'Noto Sans CJK JP', system-ui`，不要在前面叠拉丁 webfont（Jost 等），否则中日文粗细大小不一。
- **遇到视觉问题**（需要展示 layout、对比布局方案、讨论 UI 外观与交互时）：**先征得用户同意**，再把该 spec 写成 **HTML 格式**（非 Markdown），在 HTML spec 里呈现可运行 mock、画对比框，**所见即所讨论**——视觉讨论收敛在 spec 文件内，dashboard `/file` 点开即看。
- **验证记录区**：task 完成、用户验证通过后，在 spec 末尾追加 `## 验证记录`（验证清单逐条 + 通过日期）。spec 由此闭环——开头是设计意图与放弃的方案，结尾是「做对了」的证据。验证内容只落 spec，不写 tasks.json。

### 实施

spec 定稿后主线程转入**调度者**角色：实现工作按 [dispatch.md](dispatch.md) 派发 subagent 并**显式指定 model**（fable/session 模型不下放）；medium 按 subtasks 逐段串行派发、主线程逐段审 diff；仅 **trivial** 改动主线程直接做。

- spec 定稿后，把执行步骤映射到 tasks.json **subtasks，边做边更新**（不写重型 plan 文档）。subtasks 就是自适应的执行清单。
- **large** 任务的 spec 应包含 `## Task N` 段落（每个 task 一段：需求、接口约束、验收标准），定稿后用 `rime-sdd` 编排执行——每 task 派 fresh implementer subagent + per-task spec/quality review gate + final whole-branch review。medium 任务按 subtasks 顺序逐段派发实施。

> **⚠ 文档落点（配置驱动）**
> 落点由 **Claude Code `plansDirectory` 配置** 驱动：
> - **spec** → 与 `plansDirectory` **同级**的 `specs/`（例：`plansDirectory` 为 `./docs/plans` → spec 落 `./docs/specs/`）；**未配置则走默认：项目根目录下 `docs/specs/`**。文件名 `YYYY-MM-DD-<topic>-design.md`
> - **plan**（如需）→ 读 Claude Code 配置 `plansDirectory`（项目 `.claude/settings.json` 优先，否则 `~/.claude/settings.json`）所指目录；**未配置则走默认：项目根目录下 `docs/plans/`**。文件名 `YYYY-MM-DD-<feature>.md`

### 开始执行 task

用户说「做 #0011」「执行任务 xxx」「grill #xxx」等表达时（包括开始 grill/设计阶段）：

0. **没有对应 task 时先建 task**：若用户给的 ID 在 tasks.json 中不存在，或用户直接描述了一件尚未登记的工作（如「帮我做 XX 功能」），先走 `/rime-backlog`（别名 `/rime-task`）流程创建 task 拿到编号，再从第 1 步继续。所有进入执行流程的工作都必须先在 tasks.json 有对应 item
1. 读取 `.rime/tasks.json`，找到对应 item
2. 将 status 更新为 `doing`（grill/设计 即算开始，不必等到写代码）
3. 读取 `.rime/cautions.json`，按 task 的 title + description 关键词与 cautions 的 `tags` + `title` 字段做 substring 匹配（CJK 文本直接子串包含检查），匹配到的 cautions 注入到当前对话 context，无匹配则跳过
4. 评估 difficulty 是否合理：AI 根据 task 的 title + description + subtasks 重新评估 difficulty（small / medium / large），若与 tasks.json 中的 difficulty 不一致则提示用户确认并更新
5. **依赖软警告**（仅文字提示，用户自行决定）：读取 task 的 `dependsOn`，逐个查依赖 task 的 status，若有非 `done` 项，列出这些依赖（id + status），提示用户「以下依赖尚未完成，是否仍要现在开始？」。不阻止状态流转，用户自决
6. 根据 difficulty 决定执行方式（见上方流程图），执行分配规则见 [dispatch.md](dispatch.md)
7. **记录 commitFrom**: 执行 `git rev-parse HEAD`，成功则写入 task 的 `commitFrom` 字段（每次 doing 都覆写）。若命令失败（非 git 仓库等），静默跳过
8. **回填 docs**：grill/设计阶段产出的 spec/prototype/正式文档落盘后，立即写入 task 的 `docs` 字段（`[{type, path}]`，type 见 data-contract 枚举），不要等 task 完成时补
9. **Branch 建议**（仅文字建议，用户自行决定）:
   - `small` → 不建议
   - `medium` → 可选建议："这个任务可以考虑新建分支 `feature/xxx`，也可以直接在当前分支开发"
   - `large` → 强烈建议："建议为这个任务创建独立分支 `feature/xxx`"
   - 命名格式: `feature/xxx` / `fix/xxx`，描述性，不含 task ID
10. **记录 branch**: 建议后询问用户："已创建分支了吗？如有请提供分支名，跳过则直接回车"。用户提供则写入 task 的 `branch` 字段，跳过则不写

### 完成 task

1. 实施完成后，**生成并呈现验证清单**（让用户自己确认做对了，而非 AI 自说做完）:
   - 基于 task 的 title + description + 本次 commit diff 即时生成；有 spec 时对照 spec 的设计意图，把验收点翻译成用户当下能跑/能点的**具体步骤**
   - 给出**可操作**的步骤（跑哪条命令、开哪个页面点哪里、看到什么算通过），不是泛泛的「检查一下」
   - 呈现格式:「你可以这样验证: ① …  ② …  ③ …」
2. **用户实际验证**——等用户跑完反馈，不替用户判定通过
3. 验证通过后，**沉淀验证记录**:
   - **有 spec（medium / large）** → 在 spec 文件末尾追加 `## 验证记录` 区（验证清单逐条 + 通过日期）；spec 由此闭环:开头是设计意图，结尾是验证证据
   - **无 spec（small）** → 仅对话呈现，不落盘（small 本就轻量，口头闭环即可）
   - ⚠ 验证内容**不写入 tasks.json**——tasks.json 是状态机，验证属意图层，只活在 spec 与对话里
4. **收集 commit range**（标记 done 之前）:
   - 检查 task 是否有 `commitFrom`，为空则跳过
   - 获取当前 `git rev-parse HEAD` 作为 `commitTo`
   - 若 `commitFrom` === `commitTo`（零 commit），跳过写入
   - 否则写入 `commits: { "from": "<commitFrom>", "to": "<HEAD>" }`
   - 多个 task 同时 doing 时，各自范围可能重叠，属预期行为
5. 用户确认 OK 后，将 status 更新为 `done`，写入 `completedAt`
6. 如有 subtasks，确认全部完成

---

## 文档更新规则

| 时机 | 更新内容 |
|------|----------|
| 发现改善点 / 新想法 | 用 `/rime-backlog`（别名 `/rime-task`）添加到 tasks.json（status: todo） |
| 阶段完成，开始下一阶段 | 触发 Phase 关闭流程（见下方） |
| 新增依赖 / 改技术选型 `[开发]` | 更新 techstack.md |
| 交互行为变更 `[开发]` | 更新 interaction.md 对应章节 |
| 数据结构变更 `[开发]` | 更新 schema.md |
| 用户说"更新文档" | 更新 README.md + docs/ 根目录核心文档（不含子目录） |

更新方式：

- **PRD 叙事更新**：功能规划变更时更新引用列表，砍掉的加到"不做的事"
- **archive 归档**：整个 phase 完成后写入阶段总结
- **techstack.md Phase checklist** `[开发]`：完成项打 `[x]`，新阶段直接追加
- 调研内容放 `docs/researches/`，设计内容放 `docs/designs/`，不放根目录
- 详细仕様放 `docs/product/`，PRD 保持概要级别并链接过去

---

## Phase 关闭流程

当一个 phase 内所有 tasks 的 status 都变为 `done` 时：

1. 提示用户是否关闭该 phase
2. 用户确认后：
   - `phase.json`: 该 phase 的 status → `done`，记录 `completedAt`
   - `.rime/archives/tasks.P{n}.json`: 写入该 phase 的所有 done tasks（完整 task 对象原样保留）。归档 JSON 为关闭时的不可变快照，写入后不随其他文件变更而更新
   - `archive.md`: 追加阶段叙事概要（不含 task 列表）
   - `tasks.json`: 移除该 phase 的 done items；移除后扫描剩余所有 task 的 `dependsOn`，删除指向已归档 ID 的引用（依赖满足即消解，active 区不留悬空引用，详情回 archive 查）
   - `anchors/`: 删除旧 anchor 文件，全局只保留最近 10 个
   - `prd.md`: 移除已归档阶段的内容
3. 如需开始新 phase：用户在 prd.md 中定义，AI 同步更新 phase.json

> P0/P1 等已关闭阶段的 archive.md 叙事保持不变，本流程从下一个关闭的 phase 起适用。

### 归档 JSON 格式

路径与字段见 [data-contract.md](data-contract.md) 的 archives 一节。要点：不可变快照、items 保留完整 task 对象、phase/name/completedAt 从 phase.json 取值。

---

## 规则与约束

### 写入约束

**所有路径**（AI 手动更新、`/rime-backlog` command）向 tasks.json 写入 item 时，必须满足 [data-contract.md](data-contract.md) 的「写入约束」：必填字段齐全（缺失则**中止写入并报错**）、`dependsOn` 先过 DFS 检环（构成环则**拒绝写入**，图恒为 DAG）、空 `dependsOn` 省略 key。

### 编号规则

所有功能项使用**全局递增编号** `#0001`、`#0002`...：

- 编号由 `tasks.json` 的 `nextId` 自增生成，补零 4 位
- 编号全局唯一，不回收不复用
- 用 `/rime-backlog` 添加新 item 时自动分配编号

### docs/ 目录规则

- `.rime/` 和 `docs/` 默认不入库（用户可覆盖，两者入库策略应一致）
- 根目录放核心文档（prd, archive, techstack 等）
- 子目录名用**复数形式**（specs, plans, researches, designs）
- `specs/`（spec：设计意图 + 决策 + 验证记录）与 `plans/`（plan：临时执行计划）**同级**：落点跟随 Claude Code `plansDirectory` 配置，**未配置则走默认——项目根目录下 `docs/specs/`**（plan 目录 `docs/plans/` 如需）
- `product/` 放详细仕様書（复杂功能的讨论结果）

---

## 数据层参考

**`.rime/` 五类文件的字段、枚举、ID 格式、读写归属的权威定义：[data-contract.md](data-contract.md)。** 涉及字段细节时先读它。

执行分配（subagent + model 档位）的权威定义：[dispatch.md](dispatch.md)。

| 文件 | 职责 |
|------|------|
| `.rime/tasks.json` | 任务状态 source of truth（items + subtasks + dependsOn） |
| `.rime/phase.json` | 当前 phase、历史 phases |
| `.rime/cautions.json` | 踩坑记录，append-only，SessionEnd hook 自动提取 |
| `.rime/anchors/` | session 记录，自动生成，gitignore |
| `.rime/archives/` | phase 关闭时的不可变 task 快照 |
| `docs/prd.md` | 产品定位和规格，叙事文档，用 #ID 引用 tasks.json |
| `docs/archive.md` | 阶段叙事归档，phase 关闭时写入总结 |
