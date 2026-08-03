---
name: rime-init
description: Use when initializing a new project or migrating an old project to the rime workflow. New-project scaffolding + legacy migration — create the .rime/ data layer, docs/ skeleton, and AGENTS.md, and configure the dev toolchain. Triggers: initializing a new project, migrating a legacy-format project.
---

# Project Initialization & Migration

Initialize a new project or migrate a legacy project onto the rime workflow. For day-to-day management, use `rime-flow`.

---

## Scenario A: New Project

The project has just been created and needs a documentation skeleton and AI collaboration rules.

### A1. Determine Project Type

| Type | Characteristics | Examples |
|------|------|------|
| Development project | Has a code build, dependency management, a tech stack | Web app, CLI tool, library |
| Content project | Mostly text/config, no build pipeline | Toolsets, doc sites, prompt repos |

The following steps differ by type; content projects skip steps marked `[Dev]`.

### A2. Create AGENTS.md + CLAUDE.md

At the project root, define the AI collaboration rules. Full generation guide and template → [reference/agents-md.md](reference/agents-md.md)

Flow:

1. **Pre-check**: check whether the external skills the rime workflow depends on are installed; if not, warn the user (non-blocking — see the pre-check section in [reference/agents-md.md](reference/agents-md.md))
2. **Tracked-in-git decision**: ask the user (tracked in git = shared with the team; added to `.gitignore` = not made public)
3. **Optional interaction**: present language settings (AI communication / code comments / UI copy) + verification method all at once; the user answers each one or skips
4. **Automatic tech-stack skill mapping** `[Dev]`: scan package.json + config files and auto-write the matching skill rules
5. **Generate AGENTS.md**: fixed content + dynamic content from the user's choices/detection results
6. **CLAUDE.md bridge**: Claude Code only reads `CLAUDE.md`, never `AGENTS.md` — a bridge is mandatory. No `CLAUDE.md` → create one containing just the line `@AGENTS.md`; already exists → append that line at the top after dedup (leave the original content untouched). Details in [reference/agents-md.md](reference/agents-md.md)

Once created, it isn't modified day-to-day unless the collaboration rules themselves need to change.

### A3. Configure .gitignore

Make sure it includes:
- `.worktrees/`
- `.rime/` (**mandatory** — not overridable by the user)
- `docs/` (the doc layer is untracked by default; the user can override this)

Keeping `.rime/` untracked is a **hard requirement**: it holds project-global mutable state, and tracking it causes `.rime/*.json` merge conflicts, worktrees picking up stale snapshots, and **silent state drift across branch switches** (marked `done` on a feature branch, then back to `doing` after switching back to main). Authoritative explanation in rime-flow's [data-contract.md](../rime-flow/data-contract.md), "Storage Location & Resolution Order."

The tracked-in-git policy for `docs/` is **independent** of `.rime/` — each is decided on its own: `.rime/` is mutable state, `docs/` (spec / PRD) is documentation output.

`CLAUDE.md` follows `AGENTS.md`'s tracked-in-git decision (both tracked, or both gitignored): if AGENTS.md is gitignored while CLAUDE.md is tracked, `@AGENTS.md` becomes a dead link for collaborators after cloning.

### A4. Create the .rime/ Data Layer

Create the structured data directory at the project root:

```
.rime/
├── tasks.json      ← task status source of truth
├── phase.json      ← current phase info
├── cautions.json   ← pitfall log (append-only)
└── anchors/        ← session records (auto-generated, gitignored)
```

Initial file templates → [reference/template-tasks-json.md](reference/template-tasks-json.md)

### A5. Create the docs/ Documentation Skeleton

Choose the needed documents based on project size and type.

**Common documents:**

| Document | Content | Applies to |
|------|------|------|
| prd | Product positioning, goals, feature plan (narrative) | All projects |
| archive | Narrative archive of completed phases | All projects |

**Additional for dev projects:**

| Document | Content | Priority |
|------|------|--------|
| techstack | Tech stack choices, project structure, phase plan | Recommended |
| interaction | Interaction design, page states, operation flows | Medium size and up |
| schema | Data structure definitions | Medium size and up |
| DESIGN.md | Design system (tokens + rationale, [google-labs/design.md](https://github.com/google-labs-code/design.md) format) | Projects with a UI |

File naming: `{project}-{type}.md`. Exception: `DESIGN.md` uses the standard [google-labs/design.md](https://github.com/google-labs-code/design.md) filename, with no project prefix. Templates → [reference/doc-templates.md](reference/doc-templates.md) (DESIGN.md's template and generation flow live in the `rime-design` skill)

> DESIGN.md is a design contract shared by the team. If `docs/` is gitignored by default (see A3), when collaborating with a team it's recommended to `git add -f docs/DESIGN.md` separately or move it out of the ignore scope — otherwise collaborators won't get the design system after cloning.

**PRD first**: write the PRD before starting work.

After creating the documents, write a "Document Map" into the bottom of AGENTS.md (list only the documents actually created). Details in [reference/agents-md.md](reference/agents-md.md)

### A6. Configure the Dev Toolchain `[Dev]`

Applies to frontend / Node.js projects. Skip for non-JS/TS projects like Go or Swift.

Detailed setup flow → [reference/dev-tooling.md](reference/dev-tooling.md)

**Code quality tools:**

| Tool | Purpose | Priority |
|------|------|--------|
| Prettier | Code formatting | Required |
| ESLint | Code quality checks | Required |
| Husky | Git hooks management | Required |
| lint-staged | Staged-file checks | Required |
| EditorConfig | Unified editor config | Recommended |
| commitlint | Commit message conventions | Optional |

Config file templates live in the `assets/` directory.

**Component library selection (when there's a UI need):**

Ask the user whether a component library is needed; common options:

| Library | Characteristics | Best fit |
|------|------|----------|
| shadcn/ui | Copy-the-source, fully customizable, Tailwind | Projects needing heavy customization |
| Radix UI | Unstyled primitives, accessibility-first | Writing your own styles, prioritizing a11y |
| Base UI | From the MUI team, unstyled, hooks-driven | Needing low-level control |
| coss ui | Copy-the-source, Tailwind, lightweight | shadcn alternative |

Skip if no component library is needed. Once chosen, record it in `techstack.md`.

### A7. Create README.md

User-facing, tracked in git.

---

## Scenario C: Migrating a Legacy Project

A one-time migration for projects already using the old rime-flow (markdown-table-based status management).

### Determine Whether Migration Is Needed

Check for the following legacy signs:
- `backlog.md` contains a status table (`❌` / `✅`)
- `prd.md` contains a feature-requirement status table
- No `.rime/` directory

### Migration Flow

1. **Backup**: copy `prd.md`, `backlog.md`, `archive.md`, `cautions.md` to `docs/.migration-backup/`
2. **Extract items**: scan every document for `#xxx` entries → generate `tasks.json`
   - In archive → `status: done`
   - ✅ in prd → `status: done`
   - ❌ in prd → `status: doing`
   - In backlog → `status: todo`
3. **Create phase.json**: infer phase info from the P0/P1 headings in the prd
4. **Convert cautions**: if cautions.md exists → convert it to `cautions.json`
5. **Rewrite prd.md**: keep the narrative sections, replace tables with a reference list
6. **Rewrite archive.md**: replace tables with phase narratives
7. **Delete obsolete files**: `backlog.md`, `cautions.md`
8. **Create the `.rime/` structure**: the directory + `anchors/`
9. **Update .gitignore**: add `.rime/` (mandatory, see A3) and `docs/` (untracked by default). If the legacy project already tracks `.rime/` in git, run `git rm -r --cached .rime` to untrack it (the files stay in place, no need to move them)

Executed by the AI, confirming at each step. After migration is complete, confirm everything is correct before deleting `docs/.migration-backup/`.

---

## After Initialization

Once project initialization is complete, day-to-day management (task status updates, phase archiving, doc maintenance) is automatically taken over by the `rime-flow` skill.
