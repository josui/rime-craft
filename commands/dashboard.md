---
description: 打开 .rime/ 数据可视化 dashboard
---

在浏览器中打开当前项目的 `.rime/` dashboard。

## 前提条件

- Node.js 18+
- 当前项目已有 `.rime/` 目录（含 tasks.json）

如果 `.rime/` 不存在，提示用户先用 `/rimeflow` 初始化项目。

## 执行

Dashboard server 脚本位于 plugin 内部，无需复制到项目中。

找到 plugin 内的脚本路径（基于本 command 文件的位置推算）：
`<plugin-root>/skills/rimeflow/assets/dashboard-server.mjs`

打印运行命令（使用绝对路径，--rime-dir 指向当前项目的 .rime/）：

```
# 一次性打开（推荐）
node <plugin-root>/skills/rimeflow/assets/dashboard-server.mjs --rime-dir <project>/.rime --once

# live reload 模式（文件变化自动刷新）
node <plugin-root>/skills/rimeflow/assets/dashboard-server.mjs --rime-dir <project>/.rime
```
