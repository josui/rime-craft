#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-end: $*" >> "$LOG"; }

# 0. 递归检测：worker 调用的 claude -p 退出时也会触发 SessionEnd hook
if [ "${RIME_HOOK_WORKER:-}" = "1" ]; then exit 0; fi

# 1. 读取 stdin（必须在前台完成，stdin 只能读一次）
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

# 5. 过滤 transcript
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

# 空对话 → minimal anchor（同步写，很快）
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
log "filtered: $FILTERED_LINES lines, spawning background worker"

# 6. 准备临时文件传递数据给 worker
WORK_DIR=$(mktemp -d)
echo "$FILTERED" > "$WORK_DIR/filtered.txt"
cp "$RIME_DIR/tasks.json" "$WORK_DIR/tasks.json"

# 7. 启动后台 worker（nohup + disown 确保不被父进程 kill）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
nohup "$SCRIPT_DIR/session-end-worker.sh" \
  "$RIME_DIR" "$TIMESTAMP" "$TIMESTAMP_ISO" "$TODAY" "$PHASE" "$WORK_DIR" \
  </dev/null >>"$LOG" 2>&1 &
disown

log "background worker spawned (pid=$!)"
