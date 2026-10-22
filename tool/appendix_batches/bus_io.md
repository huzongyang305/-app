## 总线与设备速查

| 总线 | 典型速率量级 | 用途 |
| --- | --- | --- |
| PCIe 4.0 x4 | 约 8 GB/s | NVMe SSD |
| PCIe 4.0 x16 | 约 32 GB/s | 显卡 |
| USB 3.2 Gen2 | 约 1.2 GB/s | 外设 |
| SATA III | 约 600 MB/s | 机械盘与老式 SSD |
| I2C / SPI | 几百 kbit/s 到几十 Mbit/s | 传感器、嵌入式 |

## IO 方式对照

| 方式 | CPU 参与度 | 延迟 | 适用 |
| --- | --- | --- | --- |
| 程序控制轮询 | 高（忙等） | 最低 | 极低延迟、短传输 |
| 中断驱动 | 中（每次中断处理） | 中等 | 通用场景 |
| DMA | 低（只处理完成中断） | 低 | 大块数据传输 |
| 通道 / 协处理器 | 最低 | 低 | 大型机、专用卸载 |

```python
import time

def polling_read(read_once, is_ready, timeout=1.0):
    """轮询：延迟低但持续占用 CPU。"""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if is_ready():
            return read_once()
    raise TimeoutError("轮询超时")


def interrupt_like(read_once, is_ready, idle=0.001, timeout=1.0):
    """模拟中断驱动：空闲时让出 CPU（用 sleep 近似，实际由中断唤醒）。"""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if is_ready():
            return read_once()
        time.sleep(idle)          # 让出 CPU，代价是响应延迟
    raise TimeoutError("等待事件超时")


def throughput_mb_s(bytes_transferred: int, seconds: float) -> float:
    """把传输量与耗时换算成 MB/s（1 MB 按 10^6 字节）。"""
    if seconds <= 0:
        raise ValueError("耗时必须为正")
    return bytes_transferred / 1_000_000 / seconds


print(round(throughput_mb_s(8_000_000, 1.0), 1))    # 8.0 MB/s
```

## 性能指标速查

| 指标 | 关注点 |
| --- | --- |
| IOPS | 每秒 IO 次数，小随机 IO 的核心指标 |
| 吞吐（MB/s） | 大块顺序读写的能力 |
| 延迟 | 单次 IO 的耗时，直接影响响应 |
| 队列深度 | 同时未完成的 IO 数，影响并发能力 |
| 4K 随机读 | 数据库与虚拟化最关键的负载 |
| 顺序带宽 | 备份、日志、大文件拷贝更关注 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用顺序带宽衡量数据库盘 | 结论乐观 | 数据库多为 4K 随机读写，看 IOPS |
| 只看 IOPS 不看延迟 | 高负载下体验差 | 两者结合，关注尾延迟 |
| 忽视队列深度影响 | 并发能力被低估 | 在目标队列深度下测 |
| 认为 DMA 完全不需要 CPU | 仍需驱动与中断处理 | DMA 只减少数据搬运的 CPU 参与 |
| 用轮询处理大量设备 | CPU 被吃满 | 批量或负载高时改中断或混合模式 |
| 忽略对齐 | 出现读改写放大 | 按扇区与页对齐 |
| 忽视文件系统与缓存影响 | 结果不代表真实设备 | 用直接 IO 或清理缓存后测 |
| 混用 MB 与 MiB | 数值差 4.8% | 明确单位并统一 |
| 忽略写缓存与掉电风险 | 数据丢失 | 明确 `fsync` 语义与设备缓存策略 |
| 只测一次 | 结果噪声大 | 多次测量并报告分布 |

## 自测清单

- [ ] 能列出常见总线的速率量级。
- [ ] 能说出轮询、中断、DMA 的取舍。
- [ ] 知道数据库看 IOPS、备份看吞吐。
- [ ] 测试设备时会考虑队列深度与对齐。
- [ ] 能区分 MB 与 MiB 并统一单位。
