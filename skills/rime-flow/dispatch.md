# Task Dispatch Contract (Authoritative)

The single authoritative rule set for task dispatch (subagent + model). Whenever rime-flow / rime-sdd needs to decide "who does it, with which model," this file is the source of truth — other docs keep only a pointer, never a full restatement.

One-sentence motivation: keep fable / opus quota for dispatching and design, and push implementation work down to cheaper models.

---

## Main Thread = Dispatcher

The main thread's (fable's) responsibilities are limited to:

- grill / spec design
- Context curation (preparing self-contained dispatch material for subagents)
- Dispatching subagents
- Reviewing diffs, accepting work
- tasks.json state transitions

Outside the following two cases, the main thread never implements directly:

1. **The trivial exception** (test below)
2. **Fallback at the top of the escalation chain**: when even opus can't solve it, the problem falls back to the main thread to handle personally

---

## The trivial Test

⚠ trivial is not a difficulty enum value in tasks.json (the enum remains small / medium / large — see data-contract.md); it's a downgrade judgment made **at execution time** for a small task. tasks.json still records it as small.

All three conditions must hold **simultaneously** to count as trivial:

- Single file
- Roughly 10 lines or fewer
- No design-judgment component

When all three hold → the main thread does it directly. The context-rebuilding overhead of dispatching would exceed the benefit — dispatching would end up slower and more expensive.

---

## Dispatch Shape by difficulty

| difficulty | Dispatch shape |
|------|------|
| trivial (an execution-time judgment on small) | Main thread does it directly (no dispatch) |
| small | After the user confirms the pre-dispatch brief (authoritative rule: SKILL.md "small: Pre-dispatch Brief"), dispatch 1 implementer subagent to finish in one pass; main thread accepts the diff |
| medium | After the main thread grills → spec, dispatch implementers **serially**, segment by segment, by subtasks (not in parallel, to avoid conflicts); main thread reviews the diff after each segment; **no reviewer subagent is dispatched** |
| large | Orchestrated by rime-sdd (per-task implementer + reviewer + final review); model tiers follow this file |

---

## Commit Responsibility

| difficulty | Who commits |
|------|------|
| trivial / small / medium | The implementer does not commit; after the main thread's diff review passes, it makes one consolidated wrap-up commit (`/rime-git`) |
| large | Within rime-sdd orchestration, the implementer commits per task on its own |

---

## Model Tiers

| Tier | Model | Applicable scenarios |
|------|------|------|
| Low | haiku | Transcribing a spec that already contains complete code, mechanical single-file tweaks, renaming/formatting |
| Mid | sonnet | Routine implementation from a prose spec, multi-file integration, general review, read-only investigation (Explore) |
| Top | opus | Architectural judgment, complex debugging, concurrency/security-sensitive changes, final whole-branch review |

⚠ **fable / session inheritance**: never given to a subagent, reserved for the main thread only. **A model must be explicitly specified when dispatching** — omitting it means inheriting the session model (the most expensive), which silently breaks this contract.

> Tiers are an abstraction; the model aliases (haiku/sonnet/opus) are resolved by Claude Code to the current generation's models as they evolve.

---

## Agent Type Mapping

| Type of work | agent type |
|------|------|
| Read-only investigation / code exploration | `Explore` (the prompt must explicitly require using Read/Grep/Glob tools to read files and search code; piping bash's cat/grep is forbidden) |
| Implementation / bug fixing | `general-purpose` |
| Review (within the large flow) | rime-sdd's reviewer template |
| Draft plan before implementation (if needed) | `Plan` |

---

## Escalation Rules

- If a subagent reports **BLOCKED** or **the same segment is reworked twice** → escalate one tier and re-dispatch (haiku→sonnet→opus); **retrying with the same model as-is is forbidden**
- The top tier stops at opus; **if opus still can't do it → fall back to the main thread to handle personally** (fallback at the top of the escalation chain)

---

## Review Cost Model

Review is the largest fixed cost in the SDD flow. Three principles (the orchestration mechanics live in rime-sdd's Review Loop Cost Rules, not restated here):

- **Tiered re-review**: the depth of the post-fix re-review is downgraded based on **the highest severity fixed in this round** — a round containing a Critical / Important fix → dispatch a reviewer subagent for re-review; a round with only Minor / comment / test-only fixes → the main thread reads the fix diff and stands in. **Downgrading lowers the channel, not the bar**, and it applies only to re-review rounds — the first review round is always a full gate.
- **Reviewer stays resident and is reused**: per-task freshness guards against implementation-context contamination, and applies only to the implementer; the reviewer is the opposite — it stays with a task from the first round through to the final re-review (a warm context saves the fixed cost of re-reading the brief/diff every round), then is discarded when the task ends — **never reused across tasks**.
- **Auxiliary review batches up**: language / documentation auxiliary reviews (copy review, jp-review, etc.) don't run per commit or per review round — they're **batched to a single sweep at task wrap-up** over the full set of changes.

Accompanying discipline: each round, the reviewer must deliver a **complete verdict report in its final message** — going idle or sending only an acknowledgment does not count as completing re-review; the main thread re-prompts it. If it still delivers no report, treat the agent as dead and dispatch a fresh reviewer.

---

## Dispatch Prompt Contract

A prompt dispatched to a subagent must be self-contained:

- Task description
- Files involved (paths)
- Interface / global constraints
- Acceptance criteria
- Report format
- **Comment ban** (must be communicated explicitly every time — a subagent has no way to know this on its own): comments written into code must not contain task IDs (`#0001`), caution IDs (`C-001`), or `docs/` paths — these are untracked by default and are dead links to anyone who clones the repo. Comments should be self-contained: write the "why" directly into them. See "Ban on Referencing Untracked Assets" in [data-contract.md](data-contract.md) for the authoritative definition.

Dispatch prompts and subagent reports are written in English.

**A subagent never inherits the main thread's conversation history** — a fresh subagent works only from the information given in its prompt.

This is exactly why the previous point matters: the main thread knows what `#0012` refers to, a fresh subagent does not — so it copies it verbatim into a comment, leaving behind a reference no one can ever trace.

Large artifacts (diffs, reports) are handed off **via file path**, not pasted into the conversation.
