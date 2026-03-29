# effect-data-fetching

Use SWR / TanStack Query / framework loaders for data fetching, not raw `useEffect` + `fetch`.

## Why

Hand-rolled Effect fetch lacks caching, request dedup, race condition handling, background refresh, and error retry. Libraries solve all of these out of the box.

## Bad

```tsx
function UserProfile({ userId }: { userId: string }) {
  const [data, setData] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    fetch(`/api/users/${userId}`, { signal: controller.signal })
      .then((res) => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false))
    return () => controller.abort()
  }, [userId])

  if (loading) return <Spinner />
  if (error) return <ErrorMessage error={error} />
  return <div>{data?.name}</div>
}
```

## Good

```tsx
// SWR
function UserProfile({ userId }: { userId: string }) {
  const { data, error, isLoading } = useSWR(`/api/users/${userId}`, fetcher)

  if (isLoading) return <Spinner />
  if (error) return <ErrorMessage error={error} />
  return <div>{data?.name}</div>
}

// TanStack Query
function UserProfile({ userId }: { userId: string }) {
  const { data, error, isPending } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  })

  if (isPending) return <Spinner />
  if (error) return <ErrorMessage error={error} />
  return <div>{data?.name}</div>
}
```

## Notes

If adding a library isn't possible, use `use(promise)` (React 19) at minimum. Framework data loaders (Next.js Server Components, Remix loaders) are even better — they run server-side and eliminate the client fetch entirely.
