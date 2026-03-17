# 开发工具链配置

前端 / Node.js 项目的开发工具初始化流程。Go、Swift 等非 JS/TS 项目不适用。

---

## 前提

版本原则见 AGENTS.md。安装前先查最新文档确认兼容性。

---

## 执行步骤

### 1. 确认项目信息

询问用户：

1. **包管理器**：pnpm / npm / yarn / bun
2. **框架类型**：React / Vue / Next.js / Node.js / 纯 TypeScript / 其他
3. **样式方案**：Tailwind / CSS / SCSS / CSS-in-JS
4. **可选工具**：commitlint、EditorConfig

### 2. 安装依赖

```bash
# 基础（必选）
pnpm add -D prettier eslint husky lint-staged

# TypeScript ESLint（TypeScript 项目必选）
pnpm add -D typescript-eslint

# 可选
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

框架特定依赖见下方"框架特定配置"。

### 3. 复制配置文件

从 `assets/` 目录复制模板到项目根目录：

| 文件 | 用途 | 优先级 |
|------|------|--------|
| [.prettierrc](../assets/.prettierrc) | Prettier 配置 | 必选 |
| [.prettierignore](../assets/.prettierignore) | Prettier 忽略 | 必选 |
| [eslint.config.js](../assets/eslint.config.js) | ESLint Flat Config | 必选 |
| [.lintstagedrc.json](../assets/.lintstagedrc.json) | lint-staged 配置 | 必选 |
| [.editorconfig](../assets/.editorconfig) | 编辑器配置 | 推荐 |
| [commitlint.config.js](../assets/commitlint.config.js) | commitlint 配置 | 可选 |

根据框架类型调整 ESLint 配置。

### 4. 初始化 Husky

```bash
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

commitlint 启用时追加：

```bash
echo 'npx --no -- commitlint --edit "$1"' > .husky/commit-msg
```

### 5. 添加 package.json scripts

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

### 6. 验证

```bash
pnpm lint
pnpm format:check
```

---

## 框架特定配置

### React + Vite

```bash
pnpm add -D eslint-plugin-react-hooks eslint-plugin-react-refresh
```

### React + WXT（Chrome 扩展）

WXT 项目自带 TypeScript 配置。ESLint 配置同 React，额外注意：
- WXT 自动生成的文件（`.wxt/`、`.output/`）加入 `.prettierignore` 和 ESLint ignore
- Content Script 的 Shadow DOM 内样式不走 Stylelint

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

### 纯 TypeScript

无需额外插件，直接使用 `assets/eslint.config.js` 基础配置。

---

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| ESLint 与 Prettier 冲突 | 安装 `eslint-config-prettier` 放在配置最后 |
| Husky hooks 不执行 | 确认 `.husky/` 目录存在且有执行权限 |
| TypeScript 路径别名报错 | ESLint 配置中添加 `settings: { 'import/resolver': { typescript: {} } }` |
