#!/bin/bash
# PetaLinux 安装脚本
# 适用于 Ubuntu 18.04
# 使用方法: bash install_petalinux.sh [安装包路径] [安装目录]

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认参数
INSTALLER_PATH="${1:-${HOME}/petalinux-v2020.2-final-installer.run}"
INSTALL_DIR="${2:-/opt/Petalinux/2020.2}"

# 展开路径中的 ~
INSTALLER_PATH="${INSTALLER_PATH/#\~/$HOME}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PetaLinux 安装脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}错误: 请不要使用root用户运行此脚本${NC}"
   echo "PetaLinux安装程序不允许root用户执行"
   exit 1
fi

echo -e "${YELLOW}当前用户: $(whoami)${NC}"
echo -e "${YELLOW}安装包路径: ${INSTALLER_PATH}${NC}"
echo -e "${YELLOW}安装目录: ${INSTALL_DIR}${NC}"
echo ""

# 步骤1: 更新包列表
echo -e "${GREEN}[1/7] 更新包列表...${NC}"
sudo apt-get update

# 步骤2: 安装依赖包（使用详细教程中的完整列表）
echo -e "${GREEN}[2/7] 安装PetaLinux依赖包...${NC}"
echo "这可能需要几分钟时间，请耐心等待..."

sudo apt-get install -y \
    tofrodos iproute2 gawk gcc g++ git make net-tools libncurses5-dev \
    tftpd zlib1g:i386 libssl-dev flex bison libselinux1 gnupg wget diffstat chrpath socat \
    xterm autoconf libtool tar unzip texinfo zlib1g-dev gcc-multilib build-essential \
    libsdl1.2-dev libglib2.0-dev screen pax gzip automake \
    python python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    libarchive-dev libexpat1-dev libpng-dev libasound2-dev libpulse-dev \
    libcaca-dev libncursesw5-dev python3-dev

# 如果遇到依赖冲突，尝试使用aptitude
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}检测到依赖冲突，尝试使用aptitude解决...${NC}"
    sudo apt-get install -y aptitude
    sudo aptitude install -y gcc-multilib || true
fi

# 步骤3: 禁用dash，使用bash作为/bin/sh
echo -e "${GREEN}[3/7] 配置系统使用bash作为/bin/sh...${NC}"
echo "PetaLinux工具需要bash作为/bin/sh，而不是dash"
echo "在配置界面中选择'否'来禁用dash"
sudo dpkg-reconfigure -f noninteractive dash || {
    echo -e "${YELLOW}注意: dash配置需要交互式操作，请稍后手动执行:${NC}"
    echo "sudo dpkg-reconfigure dash"
    echo "然后选择'否'"
}

# 步骤4: 创建安装目录
echo -e "${GREEN}[4/7] 创建安装目录...${NC}"
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"
echo "安装目录已创建: $INSTALL_DIR"

# 步骤5: 检查安装包
echo -e "${GREEN}[5/7] 检查安装包...${NC}"
if [ ! -f "$INSTALLER_PATH" ]; then
    echo -e "${RED}错误: 找不到安装包: ${INSTALLER_PATH}${NC}"
    echo ""
    echo "请将PetaLinux安装包(.run文件)放到以下位置之一:"
    echo "  - ~/petalinux-v2020.2-final-installer.run (默认)"
    echo "  - 或使用第一个参数指定路径: bash install_petalinux.sh /path/to/installer.run"
    echo ""
    echo "查找已存在的安装包:"
    find ~ /tmp /home /opt -name "*petalinux*.run" -o -name "*petalinux*.tar.gz" 2>/dev/null | head -5
    exit 1
fi

# 检查安装包权限
if [ ! -x "$INSTALLER_PATH" ]; then
    echo "设置安装包执行权限..."
    chmod +x "$INSTALLER_PATH"
fi

echo -e "${GREEN}安装包已找到: ${INSTALLER_PATH}${NC}"

# 步骤6: 运行安装程序
echo -e "${GREEN}[6/7] 准备运行PetaLinux安装程序...${NC}"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "1. 安装程序会显示license协议，需要按Enter查看，然后输入'y'接受"
echo "2. 共有三个协议需要确认"
echo "3. 安装过程可能需要10-30分钟，请耐心等待"
echo ""
read -p "按Enter键继续安装，或Ctrl+C取消..."

# 进入安装包目录
INSTALLER_DIR=$(dirname "$INSTALLER_PATH")
INSTALLER_NAME=$(basename "$INSTALLER_PATH")
cd "$INSTALLER_DIR"

# 运行安装程序
echo "开始安装..."
echo "安装目录: $INSTALL_DIR"
./"$INSTALLER_NAME" -d "$INSTALL_DIR"

# 检查安装是否成功
if [ ! -f "$INSTALL_DIR/settings.sh" ]; then
    echo -e "${RED}警告: 安装可能未完成，未找到settings.sh文件${NC}"
    exit 1
fi

# 步骤7: 配置环境变量
echo -e "${GREEN}[7/7] 配置环境变量...${NC}"

# 检查.bashrc中是否已存在
if grep -q "petalinux/settings.sh" ~/.bashrc; then
    echo "环境变量配置已存在，跳过..."
else
    echo "" >> ~/.bashrc
    echo "# PetaLinux environment" >> ~/.bashrc
    echo "source $INSTALL_DIR/settings.sh" >> ~/.bashrc
    echo "环境变量已添加到 ~/.bashrc"
fi

# 使配置生效
source "$INSTALL_DIR/settings.sh"

# 验证安装
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 验证
echo "验证安装..."
if command -v petalinux-version &> /dev/null; then
    echo -e "${GREEN}PetaLinux版本:${NC}"
    petalinux-version
else
    echo -e "${YELLOW}警告: petalinux-version命令未找到${NC}"
    echo "请手动执行: source $INSTALL_DIR/settings.sh"
fi

echo ""
echo -e "${GREEN}PETALINUX环境变量:${NC}"
echo "PETALINUX=$PETALINUX"

echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "1. 环境变量已添加到 ~/.bashrc，新终端会自动加载"
echo "2. 当前终端已加载环境变量，可以直接使用petalinux命令"
echo "3. 如果dash配置未完成，请执行: sudo dpkg-reconfigure dash (选择'否')"
echo ""
echo -e "${GREEN}安装完成！${NC}"

