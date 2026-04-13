# type-discriminated-unions

Use a shared literal discriminant field (`type`, `kind`, `status`) to model state variants — never optional fields.

## Why

Optional fields allow impossible combinations to compile. A `{ loading?: boolean; data?: T; error?: E }` type permits `{ loading: true, data: someValue, error: someError }` — a state that should never exist. Discriminated unions make each variant explicit and let TypeScript narrow automatically in `switch` and `if` blocks.

## Bad

```typescript
// Optional fields allow impossible states — loading with data AND error
interface RequestState<T> {
  loading?: boolean
  data?: T
  error?: Error
}

function handle(state: RequestState<User>) {
  if (state.loading) {
    // state.data could still be set — is it stale? current?
  }
}
```

## Good

```typescript
// Each variant is explicit — impossible states are unrepresentable
type RequestState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error }

function handle(state: RequestState<User>) {
  switch (state.status) {
    case "loading":
      return showSpinner()
    case "success":
      return showUser(state.data)   // data is narrowed, guaranteed present
    case "error":
      return showError(state.error) // error is narrowed, guaranteed present
  }
}
```

## Notes

Pick one discriminant name and use it consistently across the codebase (`status` for async states, `type` for actions/events, `kind` for AST nodes). Pairs with `type-exhaustive-check` to catch unhandled variants at compile time.
