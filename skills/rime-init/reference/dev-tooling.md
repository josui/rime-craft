# Dev Toolchain Setup

Dev tool initialization flow for frontend / Node.js projects. Not applicable to non-JS/TS projects like Go or Swift.

---

## Prerequisites

Versioning principles are in AGENTS.md. Before installing, check the latest docs to confirm compatibility.

---

## Execution Steps

### 1. Confirm Project Info

Ask the user:

1. **Package manager**: pnpm / npm / yarn / bun
2. **Framework type**: React / Vue / Next.js / Node.js / plain TypeScript / other
3. **Styling approach**: Tailwind / CSS / SCSS / CSS-in-JS
4. **Optional tools**: commitlint, EditorConfig

### 2. Install Dependencies

```bash
# Base (required)
pnpm add -D prettier eslint husky lint-staged

# TypeScript ESLint (required for TypeScript projects)
pnpm add -D typescript-eslint

# Optional
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

Framework-specific dependencies are in "Framework-Specific Configuration" below.

### 3. Copy Config Files

Copy templates from the `assets/` directory to the project root:

| File | Purpose | Priority |
|------|------|--------|
| [.prettierrc](../assets/.prettierrc) | Prettier config | Required |
| [.prettierignore](../assets/.prettierignore) | Prettier ignore | Required |
| [eslint.config.js](../assets/eslint.config.js) | ESLint flat config | Required |
| [.lintstagedrc.json](../assets/.lintstagedrc.json) | lint-staged config | Required |
| [.editorconfig](../assets/.editorconfig) | Editor config | Recommended |
| [commitlint.config.js](../assets/commitlint.config.js) | commitlint config | Optional |

Adjust the ESLint config based on the framework type.

### 4. Initialize Husky

```bash
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

When commitlint is enabled, also add:

```bash
echo 'npx --no -- commitlint --edit "$1"' > .husky/commit-msg
```

### 5. Add package.json Scripts

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
```

### 6. Verify

```bash
pnpm lint
pnpm format:check
```

---

## Framework-Specific Configuration

### React + Vite

```bash
pnpm add -D eslint-plugin-react-hooks eslint-plugin-react-refresh
```

### React + WXT (Chrome Extension)

WXT projects ship with their own TypeScript config. ESLint config is the same as React, with extra notes:
- Add WXT's auto-generated files (`.wxt/`, `.output/`) to `.prettierignore` and the ESLint ignore list
- Styles inside a Content Script's Shadow DOM don't go through Stylelint

### Vue 3

```bash
pnpm add -D eslint-plugin-vue @vue/eslint-config-typescript
```

```javascript
import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import vue from 'eslint-plugin-vue'

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    rules: {
      'vue/multi-word-component-names': 'off',
    },
  }
)
```

### Next.js

```bash
pnpm add -D @next/eslint-plugin-next
```

```javascript
import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import next from '@next/eslint-plugin-next'

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    plugins: { '@next/next': next },
    rules: { ...next.configs.recommended.rules },
  }
)
```

### Node.js

```bash
pnpm add -D eslint-plugin-n
```

```javascript
import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import n from 'eslint-plugin-n'

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  n.configs['flat/recommended'],
  {
    rules: { 'n/no-missing-import': 'off' },
  }
)
```

### Plain TypeScript

No extra plugins needed — use the base `assets/eslint.config.js` config directly.

---

---

## Common Issues

| Issue | Solution |
|------|----------|
| ESLint conflicts with Prettier | Install `eslint-config-prettier` and put it last in the config |
| Husky hooks don't run | Confirm the `.husky/` directory exists and has execute permission |
| TypeScript path alias errors | Add `settings: { 'import/resolver': { typescript: {} } }` to the ESLint config |
