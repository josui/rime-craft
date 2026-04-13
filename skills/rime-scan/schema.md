# Scan JSON Schema

rime-scan 的输出格式。`extracted` 为程序化提取的精确值，`analyzed` 为 AI 视觉分析的定性判断。
截图模式下 `extracted` 为 `null`。

## 完整结构

```jsonc
{
  "meta": {
    "url": "https://example.com",    // 截图模式为 null
    "title": "页面标题",
    "scannedAt": "2026-04-14",
    "mode": "url",                   // "url" | "screenshot"
    "scope": ["token", "ui", "form", "nav", "patterns"],  // 实际提取的范围
    "extractionError": null          // 注入失败时写入 "inject failed"，否则 null
  },

  // ── 程序化提取（精确值）── URL 模式时填写，截图模式或注入失败时为 null
  "extracted": {

    // 始终提取：基础 token
    "colors": {
      "properties": [                 // CSS custom properties 中的颜色变量
        "--color-primary: #3b82f6",
        "--color-background: #ffffff"
      ],
      "computed": {
        "backgrounds": ["#ffffff", "#f9fafb", "#f3f4f6"],  // 按出现频率排序，top 10
        "texts": ["#1a1a1a", "#6b7280", "#374151"],
        "borders": ["#e5e7eb", "#d1d5db"],
        "accents": ["#3b82f6", "#2563eb"]                   // button/link/CTA 强调色
      }
    },

    "typography": {
      "families": ["Inter", "Georgia"],           // 按使用频率排序
      "sizes": [16, 14, 24, 32, 12, 48],          // px，去重按频率排序
      "weights": [400, 500, 700],
      "lineHeights": [1.5, 1.25, 1.75]
    },

    "spacing": {
      "values": [8, 16, 24, 32, 48, 64],          // 常见 padding/margin/gap px 值，去重排序
      "baseUnit": 8                                // 推断的 base unit（最大公约数）
    },

    "layout": {
      "maxWidth": "1280px",                        // 页面最大宽度
      "breakpoints": ["768px", "1024px", "1280px"], // 从 media queries 提取
      "gridColumns": 12                             // 检测到 CSS Grid 时的列数，否则 null
    },

    "shape": {
      "borderRadius": [4, 8, 12, 16, 9999],        // px，去重排序
      "shadows": [                                   // 去重后的 box-shadow 值，top 5
        "0 1px 3px rgba(0,0,0,0.1)",
        "0 4px 6px rgba(0,0,0,0.07)"
      ]
    },

    // 始终提取：UI 组件
    "ui": {
      "button": {
        "padding": "10px 20px",
        "borderRadius": "8px",
        "background": "#3b82f6",
        "color": "#ffffff",
        "fontSize": "14px",
        "fontWeight": "500",
        "border": "none"
      },
      "link": {
        "color": "#3b82f6",
        "fontWeight": "400",
        "textDecoration": "none"
      }
    },

    // 可选：scope 包含 "form" 时提取
    // 使用视觉容器策略处理 MUI/Ant Design 等 wrapper 模式
    "form": {
      "input": {
        "padding": "10px 14px",
        "borderRadius": "6px",
        "border": "1px solid #d1d5db",
        "background": "#ffffff",
        "fontSize": "14px"
      },
      "select": {
        "padding": "10px 14px",
        "borderRadius": "6px",
        "border": "1px solid #d1d5db",
        "background": "#ffffff",
        "fontSize": "14px"
      },
      "textarea": {
        "padding": "10px 14px",
        "borderRadius": "6px",
        "border": "1px solid #d1d5db",
        "background": "#ffffff",
        "fontSize": "14px"
      }
    },

    // 可选：scope 包含 "nav" 时提取
    "navigation": {
      "background": "#ffffff",
      "borderBottom": "1px solid #e5e7eb",
      "height": "64px",
      "position": "sticky"
    },

    // 可选：scope 包含 "patterns" 时提取
    // 频率 ≥ 3 次的 class，去除 Tailwind utility class，top 5
    "patterns": [
      {
        "selector": ".product-card",
        "count": 12,
        "tag": "div",
        "styles": {
          "padding": "24px",
          "borderRadius": "12px",
          "background": "#ffffff",
          "boxShadow": "0 1px 3px rgba(0,0,0,0.1)",
          "display": "flex",
          "flexDirection": "column",
          "gap": "16px"
        },
        "children": ["img", "h3", "p", "a"]
      }
    ],

    // 可选：scope 包含 "effects" 时提取
    "effects": {
      "hasCanvas": false,
      "hasWebGL": false,
      "libraries": [],                              // 检测到的动效库：gsap / three / lottie / motion 等
      "scrollListeners": "low"                      // IntersectionObserver 密度：low / medium / high
    }
  },

  // ── AI 视觉分析（定性判断）── 两种模式都填写
  "analyzed": {
    "style": {
      "mood": ["minimal", "professional", "clean"],  // 3-5 个关键词
      "aesthetic": "geometric minimalism",
      "density": "comfortable",                       // compact | comfortable | spacious
      "contrast": "medium"                            // low | medium | high
    },
    "layout": {
      "hierarchy": "size-driven",    // size-driven | weight-driven | color-driven
      "balance": "symmetric",        // symmetric | asymmetric
      "flow": "top-down",            // top-down | left-right | card-grid
      "whitespace": "generous"       // tight | moderate | generous
    },
    "components": {
      "buttons": "rounded-solid-primary",
      "cards": "subtle-shadow-white",
      "navigation": "sticky-light-border",
      "inputs": "outlined-rounded"     // 可选，scope 包含 form 时填写；不包含时为 null
      // 不含 form scope 时：
      // "inputs": null
    },
    "motion": null
    // 有可观察动效时：
    // "motion": { "style": "subtle-fade", "speed": "fast", "easing": "ease-out" }
  }
}
```

## 字段说明

### colors.computed

按 computed style 出现频率统计，排除 `transparent`、`rgba(0,0,0,0)`、`inherit`。每类最多 top 10。

### spacing.baseUnit

对 spacing.values 数组求最大公约数。如 `[8, 16, 24, 32]` → baseUnit 为 8。

### patterns

过滤规则：去除以下 Tailwind utility class 前缀的 class — `flex`、`grid`、`w-`、`h-`、`p-`、`m-`、`text-`、`font-`、`bg-`、`border-`、`rounded-`、`gap-`、`space-`、`items-`、`justify-`、`overflow-`、`relative`、`absolute`、`fixed`、`sticky`、`hidden`、`block`、`inline`、`z-`、`opacity-`、`transition`、`duration-`、`ease-`。

**注意**：过滤对象是 CSS **class 选择器名称**（即 `.product-card` 的 `product-card` 部分），而非 `styles` 对象中的样式属性键。`styles` 中可以包含 `display`、`flexDirection`、`gap` 等任何 computed style 属性。
