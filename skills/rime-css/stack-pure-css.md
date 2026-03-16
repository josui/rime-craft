# Stack: Pure CSS (No Tailwind, No Framework)

Hand-rolled layers, tokens via CSS custom properties, all styles in CSS files.

## Directory Structure

```
project/
├── styles/
│   ├── main.css          ← @layer declarations + @imports
│   ├── _reset.css        ← layer(base)
│   ├── _tokens.css       ← layer(base)
│   ├── _typography.css   ← layer(base)
│   ├── components/
│   │   ├── button.css    ← layer(components)
│   │   └── card.css
│   └── pages/
│       ├── home.css      ← layer(app)
│       └── about.css
└── index.html
```

## Entry File

```css
/* main.css */
@layer theme, base, components, app, utilities;

@import './_reset.css' layer(base);
@import './_tokens.css' layer(base);
@import './_typography.css' layer(base);
@import './components/button.css' layer(components);
@import './components/card.css' layer(components);
@import './pages/home.css' layer(app);
```

## Token System

All design values as CSS custom properties — single source of truth:

```css
/* _tokens.css */
:root {
  /* Colors (OKLCH recommended for perceptual uniformity) */
  --color-primary: oklch(0.35 0.02 260);
  --color-primary-fg: oklch(1 0 0);
  --color-border: oklch(0.88 0.005 80);
  --color-muted: oklch(0.65 0.01 80);
  --color-success: oklch(0.65 0.2 145);
  --color-destructive: oklch(0.55 0.2 25);

  /* Spacing (4px grid) */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;

  /* Radii */
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-full: 9999px;

  /* Motion */
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --duration-fast: 150ms;
  --duration-normal: 250ms;
}
```

## Component Example: Button

```css
/* components/button.css */
.c-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  font-weight: bold;
  white-space: nowrap;
  border-radius: var(--radius-full);
  border: none;
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

/* Variants via data-* */
.c-button[data-variant='default'] {
  background: var(--color-primary);
  color: var(--color-primary-fg);
}

.c-button[data-variant='outline'] {
  background: transparent;
  border: 1px solid var(--color-border);
  color: var(--color-primary);
}

.c-button[data-variant='ghost'] {
  background: transparent;
  color: var(--color-primary);
}

/* Sizes via data-* */
.c-button[data-size='sm'] {
  font-size: 0.875rem;
  padding: var(--space-1) var(--space-4);
}

.c-button[data-size='default'] {
  font-size: 1rem;
  padding: var(--space-2) var(--space-6);
}

/* States */
.c-button:active { opacity: 0.85; }
.c-button[data-disabled] { opacity: 0.5; pointer-events: none; }
```

## App Layer Example: Product List

```css
/* pages/products.css */
.l-product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: var(--space-4);
  padding: var(--space-4);
}

.product-card {
  border-radius: var(--radius-xl);
  overflow: hidden;
  background: white;
}

.product-card__image {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
}

.product-card__body {
  padding: var(--space-4);
}

.product-card__name {
  font-size: 1rem;
  font-weight: 600;
}

.product-card__price {
  font-size: 1.25rem;
  font-weight: bold;
  margin-top: var(--space-1);
}

.product-card__price[data-sale] {
  color: var(--color-destructive);
}
```

```html
<div class="l-product-grid">
  <div class="product-card">
    <img class="product-card__image" src="..." alt="..." />
    <div class="product-card__body">
      <h3 class="product-card__name">Product Name</h3>
      <div class="product-card__price" data-sale>¥1,980</div>
      <button class="c-button" data-variant="default" data-size="default">
        カートに入れる
      </button>
    </div>
  </div>
</div>
```

## Data-Driven State Example

```css
/* Tabs — state via data-*, no JS class toggling */
.nav-tab[data-active] {
  border-bottom: 2px solid var(--color-primary);
  color: var(--color-primary);
}

/* Notification badge — variant via data-* */
.c-badge[data-variant='success'] { background: var(--color-success); }
.c-badge[data-variant='error'] { background: var(--color-destructive); }
```

```html
<nav>
  <button class="nav-tab" data-active>タブ1</button>
  <button class="nav-tab">タブ2</button>
</nav>
```

## Key Rules for Pure CSS

1. **All values from tokens** — never hardcode `#fff` or `16px`, use `var(--color-*)` / `var(--space-*)`
2. **No utility classes** — everything is semantic (no `.text-center`, `.flex`, etc.)
3. **No `style=""` for skin** — inline styles only for truly dynamic values (JS-computed positions, etc.)
4. **Layer everything** — every CSS rule lives in an explicit `@layer`
