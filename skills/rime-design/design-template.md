# DESIGN.md Template

本模板用于生成 `docs/DESIGN.md`（[google-labs/design.md](https://github.com/google-labs-code/design.md) 格式，Apache-2.0 License）。
在 `rime-init` 初始化时或 `rime-design` 首次触发时，AI 扫描项目自动提取 token 值。

## 生成步骤

1. 扫描项目（CSS 变量、Tailwind config、theme 文件、组件源码等），提取实际 token 值（颜色、字体、间距、圆角等）
2. 将值填入下方 YAML frontmatter，同时撰写各 section 的 prose rationale
3. 用户确认后写入 `docs/DESIGN.md`
4. 如有 `npx @google/design.md lint` 可用，运行验证

## 模板

---

```yaml
---
version: alpha
name: <project name>
description: <one-line description>
colors:
  primary: "#______"
  secondary: "#______"
  tertiary: "#______"
  neutral: "#______"
  # 语义色按需追加：on-primary, primary-container, surface, on-surface, error, outline 等
typography:
  h1:
    fontFamily: <font>
    fontSize: 48px
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: -0.02em
  body-md:
    fontFamily: <font>
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
  label-md:
    fontFamily: <font>
    fontSize: 14px
    fontWeight: 600
    lineHeight: 20px
    letterSpacing: 0.01em
rounded:
  sm: 4px
  md: 8px
  lg: 12px
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 32px
  xl: 64px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  button-primary-hover:
    backgroundColor: "{colors.primary-container}"
  # 按需追加组件变体
---
```

## Overview

> 品牌个性、目标受众、UI 应唤起的情感。一句话定调。

## Colors

> 色板理念 + 每个 semantic color 的用途说明。

- **Primary (#______):** —
- **Secondary (#______):** —
- **Tertiary (#______):** —
- **Neutral (#______):** —

## Typography

> 字体策略 + 各层级角色。

- **Headlines:** —
- **Body:** —
- **Labels:** —

## Layout & Spacing

> 布局模型（grid / fluid / fixed-max-width）+ 间距体系。

## Elevation & Depth

> 深度表达方式（shadow / tonal layers / borders）。

## Shapes

> 圆角语言 + 各类元素的圆角约定。

## Components

> 关键组件的样式指引（buttons, cards, inputs 等）。

## Do's and Don'ts

- Do —
- Don't —

---

## 设计方向（可选，不写入 DESIGN.md）

> 项目设计方向由用户填写，**不写入 DESIGN.md 正文**（DESIGN.md 是 token + rationale 的自包含文件）。
> 如需记录，可写入 AGENTS.md 的验证 / 偏好区，或单独建 `docs/design-direction.md`。
> 不写也不影响 baseline 规则生效。

- 受众：
- 品牌调性：
- 美学方向：
