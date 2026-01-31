#!/bin/bash
# ============================================================================
# 文件打包脚本 - 在VM上打包最小文件集，用于传输到macOS
# ============================================================================
# 
# 使用方法:
#   ./pack-files-for-macos.sh [PetaLinux工程路径] [输出目录]
#   
# 示例:
#   ./pack-files-for-macos.sh /path/to/petalinux-project
#   ./pack-files-for-macos.sh /path/to/petalinux-project /tmp
#
# 功能:
#   - 打包BOOT.BIN、image.ub等启动文件
#   - 打包根文件系统（如果存在）
#   - 创建压缩包，最小化传输文件大小
#   - 生成文件清单
#
# 适用场景:
#   - 在Ubuntu VM上运行，打包文件
#   - 传输到macOS后解压使用
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 解析参数
PETALINUX_PROJECT=""
OUTPUT_DIR=""

if [ -n "$1" ]; then
    PETALINUX_PROJECT="$1"
else
    # 尝试使用脚本所在目录
    if [ -f "$SCRIPT_DIR/images/linux/BOOT.BIN" ]; then
        PETALINUX_PROJECT="$SCRIPT_DIR"
    fi
fi

if [ -n "$2" ]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$SCRIPT_DIR"
fi

# 检查工程目录
if [ -z "$PETALINUX_PROJECT" ] || [ ! -f "$PETALINUX_PROJECT/images/linux/BOOT.BIN" ]; then
    echo -e "${RED}错误: 未找到BOOT.BIN文件${NC}"
    echo "使用方法: $0 <PetaLinux工程路径> [输出目录]"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}文件打包脚本（用于macOS传输）${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}工程路径: ${PETALINUX_PROJECT}${NC}"
echo -e "${BLUE}输出目录: ${OUTPUT_DIR}${NC}"
echo ""

# 创建临时目录
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/images/linux"
mkdir -p "$PACKAGE_DIR"

# 复制启动文件
echo -e "${YELLOW}打包启动文件...${NC}"
cp "$PETALINUX_PROJECT/images/linux/BOOT.BIN" "$PACKAGE_DIR/"
cp "$PETALINUX_PROJECT/images/linux/image.ub" "$PACKAGE_DIR/"

if [ -f "$PETALINUX_PROJECT/images/linux/boot.scr" ]; then
    cp "$PETALINUX_PROJECT/images/linux/boot.scr" "$PACKAGE_DIR/"
    echo "  ✓ boot.scr"
fi

echo "  ✓ BOOT.BIN"
echo "  ✓ image.ub"

# 检查并打包根文件系统
ROOTFS_FILE=""
if [ -f "$PETALINUX_PROJECT/images/linux/rootfs.tar.gz" ]; then
    ROOTFS_FILE="rootfs.tar.gz"
    echo -e "${YELLOW}找到根文件系统: rootfs.tar.gz${NC}"
    echo -e "${BLUE}是否包含根文件系统？(y/n，默认n):${NC}"
    read -r INCLUDE_ROOTFS
    if [[ "$INCLUDE_ROOTFS" =~ ^[Yy]$ ]]; then
        cp "$PETALINUX_PROJECT/images/linux/rootfs.tar.gz" "$PACKAGE_DIR/"
        echo "  ✓ rootfs.tar.gz"
    else
        echo -e "${YELLOW}跳过根文件系统（可在macOS上单独传输）${NC}"
    fi
elif [ -f "$PETALINUX_PROJECT/images/linux/rootfs.cpio.gz" ]; then
    ROOTFS_FILE="rootfs.cpio.gz"
    echo -e "${YELLOW}找到根文件系统: rootfs.cpio.gz${NC}"
    echo -e "${BLUE}是否包含根文件系统？(y/n，默认n):${NC}"
    read -r INCLUDE_ROOTFS
    if [[ "$INCLUDE_ROOTFS" =~ ^[Yy]$ ]]; then
        cp "$PETALINUX_PROJECT/images/linux/rootfs.cpio.gz" "$PACKAGE_DIR/"
        echo "  ✓ rootfs.cpio.gz"
    else
        echo -e "${YELLOW}跳过根文件系统（可在macOS上单独传输）${NC}"
    fi
else
    echo -e "${YELLOW}未找到根文件系统文件${NC}"
fi

# 生成文件清单
echo ""
echo -e "${YELLOW}生成文件清单...${NC}"
MANIFEST_FILE="$PACKAGE_DIR/MANIFEST.txt"
cat > "$MANIFEST_FILE" << EOF
# 文件清单
生成时间: $(date)
PetaLinux工程: $PETALINUX_PROJECT

## 启动文件
EOF

for file in BOOT.BIN image.ub boot.scr; do
    if [ -f "$PACKAGE_DIR/$file" ]; then
        size=$(stat -c%s "$PACKAGE_DIR/$file" 2>/dev/null || stat -f%z "$PACKAGE_DIR/$file" 2>/dev/null)
        size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc 2>/dev/null || echo "0")
        mtime=$(stat -c "%y" "$PACKAGE_DIR/$file" 2>/dev/null || stat -f "%Sm" "$PACKAGE_DIR/$file" 2>/dev/null || echo "未知")
        echo "- $file: ${size_mb} MB, 修改时间: $mtime" >> "$MANIFEST_FILE"
    fi
done

if [ -n "$ROOTFS_FILE" ] && [ -f "$PACKAGE_DIR/$ROOTFS_FILE" ]; then
    size=$(stat -c%s "$PACKAGE_DIR/$ROOTFS_FILE" 2>/dev/null || stat -f%z "$PACKAGE_DIR/$ROOTFS_FILE" 2>/dev/null)
    size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc 2>/dev/null || echo "0")
    echo "" >> "$MANIFEST_FILE"
    echo "## 根文件系统" >> "$MANIFEST_FILE"
    echo "- $ROOTFS_FILE: ${size_mb} MB" >> "$MANIFEST_FILE"
fi

cat "$MANIFEST_FILE"
echo "  ✓ MANIFEST.txt"

# 创建压缩包
echo ""
echo -e "${YELLOW}创建压缩包...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="petalinux_files_${TIMESTAMP}.tar.gz"
PACKAGE_PATH="$OUTPUT_DIR/$PACKAGE_NAME"

cd "$TEMP_DIR"
tar -czf "$PACKAGE_PATH" images/

# 计算文件大小
PACKAGE_SIZE=$(stat -c%s "$PACKAGE_PATH" 2>/dev/null || stat -f%z "$PACKAGE_PATH" 2>/dev/null)
PACKAGE_SIZE_MB=$(echo "scale=2; $PACKAGE_SIZE / 1024 / 1024" | bc 2>/dev/null || echo "0")
PACKAGE_SIZE_GB=$(echo "scale=2; $PACKAGE_SIZE / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

# 清理临时目录
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}打包完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}压缩包信息:${NC}"
echo "  文件: $PACKAGE_NAME"
echo "  路径: $PACKAGE_PATH"
echo "  大小: ${PACKAGE_SIZE_MB} MB (${PACKAGE_SIZE_GB} GB)"
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  1. 将压缩包传输到macOS"
echo "  2. 在macOS上运行: ./copy-files-to-sd-macos.sh /path/to/extracted/files"
echo "  或者: ./copy-files-to-sd-macos.sh /path/to/$PACKAGE_NAME"
echo ""

