# AGENTS.md 生成指南与模板

本文件分为两部分：**生成指南**（指导 rime-init A2 步骤如何生成 AGENTS.md）和**模板正文**（生成产物的内容）。

---

## 生成指南

### 前置检测

- 检测 superpowers 是否安装（rime-flow 依赖 superpowers 处理 L3 任务）
- 未安装时提醒用户：rime-flow 的 L3 任务处理能力将受限
- 提醒后继续生成完整模板（superpowers 可随时安装，不影响模板内容）

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
| CSS / Tailwind | `CSS 架构参照 rime-css skill` |
| React | `React 组件开发参照 rime-react skill` |

> 新增 rime skill 时须同步更新此映射表。

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
| L1 | 单文件改动、小 bug | 直接动手，不讨论 |
| L2 | 目标明确但路径需确认 | 搜索 best practice → 简短沟通 → 执行 |
| L3 | 多文件变更、新功能、架构调整、技术选型 | Brainstorming → 用户决定后续（执行 / 产出 spec 分解 task / 仅讨论） |

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

execution plan 必须与 tasks.json 保持同步：
- writing-plans 阶段将 plan 步骤映射到 tasks.json（新增/拆分 subtask）
- implementation plan 中每个步骤必须注明：完成后更新对应 subtask status
- plan 开始前确认 task status 为 `doing`，全部完成后询问用户可否标记 `done`
- 执行中发现 task 需要调整（复杂度变化、需要拆分）时，立刻更新 tasks.json 再继续

## Git

提交统一使用 `/rime-git`。

## 约束

- 不使用 EnterPlanMode（复杂任务走 Superpowers）
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
