# AGENTS.md Generation Guide & Template

This file has two parts: the **generation guide** (instructs rime-init step A2 on how to generate AGENTS.md) and the **template body** (the content of the generated artifact).

---

## Generation Guide

### Pre-check

The rime workflow depends on the following external skills (mattpocock/skills, MIT License); if not installed, the corresponding capability is degraded:

| External skill | Purpose | Impact if missing |
|------------|------|----------|
| `grill-me` / `grill-with-docs` | Converging medium / large task design | Degrades to plain conversational design, no structured interrogation |
| `tdd` | rime-sdd implementer follows TDD | rime-sdd's subagent has no TDD constraint |
| `review` | rime-sdd final whole-branch review (Standards + Spec axes) | large tasks lack a final quality gate |

- Detection method: check whether a skill of the same name exists in the skill install locations (`~/.agents/skills/`, the project's `.agents/skills/`, or the relevant tool's skill directory)
- If not installed, remind the user: the capabilities above will be degraded, and can be installed from [mattpocock/skills](https://github.com/mattpocock/skills)
- After the reminder, continue generating the full template (external skills can be installed anytime — it doesn't affect the template content)

### Tracked-in-git Decision

Ask the user whether AGENTS.md should be tracked in git:
- Tracked: shares the AI collaboration conventions with the team
- Gitignored: don't want to disturb collaborators, or an open-source project that doesn't want this public

### Optional Interaction

Present the following options all at once; the user answers each one or skips.

**Language settings** (three independent options; unselected ones aren't written)

- AI communication language
- Code comment language
- Default UI copy language

**Verification method** (unselected → not written)

- a) The user manages the dev server manually; the AI neither starts it nor verifies
- b) The AI may start the dev server and verify on its own
- c) Use agent-browser for browser-based verification

### Automatic Tech-Stack Skill Mapping

During init, automatically detect the project's tech stack and write in the matching skill rules.
Detection method: scan package.json dependencies + project config files (e.g. tailwind.config.*, tsconfig.json). Content projects (no package.json) skip this step.

| Detection condition | Content written |
|----------|----------|
| TypeScript / JavaScript | `JS/TS development follows the rime-js skill` |
| CSS / Tailwind | `CSS architecture follows the rime-css skill` |
| React | `React component development follows the rime-react skill` |
| Has a UI (HTML/CSS/JSX/TSX) | `UI design quality follows the rime-design skill` |

> When adding a new rime skill, update this mapping table accordingly.

### CLAUDE.md Bridge

Claude Code natively reads only `CLAUDE.md` — **it never reads `AGENTS.md`**. After generating AGENTS.md, a bridge is mandatory, otherwise the rules never get loaded:

- Project has **no** `CLAUDE.md` → create `CLAUDE.md` containing only the single line `@AGENTS.md` (import syntax; expanded in place to load AGENTS.md at session start)
- Project **already has** `CLAUDE.md` → check whether it already contains `@AGENTS.md`; if not, **append that line at the top** of the file — never touch the user's existing content
- **Don't use symlinks** (`ln -s`): `@import` is cross-platform consistent (Windows symlinks need admin/developer mode) and transparent to collaborators
- `CLAUDE.md`'s tracked-in-git policy **follows AGENTS.md**'s (both tracked, or both gitignored), avoiding a dead link where "the bridge exists but the linked file doesn't"

### Document Map

Generate a "Document Map" section at the bottom of AGENTS.md pointing to the `docs/` documents, giving the agent a single entry point:

- **List only the documents actually created** (whatever A5 created, list those; skip the rest)
- A flat list, one line per document: `- [type](relative path) — one-sentence purpose`
- Write this in **after A5 creates the docs/ documents** (docs don't exist yet when A2 generates AGENTS.md)

---

## Template Body

### Fixed Content (All rime Projects)

```markdown
# AGENTS.md

## Task Execution Mode

All tasks are managed through the rime-flow lifecycle. Use `/rime-dashboard` to check progress.
Execute by complexity tier:

| Tier | Scenario | Approach |
|------|------|------|
| small | Single-file changes, small bugs | Just do it, no discussion |
| medium | Clear goal but path needs confirming | grill-me converges the design → spec → subtasks, iterate while implementing |
| large | Multi-file changes, new features, architecture changes, tech selection | grill-me converges the design → spec (with `## Task N` sections) → rime-sdd orchestrates execution |

### Evidence First

Don't guess by reasoning — get the facts before acting.

| Scenario | Anti-pattern | Correct behavior |
|------|--------|---------|
| Unsure how an API / library works | Try parameter combinations in context | Check local docs → curl the actual response → context7 / web search |
| Hit a bug / unexpected behavior | Patch based on local code alone | Trace the overall flow first, add console.log to localize it, get the actual value before fixing |
| Two attempts in a row have failed | Keep retrying with different parameters | Stop and search the error message or a proven approach |
| Need to implement a common pattern | Write it from scratch | Check first whether a proven library / pattern exists |

Not applicable to: pure business logic, project-specific domain knowledge (scenarios with no external reference to search for).

After a change is complete, review the changed scope and clean up leftover debug code and dead logic.

### Rime Alignment Rules

Execution must stay in sync with tasks.json:
- Once a spec is finalized, map its execution steps onto tasks.json subtasks (add/split)
- Update a subtask's status as soon as it's completed
- Confirm the task status is `doing` before starting execution
- Write the verification checklist into the spec's verification section first, then present it to the user (medium / large)
- Before marking `done`, pass the commit gate: every change for this task is committed and there's a new commit (HEAD ≠ commitFrom; exempt for non-git projects); `completedAt` / `commits` are written in the same write as status; no backfilling after done — rework opens a new task
- If a task is found to need adjustment during execution (complexity change, needs splitting), update tasks.json immediately before continuing

## Git

Commit uniformly via `/rime-git`.

## Constraints

- Don't use EnterPlanMode (complex tasks go through grill-me → spec → rime-sdd)
- **Ban on Referencing Untracked Assets**: `.rime/` is untracked and `docs/` is untracked by default, so code comments, commit messages, and tracked markdown must not contain task IDs (`#0001`), caution IDs (`C-001`), or paths under `docs/` — to someone who clones the repo, these are dead links to nothing. Comments must be self-contained: write the "why" directly into the comment instead of pointing at the board. `// see #0012` ✗ → `// this endpoint returns null instead of [] for an empty array` ✓
```

### Dynamic Content (Generated from Detection/Interaction Results)

**Language settings** (generated after the user chooses; not written if skipped):

```markdown
## Language

- AI communication: Chinese
- Code comments: Japanese
- UI copy: Japanese, with technical terms kept in English
```

**Verification method** (generated after the user explicitly chooses; not written if skipped):

```markdown
## Verification

- The user manages the dev server manually; the AI neither starts it nor verifies
```

**Skill usage** (generated after auto-detection; not written if there's no match):

```markdown
## Skill Usage

### CSS
- CSS architecture follows the `rime-css` skill

### React
- Run `react-doctor` when finishing a feature, fixing a bug, or reviewing
- Follow the `rime-react` skill when writing/refactoring components
```

**Document map** (generated after A5 creates the documents, listing actual output; not written for anything not created):

```markdown
## Documents

- [prd](docs/myapp-prd.md) — Product positioning and feature plan
- [techstack](docs/myapp-techstack.md) — Tech stack choices and project structure
- [DESIGN.md](docs/DESIGN.md) — Design system (tokens + rationale, google-labs DESIGN.md format)
```

### CLAUDE.md (Bridge File, Same Directory as AGENTS.md)

Create it if there's no CLAUDE.md, with just this one line; if it already exists, append this line at the top:

```markdown
@AGENTS.md
```
