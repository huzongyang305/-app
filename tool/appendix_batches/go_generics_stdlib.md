## 泛型速查

| 概念 | 写法 | 说明 |
| --- | --- | --- |
| 类型参数 | `func Map[T, U any](s []T, f func(T) U) []U` | 泛型函数 |
| 类型约束 | `type Number interface { ~int \| ~float64 }` | `~` 表示底层类型 |
| 内置约束 | `any`、`comparable` | `comparable` 支持 `==` |
| 泛型类型 | `type Set[T comparable] map[T]struct{}` | 泛型数据结构 |
| 类型推断 | 调用时通常可省略类型参数 | `Map(items, fn)` |
| 单态化 | 每种类型编译一份代码 | 体积会增大 |

```go
// 泛型集合：comparable 约束保证可以用作 map 键
type Set[T comparable] map[T]struct{}

func (s Set[T]) Add(v T) { s[v] = struct{}{} }
func (s Set[T]) Has(v T) bool {
	_, ok := s[v]
	return ok
}

// 数值约束：支持多种底层类型
type Number interface {
	~int | ~int64 | ~float64
}

func Sum[T Number](nums []T) T {
	var total T
	for _, n := range nums {
		total += n
	}
	return total
}
```

## 标准库速查

| 场景 | 包与用法 |
| --- | --- |
| HTTP 服务 | `net/http` 的 `http.Server`、`http.HandlerFunc` |
| HTTP 客户端 | `http.Client` + `context` 设置超时 |
| JSON | `encoding/json` 的 `Marshal` / `Unmarshal` / `Decoder` |
| 时间 | `time.Now()`、`time.Parse`、`time.Ticker` |
| 文件与路径 | `os`、`path/filepath`、`io/fs` |
| 字符串处理 | `strings`、`strconv` |
| 并发原语 | `sync`、`sync/atomic`、`context` |
| 日志 | `log/slog`（结构化日志） |
| 测试 | `testing`、`net/http/httptest` |
| 命令行参数 | `flag`（复杂场景用 cobra / urfave） |

```go
// Go 1.22+ 的 ServeMux 支持方法与前缀匹配，标准库即可搭服务
mux := http.NewServeMux()
mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
})

srv := &http.Server{
	Addr:              ":8080",
	Handler:           mux,
	ReadHeaderTimeout: 5 * time.Second,  // 必设，防止慢速攻击
	ReadTimeout:       15 * time.Second,
	WriteTimeout:      15 * time.Second,
	IdleTimeout:       60 * time.Second,
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 泛型约束用 `any` 却要比较 | 编译错误 | 需要比较时用 `comparable` |
| 忘记 `~` | 自定义类型无法匹配 | 用 `~int` 允许底层类型 |
| 泛型滥用 | 代码难读、二进制变大 | 有明确复用需求才使用泛型 |
| `http.Server` 不设超时 | 慢连接耗尽资源 | 设置读写与空闲超时 |
| `json.Unmarshal` 到未导出字段 | 字段始终为零值 | 字段必须导出（大写开头） |
| 忘记 `json` tag | 字段名与接口不一致 | 用 `json:"user_id"` |
| 用字符串拼 JSON | 注入与转义问题 | 用 `encoding/json` |
| `time.Parse` 时区不对 | 时间偏差几小时 | 明确布局与时区（`time.RFC3339`、`time.UTC`） |
| 逐行 `ReadString` 读大文件 | 内存与性能问题 | 用 `bufio.Scanner` 或流式解码 |
| 忽略 `resp.Body.Close()` | 连接泄漏 | `defer resp.Body.Close()` |

## 自测清单

- [ ] 会用 `comparable` 与自定义约束写泛型。
- [ ] `http.Server` 设置了完整的超时参数。
- [ ] JSON 字段导出并带 tag，错误逐层处理。
- [ ] 时间统一用 UTC 存储、展示时转换。
- [ ] HTTP 响应体一定 `defer Close()`。
