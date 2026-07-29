# AGENTS.md 生成指南与模板

本文件分为两部分：**生成指南**（指导 rime-init A2 步骤如何生成 AGENTS.md）和**模板正文**（生成产物的内容）。

---

## 生成指南

### 前置检测

rime 工作流依赖以下外部 skill（mattpocock/skills，MIT License），未安装则对应能力受限：

| 外部 skill | 用途 | 缺失影响 |
|------------|------|----------|
| `grill-me` / `grill-with-docs` | medium / large 任务设计收敛 | 退化为纯对话式设计，无结构化逼问 |
| `tdd` | rime-sdd implementer 遵循 TDD | rime-sdd 的 subagent 无 TDD 约束 |
| `review` | rime-sdd final whole-branch review（Standards + Spec 两轴） | large 任务缺最终质量闸门 |

- 检测方式：按 skill 安装位置（`~/.agents/skills/`、项目 `.agents/skills/` 或对应工具的 skill 目录）检查是否存在同名 skill
- 未安装时提醒用户：上述能力将受限，可从 [mattpocock/skills](https://github.com/mattpocock/skills) 安装
- 提醒后继续生成完整模板（外部 skill 可随时安装，不影响模板内容）

### 入库选择

询问用户 AGENTS.md 是否入库：
- 入库：团队共享 AI 协作规范
- 加入 `.gitignore`：不想干扰协作者，或开源项目不想公开

### 可选交互

一次展示以下选项，用户逐一回答或跳过。

**语言设置**（三个独立选项，不选则不写入）

- AI 沟通语言
- 代码注释语言
- UI 文案默认语言

**验证方式**（不选则不写入）

- a) 用户手动管理 dev server，AI 不启动也不验证
- b) AI 可以启动 dev server 自行验证
- c) 使用 agent-browser 做浏览器验证

### 技术栈 Skill 自动映射

init 时根据项目技术栈自动检测并写入对应 skill 规则。
检测方式：扫描 package.json 依赖 + 项目配置文件（如 tailwind.config.*、tsconfig.json 等）。内容项目（无 package.json）跳过此步骤。

| 检测条件 | 写入内容 |
|----------|----------|
| TypeScript / JavaScript | `JS/TS 开发参照 rime-js skill` |
| CSS / Tailwind | `CSS 架构参照 rime-css skill` |
| React | `React 组件开发参照 rime-react skill` |
| 有 UI（HTML/CSS/JSX/TSX） | `UI 设计品质参照 rime-design skill` |

> 新增 rime skill 时须同步更新此映射表。

### CLAUDE.md 桥接

Claude Code 只原生读取 `CLAUDE.md`，**不读 `AGENTS.md`**。生成 AGENTS.md 后必须建桥，否则规则不会被加载：

- 项目**无** `CLAUDE.md` → 新建 `CLAUDE.md`，内容仅一行 `@AGENTS.md`（import 语法，session 启动时就地展开加载 AGENTS.md）
- 项目**已有** `CLAUDE.md` → 检查是否已含 `@AGENTS.md`，没有则在文件**顶部追加**该行，绝不改动用户原有内容
- **不用软链**（`ln -s`）：`@import` 跨平台一致（Windows 软链需管理员/开发者模式），且对协作者透明
- `CLAUDE.md` 的入库策略**跟随 AGENTS.md**（同入库或同 gitignore），避免「桥在、被链文件不在」的断链

### 文档地图

AGENTS.md 底部生成「文档地图」区块，指向 `docs/` 文档，给 agent 一个统一入口：

- **仅列实际创建的文档**（A5 创建了哪些就列哪些，跳过的不写）
- 扁平列表，每个文档一行：`- [类型](相对路径) — 一句话用途`
- 在 **A5 创建 docs/ 文档之后**写入（A2 生成 AGENTS.md 时 docs 尚未存在）

---

## 模板正文

### 固定内容（所有 rime 项目）

```markdown
# AGENTS.md

## 任务执行模式

所有任务通过 rime-flow 管理生命周期。使用 `/rime-dashboard` 查看进度。
根据复杂度分层执行：

| 层级 | 场景 | 做法 |
|------|------|------|
| small | 单文件改动、小 bug | 直接动手，不讨论 |
| medium | 目标明确但路径需确认 | grill-me 收敛设计 → spec → subtasks 边做边改 |
| large | 多文件变更、新功能、架构调整、技术选型 | grill-me 收敛设计 → spec（含 ## Task N 段落）→ rime-sdd 编排执行 |

### Evidence First

不凭推理猜，先拿到事实再行动。

| 场景 | 反模式 | 正确行为 |
|------|--------|---------|
| 不确定 API / 库的用法 | 在 context 里试参数组合 | 查本地文档 → curl 拉取实际响应 → context7 / web search |
| 遇到 bug / 异常行为 | 只看局部代码打补丁 | 先梳理整体流程，加 console.log 定位，拿到实际值再修复 |
| 连续两次尝试失败 | 继续换参数重试 | 停下来搜索 error message 或成熟方案 |
| 要实现常见模式 | 从零手写 | 先查是否有成熟库 / pattern |

不适用：纯业务逻辑、项目特有的领域知识（搜不到外部资料的场景）。

改动完成后 review 变更范围，清理残留的调试代码和无用逻辑。

### Rime 对齐规则

执行必须与 tasks.json 保持同步：
- spec 定稿后将执行步骤映射到 tasks.json subtasks（新增/拆分）
- 每完成一个 subtask 即更新其 status
- 开始执行前确认 task status 为 `doing`
- 验证清单先写入 spec 的 `## 验证记录` 区、再向用户呈现（medium / large）
- 标 `done` 前过 commit gate：本 task 改动全部提交且有新 commit（HEAD ≠ commitFrom，非 git 项目豁免）；`completedAt` / `commits` 与 status 同笔写入；done 后不回填，返工新建 task
- 执行中发现 task 需要调整（复杂度变化、需要拆分）时，立刻更新 tasks.json 再继续

## Git

提交统一使用 `/rime-git`。

## 约束

- 不使用 EnterPlanMode（复杂任务走 grill-me → spec → rime-sdd）
```

### 动态内容（按检测/交互结果生成）

**语言设置**（用户选择后生成，不选不写）：

```markdown
## 语言

- AI 沟通：中文
- 代码注释：日本語
- UI 文案：日本語、技术术语保留英文
```

**验证方式**（用户显式选择后生成，不选不写）：

```markdown
## 验证

- 用户手动管理 dev server，AI 不启动/不验证
```

**Skill 使用**（自动检测后生成，无匹配不写）：

```markdown
## Skill 使用

### CSS
- CSS 架构参照 `rime-css` skill

### React
- 完成功能、修 bug、review 时运行 `react-doctor`
- 写/重构组件时参照 `rime-react` skill
```

**文档地图**（A5 创建文档后生成，按实际产出列出，未创建的不写）：

```markdown
## 文档

- [prd](docs/myapp-prd.md) — 产品定位与功能规划
- [techstack](docs/myapp-techstack.md) — 技术选型与项目结构
- [DESIGN.md](docs/DESIGN.md) — 设计系统（token + rationale，google-labs DESIGN.md 格式）
```

### CLAUDE.md（桥接文件，与 AGENTS.md 同目录）

无 CLAUDE.md 时新建，内容仅一行；已有则在顶部追加这一行：

```markdown
@AGENTS.md
```
