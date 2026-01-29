#!/usr/bin/env bash
# 把本机 SSH 公钥拷到指定的一台 Windows 服务器，实现免密登录
# 77 和 88 不能同时连（一个走 VPN、一个直连局域网），每次运行选一台配置

set -e

USER="ws"
SERVERS=("192.168.7.88" "192.168.7.77")
PUBKEY="${HOME}/.ssh/id_ed25519.pub"

if [[ ! -f "$PUBKEY" ]]; then
  echo "未找到公钥 $PUBKEY"
  echo "请先生成密钥: ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519"
  exit 1
fi

choose_server() {
  if command -v fzf &>/dev/null; then
    printf '%s\n' "${SERVERS[@]}" | fzf --height=6 --layout=reverse --prompt="选择要配置的服务器 > " --default-item="${SERVERS[0]}"
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

echo ">>> 配置 ${USER}@${SERVER}（会提示输入一次密码）" >&2
ssh-copy-id -i "$PUBKEY" "${USER}@${SERVER}"
