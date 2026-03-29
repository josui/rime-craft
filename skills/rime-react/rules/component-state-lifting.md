# component-state-lifting

Lift shared state to the nearest common ancestor or a Provider. Keep children decoupled from each other.

## Why

When sibling components each manage their own copy of the same data, they drift out of sync and require brittle cross-component synchronization. Lifting to a common ancestor gives one authoritative source of truth.

## Bad

```tsx
// Both siblings fetch and store the same selected item independently
function FilterPanel() {
  const [selected, setSelected] = useState<string | null>(null)
  // ... uses selected locally only
}

function ResultsList() {
  const [selected, setSelected] = useState<string | null>(null)
  // ... duplicated, will drift out of sync
}
```

## Good

```tsx
// Parent owns the state; children receive it via props
function Page() {
  const [selected, setSelected] = useState<string | null>(null)

  return (
    <>
      <FilterPanel selected={selected} onSelect={setSelected} />
      <ResultsList selected={selected} />
    </>
  )
}
```

## Notes

Don't over-lift. If only two siblings share a value, their immediate parent is enough — no need for a global context. The principle: "state lives as close as possible to where it's used." Reach for Context only when the common ancestor is many layers above, or when the shared state is needed by many unrelated subtrees. Global context should not hold transient UI state like hover or focus.
