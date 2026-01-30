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

#### 🌐 方式A：手动通过ISO安装Ubuntu后配置静态IP（推荐）

如果刚通过ISO手动安装完Ubuntu，需要配置静态IP地址，可以使用交互式配置向导：

```bash
# 进入项目目录
cd /path/to/OMP

# 运行静态IP配置脚本
chmod +x docs/quick_start/setup_static_ip.sh
./docs/quick_start/setup_static_ip.sh
```

脚本会：
- 📋 自动列出所有可用的网络连接
- 🎯 让你选择要配置的连接
- 💡 智能提示当前IP和网关作为默认值
- ⚙️ 交互式输入IP地址、网关、DNS等信息
- ✅ 自动应用配置并验证网络连接

**推荐配置**（VMware NAT模式）：
- IP地址：`192.168.46.128/24`
- 网关：`192.168.46.2`
- DNS：`8.8.8.8,8.8.4.4`

#### 🔧 方式B：手动配置网络

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
- 使用DHCP自动获取IP和网关，或使用静态IP配置

### 3. 配置软件源（重要！）

**⚠️ 关键步骤**：如果系统只有基础的 `bionic` 源，缺少 `bionic-updates` 和 `bionic-security`，会导致依赖冲突。必须先配置完整的软件源。

#### 检查当前软件源配置

```bash
# 检查是否缺少更新源
cat /etc/apt/sources.list | grep -E "updates|security"
```

如果输出为空或只有注释，说明缺少更新源，需要添加。

#### 配置完整的软件源（推荐使用清华镜像）

```bash
# 备份原配置
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 配置完整的软件源（包含updates和security）
sudo tee /etc/apt/sources.list > /dev/null << 'EOF'
# 清华大学镜像源 - Ubuntu 18.04
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
EOF

# 更新软件包列表
sudo apt-get update
```

**为什么需要更新源？**
- 系统可能已安装来自 `updates` 源的新版本运行时库
- 开发包（`-dev`）如果只能从基础源获取，会要求旧版本
- 版本不匹配导致依赖冲突
- 添加 `updates` 源后，开发包也能获取匹配的新版本，解决冲突

### 4. 安装PetaLinux依赖

```bash
# 1. 添加32位架构支持（PetaLinux需要）
sudo dpkg --add-architecture i386
sudo apt-get update

# 2. 安装基础依赖
sudo apt-get install -y \
    tofrodos iproute2 gawk gcc g++ git make net-tools libncurses5-dev \
    tftpd zlib1g:i386 libssl-dev flex bison libselinux1 gnupg wget diffstat chrpath socat \
    xterm autoconf libtool tar unzip texinfo zlib1g-dev gcc-multilib build-essential \
    libsdl1.2-dev libglib2.0-dev screen pax gzip automake \
    python python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    libarchive-dev libexpat1-dev libpng-dev libasound2-dev libpulse-dev \
    libcaca-dev libncursesw5-dev python3-dev
```

**注意**：
- 如果遇到配置文件冲突提示（如 `default.pa`），通常选择 `Y` 安装维护者版本
- 如果仍有依赖冲突，参考故障排除章节

### 5. 安装PetaLinux

```bash
# 创建安装目录（小梅哥建议的目录结构）
sudo mkdir -p /opt/Petalinux/2020.2
sudo chown $USER:$USER /opt/Petalinux/2020.2

# 进入安装包所在目录（通常是~/）
cd ~

# 执行安装（使用 -d 参数指定安装目录）
./petalinux-v2020.2-final-installer.run -d /opt/Petalinux/2020.2

# 安装过程中：
# 1. 阅读并接受license（输入 y）
# 2. 等待安装完成（约10-30分钟）
```

### 6. 配置环境变量

```bash
# 编辑 ~/.bashrc
nano ~/.bashrc

# 添加以下内容
source /opt/Petalinux/2020.2/settings.sh

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
libarchive-dev : 依赖: libarchive13 (= 3.2.2-3.1) 但是 3.2.2-3.1ubuntu0.5 正要被安装
```

**最常见原因**：软件源配置不完整，缺少 `bionic-updates` 和 `bionic-security` 源
- 系统已安装来自 `updates` 源的新版本运行时库
- 开发包只能从基础源获取，要求旧版本
- 版本不匹配导致依赖冲突

**解决**（按优先级）：

**方法1：添加更新源（推荐，通常能解决问题）**
```bash
# 检查是否缺少更新源
cat /etc/apt/sources.list | grep -E "updates|security"

# 如果输出为空，添加完整的软件源（参考步骤3）
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo tee /etc/apt/sources.list > /dev/null << 'EOF'
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
EOF

sudo apt-get update
# 然后重新安装依赖
```

**方法2：使用aptitude自动解决依赖**
```bash
sudo apt-get install -y aptitude
sudo aptitude install -y gcc-multilib
# aptitude会提供多个解决方案，通常选择第一个（按Y接受）
```

**方法3：强制安装32位库（谨慎使用）**
```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y libc6:i386 zlib1g:i386 --allow-downgrades
```

**建议**：优先使用方法1（添加更新源），这是最根本的解决方案。如果持续失败，考虑使用Docker容器或升级到Ubuntu 20.04。

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
sudo mkdir -p /opt/Petalinux/2020.2
sudo chown $USER:$USER /opt/Petalinux/2020.2

# 3. 使用 -d 参数（而不是 --dir）
./petalinux-v2020.2-final-installer.run -d /opt/Petalinux/2020.2
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

### 卡点7：构建时下载源码包很慢或卡住

**症状**：`petalinux-build` 执行时下载源码包非常慢，或长时间无响应

**原因**：无法访问国外源（GitHub、SourceForge等），网络连接慢

**解决：配置SOCKS5代理（推荐）**

如果Windows主机上有SOCKS5代理（如 `192.168.7.88:10080`），可以在VM上配置使用：

```bash
# 1. 安装proxychains4
sudo apt-get install -y proxychains4

# 2. 配置代理
sudo tee /etc/proxychains.conf > /dev/null << 'EOF'
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 192.168.7.88 10080
EOF

# 3. 测试代理是否工作
proxychains4 wget -O- --timeout=10 https://www.google.com 2>&1 | grep -E 'OK|已连接|200'
# 如果看到 "200 OK" 或 "已连接"，说明代理工作正常

# 4. 使用代理构建PetaLinux
cd ~/petalinux-projects/OMP
source /opt/Petalinux/2020.2/settings.sh
proxychains4 petalinux-build
```

**注意**：
- 将 `192.168.7.88:10080` 替换为你的实际代理地址和端口
- 代理必须能从VM访问到（确保网络连通）
- 如果DNS解析显示 `224.0.0.1` 是正常的（proxychains的proxy_dns机制）

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
source /opt/Petalinux/2020.2/settings.sh

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
/opt/Petalinux/2020.2/       # PetaLinux安装目录（小梅哥建议的目录结构）
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

