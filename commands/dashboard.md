---
description: 打开 .rime/ 数据可视化 dashboard
---

在浏览器中打开当前项目的 `.rime/` dashboard。

## 定位 .rime/

按以下顺序查找，使用第一个找到的：
1. `**/.rime/tasks.json`（Glob 搜索当前项目）
2. 找不到则提示用户：需要先用 `/rimeflow` 初始化项目

## 参数

`$ARGUMENTS` 可选值：
- 空 — 一次性生成并打开
- `watch` 或 `--watch` — 监听模式，JSON 变化自动刷新

## 执行步骤

1. 定位 `.rime/` 目录
2. 读取 `tasks.json`、`phase.json`、`cautions.json`
3. 在项目中查找 `scripts/dashboard.sh`（Glob `**/scripts/dashboard.sh`）
4. 运行脚本：
   - 无参数：`bash scripts/dashboard.sh`
   - watch 模式：`bash scripts/dashboard.sh --watch`（后台运行）
5. 告知用户 dashboard 已在浏览器打开
