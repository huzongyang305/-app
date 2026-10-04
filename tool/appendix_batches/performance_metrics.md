## 核心指标速查

| 指标 | 含义 | 什么时候看 |
| --- | --- | --- |
| 吞吐（Throughput） | 单位时间处理的请求数 | 容量与成本评估 |
| 延迟（Latency） | 单个请求耗时 | 用户体验 |
| P50 / P95 / P99 | 分位延迟 | 长尾与超时风险 |
| 并发数 | 同时在处理的请求数 | 与延迟、吞吐联动 |
| 错误率 | 失败请求占比 | 稳定性 |
| 饱和度 | 资源使用接近上限的程度 | 容量预警 |
| 排队时间 | 请求在队列中等待 | 定位瓶颈在服务还是排队 |

利特尔法则：`并发数 = 吞吐 × 平均延迟`。用它可以从两个指标反推第三个。

## 阿姆达尔定律速查

加速比上限为 `1 / (1 - p)`，其中 p 是可并行比例：

| 可并行比例 | 理论最大加速比 |
| --- | --- |
| 50% | 2 倍 |
| 75% | 4 倍 |
| 90% | 10 倍 |
| 95% | 20 倍 |
| 99% | 100 倍 |

结论：把最多时间花在**仍然串行**的那部分，收益最大。

```python
import statistics
import time

def measure(func, repeat: int = 30, warmup: int = 3):
    """基准测量：预热 + 多轮采样 + 报告分位数。"""
    for _ in range(warmup):
        func()

    samples = []
    for _ in range(repeat):
        start = time.perf_counter()
        func()
        samples.append((time.perf_counter() - start) * 1000)   # 毫秒

    samples.sort()
    return {
        "median_ms": round(statistics.median(samples), 3),
        "p95_ms": round(samples[int(len(samples) * 0.95) - 1], 3),
        "min_ms": round(samples[0], 3),
        "max_ms": round(samples[-1], 3),
    }


def percentile(values, p: float) -> float:
    """线性插值计算分位数，便于报表统一口径。"""
    if not values:
        raise ValueError("空集合")
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * p
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight


def little_law(throughput: float, latency_seconds: float) -> float:
    """由吞吐与平均延迟估算并发数。"""
    return throughput * latency_seconds


print(percentile([10, 20, 30, 40, 50], 0.95))
print(little_law(throughput=200, latency_seconds=0.05))   # 约 10 个并发
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看平均延迟 | 长尾被掩盖 | 同时报告 P95 / P99 与最大值 |
| 不做预热就测 | 首次执行包含冷启动 | 预热若干轮再采样 |
| 只测一轮 | 结果被噪声主导 | 多轮采样并报告分布 |
| 在共享环境测性能 | 数据不可复现 | 固定环境与配置，隔离干扰 |
| 混用毫秒与秒 | 数据差 1000 倍 | 统一单位并标注 |
| 用 Debug 构建测性能 | 结论严重偏低 | 用 Release 构建 |
| 忽略阿姆达尔定律 | 优化收益不及预期 | 先优化串行部分 |
| 混淆吞吐与延迟 | 优化方向错误 | 明确目标：更高吞吐还是更低延迟 |
| 压测只加压不限流 | 打爆下游 | 同步对下游做容量评估 |
| 忽略排队时间 | 误判服务变慢 | 区分服务耗时与排队耗时 |

## 自测清单

- [ ] 能用利特尔法则在吞吐、延迟、并发间换算。
- [ ] 性能报告包含中位数、P95、P99 与样本量。
- [ ] 测量时有预热与多轮采样。
- [ ] 记得用 Release 构建做性能测试。
- [ ] 优化前先算可并行比例的理论上限。
