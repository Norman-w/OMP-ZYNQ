# 出厂镜像类型和虚拟机情况说明

## 1. 出厂镜像是PetaLinux还是Ubuntu？

### ✅ 出厂镜像是**PetaLinux构建的Linux系统**，不是Ubuntu

**证据**：
1. **工程结构**：`plnx_prj/` 目录明确显示这是PetaLinux工程
2. **配置文件**：`plnx_prj/config.project` 和 `project-spec/configs/config` 都是PetaLinux的配置文件
3. **构建方式**：使用PetaLinux工具构建（`petalinux-build`）

### 📋 详细说明

#### PetaLinux构建的系统特点：
- ✅ 基于Yocto项目构建
- ✅ 可以配置根文件系统的包管理器（可能是类似Ubuntu的apt，但本质不同）
- ✅ 针对ZYNQ硬件优化
- ✅ 系统大小可定制（从几MB到几百MB）
- ✅ 包含U-Boot、Linux内核、设备树、根文件系统

#### 与Ubuntu的区别：
- ❌ **不是Ubuntu发行版**
- ✅ 是PetaLinux构建的**定制Linux系统**
- ✅ 可能使用类似Ubuntu的包管理方式（如果根文件系统配置了）
- ✅ 但本质上是嵌入式Linux系统，不是桌面Ubuntu

### 🔍 如何确认？

在ZYNQ板上运行：
```bash
# 查看系统信息
cat /etc/os-release
uname -a

# 查看包管理器
which apt  # 如果有，可能是配置了apt类似的包管理
which opkg # 或者使用opkg（更常见的嵌入式包管理器）
```

**预期结果**：
- 系统名称可能是 "PetaLinux" 或自定义名称
- 不是 "Ubuntu"
- 包管理器可能是opkg或类似工具

---

## 2. 有没有Ubuntu的VMware虚拟机套件？

### ❌ 没有预装好的Ubuntu VMware虚拟机

**小梅哥资料中的虚拟机相关内容**：

**位置**：`11_虚拟机/`

**内容**：
```
11_虚拟机/
├── ubuntu-16.04.4-desktop-amd64.iso    # Ubuntu 16.04 ISO镜像
├── ubuntu-18.04.4-desktop-amd64.iso    # Ubuntu 18.04 ISO镜像
└── VMware/
    ├── VMware-workstation-full-15.5.0-14665864.rar
    └── VMware-workstation-full-16.1.0-17198959.exe
```

**结论**：
- ❌ **没有预装好的虚拟机镜像**（.ova、.vmdk、.vmx等）
- ✅ 只有Ubuntu ISO镜像（需要自己安装）
- ✅ 有VMware软件（需要自己安装）

### 🔧 需要自己创建虚拟机

**步骤**：
1. **安装VMware**（使用提供的软件）
   - `VMware-workstation-full-16.1.0-17198959.exe`（Windows）
   - 或 `VMware-workstation-full-15.5.0-14665864.rar`

2. **创建虚拟机**
   - 使用 `ubuntu-18.04.4-desktop-amd64.iso`（推荐18.04）
   - 配置虚拟机（内存、硬盘等）

3. **安装Ubuntu**
   - 从ISO安装Ubuntu系统

4. **安装PetaLinux工具**
   - 从资料中获取：`05_驱动和工具软件/Linux/Petalinux/`
   - 或从Xilinx官网下载
   - 安装到虚拟机中

### 💡 为什么没有预装好的虚拟机？

**可能原因**：
1. **文件太大**：预装好的虚拟机通常几GB到几十GB
2. **版本依赖**：PetaLinux版本与Xilinx工具版本相关
3. **许可证**：可能涉及软件许可证问题
4. **灵活性**：让用户自己配置更灵活

---

## 3. 总结对比

| 项目 | 出厂镜像（ZYNQ上） | 虚拟机（PC上） |
|------|------------------|---------------|
| **类型** | PetaLinux构建的Linux系统 | Ubuntu Desktop |
| **用途** | 运行在ZYNQ硬件上 | 开发环境（PC上） |
| **来源** | PetaLinux工具构建 | Ubuntu ISO安装 |
| **是否提供** | ✅ 有（预制作镜像） | ❌ 没有（只有ISO） |
| **是否需要安装** | 直接烧录到SD卡 | 需要自己安装 |

### 📊 完整工作流程

```
PC开发环境：
├── 安装VMware（使用提供的软件）
├── 创建虚拟机（使用Ubuntu ISO）
├── 安装Ubuntu系统
└── 安装PetaLinux工具
        ↓
使用PetaLinux构建系统：
├── 导入XSA文件
├── 配置内核、根文件系统
├── 构建系统
└── 生成BOOT.BIN和rootfs
        ↓
烧录到SD卡：
├── BOOT.BIN（启动文件）
├── zImage（内核）
├── system.dtb（设备树）
└── rootfs（根文件系统）
        ↓
ZYNQ板上运行：
└── PetaLinux构建的Linux系统（不是Ubuntu）
```

---

## 4. 推荐方案

### 开发环境设置

1. **使用提供的Ubuntu ISO创建虚拟机**
   ```bash
   # 推荐使用Ubuntu 18.04
   # 因为PetaLinux 2020.1支持Ubuntu 18.04
   ```

2. **安装PetaLinux工具**
   ```bash
   # 从资料中获取
   # 05_驱动和工具软件/Linux/Petalinux/
   ./petalinux-v2020.1-final-installer.run
   ```

3. **使用出厂工程**
   ```bash
   # 复制出厂工程到虚拟机
   # 使用提供的脚本进行构建
   ```

### 快速开始

```bash
# 1. 在VMware中创建虚拟机
#    - 使用 ubuntu-18.04.4-desktop-amd64.iso
#    - 分配足够内存（建议8GB+）
#    - 分配足够硬盘（建议100GB+）

# 2. 安装Ubuntu系统

# 3. 安装PetaLinux工具
sudo ./petalinux-v2020.1-final-installer.run

# 4. 复制出厂工程到虚拟机
# 5. 使用 ./do 脚本进行构建
```

---

## 5. 关键点总结

### 出厂镜像
- ✅ **是PetaLinux构建的系统**，不是Ubuntu
- ✅ 针对ZYNQ硬件优化
- ✅ 可以直接烧录使用

### 虚拟机
- ❌ **没有预装好的虚拟机**
- ✅ 有Ubuntu ISO和VMware软件
- ✅ 需要自己创建和配置
- 💡 建议使用Ubuntu 18.04 + PetaLinux 2020.1

