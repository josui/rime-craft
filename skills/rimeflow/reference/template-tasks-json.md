# Tasks.json 模板

`.rime/tasks.json` 是任务状态的 source of truth。

## 初始模板

```json
{
  "schemaVersion": 1,
  "nextId": 1,
  "items": []
}
```

## Item Schema

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | `#001` 格式，从 nextId 补零 3 位生成 |
| title | string | 功能标题（大颗粒，人定义） |
| status | enum | `todo` / `doing` / `done` |
| phase | string | 所属阶段 `P0`, `P1`, ... |
| priority | enum | `high` / `medium` / `low` |
| difficulty | enum | `small`(🟢 半小时内) / `medium`(🟡 半天) / `large`(🔴 1天+) |
| createdAt | string | ISO 日期 `YYYY-MM-DD` |
| completedAt | string? | 完成日期，仅 done 时填写 |
| subtasks | array | AI 自动拆解的子任务 `[{title, status}]` |

## 状态流转

```
todo → doing → done
       ↑ 开始工作时手动或 AI 自动变更
```

- AI 开始处理某个 item 时，将 status 改为 `doing` 并拆出 subtasks
- 所有 subtask 完成后，SessionEnd hook 自动将 status 改为 `done`
- Phase 关闭时，`done` 的 items 被回收（archive.md 保留叙事记录）

## 编号规则

- `nextId` 是纯数字，生成 id 时补零 3 位: `nextId: 5` → `"#005"`
- 编号全局唯一，不回收不复用
- 新增 item 后 nextId 自增

## Phase.json 初始模板

```json
{
  "schemaVersion": 1,
  "current": "P0",
  "phases": [
    { "id": "P0", "name": "MVP", "status": "active", "startedAt": "YYYY-MM-DD" }
  ]
}
```

## Cautions.json 初始模板

```json
[]
```

Caution 由 SessionEnd hook 自动提取并追加，格式:

```json
{
  "id": "C001",
  "summary": "描述",
  "tags": ["tag1", "tag2"],
  "discoveredAt": "YYYY-MM-DD",
  "source": "session-YYYY-MM-DDTHH-MM"
}
```
