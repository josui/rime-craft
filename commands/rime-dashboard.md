---
description: 打开 .rime/ 数据可视化 dashboard
---

在浏览器中打开当前项目的 `.rime/` dashboard。

## 前提条件

- Node.js 18+
- 当前项目已有 `.rime/` 目录（含 tasks.json）

如果 `.rime/` 不存在，提示用户先用 `/rime-flow` 初始化项目。

## 执行

Dashboard server 脚本位于 plugin 内部，无需复制到项目中。

找到 plugin 内的脚本路径（基于本 command 文件的位置推算）：
`<plugin-root>/skills/rime-flow/assets/dashboard-server.mjs`

**直接启动，不要询问用户。** 使用后台运行（`run_in_background`）启动 live reload 模式：

```
node <plugin-root>/skills/rime-flow/assets/dashboard-server.mjs --rime-dir <project>/.rime
```

Node 启动后会自动在浏览器中打开页面，不需要额外执行 `open` 命令。

告知用户 dashboard 已启动，live reload 模式运行中。
