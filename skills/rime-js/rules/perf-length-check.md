# perf-length-check

Check array length before expensive comparison.

## Why

When comparing two arrays with costly operations (sorting, serialization, deep equality), a simple `.length` check is O(1) and immediately proves inequality when sizes differ. This avoids unnecessary O(n log n) sorts or O(n) traversals in the common case where arrays have different lengths.

## Bad

```typescript
// Always sorts both arrays even when lengths differ
function hasChanges(current: string[], original: string[]): boolean {
  return current.sort().join() !== original.sort().join()
}
```

## Good

```typescript
// O(1) length check shortcuts the expensive path
function hasChanges(current: string[], original: string[]): boolean {
  if (current.length !== original.length) return true

  const a = current.toSorted()
  const b = original.toSorted()
  return a.some((val, i) => val !== b[i])
}
```

## Notes

This pattern applies broadly: before deep-equal checks, JSON.stringify comparisons, or set-difference calculations. Also note the Bad example mutates via `.sort()` — always prefer `.toSorted()` to avoid side effects on the source arrays.
