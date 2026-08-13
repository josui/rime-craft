# Verdict Contract

The single authoritative source for the rime-review verdict contract: severity calibration, per-finding confidence, report format, full-report discipline, and review discipline rules. SKILL.md points here; it does not restate these rules.

Aligned with the rime-sdd task reviewer's severity definitions so that findings from both review mechanisms are semantically comparable.

---

## Severity Calibration

### Critical (Must Fix)

Safety issues, broken core invariants, data loss or corruption, injection on auto-execution paths. Must be fixed before merge.

Examples: SQL or shell injection on a hook/cron/startup item, unbounded write without rollback, race condition that corrupts state, secrets leaked to output or logs.

### Important (Should Fix)

Code that cannot be trusted until fixed: incorrect or fragile behavior, silent failures, missed error handling, maintainability damage that would block a merge. Verbatim duplication of a logic block, swallowed errors, tests that assert nothing.

Examples: off-by-one on a boundary condition, catch block that silently swallows all exceptions, shared mutable state accessed without synchronization.

### Minor (Nice to Have)

Polish suggestions, naming improvements, documentation nits. Do not block merge.

Examples: variable name could be clearer, a TODO comment that could be more specific, a minor documentation gap.

### spec-mandated (Escalated to Human Judgment)

When the review target has its own spec, and the spec itself mandates what the rubric would otherwise call a defect (a test that asserts nothing, verbatim duplication of a logic block, an explicit requirement that contradicts a dimension check), report it as **Important** with the `spec-mandated` tag. The spec's authorship does not grade its own work — the human decides which governs.

Do not dismiss the finding because the spec mandates it. Do not dispatch a fix that contradicts the spec without asking the human. Present the finding alongside the spec text and ask which governs.

---

## Per-Finding Confidence

Every finding carries a confidence assessment. **Only report high-confidence findings.** A medium-confidence doubt is reported as a "cannot verify" item with what the controller should check — never as a finding.

Low-confidence hunches are discarded silently. The cost of a false positive (wasted fix round, eroded trust) exceeds the cost of a missed finding that a later review will catch.

---

## file:line Requirement

Every finding must cite `file:line`. A finding without a precise location is a vague assertion, not an actionable review item. If a hunk is cut off mid-function and the full context cannot be seen, say so explicitly rather than guessing.

Each finding includes:

- `file:line` — the precise location
- What is wrong
- Why it matters
- How to fix (when not obvious)

---

## Full-Report Discipline

A review round is not complete until the full report is delivered. This applies to every round — first review and every re-review.

- **idle ≠ done**: a reviewer that goes idle, sends an acknowledgement, or narrates progress without delivering the two verdicts has not completed the review.
- **Re-prompt**: if the final message lacks the verdict report, re-prompt the same reviewer for the verdict.
- **Replace a dead reviewer**: if one re-prompt still yields no report, treat the reviewer as dead and dispatch a fresh named reviewer with the original inputs.
- **No partial credit**: a review that ends without the complete report is a failed round — the controller cannot proceed and must re-dispatch.

---

## Review Discipline

### Accompanying Descriptions Are Unverified Claims

The implementer's report, commit messages, design rationale, and any accompanying narrative are **unverified claims** about the code. They may be incomplete, inaccurate, or optimistic.

- Verify claims against the diff and the actual code.
- Design rationales ("left it per YAGNI," "kept it simple deliberately," "this is intentional") are the implementer grading their own work.
- A stated rationale **never** downgrades a finding's severity. Judge the code on its merits.

### Named-Risk Call-Site Checks

When a change touches any of the following, name the specific risk and proactively check the call sites:

- **Public contracts** — function signatures, API shapes, exported types
- **Shared mutable state** — global variables, caches, singletons
- **Concurrency** — lock ordering, synchronization primitives, async boundaries

A change to any of these surfaces has a blast radius beyond the diff. Checking call sites is the right method, not scope creep. Name both the risk and what you checked in the report.

---

## Security Finding Calibration

Security findings follow an additional calibration rule:

- **Baseline**: all security findings start at **Important**, regardless of the specific check (injection, auth, path traversal, leakage, supply chain).
- **Auto-execution escalation**: injection findings on auto-execution paths — hooks, cron jobs, startup items, session-init scripts — are **Critical** directly. These paths run without human review, so an injection there has no second gate.

---

## Report Structure

A complete review report contains:

1. **Verdict** — pass or findings (with a summary count by severity).
2. **Strengths** — what was done well, with specific evidence. Accurate praise builds trust in the rest of the feedback.
3. **Findings** — grouped by severity (Critical → Important → Minor), each with file:line, what is wrong, why it matters, and how to fix.
4. **Cannot verify** — items that could not be confirmed from the available diff or files, with what the controller should check.
5. **Assessment** — one- or two-sentence technical summary and a clear Approved / Needs fixes verdict.

A report that omits any section is incomplete and triggers the full-report discipline.
