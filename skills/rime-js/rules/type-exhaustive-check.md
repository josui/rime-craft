# type-exhaustive-check

Use `never` in switch default to catch unhandled discriminated union variants at compile time.

## Why

When a new variant is added to a union, a plain `default` branch silently swallows it — the bug only surfaces at runtime. Assigning the value to `never` in the default makes the compiler error immediately, turning a runtime surprise into a build-time fix.

## Bad

```typescript
// Default silently ignores new variants — adding "cancelled" compiles fine but breaks logic
function statusLabel(status: RequestStatus): string {
  switch (status) {
    case "idle":
      return "Ready"
    case "loading":
      return "Loading..."
    default:
      return "Unknown" // new variants fall through here unnoticed
  }
}
```

## Good

```typescript
// Compiler errors when a variant is unhandled — you cannot forget to add a case
function statusLabel(status: RequestStatus): string {
  switch (status) {
    case "idle":
      return "Ready"
    case "loading":
      return "Loading..."
    case "success":
      return "Done"
    case "error":
      return "Failed"
    default: {
      const _exhaustive: never = status
      return _exhaustive
    }
  }
}
```

## Notes

Extract a reusable helper if preferred: `function assertNever(value: never): never { throw new Error(\`Unhandled: \${value}\`) }`. Enable the `@typescript-eslint/switch-exhaustiveness-check` lint rule to catch missing cases without the helper. Pairs with `type-discriminated-unions`.
