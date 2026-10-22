## 性能工具速查

| 目的 | 命令 / 写法 |
| --- | --- |
| 逃逸分析 | `go build -gcflags="-m -l" ./...` |
| 基准测试 | `go test -bench=. -benchmem ./...` |
| 与旧结果对比 | `go test -bench=. -count=10 > new.txt` + `benchstat old.txt new.txt` |
| CPU 剖析 | 测试中加 `-cpuprofile=cpu.out`，再 `go tool pprof -http=:8080 cpu.out` |
| 内存剖析 | `-memprofile=mem.out` |
| 阻塞剖析 | `runtime.SetBlockProfileRate` + `-blockprofile` |
| 互斥锁剖析 | `runtime.SetMutexProfileFraction` |
| 追踪 | `go test -trace=trace.out` + `go tool trace trace.out` |
| 线上剖析 | 引入 `net/http/pprof`，访问 `/debug/pprof/` |

## 常见优化手段速查

| 手段 | 收益 | 注意点 |
| --- | --- | --- |
| 预分配切片容量 | 减少扩容与拷贝 | `make([]T, 0, n)` |
| 用 `strings.Builder` | 减少字符串拼接分配 | 提前 `Grow` |
| 避免不必要的接口装箱 | 减少分配与间接调用 | 热点路径避免 `any` |
| 用值接收或指针接收统一 | 减少拷贝 | 小结构体传值，大结构体传指针 |
| 复用对象（`sync.Pool`） | 降低 GC 压力 | 池中对象可能被回收 |
| 批量处理 | 减少系统调用与锁竞争 | 注意批次大小的延迟权衡 |
| 并发处理 | 利用多核 | 用 `errgroup` 限制并发 |
| 设置 `GOMEMLIMIT` | 容器中避免 OOM | 结合 `GOGC` 调整 |
| 减少锁粒度 | 提升并发 | 注意一致性 |
| 用 `atomic` 替代互斥锁 | 计数场景更快 | 只适用于简单操作 |

```go
// 基准测试：同时报告内存分配
func BenchmarkParse(b *testing.B) {
	input := []byte(`{"id":1,"name":"小明"}`)
	b.ReportAllocs()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		var user User
		if err := json.Unmarshal(input, &user); err != nil {
			b.Fatal(err)
		}
	}
}

// 并发处理 + 限制并发度 + 错误传播
func processAll(ctx context.Context, items []Item) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(8)                 // 最多 8 个并发

	for _, item := range items {
		item := item
		g.Go(func() error {
			return process(ctx, item)
		})
	}
	return g.Wait()
}
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 未做基准测试就优化 | 优化错地方，复杂度上升 | 先剖析定位热点 |
| 基准测试不计时重置 | 数据包含准备时间 | `b.ResetTimer()` |
| 单次运行就下结论 | 结果噪声大 | 多轮运行 + benchstat 对比 |
| 盲目使用 `sync.Pool` | 收益不明显甚至更慢 | 只对高分配热点使用 |
| 切片不预分配容量 | 频繁扩容拷贝 | `make([]T, 0, n)` |
| 热点路径大量接口转换 | 分配与间接调用 | 用具体类型或泛型 |
| goroutine 无上限 | 内存暴涨、调度开销大 | 用 `errgroup.SetLimit` 或信号量 |
| 忘记关闭响应体 | 连接泄漏 | `defer resp.Body.Close()` |
| 容器不设内存限制与 `GOMEMLIMIT` | 被 OOM Killer 杀掉 | 两者配合设置 |
| 生产开启 pprof 无鉴权 | 信息泄露 | 只在内网或加鉴权暴露 |

## 自测清单

- [ ] 优化前先用基准测试或 pprof 定位热点。
- [ ] 基准结果用 benchstat 对比，避免噪声误判。
- [ ] 热点路径避免不必要的分配与装箱。
- [ ] 并发任务限流并传播 context。
- [ ] 容器内存与 `GOMEMLIMIT` 配置配套。
