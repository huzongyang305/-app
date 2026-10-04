## 零基础详解：pprof 性能剖析实战

### 一句话说清它是什么

pprof 是 Go 自带的性能剖析工具，能回答四个问题：
**CPU 花在哪、内存被谁占、goroutine 卡在哪、谁在等锁**。

### 用生活比喻理解

| Profile | 比喻 | 回答什么 |
| --- | --- | --- |
| CPU | 计时赛录像 | 时间花在哪些函数 |
| heap | 仓库盘点 | 谁占内存、谁在分配 |
| goroutine | 人员点名 | 有多少、卡在哪一行 |
| block | 堵车记录 | 谁在等锁或 channel |
| mutex | 锁竞争报告 | 哪把锁最抢手 |

### 三种采集方式

```go
// 方式一：HTTP 端点（最方便）
import (
    "net/http"
    _ "net/http/pprof"
)

go func() {
    // 只监听本机或内网，切勿暴露公网
    _ = http.ListenAndServe("127.0.0.1:6060", nil)
}()
```

```go
// 方式二：代码里手动采集（适合离线任务）
f, _ := os.Create("cpu.prof")
_ = pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()
doHeavyWork()

// 方式三：内存快照
f2, _ := os.Create("heap.prof")
defer f2.Close()
_ = pprof.WriteHeapProfile(f2)
```

### 分析命令

```bash
# 采集 30 秒 CPU 数据
go tool pprof http://127.0.0.1:6060/debug/pprof/profile?seconds=30

# 内存
go tool pprof http://127.0.0.1:6060/debug/pprof/heap

# goroutine（查泄漏最有用）
go tool pprof http://127.0.0.1:6060/debug/pprof/goroutine

# 进入交互界面后的常用命令
(pprof) top          # 按占用排序
(pprof) top -cum     # 按累计时间排序（找调用链上游）
(pprof) list 函数名  # 逐行显示耗时
(pprof) web          # 生成调用图（需要 graphviz）
```

### 看数据的两个要点

| 指标 | 含义 | 怎么用 |
| --- | --- | --- |
| `flat` | 函数自身消耗 | 找真正的热点 |
| `cum` | 含被调函数的累计 | 找调用链入口 |
| `alloc_objects` | 分配次数 | 找频繁小对象 |
| `inuse_space` | 当前占用 | 找内存大户 |

**技巧**：内存问题先看 `alloc_objects`（谁在频繁分配），再看 `inuse_space`（谁一直占着）。

### 四种常见的 pprof 结论与对策

| 现象 | 可能原因 | 对策 |
| --- | --- | --- |
| CPU 热点在 `runtime.mallocgc` | 分配太多 | 预分配、复用对象、`sync.Pool` |
| 热点在 `encoding/json` | 序列化频繁 | 换更快的库或减少字段 |
| goroutine 数持续增长 | 泄漏 | 检查退出条件与 context |
| block 里锁等待长 | 临界区太大 | 缩小加锁范围 |

### goroutine 泄漏排查四步

```text
1. 看曲线：goroutine 数是否随时间单调增长
2. 抓快照：go tool pprof .../goroutine
3. 看堆栈：top 与 list，找出共同的阻塞点
4. 回到代码：确认谁在等 channel、锁或网络，补上退出条件
```

常见泄漏原因：

| 原因 | 表现 |
| --- | --- |
| 向无人接收的 channel 发送 | 卡在 `chan send` |
| 等待永远不会关闭的 channel | 卡在 `chan receive` |
| 忘了取消 context | 卡在 `select` 或网络读 |
| 锁未释放 | 卡在 `sync.(*Mutex).Lock` |
| 无限起 goroutine | 数量持续增长 |

### 基准测试配合 pprof

```bash
# 跑基准并同时采集 CPU 与内存
go test -bench . -cpuprofile cpu.out -memprofile mem.out ./...

go tool pprof -top cpu.out
go tool pprof -alloc_objects -top mem.out
```

这样在本地就能复现并定位，不用上生产。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| pprof 端点暴露公网 | 信息泄露、被滥用 | 只监听内网或加鉴权 |
| 采样时间太短 | 数据没有代表性 | 至少 30 秒或复现完整流程 |
| 只看 flat 不看 cum | 找不到调用链入口 | 两个都看 |
| 只采样一次就下结论 | 偶发噪声误导 | 多次采样对比 |
| 内存只看 inuse | 漏掉频繁小对象 | 同时看 alloc_objects |
| 忘了开 block/mutex 采样 | 采集不到等待数据 | `runtime.SetBlockProfileRate(1)` |
| 在生产直接 attach 长时间分析 | 影响线上性能 | 用低采样率或先灰度 |
| 改动后不复测 | 不知道是否真的变快 | 用同样的基准复测 |

### 手把手练习：定位一个内存热点

```go
var reportPool = sync.Pool{
    New: func() any { return new(bytes.Buffer) },
}

// 优化前：每次请求都新建 Buffer，alloc_objects 极高
func renderSlow(items []Item) string {
    buf := new(bytes.Buffer)
    for _, it := range items {
        fmt.Fprintf(buf, "%s=%d\n", it.Name, it.Value)
    }
    return buf.String()
}

// 优化后：从池里取，用完归还
func renderFast(items []Item) string {
    buf := reportPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        reportPool.Put(buf)
    }()
    for _, it := range items {
        fmt.Fprintf(buf, "%s=%d\n", it.Name, it.Value)
    }
    return buf.String()
}
```

配合 `go test -bench . -benchmem` 对比 `allocs/op` 是否下降。

### 学完自测

- [ ] 能说出四类 profile 各自回答什么问题。
- [ ] 知道 `flat` 与 `cum` 的区别。
- [ ] 能说出 goroutine 泄漏排查的四步。
- [ ] 知道内存问题为什么要同时看两个指标。
- [ ] 能说出 pprof 端点为什么不能暴露公网。
