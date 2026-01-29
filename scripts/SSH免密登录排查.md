# Windows OpenSSH 免密登录不生效排查

**环境**：Mac/Linux 用 SSH 公钥连 Windows（OpenSSH Server），已跑过 `ssh-copy-id` 或手动把公钥放进 `C:\Users\<用户>\.ssh\authorized_keys`，仍被要求输入密码。

**现象**：客户端日志有 `Offering public key`，紧接着 `Authentications that can continue`，没有 `Accepted publickey`；服务端用 `sshd -d` 可见 `Failed publickey`。

**原因**：  
- 若该 Windows 用户属于**管理员组**，sshd 只会读 **`C:\ProgramData\ssh\administrators_authorized_keys`**，不会读用户目录下的 `.ssh\authorized_keys`。  
- 公钥放在用户目录、未放在 `administrators_authorized_keys`，或该文件权限不对，都会导致公钥认证失败。

**解决**：

1. **管理员 PowerShell** 建/写 `C:\ProgramData\ssh\administrators_authorized_keys`（公钥一整行，无换行）：
   ```powershell
   $key = "ssh-ed25519 AAAA... 你的公钥整行 ..."
   [System.IO.File]::WriteAllText("C:\ProgramData\ssh\administrators_authorized_keys", $key + "`n", [System.Text.UTF8Encoding]::new($false))
   ```

2. **只给 SYSTEM 和 Administrators 权限**：
   ```powershell
   icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant:r "SYSTEM:F" /grant:r "BUILTIN\Administrators:R"
   ```

3. **sshd_config** 中确认：`PubkeyAuthentication yes`（去掉前面的 `#`）。

4. **重启 sshd**：`Restart-Service sshd`。

**如何确认是“管理员走错文件”**：  
在 Windows 上 `Stop-Service sshd` 后执行 `C:\Windows\System32\OpenSSH\sshd.exe -d`，从 Mac 连一次；若日志里出现 `trying public key file __PROGRAMDATA__/ssh/administrators_authorized_keys` 且 `No such file or directory` 或 `Failed publickey`，即为此原因。排查完记得 `Start-Service sshd`。

**非管理员用户**：公钥放在 `C:\Users\<用户>\.ssh\authorized_keys`，该文件需 LF 换行、仅一条一行；目录和文件权限只给对应用户 + SYSTEM 读（如 `icacls` 设 `inheritance:r` 后 `grant "用户:F"` 和 `grant "SYSTEM:R"`）。
