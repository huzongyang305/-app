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
