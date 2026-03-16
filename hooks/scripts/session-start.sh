#!/usr/bin/env bash
set -euo pipefail

# 1. 读取 stdin 获取 cwd
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

# 2. 检查 .rime/ 是否存在
RIME_DIR="$CWD/.rime"
[ -d "$RIME_DIR" ] || exit 0

# 3. 读取 phase
PHASE_CURRENT=$(jq -r '.current // empty' "$RIME_DIR/phase.json" 2>/dev/null || echo "")
PHASE_NAME=""
if [ -n "$PHASE_CURRENT" ]; then
  PHASE_NAME=$(jq -r --arg id "$PHASE_CURRENT" '.phases[] | select(.id == $id) | .name // empty' "$RIME_DIR/phase.json" 2>/dev/null || echo "")
fi

# 4. 读取 doing tasks
DOING_TASKS=""
if [ -f "$RIME_DIR/tasks.json" ]; then
  DOING_TASKS=$(jq -r '
    .items[] | select(.status == "doing") |
    "- \(.id) \(.title) (doing)\(
      if (.subtasks | length) > 0 then
        " — subtasks: \([.subtasks[] | if .status == "done" then "\(.title) ✅" else .title end] | join(", "))"
      else ""
      end
    )"
  ' "$RIME_DIR/tasks.json" 2>/dev/null || echo "")
fi

# 5. 读取最新 anchor
LATEST_ANCHOR=""
if [ -d "$RIME_DIR/anchors" ]; then
  LATEST_ANCHOR=$(ls -t "$RIME_DIR/anchors/"*.json 2>/dev/null | head -1 || echo "")
fi

# 6. 读取 cautions（当 cautions 少时全部展示，多时按 tag 匹配过滤）
CAUTIONS=""
if [ -f "$RIME_DIR/cautions.json" ] && [ -s "$RIME_DIR/cautions.json" ]; then
  CAUTION_COUNT=$(jq 'length' "$RIME_DIR/cautions.json" 2>/dev/null || echo "0")
  if [ "$CAUTION_COUNT" -gt 0 ] 2>/dev/null; then
    if [ "$CAUTION_COUNT" -le 5 ]; then
      # 5 条以内全部展示
      CAUTIONS=$(jq -r '.[] | "- \(.id): \(.summary)"' "$RIME_DIR/cautions.json" 2>/dev/null || echo "")
    else
      # 超过 5 条，按 doing task 的 title 关键词匹配 tags
      TASK_WORDS=$(jq -r '.items[] | select(.status == "doing") | .title' "$RIME_DIR/tasks.json" 2>/dev/null | tr '  ' '\n' | tr '[:upper:]' '[:lower:]' | sort -u | jq -R . | jq -s '.')
      CAUTIONS=$(jq -r --argjson words "$TASK_WORDS" '
        [.[] | select(
          [.tags[]? | ascii_downcase] as $tags |
          any($words[]; . as $w | any($tags[]; contains($w)))
        )] | .[] | "- \(.id): \(.summary)"
      ' "$RIME_DIR/cautions.json" 2>/dev/null || echo "")
    fi
  fi
fi

# 7. 组装输出（只在有内容时输出）
HAS_CONTENT=false

OUTPUT="## Rime Context"
OUTPUT="$OUTPUT"$'\n'

if [ -n "$PHASE_CURRENT" ]; then
  OUTPUT="$OUTPUT"$'\n'"**Phase**: $PHASE_CURRENT — $PHASE_NAME"
  HAS_CONTENT=true
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

if [ -n "$DOING_TASKS" ]; then
  OUTPUT="$OUTPUT"$'\n'"**活跃任务**:"
  OUTPUT="$OUTPUT"$'\n'"$DOING_TASKS"
  OUTPUT="$OUTPUT"$'\n'
  HAS_CONTENT=true
fi

if [ -n "$CAUTIONS" ]; then
  OUTPUT="$OUTPUT"$'\n'"**注意事项**:"
  OUTPUT="$OUTPUT"$'\n'"$CAUTIONS"
  HAS_CONTENT=true
fi

# 只有有内容时才输出
if [ "$HAS_CONTENT" = true ]; then
  echo "$OUTPUT"
fi
