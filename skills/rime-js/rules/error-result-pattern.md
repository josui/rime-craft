# error-result-pattern

Return a discriminated union result type instead of throwing exceptions for expected failure modes.

## Why

Thrown exceptions are invisible in function signatures — callers have no compile-time indication that a function can fail, and nothing forces them to handle the error. A result union makes success and failure explicit in the type system, so the compiler ensures every call site handles both cases.

## Bad

```typescript
// Caller has no idea this throws — easy to forget try/catch
function parseConfig(raw: string): Config {
  const parsed = JSON.parse(raw)
  if (!isValidConfig(parsed)) {
    throw new Error("Invalid config structure")
  }
  return parsed
}

// Silent crash if parseConfig throws
const config = parseConfig(input)
```

## Good

```typescript
type Result<T, E = string> =
  | { ok: true; data: T }
  | { ok: false; error: E }

function parseConfig(raw: string): Result<Config> {
  try {
    const parsed = JSON.parse(raw)
    if (!isValidConfig(parsed)) {
      return { ok: false, error: "Invalid config structure" }
    }
    return { ok: true, data: parsed }
  } catch {
    return { ok: false, error: "Malformed JSON" }
  }
}

const result = parseConfig(input)
if (!result.ok) {
  showError(result.error) // compiler forces you to handle this branch
  return
}
useConfig(result.data) // data is narrowed, guaranteed present
```

## Notes

Reserve `try/catch` and thrown exceptions for truly exceptional, unrecoverable situations — network failures, out-of-memory, programmer errors (assertion violations). For expected failures like validation, parsing, and business rule violations, the result pattern makes the API honest. Pairs with `type-discriminated-unions`.
