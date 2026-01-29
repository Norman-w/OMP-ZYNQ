#!/usr/bin/env bash
# 通过 SSH 在 Windows 上执行 git add/commit/push，避免在挂载盘上跑 git 超时
# 仓库在 Windows 上的实际路径：D:\ZYNQ\Norman\OMP

set -e

USER="ws"
SERVERS=("192.168.7.88" "192.168.7.77")
WIN_REPO="D:/ZYNQ/Norman/OMP"

[[ -z "$*" ]] && echo "用法: $0 <commit message>" >&2 && exit 1
COMMIT_MSG="$*"
# 避免消息里的双引号破坏远程命令
COMMIT_MSG_ESC="${COMMIT_MSG//\"/\\\"}"

choose_server() {
  if command -v fzf &>/dev/null; then
    printf '%s\n' "${SERVERS[@]}" | fzf --height=6 --layout=reverse --prompt="选择服务器 > " --default-item="${SERVERS[0]}"
  else
    echo "1) ${SERVERS[0]} (默认)" >&2
    echo "2) ${SERVERS[1]}" >&2
    printf '请选择 [1]: ' >&2
    read -r reply
    r="${reply//[$'\r\n']}"
    r="${r// }"
    case "$r" in
      ''|1) echo "${SERVERS[0]}" ;;
      2)    echo "${SERVERS[1]}" ;;
      *)    echo "无效，使用默认 ${SERVERS[0]}" >&2; echo "${SERVERS[0]}" ;;
    esac
  fi
}

SERVER=$(choose_server)
SERVER="${SERVER//[$'\r\n']}"
[[ -z "$SERVER" ]] && exit 1

echo "在 ${USER}@${SERVER} 上执行 git add/commit/push ..." >&2
ssh "${USER}@${SERVER}" "cd $WIN_REPO && git add scripts/ && git commit -m \"$COMMIT_MSG_ESC\" && git push"
