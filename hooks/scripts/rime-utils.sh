#!/usr/bin/env bash
# 共享工具函数：.rime 目录解析（含 worktree 映射）+ git 变更匹配
# 解析顺序的权威定义见 skills/rime-flow/data-contract.md「存储位置与解析顺序」

# 把 cwd 映射到主检出（main working tree）的等价路径
# linked worktree 中 <wt>/apps/foo → <main>/apps/foo；主检出中原样返回
#
# .rime/ 是项目全局的可变状态且不入库，权威副本只存在于主检出侧。
# 保留 cwd 的相对部分而非直接返回主检出根，是为了不破坏 monorepo——
# 在 <wt>/apps/foo 工作时应解析到 <main>/apps/foo/.rime，而不是把整个
# monorepo 的所有子项目 .rime/ 都返回。
# 主检出场景下返回值 == cwd，故行为与映射引入前逐字节一致。
#
# 用法: rime_resolve_base "$CWD"
rime_resolve_base() {
  local cwd="$1"
  local git_dir git_common wt_root main_root rel

  # --path-format=absolute 归一化两侧：--git-dir 在仓库根会返回相对路径 .git
  # （git ≥ 2.31），不归一化则无法与 --git-common-dir 可靠比较
  git_dir=$(cd "$cwd" 2>/dev/null && git rev-parse --path-format=absolute --git-dir 2>/dev/null) || true
  git_common=$(cd "$cwd" 2>/dev/null && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || true

  # 非 git，或不在 linked worktree 中（两者相等）→ 原样返回
  if [ -z "$git_dir" ] || [ -z "$git_common" ] || [ "$git_dir" = "$git_common" ]; then
    echo "$cwd"
    return 0
  fi

  wt_root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || true
  main_root=$(dirname "$git_common")

  # main_root 必须是一个真正的主检出：bare repo + worktree 布局下
  # dirname(git_common) 只是 bare 仓库的父目录，不含 .git，此时不可映射
  if [ -z "$wt_root" ] || [ ! -e "$main_root/.git" ]; then
    echo "$cwd"
    return 0
  fi

  rel="${cwd#"$wt_root"}"
  rel="${rel#/}"
  if [ -n "$rel" ]; then
    echo "$main_root/$rel"
  else
    echo "$main_root"
  fi
}

# 查找 .rime 目录
# 顺序: $RIME_DIR → <base>/.rime → <base> 下向下搜索（monorepo）
#       base 为 cwd 经 rime_resolve_base 映射后的路径
# 用法: find_rime_dirs "$CWD"
# 输出: 每行一个 .rime 目录的绝对路径
find_rime_dirs() {
  local cwd="$1"
  local base

  # 显式覆盖（CI / 特殊场景）
  if [ -n "${RIME_DIR:-}" ] && [ -d "$RIME_DIR" ]; then
    echo "$RIME_DIR"
    return 0
  fi

  base=$(rime_resolve_base "$cwd")

  # 单项目：直接命中
  if [ -d "$base/.rime" ]; then
    echo "$base/.rime"
    return 0
  fi

  # Monorepo：向下搜索（排除重目录，限深度 4）
  find "$base" -maxdepth 4 -name ".rime" -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/.worktrees/*" \
    -not -path "*/vendor/*" 2>/dev/null | sort
}

# 判断 .rime 目录是否匹配 git 变更文件
# 用法: rime_matches_changes "$RIME_DIR" "$CWD" "$CHANGED_FILES"
#   CHANGED_FILES = 换行分隔的相对路径列表
# 返回: 0=匹配, 1=不匹配
rime_matches_changes() {
  local rime_dir="$1"
  local cwd="$2"
  local changed="$3"
  local parent base
  parent=$(dirname "$rime_dir")
  # 与 find_rime_dirs 同侧比较：worktree 中 rime_dir 位于主检出侧，
  # 直接拿 cwd 做前缀会永不匹配，导致 session-end 静默跳过
  base=$(rime_resolve_base "$cwd")

  # 根目录的 .rime → 匹配所有变更
  if [ "$parent" = "$base" ]; then
    return 0
  fi

  # 子目录的 .rime → 检查变更文件是否在该子目录下
  # 纯 shell 前缀比较，避免路径中的 . 等字符被当正则解释（如 tools.old 误匹配 toolsXold/）
  # changed 是相对 worktree 根的路径，rel_parent 是相对主检出根的路径——
  # 映射保留了相对部分，故两者的相对层级一致，可直接比较
  local rel_parent="${parent#"$base"/}"
  local line
  while IFS= read -r line; do
    case "$line" in
      "$rel_parent"/*) return 0 ;;
    esac
  done <<< "$changed"
  return 1
}

# 获取 git 变更文件列表（相对于 CWD）
# 用法: get_changed_files "$CWD"
# 输出: 换行分隔的相对路径
get_changed_files() {
  local cwd="$1"
  cd "$cwd" 2>/dev/null || return 1
  {
    git diff --name-only HEAD 2>/dev/null
    git diff --name-only --cached 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
}

# 从 .rime 路径提取子项目标签
# /Users/x/mono/tools/.rime → tools
# /Users/x/mono/apps/kura/.rime → apps/kura
# /Users/x/project/.rime → (空，即根项目)
rime_label() {
  local rime_dir="$1"
  local cwd="$2"
  local parent base
  parent=$(dirname "$rime_dir")
  base=$(rime_resolve_base "$cwd")

  if [ "$parent" = "$base" ]; then
    echo ""
  else
    echo "${parent#"$base"/}"
  fi
}
