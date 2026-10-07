# Go 基础

![Go 语言的核心特征](images/diagram_go_basics.webp)

![Go 基础](images/remaining_go_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：30 分钟

## 学习目标

- 能用自己的话解释Go 基础解决了什么问题，而不是只背术语。
- 能说清 「Go」、「goroutine」、「channel」、「并发」 之间的关系，并分别举出一个例子。
- 能把 Go 放回「Go 基础」的知识体系，说明它和 goroutine 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：goroutine/channel 并发模型与显式错误处理。

## 前置知识

- 能运行 findUser 所在环境的基本命令；陌生术语先回到本课术语表。
- 本课阶段：基础。建议先掌握同一分类的基础课程，并能独立运行正文里的 findUser 示例。
- 开始前先复习：Go、goroutine、channel。
- 卡在 Go 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

## 语言定位

Go（Golang）由 Google 设计，主打**简单、编译快、并发友好、部署方便**：编译成单个静态可执行文件，自带垃圾回收与标准库，非常适合云原生、微服务与 CLI 工具（Docker、Kubernetes、etcd 都用它写）。

## 基础语法要点

| 特性 | 说明 |
| --- | --- |
| 变量声明 | `var x int = 1` 或短变量声明 `x := 1`（函数内可用） |
| 类型 | 静态强类型，零值明确（int 为 0、string 为 ""、指针为 nil） |
| 多返回值 | 函数可返回多个值，错误通常作为最后一个返回值 |
| 错误处理 | 显式 `if err != nil`，没有异常机制（panic 仅用于不可恢复错误） |
| 结构体 | 值类型，方法可定义在值或指针接收者上 |
| 接口 | 隐式实现：只要方法集匹配就满足接口 |
| 包管理 | go mod init / go get / go mod tidy |

## 并发模型

Go 用 **goroutine** 与 **channel** 实现 CSP 模型：不要通过共享内存来通信，而要通过通信来共享内存。

| 原语 | 用途 |
| --- | --- |
| goroutine | 轻量协程，`go f()` 即启动 |
| channel | 类型安全的管道，用于传递数据与同步 |
| select | 多路复用，可配合超时与退出信号 |
| sync 包 | Mutex、WaitGroup、Once、原子操作 |

关键实践：用 context 传递取消与超时；用 WaitGroup 等待一组任务；channel 要有明确的关闭方，避免向已关闭的 channel 发送数据导致 panic。

## 工程实践

1. 错误要带上文：`fmt.Errorf("load config: %w", err)`，用 `errors.Is/As` 判断。
2. 用 `defer` 释放资源（关闭文件、解锁），注意它在函数返回时执行。
3. 目录结构常用 `cmd/`（入口）、`internal/`（私有包）、`pkg/`（可复用包）。
4. 工具链：`go fmt` 统一格式、`go vet` 静态检查、`go test -race` 竞态检测。
5. 性能优化先看 pprof（CPU/内存/阻塞分析），再改代码。

## 常见错误与排查

1. 循环变量捕获（Go 1.22 之前需显式复制）。
2. nil map 写入会 panic，必须 make 初始化。
3. goroutine 泄漏：启动后无人回收，要用 context 控制生命周期。
4. 接口值为 nil 但底层类型非 nil，判断时容易出错。
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

## 本课小结

Go 的设计哲学是**少即是多**：语法小、工具链统一、并发原语内置。掌握 goroutine + channel + 显式错误处理，就能写出可维护的云原生服务。

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

## 复习与自测

- [ ] 会用 `:=` 与 `var`，知道零值规则。
- [ ] 函数返回错误作为最后一个值，并逐层处理。
- [ ] 切片、映射、结构体的差异与初始化方式清楚。
- [ ] 提交前跑 `gofmt`、`go vet`、`go test`。
- [ ] 知道接口的隐式实现与类型断言的安全写法。

## 零基础详解：Go 程序的骨架与「显式」哲学

### 一句话说清它是什么

Go 是一门**为工程而生**的语言：语法少、编译快、自带并发和垃圾回收。
它的核心哲学是「显式」——错误要显式返回。变量要显式使用，别指望编译器猜你的意图。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 包 package | 一个抽屉 | 相关代码放一起 |
| 模块 module | 一个项目文件夹 | 由 `go.mod` 定义，管理依赖 |
| 入口 `main` | 大门 | 程序从 `main.main` 开始执行 |
| goroutine | 轻量临时工 | 几 KB 栈，能开成千上万个 |
| error 返回值 | 签收回执 | 每次调用都要看看有没有出错 |

### 逐行拆解第一个程序

```go
package main                    // 声明这是可执行程序所在的包

import (
    "errors"                    // 标准库：构造错误
    "fmt"                       // 标准库：格式化输入输出
)

func main() {                   // 程序入口
    name, err := greet("")
    if err != nil {             // Go 的固定写法：先判错误
        fmt.Println("出错：", err)
        return
    }
    fmt.Println(name)
}

func greet(name string) (string, error) {
    if name == "" {
        return "", errors.New("名字不能为空")   // 显式返回错误
    }
    return "你好，" + name, nil
}
```

| 语法点 | 说明 |
| --- | --- |
| `package main` | 可执行程序必须叫 `main`，库用别的名字 |
| `import (...)` | 多个包用括号分组，不用逗号 |
| `:=` | 声明并推导类型，只能用在函数内 |
| `(string, error)` | 多返回值，Go 没有异常，靠它表达失败 |
| `if err != nil` | 最常出现的三行代码，别偷懒忽略 |

### 变量与零值

```go
var a int          // 0
var s string       // ""（不是 nil）
var p *int         // nil
var m map[string]int   // nil，读可以，写会 panic！

b := 10            // 短声明，最常用
const MaxRetry = 3 // 常量
```

**Go 没有「未初始化」的变量，只有零值。** 危险的是 `nil map` 和 `nil slice`：
读没问题，写要先用 `make`。

### 工具链三件套

```bash
go mod init example/demo    # 初始化模块，生成 go.mod
go run .                    # 编译并运行
go build -o demo .          # 生成可执行文件
go test ./...               # 跑全部测试
gofmt -w .                  # 格式化（Go 强制统一风格）
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 声明了变量不用 | 编译不过 | Go 不允许未使用变量，删掉或使用 |
| 向 nil map 写入 | panic | 先 `make(map[string]int)` |
| 忽略 error | 问题被掩盖 | 每个 error 都要处理 |
| 循环变量取地址 | 所有指针指向同一个值 | 循环内复制一份 `v := v`（Go 1.22 前） |
| `defer` 参数立即求值 | 拿到的是旧值 | 用闭包 `defer func(){ ... }()` |
| 大写首字母才导出 | 别的包看不到 | 需要外部访问就首字母大写 |
| 包名与目录不一致 | 导入混乱 | 包名尽量与目录同名 |
| 忘记 `go mod tidy` | 依赖缺失或多余 | 提交前执行一次 |

### 接口与错误的两条惯例

```go
// 1. 接口定义在使用方，且保持很小
type Reader interface {
    Read(p []byte) (int, error)
}

// 2. 包装错误保留上下文，便于 errors.Is / errors.As 判断
if err != nil {
    return fmt.Errorf("读取配置失败: %w", err)
}
```

### 手把手练习：命令行问候与统计

```go
package main

import (
    "errors"
    "fmt"
)

func average(nums []float64) (float64, error) {
    if len(nums) == 0 {
        return 0, errors.New("数组不能为空")
    }
    var sum float64
    for _, n := range nums {
        sum += n
    }
    return sum / float64(len(nums)), nil

}

func main() {
    avg, err := average([]float64{88, 92, 79})
    if err != nil {
        fmt.Println("计算失败：", err)
        return
    }
    fmt.Printf("平均分：%.1f\n", avg)
}
```

### 学完自测

- [ ] 能说出 `:=` 与 `var` 的使用场合。
- [ ] 能解释为什么 Go 不允许有未使用的变量。
- [ ] 知道向 nil map 写入会发生什么。
- [ ] 能写出返回 `(值, error)` 的函数并正确处理错误。
- [ ] 能说清 `defer` 的执行顺序和参数求值时机。

## 动手练习

> 本课练习重点：围绕「Go、goroutine、channel」完成复述、实验和交付，每个结果都要能被别人检查。

围绕 Go 写一个最小示例，先用 findUser 跑通，再补一个边界输入。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Go 基础解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「goroutine」是什么关系？

验收标准：说明 Go 与 goroutine 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先原样跑通正文里的 `findUser`，再只改Go相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：交付一个小结果（30 分钟）

围绕 Go 写一个最小示例，先用 findUser 跑通，再补一个边界输入。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Go」和「goroutine」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

本节围绕Go 基础安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Go 基础」的结构，画完再对照骨架：

- 主干：语言定位 → 基础语法要点 → 并发模型 → 工程实践
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Go与goroutine的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案的差异必须落在「Go 基础」的实际约束上；写清当Go越过哪条边界时应该换方案。

### 任务 3：迁移到自己的场景

**验收标准**：换一个人按你的记录重跑 findUser，能得到相同输出；得不到就补写缺失的前提。

## 故障现场

### 现场 1：向 nil map 写入

**症状**：在《Go 基础》的复现场景中，panic：assignment to entry in nil map。

**根因**：触发点是把“向 nil map 写入”当成安全做法。它没有满足《Go 基础》要求的前提，因此先表现为“panic：assignment to entry in nil map”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Go 基础》的问题，用 make(map[string]int) 初始化。

**验证**：先在《Go 基础》中记录“向 nil map 写入”留下的失败证据，再执行“用 make(map[string]int) 初始化”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：读取 nil map

**症状**：在《Go 基础》的复现场景中，返回零值，不 panic。

**根因**：当出现“读取 nil map”时，执行路径已经绕过了《Go 基础》的关键约束，最终以“返回零值，不 panic”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Go 基础》的问题，读取安全，写入才需要初始化。

**验证**：先在《Go 基础》中记录“读取 nil map”留下的失败证据，再执行“读取安全，写入才需要初始化”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：:= 重复声明同一变量

**症状**：在《Go 基础》的复现场景中，至少一个新变量才合法。

**根因**：当出现“:= 重复声明同一变量”时，执行路径已经绕过了《Go 基础》的关键约束，最终以“至少一个新变量才合法”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Go 基础》的问题，检查左侧是否已有新变量。

**验证**：在《Go 基础》中按“检查左侧是否已有新变量”调整后，从“:= 重复声明同一变量”的触发条件重放同一条路径，确认“至少一个新变量才合法”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 版本与时效

- 升级前先用 findUser 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 Go 相关的差异单独记成一条结论。
- 升级后重点回归 Go 的默认值、警告信息与错误格式。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 Go 的版本变化。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Go 的并发模型基于什么？」的判断依据。
- [ ] 不看解析，能说出「Go 的错误处理方式是？」的判断依据。
- [ ] 不看解析，能说出「向 nil map 写入会怎样？」的判断依据。
- [ ] 不看解析，能说出「Go 中 := 与 = 的区别是？」的判断依据。
- [ ] 不看解析，能说出「defer 语句的执行时机与顺序是？」的判断依据。
- [ ] 跑通「Go 基础」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Go` | 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利。 |
| `并发` | 多个任务在重叠时间窗口内推进，关注共享状态、同步与调度。 |
| `一句话说清它是什么` | Go 是一门为工程而生的语言：语法少、编译快、自带并发和垃圾回收。 |
| `逐行拆解第一个程序` | package main // 声明这是可执行程序所在的包。 |

## 考点精讲

### 考点 1：多选辨析·Go

- **题目**：围绕“Go 基础”中的 Go、goroutine、channel，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Go 基础」里，题干的正确项是学习 Go 时要同时说明输入、输出和失败路径，不能只看正常流程。在Go 基础里，判断 goroutine 时要固定版本与边界输入，所以“验证 goroutine 时要固定版本并覆盖边界输入，结论才可复现”才可复现。把“验证 goroutine 时要固定版本并”代回「Go 基础」里“围绕Go 基础中的 Go、goroutine、channel”的例子核对，条件一旦改变，结论就要用Go、goroutine、channel重新推导。

### 考点 2：代码补全·Go

- **题目**：这段 Go 代码是「Go 基础」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「Go 基础」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「Go 基础」里封装边界决定Go从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「Go 基础」的实际运行结果为准。回到「Go 基础」的正文示例，用“这段 Go 代码是Go 基础的示例片”走一遍Go、goroutine、channel的完整流程，能复现的结论才可以保留。

### 考点 3：概念判断·Go

- **题目**：向 nil map 写入会怎样？
- **判断依据**：map 必须用 make 或字面量初始化后才能写入。在「Go 基础」里，如果只凭关键词作答，很容易把「忽略写入」、「返回 error」与「panic，必须先 make」混在一起；把“panic，必须先 make”代回「Go 基础」里“向 nil map 写入会怎样”的例子核对，条件一旦改变，结论就要用Go、goroutine、channel重新推导。

### 考点 4：概念判断·Go

- **题目**：Go 中 := 与 = 的区别是？
- **判断依据**：在「Go 基础」里，结论应落在「:= 声明并推导类型（只能用在函数内），= 只做赋值」。结论应落在:= 声明并推导类型（只能用在函数内）。:= 至少要有左侧一个新变量，重复声明同一变量会编译报错。在「Go 基础」里，这道题要求区分概念与边界，「:= 声明并推导类型（只能用在函数内），= 只做赋值」只有在题干给出的前提下才成立，而「两者完全等价」、「:= 可以用于包级变量（仅部分场景成立）」缺少同一组条件。

### 考点 5：概念判断·Go

- **题目**：defer 语句的执行时机与顺序是？
- **判断依据**：作答时，先用Go建立输入与输出的基线，再把函数返回前执行代入边界条件核对，结论才能复现。这道题的关键在「Go 基础」的Go、goroutine、channel：先确认题干“defer 语句的执行时机与顺序是”问的是哪一步，再排除偷换前提的选项。把“函数返回前执行”代回「Go 基础」里“defer”的例子核对，条件一旦改变，结论就要用Go、goroutine、channel重新推导。

### 考点 6：填空·Go

- **题目**：补全代码：「Go 基础」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `fmt.____("查询失败：", err)`
- **判断依据**：在「Go 基础」里，Println。在「Go 基础」里判断这道题，要把Go、goroutine、channel的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。回到「Go 基础」的正文示例，用“补全代码”走一遍Go、goroutine、channel的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Go Basics

**Summary:** Goroutines, channels and explicit errors.

**Category:** Go
**Level:** 基础
**Key terms:** Go, goroutine, channel, 并发, error

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Go 1.24+
；本课聚焦 Go。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Go、goroutine、channel、并发、error
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Go Basics** focuses on Goroutines, channels and explicit errors.

### Learning Outcomes

- Explain what **Go Basics** solves and when it should be used.

### Glossary

- Topic: **Go Basics**
- Related terms: Go, goroutine, channel, 并发

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 语言定位 | 语言定位 |
| 基础语法要点 | 基础语法要点 |
| 并发模型 | ConcurrencyModel |
| 工程实践 | 工程实践 |
| 常见坑 | 常见坑 |
| 本课小结 | Summary |
| 基础语法速查 | 基础语法速查 |
| 常用命令速查 | 常用命令速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Go 并发](https://go.dev/talks/2012/concurrency.slide) | goroutine 与 channel |
| [Go 官方教程](https://go.dev/tour/) | 语言基础与并发入门 |
| [Effective Go](https://go.dev/doc/effective_go) | 惯用写法与接口设计 |

> 「Go 基础」的链接用于离线阅读后的延伸核对；App 不会自动联网。
