# Task 执行分配（dispatch）契约（权威定义）

task 执行分配（subagent + model）的唯一权威规则。rime-flow / rime-sdd 涉及「派谁做、用什么模型」时均以本文件为准，其他文档只留指针，不整段复述。

动机一句话：把 fable / opus 配额留给调度与设计，实现工作下沉到便宜模型。

---

## 主线程 = 调度者

主线程（fable）的职责限定为：

- grill / spec 设计
- 上下文策展（为 subagent 准备自包含的派发材料）
- 派发 subagent
- 审 diff、验收
- tasks.json 状态流转

除以下两种情况外，主线程不直接实现：

1. **trivial 例外**（判据见下）
2. **升级链顶端回落**：opus 都搞不定，问题回主线程亲自处理

---

## trivial 判据

⚠ trivial 不是 tasks.json 的 difficulty 枚举值（枚举仍是 small / medium / large，见 data-contract.md），它是 small 任务在**执行期**的降级判定，tasks.json 里照记 small。

三条**同时满足**才算 trivial：

- 单文件
- 约 10 行以内
- 无设计判断成分

三条同时满足 → 主线程直接做。派发的上下文重建开销超过收益，派反而更慢更贵。

---

## 按 difficulty 的派发形态

| difficulty | 派发形态 |
|------|------|
| trivial（small 的执行期判定） | 主线程直接做（不派发） |
| small | 派 1 个 implementer subagent 一次完成，主线程验收 diff |
| medium | 主线程 grill → spec 后，按 subtasks 逐段**串行**派发 implementer（不并行，避免冲突），主线程逐段审 diff，**不派 reviewer subagent** |
| large | rime-sdd 编排（per-task implementer + reviewer + final review），模型档位遵循本文件 |

---

## 提交责任

| difficulty | 提交方 |
|------|------|
| trivial / small / medium | implementer 不 commit；主线程审 diff 通过后统一收尾提交（`/rime-git`） |
| large | rime-sdd 编排内 implementer 每 task 自行 commit |

---

## 模型档位

| 档位 | 模型 | 适用场景 |
|------|------|------|
| 低档 | haiku | spec 里含完整代码的转写、单文件机械小修、重命名/格式化 |
| 中档 | sonnet | prose spec 的常规实现、多文件集成、一般 review、只读调查（Explore） |
| 顶档 | opus | 架构判断、复杂 debug、并发/安全敏感改动、final whole-branch review |

⚠ **fable / session 继承**：不给 subagent，只留主线程。**派发时必须显式指定 model**——省略 model 即继承 session 模型（最贵），静默击穿本契约。

> 档位是抽象，模型别名（haiku/sonnet/opus）随代际演进由 Claude Code 解析到当代模型。

---

## agent type 映射

| 工作类型 | agent type |
|------|------|
| 只读调查 / 代码探索 | `Explore`（prompt 中明确要求用 Read/Grep/Glob 工具读文件搜代码，禁止用 bash 的 cat/grep 拼管道） |
| 实现 / 修 bug | `general-purpose` |
| review（large 流程内） | rime-sdd 的 reviewer 模板 |
| 实现前的方案草案（如需） | `Plan` |

---

## 升降级规则

- subagent 报 **BLOCKED** 或**同一段返工 2 次** → 升一档重派（haiku→sonnet→opus），**禁止同模型原样重试**
- 顶档到 opus 为止；**opus 仍不行 → 回主线程亲自处理**（升级链顶端回落）

---

## 派发 prompt 契约

派发给 subagent 的 prompt 必须自包含：

- 任务描述
- 涉及文件路径
- 接口 / 全局约束
- 验收标准
- 报告格式
- **注释禁令**（必须逐条传达，subagent 不会自己知道）：写入代码的注释里不得出现 task ID（`#0001`）、caution ID（`C-001`）、`docs/` 下路径——这些默认不入库，对 clone 者是死链。注释要自足，把「为什么」直接写进去。权威定义见 [data-contract.md](data-contract.md)「不入库资产的引用禁令」

**不让 subagent 继承主线程会话历史**——fresh subagent 只靠 prompt 里给的信息工作。

上一条正因如此才关键：主线程知道 `#0012` 指什么，fresh subagent 不知道，于是照抄进注释，留下一条谁也查不到的引用。

大块产物（diff、报告）走**文件路径交接**，不粘贴进对话。
