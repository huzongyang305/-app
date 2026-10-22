## 调度算法对照

| 算法 | 抢占 | 优点 | 缺点 | 适用 |
| --- | --- | --- | --- | --- |
| 先来先服务（FCFS） | 否 | 简单公平 | 长任务阻塞短任务 | 批处理 |
| 短作业优先（SJF） | 否 | 平均等待最短 | 需预知运行时间、长任务饥饿 | 批处理 |
| 最短剩余时间优先 | 是 | 响应更好 | 同上 | 交互式批处理 |
| 时间片轮转（RR） | 是 | 响应均匀 | 时间片太小切换开销大 | 分时系统 |
| 优先级调度 | 可 | 支持重要性 | 低优先级饥饿 | 实时与混合 |
| 多级反馈队列 | 是 | 兼顾响应与吞吐 | 参数多 | 通用操作系统 |
| 完全公平调度（CFS） | 是 | 按权重分配 CPU | 实现复杂 | Linux |

## 关键指标速查

| 指标 | 含义 |
| --- | --- |
| 周转时间 | 完成时刻减到达时刻 |
| 等待时间 | 周转时间减去实际运行时间 |
| 响应时间 | 从到达到首次被调度 |
| 吞吐量 | 单位时间完成的任务数 |
| CPU 利用率 | 忙碌时间占比 |
| 上下文切换次数 | 切换开销的间接指标 |

```python
from dataclasses import dataclass

@dataclass
class Job:
    name: str
    arrive: int
    burst: int

def fcfs(jobs: list) -> dict:
    time, results = 0, {}
    for job in sorted(jobs, key=lambda j: j.arrive):
        time = max(time, job.arrive) + job.burst
        results[job.name] = {"finish": time, "turnaround": time - job.arrive}
        results[job.name]["waiting"] = results[job.name]["turnaround"] - job.burst
    return results

def sjf_non_preemptive(jobs: list) -> dict:
    """短作业优先：每次从已到达任务中挑最短的。"""
    pending, time, results = sorted(jobs, key=lambda j: j.arrive), 0, {}
    ready = []
    while pending or ready:
        while pending and pending[0].arrive <= time:
            ready.append(pending.pop(0))
        if not ready:
            time = pending[0].arrive
            continue
        job = min(ready, key=lambda j: j.burst)
        ready.remove(job)
        time += job.burst
        results[job.name] = {
            "finish": time,
            "turnaround": time - job.arrive,
            "waiting": time - job.arrive - job.burst,
        }
    return results

def average_waiting(results: dict) -> float:
    waits = [item["waiting"] for item in results.values()]
    return round(sum(waits) / len(waits), 2)

jobs = [Job("A", 0, 8), Job("B", 1, 4), Job("C", 2, 2)]
print(average_waiting(fcfs(jobs)), average_waiting(sjf_non_preemptive(jobs)))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为 SJF 适合交互系统 | 用户感到卡顿 | SJF 无法预知运行时间且易饥饿 |
| 时间片设得过小 | 切换开销占比高 | 时间片通常为几毫秒到几十毫秒 |
| 忽略优先级反转 | 高优先级任务被拖慢 | 用优先级继承或天花板协议 |
| 只看平均等待时间 | 掩盖长尾 | 同时看 P99 与最大等待 |
| 忽略亲和性 | 缓存命中率低 | 尽量让线程回到同一 CPU |
| 在实时系统用 CFS | 无法保证截止时间 | 用 SCHED_FIFO / RR 或实时补丁 |
| 认为更多线程一定更快 | 切换开销上升 | 按 CPU 密集型核数配置 |
| 忽略 IO 等待 | 误判 CPU 瓶颈 | 看 `vmstat` 的 `wa` 与 `iowait` |
| 忘了记账 | 无法解释性能问题 | 用 `pidstat`、`perf sched` 观察 |
| 把负载均值当实时值 | 判断滞后 | 结合 1/5/15 分钟与瞬时指标 |

## 自测清单

- [ ] 能列出常见调度算法与适用场景。
- [ ] 会计算周转时间、等待时间与平均等待。
- [ ] 知道时间片大小的权衡。
- [ ] 理解优先级反转与解决手段。
- [ ] 会用 `top -H`、`pidstat`、`perf sched` 观察调度行为。
