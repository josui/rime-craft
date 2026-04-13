# async-parallel

Run independent async operations with `Promise.all` or `Promise.allSettled` — never sequential `await`.

## Why

Sequential `await` on independent operations serializes them, making total latency the sum of all round trips. Parallel execution reduces total wait time to the duration of the slowest single operation. For three 200ms fetches, that is 600ms sequential vs 200ms parallel.

## Bad

```typescript
// Sequential — total wait = fetchUser + fetchPosts + fetchNotifications
async function loadDashboard(userId: string) {
  const user = await fetchUser(userId)
  const posts = await fetchPosts(userId)
  const notifications = await fetchNotifications(userId)
  return { user, posts, notifications }
}
```

## Good

```typescript
// Parallel — total wait = max(fetchUser, fetchPosts, fetchNotifications)
async function loadDashboard(userId: string) {
  const [user, posts, notifications] = await Promise.all([
    fetchUser(userId),
    fetchPosts(userId),
    fetchNotifications(userId),
  ])
  return { user, posts, notifications }
}
```

## Notes

`Promise.all` is fail-fast: any single rejection rejects the entire result. Use `Promise.allSettled` when you need partial results even if some operations fail (e.g., loading independent dashboard widgets). The deferred await pattern is useful when mixing sync and async work:

```typescript
const dataPromise = fetchData()   // starts immediately
const processed = transformLocal() // sync work runs while fetch is in flight
const data = await dataPromise     // await only when needed
```

Choose the concurrency strategy based on business semantics, not convenience.
