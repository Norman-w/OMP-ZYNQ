#!/usr/bin/env bash
# 把本机 SSH 公钥拷到指定的一台 Windows 服务器，实现免密登录
# 77 和 88 不能同时连（一个走 VPN、一个直连局域网），每次运行选一台配置

set -e

DEFAULT_USER="ws"
SERVERS=("192.168.46.128" "192.168.7.77")
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
    echo "1) ${DEFAULT_USER}@${SERVERS[0]} (默认)" >&2
    echo "2) ${DEFAULT_USER}@${SERVERS[1]}" >&2
    echo "3) 手动输入IP地址" >&2
    echo "4) 输入 user@ip 格式（例如: uisrc@192.168.46.128）" >&2
    printf '请选择 [1]: ' >&2
    read -r reply
    r="${reply//[$'\r\n']}"
    r="${r// }"
    case "$r" in
      ''|1) echo "${DEFAULT_USER}@${SERVERS[0]}" ;;
      2)    echo "${DEFAULT_USER}@${SERVERS[1]}" ;;
      3)    printf '请输入IP地址 [默认用户: %s]: ' "$DEFAULT_USER" >&2
            read -r ip_input
            ip="${ip_input//[$'\r\n']}"
            ip="${ip// }"
            if [[ -n "$ip" ]]; then
              printf '请输入用户名 [默认: %s]: ' "$DEFAULT_USER" >&2
              read -r user_input
              user="${user_input//[$'\r\n']}"
              user="${user// }"
              if [[ -z "$user" ]]; then
                user="$DEFAULT_USER"
              fi
              echo "${user}@${ip}"
            else
              echo "无效IP，使用默认 ${DEFAULT_USER}@${SERVERS[0]}" >&2
              echo "${DEFAULT_USER}@${SERVERS[0]}"
            fi
            ;;
      4)    printf '请输入 user@ip (例如: uisrc@192.168.46.128): ' >&2
            read -r userip_input
            userip="${userip_input//[$'\r\n']}"
            userip="${userip// }"
            if [[ -n "$userip" ]]; then
              echo "$userip"
            else
              echo "无效输入，使用默认 ${DEFAULT_USER}@${SERVERS[0]}" >&2
              echo "${DEFAULT_USER}@${SERVERS[0]}"
            fi
            ;;
      *)    # 检查是否是 user@ip 格式
            if [[ "$r" =~ ^[a-zA-Z0-9_-]+@[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
              echo "$r"
            # 检查是否是IP地址格式（使用默认用户）
            elif [[ "$r" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
              echo "${DEFAULT_USER}@${r}"
            else
              echo "无效，使用默认 ${DEFAULT_USER}@${SERVERS[0]}" >&2
              echo "${DEFAULT_USER}@${SERVERS[0]}"
            fi
            ;;
    esac
  fi
}

TARGET=$(choose_server)
TARGET="${TARGET//[$'\r\n']}"
[[ -z "$TARGET" ]] && exit 1

# 从TARGET中提取IP地址
TARGET_IP=$(echo "$TARGET" | sed 's/.*@//')

# 检查并删除known_hosts中的旧密钥（如果存在）
if ssh-keygen -F "$TARGET_IP" &>/dev/null; then
  echo "⚠️  检测到旧的主机密钥，正在删除..." >&2
  ssh-keygen -R "$TARGET_IP" &>/dev/null || true
  echo "✅ 已删除旧的主机密钥" >&2
fi

echo ">>> 配置 ${TARGET}（会提示输入一次密码）" >&2
ssh-copy-id -i "$PUBKEY" "${TARGET}"
