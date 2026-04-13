# perf-cache-results

Module-level Map cache for repeated computations.

## Why

When the same pure function is called many times with identical inputs — inside a loop, across event handlers, or during rendering — each call repeats the same work. A module-level Map eliminates redundant computation and works anywhere, not just inside components.

## Bad

```typescript
// slugify() called for every item, even with duplicate names
function buildSlugs(items: Item[]): string[] {
  return items.map(item => slugify(item.name))
}
```

## Good

```typescript
// Module-level cache — persists across calls
const slugCache = new Map<string, string>()

function cachedSlugify(text: string): string {
  const cached = slugCache.get(text)
  if (cached !== undefined) return cached

  const result = slugify(text)
  slugCache.set(text, result)
  return result
}

function buildSlugs(items: Item[]): string[] {
  return items.map(item => cachedSlugify(item.name))
}
```

## Notes

Use a Map (not a framework hook) so the cache works in utilities, event handlers, and workers. For single-value caches, a simple `let` variable suffices. Add a `clear()` function or size limit if the input domain is unbounded.
