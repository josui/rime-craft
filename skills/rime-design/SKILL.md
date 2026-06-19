---
name: rime-design
description: >
  Use when building, reviewing, or modifying UI/frontend interfaces.
  Covers design token anchoring, AI slop prevention, motion decisions,
  and routing to specialized design skills when available.
  Applies to any frontend project.
---

# Design Skill — UI 品质守护

三件事：**路由**（外部 design skill 指针）、**token 定义**（DESIGN.md 加载与生成）、**设计检测**（baseline rules + AI slop 防御）。

---

## 路由

### 外部 Skill

| 来源 | 安装方式 | 定位 | 何时用 |
|------|---------|------|--------|
| frontend-design | Claude Code 内置 | **设计哲学**（从 0 到 1）：像设计总监，给项目不可错认的视觉身份。关注 aesthetic direction、typography pairing、signature element、copywriting。无命令、无 detector | 新项目定设计方向、hero 设计、字体配对、视觉风险决策 |
| impeccable | `npx impeccable install` | **工具链**（从 1 到 production）：23 命令 + 44 deterministic detector rules + hook 自动检测 + live browser iteration + DESIGN.md 生成 | 设计检测、迭代打磨、a11y/perf audit、生产化 |
| emil-design-eng | 独立安装 | 动效哲学：Emil Kowalski 动效决策 + 实现 review | 动效方向决策、实现需要 review |
| transitions-dev | 独立安装（Jakub Antalík / transitions.dev） | 动效实现库：常见 UI 模式的 production-ready CSS 过渡 recipe（dropdown / modal / tabs / toast / skeleton / icon swap / staggered reveal / shake 等），copy-paste 即用 | 需要具体过渡 / 微交互的现成实现 |
| gsap（`gsap-core` 入口 + `gsap-*` 系） | 独立安装 | JS 动画库：timeline 编排、scroll-driven（ScrollTrigger）、SVG / 物理 / 复杂序列；按需 `gsap-scrolltrigger` / `gsap-timeline` / `gsap-react` / `gsap-plugins` | CSS 过渡不够用——复杂编排 / 滚动驱动 / SVG / 时间轴 |
| text-to-lottie | 独立安装 | 矢量动画：生成 Lottie (Bodymovin) JSON，本地 skia 播放 | 插画级 / 装饰性矢量动画 |
| shadcn | 独立安装 | shadcn/ui 组件管理 | shadcn 项目 |

> **frontend-design 与 impeccable 的关系**：前者是思维方法（"怎么想、怎么定方向"），后者是工具链（"怎么检测、怎么迭代"）。两者可共存——frontend-design 定方向，impeccable 检测和打磨。impeccable 自述"started from frontend-design"，但在命令系统、detector、DESIGN.md 生成上远超官方版。
>
> **动效工具怎么选**（方向永远先问 `emil-design-eng`：该不该动、怎么动、动得对不对）：
> - 简单 UI 过渡 / 微交互（dropdown / modal / toast / tabs / skeleton…）→ `transitions-dev`（现成 CSS recipe）
> - 复杂编排 / 滚动驱动 / SVG / 时间轴 → `gsap`（`gsap-core` 入口，按需 `gsap-scrolltrigger` / `gsap-timeline` / `gsap-react`）
> - 矢量插画 / 装饰性动画 → `text-to-lottie`（生成 Lottie JSON）

### 检测逻辑

AI 无法在运行时动态检测已安装的 skill 列表。采用「尝试调用 → 失败则 fallback」策略：

- 建议使用某 skill 时，直接尝试调用
- skill 不存在时 Claude 会报错，此时执行 fallback（下方设计检测 baseline）
- 一次 session 内记住哪些 skill 不可用，不重复尝试

### 设计嗅觉 — 开发过程中主动提示

在 UI 相关开发过程中，持续观察设计信号（间距混乱、文案含糊、缺乏个性、视觉过载等）。

**装了 impeccable 时**：impeccable 自带 routing rules（意图→命令映射 + context-signals 脚本驱动），让 impeccable 处理路由。rime-design 不重复维护命令映射表——impeccable 自己的注册表是单一来源，抄一遍只会过期。

**未装 impeccable 时**：发现设计信号用一句话建议对应改善方向（基于下方设计检测 baseline），用户同意则直接改善，不反复提醒同一信号。

---

## Token 定义

### 加载

1. 检查 `docs/DESIGN.md` 是否存在
2. **存在** → 读取 YAML frontmatter 获取 token 值（colors / typography / rounded / spacing / components），读取 prose 获取设计 rationale
3. **不存在** → 提示用户：「项目缺少 DESIGN.md，要现在生成吗？」

### 生成

用户同意后，优先用外部命令；不可用则手动扫描：

| 方式 | 说明 |
|------|------|
| `/impeccable init` | 交互式采集设计上下文，自动写 PRODUCT.md + DESIGN.md |
| `/impeccable document` | 从现有项目代码自动生成 DESIGN.md |
| 手动扫描 | 扫描项目（CSS 变量、Tailwind config、theme 文件、组件源码等）提取实际 token 值 → 用 `design-template.md` 模板生成 `docs/DESIGN.md` → 用户确认 → 如有 `npx @google/design.md lint` 可用则运行验证 |
| 从参考网站提取 | 使用 `rime-scan` skill 提取 scan JSON，需要时转化为 `DESIGN.md` |

> DESIGN.md 采用 [google-labs/design.md](https://github.com/google-labs-code/design.md) 格式（Apache-2.0）。模板见 [design-template.md](design-template.md)。

### 锚定类规则 — 遵循项目定义

读取 token 后，以下规则始终适用：

| Rule | Description |
|------|-------------|
| **token-first** | 禁止硬编码颜色/间距/字号值，必须使用项目 tokens |
| **component-reuse** | 项目已有的组件必须优先使用，不重造 |
| **spacing-scale** | 遵循项目间距体系，不用任意值 |
| **typography-hierarchy** | 遵循已定义的字体层级，不自创大小/粗细组合 |
| **color-palette** | 只用色板中的颜色，需要新色时先确认 |
| **responsive-breakpoints** | 遵循项目断点体系，不自创断点 |

---

## 设计检测

以下规则始终适用，不依赖外部 skill。装了 impeccable 时，impeccable 自带更详细的同类规则（44 deterministic detector rules + absolute bans），以 impeccable 为准；未装时以下为 fallback。

### AI Slop 防御

避免以下模式——装了 impeccable 时其 detector 会自动检测，未装时人工对照：

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

> 实现动效时按上方「动效工具怎么选」route 到对应 skill（CSS 过渡 → transitions-dev / 复杂编排 → gsap / 矢量 → text-to-lottie / 决策与 review → emil-design-eng）。以下为无外部 skill 时的 baseline。

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
