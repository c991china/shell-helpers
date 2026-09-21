#!/usr/bin/env bash
# 由 @22178384 贡献：Git 相关的 shell 辅助函数，配合 shell-helpers 使用。

git_current_branch() {
  git rev-parse --abbrev-ref HEAD
}

git_main_branch() {
  git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main
}

git_clean_workdir() {
  if [ -n "$(git status --porcelain)" ]; then
    echo "工作区不干净，请先提交或暂存。"
    return 1
  fi
  echo "工作区干净。"
}
