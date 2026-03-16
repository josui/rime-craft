---
description: 快速添加 backlog 条目
---

向当前项目的 `.rime/tasks.json` 添加一条新任务（status: todo）。

## 定位 tasks.json

按以下顺序查找，使用第一个找到的：
1. `**/.rime/tasks.json`（Glob 搜索当前项目）
2. 找不到则提示用户：需要先用 `/rimeflow` 初始化项目

## 输入

`$ARGUMENTS` 格式：`[内容]` 或 `[Phase]: [内容]`

示例：
- `Service Page 支持拖拽排序`
- `P2: Asset 批量删除功能`

如果 `$ARGUMENTS` 为空，询问用户要添加什么。

## 执行步骤

1. 定位并读取 `.rime/tasks.json`
2. 从 `$ARGUMENTS` 解析内容（如有 Phase 前缀则提取，否则用 `phase.json` 的 current）
3. 根据内容判断 difficulty（`small` / `medium` / `large`），告知用户
4. 根据内容判断 priority（`high` / `medium` / `low`），不确定时询问用户
5. 从 tasks.json 读取 `nextId`，生成新 id（补零 3 位）
6. 追加 item：
   ```json
   {
     "id": "#xxx",
     "title": "用户提供的内容",
     "status": "todo",
     "phase": "从解析或 phase.json 获取",
     "priority": "判断结果",
     "difficulty": "判断结果",
     "createdAt": "今天日期",
     "subtasks": []
   }
   ```
7. `nextId` 自增
8. 显示添加结果：编号、标题、difficulty（🟢/🟡/🔴）、phase
