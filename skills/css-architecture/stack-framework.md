# Stack: Framework + Tailwind + Component Library

Full CUBE CSS with component library integration (shadcn, cossui, Radix, etc.). Applies to React, Vue, Svelte, or any component-based framework with Tailwind.

## Directory Structure

```
src/
├── styles/
│   ├── global.css
│   ├── _reset.css / _tokens.css / _typography.css
├── components/ui/            ← component layer
│   ├── index.tsx             ← unified exports
│   ├── button/
│   │   ├── button.tsx
│   │   ├── button.css        ← @layer components
│   │   └── button.stories.tsx
│   └── card/ ...
├── apps/                     ← app layer
│   └── profile/
│       ├── App.tsx
│       ├── profile.css       ← @layer app (root-level)
│       └── components/
│           ├── my-point/
│           │   ├── PointCard.tsx
│           │   └── my-point.css  ← @layer app (module)
│           └── my-skin/ ...
└── lint/                     ← custom lint rules
    ├── eslint/no-skin-utilities.js
    └── stylelint/no-component-override.js
```

## Component Library Intake Flow

**Every** component pulled from shadcn/cossui MUST be restyled before use:

1. **Place** in `components/ui/{name}/`
2. **Directory** contains `{name}.tsx` + `{name}.css` + `{name}.stories.tsx`
3. **Root class** `c-{name}`, keep `data-slot` debug anchors
4. **Remove CVA** — variants via `data-*` + CSS, not class string concatenation
5. **Skin in CSS** — colors/borders/shadows stay in component CSS, never in app layer
6. **Export** via `components/ui/index.tsx`
7. **Verify** default/disabled/hover/active states before using in app code

### Before (CVA pattern — remove this):

```tsx
const variants = cva('inline-flex items-center...', {
  variants: { variant: { default: 'bg-primary text-white', outline: 'border...' } }
})
<button className={cn(variants({ variant }), className)} />
```

### After (data-\* + CSS):

```tsx
// button.tsx
<button className={cn('c-button', className)} data-variant={variant} data-size={size} {...props} />
```

```css
/* button.css — @layer components */
@reference "#styles/global.css";

@layer components {
  .c-button { @apply inline-flex items-center justify-center font-bold rounded-full; }
  .c-button[data-variant='default'] { background: var(--color-primary); color: var(--color-primary-fg); }
  .c-button[data-variant='outline'] { @apply border border-input; color: var(--color-secondary-fg); }
  .c-button[data-size='sm'] { @apply text-sm px-4 py-1; }
  .c-button[data-size='default'] { @apply text-base px-6 py-2; }
  .c-button[data-disabled] { @apply opacity-50 pointer-events-none; }
}
```

## App Layer: Full Semanticization

**Every element gets a semantic class. All visual styles go to CSS via `@apply`. No utility mixing.**

```tsx
// ✅ Correct — pure semantic classes
<Card className="point-summary">
  <div className="point-summary__heading">保有ポイント</div>
  <div className="point-summary__orb">
    <span className="point-summary__value">{points}</span>
    <span className="point-summary__unit">pt</span>
  </div>
</Card>
```

```css
@layer app {
  .point-summary { @apply p-6; }
  .point-summary__heading { @apply mb-4 text-lg font-medium; }
  .point-summary__orb {
    @apply flex size-40 flex-col items-center justify-center rounded-full shadow-md;
    background: linear-gradient(135deg, #5a6270 0%, #7a8290 100%);
  }
  .point-summary__value { @apply mb-1 text-5xl font-bold text-white; }
  .point-summary__unit { @apply text-sm text-white/90; }
}
```

```tsx
// ❌ BANNED — utility mixed with semantic class
<Card className="point-summary p-6">
  <div className="mb-4 text-lg font-medium">保有ポイント</div>
</Card>
```

## Layout Utilities on UI Components — OK

Passing layout utilities to UI components for contextual sizing is allowed:

```tsx
{/* ✅ flex-1, w-full on Button = layout override, OK */}
<div className="point-summary__actions">
  <Button variant="default" className="flex-1">履歴</Button>
  <Button variant="outline" className="flex-1">交換</Button>
</div>

{/* ✅ w-28 on Progress = sizing override, OK */}
<Progress value={score} className="w-28" />

{/* ❌ Skin utilities on UI components = BANNED */}
<Button className="bg-white rounded-xl shadow-lg">Bad</Button>
<Card className="border-red-500 text-destructive">Bad</Card>
```

## Data-Driven States

```tsx
{/* Positive/negative values */}
<span className="point-delta" data-sign={delta >= 0 ? 'plus' : 'minus'}>
  {delta >= 0 ? `+${delta}` : delta}
</span>

{/* Status with variant */}
<div className="l-point-status" data-size="xs">読み込み中...</div>

{/* Multi-step flow */}
<SheetBody data-step={step}>
  {step === 'upload' && <UploadPanel />}
  {step === 'analyzing' && <AnalyzingPanel />}
</SheetBody>
```

```css
@layer app {
  .point-delta { @apply text-sm font-medium; }
  .point-delta[data-sign='plus'] { color: var(--color-success); }
  .point-delta[data-sign='minus'] { color: var(--color-destructive); }

  .l-point-status { @apply py-6 text-center text-sm text-muted-foreground; }
  .l-point-status[data-size='xs'] { @apply py-2 text-xs; }
}
```

## Lint Enforcement

Two custom rules to enforce boundaries at CI/pre-commit level:

### ESLint: `css-arch/no-skin-utilities`

Scope: `src/apps/**/*.{ts,tsx}`

| Banned | Example |
|--------|---------|
| `bg-*` | `bg-white`, `bg-secondary/50` |
| `text-{color}` | `text-white`, `text-muted-foreground` |
| `rounded*` | `rounded`, `rounded-lg` |
| `shadow*` | `shadow`, `shadow-md` |
| `border*` | `border`, `border-t` |

Allowed: `text-sm`, `text-center`, `text-2xl` (layout/typography).

### Stylelint: `css-arch/no-component-override`

Scope: `src/apps/**/*.css`

Bans skin properties (`background`, `color`, `border-radius`, `box-shadow`, etc.) on `.c-*` selectors in app-layer CSS. Forces use of component API (variant/size props) instead of direct override.
