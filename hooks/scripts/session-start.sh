#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-start: $*" >> "$LOG"; }

# 1. 读取 stdin 获取 cwd
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ]; then log "exit: no cwd"; exit 0; fi

# 2. 加载工具函数 + 查找 .rime 目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rime-utils.sh"

RIME_DIRS=$(find_rime_dirs "$CWD")
if [ -z "$RIME_DIRS" ]; then log "exit: no .rime/ in $CWD"; exit 0; fi
log "start: cwd=$CWD dirs=$(echo "$RIME_DIRS" | tr '\n' ' ')"

RIME_DIR_COUNT=$(echo "$RIME_DIRS" | wc -l | tr -d ' ')
IS_MONO=false
[ "$RIME_DIR_COUNT" -gt 1 ] && IS_MONO=true

# 3. 对每个 .rime 目录生成 context 片段
HAS_CONTENT=false
OUTPUT="## Rime Context"
OUTPUT="$OUTPUT"$'\n'

while IFS= read -r RIME_DIR; do
  [ -z "$RIME_DIR" ] && continue

  LABEL=$(rime_label "$RIME_DIR" "$CWD")

  # Monorepo 模式下加子项目标题
  if [ "$IS_MONO" = true ] && [ -n "$LABEL" ]; then
    OUTPUT="$OUTPUT"$'\n'"### $LABEL"
  fi

  # 读取 phase
  PHASE_CURRENT=$(jq -r '.current // empty' "$RIME_DIR/phase.json" 2>/dev/null || echo "")
  PHASE_NAME=""
  if [ -n "$PHASE_CURRENT" ]; then
    PHASE_NAME=$(jq -r --arg id "$PHASE_CURRENT" '.phases[] | select(.id == $id) | .name // empty' "$RIME_DIR/phase.json" 2>/dev/null || echo "")
  fi

  if [ -n "$PHASE_CURRENT" ]; then
    OUTPUT="$OUTPUT"$'\n'"**Phase**: $PHASE_CURRENT — $PHASE_NAME"
    HAS_CONTENT=true
  fi

  # 读取最新 anchor
  LATEST_ANCHOR=""
  if [ -d "$RIME_DIR/anchors" ]; then
    LATEST_ANCHOR=$(ls -t "$RIME_DIR/anchors/"*.json 2>/dev/null | head -1 || echo "")
  fi

  if [ -n "$LATEST_ANCHOR" ]; then
    ANCHOR_TIME=$(jq -r '.timestamp // empty' "$LATEST_ANCHOR" 2>/dev/null | cut -c1-16 | tr 'T' ' ')
    ANCHOR_WORKED=$(jq -r '(.workedOn // []) | join(", ")' "$LATEST_ANCHOR" 2>/dev/null || echo "")
    ANCHOR_DECISIONS=$(jq -r '(.decisions // [])[] | "- 决策: \(.)"' "$LATEST_ANCHOR" 2>/dev/null || echo "")
    ANCHOR_NEXT=$(jq -r '(.nextSteps // [])[]' "$LATEST_ANCHOR" 2>/dev/null || echo "")

    if [ -n "$ANCHOR_TIME" ]; then
      OUTPUT="$OUTPUT"$'\n'"**上次 session** ($ANCHOR_TIME):"
      [ -n "$ANCHOR_WORKED" ] && OUTPUT="$OUTPUT"$'\n'"- 涉及: $ANCHOR_WORKED"
      [ -n "$ANCHOR_DECISIONS" ] && OUTPUT="$OUTPUT"$'\n'"$ANCHOR_DECISIONS"
      if [ -n "$ANCHOR_NEXT" ]; then
        OUTPUT="$OUTPUT"$'\n'"**下一步**:"
        while IFS= read -r line; do
          OUTPUT="$OUTPUT"$'\n'"- $line"
        done <<< "$ANCHOR_NEXT"
      fi
      OUTPUT="$OUTPUT"$'\n'
      HAS_CONTENT=true
    fi
  fi

done <<< "$RIME_DIRS"

# 4. tasks.json 同步提醒
OUTPUT="$OUTPUT"$'\n'
OUTPUT="$OUTPUT"$'\n'"**tasks.json 同步规则**：开始执行 task 时将 status 更新为 doing，完成时更新为 done 并写入 completedAt。"
HAS_CONTENT=true

# 5. 输出
if [ "$HAS_CONTENT" = true ]; then
  log "output: dirs=$RIME_DIR_COUNT mono=$IS_MONO"
  jq -n --arg ctx "$OUTPUT" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
else
  log "no content to output"
fi
