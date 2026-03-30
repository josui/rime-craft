# Design Skill Routing

## 检测逻辑

AI 无法在运行时动态检测已安装的 skill 列表。
采用「尝试调用 → 失败则 fallback」策略：

- 建议使用某 skill 时，直接尝试调用
- skill 不存在时 Claude 会报错，此时执行 fallback
- 一次 session 内记住哪些 skill 不可用，不重复尝试

## 外部 Skill 注册表

| Skill | 类型 | 覆盖维度 | 来源 |
|-------|------|---------|------|
| frontend-design | 创作 | 美学方向 + AI slop 防御 | impeccable |
| emil-design-eng | 动画 | 动画决策 + 实现 review | 独立 |
| animate | 动画 | 动画增强实现 | impeccable |
| colorize | 色彩 | 色彩策略 | impeccable |
| arrange | 布局 | 间距/节奏 | impeccable |
| typeset | 排版 | 字体/层级 | impeccable |
| clarify | 文案 | UX copy | impeccable |
| distill | 精简 | 去复杂度 | impeccable |
| bolder | 增强 | 加强度 | impeccable |
| quieter | 降噪 | 减强度 | impeccable |
| polish | 打磨 | 最终品质 | impeccable |
| adapt | 适配 | 响应式/跨端 | impeccable |
| harden | 健壮 | 边缘情况/i18n | impeccable |
| optimize | 性能 | 加载/渲染 | impeccable |
| normalize | 对齐 | 设计系统一致性 | impeccable |
| extract | 抽取 | 组件/token 提取 | impeccable |
| audit | 审计 | 全面质量检查 | impeccable |
| critique | 评审 | UX 视角评估 | impeccable |
| onboard | 入门 | 首次体验/空状态 | impeccable |
| delight | 愉悦 | 微交互/个性 | impeccable |
| overdrive | 极端 | 技术挑战型效果 | impeccable |
| shadcn | 组件 | shadcn/ui 组合规则 | 独立 |

## 维护规则

新增或移除外部 design skill 时，更新以下 2 个文件：

1. 本文件（`routing.md`）的注册表
2. `SKILL.md` 的设计嗅觉表
