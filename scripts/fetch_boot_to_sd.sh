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
  echo "远程文件: $REMOTE_PATH"
  echo "目标: $DEST"
  echo ""

  # 检查远程文件是否存在并计算哈希值
  echo "正在检查远程文件..."
  REMOTE_HASH=$(ssh "${USER}@${SERVER}" "if [ -f '$REMOTE_PATH' ]; then if command -v md5sum &>/dev/null; then md5sum '$REMOTE_PATH' 2>/dev/null | cut -d' ' -f1; elif command -v md5 &>/dev/null; then md5 -q '$REMOTE_PATH' 2>/dev/null; else echo ''; fi; else echo ''; fi" 2>/dev/null)
  if [[ -z "$REMOTE_HASH" ]]; then
    echo "❌ 错误: 远程文件不存在或无法计算哈希值"
    exit 1
  fi
  echo "🔐 远程文件 MD5: $REMOTE_HASH"
  echo ""

  # 备份旧文件（如果存在）
  BACKUP_DEST="${DEST}.bak"
  if [[ -f "$DEST" ]]; then
    echo "📦 备份旧文件: $BACKUP_DEST"
    cp "$DEST" "$BACKUP_DEST" 2>/dev/null || true
  fi

  # 下载文件
  echo "正在下载..."
  if ! scp "$REMOTE" "$DEST"; then
    echo "❌ 下载失败，请检查网络与免密登录配置。"
    exit 1
  fi

  echo ""
  echo "正在验证文件..."

  # 检查本地文件是否存在
  if [[ ! -f "$DEST" ]]; then
    echo "❌ 错误: 文件下载后不存在于目标位置"
    exit 1
  fi

  # 计算本地文件哈希值（macOS 使用 md5 -q，Linux 使用 md5sum）
  if command -v md5sum &>/dev/null; then
    LOCAL_HASH=$(md5sum "$DEST" 2>/dev/null | cut -d' ' -f1)
  elif command -v md5 &>/dev/null; then
    LOCAL_HASH=$(md5 -q "$DEST" 2>/dev/null)
  else
    echo "❌ 错误: 未找到 md5 或 md5sum 命令"
    exit 1
  fi
  
  if [[ -z "$LOCAL_HASH" ]]; then
    echo "❌ 错误: 无法计算本地文件哈希值"
    exit 1
  fi
  
  # 对比哈希值
  if [[ "$REMOTE_HASH" == "$LOCAL_HASH" ]]; then
    echo "🔐 本地文件 MD5: $LOCAL_HASH"
    echo ""
    echo -e "\033[32m✅ 文件验证成功！哈希值匹配，文件已正确下载。\033[0m"
    
    # 如果备份文件存在，检查是否与新文件相同
    if [[ -f "$BACKUP_DEST" ]]; then
      if command -v md5sum &>/dev/null; then
        BACKUP_HASH=$(md5sum "$BACKUP_DEST" 2>/dev/null | cut -d' ' -f1)
      elif command -v md5 &>/dev/null; then
        BACKUP_HASH=$(md5 -q "$BACKUP_DEST" 2>/dev/null)
      fi
      if [[ "$BACKUP_HASH" == "$LOCAL_HASH" ]]; then
        echo "ℹ️  提示: 新文件与备份文件相同（可能未重新编译）"
      else
        echo "✅ 新文件与旧文件不同，已更新"
      fi
    fi
    echo ""
    echo "正在安全弹出 SD 卡..."

    if diskutil eject "$SD_MOUNT"; then
      echo -e "\033[32m✅ SD 卡已安全弹出，可以拔掉读卡器。\033[0m"
      # macOS 通知（可选）
      if command -v osascript &>/dev/null; then
        osascript -e "display notification \"BOOT.BIN 已写入并已弹出 SD 卡\" with title \"OMP 脚本\""
      fi
    else
      echo "❌ 弹出失败，请手动在 Finder 中弹出 \"$SD_VOLUME_NAME\"。"
      exit 1
    fi
  else
    echo "🔐 本地文件 MD5: $LOCAL_HASH"
    echo ""
    echo -e "\033[31m❌ 错误: 文件哈希值不匹配！\033[0m"
    echo "   远程 MD5: $REMOTE_HASH"
    echo "   本地 MD5: $LOCAL_HASH"
    echo ""
    echo "可能的原因："
    echo "  1. 文件下载不完整"
    echo "  2. SD 卡写入失败或损坏"
    echo "  3. 网络传输错误"
    echo ""
    
    # 如果备份文件存在，恢复备份
    if [[ -f "$BACKUP_DEST" ]]; then
      echo "🔄 正在恢复备份文件..."
      cp "$BACKUP_DEST" "$DEST" 2>/dev/null && echo "✅ 已恢复备份文件" || echo "❌ 恢复备份失败"
    fi
    
    echo ""
    echo "请检查网络连接和 SD 卡状态后重试。"
    exit 1
  fi
}

main "$@"
