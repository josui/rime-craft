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

在 UI 相关开发过程中，持续观察以下信号。
发现时用一句话建议：「注意到 [信号]，要不要考虑使用 /[skill]？」

用户同意则调用，不同意则继续。不要反复提醒同一个信号。

| 信号 | 建议 Skill | 未安装时的 Fallback |
|------|-----------|-------------------|
| 编码前需要 UX/UI 规划 | /shape | 手动列出用户场景和设计方向 |
| 构建新 UI 页面/组件（完整流程） | /shape → /impeccable craft | /impeccable 或 /frontend-design |
| 构建新 UI 页面/组件（快速） | /impeccable 或 /frontend-design | baseline 全量 + 上下文 |
| 3+ 处相似组件实现 | /impeccable extract | 手动提取提示 |
| 元素间距混乱、视觉节奏不统一 | /layout | baseline spacing-scale 规则 |
| 排版层级混乱、字体选择不当 | /typeset | baseline typography-hierarchy 规则 |
| 色彩策略薄弱、界面色调单调 | /colorize | baseline 色彩底线规则 |
| 错误提示/标签/空状态文案含糊 | /clarify | 直接改善 |
| 功能完成但界面元素过多 | /distill | 直接精简建议 |
| 新用户首次进入/空数据状态 | /harden | 直接设计空状态 |
| 界面功能 OK 但缺乏个性 | /delight | 跳过 |
| 设计太安全/平淡 | /bolder | 跳过 |
| 设计太吵/视觉过载 | /quieter | 跳过 |
| 准备发布前最后一遍 | /polish | baseline 检查 |
| 需要跨端/跨屏适配 | /adapt | 直接处理 |
| 长文本溢出/i18n/边缘数据 | /harden | baseline 健壮性规则 |
| 加载慢/动画卡顿/bundle 大 | /optimize | 直接处理 |
| 偏离项目设计系统 | /polish | baseline 锚定类规则 |
| 需要全面质量检查 | /audit 或 /critique | baseline 全量检查 |
| 动画实现需要 review | /emil-design-eng | baseline motion 规则 |

详细路由映射 → [routing.md](routing.md)
上下文模板 → [context-template.md](context-template.md)
