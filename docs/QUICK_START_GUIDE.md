# 快速开始指南：从现有XSA到SD卡

## ✅ 你的情况分析

### 1. XSA文件是否具备条件？

**如果Standalone的hello world能运行，说明**：
- ✅ PS（ARM处理器）配置正确
- ✅ 基本外设（UART、GPIO等）配置正确
- ✅ XSA文件基本可用

**但需要注意**：
- ⚠️ **PL（FPGA）逻辑**：如果Standalone中没有使用PL，XSA可能只包含PS配置
- ⚠️ **ADC相关硬件**：如果后续需要ADC功能，可能需要添加PL逻辑（AXI接口等）
- ⚠️ **显示相关硬件**：如果使用显示，可能需要VDMA等PL IP

**检查XSA内容**：
```bash
# 在Vivado中打开XSA，检查：
# 1. 是否有PL逻辑（Block Design中是否有PL IP）
# 2. 是否有Bitstream文件（.bit）
# 3. 是否包含所有需要的外设
```

**结论**：
- ✅ **可以先用现有XSA开始**
- ⚠️ 如果后续需要PL功能（ADC、显示等），可能需要更新XSA
- ✅ 对于基本的Linux系统，PS配置就足够了

---

## 2. 虚拟机安装PetaLinux

### ✅ 是的，可以直接在现有虚拟机上安装

**前提条件**：
- ✅ 已有Ubuntu虚拟机（16.04/18.04/20.04）
- ✅ 虚拟机有足够资源（8GB+内存，100GB+硬盘）

**安装步骤**：

#### 1. 准备依赖
```bash
# 在Ubuntu虚拟机中
sudo apt-get update
sudo apt-get install -y \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev \
    xterm autoconf libtool libglib2.0-dev libarchive-dev \
    python3-git python3-jinja2 libncurses5-dev libncursesw5-dev \
    zlib1g-dev locales
```

#### 2. 获取PetaLinux安装包
```bash
# 从资料中获取
# 位置：05_驱动和工具软件/Linux/Petalinux/petalinux-v2018.3-final-installer.rar
# 需要先解压（在Windows上用WinRAR，或Linux上用unrar）

# 如果虚拟机可以访问Windows共享文件夹，直接复制
# 或者用scp从Windows传输到虚拟机
```

#### 3. 安装PetaLinux
```bash
# 1. 解压（如果在Linux上）
unrar x petalinux-v2018.3-final-installer.rar

# 2. 添加执行权限
chmod +x petalinux-v2018.3-final-installer.run

# 3. 运行安装程序
./petalinux-v2018.3-final-installer.run

# 4. 选择安装路径（建议：/opt/pkg/petalinux）
# 5. 等待安装完成（30分钟到1小时）
```

#### 4. 设置环境变量
```bash
# 在 ~/.bashrc 中添加
echo 'source /opt/pkg/petalinux/2018.3/settings.sh' >> ~/.bashrc

# 或者每次使用时手动source
source /opt/pkg/petalinux/2018.3/settings.sh

# 验证安装
petalinux-version
```

---

## 3. 使用小梅哥脚本集生成SD卡内容

### ✅ 是的，脚本集可以生成完整的SD卡内容

**完整流程**：

#### 第一步：准备工程
```bash
# 1. 复制出厂工程到工作目录（在虚拟机中）
cp -r /path/to/AC820_Zynq_Linux_Factory /path/to/workspace
cd /path/to/workspace

# 2. 复制你的XSA文件到工程目录
cp /path/to/your.xsa hdf/system_wrapper.xsa
# 或者保持原有XSA，后续替换
```

#### 第二步：加载XSA
```bash
# 使用do脚本加载XSA
./do load hdf/system_wrapper.xsa

# 这会：
# - 生成设备树
# - 生成FSBL
# - 复制bitstream（如果有）
```

#### 第三步：配置系统（可选）
```bash
# 配置内核（如果需要）
./do config kernel

# 配置设备树（添加ADC节点等，如果需要）
./do config dts
# 或直接编辑：user_dts/system-user.dtsi

# 配置根文件系统（添加开发工具等）
./do config rootfs
```

#### 第四步：构建系统
```bash
# 构建内核、U-Boot、设备树
./do build images

# 构建根文件系统
./do build rootfs

# 打包BOOT.BIN
./do package boot
```

#### 第五步：准备SD卡
```bash
# 1. 插入SD卡到虚拟机（需要配置USB设备直通）
# 2. 格式化SD卡
./do format sdcard

# 3. 复制启动文件
./do images sdcard

# 4. 复制根文件系统
./do rootfs sdcard
```

**完成后，SD卡包含**：
```
SD卡/
├── 分区1（FAT32，boot）：
│   ├── BOOT.BIN          # 启动文件
│   ├── zImage            # Linux内核
│   ├── system.dtb        # 设备树
│   └── boot.scr          # U-Boot脚本（如果有）
│
└── 分区2（EXT4，rootfs）：
    └── 根文件系统内容（完整的Linux系统）
```

---

## 4. 完整工作流程总结

### 你的情况：已有XSA + 虚拟机

```
1. 在虚拟机中安装PetaLinux工具链
   ↓
2. 复制出厂工程到虚拟机
   ↓
3. 复制你的XSA文件到工程目录
   ↓
4. 使用do脚本加载XSA
   ./do load hdf/system_wrapper.xsa
   ↓
5. 配置系统（可选）
   ./do config kernel
   ./do config rootfs
   ↓
6. 构建系统
   ./do build images
   ./do build rootfs
   ./do package boot
   ↓
7. 准备SD卡
   ./do format sdcard
   ./do images sdcard
   ./do rootfs sdcard
   ↓
8. SD卡已准备好，可以插入ZYNQ板子启动
```

---

## 5. 可能遇到的问题和解决方案

### 问题1：XSA只有PS配置，没有PL逻辑

**情况**：
- Standalone的hello world可能只用了PS
- XSA可能不包含PL逻辑（没有.bit文件）

**解决方案**：
- ✅ **对于基本Linux系统，PS配置就足够了**
- ⚠️ 如果后续需要ADC、显示等功能，需要：
  1. 在Vivado中添加PL逻辑
  2. 重新导出XSA
  3. 重新加载XSA到PetaLinux工程

### 问题2：虚拟机无法识别SD卡

**解决方案**：
```bash
# 1. 在虚拟机设置中配置USB设备直通
# 2. 或者使用USB转接器
# 3. 或者先在Windows上格式化SD卡，然后在虚拟机中挂载
```

### 问题3：PetaLinux版本不匹配

**情况**：
- 出厂工程可能使用PetaLinux 2020.1
- 资料中提供的是PetaLinux 2018.3

**解决方案**：
- ✅ 可以尝试使用2018.3（通常向后兼容）
- ⚠️ 如果遇到问题，可能需要下载对应版本的PetaLinux
- 💡 或者使用出厂工程已有的配置，只替换XSA

---

## 6. 快速验证清单

### ✅ 准备工作
- [ ] 虚拟机已安装Ubuntu
- [ ] 虚拟机有足够资源（8GB+内存，100GB+硬盘）
- [ ] 已有XSA文件（Standalone能运行）
- [ ] 已获取PetaLinux安装包

### ✅ 安装步骤
- [ ] 安装PetaLinux依赖
- [ ] 安装PetaLinux工具
- [ ] 设置环境变量
- [ ] 验证安装（`petalinux-version`）

### ✅ 构建步骤
- [ ] 复制出厂工程
- [ ] 加载XSA（`./do load`）
- [ ] 构建系统（`./do build images`）
- [ ] 打包BOOT.BIN（`./do package boot`）

### ✅ SD卡准备
- [ ] 格式化SD卡（`./do format sdcard`）
- [ ] 复制启动文件（`./do images sdcard`）
- [ ] 复制根文件系统（`./do rootfs sdcard`）

---

## 7. 总结

### 你的问题回答

**Q1: XSA是否具备条件？**
- ✅ **是的，如果Standalone能运行，XSA基本可用**
- ⚠️ 对于基本Linux系统，PS配置就足够
- ⚠️ 如果后续需要PL功能，可能需要更新XSA

**Q2: 可以直接在虚拟机上安装PetaLinux？**
- ✅ **是的，直接在现有Ubuntu虚拟机上安装即可**

**Q3: 使用小梅哥脚本集能得到完整SD卡内容？**
- ✅ **是的，脚本集可以生成完整的SD卡内容**
- ✅ 包括：BOOT.BIN、内核、设备树、根文件系统

### 🚀 立即开始

```bash
# 1. 在虚拟机中安装PetaLinux
./petalinux-v2018.3-final-installer.run

# 2. 复制出厂工程
cp -r AC820_Zynq_Linux_Factory workspace
cd workspace

# 3. 加载XSA
./do load hdf/system_wrapper.xsa

# 4. 构建
./do build images
./do build rootfs
./do package boot

# 5. 准备SD卡
./do format sdcard
./do images sdcard
./do rootfs sdcard
```

**完成！SD卡已准备好，可以插入ZYNQ板子启动Linux系统了！**

