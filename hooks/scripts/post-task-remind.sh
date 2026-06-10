#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook（matcher: TaskUpdate|TodoWrite）
# AI 把内部任务标记 completed 时，正是该同步 .rime subtask 的时刻——
# 若项目存在带未完成 subtask 的 doing task，注入一次同步提醒（5 分钟节流）

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] post-task-remind: $*" >> "$LOG"; }

command -v jq >/dev/null 2>&1 || exit 0
if [ "${RIME_HOOK_WORKER:-}" = "1" ]; then exit 0; fi

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

# 仅在「有任务被标记完成」时触发
HAS_COMPLETED=$(echo "$INPUT" | jq -r '
  if .tool_name == "TaskUpdate" then
    if (.tool_input.status // "") == "completed" then "yes" else "" end
  elif .tool_name == "TodoWrite" then
    if ((.tool_input.todos // []) | map(select(.status == "completed")) | length) > 0 then "yes" else "" end
  else "" end')
[ "$HAS_COMPLETED" = "yes" ] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rime-utils.sh"

RIME_DIRS=$(find_rime_dirs "$CWD")
[ -z "$RIME_DIRS" ] && exit 0

REMIND=""
while IFS= read -r RIME_DIR; do
  [ -z "$RIME_DIR" ] && continue
  [ -f "$RIME_DIR/tasks.json" ] || continue

  # 节流：同一 .rime 目录 5 分钟内只提醒一次
  STATE="${TMPDIR:-/tmp}/rime-remind-$(echo "$RIME_DIR" | cksum | cut -d' ' -f1)"
  if [ -n "$(find "$STATE" -mmin -5 2>/dev/null)" ]; then continue; fi

  # doing task 中尚有未完成 subtask 的清单
  PENDING=$(jq -r '
    (.items // [])[]
    | select(.status == "doing")
    | select((.subtasks // []) | map(select(.status != "done")) | length > 0)
    | "- \(.id) \(.title): " + ((.subtasks // []) | map(select(.status != "done") | .title) | join(" / "))
  ' "$RIME_DIR/tasks.json" 2>/dev/null || echo "")
  [ -z "$PENDING" ] && continue

  touch "$STATE"
  LABEL=$(rime_label "$RIME_DIR" "$CWD")
  REMIND="$REMIND"$'\n'"${LABEL:+[$LABEL] }$PENDING"
done <<< "$RIME_DIRS"

[ -z "$REMIND" ] && exit 0

log "remind injected for $CWD"
jq -n --arg ctx "内部任务已标记完成。若它对应以下 .rime doing task 的 subtask，请立即在 tasks.json 中将该 subtask 的 status 改为 done（dashboard 依赖此数据）：$REMIND" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
