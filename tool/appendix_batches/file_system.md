## 文件系统对照

| 文件系统 | 平台 | 特点 |
| --- | --- | --- |
| ext4 | Linux | 日志、成熟稳定、支持大文件 |
| XFS | Linux | 大文件与高并发写入好 |
| Btrfs / ZFS | Linux | 快照、校验、卷管理 |
| NTFS | Windows | 日志、权限、压缩 |
| APFS | macOS | 写时复制、快照、加密 |
| FAT32 | 跨平台 | 兼容好、单文件 4GB 上限 |
| tmpfs | Linux | 内存文件系统，重启即失 |

## 元数据与结构速查

| 概念 | 说明 |
| --- | --- |
| inode | 存放元数据与数据块指针，不含文件名 |
| 目录项 | 文件名到 inode 的映射 |
| 数据块 | 实际数据存储单位，常见 4KB |
| 超级块 | 文件系统整体信息 |
| 日志（journal） | 记录元数据变更，崩溃后快速恢复 |
| 挂载点 | 文件系统在目录树中的位置 |
| 硬链接 | 多个名字指向同一 inode |
| 软链接 | 独立文件，内容为目标路径 |

```bash
# 空间与使用情况
df -hT                     # 各挂载点类型与用量
du -sh /var/log/*          # 目录占用排序前几位
df -i                      # inode 使用率（可能 inode 用满而空间未满）

# 文件与目录结构
stat /etc/hosts            # 查看 inode、权限、时间戳
ls -li /etc/hosts          # 查看 inode 编号
find /var -xdev -type f -size +1G   # 找大文件（不跨文件系统）

# 日志与恢复
journalctl -k | grep -i 'ext4\|xfs\|i/o error'
dumpe2fs -h /dev/sda1 | head -20    # ext 系列超级块信息

# 权限与所有权
chmod 640 secret.txt
chown app:app /data
getfacl /data              # 查看 ACL
```

```python
import os
from pathlib import Path
from collections import defaultdict

def disk_usage_report(root: str, top_n: int = 5) -> dict:
    """按目录汇总大小，找出占用最大的若干项。"""
    totals = defaultdict(int)
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            path = Path(dirpath) / name
            try:
                size = path.stat().st_size
            except OSError:
                continue
            parts = path.relative_to(root).parts
            key = parts[0] if len(parts) > 1 else "(files)"
            totals[key] += size
    ordered = sorted(totals.items(), key=lambda item: -item[1])[:top_n]
    return {
        "root": root,
        "top": [(k, round(v / 1024 / 1024, 2)) for k, v in ordered],
        "total_mb": round(sum(totals.values()) / 1024 / 1024, 2),
    }

def can_hardlink(src: str, dst: str) -> bool:
    """硬链接要求同一文件系统。"""
    return os.stat(src).st_dev == os.stat(Path(dst).parent).st_dev

print(disk_usage_report(".").get("top"))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看 `df` 空间不看 `df -i` | 报「空间不足」但明明有空间 | inode 耗尽，需清理小文件 |
| 删了文件空间没释放 | `df` 没变化 | 文件仍被进程持有，需重启或清空句柄 |
| 认为硬链接能跨文件系统 | 报错 | 跨文件系统用软链接 |
| 删除源文件后软链接仍可用 | 悬空链接 | 软链接保存路径，源删除即失效 |
| 忽略日志轮转 | 磁盘被日志写满 | 配 `logrotate` 或应用级切割 |
| 不做挂载选项调优 | 性能不达标 | 按场景选 `noatime`、`discard` 等 |
| 把 tmpfs 当持久存储 | 重启后数据丢失 | 需要持久化就用真实磁盘 |
| 直接删大目录 | 长时间阻塞 | 用分批删除或工具加速 |
| 忽略 fsync 语义 | 掉电丢数据 | 关键写入显式 `fsync` 并处理错误 |
| 权限用 777 图省事 | 安全风险 | 最小权限 + ACL |

## 自测清单

- [ ] 能说清 inode、目录项与数据块的关系。
- [ ] 知道硬链接与软链接的区别与限制。
- [ ] 会同时检查空间与 inode 使用率。
- [ ] 理解日志文件系统与 fsync 的作用。
- [ ] 有日志轮转与磁盘空间告警。
