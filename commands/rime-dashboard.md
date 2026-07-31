---
description: Open the current project's .rime/ kanban dashboard — tasks, phases, and cautions. Project task tracking, NOT AI usage/spend/billing.
---

在浏览器中打开当前项目的 `.rime/` dashboard。

## 前提条件

- Node.js 18+
- 当前项目已有 `.rime/` 目录（含 tasks.json）

如果 `.rime/` 不存在，server 会打印它解析到的路径并提示先用 `/rime-init` 初始化项目。

## 执行

Dashboard server 脚本位于 plugin 内部，无需复制到项目中。脚本路径用 `${CLAUDE_PLUGIN_ROOT}` 解析——Claude Code 会在本命令进入上下文前就地展开为绝对路径，无需推算或查找。

**直接启动，不要询问用户。** 在项目目录下使用后台运行（`run_in_background`）启动 live reload 模式：

```
node ${CLAUDE_PLUGIN_ROOT}/dashboard/server.mjs
```

**不要自己拼 `--rime-dir`。** server 内置解析器，解析顺序与 hooks 完全一致（权威定义见 rime-flow 的 data-contract.md「存储位置与解析顺序」），并且会正确处理 linked worktree——从 worktree 启动时自动解析到主检出侧的权威数据。手工拼路径会绕过这层，在 worktree 下拿到错的或不存在的目录。

仅在需要指向另一个项目的 `.rime/` 时才追加 `--rime-dir <path>`。

Node 启动后会自动在浏览器中打开页面，不需要额外执行 `open` 命令。

告知用户 dashboard 已启动，live reload 模式运行中。
