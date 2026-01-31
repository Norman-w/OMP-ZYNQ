#!/bin/bash
# ============================================================================
# SD卡烧录脚本 - 格式化TF/SD卡并复制PetaLinux镜像
# ============================================================================
# 
# 使用方法:
#   1. 在PetaLinux工程根目录下执行（推荐）:
#      ./flash-to-tf-sd-card.sh
#   
#   2. 或者在工程目录外执行（需要指定工程路径）:
#      bash /path/to/petalinux-project/flash-to-tf-sd-card.sh /path/to/petalinux-project
#
# 功能:
#   - 自动检测SD卡设备
#   - 格式化SD卡为两个分区（FAT32 + EXT4）
#   - 复制BOOT.BIN和image.ub到FAT32分区
#   - 解压根文件系统到EXT4分区
#
# 注意事项:
#   - 需要root权限（使用sudo）
#   - 格式化会删除SD卡上的所有数据，请确认！
#   - 脚本会检查并避免格式化系统盘（如sda）
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录（应该是PetaLinux工程根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 如果提供了工程路径参数，使用它
if [ -n "$1" ]; then
    PETALINUX_PROJECT="$1"
else
    # 脚本应该在PetaLinux工程根目录下，直接使用脚本所在目录
    PETALINUX_PROJECT="$SCRIPT_DIR"
fi

# 检查工程目录
if [ ! -f "$PETALINUX_PROJECT/images/linux/BOOT.BIN" ]; then
    echo -e "${RED}错误: 未找到BOOT.BIN文件${NC}"
    echo "工程路径: $PETALINUX_PROJECT"
    echo "请先构建PetaLinux工程: petalinux-build"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SD卡烧录脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}工程路径: ${PETALINUX_PROJECT}${NC}"
echo ""

# 函数：检测SD卡
detect_sd_cards() {
    echo -e "${YELLOW}正在检测SD卡设备...${NC}"
    
    # 获取所有块设备
    local devices=$(lsblk -d -n -o NAME,TYPE,SIZE,MODEL | grep -E 'disk|mmcblk' | grep -v 'sda' || true)
    
    if [ -z "$devices" ]; then
        return 1
    fi
    
    echo -e "${GREEN}检测到的SD卡设备:${NC}"
    echo "$devices" | while read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        echo "  /dev/$device - $line"
    done
    
    return 0
}

# 函数：等待SD卡插入
wait_for_sd_card() {
    while true; do
        if detect_sd_cards; then
            break
        fi
        
        echo -e "${YELLOW}未检测到SD卡，请插入SD卡后按Enter继续...${NC}"
        read -r
        sleep 2
    done
}

# 检测SD卡
if ! detect_sd_cards; then
    wait_for_sd_card
fi

# 显示设备列表（只显示一次）
echo ""
echo -e "${GREEN}可用的SD卡设备:${NC}"
lsblk -d -n -o NAME,TYPE,SIZE,MODEL | grep -E 'disk|mmcblk' | grep -v 'sda' | while read -r line; do
    device=$(echo "$line" | awk '{print $1}')
    echo "  /dev/$device - $line"
done

echo ""
echo -e "${YELLOW}请输入要使用的SD卡设备名（如: sdb, sdc, mmcblk0等）:${NC}"
read -r SD_DEVICE

# 验证设备名
if [ -z "$SD_DEVICE" ]; then
    echo -e "${RED}错误: 未输入设备名${NC}"
    exit 1
fi

# 移除/dev/前缀（如果有）
SD_DEVICE="${SD_DEVICE#/dev/}"

# 检查设备是否存在
if [ ! -b "/dev/$SD_DEVICE" ]; then
    echo -e "${RED}错误: 设备 /dev/$SD_DEVICE 不存在${NC}"
    exit 1
fi

# 安全检查：避免格式化系统盘
if [ "$SD_DEVICE" = "sda" ] || [ "$SD_DEVICE" = "sda1" ] || [ "$SD_DEVICE" = "sda2" ]; then
    echo -e "${RED}错误: 不能格式化系统盘 /dev/$SD_DEVICE${NC}"
    exit 1
fi

# 确认操作
echo ""
echo -e "${RED}警告: 这将格式化 /dev/$SD_DEVICE，删除所有数据！${NC}"
echo -e "${YELLOW}设备信息:${NC}"
lsblk "/dev/$SD_DEVICE"
echo ""
echo -e "${YELLOW}确认要格式化 /dev/$SD_DEVICE 吗？(yes/y/no):${NC}"
read -r CONFIRM

# 转换为小写并检查
CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    echo "操作已取消"
    exit 0
fi

# 强制卸载所有分区
echo ""
echo -e "${YELLOW}强制卸载现有分区...${NC}"

# 获取所有分区
for partition in /dev/${SD_DEVICE}*; do
    if [ -b "$partition" ] || [ -b "${partition}1" ] || [ -b "${partition}p1" ]; then
        # 检查是否挂载
        if mountpoint -q "$partition" 2>/dev/null || mount | grep -q "$partition"; then
            echo "卸载 $partition"
            sudo umount "$partition" 2>/dev/null || true
            sudo umount -l "$partition" 2>/dev/null || true  # 懒卸载
        fi
    fi
done

# 检查是否有进程在使用设备
if lsof "/dev/$SD_DEVICE"* 2>/dev/null | grep -q .; then
    echo "检测到有进程正在使用设备，尝试终止..."
    sudo fuser -km "/dev/$SD_DEVICE"* 2>/dev/null || true
    sleep 2
    # 再次卸载
    for partition in /dev/${SD_DEVICE}*; do
        sudo umount -l "$partition" 2>/dev/null || true
    done
fi

sleep 1

# 使用parted格式化SD卡
echo ""
echo -e "${YELLOW}格式化SD卡...${NC}"

# 先删除所有现有分区（如果存在）
echo "删除现有分区..."
sudo parted -s "/dev/$SD_DEVICE" print 2>/dev/null | grep -E '^ [0-9]' | awk '{print $1}' | while read -r partnum; do
    if [ -n "$partnum" ]; then
        echo "删除分区 $partnum"
        sudo parted -s "/dev/$SD_DEVICE" rm "$partnum" 2>/dev/null || true
    fi
done

# 等待设备就绪
sleep 2

# 创建新的分区表
echo "创建新的分区表..."
sudo parted -s "/dev/$SD_DEVICE" mklabel msdos

# 获取SD卡总大小（MB）
TOTAL_SIZE=$(sudo parted -s "/dev/$SD_DEVICE" unit MB print | grep "^Disk" | awk '{print $3}' | sed 's/MB//')
BOOT_SIZE=200  # FAT32分区大小（MB）
ROOTFS_SIZE=$((TOTAL_SIZE - BOOT_SIZE - 10))  # 剩余空间给EXT4，留10MB缓冲

# 创建FAT32分区（boot）
echo "创建FAT32分区（boot）..."
sudo parted -s "/dev/$SD_DEVICE" mkpart primary fat32 1MB ${BOOT_SIZE}MB
sudo parted -s "/dev/$SD_DEVICE" set 1 boot on

# 创建EXT4分区（rootfs）
echo "创建EXT4分区（rootfs）..."
sudo parted -s "/dev/$SD_DEVICE" mkpart primary ext4 ${BOOT_SIZE}MB 100%

# 格式化分区
echo "格式化FAT32分区..."
if [[ "$SD_DEVICE" == mmcblk* ]]; then
    BOOT_PART="/dev/${SD_DEVICE}p1"
    ROOTFS_PART="/dev/${SD_DEVICE}p2"
else
    BOOT_PART="/dev/${SD_DEVICE}1"
    ROOTFS_PART="/dev/${SD_DEVICE}2"
fi

sudo mkfs.vfat -F 32 -n "BOOT" "$BOOT_PART"
echo "格式化EXT4分区..."
sudo mkfs.ext4 -F -L "rootfs" "$ROOTFS_PART"

echo -e "${GREEN}格式化完成！${NC}"
echo ""

# 创建临时挂载点
BOOT_MOUNT=$(mktemp -d)
ROOTFS_MOUNT=$(mktemp -d)

# 挂载分区
echo -e "${YELLOW}挂载分区...${NC}"
sudo mount "$BOOT_PART" "$BOOT_MOUNT"
sudo mount "$ROOTFS_PART" "$ROOTFS_MOUNT"

# 复制文件到FAT32分区
echo ""
echo -e "${YELLOW}复制启动文件到FAT32分区...${NC}"
sudo cp "$PETALINUX_PROJECT/images/linux/BOOT.BIN" "$BOOT_MOUNT/"
sudo cp "$PETALINUX_PROJECT/images/linux/image.ub" "$BOOT_MOUNT/"
if [ -f "$PETALINUX_PROJECT/images/linux/boot.scr" ]; then
    sudo cp "$PETALINUX_PROJECT/images/linux/boot.scr" "$BOOT_MOUNT/"
fi
# 同步并正确卸载FAT32分区
sync
sudo umount "$BOOT_MOUNT" || true
sleep 1
# 重新挂载以便后续操作
sudo mount "$BOOT_PART" "$BOOT_MOUNT"

echo -e "${GREEN}FAT32分区文件:${NC}"
ls -lh "$BOOT_MOUNT"

# 解压根文件系统到EXT4分区
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
    echo -e "${RED}错误: 未找到根文件系统文件${NC}"
    sudo umount "$BOOT_MOUNT"
    sudo umount "$ROOTFS_MOUNT"
    rmdir "$BOOT_MOUNT" "$ROOTFS_MOUNT"
    exit 1
fi
sync

echo -e "${GREEN}根文件系统已解压${NC}"

# 正确卸载分区（避免FAT-fs警告）
echo ""
echo -e "${YELLOW}正确卸载分区...${NC}"
# 先同步所有数据
sync
sleep 1
# 卸载FAT32分区（需要正确卸载以避免警告）
sudo umount "$BOOT_MOUNT" || sudo umount -l "$BOOT_MOUNT"
# 卸载EXT4分区
sudo umount "$ROOTFS_MOUNT" || sudo umount -l "$ROOTFS_MOUNT"
sleep 1
rmdir "$BOOT_MOUNT" "$ROOTFS_MOUNT" 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SD卡烧录完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 显示BOOT.BIN信息
echo -e "${BLUE}BOOT.BIN信息:${NC}"
if [ -f "$PETALINUX_PROJECT/images/linux/BOOT.BIN" ]; then
    BOOT_BIN_TIME=$(stat -c "%y" "$PETALINUX_PROJECT/images/linux/BOOT.BIN" 2>/dev/null || stat -f "%Sm" "$PETALINUX_PROJECT/images/linux/BOOT.BIN" 2>/dev/null || echo "未知")
    BOOT_BIN_SIZE=$(ls -lh "$PETALINUX_PROJECT/images/linux/BOOT.BIN" | awk '{print $5}')
    echo "  文件: BOOT.BIN"
    echo "  大小: $BOOT_BIN_SIZE"
    echo "  生成时间: $BOOT_BIN_TIME"
fi
echo ""

# 重新挂载以统计文件
echo -e "${YELLOW}统计分区文件...${NC}"
BOOT_MOUNT=$(mktemp -d)
ROOTFS_MOUNT=$(mktemp -d)

sudo mount "$BOOT_PART" "$BOOT_MOUNT" 2>/dev/null
sudo mount "$ROOTFS_PART" "$ROOTFS_MOUNT" 2>/dev/null

# 统计FAT32分区文件
if mountpoint -q "$BOOT_MOUNT" 2>/dev/null; then
    BOOT_FILES=$(find "$BOOT_MOUNT" -type f 2>/dev/null | wc -l)
    BOOT_SIZE=$(du -sh "$BOOT_MOUNT" 2>/dev/null | awk '{print $1}')
    echo -e "${BLUE}FAT32分区 (boot):${NC}"
    echo "  文件数: $BOOT_FILES"
    echo "  大小: $BOOT_SIZE"
    echo "  文件列表:"
    ls -lh "$BOOT_MOUNT" | tail -n +2 | awk '{print "    " $9 " (" $5 ")"}'
fi

echo ""

# 统计EXT4分区文件
if mountpoint -q "$ROOTFS_MOUNT" 2>/dev/null; then
    ROOTFS_FILES=$(find "$ROOTFS_MOUNT" -type f 2>/dev/null | wc -l)
    ROOTFS_DIRS=$(find "$ROOTFS_MOUNT" -type d 2>/dev/null | wc -l)
    ROOTFS_SIZE=$(du -sh "$ROOTFS_MOUNT" 2>/dev/null | awk '{print $1}')
    echo -e "${BLUE}EXT4分区 (rootfs):${NC}"
    echo "  文件数: $ROOTFS_FILES"
    echo "  目录数: $ROOTFS_DIRS"
    echo "  大小: $ROOTFS_SIZE"
fi

# 卸载分区
sudo umount "$BOOT_MOUNT" 2>/dev/null || true
sudo umount "$ROOTFS_MOUNT" 2>/dev/null || true
rmdir "$BOOT_MOUNT" "$ROOTFS_MOUNT" 2>/dev/null || true

echo ""
echo -e "${BLUE}SD卡分区信息:${NC}"
sudo parted -s "/dev/$SD_DEVICE" print

# 同步并安全移除
echo ""
echo -e "${YELLOW}同步数据并安全移除SD卡...${NC}"
sync
sleep 1

# 确保所有分区都已卸载
for partition in /dev/${SD_DEVICE}*; do
    if mountpoint -q "$partition" 2>/dev/null || mount | grep -q "$partition"; then
        sudo umount -l "$partition" 2>/dev/null || true
    fi
done

# 使用udisks2安全移除（如果可用）
if command -v udisksctl &> /dev/null; then
    echo "使用udisksctl安全移除..."
    udisksctl power-off -b "/dev/$SD_DEVICE" 2>/dev/null || true
elif command -v eject &> /dev/null; then
    echo "使用eject安全移除..."
    sudo eject "/dev/$SD_DEVICE" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SD卡已安全移除，可以拔出！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}下一步:${NC}"
echo "  1. 拔出SD卡"
echo "  2. 插入开发板"
echo "  3. 上电启动"
echo ""

