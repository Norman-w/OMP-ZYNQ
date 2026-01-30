# 脚本兼容性和PetaLinux安装说明

## 1. do系列脚本的平台兼容性

### 📋 脚本类型分析

**所有脚本都是Bash脚本**：
- 文件头：`#!/bin/bash` 或 `#!/bin/sh`
- 使用Linux/Unix命令（`source`, `cd`, `cp`, `mkdir`等）
- 使用Linux路径分隔符（`/`）

### ✅ 可以在哪些平台运行？

#### Linux（原生支持）
- ✅ **完全支持**
- ✅ 直接运行：`./do load xxxx.xsa`
- ✅ 无需额外配置

#### macOS（部分支持）
- ✅ **可以运行**（macOS基于Unix）
- ⚠️ **但PetaLinux工具本身不支持macOS**
- ⚠️ 即使脚本能运行，也无法使用PetaLinux功能

**macOS上的限制**：
```bash
# macOS可以运行脚本
./do load xxxx.xsa

# 但会失败，因为：
# 1. PetaLinux工具不支持macOS
# 2. 无法执行 petalinux-build 等命令
# 3. 无法使用交叉编译工具链
```

**macOS上的替代方案**：
- 使用Docker运行Linux容器
- 使用虚拟机（VMware Fusion/Parallels）
- 使用远程Linux服务器

#### Windows（不支持）
- ❌ **不能直接运行**
- ❌ Windows没有Bash（除非使用WSL/Git Bash）
- ❌ 即使使用WSL，PetaLinux工具也有兼容性问题

**Windows上的解决方案**：

**方案1：使用WSL2（推荐）**
```bash
# 1. 安装WSL2（Windows Subsystem for Linux）
# 2. 安装Ubuntu发行版
# 3. 在WSL2中安装PetaLinux
# 4. 运行脚本
```

**方案2：使用Git Bash（有限支持）**
```bash
# 1. 安装Git for Windows（包含Git Bash）
# 2. 使用Git Bash运行脚本
# ⚠️ 但PetaLinux工具仍然无法在Windows上运行
```

**方案3：使用虚拟机（最可靠）**
```bash
# 1. 安装VMware/VirtualBox
# 2. 安装Ubuntu虚拟机
# 3. 在虚拟机中运行
```

---

## 2. PetaLinux工具链安装说明

### 📦 .run文件是什么？

**`.run`文件是Linux安装程序**：
- 类似于Windows的`.exe`安装程序
- 是自解压的安装脚本
- 包含PetaLinux工具的所有文件

### 🖥️ 运行平台要求

#### ✅ 支持平台
- ✅ **Linux（Ubuntu 16.04/18.04/20.04）**
- ✅ **Red Hat Enterprise Linux (RHEL)**
- ✅ **CentOS**

#### ❌ 不支持平台
- ❌ **Windows**（原生不支持）
- ❌ **macOS**（原生不支持）

### 📋 安装步骤

#### 1. 准备环境（Ubuntu）

**系统要求**：
- Ubuntu 16.04/18.04/20.04（推荐18.04）
- 至少8GB内存（推荐16GB+）
- 至少100GB硬盘空间
- 64位系统

**安装依赖**：
```bash
# Ubuntu 18.04依赖
sudo apt-get update
sudo apt-get install -y \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev \
    xterm autoconf libtool libglib2.0-dev libarchive-dev \
    python3-git python3-jinja2 libncurses5-dev libncursesw5-dev \
    zlib1g-dev locales
```

#### 2. 下载安装包

**位置**：
- 小梅哥资料：`05_驱动和工具软件/Linux/Petalinux/`
- Xilinx官网：https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html

**文件名示例**：
```
petalinux-v2020.1-final-installer.run
petalinux-v2021.1-final-installer.run
```

#### 3. 运行安装程序

```bash
# 1. 给安装程序添加执行权限
chmod +x petalinux-v2020.1-final-installer.run

# 2. 运行安装程序
./petalinux-v2020.1-final-installer.run

# 3. 按照提示操作：
#    - 选择安装路径（如：/opt/pkg/petalinux）
#    - 等待安装完成（可能需要30分钟到1小时）
```

#### 4. 设置环境变量

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
source /opt/pkg/petalinux/2020.1/settings.sh

# 或者每次使用时手动source
source /opt/pkg/petalinux/2020.1/settings.sh
```

### 🔍 安装后的验证

```bash
# 检查PetaLinux是否安装成功
petalinux-version

# 应该显示版本号，如：
# petalinux 2020.1
```

---

## 3. 各平台完整方案

### 🐧 Linux（Ubuntu）

**完全支持**：
```bash
# 1. 安装PetaLinux
./petalinux-v2020.1-final-installer.run

# 2. 设置环境
source /opt/pkg/petalinux/2020.1/settings.sh

# 3. 运行脚本
./do load xxxx.xsa
./do build images
```

### 🍎 macOS

**方案A：使用Docker（推荐）**
```bash
# 1. 安装Docker Desktop for Mac
# 2. 拉取Ubuntu镜像
docker pull ubuntu:18.04

# 3. 运行容器
docker run -it -v /path/to/project:/workspace ubuntu:18.04

# 4. 在容器中安装PetaLinux
# 5. 运行脚本
```

**方案B：使用虚拟机**
```bash
# 1. 安装VMware Fusion或Parallels
# 2. 安装Ubuntu虚拟机
# 3. 在虚拟机中安装PetaLinux
# 4. 运行脚本
```

**方案C：使用远程Linux服务器**
```bash
# 1. 连接到远程Linux服务器（SSH）
# 2. 在服务器上安装PetaLinux
# 3. 在服务器上运行脚本
```

### 🪟 Windows

**方案A：使用WSL2（推荐）**
```powershell
# 1. 启用WSL2
wsl --install

# 2. 安装Ubuntu发行版
# 3. 在WSL2中安装PetaLinux
# 4. 运行脚本
```

**方案B：使用虚拟机**
```bash
# 1. 安装VMware Workstation或VirtualBox
# 2. 安装Ubuntu虚拟机
# 3. 在虚拟机中安装PetaLinux
# 4. 运行脚本
```

**方案C：使用Git Bash（仅脚本，不支持PetaLinux）**
```bash
# 1. 安装Git for Windows
# 2. 使用Git Bash运行脚本
# ⚠️ 但PetaLinux工具无法运行
```

---

## 4. 脚本内容分析

### do脚本示例
```bash
#!/bin/bash
# 这是Bash脚本，需要Bash解释器

if [ $1 == "load" ]
then
    echo "load $2 运行"
    source scripts/load_hdf.sh $2
elif [ -e "scripts/$1_$2.sh" ]
then
    echo "$1 $2 运行"
    scripts/$1_$2.sh
fi
```

### 关键依赖
- `bash` 或 `sh` 解释器
- Linux命令：`source`, `cd`, `cp`, `mkdir`, `fdisk`等
- PetaLinux工具：`petalinux-build`, `petalinux-config`等
- Xilinx工具：`xsct`（Xilinx Software Command-line Tool）

---

## 5. 推荐方案总结

| 平台 | 脚本运行 | PetaLinux运行 | 推荐方案 |
|------|---------|--------------|---------|
| **Linux** | ✅ 原生支持 | ✅ 原生支持 | 直接使用 |
| **macOS** | ✅ 可以运行 | ❌ 不支持 | Docker或虚拟机 |
| **Windows** | ⚠️ WSL/Git Bash | ❌ 不支持 | WSL2或虚拟机 |

### 💡 最佳实践

**对于macOS和Windows用户**：
1. **推荐使用虚拟机**（最稳定）
   - VMware Fusion（macOS）
   - VMware Workstation（Windows）
   - 或VirtualBox（免费）

2. **安装Ubuntu 18.04虚拟机**
   - 分配足够资源（8GB+内存，100GB+硬盘）
   - 安装PetaLinux工具
   - 在虚拟机中完成所有开发工作

3. **文件共享**
   - 使用共享文件夹在主机和虚拟机间共享文件
   - 或使用网络共享

---

## 6. 快速检查脚本兼容性

### 检查Bash是否可用

**Linux/macOS**：
```bash
which bash
# 应该显示：/bin/bash 或 /usr/bin/bash
```

**Windows（Git Bash）**：
```bash
which bash
# 应该显示：C:\Program Files\Git\bin\bash.exe
```

### 检查PetaLinux是否安装

```bash
petalinux-version
# 如果显示版本号，说明安装成功
# 如果显示"command not found"，说明未安装或未设置环境
```

### 检查环境变量

```bash
echo $PETALINUX
# 应该显示PetaLinux安装路径
# 如果为空，需要source settings.sh
```

---

## 7. 总结

### 脚本兼容性
- ✅ **Linux**：完全支持
- ✅ **macOS**：脚本可以运行，但PetaLinux不支持
- ⚠️ **Windows**：需要WSL或Git Bash，但PetaLinux不支持

### PetaLinux安装
- ✅ **.run文件**：Linux安装程序
- ✅ **运行平台**：仅支持Linux（Ubuntu/RHEL/CentOS）
- ❌ **不支持**：Windows和macOS

### 推荐方案
- **Linux用户**：直接使用
- **macOS/Windows用户**：使用虚拟机（最可靠）

