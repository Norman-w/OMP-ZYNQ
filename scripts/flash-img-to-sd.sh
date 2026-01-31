#!/bin/bash
# ============================================================================
# IMG镜像文件烧录脚本 - 使用dd命令烧录img文件到SD卡
# ============================================================================
# 
# 使用方法:
#   sudo ./flash-img-to-sd.sh <img文件路径> [设备名]
#   
# 示例:
#   sudo ./flash-img-to-sd.sh system.img
#   sudo ./flash-img-to-sd.sh system.img sdb
#
# 功能:
#   - 自动检测SD卡设备
#   - 使用dd命令烧录img文件到SD卡
#   - 显示烧录进度
#
# 注意事项:
#   - 需要root权限（使用sudo）
#   - 烧录会删除SD卡上的所有数据，请确认！
#   - 脚本会检查并避免烧录到系统盘（如sda）
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 请提供img文件路径${NC}"
    echo "使用方法: sudo $0 <img文件路径> [设备名]"
    echo "示例: sudo $0 system.img sdb"
    exit 1
fi

IMG_FILE="$1"
SD_DEVICE="$2"

# 检查img文件是否存在
if [ ! -f "$IMG_FILE" ]; then
    echo -e "${RED}错误: img文件不存在: $IMG_FILE${NC}"
    exit 1
fi

# 获取img文件大小
IMG_SIZE=$(stat -c%s "$IMG_FILE" 2>/dev/null || stat -f%z "$IMG_FILE" 2>/dev/null)
IMG_SIZE_MB=$((IMG_SIZE / 1024 / 1024))
IMG_SIZE_GB=$(echo "scale=2; $IMG_SIZE / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "$IMG_SIZE_MB")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}IMG镜像文件烧录脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}IMG文件: ${IMG_FILE}${NC}"
echo -e "${BLUE}文件大小: ${IMG_SIZE_MB} MB (${IMG_SIZE_GB} GB)${NC}"
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

# 如果没有指定设备，让用户选择
if [ -z "$SD_DEVICE" ]; then
    echo ""
    echo -e "${GREEN}可用的SD卡设备列表:${NC}"
    
    # 创建设备数组
    declare -a DEVICE_LIST
    declare -a DEVICE_NAMES
    index=1
    
    # 收集所有非sda设备
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            device=$(echo "$line" | awk '{print $1}')
            # 过滤掉sda及其变体
            if [[ "$device" != sda* ]]; then
                DEVICE_LIST[$index]="$device"
                DEVICE_NAMES[$index]="$line"
                echo -e "  ${BLUE}[$index]${NC} /dev/$device - $line"
                ((index++))
            fi
        fi
    done < <(lsblk -d -n -o NAME,TYPE,SIZE,MODEL | grep -E 'disk|mmcblk')
    
    if [ ${#DEVICE_LIST[@]} -eq 0 ]; then
        echo -e "${RED}错误: 未找到可用的SD卡设备${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}请选择要使用的SD卡设备（输入编号或设备名，如: 1 或 sdb）:${NC}"
    read -r USER_INPUT
    
    # 检查是否是数字
    if [[ "$USER_INPUT" =~ ^[0-9]+$ ]]; then
        if [ "$USER_INPUT" -ge 1 ] && [ "$USER_INPUT" -lt $index ]; then
            SD_DEVICE="${DEVICE_LIST[$USER_INPUT]}"
        else
            echo -e "${RED}错误: 无效的编号${NC}"
            exit 1
        fi
    else
        SD_DEVICE="$USER_INPUT"
    fi
fi

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

# 安全检查：避免烧录到系统盘
if [ "$SD_DEVICE" = "sda" ] || [ "$SD_DEVICE" = "sda1" ] || [ "$SD_DEVICE" = "sda2" ]; then
    echo -e "${RED}错误: 不能烧录到系统盘 /dev/$SD_DEVICE${NC}"
    exit 1
fi

# 获取设备大小
DEVICE_SIZE=$(sudo blockdev --getsize64 "/dev/$SD_DEVICE" 2>/dev/null || echo "0")
DEVICE_SIZE_MB=$((DEVICE_SIZE / 1024 / 1024))
DEVICE_SIZE_GB=$(echo "scale=2; $DEVICE_SIZE / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "$DEVICE_SIZE_MB")

# 检查设备大小是否足够
if [ "$DEVICE_SIZE" -lt "$IMG_SIZE" ]; then
    echo -e "${RED}错误: SD卡容量不足！${NC}"
    echo "  IMG文件大小: ${IMG_SIZE_MB} MB"
    echo "  SD卡容量: ${DEVICE_SIZE_MB} MB"
    exit 1
fi

# 确认操作
echo ""
echo -e "${RED}警告: 这将烧录img文件到 /dev/$SD_DEVICE，删除所有数据！${NC}"
echo -e "${YELLOW}设备信息:${NC}"
lsblk "/dev/$SD_DEVICE"
echo ""
echo -e "${YELLOW}IMG文件: ${IMG_FILE} (${IMG_SIZE_MB} MB)${NC}"
echo -e "${YELLOW}目标设备: /dev/$SD_DEVICE (${DEVICE_SIZE_MB} MB)${NC}"
echo ""
echo -e "${YELLOW}确认要烧录到 /dev/$SD_DEVICE 吗？(yes/y/no):${NC}"
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

# 使用dd命令烧录img文件
echo ""
echo -e "${YELLOW}开始烧录img文件...${NC}"
echo -e "${BLUE}这可能需要几分钟时间，请耐心等待...${NC}"
echo ""

# 检查并安装pv命令（用于显示进度）
if ! command -v pv &> /dev/null; then
    echo -e "${YELLOW}检测到未安装pv，正在安装...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y pv
    elif command -v yum &> /dev/null; then
        sudo yum install -y pv
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm pv
    else
        echo -e "${YELLOW}警告: 无法自动安装pv，将使用dd的进度显示${NC}"
    fi
fi

# 使用dd命令烧录img文件
if command -v pv &> /dev/null; then
    echo -e "${GREEN}使用pv显示进度...${NC}"
    sudo pv "$IMG_FILE" | sudo dd of="/dev/$SD_DEVICE" bs=4M oflag=sync status=none
else
    echo -e "${YELLOW}使用dd烧录（显示进度）...${NC}"
    sudo dd if="$IMG_FILE" of="/dev/$SD_DEVICE" bs=4M status=progress oflag=sync
fi

# 同步数据
echo ""
echo -e "${YELLOW}同步数据...${NC}"
sync

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}IMG文件烧录完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 显示设备信息
echo -e "${BLUE}SD卡分区信息:${NC}"
sudo parted -s "/dev/$SD_DEVICE" print 2>/dev/null || lsblk "/dev/$SD_DEVICE"

# 检查并报告SD卡上的关键文件信息
echo ""
echo -e "${YELLOW}检查SD卡上的关键文件...${NC}"

# 确定boot分区
if [[ "$SD_DEVICE" == mmcblk* ]]; then
    BOOT_PART="/dev/${SD_DEVICE}p1"
else
    BOOT_PART="/dev/${SD_DEVICE}1"
fi

# 创建临时挂载点
BOOT_MOUNT=$(mktemp -d)

# 尝试挂载boot分区
if sudo mount "$BOOT_PART" "$BOOT_MOUNT" 2>/dev/null; then
    echo -e "${GREEN}已挂载boot分区，检查关键文件:${NC}"
    
    # 检查常见的关键文件
    KEY_FILES=("BOOT.BIN" "boot.bin" "BOOT.bin" "image.ub" "image.ub.bin" "u-boot.bin" "uImage" "zImage")
    
    LATEST_FILE=""
    LATEST_TIME=0
    
    for key_file in "${KEY_FILES[@]}"; do
        if [ -f "$BOOT_MOUNT/$key_file" ]; then
            file_time=$(stat -c "%Y" "$BOOT_MOUNT/$key_file" 2>/dev/null || echo "0")
            file_time_readable=$(stat -c "%y" "$BOOT_MOUNT/$key_file" 2>/dev/null || echo "未知")
            file_size=$(stat -c "%s" "$BOOT_MOUNT/$key_file" 2>/dev/null || echo "0")
            file_size_mb=$(echo "scale=2; $file_size / 1024 / 1024" | bc 2>/dev/null || echo "0")
            
            echo -e "  ${BLUE}找到:${NC} $key_file"
            echo -e "    大小: ${file_size_mb} MB"
            echo -e "    写入时间: ${file_time_readable}"
            
            # 记录最新的文件
            if [ "$file_time" -gt "$LATEST_TIME" ]; then
                LATEST_TIME=$file_time
                LATEST_FILE="$key_file"
            fi
        fi
    done
    
    # 如果没有找到常见文件，列出所有文件
    if [ -z "$LATEST_FILE" ]; then
        echo -e "${YELLOW}未找到常见的关键文件，列出所有文件:${NC}"
        ls -lht "$BOOT_MOUNT" | head -10 | while read -r line; do
            if [[ "$line" =~ ^- ]]; then
                filename=$(echo "$line" | awk '{print $NF}')
                file_time=$(stat -c "%y" "$BOOT_MOUNT/$filename" 2>/dev/null || echo "未知")
                echo -e "  $filename - $file_time"
            fi
        done
    else
        latest_time_readable=$(stat -c "%y" "$BOOT_MOUNT/$LATEST_FILE" 2>/dev/null || echo "未知")
        echo ""
        echo -e "${GREEN}最新写入的关键文件:${NC}"
        echo -e "  文件: ${LATEST_FILE}"
        echo -e "  写入时间: ${latest_time_readable}"
    fi
    
    # 卸载分区
    sudo umount "$BOOT_MOUNT" 2>/dev/null || true
    rmdir "$BOOT_MOUNT" 2>/dev/null || true
else
    echo -e "${YELLOW}无法挂载boot分区，跳过文件检查${NC}"
    rmdir "$BOOT_MOUNT" 2>/dev/null || true
fi

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

