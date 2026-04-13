# type-satisfies

Use `satisfies` to validate type conformance while preserving literal type inference.

## Why

Type annotations (`const x: Type`) widen literals to their base type, losing autocomplete and narrowing. The `as` operator bypasses checks entirely — it tells TypeScript to trust you, silencing real errors. `satisfies` validates the shape at the assignment site while keeping the narrowest possible type downstream.

## Bad

```typescript
// `as` silently bypasses checks — typo in property name compiles fine
const config = {
  endpoint: "https://api.example.com",
  retries: 3,
  timeotu: 5000, // typo — no error with `as`
} as Config

// Type annotation widens — loses literal types
const routes: Record<string, string> = {
  home: "/",
  about: "/about",
}
// routes.home is string, not "/"
```

## Good

```typescript
// `satisfies` catches structural errors while preserving literal types
const config = {
  endpoint: "https://api.example.com",
  retries: 3,
  timeout: 5000,
} satisfies Config
// config.endpoint is "https://api.example.com", not string

// as const satisfies — immutable + validated + fully literal
const routes = {
  home: "/",
  about: "/about",
} as const satisfies Record<string, string>
// routes.home is "/", not string
```

## Notes

`as` remains appropriate for DOM element casts (`e.target as HTMLInputElement`), test fixtures with partial data, and interop with untyped libraries. Everywhere else, prefer `satisfies`. The `as const satisfies T` combo is ideal for configuration objects, route maps, and enum-like constants.
