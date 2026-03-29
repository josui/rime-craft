# effect-reset-with-key

Reset component state with the `key` prop, not an Effect watching a prop change.

## Why

When `key` changes, React destroys the old instance and mounts a fresh one — all state resets naturally. This is declarative and avoids the stale-value flash that Effect-based resets cause.

## Bad

```tsx
function ProfileEditor({ userId }: { userId: string }) {
  const [input, setInput] = useState('')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setInput('')
    setError(null)
  }, [userId])

  return <input value={input} onChange={(e) => setInput(e.target.value)} />
}
```

## Good

```tsx
function ProfilePage({ userId }: { userId: string }) {
  return <ProfileEditor key={userId} userId={userId} />
}

function ProfileEditor({ userId }: { userId: string }) {
  const [input, setInput] = useState('')
  const [error, setError] = useState<string | null>(null)

  return <input value={input} onChange={(e) => setInput(e.target.value)} />
}
```

## Notes

Works for any scenario where "prop X changed, so reset everything." The `key` prop is React's built-in mechanism for component identity — use it instead of manual state resets.
