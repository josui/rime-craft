# perf-async-parallel

Use `Promise.all` for independent async operations; defer `await` until the result is actually consumed.

## Why

Sequential `await` chains serialize independent fetches, making total latency the sum of all round trips. Running them in parallel reduces total wait time to the slowest single request.

## Bad

```tsx
// Sequential — total wait = fetchA + fetchB + fetchC
async function loadDashboard() {
  const user = await fetchUser()
  const posts = await fetchPosts()
  const stats = await fetchStats()
  return { user, posts, stats }
}
```

## Good

```tsx
// Parallel — total wait = max(fetchUser, fetchPosts, fetchStats)
async function loadDashboard() {
  const [user, posts, stats] = await Promise.all([
    fetchUser(),
    fetchPosts(),
    fetchStats(),
  ])
  return { user, posts, stats }
}
```

## Notes

Deferred await — start the fetch early, await only when the value is needed:

```tsx
const userPromise = fetchUser()     // starts immediately
const postsPromise = fetchPosts()   // starts immediately
doSomeSyncWork()
const user = await userPromise      // await when consumed
const posts = await postsPromise
```

This pattern applies equally to React Server Components and framework data loaders (Next.js `generateMetadata`, Remix `loader`). Use `Promise.allSettled` when you need results from all operations even if some fail.
