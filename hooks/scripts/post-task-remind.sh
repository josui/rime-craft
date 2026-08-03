#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook (matcher: TaskUpdate|TodoWrite)
# The moment the AI marks an internal task completed is exactly when the .rime subtask should be synced —
# if the project has a doing task with incomplete subtasks, inject a one-time sync reminder (throttled to 5 minutes)

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] post-task-remind: $*" >> "$LOG"; }

command -v jq >/dev/null 2>&1 || exit 0
if [ "${RIME_HOOK_WORKER:-}" = "1" ]; then exit 0; fi

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

# Only trigger when "a task was marked completed"
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

  # Throttle: only one reminder per .rime directory within 5 minutes
  STATE="${TMPDIR:-/tmp}/rime-remind-$(echo "$RIME_DIR" | cksum | cut -d' ' -f1)"
  if [ -n "$(find "$STATE" -mmin -5 2>/dev/null)" ]; then continue; fi

  # List of doing tasks that still have incomplete subtasks
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
jq -n --arg ctx "An internal task has just been marked completed. If it corresponds to a subtask of one of the following .rime doing tasks, immediately change that subtask's status to done in tasks.json (the dashboard depends on this data):$REMIND" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
