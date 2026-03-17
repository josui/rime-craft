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
    ↓ 完成后，用户确认 OK
tasks.json (status: done, completedAt: 今天)
    ↓ Phase 关闭时
archive.md 写入阶段总结 + tasks.json 回收 done items
```

### 开始执行 task

用户说「做 #0011」「执行任务 xxx」等表达时：

1. 読取 `.rime/tasks.json`，找到対応 item
2. 将 status 更新为 `doing`
3. 読取 `.rime/cautions.json`，按 task 的 title + description 关键词与 cautions 的 `tags` + `title` 字段做 substring 匹配（CJK 文本直接子串包含检查），匹配到的 cautions 注入到当前対話 context，无匹配则跳过
4. 评估 difficulty 是否合理：AI 根据 task 的 title + description + subtasks 重新评估 difficulty（small / medium / large），若与 tasks.json 中的 difficulty 不一致则提示用户确认并更新
5. 根据 difficulty 决定执行方式（見上方流程図）

### 完成 task

1. 实施完成后，向用户确认结果
2. 用户确认 OK 后，将 status 更新为 `done`，写入 `completedAt`
3. 如有 subtasks，确认全部完成

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
   - `archive.md`: 追加阶段叙事总结
   - `tasks.json`: 删除该 phase 中 `status: done` 的 items
   - `anchors/`: 删除旧 anchor 文件，全局只保留最近 10 个
   - `prd.md`: 移除已归档阶段的内容
3. 如需开始新 phase：用户在 prd.md 中定义，AI 同步更新 phase.json

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
