# perf-activity

`<Activity>` preserves state and DOM of frequently toggled components, avoiding repeated destroy/mount cycles.

## Why

Conditional rendering (`&&`) destroys a component's state and DOM on hide and rebuilds them on show. For components with expensive mount logic (data fetches, animations, editor initialization), this causes visible jank and wasted work.

## Bad

```tsx
// Switching tabs destroys <TabA> state and remounts it every time
function Tabs() {
  const [tab, setTab] = useState('a')
  return (
    <>
      <TabBar tab={tab} onChange={setTab} />
      {tab === 'a' && <TabA />}
      {tab === 'b' && <TabB />}
    </>
  )
}
```

## Good

```tsx
import { Activity } from 'react'

function Tabs() {
  const [tab, setTab] = useState('a')
  return (
    <>
      <TabBar tab={tab} onChange={setTab} />
      <Activity mode={tab === 'a' ? 'visible' : 'hidden'}>
        <TabA />
      </Activity>
      <Activity mode={tab === 'b' ? 'visible' : 'hidden'}>
        <TabB />
      </Activity>
    </>
  )
}
```

## Notes

`<Activity>` is a React 19 **experimental API** — subject to breaking changes. It is currently available in Next.js App Router. If framework support is unavailable, keep components mounted and toggle visibility with CSS as a fallback:

```tsx
<div style={{ display: tab === 'a' ? undefined : 'none' }}>
  <TabA />
</div>
```

Always communicate the experimental status to stakeholders before adopting `<Activity>` in production.
