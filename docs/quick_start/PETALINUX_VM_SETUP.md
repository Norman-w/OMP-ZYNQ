# PetaLinux 开发环境搭建指南

## 📋 基础准备

### 必需资源
- **Ubuntu 18.04 虚拟机**（推荐米联客提供的VM镜像）
- **PetaLinux 2020.2 安装包**（`.run` 文件）
- **虚拟机配置**：
  - 内存：8GB+
  - 硬盘：100GB+（PetaLinux安装约需10-15GB）
  - 网络：NAT模式（用于下载依赖）

### 系统要求
- Ubuntu 18.04 LTS（PetaLinux 2020.2官方支持）
- 非root用户（安装程序不允许root执行）
- 网络连接正常（安装过程需要下载依赖）

---

## 🚀 操作步骤

### 1. 配置SSH免密登录（可选但推荐）

**Windows端执行：**
```bash
# 在项目根目录
./scripts/setup_ssh_keys_to_server.sh
# 选择选项3或4，输入 uisrc@192.168.46.128
```

**VM端配置：**
```bash
# 安装SSH服务器（如果未安装）
sudo apt-get install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
sudo ufw allow ssh
```

### 2. 配置网络

**问题**：VM可能无法访问外网（ping不通8.8.8.8）

**解决**：检查网关配置
```bash
# 查看当前网关
ip route | grep default

# 如果网关是 192.168.46.1（错误），改为DHCP模式
# 编辑网络配置
sudo nano /etc/netplan/01-netcfg.yaml
# 或使用NetworkManager
sudo nmcli connection modify "Wired connection 1" ipv4.method auto
sudo nmcli connection up "Wired connection 1"

# 验证网络
ping -c 3 8.8.8.8
ping -c 3 baidu.com
```

**正确配置**：
- 网关应为 `192.168.46.2`（VMware NAT默认）
- 使用DHCP自动获取IP和网关

### 3. 安装PetaLinux依赖

```bash
# 更新包列表
sudo apt-get update

# 安装基础依赖
sudo apt-get install -y \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev \
    xterm autoconf libtool libglib2.0-dev libarchive-dev \
    libexpat1-dev libpng-dev libasound2-dev libpulse-dev \
    libcaca-dev libncursesw5-dev python3-dev gawk
```

**注意**：如果遇到依赖冲突，参考故障排除章节。

### 4. 安装PetaLinux

```bash
# 创建安装目录
sudo mkdir -p /opt/pkg/petalinux
sudo chown $USER:$USER /opt/pkg/petalinux

# 进入安装包所在目录（通常是/tmp）
cd /tmp

# 执行安装（使用 -d 参数指定安装目录）
./petalinux-v2020.2-final-installer.run -d /opt/pkg/petalinux

# 安装过程中：
# 1. 阅读并接受license（输入 y）
# 2. 等待安装完成（约10-30分钟）
```

### 5. 配置环境变量

```bash
# 编辑 ~/.bashrc
nano ~/.bashrc

# 添加以下内容
source /opt/pkg/petalinux/settings.sh

# 使配置生效
source ~/.bashrc

# 验证安装
petalinux-version
```

---

## ⚠️ 故障卡点

### 卡点1：依赖包冲突（Ubuntu 18.04）

**症状**：
```
E: Unable to correct problems, you have held broken packages.
gcc-multilib : Depends: gcc-7-multilib (>= 7.3.0-12~) but it is not going to be installed
```

**原因**：32位库版本冲突

**解决**：
```bash
# 方法1：使用aptitude自动解决依赖
sudo apt-get install -y aptitude
sudo aptitude install -y gcc-multilib

# 方法2：强制安装32位库（谨慎使用）
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y libc6:i386 zlib1g:i386 --allow-downgrades

# 方法3：跳过检查（不推荐，可能导致运行时问题）
# 创建符号链接绕过检查
sudo ln -s /usr/bin/gcc /usr/bin/gcc-multilib
```

**建议**：如果持续失败，考虑使用Docker容器或升级到Ubuntu 20.04。

### 卡点2：网络无法访问

**症状**：`ping 8.8.8.8` 失败，DNS解析失败

**原因**：网关配置错误（静态IP配置了错误的网关）

**解决**：
```bash
# 检查网关
ip route | grep default

# 如果显示 192.168.46.1，改为DHCP
sudo nmcli connection modify "Wired connection 1" ipv4.method auto
sudo nmcli connection up "Wired connection 1"

# 或编辑netplan配置
sudo nano /etc/netplan/01-netcfg.yaml
# 改为：
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
sudo netplan apply
```

### 卡点3：安装程序找不到安装目录

**症状**：
```
WARNING: You haven't specified the installation location.
WARNING: By default, it will be installed in your working directory: /tmp
ERROR: Failed to install PetaLinux SDK into "/tmp/."
```

**原因**：`--dir` 参数未正确解析，或安装目录非空

**解决**：
```bash
# 1. 清理/tmp目录中的残留文件（如果有）
cd /tmp
rm -rf components doc etc .gitignore

# 2. 创建干净的安装目录
sudo mkdir -p /opt/pkg/petalinux
sudo chown $USER:$USER /opt/pkg/petalinux

# 3. 使用 -d 参数（而不是 --dir）
./petalinux-v2020.2-final-installer.run -d /opt/pkg/petalinux
```

### 卡点4：安装程序要求root权限

**症状**：
```
ERROR: Cannot install as root user.
```

**解决**：使用非root用户执行安装
```bash
# 确保当前用户不是root
whoami  # 应该显示 uisrc 或其他非root用户名

# 如果当前是root，切换到普通用户
su - uisrc
```

### 卡点5：SSH连接被拒绝

**症状**：`ssh uisrc@192.168.46.128` 返回 "Connection refused"

**解决**：
```bash
# 在VM中安装并启动SSH服务
sudo apt-get install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
sudo ufw allow ssh

# 检查SSH服务状态
sudo systemctl status ssh
```

### 卡点6：SSH主机密钥验证失败

**症状**：
```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

**解决**：
```bash
# 在Windows端删除旧的主机密钥
ssh-keygen -R 192.168.46.128

# 重新连接并接受新密钥
ssh uisrc@192.168.46.128
```

---

## ✅ 验证安装

```bash
# 1. 检查PetaLinux版本
petalinux-version

# 2. 检查环境变量
echo $PETALINUX

# 3. 检查工具链
arm-xilinx-linux-gnueabi-gcc --version

# 预期输出：
# arm-xilinx-linux-gnueabi-gcc (GCC) 9.2.0
```

---

## 📝 快速参考

### 常用命令
```bash
# 激活PetaLinux环境
source /opt/pkg/petalinux/settings.sh

# 创建PetaLinux项目
petalinux-create -t project -n myproject --template zynq

# 配置项目
cd myproject
petalinux-config --get-hw-description=/path/to/xsa

# 构建项目
petalinux-build

# 打包BOOT.BIN
petalinux-package --boot --fsbl --fpga --u-boot
```

### 目录结构
```
/opt/pkg/petalinux/          # PetaLinux安装目录
├── settings.sh              # 环境变量配置脚本
├── components/               # 组件源码
├── tools/                   # 工具链
└── ...
```

---

## 🔗 相关文档

- [PetaLinux用户指南](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_2/ug1144-petalinux-tools-reference-guide.pdf)
- [项目快速开始指南](../QUICK_START_GUIDE.md)
- [PetaLinux常见问题](../PETALINUX_FAQ.md)

---

**最后更新**：2025-01-30  
**适用版本**：PetaLinux 2020.2, Ubuntu 18.04

