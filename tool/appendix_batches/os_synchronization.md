## 同步原语对照

| 原语 | 语义 | 适用 | 注意 |
| --- | --- | --- | --- |
| 互斥锁 Mutex | 临界区互斥 | 保护共享状态 | 不可重入（按实现）、不可跨进程（按实现） |
| 自旋锁 Spinlock | 忙等获取 | 极短临界区、内核 | 持锁期间不能睡眠 |
| 读写锁 RWLock | 多读或单写 | 读多写少 | 写者可能饥饿 |
| 信号量 Semaphore | 计数许可 | 限流、资源池 | 计数语义易误用 |
| 条件变量 | 等待条件成立 | 生产者消费者 | 必须配合互斥锁并循环判断 |
| 屏障 Barrier | 等待全部到达 | 并行阶段同步 | 参与者数量必须匹配 |
| 原子操作 | 无锁更新 | 计数、标志位 | 只适用于简单操作 |

## 经典问题速查

| 问题 | 核心矛盾 | 正确解法 |
| --- | --- | --- |
| 生产者消费者 | 缓冲区空满 | 互斥 + 两个条件变量（不为满、不为空） |
| 读者写者 | 读并发与写互斥 | 读写锁或写优先策略 |
| 哲学家就餐 | 循环等待 | 限制同时取筷人数或按序取 |
| 理发师问题 | 有限等待位 | 信号量控制顾客与理发师 |
| 屏障同步 | 阶段对齐 | 屏障或 `CyclicBarrier` |

```python
import threading
from collections import deque

class BoundedQueue:
    """有界阻塞队列：互斥 + 两个条件变量，实现背压。"""

    def __init__(self, capacity: int):
        if capacity <= 0:
            raise ValueError("容量必须为正")
        self.capacity = capacity
        self.items = deque()
        self.lock = threading.Lock()
        self.not_full = threading.Condition(self.lock)
        self.not_empty = threading.Condition(self.lock)
        self.closed = False

    def put(self, item, timeout: float | None = None) -> bool:
        with self.not_full:
            # 必须在循环中判断条件，防止虚假唤醒
            while len(self.items) >= self.capacity and not self.closed:
                if not self.not_full.wait(timeout):
                    return False
            if self.closed:
                return False
            self.items.append(item)
            self.not_empty.notify()
            return True

    def get(self, timeout: float | None = None):
        with self.not_empty:
            while not self.items and not self.closed:
                if not self.not_empty.wait(timeout):
                    return None
            if not self.items:
                return None
            item = self.items.popleft()
            self.not_full.notify()
            return item

    def close(self) -> None:
        with self.lock:
            self.closed = True
            self.not_empty.notify_all()
            self.not_full.notify_all()

    def __len__(self) -> int:
        with self.lock:
            return len(self.items)

queue = BoundedQueue(2)
queue.put("a")
queue.put("b")
print(len(queue), queue.get(), queue.get())
```

## 无锁编程速查

| 概念 | 说明 |
| --- | --- |
| CAS | 比较并交换，无锁更新的基础 |
| ABA 问题 | 值从 A 变 B 又回 A，CAS 误判成功；用版本号解决 |
| 内存序 | 决定读写可见性与重排约束（relaxed、acquire、release） |
| 自旋代价 | 高竞争下自旋浪费 CPU，应退化为阻塞 |
| 伪共享 | 不同线程写同一缓存行导致性能下降 |
| 公平性 | 公平锁开销更大但避免饥饿 |

建议：**能用消息传递就不用共享内存；能用现成并发容器就不手写无锁结构。**

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 条件变量用 `if` 判断 | 虚假唤醒导致越界 | 必须用 `while` 循环判断 |
| 忘记在等待前释放锁 | 死锁 | `wait` 会自动释放并在唤醒后重新获取 |
| 用信号量替代互斥锁 | 计数语义错乱 | 互斥用锁，资源计数用信号量 |
| 自旋锁中做耗时操作 | CPU 空转、系统卡顿 | 自旋锁只用于极短临界区 |
| 只用 `notify` 唤醒一个 | 其他等待者永久阻塞 | 状态变化影响多方时用 `notify_all` |
| 无锁结构不处理 ABA | 偶发数据错乱 | 加版本号或标记指针 |
| 高竞争下暴力重试 | CPU 飙高、吞吐下降 | 指数退避或改为阻塞锁 |
| 忽略伪共享 | 多线程扩展性差 | 对高频写字段做缓存行填充 |
| 长时间持有锁 | 其他线程饥饿 | 缩短临界区，锁外做耗时工作 |
| 顺序加锁不一致 | 死锁 | 统一加锁顺序 |

## 自测清单

- [ ] 能按场景选择互斥锁、读写锁、信号量或条件变量。
- [ ] 条件变量一律用 `while` 判断并配合同一个锁。
- [ ] 知道自旋锁的适用边界。
- [ ] 了解 CAS、ABA 与内存序的基本含义。
- [ ] 共享状态的并发访问都有明确同步策略。
