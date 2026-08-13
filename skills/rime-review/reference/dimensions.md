# Review Dimension Framework

The single authoritative source for the rime-review dimension framework. SKILL.md points here; it does not restate these lists.

The framework is generic — designed to apply to any project. Applicability of each check (especially security items) is judged against the target project's threat model at review time, never pre-excluded by assumption about the project's form.

---

## Code Dimensions (C0–C6)

### C0 — Necessity (pre-gate)

The threshold question, asked before any other dimension:

- Does this solve a real problem, or an imagined / speculative one?
- Does it actually solve the problem (vs. appearing to)?
- Is there a simpler alternative (fewer files, fewer abstractions, reusing an existing dependency)?
- Should this code exist / be merged at all? Can it be deleted?

A change that fails C0 produces no further dimension findings — the verdict is that the change should not proceed.

### C1 — Correctness & Robustness

- **Logic errors**: wrong condition branches, off-by-one, incorrect default values.
- **Boundary conditions**: empty input, huge input, Unicode and special characters, paths containing spaces.
- **Failure modes & degradation**: when a dependency is missing, a file does not exist, or state is abnormal — is the degradation explicit, or does the code silently pass through or corrupt unrelated functionality?
- **Silent failure**: swallowed errors, half-mutated state, catch specificity (too broad vs. too narrow), should this error be swallowed or bubble up, is the failure diagnosable?
- **State consistency**: concurrent read-modify-write races, atomicity, write validation.
- **Environment assumptions**: platform tool differences, shell dialect assumptions, assuming a command exists on all targets.

### C2 — Security

Each item is weighted against the target project's threat model at review time. No item is pre-excluded.

- **Injection**: user-controllable text entering shell, SQL, HTML, or URL construction.
- **Authentication & access control**: missing or bypassable auth checks, privilege escalation.
- **Path traversal**: untrusted input in file paths without sanitization.
- **Sensitive information leakage**: secrets or credentials must not appear in output, logs, error messages, or build artifacts.
- **Dependency & supply-chain risk**: new dependency's maintenance status, trust surface, and permission scope.

**Calibration**: security findings start at **Important**; injection on auto-execution paths (hooks, cron, startup items) is **Critical**. See verdict-contract.md for the full severity calibration.

### C3 — Architecture

- **Separation of concerns / single responsibility**: each unit has one clear job.
- **Single source of truth**: authoritative definition in one place, the rest are pointers, no parallel mechanisms.
- **Consistency with existing abstractions**: reuses existing dependencies and utilities, does not reinvent the wheel.
- **Appropriate abstraction level**: no speculative abstractions, no pre-wired configuration for imagined futures.
- **Type design** (in typed languages): encapsulation, invariant expression and enforcement through the type system.

### C4 — Performance & Resources

- **Hot path**: identified by the target's form (e.g. hooks that block a session, request-path handlers, batch-processing entry points).
- **General resource issues**: deadlocks, infinite loops, resource leaks, slow queries.
- **Obvious algorithmic problems**: repeated file reads inside a loop, avoidable O(n²) on non-trivial data.

**Anti-performance-review discipline**: non-hot-path changes do not produce performance findings.

### C5 — Maintainability

Default: only flag obvious issues. Deep Standards-level checks (naming conventions, style guide compliance, Fowler smell taxonomy) belong to the external code-review skill, not rime-review.

- **Naming**: consistent with repository conventions.
- **Nesting / function complexity**: excessive depth or cyclomatic complexity.
- **Comment quality**: accuracy (matches the code), staleness (expired TODOs, invalidated assumptions), explains *why* not *what*.
- **Documentation sync**: README, contract files, changelog updated alongside the change.

### C6 — Testing & Verifiability

Conditional dimension: enabled only when the target repository has test infrastructure. Disabled silently when it does not.

- Tests cover the changed behavior and verify real behavior, not mocks.
- Tests are robust to reasonable refactoring.
- Tests do not couple to implementation details.

---

## Skill Dimensions (S1–S6)

### S1 — Trigger Surface

- **Description coverage**: does the description reliably trigger when it should, and reliably not trigger when it should not? Are boundary overlaps or conflicts with other skills addressed?
- **Wording assertiveness**: Claude has an undertriggering tendency — the description should exhaustively enumerate trigger scenarios in multiple natural phrasings.
- **Invocation mode choice**: model-invoked vs. user-invoked — does the choice correctly trade context cost against cognitive overhead?
- **Baseline value**: does the skill deliver a demonstrable improvement over not using it?

### S2 — Contract Structure

- **Single source of truth**: authoritative definition in one place, no drift, no parallel restatements.
- **Co-location of same-concept material**: definitions, rules, and caveats concentrated in one place — both scattering and duplication are checked.
- **Environment as source**: the skill does not restate what config, directory structure, or `--help` already makes clear.
- **Repeated work bundled**: recurring operations extracted into scripts, not inlined across the skill body.

### S3 — Enforceability

- **Visibility at need time**: are rules visible to the AI when it needs them (via hook injection) or only when it remembers to load the skill (relying on self-discipline)?
- **Mechanical enforcement**: are rules enforced by a validator or hook, or only by self-discipline?

### S4 — Bloat & Staleness

- **Speculative instructions**: explanations guarding against imagined problems that have not been observed.
- **Excessive branching**: over-conditional logic for edge cases that rarely occur.
- **Over-fitted patches**: special-case rules added for a single instance.
- **Staleness accumulation**: adding feels safe, removing feels risky — does the skill carry content that is no longer serving its purpose?

### S5 — Language Boundary

- **Instruction layer vs. artifact layer**: does the skill correctly separate instruction-layer text (the skill itself) from artifact-layer output (the files or code it produces)? The boundary follows the target project's existing language rules.

### S6 — Instruction Quality

- **Reasons over hard rules**: does the skill explain *why*, or does it stack ALWAYS/NEVER edicts? Heavy capitalization is a yellow flag.
- **Negations paired with positive goals**: a bare prohibition reinforces the forbidden behavior — does the skill name what to do instead?
- **Established vocabulary**: does the skill use existing, compact concept words, or coin new terms?
- **No-op instruction detection**: does the skill pay cognitive load for instructions the model already obeys by default?
- **Completion criteria**: does each step have a discernible "done" test?
