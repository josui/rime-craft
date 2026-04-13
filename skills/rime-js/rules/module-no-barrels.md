# module-no-barrels

Avoid barrel files (`index.ts` with re-exports) — import directly from the source module.

## Why

Barrel files force bundlers and test runners to load and parse every re-exported module even when only one export is used. This inflates build times, breaks tree-shaking, and pollutes IDE autocomplete with unrelated symbols. Atlassian reported 75% faster TypeScript build times after removing barrel files from their monorepo.

## Bad

```typescript
// components/index.ts — barrel re-exports everything
export * from "./Button"
export * from "./Dialog"
export * from "./Tooltip"
export * from "./DataTable"

// consumer — importing Button also forces Dialog, Tooltip, DataTable to be resolved
import { Button } from "./components"
```

## Good

```typescript
// consumer — only Button module is resolved and parsed
import { Button } from "./components/Button"
import { Dialog } from "./components/Dialog"
```

## Notes

Barrels are especially harmful in monorepos and test environments where module resolution compounds across packages. If a library ships a barrel for public API convenience, that is the library author's tradeoff — application code within a repo should not add its own. Configure `no-restricted-imports` or `import/no-internal-modules` to enforce direct imports.
