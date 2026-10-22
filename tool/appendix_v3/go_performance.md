## 零基础详解：性能分析与常见优化

### 一句话说清它是什么

Go 的性能优化只有一条正确路径：**先用 pprof 测量，找到热点，再改一处并复测**。
凭感觉改代码，往往把时间花在不重要的地方。

### 用生活比喻理解

| 工具 | 比喻 | 说明 |
| --- | --- | --- |
| pprof | 体检报告 | 告诉你哪里真的慢 |
| 基准测试 | 对照实验 | 改动前后对比数据 |
| 逃逸分析 | 判断住哪里 | 变量在栈上还是堆上 |
| sync.Pool | 共享储物柜 | 复用临时对象，减轻 GC |
| GOMEMLIMIT | 预算上限 | 告诉运行时内存天花板 |

### 三类 pprof 各看什么

| 类型 | 采集方式 | 回答什么问题 |
| --- | --- | --- |
| CPU | `pprof.StartCPUProfile` | 时间花在哪些函数 |
| 内存 | `pprof.WriteHeapProfile` | 谁在分配、谁在占用 |
| goroutine | `pprof.Lookup("goroutine")` | 是否泄漏、卡在哪 |
| 阻塞 | `pprof.Lookup("block")` | 谁在等待锁或 channel |

最省事的做法是引入 HTTP 端点：

```go
import (
    "net/http"
    _ "net/http/pprof"          // 注册 /debug/pprof/ 路由
)

func main() {
    go func() {
        // 只在内网或本机监听，别暴露到公网
        _ = http.ListenAndServe("127.0.0.1:6060", nil)
    }()
    // ... 启动你的服务
}
```

```bash
go tool pprof http://127.0.0.1:6060/debug/pprof/profile?seconds=30
go tool pprof http://127.0.0.1:6060/debug/pprof/heap
```

### 基准测试：优化的前提

```go
func BenchmarkConcat(b *testing.B) {
    parts := []string{"a", "b", "c", "d"}
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        _ = strings.Join(parts, "")
    }
}
```

```bash
go test -bench . -benchmem -count=5
```

看三个数字：**每次耗时 ns/op、每次分配次数 allocs/op、每次分配字节 B/op**。

### 五个最常见的优化点

```go
// 1. 预分配切片容量，避免反复扩容
users := make([]User, 0, len(ids))
for _, id := range ids {
    users = append(users, load(id))
}

// 2. 拼接大量字符串用 Builder
var sb strings.Builder
sb.Grow(1024)
for _, s := range parts {
    sb.WriteString(s)
}
result := sb.String()

// 3. 复用临时对象（注意：池中对象随时可能被回收）
var bufPool = sync.Pool{
    New: func() any { return new(bytes.Buffer) },
}
buf := bufPool.Get().(*bytes.Buffer)
buf.Reset()
defer bufPool.Put(buf)

// 4. map 预分配，减少 rehash
cache := make(map[string]int, 1024)

// 5. 避免不必要的接口装箱与拷贝
func sum(nums []int) int {          // 传切片而不是数组，避免整体拷贝
    total := 0
    for _, n := range nums {
        total += n
    }
    return total
}
```

### 逃逸分析：为什么会有额外分配

```bash
go build -gcflags="-m" ./...
```

常见逃逸原因：

| 原因 | 例子 | 改进 |
| --- | --- | --- |
| 返回局部变量的指针 | `return &x` | 尽量返回值 |
| 存进 interface | `fmt.Println(x)` | 热点路径避免频繁装箱 |
| 闭包捕获 | `go func() { use(x) }()` | 明确传参 |
| 切片增长过大 | `append` 反复扩容 | 预分配容量 |
| 大小未知的栈对象 | 大数组局部变量 | 改用切片或降低体积 |

### 容器里的内存设置

```bash
# 让运行时知道容器内存上限，避免被 OOM Kill
GOMEMLIMIT=800MiB
GOMAXPROCS=4
```

| 环境变量 | 作用 |
| --- | --- |
| `GOMEMLIMIT` | 软性内存上限，比只调 GOGC 更可控 |
| `GOMAXPROCS` | 并行执行的 P 数量 |
| `GOGC` | GC 触发比例，默认 100 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 凭感觉优化 | 改了半天没效果 | 先 pprof 定位 |
| 只测一次 | 数据波动误判 | `-count=5` 取多次结果 |
| 把 pprof 暴露公网 | 信息泄露 | 只监听内网或加鉴权 |
| 滥用 `sync.Pool` | 对象丢失导致 bug | 只放可重建的临时对象 |
| 忘记 `Grow` 或 `reserve` | 反复扩容 | 已知规模就预留 |
| 在热路径做字符串拼接 | 分配量巨大 | 用 `Builder` |
| 把大结构按值传 | 每次调用都拷贝 | 传指针或切片 |
| 忽略 GC 指标 | 延迟毛刺查不出 | 看 heap 与 GC 频率 |

### 手把手练习：优化一个统计函数

```go
// 优化前：多次分配、重复拼接
func slowJoin(words []string) string {
    out := ""
    for _, w := range words {
        out += w + ","
    }
    return out
}

// 优化后：一次预分配、无多余拷贝
func fastJoin(words []string) string {
    if len(words) == 0 {
        return ""
    }
    var sb strings.Builder
    sb.Grow(len(words) * 8)          // 估算长度
    for i, w := range words {
        if i > 0 {
            sb.WriteByte(',')
        }
        sb.WriteString(w)
    }
    return sb.String()
}
```

配合两个基准测试对比 `ns/op` 与 `allocs/op`，就能看到明确差距。

### 学完自测

- [ ] 能说出 CPU、内存、goroutine 三类 profile 各回答什么问题。
- [ ] 知道 `-benchmem` 输出的三个关键指标。
- [ ] 能列出至少四个常见逃逸原因。
- [ ] 知道 `sync.Pool` 适合放什么、不适合放什么。
- [ ] 能说出容器里为什么要设置 `GOMEMLIMIT`。
