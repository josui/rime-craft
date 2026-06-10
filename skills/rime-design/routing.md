# Design Skill Routing

## 检测逻辑

AI 无法在运行时动态检测已安装的 skill 列表。
采用「尝试调用 → 失败则 fallback」策略：

- 建议使用某 skill 时，直接尝试调用
- skill 不存在时 Claude 会报错，此时执行 fallback
- 一次 session 内记住哪些 skill 不可用，不重复尝试

## 外部 Skill 来源与安装

rime-design 路由的外部 skill 来自以下来源：

| 来源 | 安装方式 | 说明 |
|------|---------|------|
| Anthropic 官方 | Claude Code 内置，无需安装 | `frontend-design` 等官方 skill |
| impeccable | `/install-plugin impeccable` | 设计增强 skill 套件（基于 Anthropic frontend-design 扩展） |
| emil-design-eng | 独立安装 | Emil Kowalski 动效哲学 |
| shadcn | 独立安装 | shadcn/ui 组件管理 |

未安装时 fallback 到 rime-design baseline 规则（见 SKILL.md）。

## 设计嗅觉表

开发过程中观察到信号时的路由依据（嗅觉行为说明见 SKILL.md，本表为唯一来源）：

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

## 外部 Skill 注册表

| Skill | 类型 | 覆盖维度 | 来源 |
|-------|------|---------|------|
| frontend-design | 创作 | 美学方向 + AI slop 防御 | Anthropic 官方 |
| impeccable | 创作/元 | frontend-design 扩展 + teach + extract + craft | impeccable |
| shape | 规划 | 编码前 UX/UI 规划，输出 design brief | impeccable |
| emil-design-eng | 动画 | 动画决策 + 实现 review | 独立 |
| animate | 动画 | 动画增强实现 | impeccable |
| colorize | 色彩 | 色彩策略 | impeccable |
| layout | 布局 | 间距/节奏/Grid vs Flex 决策 | impeccable |
| typeset | 排版 | 字体/层级 | impeccable |
| clarify | 文案 | UX copy | impeccable |
| distill | 精简 | 去复杂度 | impeccable |
| bolder | 增强 | 加强度 | impeccable |
| quieter | 降噪 | 减强度 | impeccable |
| polish | 打磨 | 最终品质 + 设计系统一致性 | impeccable |
| adapt | 适配 | 响应式/跨端 | impeccable |
| harden | 健壮 | 边缘情况/i18n/首次体验/空状态 | impeccable |
| optimize | 性能 | 加载/渲染 | impeccable |
| audit | 审计 | 全面质量检查 | impeccable |
| critique | 评审 | UX 视角评估 + 认知负荷/启发式评分/Personas | impeccable |
| delight | 愉悦 | 微交互/个性 | impeccable |
| overdrive | 极端 | 技术挑战型效果 | impeccable |
| shadcn | 组件 | shadcn/ui 组合规则 | 独立 |

### v1.5.0 → v2.1.7 变更记录

| 旧 Skill | 变化 | 版本 |
|----------|------|------|
| frontend-design | → 重命名为 `impeccable` | v2.0 |
| teach-impeccable | → 合并到 `/impeccable teach` | v2.0 |
| arrange | → 重命名为 `layout` | v2.1 |
| normalize | → 合并到 `polish` | v2.1 |
| onboard | → 合并到 `harden` | v2.1 |
| extract | → 合并到 `/impeccable extract` | v2.1 |

## 版本追踪

外部 skill 的版本标记，用于检测更新差异。

| 来源 | 同步版本 | 同步日期 |
|------|---------|---------|
| impeccable | v2.1.7 | 2026-04-16 |
| emil-design-eng | — | — |
| shadcn | — | — |

同步时操作：
1. 对比当前注册表与外部 skill 实际列表，更新增删
2. 更新同步版本和日期
3. 更新本文件设计嗅觉表中对应的 skill 名称
4. 变更记录最多保留最近 2 个版本，超出时删除最旧的

## 设计上下文来源

| 方式 | 说明 |
|------|------|
| 手动填写 | 参考 `context-template.md` 结构，在 `docs/design-context.md` 中手动记录 |
| 从参考网站提取 | 使用 `rime-scan` skill 提取 scan JSON，需要时转化为 `design-context.md` |

## 维护规则

新增或移除外部 design skill 时，只更新**本文件**（注册表、设计嗅觉表、版本追踪）。SKILL.md 只持有指针，不复述路由细节。
