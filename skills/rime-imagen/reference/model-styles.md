# 模型风格差异与完整示例

> SKILL.md 的 Step 4 产出阶段按需读取本文件：已确定模型后，**只读对应的一节**，不要两节都读。

---

## gpt-image-2（ChatGPT Web / OpenAI API）

### 风格特征

- **结构化段落** — 每个要素独立一行或一句，前置标签
- **constraints 清单化** — `Constraints: No A, no B, no C.`
- **显式 aspect ratio** — 放在段末
- 模型擅长：摄影级真实感、文字渲染（英文 > 日文 > 中文）、精准构图

### 完整示例 — 医疗产品海报

<example model="gpt-image-2" scenario="medical-poster">
Scene: A quiet hospital waiting room at dawn, soft light through blinds.
Subject: An elderly Japanese woman holding a health check-up card, wearing a beige cardigan.
Composition: Medium shot, eye level, slightly off-center to the right.
Lighting: Warm morning light from the left, gentle shadows.
Style: Documentary photography, 50mm lens, shallow depth of field.
In-image text: "健康診断のご案内" in Japanese, bold sans-serif, dark navy, upper-left corner — verbatim, no substitutions.
Constraints: No logo, no watermark, no additional people.
Aspect ratio: 3:4.
</example>

### 完整示例 — UI mockup

<example model="gpt-image-2" scenario="ui-mockup">
Scene: A Figma-style UI mockup on a neutral gray canvas.
Subject: A mobile health app dashboard screen for elderly users, iOS 17 style.
Composition: Single phone frame centered, shown at 1:1 device scale.
Lighting: Flat, uniform studio light — no shadows on the screen content.
Style: UI design mockup, clean vector interface, Figma export aesthetic.
In-image text: Navigation title "ホーム" in Japanese, 17pt SF Pro semibold, black — verbatim, no substitutions. Primary button label "今日の記録を追加" in Japanese, 16pt medium, white on blue — verbatim.
Constraints: No device hardware UI chrome drift, no fake brand logos, no Lorem Ipsum.
Aspect ratio: 9:19.5 (iPhone portrait).
</example>

### 编辑场景示例（Change / Preserve）

<example model="gpt-image-2" scenario="edit-change-preserve">
Change: Replace the poster title with "健康診断キャンペーン 2026" in the same font and weight as the original title.
Preserve: Face, pose, expression, cardigan, hand position, card design, lighting, background blur, all other text on the card, overall composition and aspect ratio.
Constraints: No new objects, no color shift, no watermark, no style change.
</example>

---

## Nano Banana Pro（Gemini 3 Pro Image / AI Studio）

### 风格特征

- **自然叙事** — 用完整英文句子描述画面，像在写分镜本
- **五要素融合** — Subject / Scene / Composition / Lighting / Style 揉进同一段
- **verbatim 锁字** — 日韩中文字必须引号 + `render verbatim, no substitutions`
- 模型擅长：多参考图合成、角色一致性、插画/概念艺术、长文本渲染

### 完整示例 — 医疗产品海报（对应 gpt-image-2 的同一需求）

<example model="nano-banana-pro" scenario="medical-poster">
A documentary-style photograph of an elderly Japanese woman holding a health check-up card in a quiet hospital waiting room at dawn. Warm morning light filters through the blinds from the left, casting gentle shadows across her beige cardigan. Shot on a 50mm lens with shallow depth of field, medium framing at eye level, she sits slightly off-center to the right. The card reads "健康診断のご案内" in bold navy Japanese sans-serif type in the upper-left corner — render this text verbatim, no substitutions. No logos, no watermarks, no additional people. 3:4 aspect ratio.
</example>

### 完整示例 — 多参考图合成

<example model="nano-banana-pro" scenario="multi-reference-compose">
Using three reference images: Image 1 shows the product — a white ceramic blood pressure monitor with a blue display. Image 2 shows the target scene — a sunlit Japanese kitchen counter with a small potted plant. Image 3 shows the mood palette — soft pastel morning tones with warm beige and sage green.

Place Image 1's blood pressure monitor naturally on the kitchen counter from Image 2, matching the lighting direction (from the window on the left) and the color grading from Image 3. Keep the monitor's exact shape, display content, and button layout identical to Image 1. The kitchen scene, counter texture, and plant from Image 2 should remain unchanged. Apply the soft pastel palette from Image 3 across the whole frame.

No additional objects, no text, no people. 1:1 aspect ratio.
</example>

### 编辑场景示例（Change / Preserve）

<example model="nano-banana-pro" scenario="edit-change-preserve">
In the provided image, change only the poster title text to "健康診断キャンペーン 2026" — render this verbatim in the same Japanese font, weight, size, color, and position as the original title. Preserve everything else exactly: the woman's face, pose, expression, cardigan, hand position, card design, all other text on the card, the lighting, background blur, and the overall composition. No new objects, no color shift, no watermark, no style change.
</example>

---

## 何时需要双版本

仅当用户显式说"两个都要 / 双版本 / 都给我看看 / compare" 时产出两个代码块。其他情况一律单版本。
