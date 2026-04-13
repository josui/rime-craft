---
name: rime-js
description: Use when writing, reviewing, or refactoring JavaScript/TypeScript code. Covers type safety patterns, module architecture, error handling, async control, and micro-performance optimization. Framework-agnostic, applies to any JS/TS project.
---

# JS/TS Rules

Framework-agnostic JavaScript/TypeScript rules. Covers 4 groups, 21 rules total: Type Safety, Module Architecture, Error & Async, and Performance.

## Rules Index

### Type Safety — "Make illegal states unrepresentable"

| Rule | Summary | Priority |
|------|---------|----------|
| [type-discriminated-unions](rules/type-discriminated-unions.md) | Model state variants with shared discriminant field, not optional field sprawl | critical |
| [type-exhaustive-check](rules/type-exhaustive-check.md) | Use `never` in switch default to catch unhandled variants at compile time | critical |
| [type-satisfies](rules/type-satisfies.md) | Use `satisfies` to validate types while preserving inference; treat `as` as last resort | critical |
| [type-branded](rules/type-branded.md) | Distinguish structurally identical values with branded types (UserId vs ProductId) | recommended |

### Module Architecture — "Every import has a cost"

| Rule | Summary | Priority |
|------|---------|----------|
| [module-no-barrels](rules/module-no-barrels.md) | Avoid barrel files (index.ts re-exports); use direct path imports | critical |
| [module-side-effects](rules/module-side-effects.md) | No side effects at module top level; mark `sideEffects` in package.json for tree-shaking | recommended |

### Error & Async — "Failures are values, not exceptions"

| Rule | Summary | Priority |
|------|---------|----------|
| [async-parallel](rules/async-parallel.md) | Run independent async ops with `Promise.all`/`allSettled`, never sequential await | critical |
| [error-result-pattern](rules/error-result-pattern.md) | Return `{ ok, data } \| { ok, error }` discriminated union instead of throwing | recommended |

### Performance — "Measure first, optimize second"

| Rule | Summary | Priority |
|------|---------|----------|
| [perf-set-map](rules/perf-set-map.md) | Use Set/Map for O(1) lookups instead of Array .includes()/.find() | critical |
| [perf-index-maps](rules/perf-index-maps.md) | Build index Map for repeated lookups by key | critical |
| [perf-immutable-sort](rules/perf-immutable-sort.md) | Use .toSorted()/.toReversed()/.toSpliced() — never mutate arrays in place | critical |
| [perf-batch-dom](rules/perf-batch-dom.md) | Batch DOM style writes, then reads — avoid layout thrashing | recommended |
| [perf-cache-results](rules/perf-cache-results.md) | Cache repeated function calls with module-level Map | recommended |
| [perf-cache-property](rules/perf-cache-property.md) | Cache deep property access in hot loops | recommended |
| [perf-cache-storage](rules/perf-cache-storage.md) | Cache localStorage/sessionStorage reads in memory | recommended |
| [perf-combine-iterations](rules/perf-combine-iterations.md) | Merge chained .filter().map() into single loop | recommended |
| [perf-early-exit](rules/perf-early-exit.md) | Return immediately when result is determined — skip remaining work | recommended |
| [perf-flatmap](rules/perf-flatmap.md) | Use .flatMap() for combined map + filter in one pass | recommended |
| [perf-hoist-regexp](rules/perf-hoist-regexp.md) | Hoist RegExp to module scope — never create in loops or renders | recommended |
| [perf-length-check](rules/perf-length-check.md) | Check array length before expensive comparisons | recommended |
| [perf-min-max-loop](rules/perf-min-max-loop.md) | Find min/max with single loop, not sort | recommended |

## Relationship with rime-react

This skill covers **framework-agnostic** JS/TS rules. React-specific patterns (Effects, component composition, RSC boundaries, etc.) live in `rime-react`. Rules like `async-parallel` and `module-no-barrels` are authoritative here — `rime-react` references them for React-specific context.

## Recommended Tools

- **typescript-eslint** — Static analysis for TypeScript-specific rules (`switch-exhaustiveness-check`, `no-unnecessary-type-assertion`, etc.)
