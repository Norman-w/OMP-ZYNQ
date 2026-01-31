# 需要转换为MD格式的PDF文件列表

## macOS 下转换说明（/Volumes/ZYNQ 映射 D:/ZYNQ）

- **PDF 实际位置**：列表中的路径是相对于「小梅哥AC820型ZYNQ或安路FPSoC开发板资料」的，在 macOS 上完整根路径为：
  `/Volumes/ZYNQ/小梅哥AC820型ZYNQ或安路FPSoC开发板资料`
- **重新转换命令**（使用独立 venv，避免 atopile 干扰）：
  ```bash
  python3 -m venv /tmp/omp-pdf2md-venv && /tmp/omp-pdf2md-venv/bin/pip install pymupdf
  cd /Volumes/ZYNQ/Norman/OMP
  /tmp/omp-pdf2md-venv/bin/python scripts/pdf_to_md.py --list \
    --zynq-base "/Volumes/ZYNQ/小梅哥AC820型ZYNQ或安路FPSoC开发板资料" \
    --output-dir docs
  ```
- **转换结果**：输出在项目内 `docs/`，含 `*.md` 与 `images/*.png`，MD 中图片引用为 `![描述](images/文件名_页码_序号.png)`。

---

## 关键Linux迁移文档（优先转换）

### 1. Linux教程文档
- **文件路径**: `01_文档教材/04_Linux应用教程/ZYNQ/2020版本/04_【Linux教程】基于Linux的嵌入式系统开发和应用教程V1_1.pdf`
- **重要性**: ⭐⭐⭐⭐⭐ 最高优先级
- **内容**: Linux系统开发和应用教程，包含PetaLinux使用、设备树配置、驱动开发等

- **文件路径**: `01_文档教材/04_Linux应用教程/ZYNQ/2018版本/04_【Linux教程】基于Linux的嵌入式系统开发和应用教程V1.4.pdf`
- **重要性**: ⭐⭐⭐⭐ 参考版本

### 2. 用户手册
- **文件路径**: `01_文档教材/01_【用户手册】AC820开发板用户手册_Zynq7020 v1.1.pdf`
- **重要性**: ⭐⭐⭐⭐⭐ 最高优先级
- **内容**: 开发板硬件说明、接口定义、功能模块介绍

### 3. QT应用指南（如果需要图形界面）
- **文件路径**: `01_文档教材/05_QT应用指南/ZYNQ7020/05_AC820-ZYNQ开发板QT环境构建手册V1.0.1.pdf`
- **重要性**: ⭐⭐⭐ 中等优先级
- **内容**: QT环境构建，如果需要在Linux上使用图形界面

## ADC相关文档（参考）

### 4. ACM7606示波器教程
- **文件路径**: `01_文档教材/03_CPU裸机编程教材文档/ZYNQ/第21章 基于ACM7606的多通道简易示波器/第21章 基于ACM7606的多通道简易示波器.pdf`
- **重要性**: ⭐⭐⭐⭐ 高优先级
- **内容**: ACM7606 ADC的使用方法，可以参考硬件配置部分

## 网络相关文档（参考）

### 5. 以太网PHY芯片手册
- **文件路径**: `08_器件手册/ETH/RTL8211F-CG.pdf`
- **重要性**: ⭐⭐⭐ 中等优先级
- **内容**: PHY芯片规格，Linux驱动可能需要参考

## 原厂手册（参考）

### 6. PetaLinux工具参考
- **文件路径**: `10_原厂手册/Xilinx/c_ug1144-petalinux-tools-reference-guide.pdf`
- **重要性**: ⭐⭐⭐ 中等优先级
- **内容**: Xilinx官方PetaLinux工具参考手册

## 转换状态

### ✅ 已转换（无需转换）
- 出厂Linux工程已解压，设备树配置可直接查看源码
- 设备树文件位置：`D:\ZYNQ\Norman\linux_factory_extract\AC820_Zynq_Linux_Factory\user_dts\system-user.dtsi`

### ✅ 已转换完成
所有关键文档已转换完成，位于 `D:\ZYNQ\Norman\OMP\docs\` 目录：

1. **Linux教程（2020版本）** - ✅ 已转换
   - `docs/04__Linux教程_基于Linux的嵌入式系统开发和应用教程V1_1.md`
   - **内容**: Linux系统开发和应用教程，包含PetaLinux使用、设备树配置、驱动开发等
   
2. **用户手册** - ✅ 已转换
   - `docs/01__用户手册_AC820开发板用户手册_Zynq7020_v1_1.md`
   - **内容**: 开发板硬件说明、接口定义、功能模块介绍
   - **关键发现**: 
     - ✅ 以太网：支持（RTL8211F-CG PHY）
     - ✅ WiFi：支持（RTL8188FTV USB WiFi模块，通过USB HUB连接）
   
3. **ACM7606教程** - ✅ 已转换
   - `docs/第21章_基于ACM7606的多通道简易示波器.md`
   - **内容**: ACM7606 ADC的使用方法，硬件配置和软件实现
   
4. **Linux教程（2018版本）** - ✅ 已转换
   - `docs/04__Linux教程_基于Linux的嵌入式系统开发和应用教程V1_4.md`
   - **内容**: 参考版本，可作为补充
   
5. **QT应用指南** - ✅ 已转换
   - `docs/05_AC820-ZYNQ开发板QT环境构建手册V1_0_1.md`
   - **内容**: QT环境构建，图形界面开发
   
6. **其他文档** - ✅ 已转换
   - `docs/RTL8211F-CG.md` - 以太网PHY芯片手册
   - `docs/c_ug1144-petalinux-tools-reference-guide.md` - PetaLinux工具参考

### 转换格式要求
- 每个PDF转换为一个MD文件
- 图片提取到 `images/` 目录，命名为 `文件名_页码_序号.png`
- MD文件中使用相对路径引用图片：`![描述](images/文件名_页码_序号.png)`

### 示例目录结构
```
docs/
├── linux-tutorial-2020.md
├── user-manual.md
├── acm7606-tutorial.md
└── images/
    ├── linux-tutorial-2020_01_01.png
    ├── linux-tutorial-2020_01_02.png
    └── ...
```

## 关于WiFi和以太网支持

### 当前发现（已解压出厂工程验证 + 文档确认）
- ✅ **以太网**: **已确认支持**
  - 设备树中配置了 `gem0` 和 `gem1` 两个以太网接口
  - `gem0`: RGMII模式，PHY地址=1，MAC地址=00:0a:35:00:1e:53
  - `gem1`: GMII模式，带GMII到RGMII转换器，MAC地址=00:0a:35:00:11:55
  - 设备树文件：`user_dts/system-user.dtsi` 和 `build/dts/pcw.dtsi`
  - PHY芯片：RTL8211F-CG（用户手册确认）
- ✅ **WiFi**: **支持USB WiFi模块**
  - 硬件：RTL8188FTV USB WiFi模块（用户手册第47-48页确认）
  - 连接方式：通过CH334H USB HUB芯片扩展的USB HOST接口
  - 需要：Linux内核支持USB WiFi驱动（RTL8188FTV驱动）
  - 设备树：USB接口已配置（`&usb0`），WiFi模块作为USB设备自动识别

### 出厂工程（已解压到 `D:\ZYNQ\Norman\linux_factory_extract\AC820_Zynq_Linux_Factory\`）
- **Linux源码**: `07_Linux源码/ZYNQ7020/2020版本/AC820出厂工程和Linux源码/AC820_Zynq_Linux_Factory.tar.gz` ✅ 已解压
- **Vivado工程**: `07_Linux源码/ZYNQ7020/2020版本/AC820出厂工程和Linux源码/Zynq7020_484_Factory_prj.zip`
- **预制作镜像**: `06_预制作镜像/ZYNQ7020/2020版本/AC820_7020_linux_new_factory.img`
- **关键文件位置**:
  - 设备树用户配置: `user_dts/system-user.dtsi`
  - 设备树完整配置: `build/dts/system.dts`, `build/dts/pcw.dtsi`
  - 编译好的镜像: `images/BOOT.BIN`, `images/zImage`, `images/system.dtb`
  - HDF硬件描述: `hdf/system_wrapper.xsa`

### 建议
1. ✅ **以太网已配置好**，可以直接使用出厂镜像测试
2. ✅ **设备树配置完整**，包含LED、按键、触摸屏、音频、HDMI等
3. ❌ **WiFi需要额外配置**：
   - 使用USB WiFi适配器（推荐）
   - 或检查是否有其他硬件接口支持WiFi

## 关于ADC支持

### 现有工程参考
- **ACM7606**: `01_文档教材/03_CPU裸机编程教材文档/ZYNQ/第21章 基于ACM7606的多通道简易示波器/21_ACM7606_Scope.rar`
- **AD7606C UDP**: `02_例程源码/ZYNQ/PL逻辑编程/ch56_ac820_ad7606_udp_ddr3.zip`
- **CM3432 TCP**: 在 `D:\ZYNQ\Norman\AC820_CM3432_TCP_zynq` 目录下

### 建议
- 出厂工程可能不包含ADC驱动，需要自己添加
- 可以参考现有的Standalone工程中的ADC控制逻辑
- 在Linux中可能需要编写字符设备驱动或使用UIO

