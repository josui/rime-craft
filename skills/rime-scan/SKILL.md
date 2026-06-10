---
name: rime-scan
description: >
  Use when extracting design language from a reference website or screenshot.
  提供 URL 时通过 agent-browser 程序化提取精确 token（颜色、
  字体、间距、组件样式）并结合 AI 视觉分析补充定性判断；提供截图时纯 AI 视觉分析（降级模式）。
  输出结构化 scan JSON，可按需转化为 design-context.md 或 HTML design sheet。
---

# rime-scan

从参考网站提取设计语言的 skill。程序化提取精确 token + AI 视觉分析定性判断，输出结构化 JSON。

## 触发场景

- 用户提供 URL，要求"扫描设计"/"提取设计语言"/"分析这个页面的设计"
- 用户提供截图，要求分析设计风格（降级为纯视觉模式）
- 用户说"参考 xxx 的设计风格"后需要系统化分析

## 两种模式

| 模式 | 输入 | 程序化提取 |
|------|------|-----------|
| **URL 模式** | 网页 URL | ✅ extract.js 注入 + 截图 + AI 视觉分析 |
| **截图模式** | 图片文件 | ❌ 纯 AI 视觉分析，`extracted` 字段为 `null` |

## 流程

### URL 模式

**Step 1 — Scope 确认**（打开页面前询问用户）

```
扫描范围确认（直接回车 = 仅基础 token）：
• 基础 token（颜色 / 字体 / 间距 / 圆角 / 阴影）— 始终提取
• button / link 样式 — 始终提取
• 表单元素（input / select / textarea）— 需要吗？[y/N]
• 导航 / 头部（nav / header）— 需要吗？[y/N]
• 重复组件 pattern（频率 ≥ 3 次的 class）— 需要吗？[y/N]
• 视觉效果（canvas / WebGL / scroll effects 等）— 需要吗？[y/N]
```

用户一次性确认后，extract.js 只运行需要的部分。**若用户原始消息中已明确提及需要的范围**（如"扫描包括表单"、"不需要视觉效果"），直接映射到对应 scope 配置，跳过确认步骤。

**Step 2 — agent-browser 打开页面**

使用 `agent-browser` skill 打开 URL，等待页面完全加载（DOMContentLoaded + load 事件，必要时等待 3-5 秒确保 JS 渲染完成）。**若页面加载失败（网络错误、bot 保护、超时）：** 告知用户原因，提议切换至截图模式（用户手动提供截图），然后停止 URL 流程。

**Step 3 — 注入 extract.js**

先用 Read tool 读取 `skills/rime-scan/scripts/extract.js` 的完整内容，然后通过 agent-browser 的 JS 执行能力将脚本注入页面，传入 scope 配置：

```js
// 根据用户 scope 选择配置 scope 对象，然后调用：
const result = rimeScanExtract({ form: true, nav: false, patterns: true, effects: false });
```

收集 `result` JSON 数据。**若 `rimeScanExtract` 未定义或抛出异常**（注入失败），以 `extracted: null` 继续执行 Step 5，并在 JSON meta 中记录 `"extractionError": "inject failed"`。

**Step 4 — 截图**

使用 agent-browser 截取 viewport 截图。

**Step 5 — AI 视觉分析**

结合截图和 Step 3 的程序化数据，补充 `analyzed` 字段：
- `style`：mood（3-5 关键词）、aesthetic、density、contrast
- `layout`：hierarchy、balance、flow、whitespace
- `components`：buttons/cards/navigation/inputs 的简短视觉描述
- `motion`：如有可观察动效则填写，否则 `null`

**Step 6 — 合并输出**

输出完整 scan JSON（参见 `schema.md`），然后显示输出后引导。

### 截图模式

Step 1 Scope 确认 → 跳过 Step 2-3 → Step 4 用用户提供的截图 → Step 5 AI 视觉分析 → Step 6 输出（`extracted: null`）

## 输出后引导

扫描完成后，统一格式输出：

```
✅ Scan 完成 — [URL or 截图]

提取结果：
• 颜色：N 个（N 背景 / N 文字 / N 强调）
• 字体族：N 个（列出名称）
• 间距值：N 个（base unit: Npx）
• UI 组件：button / link [/ input / select 等，按实际提取的列出]
• Pattern：N 个（列出 selector × count）[scope 包含 patterns 时]

你可以：
• 保存为 JSON 文件归档参考
• 让我基于这个 JSON 生成 design-context.md（rime-design 使用）
• 让我基于这个 JSON 生成可视化 HTML design sheet
• 直接开始新项目，我会参考这些 token
```

## 与 rime-design 的关系

- rime-scan 输出的 JSON 可按需转化为 `docs/design-context.md`（rime-design 的设计上下文）
- 转化不自动发生，用户明确要求时执行
- schema 参见 `schema.md`

## 不做的事

- 不自动生成 design-context.md
- 不做 Markdown 分析报告（复用性低）
- 不做多页对比（多页时多次调用）
- 不做自有项目审计（#0027 rime-design 扩展）
