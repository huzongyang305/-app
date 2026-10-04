## 启动流程速查

| 阶段 | 动作 | 关键组件 |
| --- | --- | --- |
| 上电自检 | 硬件初始化与检测 | UEFI / BIOS |
| 引导加载 | 加载内核与 initrd | GRUB、systemd-boot |
| 内核初始化 | 驱动、内存与调度就绪 | 内核 |
| 挂载根文件系统 | 切换到真实根 | initramfs |
| 启动用户态 | 拉起服务与登录 | systemd（PID 1） |
| 服务就绪 | 对外提供服务 | 目标（target）与依赖 |

| 安全机制 | 作用 |
| --- | --- |
| Secure Boot | 校验引导链签名，防篡改 |
| TPM | 存储密钥与度量值，支持可信启动 |
| 全盘加密 | 静态数据加密，防物理窃取 |
| 内核锁定与模块签名 | 限制内核模块加载 |
| 度量与远程证明 | 证明启动状态可信 |

## 权限模型速查

| 概念 | 说明 |
| --- | --- |
| 用户 / 组 | 主体身份（UID / GID） |
| 文件权限 | rwx 分别作用于属主、组、其他 |
| umask | 创建文件时屏蔽权限位 |
| SUID | 执行时以文件属主身份运行（高风险） |
| SGID | 目录中新建文件继承目录组 |
| Sticky bit | 目录内只能删除自己的文件 |
| capabilities | 细粒度特权（如绑定低端口） |
| sudo | 受控提权并记录审计 |
| SELinux / AppArmor | 强制访问控制 |

```bash
# 启动与引导排查
systemd-analyze blame | head            # 各服务启动耗时
systemd-analyze critical-chain          # 关键启动链路
journalctl -b -p err                    # 本次启动的错误日志
systemctl --failed                      # 启动失败的服务

# Secure Boot 与内核模块签名状态
mokutil --sb-state 2>/dev/null || echo "无 mokutil"
dmesg | grep -i 'secure boot\|taint'

# 权限与提权审计
find / -perm -4000 -type f 2>/dev/null | head   # 查找 SUID 文件
getenforce 2>/dev/null || aa-status 2>/dev/null || echo "未启用强制访问控制"
last -n 5                                # 最近登录记录
journalctl -u ssh -n 50                  # SSH 相关审计
```

```python
import os
import stat

def describe_mode(path: str) -> dict:
    """解读文件权限位与特殊位。"""
    mode = os.stat(path).st_mode
    return {
        "octal": oct(stat.S_IMODE(mode)),
        "owner": bool(mode & stat.S_IRWXU),
        "suid": bool(mode & stat.S_ISUID),      # 提权风险点
        "sgid": bool(mode & stat.S_ISGID),
        "sticky": bool(mode & stat.S_ISVTX),
    }

def is_world_writable(mode: int) -> bool:
    """全局可写是常见的安全弱配置。"""
    return bool(mode & stat.S_IWOTH)

def audit_critical_paths(paths: list) -> list:
    """巡检关键路径的危险权限。"""
    findings = []
    for path in paths:
        try:
            info = describe_mode(path)
        except OSError:
            continue
        if info["suid"]:
            findings.append((path, "SUID 位开启，需确认是否必要"))
        if is_world_writable(os.stat(path).st_mode):
            findings.append((path, "全局可写，建议收紧权限"))
    return findings

print(audit_critical_paths(["/etc", "/usr/bin/passwd"]))
```

## 加固清单速查

| 项 | 建议 |
| --- | --- |
| SSH | 禁用口令登录、禁用 root 直登、改端口加白名单 |
| 账号 | 删除无用账号、锁定默认账号、强制强密码策略 |
| 提权 | 最小化 sudo 权限，审计 SUID 文件 |
| 服务 | 只开必要端口与服务，关闭调试接口 |
| 更新 | 定期打补丁，订阅安全公告 |
| 日志 | 集中收集并防篡改 |
| 备份 | 离线备份 + 恢复演练 |
| 强制访问控制 | 启用 SELinux / AppArmor |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为 Secure Boot 能防一切 | 仍被应用层攻击 | 它只保证引导链完整性 |
| 关闭 SELinux 图省事 | 失去强制访问控制 | 用策略调试而不是直接关闭 |
| 随意保留 SUID 文件 | 提权漏洞面变大 | 定期审计并移除不必要的 SUID |
| umask 设为 000 | 新建文件全局可写 | 一般用 022 或 027 |
| 用 root 跑应用 | 漏洞影响面最大 | 专用低权限账号 + capabilities |
| 不做启动耗时分析 | 启动慢且不知原因 | 用 `systemd-analyze` 定位 |
| 只看内核日志不看服务日志 | 漏掉应用错误 | 结合 `journalctl -u` 与业务日志 |
| 无登录审计 | 入侵无法追溯 | 集中日志 + 告警 |
| 全盘加密不给恢复方案 | 密钥丢失数据不可恢复 | 备份恢复密钥 |
| 不做恢复演练 | 真故障时无法启动 | 定期演练救援模式 |

## 自测清单

- [ ] 能描述从 UEFI 到用户态服务的启动链路。
- [ ] 知道 Secure Boot 与 TPM 各自的边界。
- [ ] 会审计 SUID、全局可写等危险权限。
- [ ] 应用以最小权限运行，优先用 capabilities。
- [ ] 有集中日志、补丁与备份恢复演练。
