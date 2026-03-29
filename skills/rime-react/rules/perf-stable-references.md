# perf-stable-references

Four techniques to avoid unnecessary re-renders caused by unstable references: functional setState, hoisted defaults, `useRef` for transient values, lazy state initializer.

## Why

Inline object/array literals and non-functional state updates create new references on every render, breaking memoization and causing cascading re-renders in child components.

## Bad

```tsx
// Inline default → new array reference every render
function List({ items = [] }: { items?: string[] }) {
  return <ul>{items.map(i => <li key={i}>{i}</li>)}</ul>
}

// Stale closure update
function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(count + 1)}>+</button>
}

// Inside a component — runs expensiveInit on every render, not just mount
const [state, setState] = useState(expensiveInit())
```

## Good

```tsx
// Hoisted constant → stable reference
const DEFAULT_ITEMS: string[] = []
function List({ items = DEFAULT_ITEMS }: { items?: string[] }) {
  return <ul>{items.map(i => <li key={i}>{i}</li>)}</ul>
}

// Functional update → no stale closure
function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>+</button>
}

// Inside a component — lazy initializer runs once at mount
const [state, setState] = useState(() => expensiveInit())
```

## Notes

Use `useRef` for values that are read inside Effects but do not drive rendering — previous values, interval/timeout IDs, DOM nodes for measurements. Mutating a ref does not trigger re-renders. For callbacks passed as props, `useCallback` creates a stable reference; combine with `React.memo` on the child.
