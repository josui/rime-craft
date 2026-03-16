#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-end: $*" >> "$LOG"; }

# 1. 读取 stdin
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$CWD" ]; then log "exit: no cwd"; exit 0; fi
if [ -z "$TRANSCRIPT" ]; then log "exit: no transcript_path"; exit 0; fi

# 2. 检查 .rime/
RIME_DIR="$CWD/.rime"
if [ ! -d "$RIME_DIR" ]; then log "exit: no .rime/ in $CWD"; exit 0; fi
if [ ! -f "$TRANSCRIPT" ]; then log "exit: transcript not found: $TRANSCRIPT"; exit 0; fi
if [ ! -f "$RIME_DIR/tasks.json" ]; then log "exit: no tasks.json"; exit 0; fi
log "start: cwd=$CWD transcript=$TRANSCRIPT"

# 3. 时间戳
TIMESTAMP=$(date +%Y-%m-%dT%H-%M)
TIMESTAMP_ISO=$(date +%Y-%m-%dT%H:%M:%S%z)
TODAY=$(date +%Y-%m-%d)

# 4. 读取当前 phase
PHASE=$(jq -r '.current // "unknown"' "$RIME_DIR/phase.json" 2>/dev/null || echo "unknown")

# 5. 过滤 transcript: 只取 user/assistant 的文本内容，去除空行
FILTERED=$(jq -r '
  if .type == "user" then
    (.message.content // "" | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end) as $t |
    if ($t | length) > 0 then "User: \($t)" else empty end
  elif .type == "assistant" then
    ([.message.content[]? | select(.type == "text") | .text] | join("\n")) as $t |
    if ($t | length) > 0 then "Assistant: \($t)" else empty end
  else
    empty
  end
' "$TRANSCRIPT" 2>/dev/null || echo "")

# 空对话 → minimal anchor
FILTERED_LINES=$(echo "$FILTERED" | grep -c '.' 2>/dev/null || echo "0")
if [ -z "$FILTERED" ] || [ "$FILTERED_LINES" -lt 2 ]; then
  log "minimal anchor: filtered_lines=$FILTERED_LINES"
  jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
    timestamp: $ts, phase: $ph,
    workedOn: [], subtasksCompleted: [], subtasksAdded: [],
    decisions: [], nextSteps: [], cautions: []
  }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
  exit 0
fi
log "filtered: $FILTERED_LINES lines"

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

RAW=$(echo "$PROMPT" | claude -p --model haiku 2>/dev/null || echo "")

# 8. 从模型输出中提取 JSON（可能被 markdown 代码块包裹）
RESULT=$(echo "$RAW" | sed -n '/^```/,/^```/{ /^```/d; p; }' 2>/dev/null)
# 如果没有代码块包裹，尝试直接用原始输出
[ -z "$RESULT" ] && RESULT="$RAW"

# 9. 错误处理: 无效 JSON 则降级为 minimal anchor
if [ -z "$RESULT" ] || ! echo "$RESULT" | jq . >/dev/null 2>&1; then
  log "fallback: claude -p output invalid JSON: $(echo "$RAW" | head -1)"
  jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
    timestamp: $ts, phase: $ph,
    workedOn: [], subtasksCompleted: [], subtasksAdded: [],
    decisions: [], nextSteps: [], cautions: []
  }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
  exit 0
fi
log "claude-p success"

# 10. 写 anchor
echo "$RESULT" | jq --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '. + {timestamp: $ts, phase: $ph}' > "$RIME_DIR/anchors/$TIMESTAMP.json"

# 11. 更新 tasks.json — 标记完成的 subtasks
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

# 12. 更新 tasks.json — 添加新 subtasks
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

# 13. 检查是否有 item 所有 subtask 都 done → 标记 item done
TMP=$(mktemp)
jq --arg today "$TODAY" '
  .items |= map(
    if .status == "doing" and (.subtasks | length > 0) and (.subtasks | all(.status == "done")) then
      .status = "done" | .completedAt = $today
    else . end
  )
' "$RIME_DIR/tasks.json" > "$TMP" && mv "$TMP" "$RIME_DIR/tasks.json"

# 14. 追加 cautions
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

log "done: anchor=$RIME_DIR/anchors/$TIMESTAMP.json"
