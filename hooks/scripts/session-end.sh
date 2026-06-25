#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.rime-hook.log"
log() { echo "[$(date +%H:%M:%S)] session-end: $*" >> "$LOG"; }

# 0. 递归检测：worker 调用的 claude -p 退出时也会触发 SessionEnd hook
if [ "${RIME_HOOK_WORKER:-}" = "1" ]; then exit 0; fi

# 依赖预检：jq 缺失时整条管线无法工作，留痕后退出
command -v jq >/dev/null 2>&1 || { log "exit: jq not found in PATH"; exit 0; }

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
TIMESTAMP=$(date +%Y-%m-%dT%H-%M-%S)
TIMESTAMP_ISO=$(date +%Y-%m-%dT%H:%M:%S%z)
TODAY=$(date +%Y-%m-%d)

# 4. 确定哪些 .rime 目录需要处理
#    get_changed_files 在大仓库要跑 3 个 git 命令，仅在 monorepo 分支才调
RIME_DIR_COUNT=$(echo "$RIME_DIRS" | wc -l | tr -d ' ')
TARGET_DIRS=""
if [ "$RIME_DIR_COUNT" -eq 1 ]; then
  # 单目录：始终处理（向后兼容）
  TARGET_DIRS="$RIME_DIRS"
else
  CHANGED_FILES=$(get_changed_files "$CWD" || echo "")
  if [ -n "$CHANGED_FILES" ]; then
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
fi

if [ -z "$TARGET_DIRS" ]; then log "exit: no matching .rime dirs"; exit 0; fi

# 5. 每个目标 spawn 后台 worker（transcript 过滤 / minimal 判定 / claude -p 全下放后台）
#    前台只做 stdin 读取 + .rime 发现 + spawn，避免大 transcript 下被 hook 超时杀掉
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
