# perf-set-map

Use Set/Map for O(1) membership checks.

## Why

`Array.includes()` and `Array.find()` are O(n) per call. When checking membership repeatedly — inside a loop, filter, or event handler — converting the lookup source to a Set (or Map for key-value pairs) gives O(1) per check after an O(n) build step.

## Bad

```typescript
// O(n) per .includes() call — O(n*m) total
const allowedIds: string[] = ['a', 'b', 'c', /* ... */]
const filtered = items.filter(item => allowedIds.includes(item.id))
```

## Good

```typescript
// O(1) per .has() call — O(n+m) total
const allowedIds = new Set(['a', 'b', 'c', /* ... */])
const filtered = items.filter(item => allowedIds.has(item.id))
```

## Notes

Use `Set` for existence checks and `Map` when you also need the associated value. For small constant lists (< 5 items), the overhead of building a Set may not be worth it — `Array.includes()` is fine. The benefit scales with the number of lookups multiplied by the collection size.
