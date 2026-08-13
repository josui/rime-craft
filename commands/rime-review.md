---
description: Review code or a skill for quality — diffs, branches, whole files, or skill files. Spec-agnostic quality review (necessity, architecture, robustness, security, skill dimensions). NOT for pure naming/style questions (use code-review) or spec compliance (use rime-sdd task reviewer).
---

Review code or a skill for quality.

## Review Targets

**Code — fixed-point diff** (changes between two commits):
```
/rime-review BASE HEAD
```

**Code — whole branch** (changes since branching off main):
```
/rime-review
```
When no arguments are given, review the current branch against `main` (or `master` if `main` does not exist).

**Code — whole files or modules**:
```
/rime-review path/to/file.ts path/to/dir/
```

**Skill**:
```
/rime-review path/to/skill/SKILL.md
```
Any SKILL.md file, prompt template, or skill directory triggers skill mode with the S1–S6 dimension framework.

## Behavior

The rime-review skill is loaded automatically. It determines:

- **Mode** — code or skill, based on what the target path resolves to.
- **Execution shape** — small reviews (≤ ~3 files, low risk) run inline in the main thread; deep reviews dispatch a named reviewer subagent.
- **Dimensions** — code reviews apply C0–C6; skill reviews apply S1–S6.
- **Verdict** — findings carry severity (Critical / Important / Minor / spec-mandated), confidence, and file:line citations.

For natural-language review requests ("review this diff", "audit this module", "check this skill"), the skill triggers automatically through its description — this command is the explicit entry point when you want to be direct.

## Boundary

- Pure naming, code style, or code-smell taxonomy questions → use the external **code-review** skill (Standards axis).
- Spec compliance (missing / extra / misunderstood against an originating spec) → use **rime-sdd** task reviewer.
- rime-review is **spec-agnostic**: it judges quality on the code's merits, never against an originating spec.
