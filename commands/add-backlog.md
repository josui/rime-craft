---
description: 快速添加 backlog 条目
---

向当前项目的 backlog 文件添加一条记录。

## 定位 backlog 文件

按以下顺序查找，使用第一个找到的：
1. `**/backlog.md`（Glob 搜索当前项目）
2. 找不到则提示用户指定路径

## 输入

`$ARGUMENTS` 格式：`[Section]: [内容]`

示例：
- `Service Page: Fact 支持拖拽排序`
- `Project Page: Asset 批量删除`

如果 `$ARGUMENTS` 为空，询问用户要添加什么。

## 执行步骤

1. 定位并读取 backlog 文件
2. 从 `$ARGUMENTS` 解析 section 和内容（冒号分隔）
3. 如果没指定 section 或 section 不存在，询问用户
4. 根据内容判断难度（🟢 半小时内 / 🟡 半天 / 🔴 1天+），告知用户
5. 编号：读取 backlog + archive + PRD 中的最大 `#xxx` 编号，自增
6. 在对应 section 表格末尾追加一行：
   - 编号：自增
   - 状态：❌
   - 优先级：根据内容判断，不确定时询问用户
   - 内容：用户提供
   - 难度：步骤 4 判断的结果
   - 说明：从用户描述中提取补充信息，简单条目可留空
7. 显示添加结果
