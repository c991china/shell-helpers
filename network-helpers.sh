#!/usr/bin/env bash
# 网络相关辅助函数
my_ip() {
  # 打印本机出口公网 IP
  curl -sS https://api.ipify.org || echo "获取失败"
}

wait_port() {
  # 等待某主机端口就绪：wait_port host port
  local h="${1:?}" p="${2:?}"
  for _ in $(seq 1 30); do
    if (echo > "/dev/tcp/$h/$p") >/dev/null 2>&1; then
      echo "$h:$p 已就绪"; return 0
    fi
    sleep 1
  done
  echo "$h:$p 超时"; return 1
}
