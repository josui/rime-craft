# Tasks.json 模板

`.rime/tasks.json` 是任务状态的 source of truth。

## 初始模板

```json
{
  "schemaVersion": 2,
  "nextId": 1,
  "segments": {},
  "items": []
}
```

`segments` 可选，用于按 module 分配编号区间：

```json
{
  "segments": {
    "infra": "0001-0099",
    "feature-a": "0100-0199"
  }
}
```

## Item Schema

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| id | string | ✓ | `#0001` 格式，4 位补零 |
| module | string | | 功能模块（对应 segments 的 key） |
| title | string | ✓ | 功能标题（大颗粒，人定义） |
| description | string | | 详细说明 |
| status | enum | ✓ | `todo` / `doing` / `done` |
| phase | string | | 所属阶段 `P0`, `P1`, ... |
| priority | enum | ✓ | `high` / `medium` / `low` |
| difficulty | enum | | `small`(🟢 半小时内) / `medium`(🟡 半天) / `large`(🔴 1天+) |
| createdAt | string | ✓ | ISO 日期 `YYYY-MM-DD` |
| completedAt | string? | | 完成日期，仅 done 时填写 |
| subtasks | array | | AI 自动拆解的子任务 `[{title, status}]` |

## 状态流转

```
todo → doing → done
       ↑ 开始工作时手动或 AI 自动变更
```

- AI 开始处理某个 item 时，将 status 改为 `doing` 并拆出 subtasks
- 所有 subtask 完成后，SessionEnd hook 自动将 status 改为 `done`
- Phase 关闭时，`done` 的 items 被回收（archive.md 保留叙事记录）

## 编号规则

- `nextId` 是纯数字，生成 id 时补零 4 位: `nextId: 5` → `"#0005"`
- 编号全局唯一，不回收不复用
- 新增 item 后 nextId 自增
- 有 `segments` 时，按 module 对应区间分配编号

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

Caution 由 SessionEnd hook 自动提取或手动追加。

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| id | string | ✓ | `C-001` 格式 |
| module | string | | 所属模块 |
| title | string | ✓ | 简短标题 |
| summary | string | | 详细描述 |
| solution | string | | 解决方案 |
| tags | array | | 标签 |
| reference | string | | 参考文件/链接 |
| createdAt | string | ✓ | `YYYY-MM-DD` |
| source | string | | session 来源（hook 自动填） |
