# .rime/ 数据契约（权威定义）

`.rime/` 数据层的唯一权威 schema。所有消费者（rime-flow / rime-init / rime-backlog / hooks / dashboard）以本文件为准；其他文档只保留指针和最小摘要，不得整段复述 schema。

## 总览：文件与读写归属

| 文件 | 写入方 | 读取方 |
|------|--------|--------|
| `tasks.json` | `/rime-backlog`（新增 item）、rime-flow / AI（状态流转、归档清理） | hooks（session-end 传给 worker）、dashboard、rime-flow |
| `phase.json` | rime-init（创建）、rime-flow（phase 关闭 / 新 phase） | hooks（session-start/end 读 current）、dashboard、`/rime-backlog`（取 current） |
| `cautions.json` | SessionEnd worker（自动追加）、手动 | rime-flow（开始 task 时匹配注入）、dashboard |
| `anchors/{ts}.json` | session-end.sh（minimal）/ worker（完整） | session-start.sh（读最新一个注入上下文） |
| `archives/tasks.P{n}.json` | rime-flow（phase 关闭时写入，此后不可变） | dashboard（`/archives/{phaseId}` 路由） |

## 通用格式约定

- **task ID**：`#0001`，`#` + 4 位补零，全局唯一，不回收不复用，由 `nextId` 自增生成
- **caution ID**：`C-001`，连字符 + 3 位补零，由 worker 扫描现有最大值自增
- **phase ID**：`P0`, `P1`, ...
- **日期**：`YYYY-MM-DD`；**anchor 时间戳字段**：ISO 8601 含时区（`2026-06-10T09:53:23+0900`）
- **schemaVersion**：tasks.json 当前为 `2`，phase.json 为 `1`，anchor 为 `1`。**例外：cautions.json 是裸数组、无 schemaVersion**——根类型改为对象会破坏已部署的 hooks（jq 数组追加）与 dashboard，等真正 breaking 变更时再连同迁移一起做

---

## tasks.json

任务状态的 source of truth。

### 根结构

```json
{
  "schemaVersion": 2,
  "nextId": 1,
  "segments": {},
  "items": []
}
```

`segments` 可选，按 module 分配编号区间：`{ "infra": "0001-0099", "feature-a": "0100-0199" }`。

### Item 字段

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| id | string | ✓ | `#0001` 格式 |
| module | string | | 功能模块（对应 segments 的 key） |
| title | string | ✓ | 功能标题（大颗粒，人定义） |
| description | string | | 详细说明 |
| status | enum | ✓ | `todo` / `doing` / `done` |
| phase | string | ✓ | 所属阶段，从 phase.json `current` 获取 |
| priority | enum | ✓ | `high` / `medium` / `low` |
| difficulty | enum | | `small`(🟢 半小时内) / `medium`(🟡 半天) / `large`(🔴 1天+) |
| createdAt | string | ✓ | `YYYY-MM-DD` |
| completedAt | string | | 仅 done 时填写 |
| subtasks | array | | 自适应执行清单 `[{title, status}]` |
| dependsOn | array | | 依赖的 task ID 列表，构成 DAG，详见下方 |
| branch | string | | doing 时用户确认后写入的关联分支名 |
| commitFrom | string | | doing 时自动写入 HEAD hash（每次覆写），commit range 起点 |
| commits | object | | done 时自动写入 `{ "from": "...", "to": "..." }` |
| docs | array | | spec/plan 产出后写入 `[{ "type": "spec\|plan", "path": "相对路径" }]` |

### 写入约束（所有写入路径必须遵守）

- 必填字段（id / title / status / priority / createdAt / phase）缺失或格式错误时**中止写入并报错**
- `dependsOn` 写入前必须做 **DFS 检环**（含自依赖）：构成环则拒绝写入，`dependsOn` 图恒为 DAG
- `dependsOn` 为空时**省略该 key**，不写 `"dependsOn": []`
- 新增 item 后 `nextId` 自增

### 状态机

`todo → doing → done`。doing 自进入设计/grill 阶段起算；done 需用户确认。phase 关闭时该 phase 的 done items 被回收进 archives/。

### dependsOn 语义

- **单向**声明前置依赖，不反向回写；反向 `blockedBy` 由 dashboard 实时计算
- 被依赖 task 的 status 为 `done` 即视为依赖满足
- 开始 task 时依赖未满足只做**软警告**，不阻止流转
- phase 归档时自动移除指向已归档 ID 的引用（active 区不留悬空引用）

---

## phase.json

```json
{
  "schemaVersion": 1,
  "current": "P0",
  "phases": [
    { "id": "P0", "name": "MVP", "status": "active", "startedAt": "YYYY-MM-DD" }
  ]
}
```

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| current | string | ✓ | 当前活跃 phase 的 id |
| phases[].id | string | ✓ | `P0`, `P1`, ... |
| phases[].name | string | ✓ | 阶段名 |
| phases[].status | enum | ✓ | `active` / `done` |
| phases[].startedAt | string | ✓ | `YYYY-MM-DD` |
| phases[].completedAt | string | | phase 关闭时写入，对象原地更新（不替换、不删除） |

---

## cautions.json

裸数组，append-only，不设 status 字段。由 SessionEnd worker 自动提取或手动追加。

```json
[]
```

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| id | string | ✓ | `C-001` 格式 |
| title | string | ✓ | 简短标题 |
| summary | string | | 详细描述 |
| tags | array | | 分类标签，**参与匹配注入**（见下） |
| reference | string | | commit hash / 文件路径 / 链接 |
| createdAt | string | ✓ | `YYYY-MM-DD` |
| source | string | | `session-{TIMESTAMP}`，worker 自动填 |

### 匹配注入规则

rime-flow 开始 task 时：以 task 的 `title` + `description` 关键词，对 caution 的 `tags` + `title` 做 **substring 匹配**（CJK 文本直接子串包含检查）。匹配到的 cautions 注入对话上下文，无匹配则跳过。

### 收录标准

只收录**可能再发生**的教训和约束（平台隐性限制、架构决策副作用、反复出现的模式错误）；不收录已修复的一次性 bug、一次性迁移问题、文档已覆盖的内容。不再相关的条目定期直接删除。

---

## anchors/{TIMESTAMP}.json

session 记录，每次 SessionEnd 自动生成。**gitignore，不入库**；phase 关闭时清理，全局只保留最近 10 个。

- **文件名**：`YYYY-MM-DDTHH-MM-SS.json`（本地时间，连字符分隔）
- **写入方**：对话过短时由 session-end.sh 同步写 minimal anchor（各数组为空）；正常情况由后台 worker 调用 `claude -p` 生成完整内容

| 字段 | 类型 | 说明 |
|------|------|------|
| schemaVersion | number | `1` |
| timestamp | string | ISO 8601 含时区 |
| phase | string | 写入时 phase.json 的 `current` |
| workedOn | array | 涉及的 task ID（仅 tasks.json 中已存在的） |
| subtasksCompleted | array | 本次完成的工作（自由描述，仅作记录，不驱动状态变更） |
| subtasksAdded | array | 发现的新子任务（自由描述，仅作记录） |
| decisions | array | 关键决策 |
| nextSteps | array | 下一步 |
| cautions | array | 提取的踩坑 `[{title, summary?, tags?}]`——追加进 cautions.json 时由 worker 补 id / createdAt / source |

session-start.sh 读取**最新一个** anchor 的 `timestamp` / `workedOn` / `decisions` / `nextSteps` 注入新 session 上下文。

---

## archives/tasks.P{n}.json

phase 关闭时写入的**不可变快照**，写入后不随其他文件变更而更新。遵循 `.rime/` 的整体 gitignore 策略。

```json
{
  "phase": "P2",
  "name": "品质改善",
  "completedAt": "2026-03-20",
  "items": [...]
}
```

- `items` 保留完整 task 对象（所有字段原样）
- `phase` / `name` / `completedAt` 从 phase.json 取值
- dashboard 通过 `/archives/{phaseId}` 路由按需读取
