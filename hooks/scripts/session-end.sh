#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-end: $*" >> "$LOG"; }

# 0. Recursion guard: when the worker's claude -p invocation exits, it also triggers the SessionEnd hook
if [ "${RIME_HOOK_WORKER:-}" = "1" ]; then exit 0; fi

# Dependency precheck: without jq, the whole pipeline cannot work — log and exit
command -v jq >/dev/null 2>&1 || { log "exit: jq not found in PATH"; exit 0; }

# 1. Read stdin (must happen in the foreground — stdin can only be read once)
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$CWD" ]; then log "exit: no cwd"; exit 0; fi
if [ -z "$TRANSCRIPT" ]; then log "exit: no transcript_path"; exit 0; fi
if [ ! -f "$TRANSCRIPT" ]; then log "exit: transcript not found: $TRANSCRIPT"; exit 0; fi

# 2. Load utility functions + find .rime directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rime-utils.sh"

RIME_DIRS=$(find_rime_dirs "$CWD")
if [ -z "$RIME_DIRS" ]; then log "exit: no .rime/ found under $CWD"; exit 0; fi
log "found .rime dirs: $(echo "$RIME_DIRS" | tr '\n' ' ')"

# 3. Timestamps
TIMESTAMP=$(date +%Y-%m-%dT%H-%M-%S)
TIMESTAMP_ISO=$(date +%Y-%m-%dT%H:%M:%S%z)
TODAY=$(date +%Y-%m-%d)

# 4. Determine which .rime directories need processing
#    get_changed_files runs 3 git commands in a large repo — only called on the monorepo branch
RIME_DIR_COUNT=$(echo "$RIME_DIRS" | wc -l | tr -d ' ')
TARGET_DIRS=""
if [ "$RIME_DIR_COUNT" -eq 1 ]; then
  # Single directory: always process (backward compatible)
  TARGET_DIRS="$RIME_DIRS"
else
  CHANGED_FILES=$(get_changed_files "$CWD" || echo "")
  if [ -n "$CHANGED_FILES" ]; then
    # Monorepo + has git changes: match changed files to .rime directories
    while IFS= read -r rd; do
      if rime_matches_changes "$rd" "$CWD" "$CHANGED_FILES"; then
        TARGET_DIRS="${TARGET_DIRS:+$TARGET_DIRS
}$rd"
      fi
    done <<< "$RIME_DIRS"
    log "matched .rime dirs by git changes: $(echo "$TARGET_DIRS" | tr '\n' ' ')"
  else
    # Monorepo + no git changes (pure discussion): process all directories
    TARGET_DIRS="$RIME_DIRS"
    log "no git changes, processing all .rime dirs"
  fi
fi

if [ -z "$TARGET_DIRS" ]; then log "exit: no matching .rime dirs"; exit 0; fi

# 5. Spawn a background worker for each target (transcript filtering / minimal-anchor decision / claude -p — all pushed to background)
#    The foreground only does stdin reading + .rime discovery + spawning, to avoid being killed by the hook timeout on large transcripts
while IFS= read -r RIME_DIR; do
  [ -z "$RIME_DIR" ] && continue
  if [ ! -f "$RIME_DIR/tasks.json" ]; then
    log "skip: no tasks.json in $RIME_DIR"
    continue
  fi

  LABEL=$(rime_label "$RIME_DIR" "$CWD")
  log "spawning worker for ${LABEL:-root} ($RIME_DIR)"
  nohup "$SCRIPT_DIR/session-end-worker.sh" \
    "$RIME_DIR" "$TIMESTAMP" "$TIMESTAMP_ISO" "$TODAY" "$TRANSCRIPT" \
    </dev/null >>"$LOG" 2>&1 &
  disown
  log "background worker spawned for ${LABEL:-root} (pid=$!)"

done <<< "$TARGET_DIRS"
