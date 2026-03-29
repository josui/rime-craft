# component-no-inline-def

Never define components inside other components.

## Why

Each render creates a new component definition, so React sees a different component type every time. It fully remounts the child — destroying all internal state, re-running effects, and recreating DOM nodes.

## Bad

```tsx
function Parent({ theme }: { theme: string }) {
  // New function identity on every render — React remounts Child each time
  function Child() {
    return <div className={theme}>hello</div>
  }

  return <Child />
}
```

## Good

```tsx
// Defined at module level — stable identity across renders
function Child({ theme }: { theme: string }) {
  return <div className={theme}>hello</div>
}

function Parent({ theme }: { theme: string }) {
  return <Child theme={theme} />
}
```

## Notes

This applies equally to arrow function components (`const Child = () => ...`) defined inside another component body. The fix is always the same: move the definition to module top level and pass data via props instead of closing over parent scope. Symptoms of the bug: input fields lose focus on keystroke, animations restart unexpectedly, `useEffect` runs on every parent render.
