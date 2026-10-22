## 零基础详解：goroutine、channel 与「通过通信共享内存」

### 一句话说清它是什么

Go 的并发口号是「**不要通过共享内存来通信，而要通过通信来共享内存**」。
具体做法就是：用 goroutine 起任务，用 channel 在任务之间传数据，而不是到处加锁改同一个变量。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| goroutine | 临时工 | 几 KB 栈，开几万个也不吓人 |
| channel | 传送带 | 一个送、一个收，天然同步 |
| 无缓冲 channel | 手递手 | 双方必须同时到位 |
| 带缓冲 channel | 周转筐 | 筐没满就能先放 |
| `select` | 多路开关 | 谁先就绪就走哪条 |
| `sync.Mutex` | 一把锁 | 需要保护一小段共享状态时才用 |
| `context` | 停工通知 | 告诉所有相关任务「别干了」 |

### 三个工具的取舍

| 需求 | 推荐 | 原因 |
| --- | --- | --- |
| 传递数据、串起流水线 | channel | 数据流向清晰 |
| 保护一个计数器或缓存 | `sync.Mutex` / `atomic` | 比开 channel 更直接 |
| 等一组任务结束 | `sync.WaitGroup` | 计数归零即完成 |
| 取消、超时、传请求级数据 | `context` | 标准做法，能层层传递 |
| 限制并发数量 | 带缓冲 channel 当信号量 | 简洁可控 |

### 一段完整示例：worker 池

```go
package main

import (
    "fmt"
    "sync"
)

func worker(id int, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs {                 // channel 关闭后循环自动结束
        results <- job * job
    }
}

func main() {
    jobs := make(chan int, 5)
    results := make(chan int, 5)
    var wg sync.WaitGroup

    for i := 1; i <= 3; i++ {
        wg.Add(1)                           // 必须在 go 之前 Add
        go worker(i, jobs, results, &wg)
    }

    for i := 1; i <= 5; i++ {
        jobs <- i
    }
    close(jobs)                             // 由发送方关闭

    wg.Wait()
    close(results)

    for r := range results {
        fmt.Println(r)
    }
}
```

### channel 的四条铁律

| 操作 | 无缓冲 | 带缓冲（未满） | 已关闭 |
| --- | --- | --- | --- |
| 发送 | 阻塞到有人接收 | 不阻塞 | **panic** |
| 接收 | 阻塞到有人发送 | 有数据就取 | 返回零值，ok 为 false |
| 关闭 | 可以 | 可以 | 重复关闭会 panic |

结论：**只由发送方关闭 channel，并且不要向已关闭的 channel 发送数据。**

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 向已关闭的 channel 发送 | panic | 只让发送方关，先关闭再停止发送 |
| 重复关闭 | panic | 用 `sync.Once` 或明确单一关闭方 |
| 没人接收就发送 | 全部 goroutine 阻塞，报 deadlock | 保证有接收方或改成带缓冲 |
| 忘了 `wg.Add` | `Wait` 立刻返回 | 起 goroutine 前先 Add |
| `wg.Add` 写在 goroutine 里 | 计数可能来不及加 | 必须在 go 之前调用 |
| goroutine 泄漏 | 内存持续增长 | 用 context 或关闭 channel 让它退出 |
| 用共享 map 不加锁 | 并发写导致崩溃 | 加 `Mutex` 或用 channel 串行化 |
| 循环变量被捕获 | 所有 goroutine 用同一个值 | Go 1.22 已修复，旧版本要 `v := v` |

### 用 context 控制取消

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()                       // 一定要调用，释放资源

select {
case <-ctx.Done():
    fmt.Println("超时或被取消：", ctx.Err())
case result := <-ch:
    fmt.Println("拿到结果：", result)
}
```

### 学完自测

- [ ] 能说出「通过通信共享内存」是什么意思。
- [ ] 知道无缓冲与带缓冲 channel 的区别。
- [ ] 能说出关闭 channel 的两条规则。
- [ ] 知道 `WaitGroup.Add` 为什么必须写在 `go` 之前。
- [ ] 能用 `select` 加 `context` 写出带超时的等待。
