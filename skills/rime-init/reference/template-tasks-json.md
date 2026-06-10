# .rime/ 初始模板

`.rime/tasks.json` 是任务状态的 source of truth。

> **字段定义、枚举、ID 格式、写入约束等完整 schema 见权威契约：rime-flow skill 的 [data-contract.md](../../rime-flow/data-contract.md)。本文件只提供初始化骨架。**

## tasks.json

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

## cautions.json

```json
[]
```

裸数组（无 schemaVersion，理由见契约文档），append-only。由 SessionEnd hook 自动提取或手动追加。

## anchors/ 与 archives/

均为运行时自动生成，初始化时只需创建空的 `anchors/` 目录（archives/ 由 phase 关闭流程按需创建）。文件格式见契约文档。
