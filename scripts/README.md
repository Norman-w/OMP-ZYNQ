# scripts

## 免密登录（安装证书）

### Ubuntu虚拟机（米联客18.04 VM）

**配置米联客Ubuntu 18.04虚拟机的SSH免密登录：**

1. **在Ubuntu虚拟机中安装SSH服务器：**
   ```bash
   # 安装SSH服务器（可能需要降级openssh-client）
   sudo apt-get update
   sudo apt-get install -y openssh-client=1:7.6p1-4 openssh-sftp-server openssh-server --allow-downgrades
   
   # 启动SSH服务
   sudo systemctl start ssh
   sudo systemctl enable ssh
   ```

2. **从Windows配置免密登录：**
   ```bash
   ./scripts/setup_ssh_keys_to_server.sh
   ```
   选择 `4) 输入 user@ip 格式`，然后输入：`uisrc@192.168.46.128`（或当前VM的IP地址）

3. **验证连接：**
   ```bash
   ssh uisrc@192.168.46.128
   ```

**注意：** 脚本已更新，支持：
- 选择预定义服务器（1、2）
- 手动输入IP地址（3）
- 直接输入 `user@ip` 格式（4）
- 直接输入IP地址或 `user@ip`（自动识别）

---

### Windows服务器

拉取 BOOT.BIN 前需先在要用的那台 Windows 服务器上安装本机 SSH 公钥，每台只需做一次。77 和 88 不能同时连（一个走 VPN、一个直连局域网），每次运行脚本选一台配置即可。

**前提：** Windows 已安装并启用 OpenSSH 服务器，且存在用户 `ws`。

**方式一：用脚本（推荐）**

```bash
./scripts/setup_ssh_keys_to_server.sh
```

选择 192.168.46.128（Ubuntu VM）或 192.168.7.77（Windows服务器）中的一台，提示输入一次密码，写入公钥后即完成。

**方式二：手动**

```bash
# 若还没有公钥，先生成
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# 选一台能连上的拷过去（输入一次密码）
ssh-copy-id -i ~/.ssh/id_ed25519.pub ws@192.168.7.88
# 或
ssh-copy-id -i ~/.ssh/id_ed25519.pub ws@192.168.7.77
```

配置好后，`fetch_boot_to_sd.sh` 不再要求输入密码。

---

## 通过 SSH 在 Windows 上执行 git 提交

当本机是通过共享挂载访问 `D:\ZYNQ\Norman\OMP` 时，在挂载盘上跑 git 容易超时。可改为 SSH 到 Windows，在仓库所在盘执行提交：

```bash
./scripts/git_commit_via_ssh.sh "📜 新增 scripts：拉取 BOOT.BIN 到 SD 卡脚本与免密配置说明"
```

commit message 通过第一个参数传入（可含空格）。选择 88 或 77 后，会在对应 Windows 上执行 `git add scripts/ .gitignore`、`git commit`。**必要时请在 Windows 本机执行 git push 推送到远程。**
