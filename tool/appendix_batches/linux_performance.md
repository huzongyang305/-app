## USE 方法与工具速查

| 资源 | 利用率 | 饱和度 | 错误 | 工具 |
| --- | --- | --- | --- | --- |
| CPU | `%user+%sys` | 运行队列长度 | 硬件错误 | `top`、`vmstat`、`pidstat` |
| 内存 | 已用比例 | swap 换页 si/so | OOM 记录 | `free`、`vmstat`、`dmesg` |
| 磁盘 | `%util` | 队列长度 await | IO 错误 | `iostat`、`iotop` |
| 网络 | 带宽利用率 | 重传与丢包 | 错误计数 | `sar -n`、`ss`、`ip -s` |
| GPU | 使用率 | 显存占用 | Xid 错误 | `nvidia-smi`、`dcgm` |

## 排查顺序速查

| 步骤 | 动作 | 命令 |
| --- | --- | --- |
| 1 现象 | 确认慢在哪一层 | 用户反馈、端到端延迟 |
| 2 负载 | 系统整体压力 | `uptime`、`vmstat 1` |
| 3 资源 | 找饱和资源 | `top`、`iostat`、`free` |
| 4 进程 | 定位到具体进程 | `pidstat -p <pid> 1` |
| 5 热点 | 定位函数与调用栈 | `perf top`、火焰图 |
| 6 验证 | 改一处再测 | 前后对比同口径指标 |

```bash
# 一、整体：负载、CPU、内存、IO、换页
uptime && vmstat 1 5

# 二、进程级：谁在吃 CPU、内存、IO
pidstat -u -r -d 1 3
ps -eo pid,ppid,pcpu,pmem,rss,etime,cmd --sort=-pcpu | head

# 三、磁盘与网络
iostat -xz 1 3 | tail -20
sar -n DEV 1 3 | tail -10

# 四、热点函数与火焰图（采样 30 秒）
perf record -F 99 -g -p <pid> -- sleep 30
perf report --stdio | head -30

# 五、系统调用与文件：看谁在拖慢
strace -c -f -p <pid> &        # 统计系统调用耗时占比
sleep 10 && kill %1
lsof -p <pid> | wc -l          # 文件描述符数量
```

```python
from dataclasses import dataclass

@dataclass
class UseFinding:
    resource: str
    utilization: float      # 0 到 1
    saturation: float       # 0 到 1
    errors: int = 0

    def severity(self) -> str:
        if self.errors > 0:
            return "P1：存在错误，优先排查"
        if self.saturation > 0.8:
            return "P1：饱和过高，已有排队"
        if self.utilization > 0.85:
            return "P2：利用率偏高，接近瓶颈"
        return "正常"

def analyze(findings: list) -> list:
    """按严重程度排序，输出排查优先级。"""
    return sorted(
        ((f.resource, f.severity()) for f in findings),
        key=lambda item: item[1],
    )

def little_law(concurrency: float, latency_s: float) -> float:
    """由并发与延迟推算可达吞吐，用于容量估算。"""
    if latency_s <= 0:
        raise ValueError("延迟必须为正")
    return round(concurrency / latency_s, 2)

findings = [
    UseFinding("cpu", 0.62, 0.15),
    UseFinding("disk", 0.93, 0.88, errors=0),
    UseFinding("network", 0.4, 0.2, errors=3),
]
print(analyze(findings))
print(little_law(concurrency=20, latency_s=0.05))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看 CPU 使用率 | 漏掉 IO 与内存瓶颈 | 用 USE 方法逐个资源检查 |
| 高负载但 CPU 空闲就下结论 | 忽略 IO 等待 | 看 `vmstat` 的 `wa` 与 `iostat` |
| 用平均值判断性能 | 长尾被掩盖 | 看 P95/P99 与最差值 |
| 在共享机器上测性能 | 数据不可复现 | 隔离环境并固定配置 |
| 无基线直接优化 | 无法证明收益 | 先记录基线数据 |
| 一次改多个参数 | 无法归因 | 一次只改一个变量 |
| 忽略采样频率影响 | 结果偏差 | 采样频率与时长要匹配问题 |
| 生产长时间 perf 采样 | 性能影响与数据量过大 | 限定时长与频率 |
| 忽略容器配额 | 看到的是宿主机指标 | 检查 cgroup 限制 |
| 优化完不回归 | 问题复发 | 加监控与回归测试 |

## 自测清单

- [ ] 会用 USE 方法逐项检查 CPU、内存、磁盘、网络。
- [ ] 排查按「系统、进程、函数」三层递进。
- [ ] 优化前先采集基线，优化后同口径对比。
- [ ] 关注分位数而非平均值。
- [ ] 注意容器配额与宿主机指标的差异。
