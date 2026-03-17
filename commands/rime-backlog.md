---
description: 快速添加 backlog 条目
---

向当前项目的 `.rime/tasks.json` 添加一条新任务（status: todo）。

## 定位 tasks.json

按以下顺序查找，使用第一个找到的：
1. `**/.rime/tasks.json`（Glob 搜索当前项目）
2. 找不到则提示用户：需要先用 `/rime-init` 初始化项目

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
5. 从 tasks.json 读取 `nextId`，生成新 id（补零 4 位）
6. 如有 `segments`，根据 module 分配对应区间编号
7. **写入前校验**：确保以下必填字段全部存在且格式正确，缺失则中止并报错：
   - `id`: `#0001` 格式（4 位补零）
   - `title`: 非空字符串
   - `status`: 必须为 `todo`
   - `priority`: `high` / `medium` / `low` 之一
   - `createdAt`: `YYYY-MM-DD` 格式
   - `phase`: 非空字符串
8. 追加 item：
   ```json
   {
     "id": "#0001",
     "module": "模块名（有 segments 时推断，否则可选）",
     "title": "用户提供的内容",
     "description": "",
     "status": "todo",
     "phase": "从解析或 phase.json 获取",
     "priority": "判断结果",
     "difficulty": "判断结果",
     "createdAt": "今天日期",
     "subtasks": []
   }
   ```
9. `nextId` 自增
10. 显示添加结果：编号、标题、module、difficulty（🟢/🟡/🔴）、phase
