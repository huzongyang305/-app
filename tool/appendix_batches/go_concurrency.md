## goroutine 与 channel 速查

| 目的 | 写法 | 说明 |
| --- | --- | --- |
| 启动协程 | `go worker()` | 调度开销远小于线程 |
| 等待全部完成 | `var wg sync.WaitGroup` | `Add` 要在 `go` 之前调用 |
| 无缓冲 channel | `make(chan int)` | 收发同步握手 |
| 带缓冲 channel | `make(chan int, 10)` | 缓冲满则发送阻塞 |
| 只发 / 只收类型 | `chan<- int` / `<-chan int` | 用类型表达意图，减少误用 |
| 关闭 channel | `close(ch)` | 由发送方关闭，接收方用 `v, ok := <-ch` 判断 |
| 遍历 channel | `for v := range ch` | channel 关闭且无数据时自动结束 |
| 选择分支 | `select { case v := <-ch: ... }` | 多路复用，可加 `default` 做非阻塞 |
| 超时控制 | `select` + `time.After` | 避免永久等待 |
| 取消传播 | `context.WithCancel` | 逐层传递，配合 `<-ctx.Done()` |
| 限流 | `make(chan struct{}, n)` 或 `errgroup.SetLimit` | 控制并发规模 |
| 错误汇总 | `errgroup.Group` | 任一返回错误即取消其余任务 |

```go
func worker(ctx context.Context, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()
	for {
		select {
		case <-ctx.Done():
			return                       // 收到取消信号立即退出
		case job, ok := <-jobs:
			if !ok {
				return                   // channel 已关闭且取完
			}
			select {
			case results <- job * 2:
			case <-ctx.Done():
				return
			}
		}
	}
}
```

## 并发安全速查

| 场景 | 推荐做法 |
| --- | --- |
| 计数器 | `atomic.Int64` 或 `sync.Mutex` |
| 只读共享数据 | 启动前初始化好，之后不再写 |
| 读写比例高 | `sync.RWMutex` |
| 对象复用 | `sync.Pool` |
| 只执行一次的初始化 | `sync.Once` |
| 跨线程传递数据 | channel（CSP 风格） |
| 共享状态较多 | 加锁，但优先考虑改用 channel 传递所有权 |
| 检测数据竞争 | `go test -race` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `wg.Add(1)` 写在 `go func()` 内部 | `Wait` 提前返回 | `Add` 必须在启动协程前调用 |
| 向已关闭的 channel 发送 | panic | 只让发送方关闭，且关闭后不再发送 |
| 读已关闭的 channel | 立刻返回零值 | 用 `v, ok := <-ch` 区分「零值」与「已关闭」 |
| goroutine 内 panic 未捕获 | 整个进程崩溃 | 在 `recover` 中兜住并记录日志 |
| 只发不收（或只收不发） | 死锁：`all goroutines are asleep` | 确保有对应接收方，或使用缓冲与超时 |
| 在循环里用 `for _, v := range s { go func(){ use(v) }() }` | 旧版 Go 捕获同一变量导致数据错 | 把 `v` 作为参数传入闭包 |
| 忘记 `defer cancel()` | context 泄漏 | 创建后立即 `defer cancel()` |
| 用 `time.Sleep` 等待完成 | 不稳定、慢 | 用 `WaitGroup` 或 channel 同步 |
| 共享 map 并发读写 | panic：`concurrent map writes` | 加锁或用 `sync.Map` |
| 无限制启动 goroutine | 内存暴涨、调度开销大 | 用带缓冲的 channel 或 `errgroup.SetLimit` 限流 |
| 直接 `fmt.Println` 调试并发 | 输出交织、无法定位 | 用结构化日志并带请求 ID |

## 自测清单

- [ ] 会用 `WaitGroup`、`channel`、`context` 控制协程生命周期。
- [ ] 知道「谁发送谁关闭」的惯例，并用 `v, ok` 判断关闭。
- [ ] 共享数据一律加锁或用原子操作。
- [ ] 关键代码跑 `go test -race` 且无告警。
- [ ] 所有并发任务都能被取消并设了超时。
