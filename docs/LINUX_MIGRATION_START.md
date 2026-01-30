# Linux迁移起点指南

## 🎯 推荐起点：基于出厂工程修改（最快路径）

### 为什么选择这个路径？

1. **出厂工程已完整配置**：
   - ✅ 硬件描述文件（`hdf/system_wrapper.xsa`）已准备好
   - ✅ PetaLinux工程（`plnx_prj/`）已配置完成
   - ✅ 设备树已配置（包含以太网、USB、显示等）
   - ✅ 可烧录镜像（`images/BOOT.BIN`）已编译好

2. **节省时间**：
   - 不需要从零开始配置硬件
   - 不需要重新配置设备树
   - 可以直接在现有基础上添加ADC驱动

3. **风险最低**：
   - 出厂工程已经验证过，硬件配置正确
   - 可以先烧录测试，确认基础功能正常

## 📋 具体步骤

### 第一步：测试出厂镜像（验证硬件）

**目的**：确认硬件和基础功能是否正常

```bash
# 1. 找到预制作的镜像
位置：06_预制作镜像/ZYNQ7020/2020版本/AC820_7020_linux_new_factory.img

**触摸屏支持**：✅ 已配置
- 设备树中已配置 GT911/GT9147 触摸屏芯片
- 使用 `goodix,gt911` 驱动（Linux内核标准驱动）
- I2C地址：0x5d 或 0x14
- 如果触摸不工作，检查内核是否编译了驱动：`dmesg | grep -i gt911`

# 2. 烧录到SD卡
# 使用Win32DiskImager或dd命令

# 3. 测试功能
- 以太网连接
- USB WiFi（如果硬件已安装）
- 显示和触摸屏
- 基本Linux命令
```

**预期结果**：
- ✅ Linux系统正常启动
- ✅ 以太网可以连接
- ✅ 显示和触摸屏工作正常

### 第二步：复制出厂工程到工作目录

**目的**：创建一个可以修改的工作副本

```bash
# 1. 复制出厂工程
cp -r D:/ZYNQ/Norman/linux_factory_extract/AC820_Zynq_Linux_Factory \
      D:/ZYNQ/Norman/OMP/linux_workspace

# 2. 进入工作目录
cd D:/ZYNQ/Norman/OMP/linux_workspace

# 3. 检查关键文件
ls -la hdf/system_wrapper.xsa  # 硬件描述文件
ls -la plnx_prj/               # PetaLinux工程
ls -la images/BOOT.BIN         # 启动镜像
```

### 第三步：在PetaLinux中打开工程

**目的**：准备添加ADC驱动和修改配置

```bash
# 1. 设置PetaLinux环境（如果还没设置）
source /opt/pkg/petalinux/settings.sh

# 2. 进入PetaLinux工程目录
cd plnx_prj

# 3. 配置工程（如果需要修改）
petalinux-config

# 4. 构建工程（测试是否能正常编译）
petalinux-build
```

### 第四步：添加ADC驱动支持

**目的**：添加ACM7606/CM3432 ADC驱动

1. **参考Standalone工程**：
   - 查看 `D:/ZYNQ/Norman/OMP/PL/` 中的ADC控制逻辑
   - 了解AXI接口配置和寄存器映射

2. **创建Linux驱动**：
   - 方案A：字符设备驱动（推荐）
   - 方案B：UIO驱动（简单但性能较低）

3. **修改设备树**：
   - 在 `user_dts/system-user.dtsi` 中添加ADC节点
   - 配置AXI地址、中断等

## 🎯 Vitis方案：从XSA创建Platform（推荐给喜欢Vitis工作流的用户）

### 你的方案：XSA → Vitis创建Platform → PetaLinux构建系统 → Linux应用开发

**优点**：
- ✅ 统一开发环境（Vivado → Vitis → PetaLinux）
- ✅ Platform可复用，便于管理
- ✅ 符合Xilinx标准工作流

**实际流程**：
```
1. Vivado → 导出XSA（或使用出厂XSA：hdf/system_wrapper.xsa）
        ↓
2. Vitis → 创建Platform
   - File → New → Platform Project
   - 选择XSA文件
   - 配置：OS=linux, Processor=ps7_cortexa9_0
        ↓
3. PetaLinux → 导入Platform/XSA构建系统
   - petalinux-config --get-hw-description=<XSA路径>
   - 配置内核、驱动、根文件系统
   - petalinux-build
        ↓
4. Linux系统 → 开发应用
   - 在Linux用户空间开发（C/C++/Python）
   - 使用标准Linux API
```

**注意**：
- ⚠️ Vitis主要用于Platform创建，不是Linux应用开发环境
- ⚠️ Linux应用开发还是在Linux系统上进行
- ⚠️ Vitis提供Platform和BSP，PetaLinux构建完整系统

**详细说明**：参见 `docs/VITIS_VS_PETALINUX.md`

---

## 🔄 备选路径：从Vivado重新开始（如果需要修改硬件）

### 什么时候需要这个路径？

- ❌ 需要修改PL（FPGA）逻辑
- ❌ 需要添加新的AXI外设
- ❌ 需要修改时钟配置
- ❌ 需要修改DDR配置

### 步骤

1. **在Vivado中打开/创建工程**
   ```bash
   # 如果有Vivado工程文件
   # 07_Linux源码/ZYNQ7020/2020版本/AC820出厂工程和Linux源码/Zynq7020_484_Factory_prj.zip
   ```

2. **导出硬件描述文件（XSA）**
   - Vivado: File → Export → Export Hardware
   - 选择XSA格式（不是HDF，新版本用XSA）

3. **在Vitis中创建Platform**
   - Vitis: File → New → Platform Project
   - 选择导出的XSA文件
   - 配置处理器、内存等

4. **创建PetaLinux工程**
   ```bash
   petalinux-create -t project -n omp_linux --template zynq
   cd omp_linux
   petalinux-config --get-hw-description=<path-to-xsa>
   ```

## ❌ 不推荐：直接烧录镜像后修改

**为什么不推荐**：
- 镜像文件是二进制，无法直接修改
- 需要重新编译才能添加功能
- 无法追踪修改历史

**什么时候可以**：
- 只是想快速测试硬件功能
- 不需要添加任何自定义功能

## 📊 路径对比

| 路径 | 时间 | 难度 | 灵活性 | 推荐度 |
|------|------|------|--------|--------|
| **基于出厂工程修改** | ⭐⭐ 快 | ⭐⭐ 中等 | ⭐⭐⭐⭐ 高 | ⭐⭐⭐⭐⭐ **最推荐** |
| **Vitis创建Platform** | ⭐⭐⭐ 中等 | ⭐⭐⭐ 中等 | ⭐⭐⭐⭐⭐ 最高 | ⭐⭐⭐⭐ **推荐（喜欢Vitis工作流）** |
| 从Vivado重新开始 | ⭐⭐⭐⭐ 慢 | ⭐⭐⭐⭐ 难 | ⭐⭐⭐⭐⭐ 最高 | ⭐⭐⭐ 需要时 |
| 直接烧录镜像 | ⭐ 最快 | ⭐ 简单 | ⭐ 低 | ⭐⭐ 仅测试 |

## 🎯 最终建议

**立即开始**：
1. ✅ **先烧录出厂镜像测试**（10分钟）
   - 确认硬件正常
   - 熟悉Linux系统

2. ✅ **复制出厂工程到工作目录**（5分钟）
   - 创建可修改的工作副本
   - 保留原工程作为参考

3. ✅ **在PetaLinux中打开工程**（30分钟）
   - 熟悉工程结构
   - 测试编译流程

4. ✅ **开始添加ADC驱动**（后续工作）
   - 参考Standalone工程
   - 编写Linux驱动

**可选**：
- ✅ 在Vitis中创建Platform（如果喜欢Vitis工作流，便于Platform管理）
- ❌ 从Vivado重新创建XSA（除非硬件需要修改）

## 📁 关键文件位置

```
出厂工程（已解压）：
D:/ZYNQ/Norman/linux_factory_extract/AC820_Zynq_Linux_Factory/
├── hdf/system_wrapper.xsa      # 硬件描述文件（Vivado导出）
├── plnx_prj/                    # PetaLinux工程
├── images/BOOT.BIN              # 可烧录镜像
├── user_dts/system-user.dtsi    # 用户设备树配置
└── scripts/                     # 构建脚本

预制作镜像：
06_预制作镜像/ZYNQ7020/2020版本/AC820_7020_linux_new_factory.img

Vivado工程（如果需要修改硬件）：
07_Linux源码/ZYNQ7020/2020版本/AC820出厂工程和Linux源码/Zynq7020_484_Factory_prj.zip
```

## 🚀 下一步行动

1. **今天**：烧录出厂镜像，测试基础功能
2. **明天**：复制工程到工作目录，熟悉结构
3. **本周**：开始添加ADC驱动支持

