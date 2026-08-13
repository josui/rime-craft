---
name: rime-imagen
description: Use when the user explicitly asks for help writing an image-generation prompt to be pasted into an external tool (ChatGPT Web / Gemini / AI Studio). Triggers (English: "help me write an image-gen prompt", "give me a gpt-image / nano banana prompt", "write an image prompt I'll use in ChatGPT"; Chinese: "帮我写个生图 prompt", "给我一段 gpt-image prompt", "写段 prompt 我去 ChatGPT 用"). Produces copy-ready prompt text only — for actual image rendering, route to a proper image-generation tool.
---

# rime-imagen — 生图 Prompt 辅助

专门**写**高质量的生图 prompt 文本，让用户复制到 Web ChatGPT / Gemini / AI Studio 等外部工具里使用。**不调用任何生图 API，不生成图片，纯 prompt 文本产出。**

## Use when

**核心判定**：用户要的是**一段可复制的 prompt 文本**（去外部工具用），不是一张图片。满足以下之一才触发：

- 用户**明示要 prompt**：
  - "帮我写个生图 prompt / image prompt"
  - "给我一段 gpt-image / nano banana / gemini image prompt"
  - "写段 prompt 我去 ChatGPT / AI Studio 用"
- 用户已经在外部工具里卡住，找回来问怎么写 prompt（"我在 ChatGPT 里生图效果不好，帮我改 prompt"）
- 当前对话环境没有可用的生图工具，用户想手写 prompt 去别处用

### 不确定时必须问一次

用户说"生成一张图 / 做个海报 / 画个 mockup / 需要插图"**本身不足以触发本 skill** —— 这些说法的自然解读是"我要一张图片"，不是"我要一段 prompt"。此时先判断用户要的是**渲染出的图片**还是**可复制的 prompt 文本**，必要时问一次确认（e.g. "你要的是我帮你直接生成图（调生图工具），还是写一段 prompt 让你复制到 ChatGPT / Gemini 用？"）。

- 前者 → 路由到生图工具 / 生图 skill
- 后者 → 本 skill

### 满足核心判定后的具体子场景

| 子场景 | 对应模板 |
|--------|----------|
| 从零写一段 prompt（海报 / mockup / 插图 / 图标 / 概念艺术） | A |
| 写编辑现有图的 prompt（替换元素 / 改光线 / 改文字） | B |
| 写多参考图合成 prompt（产品置入 / 角色一致性 / 风格迁移） | C |
| 基于现有设计稿写 N 版 layout / 配色 / 风格变体 prompt（评审 / moodboard / PRD 插图） | B×N（或 C×N） |

### 跟代码类 skill 的边界

| 用户想要 | 走哪个 skill |
|----------|--------------|
| prompt 文本（粘到外部工具生图） | **rime-imagen**（本 skill）|
| 直接渲染出图片 | 生图工具 / 生图 skill（不是本 skill）|
| 改 React / CSS 实现新 layout | the corresponding impeccable toolchain command |
| 系统化规划整体 UX 方向（讨论层） | the corresponding impeccable toolchain command |
| 从参考站提取 design token | `rime-scan` |

## Don't use when

- 用户只是讨论图像内容或分析现有图（用正常对话回答）
- 用户做设计评审、UI 评论（用 `rime-design` / impeccable's critique flow）
- 用户聊图像相关的技术话题（模型架构、diffusion 原理等）
- **代码库图标需求** — Heroicons / Lucide / Tabler / Font Awesome 等，直接用前端组件库
- **真实数据图表** — 柱状图 / 折线图 / 饼图等数据可视化，用 Recharts / D3 / Chart.js 实现
- 纯 SVG 矢量路径绘制（几何图形 / logo 线稿），AI 生图控制不了精确坐标

## 图标类需求的判断

| 需求类型 | 是否走 rime-imagen |
|----------|---------------------|
| 插画风 app icon（手绘感 / 渲染感） | ✅ 走 |
| 吉祥物 / 角色图标 | ✅ 走 |
| 营销素材里的装饰性图标 | ✅ 走 |
| 拟物化 / 3D icon（iOS 拟物风） | ✅ 走 |
| 线性图标 / 扁平图标（用在 UI 工具栏） | ❌ 用图标库 |
| 品牌 logo 精确复刻 | ❌ 用 SVG / Figma |

## Produces

- 1 段可直接复制的生图 prompt，**放在代码块里**（默认单版本，匹配用户指定的模型风格）
- 仅当用户显式要求"两个都要 / 双版本" → 再给 gpt-image-2 + Nano Banana 两个代码块
- 代码块之后 1–2 句说明关键 prompt 技巧的选择理由
- 最后一句迭代提示，指明可以调哪个字段重新生成

---

## 执行流程（渐进式披露 — parse before ask）

**核心原则**：每一个追问项都是"**消息里缺失才问**"。不得重复问用户已经说过的东西，也不得机械地走完问卷。

### Step 1 — 信号提取（必做，先于任何追问）

收到消息后，先从字面扫描下面 5 个信号。**全部扫过一遍再决定要不要追问。**

| 信号 | 识别关键词（示例） |
|------|--------------------|
| **任务类型** | "生成 / 做张 / 画 / 来张" → A｜"改 / 替换 / 保留" → B｜"合成 / 参考图 / 放进" → C |
| **目标模型** | "gpt / chatgpt / openai / gpt-image" → gpt-image-2｜"nano banana / gemini / ai studio" → Nano Banana Pro｜没提 → 未定 |
| **主体 / 场景** | 用户已给出的任何具体描述 |
| **图内文字** | 消息里带引号的文字 / "图上写 X" / "标题是 X" |
| **尺寸 / 用途** | "海报 / 封面 / banner / 竖版 / 9:16" 等 |

Bing 的工作背景常涉及 **医疗产品、日文界面、UI mockup、概念示意图、产品海报** — 不确定时按这个场景假设，不要多问。

### Step 2 — 按模板校验完整性（不是粗粒度早退）

信号提取完成后，**按识别到的任务类型**逐项核对对应模板的必填字段。**任意必填缺失 → 进 Step 3 追问；全部齐全才跳 Step 4**。

<readiness_gate>

**任务类型 A — 从零生成**（必填）
- 目标模型（gpt-image-2 / Nano Banana Pro）
- Subject（主体是谁 / 是什么）
- Scene（环境 / 背景）
- Composition（镜头角度 / 景别）
- Lighting（光源 / 色温 / 情绪）
- Style（摄影镜头规格 / 插画风格 / 渲染引擎）
- Aspect ratio
- In-image text 精确文案 **仅当场景暗示有文字时**必填（海报 / UI mockup / 营销素材 默认有文字）

**任务类型 B — 编辑现有图**（必填）
- 目标模型
- 参考图（用户需在外部工具里附上原图）
- Change（明确要改什么）
- Preserve（明确要保留什么 —— 必须列出 face / pose / lighting / background / text / layout 等）

**任务类型 C — 多参考图合成**（必填）
- 目标模型
- 每张参考图的 role 标签（Image 1 / Image 2 / ...）
- Instruction（显式引用标签 + 合成逻辑）
- 每张图的 Preserve 约束

</readiness_gate>

**不要用"任务类型 + 主体 + 目标模型"三字段做早退判断** —— 过去版本这么写是错的。那三项只够进 Step 3 起点，不够直接出 prompt，容易产生字段缺失的半成品。

### Step 3 — 按需追问（**只问缺失项**，优先级从高到低）

> **反模式**：用户说"用 gpt 帮我写一段医疗海报生图 prompt"时，不要再问"用什么模型 / 什么任务类型" — 这两项已明确。直接追问剩余必填项（Composition / 精确文案 / aspect ratio 等）。

**1. 任务类型**（仅当 Step 1 未识别到 A/B/C 信号时问）

**2. 目标模型**（仅当 Step 1 未识别到模型信号时问）

询问方式：先问一次"给哪个工具用？gpt-image / nano banana / 都要"，不要默认产出双版本。默认双输出会翻倍无用文本。

**3. 模板必填字段**（按 Step 2 `readiness_gate` 对应类型，只问缺失的那几项）

**4. 图内文字**（仅当场景暗示有文字但用户未给出精确文案时问）

- 精确文案（**必须用引号包裹**）
- 语言（中 / 日 / 英 / 韩，多语言分开标注）
- 字体风格、字重、颜色、位置

**5. 尺寸 / 用途**（仅当 A 场景且消息未提 aspect ratio 时问）

| 用途 | aspect ratio |
|------|--------------|
| 社交媒体竖版 / 短视频封面 | 9:16 |
| 横版 banner / 视频封面 | 16:9 |
| IG post / 头像 | 1:1 |
| 海报 | 3:4 / 2:3 |
| 打印物料 | A4 / 4:5 |

**追问时一次最多 2–3 个关键项**，避免问卷感。能从上下文推断的绝不问。

### Step 4 — 产出

按收集到的信息填入下面模板，放进代码块。

<output_format>
- 用户指定了单一模型 → **只产出该模型对应风格的一个版本**
- 用户显式要求"两个都要 / 双版本 / 都给我" → 才输出 gpt-image-2 风格 + Nano Banana 风格两个代码块
- **用户要求 N 版 layout / 配色 / 风格变体** → 产出 N 个代码块，每个代码块前用 `### Variant 1 — {该版要点}` 标题区分。用户会在外部工具里**附上同一张原稿**（prompt 文本里不需要复述原图），所有变体**共享同一份 Preserve 清单**（保持原稿哪些不变），只在 **Change** 字段差异化（如 grid / spacing / color palette / style keyword）
- 代码块用 triple backtick 包裹，方便用户复制
- 代码块之后 1–2 句技巧说明 + 1 句迭代提示（见"产出后的收尾"）
</output_format>

**产出前**：先读取 `reference/model-styles.md` 里**对应模型的一节**（只读一节，不要都读），照其风格格式填写。不确定场景可参考 `reference/scenarios.md` 找首选模板和必填字段。

---

## Prompt 模板

下面三个模板是**逐字参照的骨架**，填值时不得删字段、不得改顺序。

<template name="A-from-scratch">
[Scene / Background: 环境描述，具体地点和氛围]
[Subject: 主体是谁 / 是什么，具体特征]
[Composition: 镜头角度 / 景别 / 画面距离]
[Lighting: 光源方向 / 色温 / 情绪]
[Style / Medium: 摄影镜头规格 / 插画风格 / 渲染引擎]
[In-image text: "exact text" in [language], [font/weight/color/position], verbatim — no substitutions]
[Constraints: no watermark, no logo drift, no extra elements]
[Aspect ratio: 16:9 / 1:1 / 9:16 / etc.]
</template>

<template name="B-edit-existing">
Change: [明确要改什么，越具体越好]
Preserve: [face, identity, pose, lighting, framing, background, text, layout — 所有要保留的都列出来]
Constraints: [no extra objects, no redesign, no watermark]
</template>

**关键**：编辑场景中 **Preserve 永远比 Change 重要**。漏掉 Preserve 模型会自由发挥。

<template name="C-multi-reference-compose">
Image 1: [role — 例如：base scene to preserve]
Image 2: [role — 例如：product reference]
Image 3: [role — 例如：color palette reference]
Instruction: [显式引用上面的标签，描述它们如何组合]
Constraints: [每张参考图里哪些部分不能变]
</template>

---

## 模型风格差异

- **gpt-image-2**：结构化段落 + constraints 清单化
- **Nano Banana Pro**：自然叙事 + 五要素融合

完整对照示例和用例库 → [reference/model-styles.md](reference/model-styles.md)（按需只读对应模型那一节）

---

## 反模式（产出时必须避免）

<anti_patterns>

以下是**禁区**，产出 prompt 时不得出现。每一条都是从真实失败案例里抽出来的。

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-------------|
| "premium feel", "viral quality", "atmospheric", "high quality", "masterpiece" | 用具体的镜头 / 光线 / 风格词：`50mm lens, backlit, documentary photography` |
| tag soup：`woman, hospital, morning, warm, photo, 4k, trending` | 完整句子或结构化段落 |
| 图内文字不加引号、不写 verbatim | `"健康診断のご案内" ... verbatim, no substitutions` |
| 编辑场景只说 Change 不说 Preserve | 把 face / pose / lighting / background / text / layout 全列进 Preserve |
| 跳过 Composition / Lighting / 视角 | 五要素（Scene / Subject / Composition / Lighting / Style）至少齐全 |
| 多参考图不打标签 | `Image 1 / Image 2 / Image 3` 显式引用 |

</anti_patterns>

---

## 产出后的收尾

每次产出结束后附上：

1. **技巧说明**（1–2 句）— 解释关键选择，例如：
   > "这里用 verbatim 锁死日文文案，避免 Gemini 把汉字替换成相似字形。"
   > "用 Preserve 列出 face + pose，防止模型在换背景时改动人物。"

2. **迭代提示**（1 句）— 指出可调字段：
   > "如果首次效果不满意，优先调 [Lighting] 或 [Composition] 后重新生成。"

---

## 速查与场景库

常见场景 → 首选模板 + 必填字段 + 医疗/UI mockup 常用片段 → [reference/scenarios.md](reference/scenarios.md)

仅在匹配场景不确定、需要找参考片段时读取。熟悉场景直接走 Step 1–4 流程。
