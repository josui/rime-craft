# effect-derive-state

Compute derived state inline during render — never sync via Effect.

## Why

Effect-based state sync causes redundant renders: render stale value → Effect fires → setState → re-render with correct value. Inline computation completes in a single render pass with zero overhead.

## Bad

```tsx
function Cart({ items }: { items: Item[] }) {
  const [total, setTotal] = useState(0)

  useEffect(() => {
    setTotal(items.reduce((sum, item) => sum + item.price, 0))
  }, [items])

  return <p>Total: {total}</p>
}
```

## Good

```tsx
function Cart({ items }: { items: Item[] }) {
  const total = items.reduce((sum, item) => sum + item.price, 0)

  return <p>Total: {total}</p>
}
```

## Notes

Use `useMemo` for expensive computations, but confirm the bottleneck with profiling first. Applies to filtering, sorting, formatting, and any value fully derivable from props or state.
