# 并发与异步

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：55 分钟

![Python 线程、进程与 asyncio 对比](images/diagram_python_concurrency.webp)

![并发与异步](images/remaining_python_concurrency.webp)

## 本节知识框架

**课程定位**：所属分类 `python`（Python），课程主题 `并发与异步`，学习阶段 高级，建议用时 50 分钟。

本课主线：GIL、多线程、多进程与 asyncio 的适用场景和写法。

**学完本课应当能够**
- 说清 `ProcessPoolExecutor` 与 `await` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `time.sleep` 的行为，记录输入、输出与失败条件。
- 遇到「用多线程跑 CPU 密集」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `ProcessPoolExecutor`：先掌握 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景，再用它解释 `await` 为什么会出现。
2. `await`：先掌握 异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求，再用它解释 `time.sleep` 为什么会出现。
3. `time.sleep`：先掌握 注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库，再用它解释 `并发` 为什么会出现。
4. `并发`：先掌握 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Python」分类的第 24 课。先修内容：《类型注解与测试》。《类型注解与测试》里的 `typing`、`pyproject.toml` 是本课的前提。相关或后续课程：《实战：爬虫与数据分析》。

### 完成判据

- **定义关**：不看正文也能说明 `ProcessPoolExecutor` 是 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `并发与异步`，而不是只背结论。
- **示例关**：能运行或推演 `并发与异步` 的 `python` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `并发与异步` 示例里的 调用了 `download()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 用多线程跑 CPU 密集，记录现象并按 改多进程 修复。
- **迁移关**：能把 `并发`、`并行`、`GIL`、`threading` 放进一个与 `并发与异步` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `并发与异步` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| ProcessPoolExecutor | 线程池同理，把 ProcessPoolExecutor 换成 ThreadPoolExecutor 即可，适合 IO 密集场景。 | 易错：`PicklingError`；正确做法是传简单数据或可序列化对象。 |
| await | 异步是单线程内的事件循环协作：遇到 await 就让出控制权，适合高并发网络请求。 | 易错：事件循环冲突；正确做法是用 `await main()` 或 nest_asyncio。 |
| time.sleep | 注意：**异步函数里不能写阻塞调用**（如 time.sleep、同步 requests），否则整个事件循环被卡住，应改用 asyncio.sleep、aiohttp 等异步库。 | 易错：整个事件循环被卡住；正确做法是改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor`。 |
| 并发 | 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。 | 易错：并发全部退化成串行；正确做法是用异步库或线程池。 |

## 原理与运行机制

### 机制总览

**教材衔接：怎么选**

| 场景 | 推荐方案 |
| --- | --- |
| 大量网络 / 文件 IO | `asyncio` 或线程池 |
| 少量并发、代码简单 | `threading` |
| CPU 密集计算 | `multiprocessing` |
| 需要进程间通信 | `multiprocessing.Queue` / `Pipe` |

**教材衔接：版本与时效**

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 并发 相关的差异单独记成一条结论。
- 升级后重点回归 并发 的默认值、警告信息与错误格式。
- 升级后把 ProcessPoolExecutor 的实测版本写进「内容元数据」，再更新复核日期。

**失败路径（来自本课错误表）**
- 用多线程跑 CPU 密集 → 比单线程还慢 → 改多进程。
- 在协程里做阻塞调用 → 并发全部退化成串行 → 用异步库或线程池。
- 忘了加锁 → 计数结果偏小 → 共享变量加锁或换原子方案。
- 用进程池传 lambda → 无法序列化，报错 → 用模块级函数。
### 机制拆解：每一步的输入、动作与输出

#### 1. `ProcessPoolExecutor`
- 输入：`并发`；本步把 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景 当作判断规则。
- 动作：围绕 `ProcessPoolExecutor` 保留中间状态，并记录它与 `await` 的对应关系。
- 输出：`await`，它可以被下一段代码、测试或记录继续使用。
- `ProcessPoolExecutor` 的失败条件：当`ProcessPoolExecutor` 里传不可序列化对象时，会出现`PicklingError`。

#### 2. `await`
- 输入：`ProcessPoolExecutor`；本步把 异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求 当作判断规则。
- 动作：围绕 `await` 保留中间状态，并记录它与 `time.sleep` 的对应关系。
- 输出：`time.sleep`，它可以被下一段代码、测试或记录继续使用。
- `await` 的失败条件：当在 Jupyter 里用 `asyncio.run`时，会出现事件循环冲突。

#### 3. `time.sleep`
- 输入：`await`；本步把 注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库 当作判断规则。
- 动作：围绕 `time.sleep` 保留中间状态，并记录它与 `并发` 的对应关系。
- 输出：`并发`，它可以被下一段代码、测试或记录继续使用。
- `time.sleep` 的失败条件：当在协程里调用 `time.sleep()`时，会出现整个事件循环被卡住。

#### 4. `并发`
- 输入：`time.sleep`；本步把 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度 当作判断规则。
- 动作：围绕 `并发` 保留中间状态，并记录它与 `download` 的对应关系。
- 输出：`download`，它可以被下一段代码、测试或记录继续使用。
- `并发` 的失败条件：当在协程里做阻塞调用时，会出现并发全部退化成串行。

### 示例中的可观察事实

1. 调用了 `download()`；它对应的课程主题是 `并发与异步`。
2. 调用了 `sleep()`；它对应的课程主题是 `并发与异步`。
3. 调用了 `print()`；它对应的课程主题是 `并发与异步`。
4. 调用了 `Thread()`；它对应的课程主题是 `并发与异步`。
5. 调用了 `range()`；它对应的课程主题是 `并发与异步`。
6. 调用了 `start()`；它对应的课程主题是 `并发与异步`。
7. 调用了 `join()`；它对应的课程主题是 `并发与异步`。
8. 出现字面量 `{name} 下载完成`；它对应的课程主题是 `并发与异步`。

### 复现实验记录

- 环境：`并发与异步` 使用 `python` 示例，固定 `并发`、`并行`、`GIL`、`threading` 作为第一组条件。
- 首轮输入：先确认 调用了 `download()`，预测 `ProcessPoolExecutor` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `并发`，观察 `并发` 是否仍满足定义。
- 失败注入：复现 用多线程跑 CPU 密集，确认现象是 比单线程还慢。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `并发与异步` 时才能区分概念错误与实现错误。

## 典型应用场景

- **用多线程跑 CPU 密集**：典型现象是比单线程还慢；正确做法是改多进程。
- **在协程里做阻塞调用**：典型现象是并发全部退化成串行；正确做法是用异步库或线程池。
- **忘了加锁**：典型现象是计数结果偏小；正确做法是共享变量加锁或换原子方案。
- **用进程池传 lambda**：典型现象是无法序列化，报错；正确做法是用模块级函数。

### 最小验证场景

- 准备：保留 `python` 示例的原始输入，先记录 `并发与异步` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `download()`，再改变一个与 `ProcessPoolExecutor` 相关的条件。
- 判定：新结果与 `并发与异步` 的基线不同不等于错误；只有当差异破坏了 `ProcessPoolExecutor` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `ProcessPoolExecutor` 时，先满足它的定义：线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景；易错：`PicklingError`；正确做法是传简单数据或可序列化对象。
- 使用 `await` 时，先满足它的定义：异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求；易错：事件循环冲突；正确做法是用 `await main()` 或 nest_asyncio。
- 使用 `time.sleep` 时，先满足它的定义：注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库；易错：整个事件循环被卡住；正确做法是改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor`。
- 使用 `并发` 时，先满足它的定义：多个任务在重叠时间窗口内推进，关注共享状态、同步与调度；易错：并发全部退化成串行；正确做法是用异步库或线程池。

## 代码/协议/SQL 示例

### 最小可验证示例

```python
import threading
import time

def download(name):
    time.sleep(1)              # 模拟网络等待
    print(f"{name} 下载完成")

threads = [threading.Thread(target=download, args=(f"文件{i}",)) for i in range(3)]
for t in threads:
    t.start()
for t in threads:
    t.join()                   # 等待全部结束
```

**教材衔接：多线程 threading**

共享数据要加锁：

```python
lock = threading.Lock()
count = 0

def increase():
    global count
    for _ in range(100000):
        with lock:
            count += 1
```

**教材衔接：多进程 multiprocessing**

```python
from concurrent.futures import ProcessPoolExecutor

def cpu_heavy(n):
    return sum(i * i for i in range(n))

if __name__ == "__main__":
    with ProcessPoolExecutor() as pool:
        results = list(pool.map(cpu_heavy, [10**6, 10**6, 10**6]))
    print(results)
```

线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。

**教材衔接：异步 asyncio**

异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求。

```python
import asyncio

async def fetch(name):
    await asyncio.sleep(1)         # 模拟网络请求
    return f"{name} 完成"

async def main():
    results = await asyncio.gather(
        fetch("A"), fetch("B"), fetch("C")
    )
    print(results)                 # 三个任务并发，总耗时约 1 秒

asyncio.run(main())
```

注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库。

**教材衔接：零基础详解：GIL、线程、进程与 asyncio**

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

**运行方式**：运行 `并发与异步` 的示例时，保存为 `.py` 文件后用 `python 文件名.py` 运行；第三方依赖先在虚拟环境里安装。

### 示例精读：先找证据，再改一个条件

1. 调用了 `download()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `sleep()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `print()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `Thread()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `range()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `start()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `join()`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
8. 出现字面量 `{name} 下载完成`；它出现在 `并发与异步` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `并发与异步` 中与 `ProcessPoolExecutor` 对照：示例必须能支持 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景，否则说明这一段还缺少实现或验证步骤。
- 在 `并发与异步` 中与 `await` 对照：示例必须能支持 异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求，否则说明这一段还缺少实现或验证步骤。
- 在 `并发与异步` 中与 `time.sleep` 对照：示例必须能支持 注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库，否则说明这一段还缺少实现或验证步骤。
- 在 `并发与异步` 中与 `并发` 对照：示例必须能支持 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

| 场景 | 推荐方案 | 理由 | 关键 API |
| --- | --- | --- | --- |
| 大量网络 / 文件 IO | `asyncio` | 单线程事件循环，开销最小 | `async def`、`await`、`asyncio.gather` |
| 少量并发、用同步库 | `ThreadPoolExecutor` | 等待 IO 时会释放 GIL | `executor.map`、`submit` |
| CPU 密集计算 | `ProcessPoolExecutor` | 绕开 GIL，真正并行 | `ProcessPoolExecutor`、`multiprocessing` |
| 需要共享状态的多线程 | 线程 + 锁 | 保证复合操作原子性 | `threading.Lock`、`RLock` |
| 生产消费模型 | `queue.Queue` | 天然线程安全 | `put`、`get`、`task_done` |
| 定时 / 延迟任务 | `asyncio.sleep` 或调度库 | 不阻塞线程 | 避免 `time.sleep` 出现在协程里 |

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

**测量方法**：以 `并发与异步` 的 `并发` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `并发与异步` 的 `并发`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `并发与异步` 的 `并行`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `并发与异步` 的 `GIL`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `并发与异步` 的 `threading`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `并发与异步` 的 `asyncio`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `并发与异步` 中 `ProcessPoolExecutor` 的边界：易错：`PicklingError`；正确做法是传简单数据或可序列化对象。达到边界时不要外推，必须重新测量。
- `并发与异步` 中 `await` 的边界：易错：事件循环冲突；正确做法是用 `await main()` 或 nest_asyncio。达到边界时不要外推，必须重新测量。
- `并发与异步` 中 `time.sleep` 的边界：易错：整个事件循环被卡住；正确做法是改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor`。达到边界时不要外推，必须重新测量。
- `并发与异步` 中 `并发` 的边界：易错：并发全部退化成串行；正确做法是用异步库或线程池。达到边界时不要外推，必须重新测量。
- `并发与异步` 的代码证据：先验证 调用了 `download()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用多线程跑 CPU 密集 | 比单线程还慢 | 改多进程 |
| 在协程里做阻塞调用 | 并发全部退化成串行 | 用异步库或线程池 |
| 忘了加锁 | 计数结果偏小 | 共享变量加锁或换原子方案 |
| 用进程池传 lambda | 无法序列化，报错 | 用模块级函数 |
| 线程里异常被吞掉 | 任务静默失败 | 收集 `future.exception()` |
| 无限制创建线程 | 内存暴涨 | 用线程池控制并发数 |
| 忘了 `asyncio.run` | 协程没有执行 | 用 `asyncio.run(main())` |
| 在 Jupyter 里用 `asyncio.run` | 事件循环冲突 | 用 `await main()` 或 nest_asyncio |
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
| 在协程里调用 time.sleep() | 整个事件循环被卡住。 | 改 await asyncio.sleep()；同步阻塞库用 run_in_executor。 |
| 在协程里直接 requests.get() | 其他任务全部等待。 | 用 httpx / aiohttp 等异步客户端。 |
| 忘了 await 协程 | RuntimeWarning: coroutine was never awaited。 | 调用协程函数必须 await 或交给 create_task。 |

### 现场 1：用多线程跑 CPU 密集

**症状**：比单线程还慢。

**根因与修复**：改多进程。

**自检**：在本课示例里复现「用多线程跑 CPU 密集」，改成改多进程后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：在协程里做阻塞调用

**症状**：并发全部退化成串行。

**根因与修复**：用异步库或线程池。

**自检**：在本课示例里复现「在协程里做阻塞调用」，改成用异步库或线程池后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：忘了加锁

**症状**：计数结果偏小。

**根因与修复**：共享变量加锁或换原子方案。

**自检**：在本课示例里复现「忘了加锁」，改成共享变量加锁或换原子方案后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：用进程池传 lambda

**症状**：无法序列化，报错。

**根因与修复**：用模块级函数。

**自检**：在本课示例里复现「用进程池传 lambda」，改成用模块级函数后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：线程里异常被吞掉

**症状**：任务静默失败。

**根因与修复**：收集 `future.exception()`。

**自检**：在本课示例里复现「线程里异常被吞掉」，改成收集 `future.exception()`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：无限制创建线程

**症状**：内存暴涨。

**根因与修复**：用线程池控制并发数。

**自检**：在本课示例里复现「无限制创建线程」，改成用线程池控制并发数后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：忘了 `asyncio.run`

**症状**：协程没有执行。

**根因与修复**：用 `asyncio.run(main())`。

**自检**：在本课示例里复现「忘了 `asyncio.run`」，改成用 `asyncio.run(main())`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：在 Jupyter 里用 `asyncio.run`

**症状**：事件循环冲突。

**根因与修复**：用 `await main()` 或 nest_asyncio。

**自检**：在本课示例里复现「在 Jupyter 里用 `asyncio.run`」，改成用 `await main()` 或 nest_asyncio后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：在协程里调用 `time.sleep()`

**症状**：整个事件循环被卡住。

**根因与修复**：改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor`。

**自检**：在本课示例里复现「在协程里调用 `time.sleep()`」，改成改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`类型注解与测试`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：爬虫与数据分析`。本课术语会在这些课程里继续使用。
- **术语归属**：`ProcessPoolExecutor`、`await`、`time.sleep` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《Python 并发模型、GIL 与线程进程选型》也涉及 `GIL`；两课衔接时先确认这个术语的定义是否一致。
- 同一分类的《Python asyncio 异步编程：任务、超时与取消》也涉及 `asyncio`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `类型注解与测试`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `实战：爬虫与数据分析`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `ProcessPoolExecutor` 与 `await`：前者强调 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景；后者强调 异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `await` 与 `time.sleep`：前者强调 异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求；后者强调 注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `time.sleep` 与 `并发`：前者强调 注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库；后者强调 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `ProcessPoolExecutor` 的操作性定义，并说明它与 `await` 的区别。

**参考答案**：线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。

`await` 的定位是：异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「用多线程跑 CPU 密集」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是比单线程还慢；正确做法是改多进程。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `python` 示例，把其中的 `"{name} 下载完成"` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `python` 示例应当复现正文给出的结果；把 `"{name} 下载完成"` 换成边界值后，如果结果改变或报错，先核对它是否满足 `并发与异步` 中`ProcessPoolExecutor` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `python` 示例，说明它体现了`ProcessPoolExecutor` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`ProcessPoolExecutor` 的定义是 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景，示例正是在实现这条定义。改动与 `ProcessPoolExecutor` 有关的一个输入后，如果结果不再符合 `并发与异步` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `并发与异步` 的方法迁移到自己的项目：围绕 `ProcessPoolExecutor` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「忘了 await 协程」，它会导致RuntimeWarning: coroutine was never awaited；检验方式是按调用协程函数必须 await 或交给 create_task改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `ProcessPoolExecutor` 与 `await`：各写一行适用场景、一行失败表现。

**参考答案**：`ProcessPoolExecutor` 的定义是线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景；`await` 的定义是异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「用多线程跑 CPU 密集」引发的问题，请把“复现 比单线程还慢 → 保留证据 → 改多进程 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按比单线程还慢复现；第二步记录输入、版本与完整报错；第三步按改多进程只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `并发`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：并发全部退化成串行；正确做法是用异步库或线程池。 同时要把 `并发` 的定义 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `ProcessPoolExecutor` → `await` → `time.sleep` → `并发` 的作用链。

**参考答案**：起点是 `ProcessPoolExecutor` 的定义 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景；中间每一步都保留可观察状态；终点由 `并发` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `并发与异步` 中，现象是 RuntimeWarning: coroutine was never awaited。请围绕 忘了 await 协程 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 忘了 await 协程，记录输入与完整错误；再按 调用协程函数必须 await 或交给 create_task 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `并发与异步`：先给主问题，再按顺序说出 `ProcessPoolExecutor`、`await`、`time.sleep`、`并发`，最后给一个失败案例。

**自评标准**：主问题必须对应 GIL、多线程、多进程与 asyncio 的适用场景和写法；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `ProcessPoolExecutor` | 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。 |
| `await` | 异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求。 |
| `time.sleep` | 注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库。 |
| `并发` | 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。 |

**术语关系**：`ProcessPoolExecutor`（线程池同理） → `await`（异步是单线程内的事件循环协作：遇到 `await` 就让出控制权） → `time.sleep`（注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests）） → `并发`（多个任务在重叠时间窗口内推进）。

## 考点精讲

`并发与异步` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：围绕“并发与异步”中的 并发、并行、GIL，下列哪两项是本课强调的实践判断？
- **正确项**：验证 并行 时要固定版本并覆盖边界输入，结论才可复现；学习 并发 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `并发` 上：多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。复习时把 `并发` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：代码语言为 `python`，选自 `并发与异步` 的 `ProcessPoolExecutor` 部分。课程问题为GIL、多线程、多进程与 asyncio 的适用场景和写法。哪一项描述与代码一致？
- **正确项**：调用了 `sleep()`
- **判断依据**：这道题落在术语 `ProcessPoolExecutor` 上：线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。复习时把 `ProcessPoolExecutor` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：多线程共享计数变量时出现结果偏小，解决办法是？
- **正确项**：用 Lock 保护读-改-写过程
- **判断依据**：这道题检验本课主问题：GIL、多线程、多进程与 asyncio 的适用场景和写法。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 4：第 4 题

- **题目**：GIL 带来的实际影响是？
- **正确项**：多线程无法并行执行 Python 字节码，CPU 密集任务难以提速
- **判断依据**：这道题检验本课主问题：GIL、多线程、多进程与 asyncio 的适用场景和写法。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 5：第 5 题

- **题目**：asyncio.gather 的作用是？
- **正确项**：并发调度并等待多个协程
- **判断依据**：这道题落在术语 `并发` 上：多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。复习时把 `并发` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `GIL、多线程、多进程与 asyncio 的适用场景和写法。`，这段说明是：线程池同理，把 ``____`` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。空缺处应填哪个术语？
- **正确项**：ProcessPoolExecutor
- **判断依据**：这道题落在术语 `ProcessPoolExecutor` 上：线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。复习时把 `ProcessPoolExecutor` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`ProcessPoolExecutor`

- **要点**：线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景。
- **ProcessPoolExecutor 的边界**：易错：`PicklingError`；正确做法是传简单数据或可序列化对象。

### 考点 8：`await`

- **要点**：异步是单线程内的事件循环协作：遇到 `await` 就让出控制权，适合高并发网络请求。
- **await 的边界**：易错：事件循环冲突；正确做法是用 `await main()` 或 nest_asyncio。

### 考点 9：`time.sleep`

- **要点**：注意：**异步函数里不能写阻塞调用**（如 `time.sleep`、同步 requests），否则整个事件循环被卡住，应改用 `asyncio.sleep`、`aiohttp` 等异步库。
- **time.sleep 的边界**：易错：整个事件循环被卡住；正确做法是改 `await asyncio.sleep()`；同步阻塞库用 `run_in_executor`。

### 考点 10：`并发`

- **要点**：多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。
- **并发 的边界**：易错：并发全部退化成串行；正确做法是用异步库或线程池。

### 考点 11：排错——用多线程跑 CPU 密集

- **现象**：比单线程还慢。
- **处理**：改多进程。

### 考点 12：排错——在协程里做阻塞调用

- **现象**：并发全部退化成串行。
- **处理**：用异步库或线程池。

### 考点 13：综合辨析——`ProcessPoolExecutor` 与 `并发`

- **辨析点**：`ProcessPoolExecutor` 的定义是 线程池同理，把 `ProcessPoolExecutor` 换成 `ThreadPoolExecutor` 即可，适合 IO 密集场景；`并发` 的定义是 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。
- **答题要求**：面对 `并发与异步` 的题目，先判断描述的是 `ProcessPoolExecutor` 还是 `并发`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 比单线程还慢，而不是只写“程序有错”。
- **证据分**：保留触发 用多线程跑 CPU 密集 的输入、版本和错误原文。
- **修复分**：按 改多进程 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Python 3.12+
；本课聚焦 并发。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：并发、并行、GIL、threading、asyncio、多进程
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-11-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：并发、并行、GIL、threading、asyncio、多进程。

| 参考资料 | 本课用途 |
| --- | --- |
| [asyncio 文档](https://docs.python.org/3/library/asyncio.html) | 异步 I/O 与并发任务 |
| [Python 性能分析](https://docs.python.org/3/library/profile.html) | cProfile 与性能分析 |
| [typing 文档](https://docs.python.org/3/library/typing.html) | 类型标注与泛型 |

| [本课术语索引：并发与异步](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「并发与异步」的链接用于离线阅读后的延伸核对；App 不会自动联网。