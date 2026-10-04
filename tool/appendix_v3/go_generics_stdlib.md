## 零基础详解：泛型与标准库常用武器

### 一句话说清它是什么

泛型让同一段代码适配多种类型，同时保留类型检查；
标准库则提供了日常最常用的工具：`net/http`、`encoding/json`、`time`、`slices`、`maps`。

### 泛型三件套

```go
// 1. 类型参数写在方括号里
func Map[T, U any](items []T, fn func(T) U) []U {
    out := make([]U, 0, len(items))
    for _, item := range items {
        out = append(out, fn(item))
    }
    return out
}

// 2. 约束限定可用操作
func Max[T cmp.Ordered](a, b T) T {
    if a > b {
        return a
    }
    return b
}

// 3. 调用时通常能自动推导
nums := []int{3, 1, 2}
doubled := Map(nums, func(n int) int { return n * 2 })
fmt.Println(Max(3, 7), doubled)
```

| 约束 | 允许的操作 | 例子 |
| --- | --- | --- |
| `any` | 任意类型，不能比较大小 | 容器、映射 |
| `comparable` | 可以用 `==`、`!=` | map 的键 |
| `cmp.Ordered` | 可以用 `<`、`>` | 求最大最小、排序 |
| 自定义接口 | 你规定的方法集 | 需要调用特定方法时 |

### 标准库四件套

```go
// 1. net/http：起一个带超时的服务
srv := &http.Server{
    Addr:              ":8080",
    Handler:           mux,
    ReadHeaderTimeout: 5 * time.Second,   // 不设超时是最常见的事故源
    ReadTimeout:       10 * time.Second,
    WriteTimeout:      10 * time.Second,
    IdleTimeout:       60 * time.Second,
}
log.Fatal(srv.ListenAndServe())

// 2. encoding/json：结构体标签控制字段名
type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email,omitempty"`   // 为空时不输出
    Pass  string `json:"-"`                 // 永远不输出
}

// 3. time：超时与定时
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
defer cancel()

// 4. slices / maps：常用集合操作
nums := []int{3, 1, 2}
slices.Sort(nums)                     // 原地排序
fmt.Println(slices.Contains(nums, 2)) // true
fmt.Println(slices.Max(nums))         // 3
```

### 结构体标签速查

| 标签 | 含义 |
| --- | --- |
| `json:"name"` | 序列化时用 name 作为键 |
| `json:"name,omitempty"` | 零值时省略该字段 |
| `json:"-"` | 完全忽略该字段 |
| `json:",string"` | 用字符串形式编码数字 |

**注意**：只有首字母大写的字段才会被序列化。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 泛型约束太宽 | 编译不过（无法比较） | 按需要加 `comparable` 或 `Ordered` |
| 为了省事全用 `any` | 失去类型检查 | 只在真的任意时用 |
| 忘记结构体字段大写 | JSON 输出空对象 | 需要导出的字段首字母大写 |
| HTTP server 不设超时 | 慢连接拖垮服务 | 至少设 ReadHeaderTimeout |
| 不关闭响应体 | 连接泄漏 | 拿到响应立刻 `defer resp.Body.Close()` |
| 忽略 `json.Unmarshal` 的错误 | 数据静默错乱 | 一定检查 |
| 用 `time.Sleep` 做超时 | 无法取消 | 用 `context.WithTimeout` |
| 手写排序和查找 | 容易出错 | 用 `slices`、`maps` |

### 手把手练习：泛型 + JSON + 超时请求

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type Post struct {
    ID    int    `json:"id"`
    Title string `json:"title"`
}

func fetchJSON[T any](ctx context.Context, url string) (T, error) {
    var zero T
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return zero, fmt.Errorf("构造请求失败: %w", err)
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return zero, fmt.Errorf("请求失败: %w", err)
    }
    defer resp.Body.Close()

    var out T
    if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
        return zero, fmt.Errorf("解析失败: %w", err)
    }
    return out, nil
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    post, err := fetchJSON[Post](ctx, "https://example.com/api/post/1")
    if err != nil {
        fmt.Println("出错：", err)
        return
    }
    fmt.Println(post.Title)
}
```

### 学完自测

- [ ] 能写出一个带类型参数的函数并说明约束作用。
- [ ] 知道 `any`、`comparable`、`Ordered` 的差别。
- [ ] 能说出结构体标签 `omitempty` 与 `-` 的区别。
- [ ] 知道为什么 HTTP 服务必须设置超时。
- [ ] 会用 `context.WithTimeout` 给请求加时限。
