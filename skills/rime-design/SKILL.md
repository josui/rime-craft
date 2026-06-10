---
name: rime-design
description: >
  Use when building, reviewing, or modifying UI/frontend interfaces.
  Covers design token anchoring, AI slop prevention, motion decisions,
  and routing to specialized design skills when available.
  Applies to any frontend project.
---

# Design Skill — UI 品质与 Token 一致性

UI/前端开发时的设计品质守护。内嵌 baseline 规则 + 外部 design skill 场景化路由。

---

## Baseline Rules

以下规则始终适用，不依赖外部 skill。

### 锚定类 — 遵循项目定义

| Rule | Description |
|------|-------------|
| **token-first** | 禁止硬编码颜色/间距/字号值，必须使用项目 tokens |
| **component-reuse** | 项目已有的组件必须优先使用，不重造 |
| **spacing-scale** | 遵循项目间距体系，不用任意值 |
| **typography-hierarchy** | 遵循已定义的字体层级，不自创大小/粗细组合 |
| **color-palette** | 只用色板中的颜色，需要新色时先确认 |
| **responsive-breakpoints** | 遵循项目断点体系，不自创断点 |

**适用方式**: `docs/design-context.md` 存在时，按索引路径读取源文件。不存在时，在项目中搜索 token 定义。

### AI Slop 防御 — 避免以下模式

- 不用 cyan/purple 渐变、glassmorphism、neon accent
- 不用 gradient text、bounce/elastic easing
- 不用 identical card grids、hero metric layout
- 不用 Inter/Roboto/Arial 等默认字体
- 不套 rounded rectangle + thick colored border
- 不在深色背景上加 glowing accent
- 不用 sparklines 作装饰
- 不嵌套 card in card
- 不把所有元素居中
- 不给每个 heading 上方放大圆角 icon

### Motion Base — 动画决策框架

1. 先判断是否需要动画（高频操作 100+/天 → 不动画）
2. 只动画 `transform` + `opacity`（GPU 加速），不动画 layout 属性
3. Easing: enter/exit → `ease-out`, 移动 → `ease-in-out`, hover → `ease`
4. UI 交互时长上限 300ms，不用 bounce/elastic
5. 尊重 `prefers-reduced-motion`

### 色彩底线

- 不在彩色背景上放灰色文字 — 用背景色的深色变体或透明度
- 不用纯黑/纯白 — 所有中性色向品牌色微调
- OKLCH 优先（感知均匀）

### 健壮性底线

- 长文本 overflow 处理（`overflow-wrap: anywhere`）
- 空状态必须有引导（不留空白页面）
- 响应 `prefers-reduced-motion` / `prefers-color-scheme`

---

## 设计上下文加载

Skill 加载时:

1. 检查 `docs/design-context.md` 是否存在
2. **存在** → 读取索引，按路径读取源文件（token 定义、组件目录等）
3. **不存在** → 提示用户：「项目缺少设计上下文索引，要现在扫描生成吗？」
4. 用户同意 → 扫描项目（CSS 文件、Tailwind config、组件目录等）自动填充路径 → 用 `context-template.md` 模板生成 `docs/design-context.md` → 用户确认

---

## 设计嗅觉 — 开发过程中主动提示

在 UI 相关开发过程中，持续观察设计信号（间距混乱、文案含糊、缺乏个性、视觉过载等）。
发现时查 [routing.md](routing.md) 的**设计嗅觉表**，用一句话建议：「注意到 [信号]，要不要考虑使用 /[skill]？」

用户同意则调用，不同意则继续。不要反复提醒同一个信号。skill 未安装时按嗅觉表的 fallback 列处理。

嗅觉表与外部 skill 注册表统一维护在 [routing.md](routing.md)（单一来源）。
上下文模板 → [context-template.md](context-template.md)
