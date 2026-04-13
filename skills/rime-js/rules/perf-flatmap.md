# perf-flatmap

`.flatMap()` for combined map + filter in one pass.

## Why

Chaining `.map().filter(Boolean)` iterates the array twice and creates an intermediate array that is immediately discarded. `.flatMap()` does both in a single pass — return a one-element array to keep, or an empty array to skip.

## Bad

```typescript
// 2 iterations + intermediate array
const activeNames = users
  .map(user => user.isActive ? user.name : null)
  .filter(Boolean)
```

## Good

```typescript
// 1 iteration, no intermediate array
const activeNames = users.flatMap(user =>
  user.isActive ? [user.name] : []
)
```

## Notes

Use `.flatMap()` whenever you need to conditionally transform — parsing with validation, extracting optional fields, or expanding one-to-many relationships. For simple filtering without transformation, `.filter()` alone is still the right choice.
