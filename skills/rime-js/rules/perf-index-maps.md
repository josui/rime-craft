# perf-index-maps

Build an index Map for repeated key lookups.

## Why

Calling `.find()` inside a loop is O(n) per lookup, making the overall operation O(n*m). Building a Map first is O(n) setup with O(1) per lookup — for 1000 orders x 1000 users, that is 1M comparisons reduced to ~2K operations.

## Bad

```typescript
// O(n) lookup per order — O(n*m) total
function enrichOrders(orders: Order[], users: User[]): EnrichedOrder[] {
  return orders.map(order => ({
    ...order,
    user: users.find(u => u.id === order.userId),
  }))
}
```

## Good

```typescript
// O(1) lookup per order — O(n+m) total
function enrichOrders(orders: Order[], users: User[]): EnrichedOrder[] {
  const userById = new Map(users.map(u => [u.id, u]))

  return orders.map(order => ({
    ...order,
    user: userById.get(order.userId),
  }))
}
```

## Notes

Apply this whenever you join two collections by a shared key — matching IDs, resolving foreign keys, or grouping related records. The same pattern works with `Object.groupBy()` (ES2024) for grouping by category. Use `Map` over plain objects for non-string keys and guaranteed iteration order.
