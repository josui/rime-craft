# 常见场景速查

> 按场景快速定位首选模板和必填字段。Bing 工作背景里的高频场景优先列出。

| 场景 | 模板 | 必填字段 |
|------|------|----------|
| 医疗产品营销海报 | A | In-image text（日文 verbatim）+ Subject + Aspect 3:4 |
| 日文 UI mockup | A | Style（UI design mockup / Figma-style）+ In-image text + Aspect 9:19.5 |
| 概念示意图 / infographic | A | Style（flat illustration / isometric）+ Composition |
| 产品摄影 / 电商主图 | A | Lighting（studio soft / natural）+ Background（solid / scene）+ Aspect 1:1 |
| 插画风 app icon | A | Style（3D rendered / hand-drawn illustration）+ Subject（单一主体）+ Background（纯色 / 渐变）+ Aspect 1:1 |
| 吉祥物 / 角色图标 | A | Style + Character design + Pose + Background（isolated / solid）+ Aspect 1:1 |
| 替换海报里的文字 | B | Change（新文案 verbatim）+ Preserve（layout / typography / color） |
| 改光线 / 改背景 | B | Change + Preserve（subject / pose / framing） |
| 翻译图中文字 | B | Change（target language verbatim）+ Preserve（font weight / size / position） |
| 产品置入场景 | C | Image 1 产品 + Image 2 场景 + Instruction 融合指令 |
| 角色一致性（同一人多图） | C | Image 1 角色参考 + Instruction（keep identical face / outfit） |
| 风格迁移 | C | Image 1 内容 + Image 2 风格 + Instruction（apply style only） |
| **Layout 变体探索**（基于现有设计稿出 N 版） | B ×N | 用户外部附原稿 + 每版独立 Change（grid / spacing / hierarchy）+ 共享 Preserve（content / brand color / typography） |
| **配色变体**（同一 layout 换配色） | B ×N | 用户外部附原稿 + 共享 Preserve（layout / typography / content）+ 每版 Change（palette + mood keyword） |
| **风格变体**（同一内容换视觉语言） | B ×N 或 A ×N | 每版 Style 字段差异化（flat / skeuomorphic / editorial / brutalist / bento）+ Composition 保持一致；若有原稿用 B，从零出用 A |

## 医疗场景常用约束片段

复用片段，可直接嵌入 prompt：

- **日文 verbatim 锁字**：`"{文案}" in Japanese — render verbatim, no substitutions, no transliteration.`
- **合规约束**：`No real drug brand names, no real hospital logos, no identifiable patient faces unless provided as reference.`
- **色彩安全**：`Avoid pure red/green color coding for medical data (accessibility — colorblind-safe palette).`

## UI mockup 常用片段

- **禁用伪 logo**：`No fake brand logos, no Lorem Ipsum, no placeholder gibberish text.`
- **设备帧**：`iPhone 15 Pro portrait frame with status bar showing 9:41, full battery, Wi-Fi.`
- **扁平化**：`Flat vector UI, no skeuomorphic textures, no drop shadows on the screen content itself.`
