# data-suspense-streaming

Wrap async data regions in Suspense boundaries for streaming; avoid blocking the whole page on a single fetch.

## Why

A top-level loading gate delays every pixel on the screen until the slowest data resolves. Suspense boundaries let fast sections paint immediately while slower sections stream in independently.

## Bad

```tsx
// Entire page blocked until data is ready
export default function Page() {
  const [data, setData] = useState<Data | null>(null);

  useEffect(() => {
    fetchData().then(setData);
  }, []);

  if (!data) return <Spinner />;

  return (
    <div>
      <Header />
      <DataSection data={data} />
      <Footer />
    </div>
  );
}
```

## Good

```tsx
// Header and Footer paint immediately; only DataSection streams in
export default function Page() {
  return (
    <div>
      <Header />
      <Suspense fallback={<Skeleton />}>
        <DataSection />
      </Suspense>
      <Footer />
    </div>
  );
}

async function DataSection() {
  const data = await fetchData(); // only this subtree waits
  return <div>{data.content}</div>;
}
```

## Notes

Multiple Suspense boundaries can nest; sections that resolve earlier display first regardless of DOM order (with `<SuspenseList>` for ordered reveal).

Place boundaries at meaningful UX break points — above-the-fold primary content vs. below-the-fold secondary content, or hero vs. sidebar. Avoid Suspense for critical layout data whose absence would cause a jarring shift.
