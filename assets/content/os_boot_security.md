# 系统启动与权限安全

![系统启动与权限安全](images/remaining_os_boot_security.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「系统启动与权限安全」解决了什么问题，而不是只背术语。
- 能说清 「启动」、「UEFI」、「Secure Boot」、「SUID」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「操作系统」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：UEFI/Secure Boot、权限位、capabilities 与容器隔离。

## 前置知识

- 先完成上一课《文件系统实现与 RAID》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：启动、UEFI、Secure Boot。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 启动流程

```text
通电 → CPU 执行固件（BIOS/UEFI）→ POST 自检 → 选择启动设备
→ 加载 bootloader（GRUB）→ 加载内核与 initramfs
→ 内核初始化（内存、调度、驱动）→ 挂载根文件系统
→ 启动 init/systemd（PID 1）→ 启动服务与登录界面
```

UEFI 取代 BIOS 的关键改进：GPT 分区、启动更快、支持 Secure Boot（校验 bootloader 与内核签名，防止引导链被篡改）。initramfs 是临时根文件系统，内含挂载真正根分区所需的驱动与脚本。

## 用户与权限模型

Linux 权限用「用户/组/其他 + rwx」九位表示（如 755、644）。特殊位：**SUID**（以文件所有者身份执行）、**SGID**（继承组或目录内文件继承组）、**Sticky**（目录内文件仅所有者可删，如 /tmp）。

root 权限过大，因此现代系统使用 **capabilities** 拆分特权（如 CAP_NET_BIND_SERVICE 只允许绑定低端口、CAP_SYS_ADMIN 仍然危险），配合最小权限原则降低风险。

## 强制访问控制

| 机制 | 特点 |
| --- | --- |
| SELinux | 基于标签的策略，细粒度，RHEL 系默认 |
| AppArmor | 基于路径的配置，简单易用，Ubuntu 系默认 |
| Seccomp | 限制进程可用的系统调用，容器常用 |

## 隔离：命名空间与 cgroups

容器不是虚拟机，它靠内核特性实现隔离：**命名空间**隔离视图（PID、网络、挂载、UTS、IPC、用户），**cgroups** 限制资源（CPU、内存、IO、进程数）。理解这点就能解释「容器里看到的进程号是 1」「内存超限被 OOM Kill」等现象。

## 安全加固清单

1. 禁用 root 远程登录，改用密钥 + sudo。
2. 最小化开放端口，防火墙默认拒绝。
3. 及时打补丁，关注 CVE 与内核漏洞。
4. 启用审计（auditd）与日志集中化。
5. 容器以非 root 运行、只读根文件系统、限制 capabilities。
6. 关键系统启用 Secure Boot 与磁盘加密（LUKS）。

## 权限加固的实操命令

| 目标 | 命令要点 |
| --- | --- |
| 查看文件权限与特殊位 | `ls -l` 看 rwx 与 s/t 标记；`stat -c '%a %n' <file>` 看八进制 |
| 修正目录与文件权限 | 目录 755、普通文件 644；可执行脚本 755，绝不整目录 777 |
| 查找危险的 SUID 文件 | `find / -perm -4000 -type f 2>/dev/null`，逐个确认是否必要 |
| 限制服务权限 | systemd 单元中加 `User=`、`NoNewPrivileges=true`、`ProtectSystem=strict` |
| 查看进程可用能力 | `getpcaps <pid>` 或 `capsh --print` |
| 容器最小权限 | `--read-only --cap-drop=ALL --user 1000:1000`，仅按需 `--cap-add` |

排查思路：先用审计工具（`lynis`、`auditd`）找出配置偏差，再逐项收敛；**每次改动都要在测试环境验证服务仍能启动**，权限过紧会直接导致启动失败。

## 启动故障排查表

| 现象 | 常见原因 | 处理 |
| --- | --- | --- |
| 卡在固件界面 | 硬盘未被识别、引导顺序错误 | 进 UEFI 检查启动项与磁盘 |
| GRUB 提示找不到内核 | 内核升级后未更新 grub 配置 | 用安装介质进入救援模式重建引导 |
| 启动后进入 emergency mode | /etc/fstab 中挂载项错误 | 检查 fstab 与磁盘 UUID（`blkid`） |
| Secure Boot 报签名失败 | 自编译内核或第三方模块未签名 | 签名模块或临时关闭 Secure Boot 定位 |
| 服务起不来但系统正常 | systemd 单元配置错误 | `systemctl status <svc>` + `journalctl -u <svc> -n 50` |

常用命令：`systemctl list-units --failed` 找失败单元、`journalctl -b -p err` 看本次启动的错误日志、`systemd-analyze blame` 看哪个服务拖慢启动。

## 本课小结
启动链的关键是**信任传递**（固件 → bootloader → 内核 → 用户空间），权限模型的关键是**最小权限**（用户/组 → capabilities → MAC → 命名空间与 cgroups）。

<!-- appendix:v1 -->

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

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「启动、UEFI、Secure Boot」完成复述、实验和交付，每个结果都要能被别人检查。

先画出进程、线程或资源状态，再模拟调度与竞争，最后记录状态迁移。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「系统启动与权限安全」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「UEFI」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

用伪代码或小脚本模拟一次调度、竞争或资源分配，并记录至少 5 个状态变化。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「启动」和「UEFI」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Boot & Security

**Summary:** UEFI, permissions, capabilities and isolation.

**Category:** Operating Systems  
**Level:** 进阶  
**Key terms:** 启动, UEFI, Secure Boot, SUID, capabilities, namespace

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Linux 6.x / POSIX
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：启动、UEFI、Secure Boot、SUID、capabilities、namespace
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Linux Kernel Docs](https://docs.kernel.org/) | 进程、内存、I/O 与调度 |
| [Linux man-pages](https://man7.org/linux/man-pages/) | 系统调用与用户态接口 |

> 本课主题：UEFI/Secure Boot、权限位、capabilities 与容器隔离。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

