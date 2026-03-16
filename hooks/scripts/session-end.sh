#!/usr/bin/env bash
set -euo pipefail

# 1. 读取 stdin
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
[ -z "$CWD" ] && exit 0
[ -z "$TRANSCRIPT" ] && exit 0

# 2. 检查 .rime/
RIME_DIR="$CWD/.rime"
[ -d "$RIME_DIR" ] || exit 0
[ -f "$TRANSCRIPT" ] || exit 0
[ -f "$RIME_DIR/tasks.json" ] || exit 0

# 3. 时间戳
TIMESTAMP=$(date +%Y-%m-%dT%H-%M)
TIMESTAMP_ISO=$(date +%Y-%m-%dT%H:%M:%S%z)
TODAY=$(date +%Y-%m-%d)

# 4. 读取当前 phase
PHASE=$(jq -r '.current // "unknown"' "$RIME_DIR/phase.json" 2>/dev/null || echo "unknown")

# 5. 过滤 transcript: 只取 user/assistant 的文本内容
FILTERED=$(cat "$TRANSCRIPT" | jq -r '
  if .type == "user" then
    "User: \(.message.content // "" | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end)"
  elif .type == "assistant" then
    "Assistant: \([.message.content[]? | select(.type == "text") | .text] | join("\n"))"
  else
    empty
  end
' 2>/dev/null || echo "")

# 空对话 → minimal anchor
if [ -z "$FILTERED" ] || [ "$(echo "$FILTERED" | wc -l)" -lt 2 ]; then
  jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
    timestamp: $ts, phase: $ph,
    workedOn: [], subtasksCompleted: [], subtasksAdded: [],
    decisions: [], nextSteps: [], cautions: []
  }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
  exit 0
fi

# 6. 读取 tasks.json 供 claude -p 参考
TASKS=$(cat "$RIME_DIR/tasks.json")

# 7. 调用 claude -p
PROMPT="你是一个 session 总结助手。分析以下对话内容，结合当前任务列表，提取关键信息。

当前任务列表:
$TASKS

对话内容:
$FILTERED

输出严格 JSON 格式（无 markdown 包裹、无注释、无多余文字）:
{
  \"workedOn\": [\"#xxx\"],
  \"subtasksCompleted\": [\"已完成的子任务标题（必须精确匹配 tasks.json 中的 subtask title）\"],
  \"subtasksAdded\": [{\"taskId\": \"#xxx\", \"title\": \"新子任务\"}],
  \"decisions\": [\"关键决策\"],
  \"nextSteps\": [\"下一步\"],
  \"cautions\": [{\"title\": \"踩坑标题\", \"summary\": \"详细描述（可选）\", \"tags\": [\"tag1\"]}]
}

规则:
- workedOn 只填 tasks.json 中已存在的 task ID
- subtasksCompleted 的标题必须和 tasks.json 中的 subtask title 完全一致
- 没有的字段填空数组，不要编造
- 只输出 JSON，不要任何其他文字"

RESULT=$(echo "$PROMPT" | claude -p --model haiku --output-format json 2>/dev/null || echo "")

# 8. 错误处理: claude -p 失败则降级为 minimal anchor
if [ -z "$RESULT" ] || ! echo "$RESULT" | jq . >/dev/null 2>&1; then
  jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
    timestamp: $ts, phase: $ph,
    workedOn: [], subtasksCompleted: [], subtasksAdded: [],
    decisions: [], nextSteps: [], cautions: []
  }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
  exit 0
fi

# 9. 写 anchor
echo "$RESULT" | jq --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '. + {timestamp: $ts, phase: $ph}' > "$RIME_DIR/anchors/$TIMESTAMP.json"

# 10. 更新 tasks.json — 标记完成的 subtasks
COMPLETED_COUNT=$(echo "$RESULT" | jq '.subtasksCompleted | length' 2>/dev/null || echo "0")
if [ "$COMPLETED_COUNT" -gt 0 ] 2>/dev/null; then
  TMP=$(mktemp)
  echo "$RESULT" | jq -r '.subtasksCompleted[]' 2>/dev/null | while IFS= read -r subtask; do
    [ -z "$subtask" ] && continue
    jq --arg st "$subtask" '
      .items |= map(
        .subtasks |= map(
          if .title == $st then .status = "done" else . end
        )
      )
    ' "$RIME_DIR/tasks.json" > "$TMP" && cp "$TMP" "$RIME_DIR/tasks.json"
  done
  rm -f "$TMP"
fi

# 11. 更新 tasks.json — 添加新 subtasks
ADDED_COUNT=$(echo "$RESULT" | jq '.subtasksAdded | length' 2>/dev/null || echo "0")
if [ "$ADDED_COUNT" -gt 0 ] 2>/dev/null; then
  TMP=$(mktemp)
  echo "$RESULT" | jq -c '.subtasksAdded[]' 2>/dev/null | while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    TASK_ID=$(echo "$entry" | jq -r '.taskId')
    TITLE=$(echo "$entry" | jq -r '.title')
    [ -z "$TASK_ID" ] || [ -z "$TITLE" ] && continue
    jq --arg id "$TASK_ID" --arg title "$TITLE" '
      .items |= map(
        if .id == $id and ([.subtasks[] | select(.title == $title)] | length == 0) then
          .subtasks += [{"title": $title, "status": "todo"}]
        else . end
      )
    ' "$RIME_DIR/tasks.json" > "$TMP" && cp "$TMP" "$RIME_DIR/tasks.json"
  done
  rm -f "$TMP"
fi

# 12. 检查是否有 item 所有 subtask 都 done → 标记 item done
TMP=$(mktemp)
jq --arg today "$TODAY" '
  .items |= map(
    if .status == "doing" and (.subtasks | length > 0) and (.subtasks | all(.status == "done")) then
      .status = "done" | .completedAt = $today
    else . end
  )
' "$RIME_DIR/tasks.json" > "$TMP" && mv "$TMP" "$RIME_DIR/tasks.json"

# 13. 追加 cautions
CAUTION_COUNT=$(echo "$RESULT" | jq '.cautions | length' 2>/dev/null || echo "0")
if [ "$CAUTION_COUNT" -gt 0 ] 2>/dev/null; then
  # 读取当前最大 caution ID
  MAX_NUM=$(jq -r '.[].id // "C-000"' "$RIME_DIR/cautions.json" 2>/dev/null | sed 's/C[-]*0*//' | sort -n | tail -1 || echo "0")
  [ -z "$MAX_NUM" ] && MAX_NUM=0
  COUNTER=$((10#$MAX_NUM))

  TMP=$(mktemp)
  echo "$RESULT" | jq -c '.cautions[]' 2>/dev/null | while IFS= read -r caution; do
    [ -z "$caution" ] && continue
    COUNTER=$((COUNTER + 1))
    NEW_ID=$(printf "C-%03d" $COUNTER)
    # 创建完整 caution 对象并追加到数组
    FULL_CAUTION=$(echo "$caution" | jq --arg id "$NEW_ID" --arg date "$TODAY" --arg src "session-$TIMESTAMP" \
      '. + {id: $id, createdAt: $date, source: $src}')
    jq --argjson nc "$FULL_CAUTION" '. += [$nc]' "$RIME_DIR/cautions.json" > "$TMP" && cp "$TMP" "$RIME_DIR/cautions.json"
  done
  rm -f "$TMP"
fi
