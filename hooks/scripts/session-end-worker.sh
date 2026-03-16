#!/usr/bin/env bash
set -euo pipefail

# 后台 worker：接收前台脚本准备好的数据，执行 claude -p 并写入 anchor
# 由 session-end.sh 通过 nohup 启动，不受 hook 超时限制

RIME_DIR="$1"
TIMESTAMP="$2"
TIMESTAMP_ISO="$3"
TODAY="$4"
PHASE="$5"
WORK_DIR="$6"

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-end[bg]: $*" >> "$LOG"; }

# 清理临时文件
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

FILTERED=$(cat "$WORK_DIR/filtered.txt")
TASKS=$(cat "$WORK_DIR/tasks.json")

# 调用 claude -p
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

RAW=$(RIME_HOOK_WORKER=1 claude -p --model haiku <<< "$PROMPT" 2>/dev/null || echo "")

# 从模型输出中提取 JSON（可能被 markdown 代码块包裹）
RESULT=$(echo "$RAW" | sed -n '/^```/,/^```/{ /^```/d; p; }' 2>/dev/null)
[ -z "$RESULT" ] && RESULT="$RAW"

# 无效 JSON → 降级为 minimal anchor
if [ -z "$RESULT" ] || ! echo "$RESULT" | jq . >/dev/null 2>&1; then
  log "fallback: invalid JSON: $(echo "$RAW" | head -1)"
  jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
    timestamp: $ts, phase: $ph,
    workedOn: [], subtasksCompleted: [], subtasksAdded: [],
    decisions: [], nextSteps: [], cautions: []
  }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
  exit 0
fi
log "claude-p success"

# 写 anchor
echo "$RESULT" | jq --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '. + {timestamp: $ts, phase: $ph}' > "$RIME_DIR/anchors/$TIMESTAMP.json"

# 更新 tasks.json — 标记完成的 subtasks
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

# 更新 tasks.json — 添加新 subtasks
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

# 检查是否有 item 所有 subtask 都 done → 标记 item done
TMP=$(mktemp)
jq --arg today "$TODAY" '
  .items |= map(
    if .status == "doing" and (.subtasks | length > 0) and (.subtasks | all(.status == "done")) then
      .status = "done" | .completedAt = $today
    else . end
  )
' "$RIME_DIR/tasks.json" > "$TMP" && mv "$TMP" "$RIME_DIR/tasks.json"

# 追加 cautions
CAUTION_COUNT=$(echo "$RESULT" | jq '.cautions | length' 2>/dev/null || echo "0")
if [ "$CAUTION_COUNT" -gt 0 ] 2>/dev/null; then
  MAX_NUM=$(jq -r '.[].id // "C-000"' "$RIME_DIR/cautions.json" 2>/dev/null | sed 's/C[-]*0*//' | sort -n | tail -1 || echo "0")
  [ -z "$MAX_NUM" ] && MAX_NUM=0
  COUNTER=$((10#$MAX_NUM))

  TMP=$(mktemp)
  echo "$RESULT" | jq -c '.cautions[]' 2>/dev/null | while IFS= read -r caution; do
    [ -z "$caution" ] && continue
    COUNTER=$((COUNTER + 1))
    NEW_ID=$(printf "C-%03d" $COUNTER)
    FULL_CAUTION=$(echo "$caution" | jq --arg id "$NEW_ID" --arg date "$TODAY" --arg src "session-$TIMESTAMP" \
      '. + {id: $id, createdAt: $date, source: $src}')
    jq --argjson nc "$FULL_CAUTION" '. += [$nc]' "$RIME_DIR/cautions.json" > "$TMP" && cp "$TMP" "$RIME_DIR/cautions.json"
  done
  rm -f "$TMP"
fi

log "done: anchor=$RIME_DIR/anchors/$TIMESTAMP.json"
