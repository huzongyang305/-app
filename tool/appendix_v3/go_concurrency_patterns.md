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
