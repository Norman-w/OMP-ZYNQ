#!/bin/bash
# ============================================================================
# macOS SD卡文件复制脚本 - 仅复制文件到已分区的SD卡（不格式化）
# ============================================================================
# 
# 使用方法:
#   ./copy-files-to-sd-macos.sh [PetaLinux工程路径] [文件包路径]
#   
# 示例:
#   ./copy-files-to-sd-macos.sh /path/to/petalinux-project
#   ./copy-files-to-sd-macos.sh /path/to/petalinux-project /path/to/files.tar.gz
#
# 功能:
#   - 自动检测macOS上的SD卡设备
#   - 挂载SD卡分区（FAT32和EXT4）
#   - 复制BOOT.BIN和image.ub到FAT32分区
#   - 解压根文件系统到EXT4分区（如果提供）
#   - 不格式化，只更新文件内容
#
# 适用场景:
#   - SD卡分区已做好，只需要更新文件
#   - 在macOS上操作，减少从VM传输文件
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}警告: 此脚本专为macOS设计，当前系统可能不兼容${NC}"
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 解析参数
PETALINUX_PROJECT=""
FILES_PACKAGE=""

if [ -n "$1" ]; then
    if [ -f "$1" ] && [[ "$1" == *.tar.gz ]] || [[ "$1" == *.tgz ]]; then
        FILES_PACKAGE="$1"
    else
        PETALINUX_PROJECT="$1"
    fi
fi

if [ -n "$2" ] && [ -z "$FILES_PACKAGE" ]; then
    FILES_PACKAGE="$2"
fi

# 如果没有指定工程路径，尝试使用脚本所在目录
if [ -z "$PETALINUX_PROJECT" ] && [ -z "$FILES_PACKAGE" ]; then
    if [ -f "$SCRIPT_DIR/images/linux/BOOT.BIN" ]; then
        PETALINUX_PROJECT="$SCRIPT_DIR"
    fi
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}macOS SD卡文件复制脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 函数：检测macOS上的SD卡
detect_sd_cards_macos() {
    echo -e "${YELLOW}正在检测SD卡设备...${NC}"
    
    # macOS使用diskutil列出所有磁盘
    local devices=$(diskutil list | grep -E "disk[0-9]+" | grep -v "disk0" | awk '{print $NF}' || true)
    
    if [ -z "$devices" ]; then
        return 1
    fi
    
    echo -e "${GREEN}检测到的SD卡设备:${NC}"
    for device in $devices; do
        if [ "$device" != "disk0" ]; then
            size=$(diskutil info "$device" 2>/dev/null | grep "Disk Size" | awk -F: '{print $2}' | xargs || echo "未知")
            echo "  /dev/$device - $size"
        fi
    done
    
    return 0
}

# 函数：等待SD卡插入
wait_for_sd_card_macos() {
    while true; do
        if detect_sd_cards_macos; then
            break
        fi
        
        echo -e "${YELLOW}未检测到SD卡，请插入SD卡后按Enter继续...${NC}"
        read -r
        sleep 2
    done
}

# 检测SD卡
if ! detect_sd_cards_macos; then
    wait_for_sd_card_macos
fi

# 显示设备列表
echo ""
echo -e "${GREEN}可用的SD卡设备:${NC}"

# 收集设备列表
DEVICE_ARRAY=()
while IFS= read -r line; do
    if [ -n "$line" ]; then
        device=$(echo "$line" | awk '{print $NF}')
        if [ "$device" != "disk0" ] && [[ "$device" =~ ^disk[0-9]+$ ]]; then
            DEVICE_ARRAY+=("$device")
        fi
    fi
done < <(diskutil list | grep -E "^/dev/disk[0-9]+" | awk '{print $1}')

# 显示设备列表
index=1
for device in "${DEVICE_ARRAY[@]}"; do
    size=$(diskutil info "$device" 2>/dev/null | grep "Disk Size" | awk -F: '{print $2}' | xargs || echo "未知")
    echo -e "  ${BLUE}[$index]${NC} $device - $size"
    ((index++))
done

if [ ${#DEVICE_ARRAY[@]} -eq 0 ]; then
    echo -e "${RED}错误: 未找到可用的SD卡设备${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}请选择要使用的SD卡设备（输入编号或设备名，如: 1 或 disk2）:${NC}"
read -r USER_INPUT

# 确定设备名
if [[ "$USER_INPUT" =~ ^[0-9]+$ ]]; then
    if [ "$USER_INPUT" -ge 1 ] && [ "$USER_INPUT" -le ${#DEVICE_ARRAY[@]} ]; then
        SD_DEVICE="${DEVICE_ARRAY[$((USER_INPUT-1))]}"
    else
        echo -e "${RED}错误: 无效的编号${NC}"
        exit 1
    fi
else
    SD_DEVICE="${USER_INPUT#/dev/}"
    if [[ ! "$SD_DEVICE" =~ ^disk ]]; then
        SD_DEVICE="disk${SD_DEVICE}"
    fi
fi

# 验证设备
if ! diskutil info "$SD_DEVICE" &>/dev/null; then
    echo -e "${RED}错误: 设备 $SD_DEVICE 不存在${NC}"
    exit 1
fi

# 安全检查
if [ "$SD_DEVICE" = "disk0" ]; then
    echo -e "${RED}错误: 不能操作系统盘${NC}"
    exit 1
fi

# 获取分区信息
echo ""
echo -e "${YELLOW}设备信息:${NC}"
diskutil list "$SD_DEVICE"

# 查找FAT32和EXT4分区
BOOT_PART=""
ROOTFS_PART=""

# 获取所有分区
while IFS= read -r line; do
    part=$(echo "$line" | awk '{print $NF}')
    if [[ "$part" =~ ^${SD_DEVICE}s[0-9]+$ ]]; then
        fstype=$(diskutil info "$part" 2>/dev/null | grep "File System Personality" | awk -F: '{print $2}' | xargs || echo "")
        if [[ "$fstype" == *"MS-DOS"* ]] || [[ "$fstype" == *"FAT32"* ]] || [[ "$fstype" == *"FAT"* ]]; then
            if [ -z "$BOOT_PART" ]; then
                BOOT_PART="$part"
            fi
        elif [[ "$fstype" == *"ext4"* ]] || [[ "$fstype" == *"Linux"* ]]; then
            if [ -z "$ROOTFS_PART" ]; then
                ROOTFS_PART="$part"
            fi
        fi
    fi
done < <(diskutil list "$SD_DEVICE" | grep -E "^/dev/")

if [ -z "$BOOT_PART" ]; then
    echo -e "${RED}错误: 未找到FAT32分区（boot分区）${NC}"
    exit 1
fi

if [ -z "$ROOTFS_PART" ]; then
    echo -e "${YELLOW}警告: 未找到EXT4分区（rootfs分区），将只更新boot分区${NC}"
fi

echo ""
echo -e "${GREEN}找到分区:${NC}"
echo "  Boot分区 (FAT32): $BOOT_PART"
if [ -n "$ROOTFS_PART" ]; then
    echo "  Rootfs分区 (EXT4): $ROOTFS_PART"
fi

# 确认操作
echo ""
echo -e "${YELLOW}确认要更新这些分区吗？(yes/y/no):${NC}"
read -r CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    echo "操作已取消"
    exit 0
fi

# 处理文件包（如果提供）
if [ -n "$FILES_PACKAGE" ]; then
    echo ""
    echo -e "${YELLOW}解压文件包: $FILES_PACKAGE${NC}"
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$FILES_PACKAGE" -C "$TEMP_DIR"
    PETALINUX_PROJECT="$TEMP_DIR"
fi

# 检查必要文件
if [ -z "$PETALINUX_PROJECT" ] || [ ! -f "$PETALINUX_PROJECT/images/linux/BOOT.BIN" ]; then
    echo -e "${RED}错误: 未找到BOOT.BIN文件${NC}"
    if [ -n "$FILES_PACKAGE" ]; then
        rm -rf "$TEMP_DIR"
    fi
    exit 1
fi

# 挂载分区
echo ""
echo -e "${YELLOW}挂载分区...${NC}"

BOOT_MOUNT=$(mktemp -d)
diskutil mount -mountPoint "$BOOT_MOUNT" "$BOOT_PART" || {
    echo -e "${RED}错误: 无法挂载boot分区${NC}"
    exit 1
}

if [ -n "$ROOTFS_PART" ]; then
    ROOTFS_MOUNT=$(mktemp -d)
    # macOS需要安装fuse-ext2或使用其他方法挂载ext4
    if command -v fuse-ext2 &> /dev/null; then
        fuse-ext2 "$ROOTFS_PART" "$ROOTFS_MOUNT" -o rw+ || {
            echo -e "${YELLOW}警告: 无法挂载ext4分区，将只更新boot分区${NC}"
            ROOTFS_PART=""
        }
    else
        echo -e "${YELLOW}警告: macOS需要fuse-ext2来挂载ext4分区${NC}"
        echo "安装方法: brew install --cask osxfuse && brew install fuse-ext2"
        echo "将只更新boot分区"
        ROOTFS_PART=""
    fi
fi

# 复制文件到FAT32分区
echo ""
echo -e "${YELLOW}复制启动文件到FAT32分区...${NC}"
cp "$PETALINUX_PROJECT/images/linux/BOOT.BIN" "$BOOT_MOUNT/"
cp "$PETALINUX_PROJECT/images/linux/image.ub" "$BOOT_MOUNT/"
if [ -f "$PETALINUX_PROJECT/images/linux/boot.scr" ]; then
    cp "$PETALINUX_PROJECT/images/linux/boot.scr" "$BOOT_MOUNT/"
fi

sync
echo -e "${GREEN}FAT32分区文件:${NC}"
ls -lh "$BOOT_MOUNT"

# 解压根文件系统到EXT4分区（如果提供）
if [ -n "$ROOTFS_PART" ] && [ -n "$ROOTFS_MOUNT" ]; then
    echo ""
    echo -e "${YELLOW}解压根文件系统到EXT4分区...${NC}"
    
    if [ -f "$PETALINUX_PROJECT/images/linux/rootfs.tar.gz" ]; then
        echo "使用 rootfs.tar.gz..."
        sudo tar -xzf "$PETALINUX_PROJECT/images/linux/rootfs.tar.gz" -C "$ROOTFS_MOUNT"
    elif [ -f "$PETALINUX_PROJECT/images/linux/rootfs.cpio.gz" ]; then
        echo "使用 rootfs.cpio.gz..."
        cd "$ROOTFS_MOUNT"
        sudo zcat "$PETALINUX_PROJECT/images/linux/rootfs.cpio.gz" | sudo cpio -idm
        cd - > /dev/null
    else
        echo -e "${YELLOW}未找到根文件系统文件，跳过${NC}"
    fi
    sync
fi

# 卸载分区
echo ""
echo -e "${YELLOW}卸载分区...${NC}"
diskutil unmount "$BOOT_PART" || true

if [ -n "$ROOTFS_PART" ] && [ -n "$ROOTFS_MOUNT" ]; then
    if mountpoint -q "$ROOTFS_MOUNT" 2>/dev/null; then
        sudo umount "$ROOTFS_MOUNT" || true
    fi
    rmdir "$ROOTFS_MOUNT" 2>/dev/null || true
fi

rmdir "$BOOT_MOUNT" 2>/dev/null || true

# 清理临时文件
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}文件复制完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 显示文件信息
echo -e "${BLUE}BOOT.BIN信息:${NC}"
if [ -f "$PETALINUX_PROJECT/images/linux/BOOT.BIN" ]; then
    BOOT_BIN_TIME=$(stat -f "%Sm" "$PETALINUX_PROJECT/images/linux/BOOT.BIN" 2>/dev/null || echo "未知")
    BOOT_BIN_SIZE=$(ls -lh "$PETALINUX_PROJECT/images/linux/BOOT.BIN" | awk '{print $5}')
    echo "  文件: BOOT.BIN"
    echo "  大小: $BOOT_BIN_SIZE"
    echo "  生成时间: $BOOT_BIN_TIME"
fi

echo ""
echo -e "${GREEN}SD卡已准备就绪，可以安全拔出！${NC}"
echo ""

