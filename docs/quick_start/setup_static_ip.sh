#!/bin/bash

# ============================================================================
# Ubuntu 静态IP配置向导
# 用途：手动通过ISO安装Ubuntu后，配置静态IP地址
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then 
    print_error "请不要使用root用户运行此脚本"
    exit 1
fi

# 检查NetworkManager是否安装
if ! command -v nmcli &> /dev/null; then
    print_error "未检测到NetworkManager，请先安装："
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y network-manager"
    exit 1
fi

print_info "=========================================="
print_info "Ubuntu 静态IP配置向导"
print_info "=========================================="
echo ""

# 显示可用的网络连接
print_info "正在获取可用的网络连接..."
echo ""

connections=$(nmcli -t -f NAME,DEVICE connection show | grep -v "^lo:")

if [ -z "$connections" ]; then
    print_error "未找到可用的网络连接"
    exit 1
fi

# 将连接列表转换为数组
IFS=$'\n' read -d '' -r -a conn_array <<< "$connections"

# 显示连接列表
print_info "可用的网络连接："
echo ""
index=1
declare -A conn_map

for conn in "${conn_array[@]}"; do
    conn_name=$(echo "$conn" | cut -d: -f1)
    conn_device=$(echo "$conn" | cut -d: -f2)
    echo "  [$index] $conn_name (设备: $conn_device)"
    conn_map[$index]=$conn_name
    ((index++))
done

echo ""

# 让用户选择连接
while true; do
    read -p "请选择要配置的网络连接 [1-$((index-1))]: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$index" ]; then
        selected_conn="${conn_map[$choice]}"
        print_success "已选择连接: $selected_conn"
        break
    else
        print_error "无效的选择，请输入 1 到 $((index-1)) 之间的数字"
    fi
done

echo ""

# 获取当前IP信息（用于默认值）
current_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n1)
current_gateway=$(ip route | grep default | awk '{print $3}' | head -n1)

# 输入IP地址
print_info "请输入静态IP配置信息"
echo ""

if [ -n "$current_ip" ]; then
    read -p "IP地址 [$current_ip]: " ip_address
    ip_address=${ip_address:-$current_ip}
else
    read -p "IP地址: " ip_address
fi

if [ -z "$ip_address" ]; then
    print_error "IP地址不能为空"
    exit 1
fi

# 输入子网掩码（简化，只输入CIDR前缀）
read -p "子网掩码前缀 [24]: " netmask_prefix
netmask_prefix=${netmask_prefix:-24}

# 输入网关
if [ -n "$current_gateway" ]; then
    read -p "网关地址 [$current_gateway]: " gateway
    gateway=${gateway:-$current_gateway}
else
    read -p "网关地址: " gateway
fi

if [ -z "$gateway" ]; then
    print_error "网关地址不能为空"
    exit 1
fi

# 输入DNS服务器
read -p "DNS服务器 [8.8.8.8,8.8.4.4]: " dns_servers
dns_servers=${dns_servers:-8.8.8.8,8.8.4.4}

echo ""
print_info "配置摘要："
echo "  连接名称: $selected_conn"
echo "  IP地址:   $ip_address/$netmask_prefix"
echo "  网关:     $gateway"
echo "  DNS:      $dns_servers"
echo ""

read -p "确认应用此配置？[y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_warning "已取消配置"
    exit 0
fi

echo ""

# 应用配置
print_info "正在配置网络连接..."

sudo nmcli connection modify "$selected_conn" ipv4.method manual
sudo nmcli connection modify "$selected_conn" ipv4.addresses "$ip_address/$netmask_prefix"
sudo nmcli connection modify "$selected_conn" ipv4.gateway "$gateway"
sudo nmcli connection modify "$selected_conn" ipv4.dns "$dns_servers"

print_success "配置已保存"

# 重启连接
print_info "正在重启网络连接..."
sudo nmcli connection down "$selected_conn" 2>/dev/null || true
sleep 1
sudo nmcli connection up "$selected_conn"

print_success "网络连接已重启"

echo ""
print_info "验证配置："
echo ""

# 显示IP配置
ip addr show | grep -A 2 "inet " | grep -v "127.0.0.1" || true

# 显示路由
echo ""
print_info "默认路由："
ip route | grep default || print_warning "未找到默认路由"

# 测试连接
echo ""
read -p "是否测试网络连接？[Y/n]: " test_network
if [[ ! "$test_network" =~ ^[Nn]$ ]]; then
    echo ""
    print_info "正在测试网关连接..."
    if ping -c 2 -W 2 "$gateway" &> /dev/null; then
        print_success "网关 $gateway 连接正常"
    else
        print_warning "网关 $gateway 连接失败，请检查配置"
    fi
    
    echo ""
    print_info "正在测试外网连接..."
    if ping -c 2 -W 2 8.8.8.8 &> /dev/null; then
        print_success "外网连接正常"
    else
        print_warning "外网连接失败，请检查网关和DNS配置"
    fi
fi

echo ""
print_success "静态IP配置完成！"
print_info "当前IP地址: $ip_address/$netmask_prefix"
print_info "网关地址: $gateway"

