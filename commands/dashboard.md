---
description: 打开 .rime/ 数据可视化 dashboard
---

在浏览器中打开当前项目的 `.rime/` dashboard。

如果 `.rime/` 不存在，提示用户先用 `/rimeflow` 初始化项目。

## 前提条件

需要 Node.js 18+。

## 执行

检测 `.rime/dashboard-server.mjs` 是否存在：

- 存在 → 打印运行命令（使用绝对路径）：
  ```
  node <absolute-path-to-.rime>/dashboard-server.mjs          # live reload
  node <absolute-path-to-.rime>/dashboard-server.mjs --once   # 一次性打开
  ```
- 不存在 → 提示用 `/rimeflow` 初始化项目（会自动复制 dashboard-server.mjs）
