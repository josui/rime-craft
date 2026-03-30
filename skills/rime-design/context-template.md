# Design Context Template

本模板用于生成 `docs/design-context.md`。
在 `rime-init` 初始化时或 `rime-design` 首次触发时，AI 扫描项目自动填充路径。

## 生成步骤

1. 扫描项目（CSS 文件、Tailwind config、组件目录等）
2. 将路径填入下方模板
3. 用户确认后写入 `docs/design-context.md`

## 模板

---

# Design Context

项目的 design token 和组件约定索引。
rime-design 加载时读取此文件，按路径获取最新的实际定义。

## Tokens

| 类型 | 源文件 | 说明 |
|------|--------|------|
| 色彩 | — | — |
| 间距 | — | — |
| 字体 | — | — |
| 断点 | — | — |
| 圆角/阴影 | — | — |

## 组件约定

| 类型 | 路径 | 说明 |
|------|------|------|
| 基础组件 | — | — |
| 布局组件 | — | — |
| 图标 | — | — |

## 设计方向（可选）

> 由用户或 /teach-impeccable 填写。
> 不写也不影响 baseline 规则生效。

- 受众：
- 品牌调性：
- 美学方向：
