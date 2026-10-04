## 零基础详解：Go 工程结构与测试

### 一句话说清它是什么

Go 的工程约定非常固定：**cmd 放入口、internal 放私有实现、pkg 放可复用库**。
测试则用标准库自带的 `testing` 包，不依赖第三方框架。

### 用生活比喻理解

| 目录 | 比喻 | 说明 |
| --- | --- | --- |
| `cmd/` | 大门 | 每个可执行程序一个子目录 |
| `internal/` | 内部车间 | 编译器强制只允许本模块导入 |
| `pkg/` | 对外开放的柜台 | 允许外部项目使用 |
| `go.mod` | 项目身份证 | 模块名与依赖版本 |
| `_test.go` | 验收单 | 与源码放在一起 |

### 一个标准的项目骨架

```text
myapp/
  cmd/
    server/main.go          程序入口
  internal/
    user/
      service.go            业务逻辑
      service_test.go       单元测试
      store.go              数据访问
  pkg/
    validate/               可被外部复用的工具
  go.mod
  Makefile
```

```go
// cmd/server/main.go
package main

import (
    "log"
    "net/http"

    "example.com/myapp/internal/user"
)

func main() {
    svc := user.NewService()
    mux := http.NewServeMux()
    mux.HandleFunc("/users", svc.HandleList)

    srv := &http.Server{
        Addr:              ":8080",
        Handler:           mux,
        ReadHeaderTimeout: 5 * time.Second,
    }
    log.Fatal(srv.ListenAndServe())
}
```

### 表驱动测试：Go 的标准写法

```go
package user

import (
    "strings"
    "testing"
)

func TestValidateName(t *testing.T) {
    cases := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"正常", "小明", false},
        {"空字符串", "", true},
        {"太长", strings.Repeat("字", 51), true},
    }

    for _, c := range cases {
        t.Run(c.name, func(t *testing.T) {
            err := ValidateName(c.input)
            if (err != nil) != c.wantErr {
                t.Fatalf("ValidateName(%q) 错误 = %v，期望出错 %v", c.input, err, c.wantErr)
            }
        })
    }
}
```

### 测试四件套

| 功能 | 写法 | 说明 |
| --- | --- | --- |
| 普通测试 | `func TestXxx(t *testing.T)` | 必须以 Test 开头 |
| 基准测试 | `func BenchmarkXxx(b *testing.B)` | 用 `go test -bench .` |
| 示例测试 | `func ExampleXxx()` | 用注释写期望输出 |
| 模糊测试 | `func FuzzXxx(f *testing.F)` | 自动生成输入找边界问题 |

```bash
go test ./...                    # 跑全部包
go test -race ./...              # 检测数据竞争
go test -cover ./...             # 查看覆盖率
go test -run TestValidate -v     # 只跑指定测试
go test -bench . -benchmem       # 基准测试并显示内存分配
```

### 依赖与接口：让测试能替换实现

```go
// 接口定义在使用方，方便测试替换
type Store interface {
    Get(id int) (User, error)
}

type Service struct {
    store Store
}

func NewService(store Store) *Service { return &Service{store: store} }

// 测试里用内存实现，不依赖数据库
type memoryStore struct{ data map[int]User }

func (m *memoryStore) Get(id int) (User, error) {
    u, ok := m.data[id]
    if !ok {
        return User{}, ErrNotFound
    }
    return u, nil
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用相对导入路径 | 编译失败 | 用模块名开头的完整路径 |
| 把实现放 `pkg/` | 对外暴露内部细节 | 私有实现放 `internal/` |
| 测试依赖真实数据库 | 慢且不稳定 | 用接口加内存实现 |
| 只用 `t.Log` 不失败 | 测试永远通过 | 用 `t.Errorf` / `t.Fatalf` |
| 表驱动测试没起名字 | 失败时分不清哪条 | 用 `t.Run(name, ...)` |
| 忘了 `-race` | 数据竞争漏检 | CI 里加 `go test -race` |
| 循环变量在子测试里 | 旧版本会全部用最后一个值 | Go 1.22 已修复，旧版本加 `c := c` |
| 依赖版本不整理 | go.mod 与代码不一致 | 提交前 `go mod tidy` |

### 手把手练习：为金额工具写测试

```go
// money.go
package money

import (
    "errors"
    "math"
)

var ErrNegative = errors.New("金额不能为负")

func Round(amount float64) (float64, error) {
    if amount < 0 {
        return 0, ErrNegative
    }
    return math.Round(amount*100) / 100, nil
}
```

```go
// money_test.go
package money

import (
    "errors"
    "testing"
)

func TestRound(t *testing.T) {
    cases := []struct {
        in   float64
        want float64
    }{
        {19.994, 19.99},
        {19.995, 20.0},
        {0, 0},
    }
    for _, c := range cases {
        got, err := Round(c.in)
        if err != nil {
            t.Fatalf("Round(%v) 意外出错：%v", c.in, err)
        }
        if got != c.want {
            t.Errorf("Round(%v) = %v，期望 %v", c.in, got, c.want)
        }
    }
}

func TestRoundNegative(t *testing.T) {
    _, err := Round(-1)
    if !errors.Is(err, ErrNegative) {
        t.Fatalf("期望 ErrNegative，实际 %v", err)
    }
}
```

### 学完自测

- [ ] 能说出 `cmd`、`internal`、`pkg` 各自的用途。
- [ ] 能写出一个表驱动测试并给子测试命名。
- [ ] 知道为什么要用接口让测试替换实现。
- [ ] 能说出 `-race` 与 `-cover` 的作用。
- [ ] 知道提交前要跑 `go mod tidy`。
