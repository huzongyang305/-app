## 任务队列设计速查

| 组件 | 职责 | 关键点 |
| --- | --- | --- |
| 队列 | 缓冲与背压 | 有界、支持超时与关闭 |
| 工作池 | 执行任务 | 线程数与任务类型匹配 |
| 调度 | 优先级与公平 | 避免饥饿 |
| 结果通道 | 回传结果 | 有缓冲，避免阻塞 |
| 取消机制 | 停止任务 | 通过 context 或标志传播 |
| 持久化 | 崩溃恢复 | 任务与状态落盘 |
| 观测 | 指标与日志 | 队列长度、延迟、失败率 |

## 并发与线程数速查

| 任务类型 | 线程数建议 | 理由 |
| --- | --- | --- |
| CPU 密集 | 约等于核数 | 避免上下文切换开销 |
| IO 密集 | 核数 ×（1 + 等待占比/计算占比） | 等待期间让出 CPU |
| 混合 | 拆分两类池 | 防止相互阻塞 |
| 虚拟线程（Java 21+） | 按任务量创建 | 适合高并发 IO |

```python
import queue
import threading
import time
from dataclasses import dataclass, field

@dataclass
class Metrics:
    processed: int = 0
    failed: int = 0
    total_wait_ms: float = 0.0
    total_run_ms: float = 0.0

    def summary(self) -> dict:
        processed = max(1, self.processed)
        return {
            "processed": self.processed,
            "failed": self.failed,
            "avg_wait_ms": round(self.total_wait_ms / processed, 2),
            "avg_run_ms": round(self.total_run_ms / processed, 2),
        }

@dataclass
class TaskQueue:
    """有界任务队列 + 优雅关闭：支持背压与在途任务完成。"""

    capacity: int = 32
    workers: int = 4
    metrics: Metrics = field(default_factory=Metrics)

    def __post_init__(self):
        self.queue: queue.Queue = queue.Queue(maxsize=self.capacity)
        self.stop_event = threading.Event()
        self.threads = []

    def start(self, handler) -> None:
        for index in range(self.workers):
            thread = threading.Thread(
                target=self._worker, args=(handler,), name=f"worker-{index}", daemon=True
            )
            thread.start()
            self.threads.append(thread)

    def submit(self, item, timeout: float = 0.5) -> bool:
        try:
            self.queue.put((item, time.monotonic()), timeout=timeout)
            return True
        except queue.Full:
            return False        # 背压：调用方决定等待、降级或丢弃

    def _worker(self, handler) -> None:
        while not self.stop_event.is_set() or not self.queue.empty():
            try:
                item, enqueued = self.queue.get(timeout=0.2)
            except queue.Empty:
                continue
            started = time.monotonic()
            self.metrics.total_wait_ms += (started - enqueued) * 1000
            try:
                handler(item)
                self.metrics.processed += 1
            except Exception:
                self.metrics.failed += 1
            finally:
                self.metrics.total_run_ms += (time.monotonic() - started) * 1000
                self.queue.task_done()

    def shutdown(self, timeout: float = 5.0) -> bool:
        self.stop_event.set()
        for thread in self.threads:
            thread.join(timeout=timeout)
        return not any(thread.is_alive() for thread in self.threads)

def process(item) -> None:
    if item == "boom":
        raise ValueError("任务失败")
    time.sleep(0.01)

tq = TaskQueue(capacity=4, workers=2)
tq.start(process)
for task in ["a", "b", "boom", "c"]:
    tq.submit(task)
time.sleep(0.4)
print(tq.shutdown(), tq.metrics.summary())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 队列无界 | 内存持续增长直至 OOM | 用有界队列 + 拒绝策略实现背压 |
| 关闭时直接杀线程 | 任务半途中断、数据不一致 | 停止接收 + 等待在途完成 |
| 任务不幂等 | 重试产生副作用 | 用幂等键与状态机 |
| 异常未捕获 | 工作线程静默退出 | 在 worker 内统一捕获并记录 |
| 线程数与任务类型不匹配 | CPU 空转或切换过多 | 按 CPU/IO 类型分配 |
| 无指标监控 | 队列积压不可见 | 记录队列长度、等待与执行时间 |
| 无取消机制 | 无法停止长任务 | 用 context 或标志位检查 |
| 崩溃丢任务 | 重启后任务消失 | 关键任务持久化 + 恢复扫描 |
| 死锁式等待结果 | 队列满且调用方阻塞 | 结果通道有缓冲或异步回传 |
| 忽略优雅退出测试 | 上线才发现丢任务 | 写测试覆盖关闭路径 |

## 自测清单

- [ ] 队列有界，并定义明确的拒绝策略。
- [ ] 支持优雅关闭，等在途任务完成。
- [ ] 任务幂等，失败可安全重试。
- [ ] 线程数按任务类型设置，CPU 与 IO 分离。
- [ ] 有队列长度、等待时间与失败率监控。
