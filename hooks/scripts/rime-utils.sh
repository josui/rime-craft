#!/usr/bin/env bash
# 共享工具函数：monorepo .rime 目录发现 + git 变更匹配

# 查找 .rime 目录
# 优先 $CWD/.rime（单项目），否则搜索子目录（monorepo）
# 用法: find_rime_dirs "$CWD"
# 输出: 每行一个 .rime 目录的绝对路径
find_rime_dirs() {
  local cwd="$1"

  # 单项目：直接命中
  if [ -d "$cwd/.rime" ]; then
    echo "$cwd/.rime"
    return 0
  fi

  # Monorepo：向下搜索（排除重目录，限深度 4）
  find "$cwd" -maxdepth 4 -name ".rime" -type d \
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
  local parent
  parent=$(dirname "$rime_dir")

  # 根目录的 .rime → 匹配所有变更
  if [ "$parent" = "$cwd" ]; then
    return 0
  fi

  # 子目录的 .rime → 检查变更文件是否在该子目录下
  local rel_parent="${parent#$cwd/}"
  echo "$changed" | grep -q "^${rel_parent}/" && return 0
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
  local parent
  parent=$(dirname "$rime_dir")

  if [ "$parent" = "$cwd" ]; then
    echo ""
  else
    echo "${parent#$cwd/}"
  fi
}
