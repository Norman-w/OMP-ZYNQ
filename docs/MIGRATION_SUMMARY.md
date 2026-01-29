# Linux迁移关键信息总结

## 网络支持情况

### ✅ 以太网（已确认支持）
- **硬件**: RTL8211F-CG PHY芯片
- **接口**: gem0 (RGMII) 和 gem1 (GMII)
- **设备树配置**: 已在出厂工程中配置完成
- **MAC地址**: 
  - gem0: 00:0a:35:00:1e:53
  - gem1: 00:0a:35:00:11:55
- **状态**: 出厂Linux镜像应已支持，可直接使用

### ✅ WiFi（USB WiFi模块）
- **硬件**: RTL8188FTV USB WiFi模块
- **连接方式**: 通过CH334H USB HUB扩展的USB HOST接口
- **驱动**: 需要Linux内核支持RTL8188FTV驱动
- **设备树**: USB接口已配置（`&usb0`），WiFi模块作为USB设备自动识别
- **状态**: 硬件支持，需要确认Linux内核是否包含驱动

## ADC支持情况

### ACM7606/CM3432
- **硬件**: ACM7606（8通道16位）或CM3432（双通道14位）
- **连接方式**: 通过PL（FPGA）侧AXI接口
- **驱动**: 出厂工程**不包含**ADC驱动，需要自行添加
- **建议方案**:
  1. 参考Standalone工程中的ADC控制逻辑
  2. 在Linux中编写字符设备驱动或使用UIO
  3. 使用DMA将ADC数据从PL传输到PS

## 基础工程可用性

### ✅ 可直接使用的基础工程
- **出厂Linux工程**: `AC820_Zynq_Linux_Factory.tar.gz` ✅ 已解压
  - 位置: `D:\ZYNQ\Norman\linux_factory_extract\AC820_Zynq_Linux_Factory\`
  - 包含: 完整的PetaLinux工程、设备树、内核、根文件系统
  - 支持: 以太网、USB、显示、触摸屏、音频等
  - **不支持**: ADC驱动（需要自行添加）

### 需要添加的功能
1. **ADC驱动**: 参考Standalone工程实现
2. **ADC数据采集应用**: 基于驱动编写用户空间应用
3. **示波器UI**: 可以使用QT或直接操作framebuffer

## 迁移建议

### 第一步：测试基础功能
1. 使用出厂镜像测试以太网连接
2. 测试USB WiFi模块（如果硬件已安装）
3. 验证显示和触摸屏功能

### 第二步：添加ADC支持
1. 参考Standalone工程中的ADC控制逻辑
2. 编写Linux字符设备驱动或使用UIO
3. 实现DMA数据传输

### 第三步：应用层迁移
1. 将示波器UI从Standalone迁移到Linux
2. 使用Linux标准API替代Xilinx Standalone API
3. 优化实时性能（考虑PREEMPT_RT或FPGA侧缓冲）

## 关键文档位置

- **Linux教程**: `docs/04__Linux教程_基于Linux的嵌入式系统开发和应用教程V1_1.md`
- **用户手册**: `docs/01__用户手册_AC820开发板用户手册_Zynq7020_v1_1.md`
- **ACM7606教程**: `docs/第21章_基于ACM7606的多通道简易示波器.md`
- **出厂工程**: `D:\ZYNQ\Norman\linux_factory_extract\AC820_Zynq_Linux_Factory\`

