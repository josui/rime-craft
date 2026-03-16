---
name: rime-css
description: Use when setting up CSS file structure, writing component or page styles, establishing BEM naming conventions, configuring CSS @layer ordering, reviewing CSS organization, or migrating CSS architecture. Covers CUBE CSS methodology, data-* driven variants, skin vs layout separation, CSS custom properties tokens. Applies to pure CSS, Tailwind (@apply, @reference), and framework-based (React/Vue/Svelte) projects with or without component libraries (shadcn, cossui, Radix).
---

# CSS Architecture — CUBE CSS Layered Approach

Layered CSS architecture based on CUBE CSS. Separates **skin** (visual) from **layout** (spatial), enforces layer boundaries via CSS `@layer`, uses `data-*` for all variants/states. Adapts to any web stack.

## Stack Detection

Detect stack first, then read the corresponding sub-document for implementation details:

```
Has Tailwind? ─── NO ──→ Read stack-pure-css.md
      │
     YES
      │
Has framework? ─── NO ──→ Read stack-tailwind.md
      │
     YES ──→ Read stack-framework.md
```

## Core: Layer Strategy (Universal)

```
theme < base < components < app < utilities
```

| Layer | Content | Source |
|-------|---------|--------|
| `theme` / `base` | Tokens, reset, typography, global layout | `styles/_*.css` |
| `components` | Reusable UI components (`c-*`) | `components/**/*.css` |
| `app` | Page/feature semantic styles | `apps/**/*.css` or `pages/**/*.css` |
| `utilities` | Single-purpose overrides | Tailwind auto-gen or hand-rolled |

```css
/* CSS entry file — declare order, then import */
@layer theme, base, components, app, utilities;
```

### Legacy Coexistence (unlayered styles)

When the page has **unlayered legacy/preload CSS you cannot modify**, unlayered styles always beat all `@layer` styles — regardless of specificity. In this case:

- **Design system / third-party** → keep in `layer()` (e.g. `@import url("lib.css") layer(lib)`)
- **Your components / app / utilities** → write **unlayered** (no `@layer` wrapper)
- Maintain the same mental ordering (`components` before `app` before `utilities`) via source order and specificity, even without explicit layers

```css
/* Third-party in layer — lowest priority */
@import url("lib.css") layer(lib);

/* Your styles — unlayered to coexist with legacy unlayered CSS */
/* components (loaded first = lower source-order priority) */
@import './components/button.css';
/* app (loaded after = wins over components by source order) */
@import './pages/home.css';
```

Only adopt full `@layer` when you control **all** CSS on the page.

### Cascade Effect

| Scenario | Winner | Why |
|----------|--------|-----|
| app vs component | app | `app` > `components` |
| app vs utility | utility | `utilities` > `app` |
| component vs utility | utility | `utilities` > `components` |
| any layered vs unlayered | unlayered | Unlayered always wins |

Layout utilities naturally override lower layers — no `!important` needed. **`!important` is banned.**

## Core: Naming Convention (Universal)

### BEM: block\_\_element only, NO --modifier

| Layer | Pattern | Example |
|-------|---------|---------|
| Layout | `l-{context}-{pattern}` | `l-profile-stack`, `l-grid-2col` |
| Component | `c-{component}__element` | `c-button`, `c-card__title` |
| App | `{module}-{semantic}__element` | `point-summary__value` |

Module namespace prefixes (`point-*`, `skin-*`, `cart-*`) prevent collisions.

### `data-*` for Variants & States

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `data-slot` | Debug anchor | `data-slot="card-title"` |
| `data-variant` | Visual variant | `data-variant="outline"` |
| `data-size` | Size variant | `data-size="lg"` |
| `data-state` | Interaction state | `data-state="loading"` |
| `data-{semantic}` | Domain state | `data-sign="plus"` |

```css
.c-button { /* base */ }
.c-button[data-variant='outline'] { /* variant */ }
.c-button[data-size='sm'] { /* size */ }
.c-button[data-disabled] { /* state */ }
```

## Core: Skin vs Layout Boundary (Universal)

**The most important rule — skin in CSS, layout flows freely.**

| Category | Properties | Where |
|----------|-----------|-------|
| **Skin** (must be in CSS) | `background`, `color`, `border-color`, `border-radius`, `box-shadow`, `outline` | `@layer components` or `@layer app` |
| **Layout** (can use utilities) | `width`, `height`, `margin`, `padding`, `flex`, `grid`, `gap`, `position`, `display`, `font-size`, `text-align` | CSS or markup utilities |

## Quick Reference

| Question | Answer |
|----------|--------|
| Where do skin styles go? | CSS file, in `@layer` or unlayered (see Legacy Coexistence) |
| How to express variants? | `data-*` attributes + CSS selectors |
| Can I use `--modifier` in BEM? | No. Use `data-*` instead |
| Can I mix utilities with semantic class? | No. Semantic class = all styles in CSS |
| Can app CSS override `c-*` skin? | No. Use component props/variants |
| Can I use `!important`? | No. Fix layer order instead |

## Review Checklist

- [ ] `@layer` declarations in CSS entry file (or source-order if legacy coexistence)
- [ ] Component CSS in `@layer components`, app CSS in `@layer app` (or unlayered if legacy page)
- [ ] BEM `block__element` only, no `--modifier`
- [ ] All variants/states use `data-*`
- [ ] No skin utilities in app-layer markup
- [ ] Semantic classes not mixed with utilities
- [ ] App CSS does not override `c-*` skin
- [ ] No `!important`, no hardcoded colors/radii
