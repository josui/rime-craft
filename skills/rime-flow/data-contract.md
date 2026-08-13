# .rime/ Data Contract (Authoritative)

The single authoritative schema for the `.rime/` data layer. All consumers (rime-flow / rime-init / rime-backlog / hooks / dashboard) treat this file as the source of truth; other docs keep only a pointer and a minimal summary, never a full restatement of the schema.

## Overview: Files and Read/Write Ownership

| File | Written by | Read by |
|------|--------|--------|
| `tasks.json` | `/rime-backlog` (alias `/rime-task`, new items), rime-flow / AI (state transitions, archive cleanup) | hooks (session-end hands off to the worker), dashboard, rime-flow |
| `phase.json` | rime-init (creation), rime-flow (phase closing / new phase) | hooks (session-start/end read `current`), dashboard, `/rime-backlog` (reads `current`) |
| `cautions.json` | SessionEnd worker (auto-appended), manual | rime-flow (matched and injected when starting a task), dashboard |
| `anchors/{ts}.json` | session-end.sh (minimal) / worker (full) | session-start.sh (reads the latest one and injects it into context) |
| `archives/tasks.P{n}.json` | rime-flow (written at phase closing, immutable afterward) | dashboard (`/archives/{phaseId}` route) |

## Storage Location & Resolution Order

`.rime/` lives at the **project root** and is **never tracked in git**. The location and resolution rules are part of the contract — every component (hooks / dashboard / rime-sdd / AI) must follow the same order.

### Being Untracked Is a Hard Requirement

`.rime/` is project-wide mutable state. Once it's tracked by git, three symptoms appear — the third one completely silent:

| Symptom | Cause |
|------|------|
| `.rime/*.json` conflicts on merge | State files have no semantically correct conflict resolution |
| **Content flips when switching branches** | Marked done on a feature branch, switches back to doing when you check out main — **with no warning at all** |
| Worktrees get a stale snapshot | The old committed version at branch checkout |

Therefore `.gitignore` must contain a `.rime/` entry. This is not a suggestion, and it is not overridable by the user. Gitignored files aren't affected by `checkout` and don't participate in `merge` — all three symptoms above disappear as a result.

> The tracking policy for `docs/` is **independent** of `.rime/` — each is decided separately: `.rime/` is mutable state, `docs/` (spec / prd) is documentation output.

### Resolution Order

```
1. $RIME_DIR env var, if set and it's an existing directory → use it (explicit override, for CI / special cases)
2. base = cwd mapped to the equivalent path in the main checkout (see below)
3. <base>/.rime exists                 → use it
4. Otherwise, search downward under <base>  → monorepo, maxdepth 4,
                                        excluding node_modules / .git / dist / .worktrees / vendor
```

**cwd → main-checkout equivalent-path mapping** (step 2):

- Compare `git rev-parse --path-format=absolute --git-dir` with `--git-common-dir` — if they differ, you're in a **linked worktree**
- If it's a worktree → `base = dirname(git-common-dir) + (cwd's path relative to the worktree root)`
- Otherwise → `base = cwd`

Key points:

- `--path-format=absolute` **must be included**: at the repo root, `--git-dir` returns the relative path `.git`; without normalizing it, it can't be reliably compared with `--git-common-dir` (requires git ≥ 2.31)
- `--git-common-dir` resolves to the same absolute path across all worktrees, entirely unaffected by checkout
- **Preserve cwd's relative portion** — never return the main checkout root directly, or it breaks monorepos: working in `<wt>/apps/foo` should resolve to `<main>/apps/foo/.rime`, not return the same `.rime/` for every sub-project
- In the main-checkout case, `base == cwd`, and behavior is **exactly the same** as before this mapping was introduced
- In a bare-repo + worktree layout, `dirname(git-common-dir)` is just the bare repo's parent directory, not the main checkout — you must check that a `.git` exists under it before mapping, otherwise fall back to `cwd`

### Implementation Ownership

| Implementation | Location | Consumers |
|------|------|--------|
| shell | `rime_resolve_base` / `find_rime_dirs` in `hooks/scripts/rime-utils.sh` | the 4 hook scripts, rime-sdd's `sdd-workspace` |
| JS | `resolveBase` in `dashboard/server.mjs` | dashboard |

The two implementations must stay equivalent — the moment they drift, hooks and dashboard see different data. `rime_matches_changes` / `rime_label`'s path-prefix comparison must also use the mapped `base`; using `cwd` would never match under a worktree, causing session-end to skip silently.

### Migrating an Already-Tracked Project

The location stays the same — only untracking is needed (**no files need to be moved**):

```bash
git rm -r --cached .rime          # untrack, files stay in place
echo '.rime/' >> .gitignore       # if the entry isn't already there
```

There is no automated migration command: this operation touches user data, and the edge-case risk (uncommitted changes, target already existing, rollback on failure) isn't worth the two commands it would save.

### Ban on Referencing Untracked Assets

`.rime/` is never tracked, and `docs/` is untracked by default, so **tracked files must not reference untracked assets** — to anyone who clones the repo (including yourself on a different machine), these are all dangling references that resolve to nothing.

The following must not appear in **code comments, commit messages, or any tracked markdown** (README / AGENTS.md / skill docs):

| Referenced thing | Constraint |
|---|---|
| task ID (`#0001`), caution ID (`C-001`) | **Unconditionally forbidden** — `.rime/` is hard-never-tracked |
| Document paths under `docs/` (`docs/prd.md`, `docs/specs/*.md`) | **Conditionally forbidden** — forbidden while `docs/` is untracked (the default); allowed if the project has tracked `docs/` |

**Instead**: write the "why" directly into the comment itself. A comment should stand on its own, without depending on an external board.

| ✗ Dangling reference | ✓ Self-contained comment |
|---|---|
| `// see #0005` | `// under a worktree, toplevel points at the worktree; must be mapped back to the main checkout` |
| `// see the lesson from C-003` | `// --git-dir returns a relative path at the repo root; --path-format=absolute is required` |
| `// see docs/specs/xxx.md for details` | Extract the key constraint into the comment; leave the long background in the spec — don't reference it from the comment |

**Not subject to this restriction**: cross-references between files within `.rime/`, or between documents within `docs/` (they belong to the same untracked set — they distribute together or not at all). Writing `#0005` inside a spec is perfectly fine.

---

## General Format Conventions

- **task ID**: `#0001`, `#` + 4-digit zero-padding, globally unique, never recycled or reused, generated by incrementing `nextId`
- **caution ID**: `C-001`, hyphen + 3-digit zero-padding, incremented by the worker scanning the current maximum value
- **phase ID**: `P0`, `P1`, ...
- **date**: `YYYY-MM-DD`; **anchor timestamp field**: ISO 8601 with timezone (`2026-06-10T09:53:23+0900`)
- **schemaVersion**: currently `2` for tasks.json, `1` for phase.json, `1` for anchor. **Exception: cautions.json is a bare array with no schemaVersion** — changing the root type to an object would break deployed hooks (jq array append) and the dashboard; that migration is deferred until a genuinely breaking change happens alongside it

---

## tasks.json

Source of truth for task state.

### Root Structure

```json
{
  "schemaVersion": 2,
  "nextId": 1,
  "segments": {},
  "items": []
}
```

`segments` is optional; it assigns ID ranges by module: `{ "infra": "0001-0099", "feature-a": "0100-0199" }`.

### Item Fields

| Field | Type | Required | Description |
|------|------|------|------|
| id | string | ✓ | `#0001` format |
| module | string | | Feature module (corresponds to a `segments` key) |
| title | string | ✓ | Feature title (coarse-grained, human-defined) |
| description | string | | Detailed description; **write it multi-line** — background/goals/constraints/acceptance points split into lines or paragraphs (`\n`-separated); don't cram it into one long line — this helps human skimming and dashboard rendering |
| status | enum | ✓ | `todo` / `doing` / `done` |
| phase | string | ✓ | The phase it belongs to, taken from phase.json's `current` |
| priority | enum | ✓ | `high` / `medium` / `low` |
| difficulty | enum | | `small`(🟢 within half an hour) / `medium`(🟡 half a day) / `large`(🔴 1+ day) |
| createdAt | string | ✓ | `YYYY-MM-DD` |
| completedAt | string | | Filled in only when done |
| subtasks | array | | Adaptive execution checklist `[{title, status}]` |
| dependsOn | array | | List of dependency task IDs, forms a DAG, see below for details |
| branch | string | | The associated branch name, written after the user confirms while doing |
| commitFrom | string | | Automatically written with the HEAD hash while doing (overwritten every time), the start of the commit range |
| commits | object | | Written **in the same write** as status when marked done: `{ "from": "...", "to": "..." }` (from ≠ to); omitted for non-git projects |
| docs | array | | Written after producing a spec/plan/etc.: `[{ "type": "spec\|plan\|prototype\|reference\|blueprint", "path": "relative path" }]` |

### Write Constraints (all write paths must comply)

- If required fields (id / title / status / priority / createdAt / phase) are missing or malformed, **abort the write and report an error**
- `dependsOn` must undergo a **DFS cycle check** before being written (including self-dependency): a cycle rejects the write — the `dependsOn` graph is always a DAG
- When `dependsOn` is empty, **omit the key** — don't write `"dependsOn": []`
- `nextId` increments after a new item is added
- If `description` is filled in, it must be **written multi-line** (`\n`-separated background/goals/constraints/acceptance points, see the field table above); it may not be crammed into one long line
- An item **may only have fields listed in this file's field table written to it**; a new field requires revising this contract first (along with a schemaVersion evolution assessment) — consumers (dashboard/hooks) treat the field table as a whitelist
- **Commit gate**: must be satisfied before status changes to `done` — exempt for non-git projects (`git rev-parse --git-dir` fails), or when every deliverable of this task lives in untracked-by-design locations (`docs/`, `.rime/`) and the user has confirmed the deliverables (expressed by removing `commitFrom` and writing no `commits`, in the same write as `status`); otherwise, all of this task's changes are committed (uncommitted changes from parallel doing tasks don't count) and HEAD ≠ commitFrom; `completedAt` and `commits` are written **in the same write** as status
- **done is a terminal state**: no field of this item is written again after being marked done, with exactly two exceptions — archival removal on phase closing, and data fixes for validator errors; if a problem is found after done, create a new task to handle it, never roll back the status

### State Machine

`todo → doing → done`. doing is counted from entering the design/grill phase; done requires user confirmation and passing the **commit gate** (see Write Constraints). done is a terminal state: rework creates a new task, never rolls back the status. When a phase closes, that phase's done items are reclaimed into archives/.

### dependsOn Semantics

- Declares prerequisite dependencies **one-way**, never written back in reverse; the reverse `blockedBy` is computed live by the dashboard
- A dependency is considered satisfied once the depended-on task's status is `done`
- When starting a task, an unsatisfied dependency triggers only a **soft warning**, and doesn't block the transition
- References pointing to archived IDs are automatically removed on phase archiving (the active set keeps no dangling references)

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

| Field | Type | Required | Description |
|------|------|------|------|
| current | string | ✓ | ID of the currently active phase |
| phases[].id | string | ✓ | `P0`, `P1`, ... |
| phases[].name | string | ✓ | Phase name |
| phases[].status | enum | ✓ | `active` / `done` |
| phases[].startedAt | string | ✓ | `YYYY-MM-DD` |
| phases[].completedAt | string | | Written at phase closing, the object is updated in place (not replaced, not deleted) |

---

## cautions.json

A bare array, append-only, with no status field. Automatically extracted by the SessionEnd worker, or appended manually.

```json
[]
```

| Field | Type | Required | Description |
|------|------|------|------|
| id | string | ✓ | `C-001` format |
| title | string | ✓ | Short title |
| summary | string | | Detailed description |
| tags | array | | Classification tags, **participate in match-injection** (see below) |
| reference | string | | commit hash / file path / link |
| createdAt | string | ✓ | `YYYY-MM-DD` |
| source | string | | `session-{TIMESTAMP}`, auto-filled by the worker |

### Match-Injection Rules

When rime-flow starts a task: keywords from the task's `title` + `description` are matched against a caution's `tags` + `title` via **substring matching** (for CJK text, a plain substring-containment check). Matched cautions are injected into the conversation context; if there's no match, skip.

### Inclusion Criteria

Only include lessons and constraints that **could recur** (implicit platform limitations, side effects of architectural decisions, recurring pattern mistakes); don't include one-off bugs already fixed, one-off migration issues, or content already covered by documentation. Entries that are no longer relevant are deleted outright on a regular basis; in addition, on every task completion rime-flow performs an **incremental GC** — reviewing only entries added while that task was in progress, judged as DROP / MERGE / KEEP (see "Completing a task" in SKILL.md for the process); deletions/merges keep the existing ids without renumbering.

---

## anchors/{TIMESTAMP}.json

Session records, auto-generated on every SessionEnd. **Gitignored, never tracked**; cleaned up on phase closing, keeping only the most recent 10 globally.

- **Filename**: `YYYY-MM-DDTHH-MM-SS.json` (local time, hyphen-separated)
- **Written by**: when the conversation is too short, session-end.sh synchronously writes a minimal anchor (all arrays empty); normally, a background worker calls `claude -p` to generate the full content

| Field | Type | Description |
|------|------|------|
| schemaVersion | number | `1` |
| timestamp | string | ISO 8601 with timezone |
| phase | string | phase.json's `current` at write time |
| workedOn | array | Task IDs involved (only ones that already exist in tasks.json) |
| subtasksCompleted | array | Work completed this session. **Drives conservative reconciliation**: limited to tasks in workedOn with **status=doing**; when an entry exactly equals or is a mutual substring of a subtask title, the worker automatically flips that subtask to done (one-directional, never flips back); non-matching entries are recorded only |
| subtasksAdded | array | New subtasks discovered (free-form description, recorded only) |
| decisions | array | Key decisions |
| nextSteps | array | Next steps |
| cautions | array | Extracted pitfalls `[{title, summary?, tags?}]` — the worker fills in id / createdAt / source when appending to cautions.json |

session-start.sh reads the **most recent** anchor's `timestamp` / `workedOn` / `decisions` / `nextSteps` and injects them into the new session's context.

---

## archives/tasks.P{n}.json

An **immutable snapshot** written at phase closing; it does not update afterward when other files change. Untracked along with the rest of `.rime/` (see "Storage Location & Resolution Order").

```json
{
  "phase": "P2",
  "name": "Quality Improvements",
  "completedAt": "2026-03-20",
  "items": [...]
}
```

- `items` preserves full task objects (all fields as-is)
- `phase` / `name` / `completedAt` are taken from phase.json
- The dashboard reads it on demand via the `/archives/{phaseId}` route
- Archive snapshots are not covered by mechanical validation (validate-tasks.mjs only covers `tasks.json`)
