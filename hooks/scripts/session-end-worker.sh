#!/usr/bin/env bash
set -euo pipefail

# Background worker: receives data prepared by the foreground script, runs claude -p, and writes the anchor
# Started by session-end.sh via nohup, not subject to the hook timeout

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

# Transcript filtering (heavy lifting pushed to background, to avoid the foreground being killed by the hook timeout)
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

# Empty conversation → minimal anchor, no need to call claude -p
if [ -z "$FILTERED" ] || [ "$FILTERED_LINES" -lt 2 ]; then
  log "minimal anchor: $RIME_DIR (filtered_lines=$FILTERED_LINES)"
  write_minimal_anchor
  exit 0
fi

TASKS=$(cat "$RIME_DIR/tasks.json")

# Call claude -p
PROMPT="You are a session-summarization assistant. Analyze the following conversation, cross-reference it with the current task list, and extract the key information.

Current task list:
$TASKS

Conversation:
$FILTERED

Output strict JSON (no markdown wrapping, no comments, no extra text):
{
  \"workedOn\": [\"#xxx\"],
  \"subtasksCompleted\": [\"work completed in this session (free-form description)\"],
  \"subtasksAdded\": [\"newly discovered subtasks (free-form description)\"],
  \"decisions\": [\"key decisions\"],
  \"nextSteps\": [\"next steps\"],
  \"cautions\": [{\"title\": \"pitfall title\", \"summary\": \"detailed description (optional)\", \"tags\": [\"tag1\"]}]
}

Rules:
- workedOn: only fill in task IDs that already exist in tasks.json
- subtasksCompleted: work completed in this session. If it corresponds to a subtask of a doing task, **repeat that subtask's title verbatim** (the system uses this to automatically reconcile it to done); otherwise, describe freely
- subtasksAdded: freely describe newly discovered subtasks (recorded for the session log only, not used for automatic status changes)
- Leave fields with nothing to report as empty arrays — do not invent content
- cautions: write the title and summary in English regardless of the conversation's language
- Output only the JSON, with no other text"

# perl alarm for timeout (macOS has no GNU timeout): on timeout, receives SIGALRM and exits, falling back to a minimal anchor
CLAUDE_TIMEOUT="${RIME_CLAUDE_TIMEOUT:-120}"
RAW=$(RIME_HOOK_WORKER=1 perl -e 'alarm shift @ARGV; exec @ARGV' "$CLAUDE_TIMEOUT" \
  claude -p --model haiku <<< "$PROMPT" 2>/dev/null || echo "")

# Extract JSON from the model output (may be wrapped in a markdown code block)
RESULT=$(echo "$RAW" | sed -n '/^```/,/^```/{ /^```/d; p; }' 2>/dev/null)
[ -z "$RESULT" ] && RESULT="$RAW"

# Invalid JSON → fall back to minimal anchor
if [ -z "$RESULT" ] || ! echo "$RESULT" | jq . >/dev/null 2>&1; then
  log "fallback: invalid JSON: $(echo "$RAW" | head -1)"
  write_minimal_anchor
  exit 0
fi
log "claude-p success"

# Write anchor
echo "$RESULT" | jq --arg ts "$TIMESTAMP_ISO" --arg ph "$PHASE" '{schemaVersion: 1} + . + {timestamp: $ts, phase: $ph}' > "$RIME_DIR/anchors/$TIMESTAMP.json"

# Conservative subtask reconciliation: limited to tasks in workedOn; when subtasksCompleted and the subtask title
# are exactly equal or mutual substrings, flip to done (only forward, never reverts). Semantics documented in rime-flow/data-contract.md
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

# Append cautions
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
