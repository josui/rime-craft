# perf-cache-storage

Cache localStorage/sessionStorage reads in memory.

## Why

`localStorage`, `sessionStorage`, and `document.cookie` are synchronous I/O. Each call blocks the main thread to access disk-backed storage. When the same key is read repeatedly (e.g. theme, locale, feature flags), an in-memory Map eliminates the I/O cost entirely.

## Bad

```typescript
// Reads from disk on every call
function getTheme(): string {
  return localStorage.getItem('theme') ?? 'light'
}
// Called 10 times = 10 synchronous I/O reads
```

## Good

```typescript
const storageCache = new Map<string, string | null>()

function getCached(key: string): string | null {
  if (!storageCache.has(key)) {
    storageCache.set(key, localStorage.getItem(key))
  }
  return storageCache.get(key)!
}

function setCached(key: string, value: string): void {
  localStorage.setItem(key, value)
  storageCache.set(key, value)
}
```

## Notes

Invalidate the cache when storage can change externally. Listen for the `storage` event (cross-tab writes) and clear on `visibilitychange` if server-set cookies may have changed. Use a Map (not a framework hook) so the cache works in utilities and event handlers.
