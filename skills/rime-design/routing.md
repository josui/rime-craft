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
| impeccable | v2.1.7 | 2026-04-13 |
| emil-design-eng | — | — |
| shadcn | — | — |

同步时操作：
1. 对比当前注册表与外部 skill 实际列表，更新增删
2. 更新同步版本和日期
3. 更新 `SKILL.md` 设计嗅觉表中对应的 skill 名称
4. 变更记录最多保留最近 2 个版本，超出时删除最旧的

## 设计上下文来源

| 方式 | 说明 |
|------|------|
| 手动填写 | 参考 `context-template.md` 结构，在 `docs/design-context.md` 中手动记录 |
| 从参考网站提取 | 使用 `rime-scan` skill 提取 scan JSON，需要时转化为 `design-context.md` |

## 维护规则

新增或移除外部 design skill 时，更新以下 2 个文件：

1. 本文件（`routing.md`）的注册表和版本追踪
2. `SKILL.md` 的设计嗅觉表
