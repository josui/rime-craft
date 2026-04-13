# perf-batch-dom

Batch DOM writes then reads to avoid layout thrashing.

## Why

Reading a layout property (`offsetWidth`, `getBoundingClientRect()`, `getComputedStyle()`) between style writes forces the browser to perform a synchronous reflow. Interleaving reads and writes in a loop can trigger dozens of forced layouts per frame, destroying scroll and animation performance.

## Bad

```typescript
// Interleaved write-read forces reflow on every pair
function resize(el: HTMLElement) {
  el.style.width = '100px'
  const w = el.offsetWidth   // forced reflow
  el.style.height = '200px'
  const h = el.offsetHeight  // forced reflow again
}
```

## Good

```typescript
// All reads first, then all writes — single reflow
function resize(el: HTMLElement) {
  const rect = el.getBoundingClientRect()
  const scrollY = window.scrollY

  el.style.width = `${rect.width * 2}px`
  el.style.height = `${rect.height * 2}px`
  el.style.top = `${rect.top + scrollY}px`
}
```

## Notes

Prefer toggling CSS classes over setting inline styles — the browser batches class-based changes more efficiently. When you must mix reads and writes across multiple elements, use `requestAnimationFrame` to defer the write phase. See [CSS Triggers](https://csstriggers.com/) for which properties force layout.
