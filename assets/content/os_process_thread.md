# 进程与线程

![进程与线程](images/remaining_process_thread.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：14 分钟

## 学习目标

- 能用自己的话解释「进程与线程」解决了什么问题，而不是只背术语。
- 能说清 「进程」、「线程」、「并发」、「上下文切换」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「操作系统」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：资源分配与调度的区别，以及并发安全问题。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：进程、线程、并发。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 进程：资源分配的单位

进程是正在运行的程序实例，拥有独立的虚拟地址空间、文件描述符和信号处理等资源。进程之间相互隔离，一个进程崩溃通常不影响其他进程。

```text
进程 = 代码段 + 数据段 + 堆 + 栈 + 打开的文件 + 页表 ...
```

## 线程：CPU 调度的单位

线程是进程内的执行流，同一进程的多个线程**共享地址空间和打开的文件**，但各自拥有独立的栈和寄存器状态。

| 对比项 | 进程 | 线程 |
| --- | --- | --- |
| 地址空间 | 独立 | 共享 |
| 创建开销 | 大 | 小 |
| 通信方式 | 管道、共享内存、消息队列 | 直接读写共享变量 |
| 隔离性 | 强 | 弱，一个线程崩溃可能拖垮进程 |
| 切换成本 | 高（切换页表） | 低 |

## 上下文切换

CPU 核心数有限，操作系统通过时间片轮转让多个线程「同时」运行。切换时需要保存和恢复寄存器、程序计数器等状态：

```text
线程 A 运行 -> 时间片用完 -> 保存 A 的上下文
            -> 载入 B 的上下文 -> 线程 B 运行
```

频繁切换会带来额外开销，所以线程数不是越多越好。

## 并发安全问题

多个线程同时修改共享数据会产生竞态条件：

```python
import threading

count = 0

def increase():
    global count
    for _ in range(100000):
        count += 1        # 实际是「读-改-写」三步，非原子

threads = [threading.Thread(target=increase) for _ in range(2)]
for t in threads:
    t.start()
for t in threads:
    t.join()

print(count)   # 很可能小于 200000
```

解决办法：加锁、使用原子操作，或避免共享可变状态。

```python
lock = threading.Lock()

def safe_increase():
    global count
    for _ in range(100000):
        with lock:
            count += 1
```

## 复现竞态与死锁的步骤

**实验一：竞态（丢失更新）**

1. 两个线程各自把全局计数变量自增 10 万次（读-改-写三步非原子）。
2. 预期 20 万，实际通常小于该值——这就是丢失更新。
3. 修复：用互斥锁包住自增语句，或改用原子类型；修复后再跑 10 次，结果应稳定为 20 万。

**实验二：死锁**

1. 准备两把锁 a、b；线程 T1 先拿 a 再拿 b，线程 T2 先拿 b 再拿 a。
2. 在两次加锁之间插入短睡眠，放大交错概率，程序会卡住不再输出。
3. 修复：统一加锁顺序（都按 a→b），或用带超时的加锁（超时后释放已持有的锁并重试）。

**验证与观测手段**

| 手段 | 用途 |
| --- | --- |
| 加压后反复运行 | 竞态问题具有偶发性，需多次运行才暴露 |
| 打印线程栈 / faulthandler | 死锁时看线程卡在哪一行 |
| top -H 看线程数 | 线程持续增长说明创建后未回收 |
| 并发单测（跑 1 万次断言） | 把修复固化下来，防止回归 |

关键认知：竞态与死锁都**不会稳定复现**，因此修复后必须用高频次的并发测试来验证，而不是跑一次通过就认为好了。

## 本课小结
**进程隔离资源，线程共享资源**。共享带来了便利，也带来了同步问题。


## 进程与线程速查

| 维度 | 进程 | 线程 |
| --- | --- | --- |
| 定义 | 资源分配的基本单位 | CPU 调度的基本单位 |
| 地址空间 | 各自独立 | 同进程内共享 |
| 创建开销 | 大（含页表与资源） | 小 |
| 通信方式 | 管道、消息队列、共享内存、socket | 直接读写共享变量（需同步） |
| 隔离性 | 强，一个崩溃通常不影响其他 | 弱，一个线程崩溃拖垮整个进程 |
| 切换成本 | 高（切页表、刷 TLB） | 较低 |
| 典型用途 | 服务隔离、多核并行计算 | 并发处理请求、异步 IO |

线程共享与私有内容：

| 共享 | 私有 |
| --- | --- |
| 代码段、堆、全局变量、打开的文件 | 栈、寄存器、程序计数器、线程局部存储 |

## 常见并发问题速查

| 问题 | 成因 | 现象 | 对策 |
| --- | --- | --- | --- |
| 竞态条件 | 多线程交错读写共享数据 | 结果随机、偶发错误 | 加锁、原子操作、减少共享 |
| 死锁 | 互等对方持有的锁 | 线程永久阻塞 | 统一加锁顺序、超时、避免嵌套锁 |
| 活锁 | 不断重试但无法推进 | CPU 高但无进展 | 加入随机退避 |
| 饥饿 | 低优先级线程长期得不到调度 | 个别任务迟迟不完成 | 公平锁、队列化 |
| 伪共享 | 不同线程改同一缓存行 | 性能远低于预期 | 数据填充对齐、线程本地累加 |

```python
import threading

counter = 0
lock = threading.Lock()

def worker(times: int) -> None:
    global counter
    for _ in range(times):
        with lock:                 # 复合操作必须加锁
            counter += 1

threads = [threading.Thread(target=worker, args=(10_000,)) for _ in range(4)]
for t in threads: t.start()
for t in threads: t.join()
print(counter)                     # 40000
```

## 排查命令速查

| 目的 | 命令 |
| --- | --- |
| 查看进程与线程 | `ps -eLf \| grep app`、`top -H -p <pid>` |
| 查看线程栈 | `pstack <pid>`、`gdb -p <pid>` + `thread apply all bt` |
| 查看 Java 线程 | `jstack <pid>`、`jcmd <pid> Thread.print` |
| 查看锁等待 | `SHOW ENGINE INNODB STATUS`（数据库）、`jstack` 找 `BLOCKED` |
| 查看资源占用 | `pidstat -w -p <pid> 1`（上下文切换）、`vmstat 1` |
| 查看文件句柄 | `lsof -p <pid>` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用线程处理 CPU 密集任务（Python） | 没有加速 | GIL 限制，改用多进程 |
| 加锁粒度覆盖整个函数 | 并发退化为串行 | 只锁临界区 |
| 同一业务却用多把锁嵌套 | 偶发死锁 | 统一顺序或改用单锁 |
| 线程池核心数远大于核数且任务是 CPU 型 | 上下文切换开销大 | CPU 密集型线程数约等于核数 |
| 线程间共享可变对象且不加同步 | 数据损坏 | 用不可变数据、加锁或消息传递 |
| 忘记 `join` | 主线程提前退出或统计错误 | 明确等待所有线程结束 |
| 用 `sleep` 代替同步 | 测试通过但线上偶发失败 | 用条件变量、队列或事件 |
| 任务异常未捕获 | 线程静默退出，任务丢失 | 在线程入口统一捕获并记录 |
| 进程退出前未清理子进程 | 僵尸进程 | 等待或 `kill` 后 `wait` |

## 自测清单

- [ ] 能说清「进程是资源单位、线程是调度单位」。
- [ ] 知道线程间共享与私有的内存区域。
- [ ] 加锁只覆盖临界区，并统一加锁顺序。
- [ ] 会用 `top -H`、`jstack`、`pstack` 排查卡死。
- [ ] 线程池大小按任务类型（CPU / IO）确定。

## 动手练习


> 本课练习重点：围绕「进程、线程、并发」完成复述、实验和交付，每个结果都要能被别人检查。

先画出进程、线程或资源状态，再模拟调度与竞争，最后记录状态迁移。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「进程与线程」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「线程」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

用伪代码或小脚本模拟一次调度、竞争或资源分配，并记录至少 5 个状态变化。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「进程」和「线程」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：操作系统中资源分配的基本单位是？

- **正确判断**：进程
- **判断依据**：进程是资源分配的基本单位，拥有独立的地址空间和文件描述符。其他选项：线程是 CPU 调度的基本单位，并不拥有独立的地址空间与文件描述符。针对「操作系统中资源分配的基本单位是，」，本课在「上下文切换」中说明：CPU 核心数有限，操作系统通过时间片轮转让多个线程「同时」运行。本课还在「进程：资源分配的单位」中说明：进程是正在运行的程序实例，拥有独立的虚拟地址空间、文件描述符和信号处理等资源。本课还在「线程：CPU 调度的单位」中说明：线程是进程内的执行流，同一进程的多个线程共享地址空间和打开的文件，但各自拥有独立的栈和寄存器状态。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：同一进程内的多个线程默认共享什么？

- **正确判断**：地址空间与打开的文件
- **判断依据**：正确答案是「地址空间与打开的文件」，本课在「线程：CPU 调度的单位」中说明：线程是进程内的执行流，同一进程的多个线程共享地址空间和打开的文件，但各自拥有独立的栈和寄存器状态。线程共享进程的地址空间和打开的文件，但各自拥有独立的栈和寄存器状态。本课还在「上下文切换」中说明：切换时需要保存和恢复寄存器、程序计数器等状态。本课还在「进程：资源分配的单位」中说明：进程是正在运行的程序实例，拥有独立的虚拟地址空间、文件描述符和信号处理等资源。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：多线程执行 count += 1 结果偏小，根本原因是什么？

- **正确判断**：读-改-写不是原子操作，存在竞态条件
- **判断依据**：正确答案是「读-改-写不是原子操作，存在竞态条件」，本课在「并发安全问题」中说明：解决办法：加锁、使用原子操作，或避免共享可变状态。count += 1 实际包含读取、加一、写回三步，交错执行会丢失更新，需要加锁或使用原子操作。本课还在「上下文切换」中说明：频繁切换会带来额外开销，所以线程数不是越多越好。本课还在「复现竞态与死锁的步骤」中说明：两个线程各自把全局计数变量自增 10 万次（读-改-写三步非原子）。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：操作系统中 CPU 调度的基本单位是？

- **正确判断**：线程（进程是资源分配的基本单位）
- **判断依据**：正确答案是「线程（进程是资源分配的基本单位）」，本课在「上下文切换」中说明：CPU 核心数有限，操作系统通过时间片轮转让多个线程「同时」运行。所以同一进程内的多线程才能真正并行于多核之上。本课还在「复现竞态与死锁的步骤」中说明：关键认知：竞态与死锁都不会稳定复现，因此修复后必须用高频次的并发测试来验证，而不是跑一次通过就认为好了。本课还在「进程：资源分配的单位」中说明：进程之间相互隔离，一个进程崩溃通常不影响其他进程。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：同进程内线程切换通常比进程切换快的原因是？

- **正确判断**：共享同一地址空间
- **判断依据**：正确答案是「共享同一地址空间」，本课在「上下文切换」中说明：切换时需要保存和恢复寄存器、程序计数器等状态。这也解释了为什么高并发服务器优先使用线程池而不是频繁创建进程。本课还在「复现竞态与死锁的步骤」中说明：预期 20 万，实际通常小于该值——这就是丢失更新。本课还在「复现竞态与死锁的步骤」中说明：线程 T1 先拿 a 再拿 b，线程 T2 先拿 b 再拿 a。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 6：补全代码：「进程与线程」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `for t in threads: t.____()`

- **正确判断**：join
- **判断依据**：正确答案是「join」，本课在「复现竞态与死锁的步骤」中说明：关键认知：竞态与死锁都不会稳定复现，因此修复后必须用高频次的并发测试来验证，而不是跑一次通过就认为好了。本课示例中还能看到 `t.join()` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「操作系统中资源分配的基本单位是？」的判断依据。
- [ ] 不看解析，能说出「同一进程内的多个线程默认共享什么？」的判断依据。
- [ ] 不看解析，能说出「多线程执行 count += 1 结果偏小，根本原因是什么？」的判断依据。
- [ ] 不看解析，能说出「操作系统中 CPU 调度的基本单位是？」的判断依据。
- [ ] 不看解析，能说出「同进程内线程切换通常比进程切换快的原因是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「进程与线程」示例中，下面这行代码缺少哪个关键字或函数名？请填入 __…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Process & Thread

**Summary:** Resource ownership vs scheduling, and race conditions.

**Category:** Operating Systems  
**Level:** 进阶  
**Key terms:** 进程, 线程, 并发, 上下文切换, 锁, 竞态

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Linux 6.x / POSIX
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：进程、线程、并发、上下文切换、锁、竞态
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**Process & Thread** focuses on Resource ownership vs scheduling, and race conditions.

### Learning Outcomes

- Explain what **Process & Thread** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Process & Thread**
- Related terms: 进程, 线程, 并发, 上下文切换
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 进程：资源分配的单位 | 进程：资源分配的单位 |
| 线程：CPU 调度的单位 | 线程：CPU 调度的单位 |
| 上下文切换 | Context切换 |
| 并发安全问题 | ConcurrencySecurity问题 |
| 复现竞态与死锁的步骤 | 复现竞态与死锁的步骤 |
| 本课小结 | Summary |
| 进程与线程速查 | 进程与线程速查 |
| 常见并发问题速查 | 常见Concurrency问题速查 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Linux Kernel Docs](https://docs.kernel.org/) | 进程、内存、I/O 与调度 |
| [Linux man-pages](https://man7.org/linux/man-pages/) | 系统调用与用户态接口 |

> 本课主题：资源分配与调度的区别，以及并发安全问题。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

