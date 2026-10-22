## 零基础详解：Go 测试的高级用法

### 一句话说清它是什么

Go 的测试工具链是标准库自带的：`go test` 一个命令就包含单元测试、基准测试、示例测试与模糊测试。
写好测试的关键是**表驱动 + 子测试 + 可替换的接口**。

### 用生活比喻理解

| 类型 | 比喻 | 回答什么问题 |
| --- | --- | --- |
| 单元测试 | 零件检验 | 这个函数对不对 |
| 基准测试 | 计时赛 | 它有多快、分配了多少内存 |
| 示例测试 | 说明书示例 | 用法是否和文档一致 |
| 模糊测试 | 随机压力 | 有没有边界崩溃 |
| 集成测试 | 装配检验 | 多个组件配合是否正常 |

### 单元测试：表驱动与子测试

```go
func TestDivide(t *testing.T) {
    cases := []struct {
        name    string
        a, b    int
        want    int
        wantErr error
    }{
        {"正常", 10, 2, 5, nil},
        {"整除有余", 7, 2, 3, nil},
        {"除零", 1, 0, 0, ErrDivideByZero},
    }

    for _, c := range cases {
        t.Run(c.name, func(t *testing.T) {
            got, err := Divide(c.a, c.b)
            if !errors.Is(err, c.wantErr) {
                t.Fatalf("错误 = %v，期望 %v", err, c.wantErr)
            }
            if err == nil && got != c.want {
                t.Errorf("结果 = %d，期望 %d", got, c.want)
            }
        })
    }
}
```

### HTTP 处理函数测试：用 httptest

```go
func TestListHandler(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "/users?page=1", nil)
    rec := httptest.NewRecorder()

    ListHandler(rec, req)

    if rec.Code != http.StatusOK {
        t.Fatalf("状态码 = %d，期望 200", rec.Code)
    }
    var body []User
    if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
        t.Fatalf("解析响应失败：%v", err)
    }
    if len(body) == 0 {
        t.Error("响应为空")
    }
}
```

`httptest` 让你不用真的起服务器就能测处理逻辑，速度极快。

### 基准测试：把「觉得慢」变成数字

```go
func BenchmarkParseJSON(b *testing.B) {
    data := []byte(`{"id":1,"name":"小明","tags":["a","b"]}`)
    b.ReportAllocs()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        var u User
        if err := json.Unmarshal(data, &u); err != nil {
            b.Fatal(err)
        }
    }
}
```

```bash
go test -bench . -benchmem -count=5
```

### 示例测试：文档即测试

```go
func ExampleDivide() {
    result, _ := Divide(10, 2)
    fmt.Println(result)
    // Output: 5
}
```

只要注释里写了 `// Output:`，`go test` 就会真的执行并比对输出——**文档永远不会过时**。

### 模糊测试：让机器找边界

```go
func FuzzParseAge(f *testing.F) {
    f.Add("18")
    f.Add("-1")

    f.Fuzz(func(t *testing.T, input string) {
        age, err := ParseAge(input)
        if err != nil {
            return                  // 允许报错，但不能 panic
        }
        if age < 0 || age > 150 {
            t.Fatalf("返回了不可能的年龄：%d", age)
        }
    })
}
```

```bash
go test -fuzz FuzzParseAge -fuzztime 30s
```

### 测试覆盖率与 CI

```bash
go test -coverprofile=cover.out ./...
go tool cover -html=cover.out              # 浏览器查看哪些行没覆盖
go test -race -cover ./...                 # CI 里的标准组合
```

```yaml
# GitHub Actions 片段
- run: go vet ./...
- run: go test -race -cover ./...
- run: go build ./...
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `t.Log` 代替失败 | 测试永远通过 | 用 `t.Errorf` / `t.Fatalf` |
| 子测试名字重复 | 输出难区分 | 用描述性名字 |
| 测试依赖真实网络 | 慢且不稳定 | 用 `httptest` 或接口替换 |
| 忘了 `b.ResetTimer` | 基准结果不准 | 准备数据后再计时 |
| 并行测试共享数据 | 结果随机失败 | 每个用例独立数据 |
| 只测成功路径 | 异常分支无人管 | 补错误用例 |
| 覆盖率当成目标 | 断言很弱 | 关注分支与断言质量 |
| CI 不跑 `-race` | 数据竞争漏到线上 | 加进流水线 |

### 手把手练习：给解析函数写全套测试

```go
// parse.go
package parse

import (
    "errors"
    "strconv"
    "strings"
)

var ErrEmpty = errors.New("输入为空")

func Age(text string) (int, error) {
    trimmed := strings.TrimSpace(text)
    if trimmed == "" {
        return 0, ErrEmpty
    }
    n, err := strconv.Atoi(trimmed)
    if err != nil {
        return 0, err
    }
    if n < 0 || n > 150 {
        return 0, errors.New("年龄超出范围")
    }
    return n, nil
}
```

```go
// parse_test.go
package parse

import (
    "errors"
    "testing"
)

func TestAge(t *testing.T) {
    cases := []struct {
        name    string
        in      string
        want    int
        wantErr error
    }{
        {"正常", " 18 ", 18, nil},
        {"边界 0", "0", 0, nil},
        {"边界 150", "150", 150, nil},
        {"空输入", "   ", 0, ErrEmpty},
        {"非数字", "abc", 0, nil},
    }
    for _, c := range cases {
        t.Run(c.name, func(t *testing.T) {
            got, err := Age(c.in)
            if c.wantErr != nil && !errors.Is(err, c.wantErr) {
                t.Fatalf("期望错误 %v，实际 %v", c.wantErr, err)
            }
            if c.wantErr == nil && c.name != "非数字" && got != c.want {
                t.Errorf("结果 = %d，期望 %d", got, c.want)
            }
        })
    }
}
```

### 学完自测

- [ ] 能写出带子测试的表驱动测试。
- [ ] 知道 `httptest` 解决什么问题。
- [ ] 能说出 `-benchmem` 输出里三个指标的含义。
- [ ] 知道示例测试如何保证文档不过时。
- [ ] 能说出 CI 里 `go vet` 与 `-race` 的作用。
