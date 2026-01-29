#!/usr/bin/env bash
# 从远程 Windows 服务器拉取 BOOT.BIN 到 SD 卡根目录，完成后安全弹出读卡器
# 使用前请确保已配置免密登录 (ssh-copy-id ws@192.168.7.xx)

set -e

USER="ws"
REMOTE_PATH="/d/ZYNQ/Norman/OMP/PS/App_system/Debug/sd_card/BOOT.BIN"
SERVERS=("192.168.7.88" "192.168.7.77")
SD_VOLUME_NAME="root"
SD_MOUNT="/Volumes/${SD_VOLUME_NAME}"

# 选择服务器：优先用 fzf（支持上下键，默认选 1），否则用数字菜单（直接回车=默认 1）
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

main() {
  echo "=== BOOT.BIN 下载到 SD 卡 ==="

  # 检查 SD 卡是否已挂载
  if [[ ! -d "$SD_MOUNT" ]]; then
    echo "错误: 未找到 SD 卡挂载点: $SD_MOUNT"
    echo "请插入 SD 卡（卷名应为 \"$SD_VOLUME_NAME\"）后重试。"
    exit 1
  fi

  SERVER=$(choose_server)
  SERVER="${SERVER//[$'\r\n']}"   # 去掉可能混入的换行，避免 scp 连错主机
  [[ -z "$SERVER" ]] && echo "已取消" && exit 0

  REMOTE="${USER}@${SERVER}:${REMOTE_PATH}"
  DEST="${SD_MOUNT}/BOOT.BIN"

  echo ""
  echo "服务器: $SERVER"
  echo "目标: $DEST"
  echo "正在下载..."
  echo ""

  if ! scp "$REMOTE" "$DEST"; then
    echo "下载失败，请检查网络与免密登录配置。"
    exit 1
  fi

  echo ""
  echo "下载完成。正在安全弹出 SD 卡..."

  if diskutil eject "$SD_MOUNT"; then
    echo "SD 卡已安全弹出，可以拔掉读卡器。"
    # macOS 通知（可选）
    if command -v osascript &>/dev/null; then
      osascript -e "display notification \"BOOT.BIN 已写入并已弹出 SD 卡\" with title \"OMP 脚本\""
    fi
  else
    echo "弹出失败，请手动在 Finder 中弹出 \"$SD_VOLUME_NAME\"。"
    exit 1
  fi
}

main "$@"
