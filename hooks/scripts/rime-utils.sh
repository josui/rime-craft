#!/usr/bin/env bash
# Shared utility functions: .rime directory resolution (including worktree mapping) + git change matching
# The authoritative definition of the resolution order is in skills/rime-flow/data-contract.md, "Storage Location & Resolution Order"

# Map cwd to its equivalent path in the main checkout (main working tree)
# In a linked worktree, <wt>/apps/foo → <main>/apps/foo; in the main checkout, returned as-is
#
# .rime/ is project-global mutable state and is untracked; the authoritative copy exists only on the main-checkout side.
# We keep the relative part of cwd rather than returning the main-checkout root directly, so as not to break monorepos —
# when working in <wt>/apps/foo, it should resolve to <main>/apps/foo/.rime, not return
# every subproject's .rime/ across the whole monorepo.
# In the main-checkout case the return value == cwd, so behavior is byte-identical to before this mapping was introduced.
#
# Usage: rime_resolve_base "$CWD"
rime_resolve_base() {
  local cwd="$1"
  local git_dir git_common wt_root main_root rel

  # --path-format=absolute normalizes both sides: at the repo root, --git-dir returns the relative path .git
  # (git ≥ 2.31); without normalization it cannot be reliably compared against --git-common-dir
  git_dir=$(cd "$cwd" 2>/dev/null && git rev-parse --path-format=absolute --git-dir 2>/dev/null) || true
  git_common=$(cd "$cwd" 2>/dev/null && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || true

  # Not a git repo, or not inside a linked worktree (the two are equal) → return as-is
  if [ -z "$git_dir" ] || [ -z "$git_common" ] || [ "$git_dir" = "$git_common" ]; then
    echo "$cwd"
    return 0
  fi

  wt_root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || true
  main_root=$(dirname "$git_common")

  # main_root must be a genuine main checkout: under a bare-repo + worktree layout,
  # dirname(git_common) is just the bare repo's parent directory and has no .git, so mapping isn't valid here
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

# Find .rime directories
# Order: $RIME_DIR → <base>/.rime → search downward under <base> (monorepo)
#        base is cwd after mapping through rime_resolve_base
# Usage: find_rime_dirs "$CWD"
# Output: one absolute .rime directory path per line
find_rime_dirs() {
  local cwd="$1"
  local base

  # Explicit override (CI / special cases)
  if [ -n "${RIME_DIR:-}" ] && [ -d "$RIME_DIR" ]; then
    echo "$RIME_DIR"
    return 0
  fi

  base=$(rime_resolve_base "$cwd")

  # Single project: direct hit
  if [ -d "$base/.rime" ]; then
    echo "$base/.rime"
    return 0
  fi

  # Monorepo: search downward (excluding heavy directories, depth limited to 4)
  find "$base" -maxdepth 4 -name ".rime" -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/.worktrees/*" \
    -not -path "*/vendor/*" 2>/dev/null | sort
}

# Determine whether a .rime directory matches the git-changed files
# Usage: rime_matches_changes "$RIME_DIR" "$CWD" "$CHANGED_FILES"
#   CHANGED_FILES = newline-separated list of relative paths
# Returns: 0=match, 1=no match
rime_matches_changes() {
  local rime_dir="$1"
  local cwd="$2"
  local changed="$3"
  local parent base
  parent=$(dirname "$rime_dir")
  # Compare on the same side as find_rime_dirs: in a worktree, rime_dir lives on the main-checkout side,
  # so using cwd directly as the prefix would never match, causing session-end to silently skip
  base=$(rime_resolve_base "$cwd")

  # .rime at the root → matches all changes
  if [ "$parent" = "$base" ]; then
    return 0
  fi

  # .rime in a subdirectory → check whether the changed files fall under that subdirectory
  # Pure shell prefix comparison, to avoid characters like . in the path being interpreted as regex (e.g. tools.old wrongly matching toolsXold/)
  # changed is relative to the worktree root, rel_parent is relative to the main-checkout root —
  # the mapping preserves the relative part, so the two are at the same relative level and can be compared directly
  local rel_parent="${parent#"$base"/}"
  local line
  while IFS= read -r line; do
    case "$line" in
      "$rel_parent"/*) return 0 ;;
    esac
  done <<< "$changed"
  return 1
}

# Get the list of git-changed files (relative to CWD)
# Usage: get_changed_files "$CWD"
# Output: newline-separated relative paths
get_changed_files() {
  local cwd="$1"
  cd "$cwd" 2>/dev/null || return 1
  {
    git diff --name-only HEAD 2>/dev/null
    git diff --name-only --cached 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
}

# Extract a subproject label from a .rime path
# /Users/x/mono/tools/.rime → tools
# /Users/x/mono/apps/kura/.rime → apps/kura
# /Users/x/project/.rime → (empty, i.e. the root project)
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
