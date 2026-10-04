## 基础语法速查

| 概念 | 写法 | 说明 |
| --- | --- | --- |
| 变量声明 | `var name string` / `name := "x"` | `:=` 只能用在函数内 |
| 常量 | `const Pi = 3.14` | 编译期确定 |
| 多返回值 | `func f() (int, error)` | 错误作为最后一个返回值 |
| 零值 | 声明未赋值即零值 | `int` 为 0、`string` 为 ""、`map` 为 nil |
| 切片 | `s := []int{1, 2, 3}` | 动态数组，最常用 |
| 数组 | `a := [3]int{}` | 固定长度，赋值会整体拷贝 |
| 映射 | `m := map[string]int{}` | 必须 `make` 后才能写入 |
| 结构体 | `type User struct { ID int }` | 值语义，传参默认拷贝 |
| 指针 | `&user`、`*p` | 需要改原对象时用 |
| 接口 | `type Reader interface { Read() }` | 隐式实现 |
| 类型断言 | `v, ok := x.(T)` | 双返回值避免 panic |
| 空接口 | `any` | 可存任意类型，使用前需断言 |

```go
package main

import (
	"errors"
	"fmt"
)

type User struct {
	ID   int
	Name string
}

// 错误作为最后一个返回值，是 Go 的惯例
func findUser(users []User, id int) (User, error) {
	for _, u := range users {
		if u.ID == id {
			return u, nil
		}
	}
	return User{}, fmt.Errorf("user %d: %w", id, errors.New("not found"))
}

func main() {
	users := []User{{ID: 1, Name: "小明"}}
	user, err := findUser(users, 2)
	if err != nil {
		fmt.Println("查询失败：", err)
		return
	}
	fmt.Println(user.Name)
}
```

## 常用命令速查

| 目的 | 命令 |
| --- | --- |
| 初始化模块 | `go mod init example.com/app` |
| 整理依赖 | `go mod tidy` |
| 运行 | `go run .` |
| 构建 | `go build -o bin/app .` |
| 测试 | `go test ./...` |
| 竞态检测 | `go test -race ./...` |
| 覆盖率 | `go test -coverprofile=cover.out ./...` |
| 格式化 | `gofmt -w .`、`go fmt ./...` |
| 静态检查 | `go vet ./...` |
| 交叉编译 | `GOOS=linux GOARCH=amd64 go build` |
| 查看文档 | `go doc fmt.Println` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 向 nil map 写入 | panic：`assignment to entry in nil map` | 用 `make(map[string]int)` 初始化 |
| 读取 nil map | 返回零值，不 panic | 读取安全，写入才需要初始化 |
| 忽略返回的 `error` | 问题被隐藏 | 显式检查并处理或返回 |
| 用 `_` 丢弃错误变量名 | 掩盖错误 | 只在确定无需处理时使用 |
| 未使用的变量或 import | 编译错误 | Go 强制整洁，删掉或用 `_` |
| `:=` 重复声明同一变量 | 至少一个新变量才合法 | 检查左侧是否已有新变量 |
| 切片追加后原切片未更新 | 数据丢失 | `s = append(s, x)` 必须赋值回去 |
| 遍历时取 `&v` 的地址 | 拿到同一个地址 | 用下标取址或先复制到局部变量 |
| 用 `==` 比较含不可比较字段的结构体 | 编译错误 | 用 `reflect.DeepEqual` 或逐字段比较 |
| 用 `nil` 判断接口是否为「空实现」 | 结果非 nil | 接口与具体值都为 nil 时才等于 nil |

## 自测清单

- [ ] 会用 `:=` 与 `var`，知道零值规则。
- [ ] 函数返回错误作为最后一个值，并逐层处理。
- [ ] 切片、映射、结构体的差异与初始化方式清楚。
- [ ] 提交前跑 `gofmt`、`go vet`、`go test`。
- [ ] 知道接口的隐式实现与类型断言的安全写法。
