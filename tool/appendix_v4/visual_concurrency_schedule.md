## 补充：线程池参数、泄漏排查与选型

### 线程池大小怎么算

```text
CPU 密集型：线程数 ≈ 核心数 + 1
  · 多出的 1 个用于在偶发缺页时顶上

IO 密集型：线程数 ≈ 核心数 × (1 + 等待时间 / 计算时间)
  · 例：4 核，任务 90% 时间在等网络 → 4 × (1 + 9) = 40

工程做法：按公式给出初值，再用压测确定最终值
```

| 参数 | 设太小 | 设太大 |
| --- | --- | --- |
| 核心线程数 | 请求排队 | 上下文切换开销 |
| 队列容量 | 直接拒绝请求 | 内存堆积、延迟升高 |
| 空闲回收时间 | 频繁创建销毁 | 资源长期占用 |
| 超时时间 | 请求快速失败 | 线程被慢请求占满 |

```java
// 线程池：不要用无界队列，否则拒绝策略永远不会触发
ExecutorService pool = new ThreadPoolExecutor(
    4, 16,                       // 核心与最大线程数
    60, TimeUnit.SECONDS,
    new ArrayBlockingQueue<>(200),        // 有界队列
    new ThreadPoolExecutor.CallerRunsPolicy()  // 满了就让调用方自己执行
);
```

### goroutine 泄漏的四种典型写法

```go
// ① 向无人接收的 channel 发送 → 永久阻塞
go func() { ch <- compute() }()   // 若没人读 ch，这个 goroutine 永远活着

// 修复：带缓冲，或监听 ctx.Done()
go func() {
    select {
    case ch <- compute():
    case <-ctx.Done():
    }
}()

// ② 等待永远不会关闭的 channel → 永久阻塞
for v := range ch { }             // 谁负责 close(ch)？

// ③ 忘了取消 context
ctx, cancel := context.WithCancel(parent)
defer cancel()                    // 缺这一行，子 goroutine 永不退出

// ④ 锁未释放导致后续 goroutine 排队
mu.Lock()
// 中间 panic 时不写 defer Unlock 就会死锁
defer mu.Unlock()
```

```bash
# 用 pprof 一眼看出泄漏：goroutine 数是否随时间单调增长
go tool pprof http://127.0.0.1:6060/debug/pprof/goroutine
(pprof) top        # 看哪个函数堆了最多 goroutine
```

### 三种并发模型的切换代价对照

| 模型 | 切换进入内核 | 单任务内存 | 数量级 | 适用 |
| --- | --- | --- | --- | --- |
| 系统线程 | 是 | 1 MB 栈（典型） | 千级 | CPU 密集、需真并行 |
| 协程 / goroutine | 否 | 几 KB 起 | 十万级 | 高并发 IO |
| 事件循环回调 | 否 | 极小 | 视队列而定 | IO 密集、前端与 Node |

```text
一句话选型
  · 计算密集 → 线程池 / 多进程
  · 大量网络等待 → 协程或事件循环
  · 需要强隔离（互不影响）→ 多进程
```

### 并发正确性的三种验证手段

| 手段 | 能发现 | 局限 |
| --- | --- | --- |
| 数据竞争检测（Go `-race`、TSan） | 无同步的内存访问 | 只对执行到的路径生效 |
| 压力测试（高并发重复执行） | 偶发死锁、丢失更新 | 需要足够轮次 |
| 静态检查（Rust 编译期、clippy） | 借用与所有权问题 | 语言特性决定覆盖范围 |

```bash
# Go：把竞态检测放进 CI，而不是只跑一次
go test -race -count=5 ./...

# 压测：并发 200、持续 60 秒，观察是否出现死锁或计数偏差
hey -c 200 -z 60s http://localhost:8080/api/orders
```

### 自查清单

- [ ] 线程池使用有界队列，并有明确的拒绝策略
- [ ] 每个 goroutine / 协程都有退出条件
- [ ] `context` 与 `cancel()` 成对出现
- [ ] CI 中开启了竞态检测
- [ ] 压测覆盖高并发场景，而不只是功能验证

