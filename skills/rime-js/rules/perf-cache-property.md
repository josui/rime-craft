# perf-cache-property

Cache deep property access in hot loops.

## Why

Each dot in a property chain is a lookup. In tight loops running thousands of iterations, repeatedly traversing `obj.config.settings.value` adds measurable overhead. Hoisting the value into a local variable eliminates redundant lookups.

## Bad

```typescript
// 3 property lookups per iteration
for (let i = 0; i < arr.length; i++) {
  process(obj.config.settings.value)
}
```

## Good

```typescript
// Single lookup, reused across all iterations
const value = obj.config.settings.value
const len = arr.length
for (let i = 0; i < len; i++) {
  process(value)
}
```

## Notes

This matters most in hot paths — inner loops, animation frames, data processing pipelines. For code that runs once or a few times, readability wins over micro-optimization. Also cache `array.length` when the array size does not change during iteration.
