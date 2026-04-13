# perf-immutable-sort

Use `.toSorted()` instead of `.sort()` for immutability.

## Why

`.sort()` mutates the original array in place. This causes subtle bugs when the source array is shared state, a function parameter, or referenced elsewhere. `.toSorted()` returns a new sorted array, leaving the original untouched — aligning with immutable data patterns.

## Bad

```typescript
// Mutates the input array — caller's data is silently changed
function getTopScores(scores: number[]): number[] {
  return scores.sort((a, b) => b - a).slice(0, 10)
}
```

## Good

```typescript
// Returns a new array — input is unchanged
function getTopScores(scores: number[]): number[] {
  return scores.toSorted((a, b) => b - a).slice(0, 10)
}
```

## Notes

The full family of non-mutating array methods: `.toSorted()`, `.toReversed()`, `.toSpliced()`, and `.with()`. All return new arrays. Available in all modern browsers (Chrome 110+, Safari 16+, Firefox 115+) and Node.js 20+. For older environments, use `[...arr].sort()` as a fallback.
