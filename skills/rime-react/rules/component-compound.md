# component-compound

Use the compound component pattern for complex UI: a top-level component owns shared state via Context, sub-components consume it.

## Why

Monolithic components with render props or long prop lists are hard to extend and lock consumers into one layout. Compound components let consumers compose exactly what they need while shared state flows through Context automatically.

## Bad

```tsx
// Monolithic API — callers can't reorder or omit regions without new props
<Select
  items={items}
  value={value}
  onChange={onChange}
  renderItem={(item) => <span>{item.label}</span>}
  renderEmpty={() => <p>No results</p>}
/>
```

## Good

```tsx
const SelectContext = createContext<SelectContextValue | null>(null)

function Select({ value, onChange, children }: SelectProps) {
  return (
    <SelectContext value={{ value, onChange }}>
      {children}
    </SelectContext>
  )
}

function SelectTrigger() {
  const { value } = use(SelectContext)!
  return <button>{value ?? 'Select…'}</button>
}

function SelectList({ children }: { children: React.ReactNode }) {
  return <ul role="listbox">{children}</ul>
}

// Expose as static properties
Select.Trigger = SelectTrigger
Select.List = SelectList

// Usage
<Select value={v} onChange={setV}>
  <Select.Trigger />
  <Select.List>
    {items.map((item) => <li key={item.id}>{item.label}</li>)}
  </Select.List>
</Select>
```

## Notes

Share state internally via Context — never thread it down through sub-component props. Avoid `React.cloneElement` for sharing state; it breaks when an element is wrapped. Expose sub-components as static properties (`Select.Trigger`, `Select.List`) so they are co-located with the parent in imports.
