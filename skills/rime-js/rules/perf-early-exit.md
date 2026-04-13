# perf-early-exit

Return early when result is determined.

## Why

Continuing to process data after the answer is known wastes CPU cycles. In validation loops, search functions, and permission checks, an early `return` or `break` can skip thousands of unnecessary iterations — especially when the exit condition is hit near the start.

## Bad

```typescript
// Keeps iterating after the first error is found
function validateUsers(users: User[]): ValidationResult {
  let hasError = false
  let errorMessage = ''

  for (const user of users) {
    if (!user.email) {
      hasError = true
      errorMessage = 'Email required'
    }
    if (!user.name) {
      hasError = true
      errorMessage = 'Name required'
    }
  }

  return hasError ? { valid: false, error: errorMessage } : { valid: true }
}
```

## Good

```typescript
// Returns immediately on first error
function validateUsers(users: User[]): ValidationResult {
  for (const user of users) {
    if (!user.email) return { valid: false, error: 'Email required' }
    if (!user.name) return { valid: false, error: 'Name required' }
  }

  return { valid: true }
}
```

## Notes

Apply the same pattern to `.find()`, `.some()`, and `.every()` — they already short-circuit internally. For nested loops, consider extracting the inner loop into a function so `return` exits cleanly without needing labeled `break`.
