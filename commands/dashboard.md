---
description: 打开 .rime/ 数据可视化 dashboard
---

在浏览器中打开当前项目的 `.rime/` dashboard。

如果 `.rime/` 不存在，提示用户先用 `/rimeflow` 初始化项目。

## 参数

`$ARGUMENTS` 可选值：
- 空 — 一次性生成并打开
- `watch` 或 `--watch` — 监听模式，JSON 变化自动刷新

## 执行

定位脚本并运行：

```bash
# 找到本 plugin 内的 dashboard.sh（取最新版本目录）
SCRIPT=$(ls -d ~/.claude/plugins/cache/rime-marketplace/rime-craft/*/scripts/dashboard.sh 2>/dev/null | tail -1)
bash "$SCRIPT"          # 默认
bash "$SCRIPT" --watch  # watch 模式
```
