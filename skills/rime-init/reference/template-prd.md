# PRD Template

The PRD is the project's product positioning and spec description. **Write the PRD before starting work.**

Task status is managed by `.rime/tasks.json`; the PRD is narrative-only.

## Template

```markdown
# {Project Name} — Product Requirements Document

## Overview

One sentence stating what this is and what problem it solves.
State the positioning clearly: personal tool / open-source project / commercial product.

## Core Philosophy

- **Keyword** — one-sentence explanation
- 3-5 items establishing the design philosophy

## User Persona

A paragraph describing: target user identity, work habits, core pain points.

## Core Flow

<!-- Show the main scenario with a real example -->
<!-- UI screenshots / CLI output / usage flow / directory structure, etc. -->

## Feature Plan

> Task status is managed by `.rime/tasks.json`.
> Completed phases are archived to [archive.md](archive.md).

### P0 — MVP

This phase's goal: one-sentence description.

- #001 Feature title — brief description
- #002 Feature title — brief description

<!-- Early on, the PRD may list the plan for all phases P0-P2 -->
<!-- After a phase completes: the PRD keeps only the current and future phases -->

### Future Directions

(Large-grained ideas, not assigned an ID; after evaluation, bring into tasks.json via /rime-backlog)

## Non-Functional Requirements (as needed)

| Requirement | Description |
|------|------|
<!-- Use concrete numbers: startup < 200ms, supports 10K records, etc. -->

## Out of Scope

- Explicitly list features that won't be built
- Draw the boundary to prevent scope creep

## Tech Stack (dev projects)

| Purpose | Choice | Notes |
|------|------|------|

## Related Documents

| Document | Content |
|------|------|
| .rime/tasks.json | Task status (source of truth) |
| archive.md | Archive of completed phases |
| product/ | Detailed specifications |
```

## Writing Notes

- **The PRD is a narrative document**, describing product positioning, goals, and feature specs
- **Task status is not managed in the PRD** — that's `.rime/tasks.json`'s job
- **Use a reference list for the feature plan** (`- #001 Title — description`), not a status table
- **Use real examples for the core flow**, not abstract descriptions
- **"Out of Scope" is mandatory** — the easiest to skip and the most valuable
- After a phase completes, move it into archive.md; the PRD keeps only the current and future phases
