# perf-hoist-regexp

Hoist RegExp creation to module scope.

## Why

`new RegExp()` compiles the pattern every time it is called. In functions that run frequently — event handlers, loops, repeated utility calls — this compilation cost adds up. Moving static patterns to module scope ensures they are compiled once.

## Bad

```typescript
// RegExp compiled on every call
function isValidEmail(input: string): boolean {
  const pattern = new RegExp('^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$')
  return pattern.test(input)
}
```

## Good

```typescript
// Compiled once at module load
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function isValidEmail(input: string): boolean {
  return EMAIL_RE.test(input)
}
```

## Notes

For dynamic patterns (user-supplied search terms), cache the compiled RegExp in a Map keyed by the pattern string. Beware that global (`/g`) regexps have mutable `lastIndex` state — calling `.test()` twice on the same string gives different results. Use a non-global regexp or reset `lastIndex = 0` before each use.
