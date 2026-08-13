---
name: rime-flow
description: Use when starting or executing a task from tasks.json, updating task status, closing a phase, or maintaining project docs. Daily lifecycle management — tasks.json status flow (todo → doing → done), phase lifecycle, and doc-update rules. Triggers: executing or starting a tasks.json task, updating task status, archiving a phase, maintaining docs.
---

# Daily Lifecycle Management

Manages day-to-day state transitions in the `.rime/` data layer. For new projects, use `/rime-init`.

---

## Task Lifecycle

```
User defines a feature → /rime-backlog (alias /rime-task) → tasks.json (status: todo)
    ↓ User says "do #xxx", "execute #xxx", "grill #xxx", etc. (if no matching task exists, create one first — see step 0 below)
tasks.json (status: doing)  ← entering the design/grill phase counts as starting
    ↓ Execution shape decided by difficulty
    ├─ trivial → main thread implements directly (the only exception; see dispatch.md for the test)
    ├─ small  → pre-dispatch brief confirmed by the user → dispatch 1 implementer subagent to finish in one pass (model per dispatch.md; see "small: Pre-dispatch Brief")
    ├─ medium → grill-me converges the design → spec → dispatch implementer(s) by subtasks (subtasks are a living plan, edited as work proceeds)
    └─ large  → grill-me → spec (with ## Task N sections) → rime-sdd orchestrates execution (subagent per task + per-task review)
    ⚠ The spec locks design intent; tasks.json subtasks are an adaptive execution checklist — add/remove items freely when reality diverges from expectations
    ⚠ Dispatch rules (subagent + model) are defined in dispatch.md: the main thread only dispatches — implementation work is delegated to a subagent with an explicitly specified model tier
    ⚠ Once a spec file is produced, write its path into the task's docs field
    ↓ Once done, after the user confirms OK and changes are committed (zero commits → may not be marked done)
tasks.json (status: done, completedAt: today)
    ↓ On phase closing
archives/tasks.P{n}.json archived → archive.md narrative summary → tasks.json removes archived items
```

## small: Pre-dispatch Brief

small tasks skip the grill/spec phase, but not confirmation. Before dispatching the implementer, the main thread presents a short **in-conversation brief** — a few lines in the user's conversation language, not persisted to disk: which files will change, the intended approach, and the acceptance criteria. **Dispatch only after the user confirms the brief** — "do #xxx" authorizes starting the task (status → doing), not the implementation approach.

- **Visual/style small tasks upgrade to an HTML spec**: when the change concerns layout, UI appearance, or styling — where a text brief can't convey what will be seen — write an HTML spec and get the user's confirmation first (see "Spec Format" below; the task then follows the with-spec verification path). small difficulty is no exemption from visual confirmation.

## Design phase: grill-me

For medium / large tasks, converge the design and produce a **spec** before touching code. The default is grill-me style, question-by-question grilling:

> Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.
>
> Ask the questions one at a time.
>
> If a question can be answered by exploring the codebase, explore the codebase instead.

> The original grill-me prompt is from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT License).

- **grill-me (convergence) is the default**: when the user arrives with a direction, grill to pin down every branch of the decision tree. Use `grill-with-docs` when ADRs / glossary need to be produced alongside.
- Once convergence is done, write the **spec**, capturing key decisions + rationale + rejected alternatives — a spec outlasts an implementation plan.
- **When a visual question comes up during grilling** (layout / UI appearance / option comparisons that words alone can't convey): **ask the user first** whether to switch on an **HTML-format spec** to sketch mocks for discussion; if the user agrees, create the HTML spec (see "Spec Format" below).

### Spec Format

- Default is **Markdown**, placed in `specs/` at the same level as `plansDirectory` (default `docs/specs/*.md`, see "Implementation › Doc Placement" below).
- Specs involving **UI** use **HTML**: wireframes can be drawn and runnable mocks embedded. See `rime-init`'s `reference/template-spec.html` for the template (numbered sidebar navigation + decision table + phone/desktop dual mock frames). The dashboard's `/file` renders `.html` natively — open it and you see it directly. Set the body font to match the spec's language: Chinese `'Noto Sans CJK SC', system-ui`, Japanese `'Noto Sans CJK JP', system-ui`; don't stack a Latin webfont (Jost, etc.) in front of it, or CJK weight/size will look inconsistent.
- **When a visual question arises** (needing to show layout, compare layout options, or discuss UI appearance and interaction): **get the user's agreement first**, then write that spec in **HTML format** (not Markdown); present runnable mocks and comparison frames inside the HTML spec — **what you see is what you discuss** — visual discussion converges inside the spec file, and the dashboard's `/file` shows it the moment it's opened.
- **Verification section**: when the task is complete, **first** append a verification-record section to the end of the spec (heading written in the spec's own language; checklist items persisted one by one, in unverified state `- [ ]`), **then** present the verification checklist to the user in the user's conversation language along with the spec path; after the user verifies and reports back, fill in the results (check off passed items + pass date). The spec closes the loop — it opens with design intent and rejected alternatives, and closes with verification evidence. Verification content is written only to the spec, never to tasks.json.

### Implementation

Once the spec is finalized, the main thread switches into the **dispatcher** role: implementation work is dispatched to subagents per [dispatch.md](dispatch.md) with an **explicitly specified model** (the fable/session model is never delegated down); for medium tasks, dispatch serially, segment by segment, following subtasks, with the main thread reviewing the diff after each segment; only **trivial** changes are done directly by the main thread.

- Once the spec is finalized, map the execution steps onto tasks.json **subtasks, updated as work proceeds** (no heavyweight plan document is written). Subtasks are the adaptive execution checklist.
- The spec for a **large** task should include `## Task N` sections (one section per task: requirements, interface constraints, acceptance criteria); once finalized, use `rime-sdd` to orchestrate execution — each task gets a fresh implementer subagent + a per-task spec/quality review gate + a final whole-branch review. Medium tasks are dispatched for implementation segment by segment, in subtask order.

> **⚠ Doc Placement (configuration-driven)**
> Placement is driven by the **Claude Code `plansDirectory` setting**:
> - **spec** → `specs/` at the **same level** as `plansDirectory` (e.g., `plansDirectory` = `./docs/plans` → spec goes to `./docs/specs/`); **if unconfigured, default to `docs/specs/` at the project root**. Filename: `YYYY-MM-DD-<topic>-design.md`
> - **plan** (if needed) → the directory pointed to by the Claude Code `plansDirectory` setting (project `.claude/settings.json` takes precedence, otherwise `~/.claude/settings.json`); **if unconfigured, default to `docs/plans/` at the project root**. Filename: `YYYY-MM-DD-<feature>.md`

### Starting a task

When the user says something like "do #0011", "start task xxx", "grill #xxx" (including starting the grill/design phase):

0. **If no matching task exists, create one first**: if the ID the user gave doesn't exist in tasks.json, or the user directly describes work that isn't registered yet (e.g., "help me build feature XX"), first go through the `/rime-backlog` (alias `/rime-task`) flow to create the task and get an ID, then continue from step 1. All work entering the execution flow must first have a corresponding item in tasks.json.
1. Read `.rime/tasks.json` and find the matching item
2. Update status to `doing` (entering grill/design counts as starting — no need to wait until code is written)
3. Read `.rime/cautions.json`; match the task's title + description keywords against the cautions' `tags` + `title` fields via substring matching (for CJK text, a plain substring-containment check); any matched cautions are injected into the current conversation context, otherwise skip
4. Assess whether difficulty is reasonable: the AI re-evaluates difficulty (small / medium / large) from the task's title + description + subtasks; if it disagrees with the difficulty recorded in tasks.json, prompt the user to confirm and update it
5. **Soft warning on dependencies** (a text prompt only, the user decides): read the task's `dependsOn`, check the status of each dependency task; if any are not `done`, list those dependencies (id + status) and prompt the user, delivered in the user's conversation language: "The following dependencies aren't done yet — do you still want to start now?" This doesn't block the state transition; the user decides.
6. Decide the execution shape by difficulty (see the lifecycle diagram above); dispatch rules are in [dispatch.md](dispatch.md)
7. **Record commitFrom**: run `git rev-parse HEAD`; on success, write it into the task's `commitFrom` field (overwritten every time the task enters doing). If the command fails (not a git repo, etc.), skip silently.
8. **Backfill docs**: as soon as a spec/prototype/formal document produced during the grill/design phase is written to disk, immediately write it into the task's `docs` field (`[{type, path}]`, see data-contract for the type enum) — don't wait until task completion to add it
9. **Branch suggestion** (text suggestion only, the user decides), presented in the user's conversation language:
   - `small` → no suggestion
   - `medium` → optional suggestion: "You could create a new branch `feature/xxx` for this task, or just develop on the current branch"
   - `large` → strong suggestion: "Recommend creating a dedicated branch `feature/xxx` for this task"
   - Naming format: `feature/xxx` / `fix/xxx`, descriptive, without the task ID
10. **Record the branch**: after suggesting, ask the user, in the user's conversation language: "Have you created the branch? If so, provide the branch name; press enter to skip." If the user provides one, write it to the task's `branch` field; if skipped, leave it unwritten.

### Completing a task

1. **Incremental cautions GC**: read `.rime/cautions.json` and filter to entries added since the last GC pass — `createdAt` ≥ the `completedAt` of the previous done task in the active set; if there is none, use the date this task entered doing (`git show -s --format=%cs <commitFrom>`, or the task's `createdAt` if there's no `commitFrom`). The boundary is inclusive of that day — err on the side of over-including rather than missing entries; re-reviewed entries keep their prior verdict. Judge entry by entry, **do not do a full scan**:
   - **DROP** (delete outright) if any of: a one-off incident (a syntax slip, a commit mistake, a wrong-branch mishap); a session status report ("XX not updated", "XX pending confirmation", "XX unrelated to this round"); a project figure/decision record (amounts, durations, sizes, etc. — these belong in anchor decisions, not cautions); common knowledge everyone already knows (cache needs refreshing, a warning doesn't affect functionality)
   - **MERGE**: if it teaches the same lesson as an existing entry → delete the new one and keep the old; if the new entry has more complete information, fold the additional detail into the old entry's `summary`
   - **KEEP**: reusable technical lessons — pitfalls that would recur in a different project or at a different time (browser compatibility, CSS/Canvas/API behavior, data-loss lessons, security issues, etc.)
   - One-sentence test: "Three months from now, in a different project, facing a similar scenario — would this still be useful?" Keep it only if the answer is yes.
   - Edit cautions.json directly — the change takes effect once written; **keep existing ids, don't renumber**; when done, report to the user in one sentence, in the user's conversation language (how many were removed, how many kept)
2. If there are subtasks, confirm they are all complete
3. **Wrap-up commit**: commit all of this task's changes in full (via `/rime-git`); fixes made during verification are committed additionally as usual
4. **Generate the verification checklist — persist first, present second**: based on the task's title + description and the `commitFrom..HEAD` diff, generate **actionable** steps (which command to run, which page/element to open and click, what result counts as passing); when there is a spec, cross-reference its design intent and translate acceptance points into concrete steps the user can run/click right now
   - **With a spec**: first append a verification-record section to the end of the spec (heading in the spec's own language; checklist items persisted one by one, in unverified state `- [ ]`), then present it to the user, in the user's conversation language, along with the spec path. Do not ask the user to start verifying until the spec is persisted to disk.
   - **Without a spec**: present in conversation only, in the user's conversation language, in the format "You can verify this as follows: ① … ② … ③ …"
5. **Actual user verification** — wait for the user to run through it and report back; never decide pass/fail on the user's behalf. **Implementing and marking done in the same turn is prohibited**: the done write may only happen after the user has replied confirming verification — an uninterrupted implement → commit → done run is exactly the violation this step exists to stop
6. **Backfill the verification record**: with a spec → update the spec's verification section: check off passed items with a pass date, and record the issue and follow-up for items that failed; without a spec → close the loop verbally. Verification content is **never written to tasks.json**
7. **Commit gate → mark done (in one write)**:
   - **Gate** (exempt for non-git projects: if `git rev-parse --git-dir` fails → skip the check and go straight to marking done): all of this task's changes are committed (uncommitted changes from other tasks concurrently doing don't count); `git rev-parse HEAD` ≠ `commitFrom`. If either condition fails → **may not be marked done** — go back to step 3 and finish committing. A git project missing `commitFrom` → confirm the starting commit with the user, backfill `commitFrom`, then pass the gate
   - **Marking done**: once the user confirms OK, complete `status: done` + `completedAt` + `commits: { "from": "<commitFrom>", "to": "<HEAD>" }` **in the same write** (omit `commits` for non-git projects)
   - **done is a terminal state**: no field of this task is written again afterward, with exactly two exceptions — archival removal on phase closing, and data fixes for validator errors; if a problem is found after done → create a new task to handle it, never roll back the status
   - When multiple tasks are doing in parallel, their commit ranges may overlap — this is expected

---

## Doc Update Rules

| Trigger | Update |
|------|----------|
| Found an improvement / new idea | Add it to tasks.json via `/rime-backlog` (alias `/rime-task`) (status: todo) |
| Phase completed, starting the next one | Trigger the Phase Closing Flow (see below) |
| New dependency / tech-stack change `[dev]` | Update techstack.md |
| Interaction behavior change `[dev]` | Update the corresponding section of interaction.md |
| Data structure change `[dev]` | Update schema.md |
| User says "update the docs" | Update README.md + the core docs at the docs/ root (excluding subdirectories) |

How to update:

- **PRD narrative update**: when feature planning changes, update the reference list; anything cut gets added to "Things we're not doing"
- **Archive**: write the phase summary once the entire phase is complete
- **techstack.md Phase checklist** `[dev]`: check off `[x]` for completed items; append directly for new phases
- Research content goes in `docs/researches/`, design content in `docs/designs/` — not at the root
- Detailed specifications go in `docs/product/`; the PRD stays at summary level and links over to them

---

## Phase Closing Flow

When every task's status within a phase becomes `done`:

1. Prompt the user, in the user's conversation language, on whether to close the phase
2. Once the user confirms:
   - `phase.json`: set that phase's status → `done`, record `completedAt`
   - `.rime/archives/tasks.P{n}.json`: write all of that phase's done tasks (full task objects preserved as-is). The archive JSON is an immutable snapshot taken at closing time — it does not update afterward when other files change
   - `archive.md`: append a narrative summary of the phase (no task list)
   - `tasks.json`: remove that phase's done items; after removal, scan the `dependsOn` of all remaining tasks and delete references pointing to archived IDs (a dependency is considered resolved once satisfied — the active set keeps no dangling references; details live in the archive)
   - `anchors/`: delete old anchor files, keeping only the most recent 10 globally
   - `prd.md`: remove content for the archived phase
3. To start a new phase: the user defines it in prd.md, and the AI updates phase.json to match

> The archive.md narrative for already-closed phases like P0/P1 stays unchanged; this flow applies starting from the next phase that closes.

### Archive JSON Format

See the archives section of [data-contract.md](data-contract.md) for the path and fields. Key points: an immutable snapshot, items preserve full task objects, phase/name/completedAt are taken from phase.json.

---

## Rules & Constraints

### Write Constraints

**Every path** (manual AI updates, the `/rime-backlog` command) writing an item to tasks.json must satisfy the "Write Constraints" in [data-contract.md](data-contract.md): all required fields present (missing → **abort the write and report an error**), `dependsOn` passes a DFS cycle check first (a cycle → **reject the write**; the graph is always a DAG), and an empty `dependsOn` omits the key.

### ID Rules

All feature items use a **globally incrementing ID** `#0001`, `#0002`, ...:

- The ID is generated by incrementing `tasks.json`'s `nextId`, zero-padded to 4 digits
- IDs are globally unique, never recycled or reused
- Assigned automatically when adding a new item via `/rime-backlog`

### docs/ Directory Rules

- `.rime/` is **never tracked in git** — a hard requirement, not overridable by the user (tracking it causes merge conflicts and **silent state drift when switching branches**; see "Storage Location & Resolution Order" in [data-contract.md](data-contract.md))
- `docs/` is untracked by default; its policy is **independent** of `.rime/` and decided separately (`.rime/` is mutable state, `docs/` is documentation output)
- **Tracked files must not reference untracked assets**: don't write task IDs (`#0001`), caution IDs (`C-001`), or `docs/` paths in code comments, commit messages, or tracked markdown — they're dead links to anyone who clones the repo. Make comments self-contained: write the "why" directly into the comment itself. When dispatching a subagent, this must be communicated explicitly (it has no idea what `#0012` refers to). See "Ban on Referencing Untracked Assets" in [data-contract.md](data-contract.md) for details.
- Core docs (prd, archive, techstack, etc.) live at the root
- Subdirectory names use the **plural form** (specs, plans, researches, designs)
- `specs/` (spec: design intent + decisions + verification log) sits **alongside** `plans/` (plan: a temporary execution plan): placement follows the Claude Code `plansDirectory` setting; **if unconfigured, default to `docs/specs/` at the project root** (plan directory `docs/plans/` if needed)
- `product/` holds detailed specifications (the outcome of discussions for complex features)

---

## Data Layer Reference

**The authoritative definition of fields, enums, ID formats, and read/write ownership for the five `.rime/` file types is [data-contract.md](data-contract.md).** Read it first whenever field-level detail is involved.

The authoritative definition of dispatch (subagent + model tier) is [dispatch.md](dispatch.md).

| File | Responsibility |
|------|------|
| `.rime/tasks.json` | Source of truth for task state (items + subtasks + dependsOn) |
| `.rime/phase.json` | Current phase, historical phases |
| `.rime/cautions.json` | Pitfall records, append-only, auto-extracted by the SessionEnd hook |
| `.rime/anchors/` | Session records, auto-generated, gitignored |
| `.rime/archives/` | Immutable task snapshots taken at phase closing |
| `docs/prd.md` | Product positioning and spec, a narrative document, references tasks.json via #ID |
| `docs/archive.md` | Phase narrative archive, summary written at phase closing |
