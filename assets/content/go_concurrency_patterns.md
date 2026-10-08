# Go 并发模式与 errgroup

![Go Worker Pool 与 Pipeline 模式](images/diagram_go_patterns.webp)

![Go 并发模式与 errgroup](images/remaining_go_concurrency_patterns.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：45 分钟

## 本节知识框架

**课程定位**：所属分类为「Go」，课程主题为「Go 并发模式与 errgroup」，学习阶段为「高级」，建议用时 45 分钟。

**本课要解决的主问题**：Worker Pool、Pipeline、Fan-in/Fan-out 与并发限流。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Go 并发模式与 errgroup」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Go 并发模式与 errgroup」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「并发模式」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《gRPC 与 Protobuf 实践》

**学习位置**：本课位于《Go 泛型与标准库实战》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《实战：Go REST API 服务》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Go 并发模式与 errgroup解决了什么问题，而不是只背术语。
- 能说清 「并发模式」、「errgroup」、「worker pool」、「pipeline」 之间的关系，并分别举出一个例子。
- 能把 并发模式 放回「Go 并发模式与 errgroup」的知识体系，说明它和 errgroup 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Worker Pool、Pipeline、Fan-in/Fan-out 与并发限流。

**教材衔接：前置知识**

- 先完成上一课《gRPC 与 Protobuf 实践》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：并发模式、errgroup、worker pool。
- 看不懂就直接缩小例子：只保留 并发模式 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

- 核心问题：Go 并发模式与 errgroup不是孤立术语，而是在「Go」中解决一类具体问题。
- 关键关系：先分清「并发模式」与「errgroup」的职责，再理解「worker pool」的适用边界。
- 判断标准：能说清 WithContext 在正常与异常输入下的差别。
- 下一步：先复述 errgroup 的边界，再开始本课测验。

## 核心概念定义

> 阅读约定：本课先给「Go 并发模式与 errgroup」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| 并发模式 | 并发模式是「被反复验证过的 goroutine + channel 组合拳」。 | 仅在「Go 并发模式与 errgroup」明确给出的输入、版本与资源条件下成立。 |
| worker 池 | 固定数量的 goroutine 从 channel 取任务，用有界并发保护下游与本地资源。 | 仅在「Go 并发模式与 errgroup」明确给出的输入、版本与资源条件下成立。 |
| fan-in 与 fan-out | 把任务分发给多个 goroutine，再把结果汇聚回一个 channel 的经典并发结构。 | 仅在「Go 并发模式与 errgroup」明确给出的输入、版本与资源条件下成立。 |
| 限流 | 用带缓冲 channel 或 rate.Limiter 控制单位时间放行的任务数，避免把下游打垮。 | 仅在「Go 并发模式与 errgroup」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Go 并发模式与 errgroup」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「并发模式」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「worker 池」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「fan-in 与 fan-out」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Go 并发模式与 errgroup」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | 并发模式 | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | worker 池 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | fan-in 与 fan-out | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Go 并发模式与 errgroup」自己的示例验证。「Go 并发模式与 errgroup」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：模式速查**

| 模式 | 结构 | 适用 |
| --- | --- | --- |
| Worker Pool | 固定 worker 消费任务队列 | 控制并发度、批量处理 |
| Pipeline | 多阶段 channel 串联 | 数据流式处理 |
| Fan-out / Fan-in | 多协程处理再汇总 | 提高吞吐 |
| Semaphore | 带缓冲 channel 限制并发 | 保护下游 |
| Timeout / Cancellation | context 传播取消 | 防止无限等待 |
| Singleflight | 合并重复请求 | 缓存击穿、惊群 |

**教材衔接：版本与时效**

- 升级前确认 并发模式 的兼容范围，把不可回退的改动单独拆成一次提交。
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 并发模式 相关的差异单独记成一条结论。
- 升级后重点回归 并发模式 的默认值、警告信息与错误格式。
- 升级后把 WithContext 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 并发模式、errgroup | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Go 并发模式与 errgroup」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Go 并发模式与 errgroup」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:go`，用于动手验证《Go 并发模式与 errgroup》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Go 并发模式与 errgroup》原文中的最小示例。先预测《Go 并发模式与 errgroup》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

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

**教材衔接：Worker Pool + errgroup**

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

## 时间/空间复杂度或性能分析

**复杂度证据**：「Go 并发模式与 errgroup」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Go 并发模式与 errgroup」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Go 并发模式与 errgroup」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：并发安全原语速查**

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

**教材衔接：零基础详解：六种常用并发模式**

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

## 常见误区与易错点

> 复核《Go 并发模式与 errgroup》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Go 并发模式与 errgroup」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

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

**教材衔接：故障现场**

### 现场 1：无限制启动 goroutine

**症状**：在《Go 并发模式与 errgroup》的复现场景中，内存暴涨、下游被打爆。

**根因**：触发点是把“无限制启动 goroutine”当成安全做法。它没有满足《Go 并发模式与 errgroup》要求的前提，因此先表现为“内存暴涨、下游被打爆”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Go 并发模式与 errgroup》的问题，用 SetLimit 或信号量限流。

**验证**：在《Go 并发模式与 errgroup》中按“用 SetLimit 或信号量限流”调整后，从“无限制启动 goroutine”的触发条件重放同一条路径，确认“内存暴涨、下游被打爆”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：忘记 defer close(out)

**症状**：在《Go 并发模式与 errgroup》的复现场景中，下游 range 永久阻塞。

**根因**：触发点是把“忘记 defer close(out)”当成安全做法。它没有满足《Go 并发模式与 errgroup》要求的前提，因此先表现为“下游 range 永久阻塞”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Go 并发模式与 errgroup》的问题，阶段结束时关闭 channel。

**验证**：保留《Go 并发模式与 errgroup》里触发“下游 range 永久阻塞”的输入、版本和日志，按“阶段结束时关闭 channel”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：在循环里直接闭包捕获循环变量

**症状**：在《Go 并发模式与 errgroup》的复现场景中，处理到同一个元素。

**根因**：触发点是把“在循环里直接闭包捕获循环变量”当成安全做法。它没有满足《Go 并发模式与 errgroup》要求的前提，因此先表现为“处理到同一个元素”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Go 并发模式与 errgroup》的问题，Go 1.22 前需复制或传参。

**验证**：保留《Go 并发模式与 errgroup》里触发“处理到同一个元素”的输入、版本和日志，按“Go 1.22 前需复制或传参”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《gRPC 与 Protobuf 实践》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Go 测试进阶：基准、模糊与集成》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Go 泛型与标准库实战》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《实战：Go REST API 服务》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Go 并发模式与 errgroup」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Go 并发模式与 errgroup》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

这段 Go 代码是「Go 并发模式与 errgroup」的示例片段，下面哪一项描述与它一致？

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

A. 这段代码包含异常处理分支，失败时会走专门的补救路径。
B. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码包含条件分支，不同输入会走不同的执行路径。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「Go 并发模式与 errgroup」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Go 并发模式与 errgroup」的正文示例，围绕并发模式、errgroup、worker pool展开；把输入或边界换成空值、极值或失败情况后，结论要以「Go 并发模式与 errgroup」的实际运行结果为准。

### 自测 2

Pipeline 各阶段为什么通常要 defer close(out)？

A. 为了提升吞吐
B. 为了让 panic 不传播
C. 为了节省内存
D. 让下游 range 能正常结束

**参考答案**：让下游 range 能正常结束

**解析**：在「Go 并发模式与 errgroup」里，让下游 range 能正常结束。关闭 channel 后下游 range 才会退出，这是连式 goroutine 不泄漏的关键。把“让下游 range 能正常结束”代回「Go 并发模式与 errgroup」里“Pipeline 各阶段为什么通常要 defer close”的例子核对，条件一旦改变，结论就要用并发模式、errgroup、worker pool重新推导。

### 自测 3

围绕“Go 并发模式与 errgroup”中的 并发模式、errgroup、worker pool，下列哪两项是本课强调的实践判断？

A. 学习 并发模式 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 并发模式 的常规示例通过，就可以跳过边界与异常路径
C. 验证 errgroup 时要固定版本并覆盖边界输入，结论才可复现
D. 把 errgroup 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 并发模式 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 errgroup 时要固定版本并覆盖边界输入，结论才可复现

**解析**：结论应落在学习 并发模式 时要同时说明输入、输出和失败路径。本课把Go 并发模式与 errgroup拆成概念、示例与故障现场三部分，因此判断 并发模式 时必须同时交代输入、输出和失败路径，这使“学习 并发模式 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Go 并发模式与 errgroup里，判断 errgroup 时要固定版本与边界输入，所以“验证 errgroup 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 会用 errgroup 限制并发并传播取消。
- [ ] 能写出三阶段的 pipeline 且正确关闭 channel。
- [ ] 知道何时用原子操作、锁或 channel。
- [ ] goroutine 内 panic 有 recover 与日志。
- [ ] 重复请求用 singleflight 合并。

**教材衔接：动手练习**

> 本课练习重点：围绕「并发模式、errgroup、worker pool」完成复述、实验和交付，每个结果都要能被别人检查。

用 WithContext 构造最小可运行示例，并把输出与「模式速查」的结论对照。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Go 并发模式与 errgroup解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「errgroup」是什么关系？

验收标准：回答里必须出现 并发模式，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 WithContext 当作原例，改动一次errgroup的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

用 WithContext 构造最小可运行示例，并把输出与「模式速查」的结论对照。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「并发模式」和「errgroup」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Go 并发模式与 errgroup安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Go 并发模式与 errgroup」的结构，画完再对照骨架：

- 主干：模式速查 → 并发安全原语速查 → 零基础详解：六种常用并发模式 → 实践任务
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明并发模式与errgroup的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案的差异必须落在「Go 并发模式与 errgroup」的实际约束上；写清当并发模式越过哪条边界时应该换方案。

### 任务 3：迁移到自己的场景

**验收标准**：至少给出一个命令或数据样例，让读者能独立复现 errgroup 的结论。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「要把并发处理限制在固定数量，最简洁的做法是？」的判断依据。
- [ ] 不看解析，能说出「Pipeline 各阶段为什么通常要 defer close(out)？」的判断依据。
- [ ] 不看解析，能说出「大量相同请求同时到达导致下游被打爆，可用什么合并？」的判断依据。
- [ ] 不看解析，能说出「关于并发中的错误处理，正确的是？」的判断依据。
- [ ] 不看解析，能说出「简单的并发计数，最轻量的方案是？」的判断依据。
- [ ] 至少运行一次 WithContext 的示例，记录输入、输出和 并发模式 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `并发模式` | 并发模式是「被反复验证过的 goroutine + channel 组合拳」。 |
| `worker 池` | 固定数量的 goroutine 从 channel 取任务，用有界并发保护下游与本地资源。 |
| `fan-in 与 fan-out` | 把任务分发给多个 goroutine，再把结果汇聚回一个 channel 的经典并发结构。 |
| `限流` | 用带缓冲 channel 或 rate.Limiter 控制单位时间放行的任务数，避免把下游打垮。 |

## 考点精讲

### 考点 1：代码补全·并发模式

- **题目**：这段 Go 代码是「Go 并发模式与 errgroup」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「Go 并发模式与 errgroup」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Go 并发模式与 errgroup」的正文示例，围绕并发模式、errgroup、worker pool展开；把输入或边界换成空值、极值或失败情况后，结论要以「Go 并发模式与 errgroup」的实际运行结果为准。

### 考点 2：概念判断·并发模式

- **题目**：Pipeline 各阶段为什么通常要 defer close(out)？
- **判断依据**：在「Go 并发模式与 errgroup」里，让下游 range 能正常结束。关闭 channel 后下游 range 才会退出，这是连式 goroutine 不泄漏的关键。把“让下游 range 能正常结束”代回「Go 并发模式与 errgroup」里“Pipeline 各阶段为什么通常要 defer close”的例子核对，条件一旦改变，结论就要用并发模式、errgroup、worker pool重新推导。

### 考点 3：概念判断·并发模式

- **题目**：大量相同请求同时到达导致下游被打爆，可用什么合并？
- **判断依据**：在「Go 并发模式与 errgroup」里，singleflight 把同一 key 的并发调用合并成一次真实请求，其余共享结果，是缓存击穿的常用解法。把“singleflight”代回「Go 并发模式与 errgroup」里“大量相同请求同时到达导致下游被打爆”的例子核对，条件一旦改变，结论就要用并发模式、errgroup、worker pool重新推导。

### 考点 4：多选辨析·并发模式

- **题目**：围绕“Go 并发模式与 errgroup”中的 并发模式、errgroup、worker pool，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在学习 并发模式 时要同时说明输入、输出和失败路径。本课把Go 并发模式与 errgroup拆成概念、示例与故障现场三部分，因此判断 并发模式 时必须同时交代输入、输出和失败路径，这使“学习 并发模式 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Go 并发模式与 errgroup里，判断 errgroup 时要固定版本与边界输入，所以“验证 errgroup 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·并发模式

- **题目**：简单的并发计数，最轻量的方案是？
- **判断依据**：在「Go 并发模式与 errgroup」里，atomic.Int64。单值自增用原子操作最直接，无锁开销也更小。“简单的并发计数”与「Go 并发模式与 errgroup」的术语表相呼应，只有符合并发模式、errgroup、worker pool约束的“atomic.Int64”才是正文支持的结论。

### 考点 6：填空·并发模式

- **题目**：补全代码：「Go 并发模式与 errgroup」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `g, ctx := ____.WithContext(ctx)`
- **判断依据**：在「Go 并发模式与 errgroup」里，errgroup。在「Go 并发模式与 errgroup」里判断这道题，要把并发模式、errgroup、worker pool的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“并发模式与”与「Go 并发模式与 errgroup」的术语表相呼应，只有符合并发模式、errgroup、worker pool约束的“errgroup”才是正文支持的结论。

## English Overview

**Title:** Concurrency Patterns

**Summary:** Worker pool, pipeline, fan-out and concurrency limits.

**Category:** Go
**Level:** 高级
**Key terms:** 并发模式, errgroup, worker pool, pipeline, singleflight

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Go 1.24+
；本课聚焦 并发模式。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：并发模式、errgroup、worker pool、pipeline、singleflight
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Go 并发](https://go.dev/talks/2012/concurrency.slide) | goroutine 与 channel |
| [Effective Go](https://go.dev/doc/effective_go) | 惯用写法与接口设计 |
| [Go 测试](https://go.dev/doc/tutorial/add-a-test) | 测试、基准与覆盖率 |

> 「Go 并发模式与 errgroup」的链接用于离线阅读后的延伸核对；App 不会自动联网。
