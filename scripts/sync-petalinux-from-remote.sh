#!/bin/bash
# ============================================================================
# 从远程服务器同步 Petalinux 项目到本地
# ============================================================================
# 
# 功能:
#   - 从 norman@192.168.46.128:petalinux-projects/OMP 复制到本地 Petalinux 目录
#   - 使用 rsync 保持文件同步（如果可用），否则使用 scp
#
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REMOTE_HOST="norman@192.168.46.128"
REMOTE_PATH="petalinux-projects/OMP"
LOCAL_BASE_DIR="D:/ZYNQ/Norman/OMP"
LOCAL_TARGET_DIR="$LOCAL_BASE_DIR/Petalinux"

# 转换 Windows 路径为 Unix 风格（如果在 Git Bash 中）
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    LOCAL_TARGET_DIR=$(cygpath -u "$LOCAL_TARGET_DIR" 2>/dev/null || echo "$LOCAL_TARGET_DIR")
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}同步 Petalinux 项目${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}远程: ${REMOTE_HOST}:${REMOTE_PATH}${NC}"
echo -e "${BLUE}本地: ${LOCAL_TARGET_DIR}${NC}"
echo ""

# 检查目标目录是否存在，不存在则创建
if [ ! -d "$LOCAL_TARGET_DIR" ]; then
    echo -e "${YELLOW}创建目标目录: ${LOCAL_TARGET_DIR}${NC}"
    mkdir -p "$LOCAL_TARGET_DIR"
fi

# 检查是否可以使用 rsync（更高效）
if command -v rsync &> /dev/null; then
    echo -e "${GREEN}使用 rsync 同步文件...${NC}"
    echo -e "${YELLOW}这可能需要一些时间，请耐心等待...${NC}"
    echo ""
    
    rsync -avz --progress \
        --exclude='.git' \
        --exclude='*.log' \
        --exclude='build/' \
        --exclude='images/linux/*.cpio.gz' \
        --exclude='images/linux/*.tar.gz' \
        "${REMOTE_HOST}:${REMOTE_PATH}/" \
        "${LOCAL_TARGET_DIR}/"
else
    echo -e "${YELLOW}rsync 不可用，使用 scp 复制文件...${NC}"
    echo -e "${YELLOW}这可能需要一些时间，请耐心等待...${NC}"
    echo ""
    
    scp -r "${REMOTE_HOST}:${REMOTE_PATH}/"* "${LOCAL_TARGET_DIR}/"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}文件同步完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}本地目录: ${LOCAL_TARGET_DIR}${NC}"
echo ""

