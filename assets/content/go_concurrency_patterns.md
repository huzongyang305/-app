# Go 并发模式与 errgroup

![Go Worker Pool 与 Pipeline 模式](images/diagram_go_patterns.webp)

![Go 并发模式与 errgroup](images/remaining_go_concurrency_patterns.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：35 分钟

## 学习目标

- 能用自己的话解释Go 并发模式与 errgroup解决了什么问题，而不是只背术语。
- 能说清 「并发模式」、「errgroup」、「worker pool」、「pipeline」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Go」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Worker Pool、Pipeline、Fan-in/Fan-out 与并发限流。

## 前置知识

- 先完成上一课《gRPC 与 Protobuf 实践》；如果已经掌握，可以直接用本课练习自测。
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

## 常见错误与排查

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

## 复习与自测

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

1. Go 并发模式与 errgroup解决了什么问题？
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

- 核心问题：Go 并发模式与 errgroup不是孤立术语，而是在「Go」中解决一类具体问题。
- 关键关系：先分清「并发模式」与「errgroup」的职责，再理解「worker pool」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。

## 可运行练习

本节围绕Go 并发模式与 errgroup安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Go 并发模式与 errgroup」的结构，画完再对照骨架：

- 主干：模式速查 → 并发安全原语速查 → 零基础详解：六种常用并发模式 → 实践任务
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明并发模式与errgroup的关系？

### 任务 2：做一次对比实验

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。

## 故障现场

### 现场 1：本课的 并发模式 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 并发模式 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 并发模式 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“并发模式 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 并发模式 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 errgroup 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 errgroup 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 errgroup 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“errgroup 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 errgroup 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，并发模式 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- 升级前用 go vet、go test -race 与静态检查覆盖并发生命周期
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「要把并发处理限制在固定数量，最简洁的做法是？」的判断依据。
- [ ] 不看解析，能说出「Pipeline 各阶段为什么通常要 defer close(out)？」的判断依据。
- [ ] 不看解析，能说出「大量相同请求同时到达导致下游被打爆，可用什么合并？」的判断依据。
- [ ] 不看解析，能说出「关于并发中的错误处理，正确的是？」的判断依据。
- [ ] 不看解析，能说出「简单的并发计数，最轻量的方案是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `atomic.Int64` | \| 计数 \| `atomic.Int64` \| 比互斥锁更轻 \| |
| `sync.Mutex` | \| 复合状态更新 \| `sync.Mutex` \| 临界区要尽量短 \| |
| `sync.RWMutex` | \| 读多写少 \| `sync.RWMutex` \| 注意写者饥饿 \| |
| `sync.Once` | \| 一次性初始化 \| `sync.Once` \| 配合包级变量 \| |
| `sync.Pool` | \| 临时对象复用 \| `sync.Pool` \| 不能当缓存用 \| |
| `context` | \| 取消传播 \| `context` \| 逐层传递并检查 \| |

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
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：并发模式、errgroup、worker pool、pipeline、singleflight
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Go 并发](https://go.dev/talks/2012/concurrency.slide) | goroutine 与 channel |
| [Effective Go](https://go.dev/doc/effective_go) | 惯用写法与接口设计 |
| [Go 测试](https://go.dev/doc/tutorial/add-a-test) | 测试、基准与覆盖率 |

> 「Go 并发模式与 errgroup」的链接用于离线阅读后的延伸核对；App 不会自动联网。
