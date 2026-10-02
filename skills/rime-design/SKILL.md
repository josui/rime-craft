---
name: rime-design
description: >
  Use when building, reviewing, or modifying UI/frontend interfaces.
  Covers design token anchoring, AI slop prevention, motion decisions,
  and routing to specialized design skills when available.
  Applies to any frontend project.
---

# Design Skill — UI 品质守护

两件事：**路由**（外部 design skill 指针）、**设计检测**（baseline rules + AI slop 防御）。

---

## 路由

### 外部 Skill

| 来源 | 安装方式 | 定位 | 何时用 |
|------|---------|------|--------|
| Design（Artifact 类型） | Claude Code 内置 Artifact 工具（`action: "quickstart"`, `intent: "design"`） | 官方设计画布：在画布上产出可交互 artboard（页面 / 屏幕 / mockup / 线框），可套用账户的 Design System | 需要出 prototype / mockup / 界面原型给人看 |
| emil-design-eng | 独立安装 | 动效哲学：Emil Kowalski 动效决策 + 实现 review | 动效方向决策、实现需要 review |
| transitions-dev | 独立安装（Jakub Antalík / transitions.dev） | 动效实现库：常见 UI 模式的 production-ready CSS 过渡 recipe（dropdown / modal / tabs / toast / skeleton / icon swap / staggered reveal / shake 等），copy-paste 即用 | 需要具体过渡 / 微交互的现成实现 |
| gsap（`gsap-core` 入口 + `gsap-*` 系） | 独立安装 | JS 动画库：timeline 编排、scroll-driven（ScrollTrigger）、SVG / 物理 / 复杂序列；按需 `gsap-scrolltrigger` / `gsap-timeline` / `gsap-react` / `gsap-plugins` | CSS 过渡不够用——复杂编排 / 滚动驱动 / SVG / 时间轴 |

> 当前环境没有 Artifact 工具时，prototype 回退到 rime-flow 的本地 HTML spec。发布 artifact 后，把 URL 登记到任务的 `docs`：`{type: "prototype", name: "<可区分的名称>", path: "<artifact URL>"}`（`docs` 条目格式见 rime-flow 的 `data-contract.md`）。
>
> **动效工具怎么选**（方向永远先问 `emil-design-eng`：该不该动、怎么动、动得对不对）：
> - 简单 UI 过渡 / 微交互（dropdown / modal / toast / tabs / skeleton…）→ `transitions-dev`（现成 CSS recipe）
> - 复杂编排 / 滚动驱动 / SVG / 时间轴 → `gsap`（`gsap-core` 入口，按需 `gsap-scrolltrigger` / `gsap-timeline` / `gsap-react`）

### 检测逻辑

AI 无法在运行时动态检测已安装的 skill 列表。采用「尝试调用 → 失败则 fallback」策略：

- 建议使用某 skill 时，直接尝试调用
- skill 不存在时 Claude 会报错，此时执行 fallback（下方设计检测 baseline）
- 一次 session 内记住哪些 skill 不可用，不重复尝试

### 设计嗅觉 — 开发过程中主动提示

在 UI 相关开发过程中，持续观察设计信号（间距混乱、文案含糊、缺乏个性、视觉过载等）。

发现设计信号用一句话建议对应改善方向（基于下方设计检测 baseline），用户同意则直接改善，不反复提醒同一信号。

---

## Token 锚定

遵循项目已有的 token——CSS custom properties、Tailwind config、theme 文件、现有组件——而不是另起定义。以下规则始终适用：

| Rule | Description |
|------|-------------|
| **token-first** | 禁止硬编码颜色/间距/字号值，必须使用项目已有 tokens |
| **component-reuse** | 项目已有的组件必须优先使用，不重造 |
| **spacing-scale** | 遵循项目间距体系，不用任意值 |
| **typography-hierarchy** | 遵循已有的字体层级，不自创大小/粗细组合 |
| **color-palette** | 只用项目色板中的颜色，需要新色时先确认 |
| **responsive-breakpoints** | 遵循项目断点体系，不自创断点 |

---

## 设计检测

以下规则始终适用，不依赖外部 skill。

### AI Slop 防御

避免以下模式：

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

### Motion Base

> 实现动效时按上方「动效工具怎么选」route 到对应 skill（CSS 过渡 → transitions-dev / 复杂编排 → gsap / 决策与 review → emil-design-eng）。以下为无外部 skill 时的 baseline。

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
