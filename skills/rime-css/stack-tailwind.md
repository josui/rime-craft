# Stack: Tailwind CSS (No Framework)

Uses Tailwind for utilities but semantic classes for app-layer elements via `@apply`.

## Directory Structure

```
project/
├── styles/
│   ├── global.css        ← entry: @import url() → @layer → @import 'tailwindcss'
│   ├── _reset.css        ← layer(base)
│   ├── _tokens.css       ← layer(base)
│   ├── _typography.css   ← layer(base)
│   ├── components/
│   │   └── button.css    ← @layer components, uses @reference + @apply
│   └── pages/
│       └── home.css      ← @layer app, uses @reference + @apply
└── index.html
```

## Entry File

```css
/* global.css — ORDER MATTERS */

/* 1. External fonts MUST be first, before everything */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

/* 2. Layer declaration */
@layer theme, base, components, app, utilities;

/* 3. Tailwind (manages utilities layer) */
@import 'tailwindcss';

/* 4. Base layer imports */
@import './_reset.css' layer(base);
@import './_tokens.css' layer(base);
@import './_typography.css' layer(base);
```

## `@apply` Bridging Strategy

**Use `@apply` for** properties with Tailwind equivalents (spacing, flex, grid, font-size, text-align, etc.)

**Hand-write** properties without equivalents (custom OKLCH colors, complex gradients, animations)

**Mixing is OK** in the same declaration block:

```css
@layer app {
  .hero-banner {
    @apply p-8 grid gap-6 rounded-2xl;         /* layout — @apply */
    background: linear-gradient(135deg, #2a2a3a 0%, #4a4a6a 100%);  /* skin — hand-write */
  }
}
```

## `@reference` Directive (Tailwind v4)

CSS files using `@apply` outside the entry file MUST declare `@reference`:

```css
/* components/button.css — separate file */
@reference "../styles/global.css";

@layer components {
  .c-button { @apply inline-flex items-center justify-center font-bold rounded-full; }
  .c-button[data-variant='default'] {
    background: var(--color-primary);
    color: var(--color-primary-fg);
  }
  .c-button[data-variant='outline'] { @apply border border-input; }
}
```

**Tip:** Use Node.js subpath imports to simplify paths:

```json
// package.json
{ "imports": { "#styles/*": "./src/styles/*" } }
```

```css
@reference "#styles/global.css";  /* works from any depth */
```

## Component Example

```css
/* components/card.css */
@reference "#styles/global.css";

@layer components {
  .c-card {
    @apply rounded-2xl overflow-hidden;
    background: var(--color-card);
  }

  .c-card[data-elevated] {
    @apply shadow-md;
  }
}
```

## App Layer Example: Dashboard

```css
/* pages/dashboard.css */
@reference "#styles/global.css";

@layer app {
  .l-dashboard {
    @apply p-6 grid gap-6;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  }

  .stat-card {
    @apply p-6 text-center;
  }

  .stat-card__label {
    @apply text-xs mb-2 text-muted-foreground;
  }

  .stat-card__value {
    @apply text-4xl font-bold;
  }

  .stat-card__trend {
    @apply text-sm mt-1;
  }

  .stat-card__trend[data-direction='up'] {
    color: var(--color-success);
  }

  .stat-card__trend[data-direction='down'] {
    color: var(--color-destructive);
  }
}
```

```html
<div class="l-dashboard">
  <div class="c-card" data-elevated>
    <div class="stat-card">
      <div class="stat-card__label">Monthly Revenue</div>
      <div class="stat-card__value">¥1,234,567</div>
      <div class="stat-card__trend" data-direction="up">+12.5%</div>
    </div>
  </div>
</div>
```

## Skin vs Layout in HTML

```html
<!-- ✅ Layout utilities on elements without semantic class -->
<div class="mt-4 flex gap-3">
  <button class="c-button" data-variant="default">OK</button>
  <button class="c-button" data-variant="outline">Cancel</button>
</div>

<!-- ❌ Skin utilities in app markup — extract to CSS -->
<div class="bg-white rounded-xl shadow-lg p-6">Bad</div>

<!-- ✅ Same thing, properly semantic -->
<div class="stat-card">Good</div>
```

## Gotchas

### 1. `--alpha()` Variables (Tailwind v4)

Some theme variables use Tailwind's build-time `--alpha()` function — browsers can't parse them:

| Variable | `var()` safe? | Use instead |
|----------|---------------|-------------|
| `--muted`, `--secondary`, `--accent`, `--border`, `--input` | **NO** | `@apply bg-muted`, `@apply border-input` |
| `--muted-foreground`, `--primary`, `--destructive` | **YES** | `color: var(--color-primary)` OK |

```css
/* ✅ */ .foo { @apply bg-muted border-input; }
/* ❌ */ .foo { background: var(--color-muted); }  /* unresolved --alpha() */
```

### 2. Font `@import url()` Placement

Must be at **very top** of entry file, **before** `@layer` and `@import 'tailwindcss'`. Placing in a sub-file imported with `layer()` silently fails.

### 3. `@reference` Required

Any `.css` file using `@apply` outside the entry file needs `@reference` or build fails with "Cannot apply unknown utility class".
