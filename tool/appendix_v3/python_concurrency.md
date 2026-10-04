## 零基础详解：GIL、线程、进程与 asyncio

### 一句话说清它是什么

Python 有 GIL（全局解释器锁），所以**多线程不能并行跑 CPU 密集任务**，但非常适合 IO 等待；
想真正并行算东西要用多进程；想处理成千上万条网络连接就用 asyncio。

### 用生活比喻理解

| 方案 | 比喻 | 适合 |
| --- | --- | --- |
| 多线程 | 一个收银台，多个人轮流用 | IO 等待（下载、读写文件） |
| 多进程 | 开几家分店 | CPU 密集（计算、图像处理） |
| asyncio | 一个服务员同时照看多桌 | 高并发网络请求 |
| GIL | 只有一把话筒 | 同一时刻只允许一个线程执行字节码 |

### 决策表：先看任务是 IO 还是 CPU

| 任务类型 | 首选方案 | 例子 |
| --- | --- | --- |
| IO 密集，任务数不多 | `ThreadPoolExecutor` | 下载文件、读写磁盘 |
| IO 密集，任务数极多 | `asyncio` | 上万条 HTTP 请求 |
| CPU 密集 | `ProcessPoolExecutor` | 数值计算、图像处理 |
| 简单并行循环 | `concurrent.futures` | 批量处理 |

### 三种写法的对比

```python
# 1. 多线程：适合 IO
from concurrent.futures import ThreadPoolExecutor

def download(url: str) -> int:
    ...                       # 假设这里是网络请求
    return len(url)

with ThreadPoolExecutor(max_workers=8) as pool:
    sizes = list(pool.map(download, urls))

# 2. 多进程：适合 CPU
from concurrent.futures import ProcessPoolExecutor

def heavy(n: int) -> int:
    return sum(i * i for i in range(n))

with ProcessPoolExecutor() as pool:
    results = list(pool.map(heavy, [10**6, 10**6, 10**6]))

# 3. asyncio：适合高并发 IO
import asyncio
import httpx

async def fetch(client: httpx.AsyncClient, url: str) -> int:
    resp = await client.get(url)
    return resp.status_code

async def main() -> None:
    async with httpx.AsyncClient() as client:
        tasks = [fetch(client, url) for url in urls]
        statuses = await asyncio.gather(*tasks)
    print(statuses)

asyncio.run(main())
```

### 加锁：共享数据才需要

```python
import threading

counter = 0
lock = threading.Lock()

def increase() -> None:
    global counter
    for _ in range(1000):
        with lock:                 # 只有这一小段需要保护
            counter += 1
```

多进程之间不共享内存，所以**进程不需要锁，但需要能序列化的数据**。

### asyncio 的三条纪律

1. **不要在协程里写阻塞调用**（`time.sleep`、`requests`），它会卡住整个事件循环。
2. 用 `asyncio.sleep`、`httpx.AsyncClient`、`aiofiles` 这类异步库。
3. CPU 密集的工作丢给 `run_in_executor` 或进程池。

```python
import asyncio

async def main() -> None:
    await asyncio.sleep(1)                 # 正确：异步睡眠
    # time.sleep(1)                        # 错误：会阻塞整个事件循环
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用多线程跑 CPU 密集 | 比单线程还慢 | 改多进程 |
| 在协程里做阻塞调用 | 并发全部退化成串行 | 用异步库或线程池 |
| 忘了加锁 | 计数结果偏小 | 共享变量加锁或换原子方案 |
| 用进程池传 lambda | 无法序列化，报错 | 用模块级函数 |
| 线程里异常被吞掉 | 任务静默失败 | 收集 `future.exception()` |
| 无限制创建线程 | 内存暴涨 | 用线程池控制并发数 |
| 忘了 `asyncio.run` | 协程没有执行 | 用 `asyncio.run(main())` |
| 在 Jupyter 里用 `asyncio.run` | 事件循环冲突 | 用 `await main()` 或 nest_asyncio |

### 手把手练习：并发抓取并统计

```python
import asyncio
import time

import httpx


async def fetch(client: httpx.AsyncClient, url: str) -> tuple[str, int | str]:
    try:
        resp = await client.get(url, timeout=5)
        return url, resp.status_code
    except httpx.HTTPError as exc:
        return url, f"失败：{exc.__class__.__name__}"


async def main(urls: list[str]) -> None:
    start = time.perf_counter()
    async with httpx.AsyncClient() as client:
        results = await asyncio.gather(*(fetch(client, u) for u in urls))
    for url, status in results:
        print(f"{status}  {url}")
    print(f"耗时 {time.perf_counter() - start:.2f} 秒")


if __name__ == "__main__":
    asyncio.run(main(["https://example.com"] * 5))
```

### 学完自测

- [ ] 能用一句话解释 GIL 的影响。
- [ ] 能判断一个任务是 IO 密集还是 CPU 密集，并选对方案。
- [ ] 知道为什么协程里不能写阻塞调用。
- [ ] 知道多进程与多线程在数据共享上的差别。
- [ ] 能说出线程池 `max_workers` 为什么要设上限。
