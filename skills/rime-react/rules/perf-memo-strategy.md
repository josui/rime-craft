# perf-memo-strategy

With React Compiler: memoization is automatic. Without: use `useMemo`/`React.memo` only for verified expensive computations.

## Why

React Compiler eliminates the need for manual memoization by automatically optimizing re-renders. Without it, wrapping trivial expressions in `useMemo` adds overhead without benefit and obscures intent.

## Bad

```tsx
// useMemo on a trivial expression — no benefit, pure noise
function Label({ firstName, lastName }: Props) {
  const fullName = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName])
  return <span>{fullName}</span>
}
```

## Good

```tsx
// With React Compiler → do nothing, compiler handles it

// Without React Compiler → useMemo only for genuinely expensive work
function SortedList({ items }: { items: Item[] }) {
  const sorted = useMemo(
    () => [...items].sort((a, b) => expensiveScore(b) - expensiveScore(a)),
    [items]
  )
  return <ul>{sorted.map(item => <li key={item.id}>{item.name}</li>)}</ul>
}
```

## Notes

Check Compiler availability: `npx react-compiler-healthcheck`. Simple expressions — property access, arithmetic, string concatenation — never need `useMemo`. `React.memo` is for pure display components that re-render frequently with identical props; pair with `useCallback` for stable callback props. Extract expensive logic into a memoized child component so early returns can skip it entirely.
