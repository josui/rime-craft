---
name: rime-react
description: Use when writing, reviewing, or refactoring React components, hooks, or data-fetching patterns. Covers effect discipline, component composition, performance optimization, and data flow. Applies to any React project (Vite, Next.js, Remix, etc.).
---

# React Component Rules

Framework-agnostic React component development rules. Covers 4 groups, 21 rules total: Effect Discipline, Component Structure, Performance, and Data & Boundaries.

## Rules Index

### Effect Discipline — "useEffect is not a lifecycle hook"

| Rule | Summary | Priority |
|------|---------|----------|
| [effect-derive-state](rules/effect-derive-state.md) | Compute derived state inline, never sync via Effect | critical |
| [effect-use-event-handler](rules/effect-use-event-handler.md) | Side effects from user actions belong in event handlers | critical |
| [effect-data-fetching](rules/effect-data-fetching.md) | Use a data-fetching library, not raw Effect + fetch | critical |
| [effect-mount-only](rules/effect-mount-only.md) | Effects are only for syncing with external systems on mount | critical |
| [effect-reset-with-key](rules/effect-reset-with-key.md) | Reset component state with key prop, not Effect | critical |

### Component Structure — "Composition over configuration"

| Rule | Summary | Priority |
|------|---------|----------|
| [component-no-inline-def](rules/component-no-inline-def.md) | Never define components inside other components | critical |
| [component-composition](rules/component-composition.md) | Prefer composition (children) over boolean prop sprawl | recommended |
| [component-compound](rules/component-compound.md) | Use compound component pattern for complex UI | recommended |
| [component-state-lifting](rules/component-state-lifting.md) | Lift state to nearest common ancestor or provider | recommended |
| [component-conditional-render](rules/component-conditional-render.md) | Guard && renders against numeric falsy values (0, NaN) | critical |

### Performance — "Measure first, optimize second"

| Rule | Summary | Priority |
|------|---------|----------|
| [perf-memo-strategy](rules/perf-memo-strategy.md) | With React Compiler: automatic. Without: manual memo for expensive computations only | recommended |
| [perf-stable-references](rules/perf-stable-references.md) | Functional setState, hoisted defaults, useRef for transient values, lazy init | recommended |
| [perf-bundle-imports](rules/perf-bundle-imports.md) | Avoid barrel imports; defer third-party scripts post-hydration | critical |
| [perf-lazy-loading](rules/perf-lazy-loading.md) | Lazy-load heavy components + preload on hover/focus | recommended |
| [perf-async-parallel](rules/perf-async-parallel.md) | Promise.all for independent ops; defer await until consumption | recommended |
| [perf-transitions](rules/perf-transitions.md) | Mark non-urgent updates with startTransition | recommended |
| [perf-activity](rules/perf-activity.md) | Preserve state/DOM of toggled components with Activity (experimental) | recommended |

### Data & Boundaries — "Data flows down, events flow up"

| Rule | Summary | Priority |
|------|---------|----------|
| [data-rsc-boundary](rules/data-rsc-boundary.md) | Minimize serialized data across Server/Client boundary | recommended |
| [data-suspense-streaming](rules/data-suspense-streaming.md) | Wrap async regions in Suspense for streaming, avoid waterfalls | recommended |
| [data-dedup](rules/data-dedup.md) | Client: SWR/TanStack Query dedup. Server: React.cache() | recommended |
| [data-render-as-you-fetch](rules/data-render-as-you-fetch.md) | Component tree mirrors data dependencies; parent fetches, child consumes | recommended |

## Stack Hints

| Scenario | Vite SPA | Next.js App Router | Remix |
|----------|----------|-------------------|-------|
| Lazy loading | `React.lazy` + `Suspense` | `next/dynamic` | `React.lazy` (route-level handled by framework) |
| RSC boundary | N/A | `"use client"` / `"use server"` | N/A (Remix v3+ exploring) |
| Data fetching | SWR / TanStack Query | Server Components + `fetch` | `loader` / `action` |
| Streaming | Manual SSR streaming setup | Built-in | Built-in |

## Framework API Guidance

Framework-specific APIs (routing, data loading, middleware, etc.) are out of scope. Use context7 or official docs to look up the latest framework APIs.

## Recommended Tools

- **react-doctor** — React code health check (if installed). Run it and cross-reference findings with these rules.
