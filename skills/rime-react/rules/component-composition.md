# component-composition

Prefer composition (children / slots) over boolean prop sprawl.

## Why

Each boolean prop added to a component doubles the number of possible internal states. Three boolean props already yields eight combinations — most of them untested and subtly broken.

## Bad

```tsx
// Boolean props accumulate and create hidden branching inside Card
<Card
  bordered
  shadowed
  loading
  header={<h2>Title</h2>}
  footer={<button>Save</button>}
/>
```

## Good

```tsx
// Structure is explicit at the call site — no hidden conditionals inside Card
<Card>
  <Card.Header><h2>Title</h2></Card.Header>
  <Card.Body>content</Card.Body>
  <Card.Footer><button>Save</button></Card.Footer>
</Card>
```

## Notes

Rule of thumb: if a component accumulates more than 3 boolean props, refactor to composition. `children` is the simplest slot and covers most cases. For complex layouts with multiple named regions, use compound components (see `component-compound.md`). Each composed variant is explicit about what it renders — no internal `if/else` chains to maintain.
