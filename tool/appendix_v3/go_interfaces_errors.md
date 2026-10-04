## 零基础详解：接口是「能力清单」，error 是「签收回执」

### 一句话说清它是什么

Go 的接口是**隐式实现**的：只要你的类型有这些方法，就算实现了它，不用写 `implements`。
错误处理则坚持**显式返回**：函数把 error 当作第二个返回值交给你，由你决定怎么处理。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 接口 | 岗位要求清单 | 满足要求就能上岗，不需要登记 |
| 方法集 | 会的技能 | 有这些方法就满足接口 |
| error | 签收回执 | 每次调用都要看一眼 |
| `%w` 包装 | 转交时附上来源说明 | 保留原始错误，便于追根 |
| panic | 火警 | 只在真的失控时拉响 |

### 接口的两条最佳实践

```go
// 1. 接口定义在使用方，而不是实现方
type Store interface {
    Save(user User) error
}

// 2. 接口要小，一个方法最好
type Stringer interface {
    String() string
}
```

小接口更容易被满足，也更容易组合；`io.Reader`、`io.Writer` 就是最好的例子。

### 错误处理的三种层次

```go
var ErrNotFound = errors.New("记录不存在")     // 1. 哨兵错误，供比较

func Find(id int) (User, error) {
    u, err := db.Query(id)
    if err != nil {
        // 2. 包装错误，保留原因并加上下文
        return User{}, fmt.Errorf("查询用户 %d 失败: %w", id, err)
    }
    if u.ID == 0 {
        return User{}, ErrNotFound
    }
    return u, nil
}

// 3. 调用方按类型或值判断，而不是比字符串
if errors.Is(err, ErrNotFound) {
    // 处理「没找到」
}

var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Println("出错路径：", pathErr.Path)
}
```

### error 判断方式对照

| 写法 | 用途 | 注意 |
| --- | --- | --- |
| `err != nil` | 最常见 | 必写，别忽略 |
| `errors.Is` | 判断是不是某个具体错误 | 能穿透 `%w` 包装 |
| `errors.As` | 把错误转成具体类型 | 用于需要读字段的场景 |
| 比较错误字符串 | 判断错误内容 | **不要用**，日志一变就失效 |

### panic 与 recover 的正确用法

```go
func safeDivide(a, b int) (result int, err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("除零保护: %v", r)
        }
    }()
    return a / b, nil
}
```

规则：**可预期的问题用 error，不可恢复的程序缺陷才 panic**；
`recover` 只应出现在服务或任务的边界（例如 HTTP 中间件），不要到处写。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忽略 error | 问题延后爆发 | 每个 error 都处理 |
| 用字符串比较错误 | 日志一变就失效 | 用 `errors.Is` 或 `As` |
| 包装时用 `%v` | 丢失错误链 | 用 `%w` |
| 接口定义得太胖 | 没人能实现 | 拆成一两个方法 |
| 返回接口而不是具体类型 | 调用方失去信息 | 返回具体类型，接收用接口 |
| 到处 panic | 一个错误搞崩服务 | 改回 error 返回 |
| `recover` 写在错误的层级 | 抓不到 | 放在 defer 中且在同一 goroutine |
| nil 接口不等于 nil | 判空失效 | 注意「带类型的 nil」陷阱 |

### 手把手练习：带错误链的配置读取

```go
package main

import (
    "errors"
    "fmt"
)

var ErrMissingKey = errors.New("缺少配置项")

type Config map[string]string

func (c Config) Require(key string) (string, error) {
    value, ok := c[key]
    if !ok || value == "" {
        return "", fmt.Errorf("读取配置 %q: %w", key, ErrMissingKey)
    }
    return value, nil
}

func main() {
    cfg := Config{"host": "localhost"}
    _, err := cfg.Require("port")
    if errors.Is(err, ErrMissingKey) {
        fmt.Println("配置不完整：", err)
    }
}
```

### 学完自测

- [ ] 能解释「隐式实现接口」的含义。
- [ ] 知道为什么接口要定义在使用方且尽量小。
- [ ] 能说出 `errors.Is` 与 `errors.As` 的区别。
- [ ] 知道包装错误要用 `%w` 而不是 `%v`。
- [ ] 能说出 panic 与 error 各自适用的场景。
