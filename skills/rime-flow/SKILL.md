---
name: rime-flow
description: 日常生命周期管理。管理 tasks.json 状态流转（todo → doing → done）、phase 生命周期、文档更新规则。触发场景：执行/开始 tasks.json 中的任务、任务状态更新、阶段归档、文档维护。
---

# 日常生命周期管理

管理 .rime/ 数据层的日常状态流转。初创项目请使用 `/rime-init`。

---

## 任务生命周期

```
用户定义功能 → tasks.json (status: todo)
    ↓ 用户说「做 #xxx」「执行任务 xxx」
tasks.json (status: doing)
    ↓ 根据 difficulty 决定执行方式
    ├─ small → 直接实现
    ├─ medium → superpowers:writing-plans → 实施
    └─ large → superpowers:brainstorming → writing-plans → 实施
    ⚠ plan 的每个 task 完成后必须更新 tasks.json 中对应 subtask 的 status
    ⚠ brainstorming/writing-plans 产出 spec/plan 文件后，将路径写入 task 的 docs 字段
    ↓ 完成后，用户确认 OK
tasks.json (status: done, completedAt: 今天)
    ↓ Phase 关闭时
archives/tasks.P{n}.json 归档 → archive.md 叙事总结 → tasks.json 移除已归档 items
```

### 开始执行 task

用户说「做 #0011」「执行任务 xxx」等表达时：

1. 读取 `.rime/tasks.json`，找到对应 item
2. 将 status 更新为 `doing`
3. 读取 `.rime/cautions.json`，按 task 的 title + description 关键词与 cautions 的 `tags` + `title` 字段做 substring 匹配（CJK 文本直接子串包含检查），匹配到的 cautions 注入到当前对话 context，无匹配则跳过
4. 评估 difficulty 是否合理：AI 根据 task 的 title + description + subtasks 重新评估 difficulty（small / medium / large），若与 tasks.json 中的 difficulty 不一致则提示用户确认并更新
5. 根据 difficulty 决定执行方式（见上方流程图）
6. **记录 commitFrom**: 执行 `git rev-parse HEAD`，成功则写入 task 的 `commitFrom` 字段（每次 doing 都覆写）。若命令失败（非 git 仓库等），静默跳过
7. **Branch 建议**（仅文字建议，用户自行决定）:
   - `small` → 不建议
   - `medium` → 可选建议："这个任务可以考虑新建分支 `feature/xxx`，也可以直接在当前分支开发"
   - `large` → 强烈建议："建议为这个任务创建独立分支 `feature/xxx`"
   - 命名格式: `feature/xxx` / `fix/xxx`，描述性，不含 task ID
8. **记录 branch**: 建议后询问用户："已创建分支了吗？如有请提供分支名，跳过则直接回车"。用户提供则写入 task 的 `branch` 字段，跳过则不写

### 完成 task

1. 实施完成后，向用户确认结果
2. **收集 commit range**（标记 done 之前）:
   - 检查 task 是否有 `commitFrom`，为空则跳过
   - 获取当前 `git rev-parse HEAD` 作为 `commitTo`
   - 若 `commitFrom` === `commitTo`（零 commit），跳过写入
   - 否则写入 `commits: { "from": "<commitFrom>", "to": "<HEAD>" }`
   - 多个 task 同时 doing 时，各自范围可能重叠，属预期行为
3. 用户确认 OK 后，将 status 更新为 `done`，写入 `completedAt`
4. 如有 subtasks，确认全部完成

---

## 文档更新规则

| 时机 | 更新内容 |
|------|----------|
| 发现改善点 / 新想法 | 用 `/rime-backlog` 添加到 tasks.json（status: todo） |
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
   - `tasks.json`: 移除该 phase 的 done items
   - `anchors/`: 删除旧 anchor 文件，全局只保留最近 10 个
   - `prd.md`: 移除已归档阶段的内容
3. 如需开始新 phase：用户在 prd.md 中定义，AI 同步更新 phase.json

> P0/P1 等已关闭阶段的 archive.md 叙事保持不变，本流程从下一个关闭的 phase 起适用。

### 归档 JSON 格式

路径：`.rime/archives/tasks.P{n}.json`

```json
{
  "phase": "P2",
  "name": "品质改善",
  "completedAt": "2026-03-20",
  "items": [...]
}
```

- items 保留完整 task 对象（所有字段原样保留）
- phase/name/completedAt 从 phase.json 取值
- `archives/` 遵循 `.rime/` 的整体 gitignore 策略

---

## 规则与约束

### 写入约束

**所有路径**（AI 手动更新、`/rime-backlog` command）向 tasks.json 写入 item 时，必须包含以下必填字段：

| 字段 | 格式 | 说明 |
|------|------|------|
| id | `#0001`（4 位补零） | 由 nextId 生成 |
| title | 非空字符串 | — |
| status | `todo` / `doing` / `done` | — |
| priority | `high` / `medium` / `low` | 不确定时询问用户 |
| createdAt | `YYYY-MM-DD` | — |
| phase | `P0`, `P1`, ... | 从 phase.json current 获取 |

缺失必填字段时**中止写入并报错**，不允许写入不完整的 item。

### 编号规则

所有功能项使用**全局递增编号** `#0001`、`#0002`...：

- 编号由 `tasks.json` 的 `nextId` 自增生成，补零 4 位
- 编号全局唯一，不回收不复用
- 用 `/rime-backlog` 添加新 item 时自动分配编号

### docs/ 目录规则

- `.rime/` 和 `docs/` 默认不入库（用户可覆盖，两者入库策略应一致）
- 根目录放核心文档（prd, archive, techstack 等）
- 子目录名用**复数形式**（researches, designs, plans）
- `plans/` 仅放临时计划
- `product/` 放详细仕様書（复杂功能的讨论结果）

---

## 数据层参考

| 文件 | 职责 | 内容 |
|------|------|------|
| `.rime/tasks.json` | 任务状态 source of truth | todo/doing/done items + subtasks |
| `.rime/phase.json` | 阶段信息 | 当前 phase、历史 phases |
| `.rime/cautions.json` | 踩坑记录 | append-only，SessionEnd hook 自动提取 |
| `.rime/anchors/` | session 记录 | 每次 session 结束自动生成，gitignore |
| `docs/prd.md` | 产品定位和规格 | 叙事文档，用 #ID 引用 tasks.json |
| `docs/archive.md` | 阶段叙事归档 | phase 关闭时写入总结 |

### tasks.json 可选字段

| 字段 | 类型 | 写入时机 | 说明 |
|------|------|----------|------|
| `branch` | string, 可选 | doing 时用户确认后 | 关联分支名 |
| `commitFrom` | string, 可选 | doing 时自动（每次覆写） | HEAD hash，commit range 起点 |
| `commits` | object, 可选 | done 时自动 | `{ "from": "...", "to": "..." }` |
| `docs` | array, 可选 | brainstorming/writing-plans 产出后 | `[{ "type": "spec\|plan", "path": "相对路径" }]` |
