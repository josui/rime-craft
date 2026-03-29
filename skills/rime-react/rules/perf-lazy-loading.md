# perf-lazy-loading

Lazy-load heavy components (charts, editors, maps). Preload on hover/focus for an instant feel.

## Why

Static top-level imports include every component in the initial bundle, bloating the main chunk and delaying Time to Interactive (TTI). Deferring large components until they are actually needed improves load performance significantly.

## Bad

```tsx
// Bundled into the main chunk even if the user never visits this tab
import HeavyChart from './HeavyChart'

function Dashboard() {
  return <HeavyChart data={data} />
}
```

## Good

```tsx
import { lazy, Suspense } from 'react'

const HeavyChart = lazy(() => import('./HeavyChart'))

function Dashboard() {
  return (
    <Suspense fallback={<Skeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  )
}

// Preload on hover so the chunk is ready before the click
function ChartButton() {
  return (
    <button
      onMouseEnter={() => import('./HeavyChart')}
      onClick={() => setShowChart(true)}
    >
      Show Chart
    </button>
  )
}
```

## Notes

Stack hints — Vite: use `React.lazy` + `Suspense` as shown above. Next.js: prefer `next/dynamic` which handles SSR and named exports cleanly:

```tsx
import dynamic from 'next/dynamic'
const HeavyChart = dynamic(() => import('./HeavyChart'), { ssr: false })
```

Preloading on `onMouseEnter`/`onFocus` gives ~100–300 ms head start, making the component appear instant on click. Good candidates: code editors, rich-text editors, map components, data-visualization libraries.
