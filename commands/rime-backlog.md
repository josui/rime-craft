---
description: Quickly add a backlog entry
---

Add a new task (status: todo) to the current project's `.rime/tasks.json`.

> The authoritative definitions of fields, enums, and Write Constraints live in the rime-flow skill's `data-contract.md`; the validation steps embedded in this command are kept consistent with it — when they conflict, the contract wins.

## Locate tasks.json

Search in the following order and use the first one found:
1. `**/.rime/tasks.json` (Glob search of the current project)
2. If not found, tell the user, in the user's conversation language, that the project needs to be initialized first with `/rime-init`

## Input

`$ARGUMENTS` format: `[content]` or `[Phase]: [content]`; the content may carry a dependency declaration.

Examples:
- `Service Page supports drag-and-drop reordering`
- `P2: Asset bulk-delete feature`

**Dependency parsing**: recognize expressions such as "depends on #0017" or "depends on #0017 #0018" in the content, and extract the task IDs they contain (`#` + 4 digits) into the `dependsOn` ID list. If there is no explicit dependency, do not write this field (do not write `"dependsOn": []`).

Examples:
- `Dashboard interactivity depends on #0017` → `dependsOn: ["#0017"]`
- `P2: Topological-sort rendering depends on #0017 #0018` → `dependsOn: ["#0017", "#0018"]`

If `$ARGUMENTS` is empty, ask the user what to add, in the user's conversation language.

## Execution Steps

1. Locate and read `.rime/tasks.json`
2. Parse the content from `$ARGUMENTS` (extract the Phase prefix if present, otherwise use `phase.json`'s current)
3. Judge difficulty from the content (`small` / `medium` / `large`) and tell the user, in the user's conversation language
4. Judge priority from the content (`high` / `medium` / `low`); if uncertain, ask the user, in the user's conversation language
5. Read `nextId` from tasks.json and generate the new id (zero-padded to 4 digits)
6. If `segments` exist, assign the corresponding range number based on module
7. **Dependency existence check** (only when `dependsOn` was parsed out): every referenced ID must exist in the current `tasks.json`. If any ID does not exist, list them and prompt the user, in the user's conversation language, requiring confirmation (keep) or removal before proceeding; do not write until this is resolved.
8. **Dependency cycle check (DFS)** (only when `dependsOn` was parsed out): fold the new task's `dependsOn` into the dependency graph formed by existing tasks' `dependsOn`, and run a DFS starting from the new task. If it forms a cycle (including a self-dependency where `dependsOn` points at itself), **refuse to write** and report the cycle path to the user, in the user's conversation language (e.g. `#0033 → #0017 → #0033`). `tasks.json` must always remain a DAG.
9. **Pre-write validation**: make sure all of the following required fields are present and correctly formatted; if any are missing, abort and report the error to the user, in the user's conversation language:
   - `id`: `#0001` format (4-digit zero-padded)
   - `title`: non-empty string
   - `status`: must be `todo`
   - `priority`: one of `high` / `medium` / `low`
   - `createdAt`: `YYYY-MM-DD` format
   - `phase`: non-empty string
   - `dependsOn` (optional): if present, must be an array of task IDs that has already passed the existence and acyclicity checks from steps 7 and 8; omit this key when empty
   - `description` (optional): if filled in, must be **written as multiple lines** — break the background/goal/constraints/acceptance points into lines or paragraphs with `\n`; **must not be crammed into one long line of text**
10. Append the item (`dependsOn` included only when non-empty; omit this key when there is no dependency):
    ```json
    {
      "id": "#0001",
      "module": "module name (inferred when segments exist, otherwise optional)",
      "title": "content provided by the user",
      "description": "Background: why to do this\nGoal: what it should look like when done\nAcceptance: how to tell it's complete",
      "status": "todo",
      "phase": "obtained from parsing or from phase.json",
      "priority": "the judged result",
      "difficulty": "the judged result",
      "createdAt": "today's date",
      "dependsOn": ["#0017"],
      "subtasks": []
    }
    ```

    ⚠ When `description` has content, it must be **written as multiple lines** as in the example above (`\n`-separated) — a single long line of text is hard to scan and also renders poorly in the dashboard.

11. Increment `nextId`
12. Show the result of the addition, in the user's conversation language: id, title, module, difficulty (🟢/🟡/🔴), phase
