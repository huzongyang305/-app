## 磁盘布局速查

| 区域 | 作用 |
| --- | --- |
| 引导块 | 启动代码 |
| 超级块 | 文件系统元信息（大小、空闲块等） |
| inode 表 | 存放所有 inode |
| 数据块区 | 实际数据 |
| 位图 | 记录 inode 与数据块的空闲状态 |

## 分配方式对照

| 方式 | 优点 | 缺点 |
| --- | --- | --- |
| 连续分配 | 顺序读最快 | 碎片与扩展困难 |
| 链式分配 | 易扩展 | 随机访问慢 |
| 索引分配（多级） | 支持大文件、随机访问好 | 索引块开销 |
| 混合（ext4 extent） | 兼顾大文件与碎片控制 | 实现复杂 |

## RAID 对照

| 级别 | 冗余 | 容量利用率 | 读写性能 | 最少盘数 |
| --- | --- | --- | --- | --- |
| RAID 0 | 无 | 100% | 读快写快 | 2 |
| RAID 1 | 镜像 | 50% | 读快写一般 | 2 |
| RAID 5 | 单盘校验 | (n-1)/n | 读快写慢 | 3 |
| RAID 6 | 双盘校验 | (n-2)/n | 读快写更慢 | 4 |
| RAID 10 | 镜像 + 条带 | 50% | 读写都强 | 4 |

```python
from dataclasses import dataclass

@dataclass
class RaidPlan:
    level: str
    disks: int
    disk_size_tb: float

    def usable_tb(self) -> float:
        if self.level == "0":
            return self.disks * self.disk_size_tb
        if self.level == "1":
            return self.disks // 2 * self.disk_size_tb
        if self.level == "5":
            return (self.disks - 1) * self.disk_size_tb
        if self.level == "6":
            return (self.disks - 2) * self.disk_size_tb
        if self.level == "10":
            return self.disks // 2 * self.disk_size_tb
        raise ValueError("不支持的 RAID 级别")

    def tolerance(self) -> str:
        return {
            "0": "无冗余，任一盘故障即丢数据",
            "1": "每组镜像可坏 1 块",
            "5": "可坏 1 块",
            "6": "可坏 2 块",
            "10": "每组镜像可坏 1 块（视分布）",
        }[self.level]

    def rebuild_risk(self) -> str:
        """重建期风险提示：容量越大重建越久。"""
        if self.disk_size_tb >= 12 and self.level in {"5", "6"}:
            return "单盘容量大，重建耗时长，建议 RAID 10 或 RAID 6"
        return "重建风险可接受"

def write_amplification(logical_write_mb: float, physical_write_mb: float) -> float:
    """写放大系数：SSD 寿命评估的关键指标。"""
    if logical_write_mb <= 0:
        raise ValueError("逻辑写入必须为正")
    return round(physical_write_mb / logical_write_mb, 2)

print(RaidPlan("5", 6, 8).usable_tb(), RaidPlan("5", 6, 8).tolerance())
print(write_amplification(100, 320))
```

## 性能与可靠性速查

| 关注点 | 做法 |
| --- | --- |
| 顺序 vs 随机 | 尽量把随机写变成顺序写（日志、追加） |
| 预读 | 顺序访问开启预读，随机访问关闭 |
| 写缓存 | 开启需配合掉电保护（BBU），否则有丢数据风险 |
| TRIM | 定期执行，降低写放大 |
| 对齐 | 分区与文件系统按 4K 对齐 |
| 快照 | 用于备份与误操作恢复 |
| 校验 | 文件系统级校验（ZFS、Btrfs）可发现静默损坏 |
| 监控 | SMART 指标与坏道预警 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 大容量盘只用 RAID 5 | 重建期二次故障丢数据 | 改 RAID 6 或 RAID 10 |
| 认为 RAID 等于备份 | 误删与勒索无法防护 | RAID 之外仍需离线备份 |
| 忽略写缓存掉电风险 | 断电后数据损坏 | 用带电池保护的缓存卡 |
| SSD 不做 TRIM | 写放大升高、寿命下降 | 启用定期 TRIM |
| 分区未 4K 对齐 | 读写放大 | 用现代工具自动对齐 |
| 随机读写混用同一盘 | 性能抖动 | 数据与日志分离到不同设备 |
| 不做 SMART 监控 | 磁盘故障突发 | 采集并设置告警 |
| 忽略文件系统校验 | 静默数据损坏 | 用带校验的文件系统或定期校验 |
| 备份与生产同机房 | 一起故障 | 异地或对象存储 |
| 只测顺序吞吐 | 数据库场景结论错误 | 按业务模式测随机 IOPS |

## 自测清单

- [ ] 能说出磁盘布局的各个区域。
- [ ] 能对比连续、链式、索引分配方式。
- [ ] 能按需求选择 RAID 级别并说明容错能力。
- [ ] 理解写放大与 TRIM 对 SSD 的影响。
- [ ] 有 SMART 监控与离线备份。
