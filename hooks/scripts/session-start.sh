#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-start: $*" >> "$LOG"; }

# Dependency precheck: without jq, context injection cannot work — log and exit
command -v jq >/dev/null 2>&1 || { log "exit: jq not found in PATH"; exit 0; }

# 1. Read stdin to get cwd
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ]; then log "exit: no cwd"; exit 0; fi

# 2. Load utility functions + find .rime directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rime-utils.sh"

RIME_DIRS=$(find_rime_dirs "$CWD")
if [ -z "$RIME_DIRS" ]; then log "exit: no .rime/ in $CWD"; exit 0; fi
log "start: cwd=$CWD dirs=$(echo "$RIME_DIRS" | tr '\n' ' ')"

RIME_DIR_COUNT=$(echo "$RIME_DIRS" | wc -l | tr -d ' ')
IS_MONO=false
[ "$RIME_DIR_COUNT" -gt 1 ] && IS_MONO=true

# 3. Generate a context fragment for each .rime directory
HAS_CONTENT=false
OUTPUT="## Rime Context"
OUTPUT="$OUTPUT"$'\n'

while IFS= read -r RIME_DIR; do
  [ -z "$RIME_DIR" ] && continue

  LABEL=$(rime_label "$RIME_DIR" "$CWD")

  # In monorepo mode, add a subproject heading
  if [ "$IS_MONO" = true ] && [ -n "$LABEL" ]; then
    OUTPUT="$OUTPUT"$'\n'"### $LABEL"
  fi

  # Read phase
  PHASE_CURRENT=$(jq -r '.current // empty' "$RIME_DIR/phase.json" 2>/dev/null || echo "")
  PHASE_NAME=""
  if [ -n "$PHASE_CURRENT" ]; then
    PHASE_NAME=$(jq -r --arg id "$PHASE_CURRENT" '.phases[] | select(.id == $id) | .name // empty' "$RIME_DIR/phase.json" 2>/dev/null || echo "")
  fi

  if [ -n "$PHASE_CURRENT" ]; then
    OUTPUT="$OUTPUT"$'\n'"**Phase**: $PHASE_CURRENT — $PHASE_NAME"
    HAS_CONTENT=true
  fi

  # Live checklist of incomplete subtasks for doing tasks (visibility → improves real-time sync rate)
  DOING_LIST=""
  if [ -f "$RIME_DIR/tasks.json" ]; then
    DOING_LIST=$(jq -r '
      (.items // [])[]
      | select(.status == "doing")
      | "- \(.id) \(.title)" +
        ((.subtasks // []) | map(select(.status != "done")) |
          if length > 0 then "\n" + (map("  - [ ] " + .title) | join("\n")) else "" end)
    ' "$RIME_DIR/tasks.json" 2>/dev/null || echo "")
  fi

  if [ -n "$DOING_LIST" ]; then
    OUTPUT="$OUTPUT"$'\n'"**In progress**:"$'\n'"$DOING_LIST"
    HAS_CONTENT=true
  fi

  # Read the latest anchor
  LATEST_ANCHOR=""
  if [ -d "$RIME_DIR/anchors" ]; then
    LATEST_ANCHOR=$(ls -t "$RIME_DIR/anchors/"*.json 2>/dev/null | head -1 || echo "")
  fi

  if [ -n "$LATEST_ANCHOR" ]; then
    ANCHOR_TIME=$(jq -r '.timestamp // empty' "$LATEST_ANCHOR" 2>/dev/null | cut -c1-16 | tr 'T' ' ')
    ANCHOR_WORKED=$(jq -r '(.workedOn // []) | join(", ")' "$LATEST_ANCHOR" 2>/dev/null || echo "")
    ANCHOR_DECISIONS=$(jq -r '(.decisions // [])[] | "- Decision: \(.)"' "$LATEST_ANCHOR" 2>/dev/null || echo "")
    ANCHOR_NEXT=$(jq -r '(.nextSteps // [])[]' "$LATEST_ANCHOR" 2>/dev/null || echo "")

    if [ -n "$ANCHOR_TIME" ]; then
      OUTPUT="$OUTPUT"$'\n'"**Last session** ($ANCHOR_TIME):"
      [ -n "$ANCHOR_WORKED" ] && OUTPUT="$OUTPUT"$'\n'"- Touched: $ANCHOR_WORKED"
      [ -n "$ANCHOR_DECISIONS" ] && OUTPUT="$OUTPUT"$'\n'"$ANCHOR_DECISIONS"
      if [ -n "$ANCHOR_NEXT" ]; then
        OUTPUT="$OUTPUT"$'\n'"**Next steps**:"
        while IFS= read -r line; do
          OUTPUT="$OUTPUT"$'\n'"- $line"
        done <<< "$ANCHOR_NEXT"
      fi
      OUTPUT="$OUTPUT"$'\n'
      HAS_CONTENT=true
    fi
  fi

done <<< "$RIME_DIRS"

# 4. tasks.json sync reminder
OUTPUT="$OUTPUT"$'\n'
OUTPUT="$OUTPUT"$'\n'"**tasks.json sync rules**: Starting a task (including grill / design phase) → set status=doing and overwrite commitFrom (git rev-parse HEAD); **mark each subtask done the moment it's finished** (the dashboard depends on this — don't batch them up); when a spec/prototype output is persisted to disk → immediately backfill docs:[{type,path}]; the verification checklist must **first be written into the spec's verification section, then presented to the user** (persist to disk before presenting; the presentation includes the spec path and is delivered in the user's conversation language); a small task requires a pre-dispatch brief confirmed by the user before dispatching (visual/style small upgrades to an HTML spec); completing a task → present the verification checklist and **wait for the user to verify and confirm OK** (implementing and marking done in the same turn, with no user reply in between, is prohibited), then pass the commit gate (changes committed, HEAD ≠ commitFrom, zero commits must not be marked done; exempt for non-git projects or when every deliverable is untracked-by-design and user-confirmed — remove commitFrom, write no commits), with done + completedAt + commits{from,to} written in the same write — backfilling after done is prohibited. Only fields listed in the data-contract.md field table may be written; inventing new fields is prohibited. When unsure, load the rime-flow skill first."
HAS_CONTENT=true

# 5. Output
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
