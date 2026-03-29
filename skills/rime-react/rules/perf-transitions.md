# perf-transitions

Mark non-urgent state updates with `startTransition` to keep inputs responsive during expensive re-renders.

## Why

By default all `setState` calls are treated as urgent, blocking the browser from handling user input until the render finishes. `startTransition` tells React to deprioritize the update, keeping the UI interactive.

## Bad

```tsx
// Filtering triggers an expensive re-render synchronously on every keystroke
function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState(allItems)

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value)
    setResults(allItems.filter(item => item.name.includes(e.target.value)))
  }

  return <input value={query} onChange={handleChange} />
}
```

## Good

```tsx
import { useTransition, useState } from 'react'

function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState(allItems)
  const [isPending, startTransition] = useTransition()

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    setQuery(value)                          // urgent — updates input immediately
    startTransition(() => {
      setResults(allItems.filter(item => item.name.includes(value)))
    })
  }

  return (
    <>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <ResultsList items={results} />
    </>
  )
}
```

## Notes

Do not wrap every `setState` call — only those that trigger expensive UI work (large list filtering, complex tree re-renders, heavy chart updates). `useTransition` returns `[isPending, startTransition]`; use `isPending` to show a loading indicator. `startTransition` (imported directly) is the standalone version when you don't need `isPending`.
