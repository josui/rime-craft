# effect-mount-only

Effects are strictly for syncing with external systems on mount: DOM APIs, third-party widgets, browser API subscriptions.

## Why

Effects exist to synchronize React with the outside world. If both sides of the synchronization are React state, you don't need an Effect — use derived computation or event handlers instead.

## Bad

```tsx
function ThemeSync({ isDark }: { isDark: boolean }) {
  const [bodyClass, setBodyClass] = useState('')

  useEffect(() => {
    setBodyClass(isDark ? 'dark' : 'light')
  }, [isDark])

  return <div className={bodyClass} />
}
```

## Good

```tsx
function MapWidget({ center }: { center: LatLng }) {
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const map = L.map(ref.current!)
    map.setView(center)
    return () => map.remove()
  }, [])

  return <div ref={ref} />
}
```

## Notes

An empty dependency array `[]` is the only reasonable Effect pattern (mount-only). If you're adding dependencies beyond refs, you likely need an event handler (`effect-use-event-handler`) or derived computation (`effect-derive-state`) instead. Suppress `react-hooks/exhaustive-deps` for mount-only Effects that intentionally read initial props — the lint rule cannot distinguish "sync on every change" from "read once at mount."
