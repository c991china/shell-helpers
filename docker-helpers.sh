#!/usr/bin/env bash
# 容器相关辅助函数
dk_clean() {
  # 删除所有已停止的容器与悬空镜像
  docker container prune -f
  docker image prune -f
  echo "已清理停止的容器与悬空镜像"
}

dk_shell() {
  # 进入某个运行中容器的 shell：dk_shell <容器名>
  local c="${1:?用法: dk_shell <容器名>}"
  docker exec -it "$c" /bin/sh
}
