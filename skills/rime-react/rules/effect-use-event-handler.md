# effect-use-event-handler

Side effects from user actions belong in event handlers, not Effects.

## Why

An Effect's dependency array changing does not mean the user intended an action. Event handlers express user intent directly and avoid accidental re-runs caused by unrelated dependency changes.

## Bad

```tsx
function ProductPage() {
  const [selectedId, setSelectedId] = useState('')

  useEffect(() => {
    logView(selectedId)
  }, [selectedId])

  return <select onChange={(e) => setSelectedId(e.target.value)} />
}
```

## Good

```tsx
function ProductPage() {
  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    setSelectedId(e.target.value)
    logView(e.target.value)
  }

  return <select onChange={handleChange} />
}
```

## Notes

If the side effect is "user did X, so do Y" — it's an event handler. If it's "component appeared, so sync with an external system" — it might be a legitimate Effect (see `effect-mount-only`).
