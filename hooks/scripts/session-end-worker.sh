#!/usr/bin/env bash
set -euo pipefail

# 后台 worker：接收前台脚本准备好的数据，执行 claude -p 并写入 anchor
# 由 session-end.sh 通过 nohup 启动，不受 hook 超时限制

RIME_DIR="$1"
TIMESTAMP="$2"
TIMESTAMP_ISO="$3"
TODAY="$4"
TRANSCRIPT="$5"

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-end[bg]: $*" >> "$LOG"; }

command -v jq >/dev/null 2>&1 || { log "exit: jq not found in PATH"; exit 0; }
[ -f "$TRANSCRIPT" ] || { log "exit: transcript missing: $TRANSCRIPT"; exit 0; }

PHASE=$(jq -r '.current // "unknown"' "$RIME_DIR/phase.json" 2>/dev/null || echo "unknown")
mkdir -p "$RIME_DIR/anchors"

write_minimal_anchor() {
  jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
    schemaVersion: 1, timestamp: $ts, phase: $ph,
    workedOn: [], subtasksCompleted: [], subtasksAdded: [],
    decisions: [], nextSteps: [], cautions: []
  }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
}

# transcript 过滤（重活下放后台，避免前台被 hook 超时杀）
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

FILTERED_LINES=$(echo "$FILTERED" | grep -c '.' 2>/dev/null || echo "0")

# 空对话 → minimal anchor，无需调 claude -p
if [ -z "$FILTERED" ] || [ "$FILTERED_LINES" -lt 2 ]; then
  log "minimal anchor: $RIME_DIR (filtered_lines=$FILTERED_LINES)"
  write_minimal_anchor
  exit 0
fi

TASKS=$(cat "$RIME_DIR/tasks.json")

# 调用 claude -p
PROMPT="你是一个 session 总结助手。分析以下对话内容，结合当前任务列表，提取关键信息。

当前任务列表:
$TASKS

对话内容:
$FILTERED

输出严格 JSON 格式（无 markdown 包裹、无注释、无多余文字）:
{
  \"workedOn\": [\"#xxx\"],
  \"subtasksCompleted\": [\"本次完成的工作内容（自由描述）\"],
  \"subtasksAdded\": [\"发现的新子任务（自由描述）\"],
  \"decisions\": [\"关键决策\"],
  \"nextSteps\": [\"下一步\"],
  \"cautions\": [{\"title\": \"踩坑标题\", \"summary\": \"详细描述（可选）\", \"tags\": [\"tag1\"]}]
}

规则:
- workedOn 只填 tasks.json 中已存在的 task ID
- subtasksCompleted: 本次完成的工作。若对应某个 doing task 的 subtask，**原样复述该 subtask 的 title**（系统会据此自动对账翻 done）；其余自由描述
- subtasksAdded: 自由描述发现的新子任务（作为 session 记录，不用于自动状态变更）
- 没有的字段填空数组，不要编造
- 只输出 JSON，不要任何其他文字"

# perl alarm 做超时（macOS 无 GNU timeout）：超时收到 SIGALRM 退出，降级走 minimal anchor
CLAUDE_TIMEOUT="${RIME_CLAUDE_TIMEOUT:-120}"
RAW=$(RIME_HOOK_WORKER=1 perl -e 'alarm shift @ARGV; exec @ARGV' "$CLAUDE_TIMEOUT" \
  claude -p --model haiku <<< "$PROMPT" 2>/dev/null || echo "")

# 从模型输出中提取 JSON（可能被 markdown 代码块包裹）
RESULT=$(echo "$RAW" | sed -n '/^```/,/^```/{ /^```/d; p; }' 2>/dev/null)
[ -z "$RESULT" ] && RESULT="$RAW"

# 无效 JSON → 降级为 minimal anchor
if [ -z "$RESULT" ] || ! echo "$RESULT" | jq . >/dev/null 2>&1; then
  log "fallback: invalid JSON: $(echo "$RAW" | head -1)"
  write_minimal_anchor
  exit 0
fi
log "claude-p success"

# 写 anchor
echo "$RESULT" | jq --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{schemaVersion: 1} + . + {timestamp: $ts, phase: $ph}' > "$RIME_DIR/anchors/$TIMESTAMP.json"

# subtask 保守对账：仅限 workedOn 的 task，subtasksCompleted 与 subtask title
# 精确相等或互为子串时翻 done（只翻不回翻）。语义见 rime-flow/data-contract.md
WORKED=$(echo "$RESULT" | jq -c '.workedOn // []' 2>/dev/null || echo "[]")
COMPLETED=$(echo "$RESULT" | jq -c '.subtasksCompleted // []' 2>/dev/null || echo "[]")
if [ "$(echo "$WORKED" | jq 'length')" -gt 0 ] && [ "$(echo "$COMPLETED" | jq 'length')" -gt 0 ]; then
  TMP2=$(mktemp)
  if jq --argjson worked "$WORKED" --argjson completed "$COMPLETED" '
    if (.items | type) == "array" then
      .items |= map(
        if ((.id as $id | $worked | index($id)) != null) and (.status == "doing") and ((.subtasks | type) == "array") then
          .subtasks |= map(
            if .status != "done" and (.title as $t |
              $completed | any(. as $c | ($c | length) > 0 and
                ($c == $t or ($t | contains($c)) or ($c | contains($t))))) then
              .status = "done"
            else . end)
        else . end)
    else . end
  ' "$RIME_DIR/tasks.json" > "$TMP2" 2>/dev/null; then
    if ! cmp -s "$TMP2" "$RIME_DIR/tasks.json"; then
      OLD_N=$(jq '.items | length' "$RIME_DIR/tasks.json" 2>/dev/null)
      NEW_N=$(jq '.items | length' "$TMP2" 2>/dev/null)
      if [ -n "$OLD_N" ] && [ "$NEW_N" = "$OLD_N" ]; then
        mv "$TMP2" "$RIME_DIR/tasks.json"
        log "subtask reconcile: tasks.json updated"
      else
        rm -f "$TMP2"
        log "subtask reconcile: item count mismatch, skipped"
      fi
    else
      rm -f "$TMP2"
    fi
  else
    rm -f "$TMP2"
    log "subtask reconcile: jq failed, skipped"
  fi
fi

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
