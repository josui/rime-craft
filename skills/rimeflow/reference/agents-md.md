# AGENTS.md 模板

AGENTS.md 放在项目根目录。定义 AI Agent 在此项目中的协作规则。
初创时创建，之后除非协作规则本身需要调整，否则不改。

**是否入库由用户决定：**
- 入库：团队共享 AI 协作规范
- 加入 `.gitignore`：不想干扰协作者，或开源项目不想公开

创建时询问用户偏好。

---

## 模板

```markdown
# AGENTS.md

## 任务执行模式

根据复杂度分层，不要所有任务走同一个流程。

| 层级 | 场景 | 做法 |
|------|------|------|
| L1 | 单文件改动、小 bug | 直接动手，不讨论 |
| L2 | 目标明确但路径需确认 | 搜索 best practice → 简短沟通 → 执行 |
| L3 | 多文件变更、新功能、架构调整 | Superpower brainstorming → 规划 → 分步执行（提供进度汇报） |
| L4 | 技术选型、方案探讨 | 提供 2-3 种方案分析优劣，不执行，等用户决策 |

遇到困难时的闭环：搜索 → 沟通 → 尝试 → 失败再搜索。
原则：先查权威资料，再动手。

## Git 规范

- 仅在用户明确要求时才 commit
- Subagent 执行过程中**禁止逐步 commit**
- 使用 `git-commit` skill 处理提交
- 禁止添加 co-authored-by
- Branch 命名：`feature/xxxx-xxxx`、`fix/xxxx-xxxx`
- `.gitignore` 忽略的文件遇 add 报错直接跳过，不用 `-f`
- Tag 用 annotated tag（`git tag -a`），带分类 release notes

## 版本原则

**始终使用满足兼容性的最新稳定版本。**

- 安装依赖、选择工具前，先用 context7 MCP 或 web search 查询最新文档
- 关注大版本 breaking changes、框架插件兼容性
- 不确定时搜索后再决定，不凭记忆猜版本

## 代码注释

- 中文注释，技术术语保留英文
- 重点说明"为什么"，不只是"做什么"
- 函数注释：功能说明 + 关键参数含义 + 算法逻辑
- 常量/阈值：取值依据 + 校准来源 + 调整建议
- 不给没改过的代码加注释

## AI 协作

### 角色分工
- 用户：定需求、做决策、验收
- AI：调研、规划、执行、汇报

### 沟通规范
- 执行前：说清要做什么、影响哪些文件
- 执行中：L3 任务提供进度汇报
- 执行后：总结改动、提示后续步骤
- 遇阻时：不反复重试同一方案，沟通后切换方向

### 禁止事项
- 不主动 commit（等用户指令）
- 不启动/验证 dev server（用户手动管理）
- 不使用 EnterPlanMode（复杂任务走 Superpower）

## 文档管理

- `docs/` 在 `.gitignore` 中，不入库
- "更新文档" = README.md + docs/ 根目录核心文档（不含子目录）
- 详见 project-workflow skill

## 技术栈

<!-- 项目特有的技术约束写在这里 -->
<!-- 示例：-->
<!-- - 严禁 `any` 类型 -->
<!-- - 优先使用 ES2025+ 特性 -->
<!-- - 未达 Baseline 的 CSS 特性用 @supports 降级 -->

## Skill 使用（按需保留相关项）

<!-- 根据项目技术栈保留对应的 skill 规则，删除不相关的 -->

### CSS（使用 CSS / Tailwind 的项目）

- CSS 架构参照 `css-architecture` skill
- 覆盖：CUBE CSS 分层、BEM 命名、`data-*` 变体、skin vs layout 分离
- 适用于 shadcn、coss ui、Radix 等组件库项目

### React（React 项目）

- 完成功能、修 bug、review 时运行 `react-doctor`
- 写/重构组件时参照 `vercel-react-best-practices`
- 重构 props 膨胀的组件、设计组件 API 时参照 `vercel-composition-patterns`
```

---

## 字段说明

| 章节 | 必须 | 说明 |
|------|------|------|
| 任务执行模式 | ✅ | 核心，决定 AI 如何响应不同复杂度的任务 |
| Git 规范 | ✅ | 防止 AI 擅自 commit 或破坏 git 历史 |
| 代码注释 | ✅ | 统一注释风格 |
| AI 协作 | ✅ | 角色、沟通、禁止事项 |
| 文档管理 | ✅ | 指向 project-workflow skill |
| 技术栈 | 推荐 | 项目特有的技术约束和偏好 |
| Skill 使用 | 推荐 | 按技术栈保留对应 skill 规则（CSS / React 等） |

---

## Worktree 规则（可选追加）

如果项目使用 worktree 隔离开发：

```markdown
## Worktree

- 命名必须带自定义名，禁止随机名
- 路径用 `.worktrees/`（已在 .gitignore）
- 大工程手动创建后再进 claude：
  `git worktree add .worktrees/xxx -b feature/xxx && cd .worktrees/xxx && claude`
```
