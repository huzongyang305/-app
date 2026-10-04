## 并发方案选型速查

| 场景 | 推荐方案 | 理由 | 关键 API |
| --- | --- | --- | --- |
| 大量网络 / 文件 IO | `asyncio` | 单线程事件循环，开销最小 | `async def`、`await`、`asyncio.gather` |
| 少量并发、用同步库 | `ThreadPoolExecutor` | 等待 IO 时会释放 GIL | `executor.map`、`submit` |
| CPU 密集计算 | `ProcessPoolExecutor` | 绕开 GIL，真正并行 | `ProcessPoolExecutor`、`multiprocessing` |
| 需要共享状态的多线程 | 线程 + 锁 | 保证复合操作原子性 | `threading.Lock`、`RLock` |
| 生产消费模型 | `queue.Queue` | 天然线程安全 | `put`、`get`、`task_done` |
| 定时 / 延迟任务 | `asyncio.sleep` 或调度库 | 不阻塞线程 | 避免 `time.sleep` 出现在协程里 |

GIL 速查：

| 问题 | 结论 |
| --- | --- |
| GIL 是什么 | CPython 解释器级别的互斥锁，保证同一时刻只有一个线程执行字节码 |
| 影响 CPU 密集吗 | 有影响，多线程难以提速，应使用多进程 |
| 影响 IO 密集吗 | 影响很小，等待 IO 时会释放 GIL |
| 多线程还需要锁吗 | 需要，`count += 1` 这类复合操作不是原子的 |
| 未来会移除吗 | 已有可选的无 GIL 构建，但生态兼容仍在推进 |

```python
import asyncio

async def fetch(name, delay):
    await asyncio.sleep(delay)      # 模拟网络等待，注意不是 time.sleep
    return f"{name} 完成"

async def main():
    # 并发执行，总耗时约等于最慢的那个（0.3 秒）
    results = await asyncio.gather(fetch("a", 0.3), fetch("b", 0.1))
    print(results)

asyncio.run(main())
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在协程里调用 `time.sleep()` | 整个事件循环被卡住 | 改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor` |
| 在协程里直接 `requests.get()` | 其他任务全部等待 | 用 `httpx` / `aiohttp` 等异步客户端 |
| 忘了 `await` 协程 | `RuntimeWarning: coroutine was never awaited` | 调用协程函数必须 `await` 或交给 `create_task` |
| 多线程共享计数变量直接 `+=` | 结果偏小 | 加锁或用 `queue` 汇总 |
| 用多线程跑 CPU 密集任务 | 速度没有提升甚至更慢 | 改多进程或原生扩展 |
| `ProcessPoolExecutor` 里传不可序列化对象 | `PicklingError` | 传简单数据或可序列化对象 |
| 无限制创建线程 / 协程 | 内存暴涨、调度开销大 | 用线程池与信号量（`asyncio.Semaphore`）限制并发 |
| 忘记关闭线程池 | 进程无法退出 | `with ThreadPoolExecutor() as ex:` 或显式 `shutdown` |
| 多进程直接改全局变量 | 父进程看不到变化 | 进程内存独立，用返回值或共享内存 / 队列 |
| 用 `asyncio.run` 嵌套调用 | `RuntimeError: asyncio.run() cannot be called from a running event loop` | 顶层只调用一次，内部用 `await` 或 `create_task` |

## 自测清单

- [ ] 能按「IO 密集 / CPU 密集」正确选择 asyncio、多线程、多进程。
- [ ] 知道 GIL 会释放的时机，以及为什么共享计数要加锁。
- [ ] 协程里绝不出现阻塞调用。
- [ ] 用信号量或线程池限制并发规模。
- [ ] 用 `asyncio.gather` 并发等待多个协程，而不是逐个 `await`。
