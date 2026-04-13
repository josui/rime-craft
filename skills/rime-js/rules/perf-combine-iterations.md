# perf-combine-iterations

Merge chained .filter().map() into a single loop.

## Why

Each chained array method (`.filter()`, `.map()`, `.reduce()`) creates a new intermediate array and walks the entire collection again. When you need multiple derived lists from the same source, a single `for...of` loop does one pass and allocates only the result arrays.

## Bad

```typescript
// 3 full iterations over the same array
const admins = users.filter(u => u.isAdmin)
const testers = users.filter(u => u.isTester)
const inactive = users.filter(u => !u.isActive)
```

## Good

```typescript
// 1 iteration, 3 results
const admins: User[] = []
const testers: User[] = []
const inactive: User[] = []

for (const user of users) {
  if (user.isAdmin) admins.push(user)
  if (user.isTester) testers.push(user)
  if (!user.isActive) inactive.push(user)
}
```

## Notes

This matters when the array is large or the predicate is expensive. For small arrays with simple predicates, chained methods are fine and more readable. The same principle applies to `.map().filter()` chains — see `perf-flatmap` for a concise single-pass alternative.
