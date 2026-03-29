# data-dedup

Deduplicate data requests: use SWR / TanStack Query cache on the client, and `React.cache()` on the server.

## Why

Multiple components independently fetching the same endpoint causes redundant network round-trips, inconsistent UI state, and unnecessary server load.

## Bad

```tsx
// Each component fires its own fetch — 3 identical requests in flight
function Avatar() {
  const [user, setUser] = useState<User | null>(null);
  useEffect(() => {
    fetch("/api/me").then((r) => r.json()).then(setUser);
  }, []);
  return <img src={user?.avatar} />;
}

function Username() {
  const [user, setUser] = useState<User | null>(null);
  useEffect(() => {
    fetch("/api/me").then((r) => r.json()).then(setUser);
  }, []);
  return <span>{user?.name}</span>;
}
```

## Good

```tsx
// Client: useSWR key deduplicates across all mounted components
import useSWR from "swr";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

function Avatar() {
  const { data: user } = useSWR<User>("/api/me", fetcher);
  return <img src={user?.avatar} />;
}

function Username() {
  const { data: user } = useSWR<User>("/api/me", fetcher); // reuses same request
  return <span>{user?.name}</span>;
}

// Server: React.cache() deduplicates within the same render tree
import { cache } from "react";

const getUser = cache(async (id: string): Promise<User> => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
});

async function Avatar({ id }: { id: string }) {
  const user = await getUser(id); // fetches once
  return <img src={user.avatar} />;
}

async function Username({ id }: { id: string }) {
  const user = await getUser(id); // returns cached result
  return <span>{user.name}</span>;
}
```

## Notes

`React.cache()` is per-request on the server — it deduplicates within a single render tree but does not persist across requests.

Client libraries (SWR, TanStack Query) deduplicate both across simultaneous component mounts and across time via stale-while-revalidate, making them suitable for polling or background refresh scenarios.
