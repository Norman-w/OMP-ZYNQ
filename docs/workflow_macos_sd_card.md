# macOS SD卡烧录工作流程

## 场景说明

- **macOS**: 本地机器，有SD卡读卡器，开发板在旁边
- **Windows服务器**: 远程服务器，运行Ubuntu VM
- **目标**: 最小化从VM传输到macOS的文件，在macOS上完成SD卡烧录

## 方案一：分区已做好，只更新文件（推荐）

### 步骤1: 在Ubuntu VM上打包文件

```bash
# 在VM上运行
cd /path/to/petalinux-project
./scripts/pack-files-for-macos.sh

# 或者指定输出目录
./scripts/pack-files-for-macos.sh /path/to/petalinux-project /tmp
```

这会生成一个压缩包，例如：`petalinux_files_20240101_120000.tar.gz`

**文件大小优化**：
- 默认只打包启动文件（BOOT.BIN, image.ub）- 通常只有几十MB
- 可选择是否包含根文件系统（rootfs.tar.gz）- 可能几百MB到几GB
- 如果根文件系统很大，可以：
  1. 第一次传输包含rootfs的完整包
  2. 后续只传输启动文件包（快速更新）

### 步骤2: 传输到macOS

使用scp、rsync或其他方式传输压缩包：

```bash
# 从macOS执行
scp user@windows-server:/path/to/petalinux_files_*.tar.gz ~/Downloads/
```

### 步骤3: 在macOS上更新SD卡

```bash
# 方法1: 直接使用压缩包（脚本会自动解压）
./scripts/copy-files-to-sd-macos.sh ~/Downloads/petalinux_files_*.tar.gz

# 方法2: 先解压再使用
cd ~/Downloads
tar -xzf petalinux_files_*.tar.gz
./scripts/copy-files-to-sd-macos.sh ./images/linux
```

## 方案二：完整烧录（首次使用）

如果SD卡还没有分区，需要先格式化：

### 在macOS上使用完整烧录

macOS上可以使用 `dd` 命令烧录完整的img文件：

```bash
# 1. 在VM上生成完整img文件（如果还没有）
# 2. 传输img文件到macOS
# 3. 在macOS上使用dd烧录

# 查看SD卡设备
diskutil list

# 卸载SD卡
diskutil unmountDisk /dev/disk2

# 使用dd烧录（注意：disk2需要替换为实际设备）
sudo dd if=system.img of=/dev/rdisk2 bs=4m status=progress

# 同步
sync
```

**注意**: macOS使用 `/dev/rdisk*` 可以获得更好的性能。

## 方案三：混合方案（最灵活）

1. **首次烧录**: 在VM上使用完整img文件烧录，或使用 `flash-img-to-sd.sh` 脚本
2. **后续更新**: 
   - 在VM上打包文件（只包含启动文件，不包含rootfs）
   - 传输到macOS（文件小，传输快）
   - 在macOS上使用 `copy-files-to-sd-macos.sh` 更新

## macOS脚本功能说明

### `copy-files-to-sd-macos.sh`

- ✅ 自动检测macOS上的SD卡设备
- ✅ 支持已分区的SD卡（不格式化）
- ✅ 只更新文件内容
- ✅ 支持直接使用压缩包（自动解压）
- ✅ 显示文件信息和写入时间

**限制**:
- macOS需要 `fuse-ext2` 来挂载ext4分区（用于更新rootfs）
- 如果只需要更新boot分区，不需要安装fuse-ext2

### 安装fuse-ext2（可选，仅更新rootfs时需要）

```bash
# 安装Homebrew（如果还没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装fuse-ext2
brew install --cask osxfuse
brew install fuse-ext2
```

## 文件传输大小对比

| 方案 | 传输文件大小 | 适用场景 |
|------|-------------|---------|
| 完整img文件 | 几GB | 首次烧录，需要完整镜像 |
| 启动文件包（不含rootfs） | 10-50MB | 只更新内核/设备树/U-Boot |
| 完整文件包（含rootfs） | 几百MB-几GB | 更新根文件系统 |

## 推荐工作流程

1. **开发阶段**（频繁更新）:
   - 在VM上打包启动文件（不含rootfs）
   - 传输到macOS（快速）
   - 在macOS上更新SD卡

2. **测试阶段**（需要完整系统）:
   - 在VM上打包完整文件（含rootfs）
   - 传输到macOS
   - 在macOS上更新SD卡

3. **生产部署**:
   - 在VM上生成完整img文件
   - 传输到macOS
   - 使用dd命令完整烧录

## 故障排除

### macOS无法挂载ext4分区

如果只需要更新boot分区，可以忽略这个错误。如果需要更新rootfs：
```bash
brew install --cask osxfuse
brew install fuse-ext2
```

### 设备检测失败

手动指定设备：
```bash
# 先查看设备
diskutil list

# 然后手动指定（修改脚本或使用参数）
```

### 文件权限问题

macOS上挂载的FAT32分区可能需要sudo权限来复制文件。脚本会自动处理。

## 脚本位置

- `scripts/pack-files-for-macos.sh` - VM上打包脚本
- `scripts/copy-files-to-sd-macos.sh` - macOS上复制脚本
- `scripts/flash-img-to-sd.sh` - 完整img烧录脚本（Linux/VM）
- `scripts/flash-to-tf-sd-card.sh` - 完整格式化烧录脚本（Linux/VM）

