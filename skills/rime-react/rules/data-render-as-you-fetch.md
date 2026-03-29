# data-render-as-you-fetch

Initiate fetches at the parent level and pass results down — never let children trigger their own fetches on mount in sequence.

## Why

When each component fetches on mount, requests form a waterfall: parent renders → parent fetches → child mounts → child fetches → grandchild mounts → grandchild fetches. Each step waits for the previous, multiplying latency.

## Bad

```tsx
// Sequential waterfall — each fetch waits for the previous component to mount
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    fetchUser(userId).then(setUser); // fetch starts only after mount
  }, [userId]);

  if (!user) return null;
  return <UserPosts userId={user.id} />;
}

function UserPosts({ userId }: { userId: string }) {
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => {
    fetchPosts(userId).then(setPosts); // waits for UserProfile fetch to finish
  }, [userId]);

  return <ul>{posts.map((p) => <li key={p.id}>{p.title}</li>)}</ul>;
}
```

## Good

```tsx
// Parent fires all fetches in parallel before any child mounts
function UserProfile({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId);   // starts immediately
  const postsPromise = fetchPosts(userId); // starts in parallel

  return (
    <Suspense fallback={<Skeleton />}>
      <UserDetails userPromise={userPromise} />
      <UserPosts postsPromise={postsPromise} />
    </Suspense>
  );
}

function UserDetails({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  return <h1>{user.name}</h1>;
}

function UserPosts({ postsPromise }: { postsPromise: Promise<Post[]> }) {
  const posts = use(postsPromise);
  return <ul>{posts.map((p) => <li key={p.id}>{p.title}</li>)}</ul>;
}
```

## Notes

Works best with Suspense: data requests and component rendering start simultaneously instead of waiting for each mount. Also called "fetch-then-render" or the "preloading" pattern.

On the server (RSC), parallel `Promise.all` or co-located `await` at the page level achieves the same effect without Suspense. On the client, TanStack Query's `prefetchQuery` or SWR's `preload` can warm the cache before the component tree renders.
