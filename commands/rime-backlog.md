---
description: 快速添加 backlog 条目
---

向当前项目的 `.rime/tasks.json` 添加一条新任务（status: todo）。

## 定位 tasks.json

按以下顺序查找，使用第一个找到的：
1. `**/.rime/tasks.json`（Glob 搜索当前项目）
2. 找不到则提示用户：需要先用 `/rime-init` 初始化项目

## 输入

`$ARGUMENTS` 格式：`[内容]` 或 `[Phase]: [内容]`，内容中可附带依赖声明。

示例：
- `Service Page 支持拖拽排序`
- `P2: Asset 批量删除功能`

**依赖解析**：识别内容中的「依赖 #0017」「依赖 #0017 #0018」这类表达，提取其中的 task ID（`#` + 4 位数字）为 `dependsOn` ID 列表。无显式依赖则不写该字段（不写 `"dependsOn": []`）。

示例：
- `Dashboard 交互化 依赖 #0017` → `dependsOn: ["#0017"]`
- `P2: 拓扑排序渲染 依赖 #0017 #0018` → `dependsOn: ["#0017", "#0018"]`

如果 `$ARGUMENTS` 为空，询问用户要添加什么。

## 执行步骤

1. 定位并读取 `.rime/tasks.json`
2. 从 `$ARGUMENTS` 解析内容（如有 Phase 前缀则提取，否则用 `phase.json` 的 current）
3. 根据内容判断 difficulty（`small` / `medium` / `large`），告知用户
4. 根据内容判断 priority（`high` / `medium` / `low`），不确定时询问用户
5. 从 tasks.json 读取 `nextId`，生成新 id（补零 4 位）
6. 如有 `segments`，根据 module 分配对应区间编号
7. **依赖存在性校验**（仅当解析出 `dependsOn`）：每个被依赖 ID 必须在当前 `tasks.json` 中存在。若有不存在的 ID，列出并提示用户，要求确认（保留）或移除后再继续；未澄清前不写入。
8. **依赖检环（DFS）**（仅当解析出 `dependsOn`）：将新 task 的 `dependsOn` 纳入由现有 task 的 `dependsOn` 构成的依赖图，从新 task 出发做 DFS。若构成环（含 `dependsOn` 指向自身的自依赖），**拒绝写入**并提示环路径（如 `#0033 → #0017 → #0033`）。tasks.json 须恒为 DAG。
9. **写入前校验**：确保以下必填字段全部存在且格式正确，缺失则中止并报错：
   - `id`: `#0001` 格式（4 位补零）
   - `title`: 非空字符串
   - `status`: 必须为 `todo`
   - `priority`: `high` / `medium` / `low` 之一
   - `createdAt`: `YYYY-MM-DD` 格式
   - `phase`: 非空字符串
   - `dependsOn`（可选）：若存在，须为 task ID 数组，且已通过第 7、8 步的存在性 + 无环校验；为空时不写该 key
10. 追加 item（`dependsOn` 仅当非空时加入，无依赖则省略该 key）：
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
      "dependsOn": ["#0017"],
      "subtasks": []
    }
    ```
11. `nextId` 自增
12. 显示添加结果：编号、标题、module、difficulty（🟢/🟡/🔴）、phase
