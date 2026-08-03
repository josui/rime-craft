# .rime/ Initial Templates

`.rime/tasks.json` is the source of truth for task status.

> **For the full schema — field definitions, enums, ID format, write constraints, etc. — see the authoritative contract: rime-flow skill's [data-contract.md](../../rime-flow/data-contract.md). This file only provides the initialization skeleton.**

## tasks.json

```json
{
  "schemaVersion": 2,
  "nextId": 1,
  "segments": {},
  "items": []
}
```

`segments` is optional, used to allocate ID ranges by module:

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

A bare array (no schemaVersion — see the contract doc for why), append-only. Auto-extracted by the SessionEnd hook or appended manually.

## anchors/ and archives/

Both are auto-generated at runtime; initialization only needs to create an empty `anchors/` directory (archives/ is created as needed by the phase-closing flow). File format is in the contract doc.
