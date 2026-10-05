# Go 并发模式与 errgroup

![Go Worker Pool 与 Pipeline 模式](images/diagram_go_patterns.webp)

![Go 并发模式与 errgroup](images/remaining_go_concurrency_patterns.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「Go 并发模式与 errgroup」解决了什么问题，而不是只背术语。
- 能说清 「并发模式」、「errgroup」、「worker pool」、「pipeline」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Go」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Worker Pool、Pipeline、Fan-in/Fan-out 与并发限流。

## 前置知识

- 先完成上一课《gRPC 与 Protobuf 实践》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：并发模式、errgroup、worker pool。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 模式速查

| 模式 | 结构 | 适用 |
| --- | --- | --- |
| Worker Pool | 固定 worker 消费任务队列 | 控制并发度、批量处理 |
| Pipeline | 多阶段 channel 串联 | 数据流式处理 |
| Fan-out / Fan-in | 多协程处理再汇总 | 提高吞吐 |
| Semaphore | 带缓冲 channel 限制并发 | 保护下游 |
| Timeout / Cancellation | context 传播取消 | 防止无限等待 |
| Singleflight | 合并重复请求 | 缓存击穿、惊群 |

## Worker Pool + errgroup

```go
// 固定并发度处理任务，任一失败即取消其余任务
func ProcessAll(ctx context.Context, items []Item, workers int) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(workers)                 // 限制并发，避免打爆下游

	for _, item := range items {
		item := item                    // Go 1.22 之前需复制，避免闭包捕获
		g.Go(func() error {
			select {
			case <-ctx.Done():
				return ctx.Err()
			default:
			}
			return process(ctx, item)
		})
	}
	return g.Wait()
}

// Pipeline：每个阶段一个 goroutine，用 channel 传递，defer close 保证下游能退出
func Generate(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for _, n := range nums {
			out <- n
		}
	}()
	return out
}

func Square(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for n := range in {
			out <- n * n
		}
	}()
	return out
}

func Sum(in <-chan int) int {
	total := 0
	for n := range in {
		total += n
	}
	return total
}

// 使用：Generate → Square → Sum，全程流式，内存占用恒定
func Demo() int {
	return Sum(Square(Generate(1, 2, 3, 4)))
}
```

## 并发安全原语速查

| 需求 | 选择 | 说明 |
| --- | --- | --- |
| 只读共享数据 | 启动前初始化 | 无需加锁，最简单 |
| 计数 | `atomic.Int64` | 比互斥锁更轻 |
| 复合状态更新 | `sync.Mutex` | 临界区要尽量短 |
| 读多写少 | `sync.RWMutex` | 注意写者饥饿 |
| 一次性初始化 | `sync.Once` | 配合包级变量 |
| 临时对象复用 | `sync.Pool` | 不能当缓存用 |
| 取消传播 | `context` | 逐层传递并检查 |
| 去重合并 | `golang.org/x/sync/singleflight` | 缓存击穿场景 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 无限制启动 goroutine | 内存暴涨、下游被打爆 | 用 `SetLimit` 或信号量限流 |
| 忘记 `defer close(out)` | 下游 `range` 永久阻塞 | 阶段结束时关闭 channel |
| 在循环里直接闭包捕获循环变量 | 处理到同一个元素 | Go 1.22 前需复制或传参 |
| goroutine 里 panic 未处理 | 进程崩溃 | 在入口 `recover` 并记录 |
| 用 channel 做共享内存同步 | 代码难懂、易死锁 | 简单计数用原子操作，状态用锁 |
| 忘记检查 `ctx.Done()` | 取消后仍继续干活 | 在循环与阻塞点检查 |
| 在 worker 中用 `time.Sleep` 重试 | 无法取消 | 用 `select` 配合 `ctx.Done()` 与定时器 |
| 重复请求各打一次下游 | 缓存击穿放大 | 用 singleflight 合并 |

## 自测清单

- [ ] 会用 errgroup 限制并发并传播取消。
- [ ] 能写出三阶段的 pipeline 且正确关闭 channel。
- [ ] 知道何时用原子操作、锁或 channel。
- [ ] goroutine 内 panic 有 recover 与日志。
- [ ] 重复请求用 singleflight 合并。


## 零基础详解：六种常用并发模式

### 一句话说清它是什么

并发模式是「被反复验证过的 goroutine + channel 组合拳」。
记住这六种，日常大部分并发需求都能直接套用。

### 用生活比喻理解

| 模式 | 比喻 | 解决什么 |
| --- | --- | --- |
| worker 池 | 固定人数的服务组 | 限制并发，复用 worker |
| fan-out | 一个任务派给多人 | 提高处理速度 |
| fan-in | 多人结果汇总到一人 | 收集结果 |
| pipeline | 流水线工位 | 分阶段处理数据 |
| semaphore | 停车位 | 限制同时进行的数量 |
| errgroup | 带对讲机的施工队 | 任一失败就全体收工 |

### 模式一：worker 池（限制并发）

```go
func RunWorkers(ctx context.Context, jobs <-chan Job, size int) {
    var wg sync.WaitGroup
    for i := 0; i < size; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            for {
                select {
                case <-ctx.Done():
                    return
                case job, ok := <-jobs:
                    if !ok {
                        return          // channel 已关闭，退出
                    }
                    process(id, job)
                }
            }
        }(i)
    }
    wg.Wait()
}
```

### 模式二与三：fan-out / fan-in

```go
func FanOutFanIn(ctx context.Context, inputs []int) []int {
    in := make(chan int)
    out := make(chan int)

    // fan-out：3 个 worker 同时消费
    var wg sync.WaitGroup
    for i := 0; i < 3; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for n := range in {
                select {
                case out <- n * n:
                case <-ctx.Done():
                    return
                }
            }
        }()
    }

    // 投递输入
    go func() {
        defer close(in)
        for _, n := range inputs {
            select {
            case in <- n:
            case <-ctx.Done():
                return
            }
        }
    }()

    // fan-in：收集结果
    go func() {
        wg.Wait()
        close(out)
    }()

    var results []int
    for r := range out {
        results = append(results, r)
    }
    return results
}
```

### 模式四：pipeline（流水线）

```go
func Stage1(nums []int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for _, n := range nums {
            out <- n
        }
    }()
    return out
}

func Stage2(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range in {
            out <- n * n
        }
    }()
    return out
}

// 使用：数据像流水一样一层层加工
for result := range Stage2(Stage1([]int{1, 2, 3})) {
    fmt.Println(result)
}
```

**每个阶段自己关闭自己的输出 channel**，这是流水线不变式。

### 模式五：semaphore（限制并发数）

```go
func FetchAll(urls []string, limit int) {
    sem := make(chan struct{}, limit)     // 容量就是并发上限
    var wg sync.WaitGroup

    for _, url := range urls {
        wg.Add(1)
        go func(u string) {
            defer wg.Done()
            sem <- struct{}{}             // 占位
            defer func() { <-sem }()      // 释放
            fetch(u)
        }(url)
    }
    wg.Wait()
}
```

### 模式六：errgroup（带取消的并发）

```go
import "golang.org/x/sync/errgroup"

func LoadAll(ctx context.Context, urls []string) error {
    g, ctx := errgroup.WithContext(ctx)     // 任一失败会取消 ctx

    for _, url := range urls {
        url := url
        g.Go(func() error {
            return fetchWithContext(ctx, url)   // 第一个返回的错误被保留
        })
    }
    return g.Wait()
}
```

| 需求 | 用什么 |
| --- | --- |
| 只要结果，任一失败就停 | `errgroup` |
| 限制并发数 | `errgroup.SetLimit(n)` 或 semaphore |
| 收集全部结果 | channel + WaitGroup |
| 只要最快的 | `select` 配合 context |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 没人关闭 channel | 接收方永远阻塞 | 由发送方在结束前关闭 |
| 多个发送方都关 channel | panic | 用 WaitGroup 加一个协程关闭 |
| goroutine 泄漏 | 内存持续增长 | 加 context 或退出条件 |
| 用无缓冲 channel 传大量结果 | 发送方被阻塞 | 用带缓冲或专门收集协程 |
| 忘了检查 `ok` | 读到零值当成有效数据 | `v, ok := <-ch` |
| 用共享变量收集结果 | 数据竞争 | 用 channel 或加锁 |
| 循环变量捕获 | 全部用最后一个值 | Go 1.22 已修复，旧版本加 `v := v` |
| 无限起 goroutine | 资源耗尽 | 用 semaphore 或 worker 池 |

### 手把手练习：并发下载 + 限流 + 错误汇总

```go
import "golang.org/x/sync/errgroup"

func DownloadAll(ctx context.Context, urls []string, limit int) ([]string, error) {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(limit)                       // 限制并发数

    results := make([]string, len(urls))
    for i, url := range urls {
        i, url := i, url
        g.Go(func() error {
            body, err := fetchWithContext(ctx, url)
            if err != nil {
                return fmt.Errorf("下载 %s: %w", url, err)
            }
            results[i] = body               // 每个索引只被一个 goroutine 写
            return nil
        })
    }
    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}
```

写入不同索引不会产生数据竞争，这比加锁更简洁。

### 学完自测

- [ ] 能说出 worker 池与 semaphore 的差别。
- [ ] 知道 fan-in 需要谁来关闭 channel。
- [ ] 能说出 pipeline 每阶段的关闭规则。
- [ ] 知道 `errgroup` 的取消是怎么传播的。
- [ ] 能说出三种导致 goroutine 泄漏的原因。

## 动手练习


> 本课练习重点：围绕「并发模式、errgroup、worker pool」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小程序并用 go test 验证，再补 context、并发上限和错误传播。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Go 并发模式与 errgroup」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「errgroup」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小程序，并用 `go test` 或 `go vet` 验证结果。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「并发模式」和「errgroup」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「Go 并发模式与 errgroup」不是孤立术语，而是在「Go」中解决一类具体问题。
- 关键关系：先分清「并发模式」与「errgroup」的职责，再理解「worker pool」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：要把并发处理限制在固定数量，最简洁的做法是？

- **正确判断**：用 errgroup.SetLimit 或带缓冲 channel 作信号量
- **判断依据**：正确答案是「用 errgroup.SetLimit 或带缓冲 channel 作信号量」，本课在「零基础详解：六种常用并发模式」中说明：并发模式是「被反复验证过的 goroutine + channel 组合拳」。SetLimit 与信号量都能把并发度钉在固定值，避免打爆下游。本课还在「零基础详解：六种常用并发模式」中说明：每个阶段自己关闭自己的输出 channel，这是流水线不变式。本课还在「零基础详解：六种常用并发模式」中说明：能说出三种导致 goroutine 泄漏的原因。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：Pipeline 各阶段为什么通常要 defer close(out)？

- **正确判断**：让下游 range 能正常结束
- **判断依据**：正确答案是「让下游 range 能正常结束」，本课在「零基础详解：六种常用并发模式」中说明：并发模式是「被反复验证过的 goroutine + channel 组合拳」。关闭 channel 后下游 range 才会退出，这是连式 goroutine 不泄漏的关键。本课还在「零基础详解：六种常用并发模式」中说明：能说出 pipeline 每阶段的关闭规则。本课还在「零基础详解：六种常用并发模式」中说明：知道 errgroup 的取消是怎么传播的。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：大量相同请求同时到达导致下游被打爆，可用什么合并？

- **正确判断**：singleflight
- **判断依据**：singleflight 把同一 key 的并发调用合并成一次真实请求，其余共享结果，是缓存击穿的常用解法。针对「大量相同请求同时到达导致下游被打爆，可用什么合并，」，本课在「零基础详解：六种常用并发模式」中说明：能说出 worker 池与 semaphore 的差别。本课还在「零基础详解：六种常用并发模式」中说明：记住这六种，日常大部分并发需求都能直接套用。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：关于并发中的错误处理，正确的是？

- **正确判断**：goroutine 里未处理的 panic 会导致整个进程崩溃
- **判断依据**：正确答案是「goroutine 里未处理的 panic 会导致整个进程崩溃」，本课在「零基础详解：六种常用并发模式」中说明：知道 fan-in 需要谁来关闭 channel。Go 中任何未恢复的 panic 都会终止整个进程，因此每个 goroutine 入口都应有 recover 与日志。本课还在「零基础详解：六种常用并发模式」中说明：能说出三种导致 goroutine 泄漏的原因。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：简单的并发计数，最轻量的方案是？

- **正确判断**：atomic.Int64
- **判断依据**：正确答案是「atomic.Int64」，这道题在问简单的并发计数，最轻量的方案是，判断时要把题干限定的输入、边界与目标逐项对齐。单值自增用原子操作最直接，无锁开销也更小。课程摘要指出Worker Pool，Pipeline，Fan-in/Fan-out 与并发限流，本课要判断的正是简单的并发计数，最轻量的方案是。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 6：补全代码：「Go 并发模式与 errgroup」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `g, ctx := ____.WithContext(ctx)`

- **正确判断**：errgroup
- **判断依据**：正确答案是「errgroup」，本课在「零基础详解：六种常用并发模式」中说明：知道 errgroup 的取消是怎么传播的。本课示例中还能看到 `g, ctx := errgroup.WithContext(ctx)` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：如果填成相近的另一个函数或关键字，程序会在哪一步出错？

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「要把并发处理限制在固定数量，最简洁的做法是？」的判断依据。
- [ ] 不看解析，能说出「Pipeline 各阶段为什么通常要 defer close(out)？」的判断依据。
- [ ] 不看解析，能说出「大量相同请求同时到达导致下游被打爆，可用什么合并？」的判断依据。
- [ ] 不看解析，能说出「关于并发中的错误处理，正确的是？」的判断依据。
- [ ] 不看解析，能说出「简单的并发计数，最轻量的方案是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「Go 并发模式与 errgroup」示例中，下面这行代码缺少哪个关键…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `atomic.Int64` | \| 计数 \| `atomic.Int64` \| 比互斥锁更轻 \| |
| `sync.Mutex` | \| 复合状态更新 \| `sync.Mutex` \| 临界区要尽量短 \| |
| `sync.RWMutex` | \| 读多写少 \| `sync.RWMutex` \| 注意写者饥饿 \| |
| `sync.Once` | \| 一次性初始化 \| `sync.Once` \| 配合包级变量 \| |
| `sync.Pool` | \| 临时对象复用 \| `sync.Pool` \| 不能当缓存用 \| |
| `context` | \| 取消传播 \| `context` \| 逐层传递并检查 \| |
| `golang.org/x/sync/singleflight` | \| 去重合并 \| `golang.org/x/sync/singleflight` \| 缓存击穿场景 \| |
| `SetLimit` | \| 无限制启动 goroutine \| 内存暴涨、下游被打爆 \| 用 `SetLimit` 或信号量限流 \| |
| `defer close(out)` | \| 忘记 `defer close(out)` \| 下游 `range` 永久阻塞 \| 阶段结束时关闭 channel \| |
| `range` | \| 忘记 `defer close(out)` \| 下游 `range` 永久阻塞 \| 阶段结束时关闭 channel \| |
| `recover` | \| goroutine 里 panic 未处理 \| 进程崩溃 \| 在入口 `recover` 并记录 \| |
| `ctx.Done()` | \| 忘记检查 `ctx.Done()` \| 取消后仍继续干活 \| 在循环与阻塞点检查 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：要把并发处理限制在固定数量，最简洁的做法是？

**参考回答**：正确答案是「用 errgroup.SetLimit 或带缓冲 channel 作信号量」，本课在「零基础详解·六种常用并发模式」中说明：并发模式是「被反复验证过的 goroutine + channel 组合拳」。SetLimit 与信号量都能把并发度钉在固定值，避免打爆下游。本课还在「零基础详解·六种常用并发模式」中说明：每个阶段自己关闭自己的输出 channel，这是流水线不变式。本课还在「零基础详解·六种常用并发模式」中说明：能说出三种导致 goroutine 泄漏的原因。

### 追问 2：Pipeline 各阶段为什么通常要 defer close(out)？

**参考回答**：正确答案是「让下游 range 能正常结束」，本课在「零基础详解·六种常用并发模式」中说明：并发模式是「被反复验证过的 goroutine + channel 组合拳」。关闭 channel 后下游 range 才会退出，这是连式 goroutine 不泄漏的关键。本课还在「零基础详解·六种常用并发模式」中说明：能说出 pipeline 每阶段的关闭规则。本课还在「零基础详解·六种常用并发模式」中说明：知道 errgroup 的取消是怎么传播的。

### 追问 3：大量相同请求同时到达导致下游被打爆，可用什么合并？

**参考回答**：singleflight 把同一 key 的并发调用合并成一次真实请求，其余共享结果，是缓存击穿的常用解法。针对「大量相同请求同时到达导致下游被打爆，可用什么合并，」，本课在「零基础详解·六种常用并发模式」中说明：能说出 worker 池与 semaphore 的差别。本课还在「零基础详解·六种常用并发模式」中说明：记住这六种，日常大部分并发需求都能直接套用。

### 追问 4：关于并发中的错误处理，正确的是？

**参考回答**：正确答案是「goroutine 里未处理的 panic 会导致整个进程崩溃」，本课在「零基础详解·六种常用并发模式」中说明：知道 fan-in 需要谁来关闭 channel。Go 中任何未恢复的 panic 都会终止整个进程，因此每个 goroutine 入口都应有 recover 与日志。本课还在「零基础详解·六种常用并发模式」中说明：能说出三种导致 goroutine 泄漏的原因。

### 追问 5：简单的并发计数，最轻量的方案是？

**参考回答**：正确答案是「atomic.Int64」，这道题在问简单的并发计数，最轻量的方案是，判断时要把题干限定的输入、边界与目标逐项对齐。单值自增用原子操作最直接，无锁开销也更小。课程摘要指出Worker Pool，Pipeline，Fan-in/Fan-out 与并发限流，本课要判断的正是简单的并发计数，最轻量的方案是。

## English Overview

**Title:** Concurrency Patterns

**Summary:** Worker pool, pipeline, fan-out and concurrency limits.

**Category:** Go  
**Level:** 高级  
**Key terms:** 并发模式, errgroup, worker pool, pipeline, singleflight

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Go 1.24+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：并发模式、errgroup、worker pool、pipeline、singleflight
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Go 官方文档](https://go.dev/doc/) | 语言、并发与工具链 |
| [Go 标准库](https://pkg.go.dev/std) | 标准库 API |

> 本课主题：Worker Pool、Pipeline、Fan-in/Fan-out 与并发限流。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
