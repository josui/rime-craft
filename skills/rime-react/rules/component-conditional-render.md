# component-conditional-render

Guard `&&` conditional renders against numeric falsy values that leak to the DOM.

## Why

`0` and `NaN` are falsy in JavaScript, but JSX renders them as visible text nodes. Using `&&` with a number condition silently prints `0` or `NaN` in the UI instead of rendering nothing.

## Bad

```tsx
function Badge({ count }: { count: number }) {
  // When count = 0, renders literal "0" in the DOM
  return <div>{count && <span className="badge">{count}</span>}</div>
}
```

## Good

```tsx
function Badge({ count }: { count: number }) {
  // Explicit comparison — renders nothing when count is 0
  return <div>{count > 0 && <span className="badge">{count}</span>}</div>
}

// Or with a ternary for full control
function Badge({ count }: { count: number }) {
  return (
    <div>
      {count > 0 ? <span className="badge">{count}</span> : null}
    </div>
  )
}
```

## Notes

Only `null`, `undefined`, and `false` produce no output in JSX. `""`, `0`, and `NaN` all render as text nodes. When the condition is a boolean (e.g. `isVisible && <Component />`), `&&` is safe. When the condition is derived from a number, array length, or any expression that may produce `0` or `NaN`, use an explicit comparison or a ternary.
