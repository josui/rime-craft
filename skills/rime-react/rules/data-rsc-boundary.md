# data-rsc-boundary

Minimize serialized data across the Server/Client boundary; define "use client" split points at the smallest interactive unit.

## Why

Every prop crossing the RSC boundary is serialized into the HTML payload. Marking large components "use client" shifts data fetching to the client and bloats the wire payload with unused fields.

## Bad

```tsx
// Entire page marked "use client" — all data fetched on the client
"use client";

export default function Page() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    fetch("/api/user/1")
      .then((r) => r.json())
      .then(setUser);
  }, []);

  return <div>{user?.name}</div>;
}
```

## Good

```tsx
// Server Component fetches data; only the interactive widget is "use client"
async function Page() {
  const user = await fetchUser(1); // runs on server, never serialized
  return <LikeButton userId={user.id} initialCount={user.likeCount} />;
  //                  ^^^^^^^^^^^^ only two fields cross the boundary
}

// LikeButton.tsx
"use client";
function LikeButton({
  userId,
  initialCount,
}: {
  userId: string;
  initialCount: number;
}) {
  const [count, setCount] = useState(initialCount);
  return <button onClick={() => setCount((c) => c + 1)}>{count}</button>;
}
```

## Notes

RSC requires framework support (Next.js App Router, Remix future flags, etc.). **Skip this rule for projects without RSC support.**

Keep serialized props minimal — never pass an entire database object across the boundary. Extract only the fields the client component actually renders or reacts to.
