# perf-min-max-loop

Find min/max with a single loop instead of sorting.

## Why

Sorting an array to find the smallest or largest element is O(n log n). A single linear scan is O(n), does not allocate a copy, and can find both min and max in one pass. The difference grows significantly with array size.

## Bad

```typescript
// O(n log n) sort just to find one element
function getLatest(projects: Project[]): Project | null {
  const sorted = projects.toSorted((a, b) => b.updatedAt - a.updatedAt)
  return sorted[0] ?? null
}
```

## Good

```typescript
// O(n) single pass
function getLatest(projects: Project[]): Project | null {
  if (projects.length === 0) return null

  let latest = projects[0]
  for (let i = 1; i < projects.length; i++) {
    if (projects[i].updatedAt > latest.updatedAt) {
      latest = projects[i]
    }
  }
  return latest
}
```

## Notes

For primitive arrays, `Math.min(...arr)` / `Math.max(...arr)` is concise but throws on large arrays (~100k+ elements) due to argument limits. Use the loop approach for reliability. The same pattern extends to finding both min and max simultaneously in a single pass.
