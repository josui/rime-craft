# perf-bundle-imports

Avoid barrel file re-exports; conditionally load heavy modules; defer third-party scripts post-hydration.

## Why

Barrel files (`index.ts` that re-exports everything) force bundlers to load thousands of unused modules. Popular icon or component libraries can add 200–800 ms to dev cold starts and inflate production bundles significantly.

## Bad

```tsx
// Barrel import — loads the entire @/components module graph
import { Button, Card, Input } from '@/components'

// Third-party script blocking hydration
import { initAnalytics } from 'analytics-sdk'
initAnalytics()
```

## Good

```tsx
// Direct import — only the module you need
import { Button } from '@/components/Button'
import { Card } from '@/components/Card'
import { Input } from '@/components/Input'

// Defer analytics until after hydration
useEffect(() => {
  import('analytics-sdk').then(({ initAnalytics }) => initAnalytics())
}, [])
```

## Notes

Next.js `optimizePackageImports` (13.5+) auto-transforms barrel imports for listed packages — you can keep ergonomic barrel syntax while still getting direct-import performance:

```js
// next.config.js
experimental: { optimizePackageImports: ['lucide-react', '@mui/material'] }
```

Vite handles first-party barrels well when all code is bundled together; the problem is most acute with external packages marked as non-bundled. For analytics, chat widgets, and A/B testing scripts, always load after hydration via dynamic import or a framework Script component.
