# module-side-effects

No side effects at module top level — defer initialization to explicit function calls.

## Why

Top-level side effects run the moment a module is imported, even if the consumer only needs a type or a utility from it. This breaks tree-shaking, slows application startup, causes issues in test environments, and creates hidden dependencies on import order.

## Bad

```typescript
// api.ts — client instantiated at import time, runs in every test file that touches this module
const client = new APIClient({ baseURL: process.env.API_URL! })

export function fetchUsers() {
  return client.get("/users")
}
```

## Good

```typescript
// api.ts — client created lazily, only when actually used
let client: APIClient | null = null

function getClient(): APIClient {
  if (!client) {
    client = new APIClient({ baseURL: process.env.API_URL! })
  }
  return client
}

export function fetchUsers() {
  return getClient().get("/users")
}
```

## Notes

Mark side-effect-free packages with `"sideEffects": false` in `package.json` so bundlers can tree-shake unused modules. For individual expressions, use `/*#__PURE__*/` to tell bundlers the call can be safely dropped if its return value is unused. CSS imports and polyfills are legitimate side effects — list them explicitly in the `"sideEffects"` array (e.g., `["*.css"]`).
