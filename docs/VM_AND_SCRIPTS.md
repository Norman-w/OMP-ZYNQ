# 虚拟机镜像和自动化构建脚本

## 1. 虚拟机镜像情况

### 📦 小梅哥资料中的虚拟机相关文件

**位置**：`11_虚拟机/`

**内容**：
- ✅ `ubuntu-16.04.4-desktop-amd64.iso` - Ubuntu 16.04 ISO镜像
- ✅ `ubuntu-18.04.4-desktop-amd64.iso` - Ubuntu 18.04 ISO镜像
- ✅ `VMware/` - VMware虚拟机软件

**结论**：
- ❌ **没有预装PetaLinux的虚拟机镜像**（.ova、.vmdk等）
- ✅ 只有Ubuntu ISO镜像，需要自己安装和配置PetaLinux

### 🔧 需要自己安装PetaLinux

如果使用提供的Ubuntu ISO，需要：

1. **安装Ubuntu**（使用提供的ISO）
2. **安装PetaLinux工具**：
   ```bash
   # 下载PetaLinux安装包（从Xilinx官网或资料中的05_驱动和工具软件/Linux/Petalinux/）
   # 安装
   ./petalinux-v2020.1-final-installer.run
   ```

**或者**：
- 使用资料中的PetaLinux安装包：`05_驱动和工具软件/Linux/Petalinux/`

---

## 2. 自动化构建脚本（脚手架）

### ✅ 出厂工程已提供完整的构建脚本

**位置**：`D:/ZYNQ/Norman/linux_factory_extract/AC820_Zynq_Linux_Factory/scripts/`

### 🎯 核心脚本：`do` - 统一命令入口

这是一个**统一的命令入口脚本**，提供了所有常用操作的快捷方式：

```bash
# 使用方法
./do <命令> <参数>

# 命令列表：
./do load xxxx              # 加载xxxx.xsa文件
./do config kernel          # 进入kernel配置界面
./do config uboot            # 进入uboot配置界面
./do config dts              # 修改dts文件
./do config rootfs           # 进入rootfs配置界面
./do build kernel            # 编译kernel
./do build uboot             # 编译uboot
./do build dts               # 编译dts文件
./do build rootfs            # 编译rootfs
./do build images            # 编译kernel,uboot,dts
./do package boot            # 打包生成BOOT.BIN文件
./do clean kernel            # 清理kernel
./do clean uboot             # 清理uboot
./do clean plnx              # 清理petalinux工程
./do format sdcard           # 格式化SD卡
./do images sdcard            # 启动文件-->SD卡的boot分区
./do rootfs sdcard            # 根文件系统-->SD卡的rootfs分区
```

### 📋 完整工作流程示例

#### 从XSA到SD卡的完整流程：

```bash
# 1. 加载XSA文件（导入硬件配置）
./do load ../hdf/system_wrapper.xsa

# 2. 配置内核（如果需要）
./do config kernel

# 3. 配置设备树（添加ADC节点等）
./do config dts

# 4. 配置根文件系统（添加开发工具等）
./do config rootfs

# 5. 构建所有组件
./do build images
./do build rootfs

# 6. 打包生成BOOT.BIN
./do package boot

# 7. 格式化SD卡（首次使用）
./do format sdcard

# 8. 复制启动文件到SD卡
./do images sdcard

# 9. 复制根文件系统到SD卡
./do rootfs sdcard
```

### 🔍 各个脚本的功能

#### `load_hdf.sh` - 加载XSA/HDF文件
```bash
# 功能：
# 1. 从XSA/HDF提取设备树信息
# 2. 生成FSBL
# 3. 复制设备树文件到内核和U-Boot目录
# 4. 复制bitstream文件
```

#### `build_kernel.sh` - 编译内核
```bash
# 功能：编译Linux内核
```

#### `build_uboot.sh` - 编译U-Boot
```bash
# 功能：编译U-Boot引导程序
```

#### `build_dts.sh` - 编译设备树
```bash
# 功能：编译设备树文件（.dts → .dtb）
```

#### `build_rootfs.sh` - 构建根文件系统
```bash
# 功能：构建根文件系统
```

#### `package_boot.sh` - 打包BOOT.BIN
```bash
# 功能：将FSBL、Bitstream、U-Boot打包成BOOT.BIN
```

#### `format_sdcard.sh` - 格式化SD卡
```bash
# 功能：
# 1. 自动检测SD卡设备（sdb或sdc）
# 2. 创建两个分区：
#    - 分区1：FAT32，100MB（启动分区）
#    - 分区2：EXT4，剩余空间（根文件系统分区）
# 3. 格式化分区
```

#### `images_sdcard.sh` - 复制启动文件
```bash
# 功能：将BOOT.BIN、内核、设备树等复制到SD卡boot分区
```

#### `rootfs_sdcard.sh` - 复制根文件系统
```bash
# 功能：将根文件系统解压到SD卡rootfs分区
```

---

## 3. 创建自己的快速构建脚本

### 🚀 一键构建脚本示例

基于出厂工程的脚本，可以创建一个更高级的自动化脚本：

```bash
#!/bin/bash
# build_all.sh - 从XSA到SD卡的一键构建脚本

set -e  # 遇到错误立即退出

# 配置
XSA_FILE="${1:-../hdf/system_wrapper.xsa}"
SD_DEV="${2:-sdb}"

echo "=========================================="
echo "OMP Linux 一键构建脚本"
echo "=========================================="

# 检查XSA文件
if [ ! -f "$XSA_FILE" ]; then
    echo "错误: XSA文件不存在: $XSA_FILE"
    exit 1
fi

# 1. 加载XSA
echo "[1/8] 加载XSA文件..."
./do load "$XSA_FILE"

# 2. 构建内核、U-Boot、设备树
echo "[2/8] 构建内核、U-Boot、设备树..."
./do build images

# 3. 构建根文件系统
echo "[3/8] 构建根文件系统..."
./do build rootfs

# 4. 打包BOOT.BIN
echo "[4/8] 打包BOOT.BIN..."
./do package boot

# 5. 检查SD卡
echo "[5/8] 检查SD卡设备..."
if [ ! -b "/dev/${SD_DEV}" ]; then
    echo "错误: SD卡设备不存在: /dev/${SD_DEV}"
    exit 1
fi

# 6. 格式化SD卡（可选，需要确认）
read -p "是否格式化SD卡? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[6/8] 格式化SD卡..."
    ./do format sdcard
else
    echo "[6/8] 跳过格式化SD卡"
fi

# 7. 复制启动文件
echo "[7/8] 复制启动文件到SD卡..."
./do images sdcard

# 8. 复制根文件系统
echo "[8/8] 复制根文件系统到SD卡..."
./do rootfs sdcard

echo "=========================================="
echo "构建完成！SD卡已准备好。"
echo "=========================================="
```

**使用方法**：
```bash
# 使用默认XSA和SD卡设备
./build_all.sh

# 指定XSA文件和SD卡设备
./build_all.sh /path/to/your.xsa sdc
```

### 📝 添加用户代码的脚本

如果需要自动添加用户应用代码：

```bash
#!/bin/bash
# add_user_app.sh - 添加用户应用代码到根文件系统

USER_APP_DIR="${1:-../user_apps}"
ROOTFS_DIR="images/rootfs"

echo "添加用户应用代码..."

# 检查用户代码目录
if [ ! -d "$USER_APP_DIR" ]; then
    echo "错误: 用户代码目录不存在: $USER_APP_DIR"
    exit 1
fi

# 创建应用目录
mkdir -p "$ROOTFS_DIR/usr/local/bin"
mkdir -p "$ROOTFS_DIR/etc/init.d"

# 复制应用文件
echo "复制应用文件..."
cp -r "$USER_APP_DIR/bin/"* "$ROOTFS_DIR/usr/local/bin/" 2>/dev/null || true
cp -r "$USER_APP_DIR/scripts/"* "$ROOTFS_DIR/etc/init.d/" 2>/dev/null || true

# 设置权限
chmod +x "$ROOTFS_DIR/usr/local/bin/"* 2>/dev/null || true
chmod +x "$ROOTFS_DIR/etc/init.d/"* 2>/dev/null || true

echo "用户应用代码已添加到根文件系统"
```

---

## 4. 推荐的完整工作流程

### 第一次使用（设置环境）

```bash
# 1. 复制出厂工程到工作目录
cp -r D:/ZYNQ/Norman/linux_factory_extract/AC820_Zynq_Linux_Factory \
      D:/ZYNQ/Norman/OMP/linux_workspace

# 2. 进入工作目录
cd D:/ZYNQ/Norman/OMP/linux_workspace

# 3. 加载XSA（使用出厂XSA或自己的XSA）
./do load hdf/system_wrapper.xsa

# 4. 配置系统（根据需要）
./do config kernel    # 配置内核
./do config rootfs    # 配置根文件系统
./do config dts       # 修改设备树（添加ADC节点等）
```

### 日常开发（快速构建）

```bash
# 1. 修改代码后，构建
./do build images
./do build rootfs
./do package boot

# 2. 烧录到SD卡
./do images sdcard
./do rootfs sdcard
```

### 一键构建（使用自定义脚本）

```bash
# 创建一键构建脚本
cat > build_all.sh << 'EOF'
#!/bin/bash
./do load hdf/system_wrapper.xsa
./do build images
./do build rootfs
./do package boot
./do images sdcard
./do rootfs sdcard
EOF

chmod +x build_all.sh

# 使用
./build_all.sh
```

---

## 5. 总结

### 虚拟机镜像
- ❌ **没有预装PetaLinux的虚拟机镜像**
- ✅ 有Ubuntu ISO镜像，需要自己安装PetaLinux
- 💡 建议：使用Ubuntu 18.04 ISO，然后安装PetaLinux 2020.1

### 自动化脚本
- ✅ **出厂工程已提供完整的构建脚本**
- ✅ **`do` 脚本提供统一命令入口**
- ✅ 包含从XSA到SD卡的完整流程
- 💡 可以基于现有脚本创建更高级的自动化脚本

### 快速开始
1. 使用提供的Ubuntu ISO安装虚拟机
2. 安装PetaLinux工具
3. 复制出厂工程到工作目录
4. 使用 `./do` 脚本进行构建
5. 可以创建自定义的一键构建脚本

---

## 6. 下一步建议

1. **创建一键构建脚本**：基于 `do` 脚本，创建更高级的自动化脚本
2. **添加用户代码集成**：创建脚本自动将用户应用代码添加到根文件系统
3. **交叉编译工具链**：创建脚本自动设置交叉编译环境
4. **版本管理**：将构建脚本纳入Git管理

