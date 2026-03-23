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
if [ ! -f "$TRANSCRIPT" ]; then log "exit: transcript not found: $TRANSCRIPT"; exit 0; fi

# 2. 加载工具函数 + 查找 .rime 目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rime-utils.sh"

RIME_DIRS=$(find_rime_dirs "$CWD")
if [ -z "$RIME_DIRS" ]; then log "exit: no .rime/ found under $CWD"; exit 0; fi
log "found .rime dirs: $(echo "$RIME_DIRS" | tr '\n' ' ')"

# 3. 时间戳
TIMESTAMP=$(date +%Y-%m-%dT%H-%M)
TIMESTAMP_ISO=$(date +%Y-%m-%dT%H:%M:%S%z)
TODAY=$(date +%Y-%m-%d)

# 4. 过滤 transcript
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

# 5. 确定哪些 .rime 目录需要处理
CHANGED_FILES=$(get_changed_files "$CWD" || echo "")
RIME_DIR_COUNT=$(echo "$RIME_DIRS" | wc -l | tr -d ' ')

TARGET_DIRS=""
if [ "$RIME_DIR_COUNT" -eq 1 ]; then
  # 单目录：始终处理（向后兼容）
  TARGET_DIRS="$RIME_DIRS"
elif [ -n "$CHANGED_FILES" ]; then
  # Monorepo + 有 git 变更：匹配变更文件到 .rime 目录
  while IFS= read -r rd; do
    if rime_matches_changes "$rd" "$CWD" "$CHANGED_FILES"; then
      TARGET_DIRS="${TARGET_DIRS:+$TARGET_DIRS
}$rd"
    fi
  done <<< "$RIME_DIRS"
  log "matched .rime dirs by git changes: $(echo "$TARGET_DIRS" | tr '\n' ' ')"
else
  # Monorepo + 无 git 变更（纯讨论）：处理所有目录
  TARGET_DIRS="$RIME_DIRS"
  log "no git changes, processing all .rime dirs"
fi

if [ -z "$TARGET_DIRS" ]; then log "exit: no matching .rime dirs"; exit 0; fi

# 6. 对每个目标 .rime 目录生成 anchor
while IFS= read -r RIME_DIR; do
  [ -z "$RIME_DIR" ] && continue
  if [ ! -f "$RIME_DIR/tasks.json" ]; then
    log "skip: no tasks.json in $RIME_DIR"
    continue
  fi

  PHASE=$(jq -r '.current // "unknown"' "$RIME_DIR/phase.json" 2>/dev/null || echo "unknown")
  mkdir -p "$RIME_DIR/anchors"

  # 空对话 → minimal anchor（同步写，很快）
  if [ -z "$FILTERED" ] || [ "$FILTERED_LINES" -lt 2 ]; then
    log "minimal anchor: $RIME_DIR (filtered_lines=$FILTERED_LINES)"
    jq -n --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{
      timestamp: $ts, phase: $ph,
      workedOn: [], subtasksCompleted: [], subtasksAdded: [],
      decisions: [], nextSteps: [], cautions: []
    }' > "$RIME_DIR/anchors/$TIMESTAMP.json"
    continue
  fi

  # 准备临时文件传递数据给 worker
  WORK_DIR=$(mktemp -d)
  echo "$FILTERED" > "$WORK_DIR/filtered.txt"
  cp "$RIME_DIR/tasks.json" "$WORK_DIR/tasks.json"

  # 启动后台 worker
  LABEL=$(rime_label "$RIME_DIR" "$CWD")
  log "spawning worker for ${LABEL:-root} ($RIME_DIR)"
  nohup "$SCRIPT_DIR/session-end-worker.sh" \
    "$RIME_DIR" "$TIMESTAMP" "$TIMESTAMP_ISO" "$TODAY" "$PHASE" "$WORK_DIR" \
    </dev/null >>"$LOG" 2>&1 &
  disown
  log "background worker spawned for ${LABEL:-root} (pid=$!)"

done <<< "$TARGET_DIRS"
