# Go Foundation

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Projected duration: 15 minutes

## Learning objectives

- It is possible to explain in its own words what the Go Foundation solves, not just a term.
- The relationship between "go", "goroutine," "channel" and "co-op" is clear, with one example.
- It's a way to put the knowledge back into "Go" and tell us how it works.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: Goroutine/channel combined with a model and visible error processing.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- We'll start with Go, Goroutine and Channel.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Language positioning

Go (Golang) is designed by Google. **Simplified, compiled and easily deployed.** Compiled into a single static implementable document with self-carrying garbage collections and standard repositories that are very suitable for cloud origin, microservices and CLI tools (Docker, Kubernetes, etcd).

## Basic Syntax:

|Features|Annotations|
| --- | --- |
|Variable declaration|⟦ or short variable declaration ⟦ (available in function)|
|Type|Static Power Type, Zero Clear (int: 0; pointer: nil)|
|Multiple return value|Function returns multiple values, usually as last value|
|Error management|Visible ⟦, no anomaly.|
|Structure|Value type, method can be defined on value or pointer recipient|
|Interface|Invisible realization: Matches the interface with a set of methods|
|Package management| go mod init / go get / go mod tidy |

## Parallel Models

Go achieve the CSP model with **goroutine** and **channel**: not by sharing memory, but through communication.

|Original language|Purpose|
| --- | --- |
| goroutine |Lightweight, zero.|
| channel |Type secure conduit for data transfer and synchronization|
| select |It's multiple. We can match the time and exit signals.|
|sync package|Mutex, WaitGroup, Once, Atomic Operations|

Key practice: transfer cancellation and timeout in context; wait for a group of tasks with WaitGroup;Channel should have a clear closure and avoid sending data to closed Chennel resulting in Panic.

## Engineering practice

1. The error must be taken from above: ⟦1.
2. Use ⟦0 to release the resource (closure, unlock) and note that it is executed when the function returns.
3. The directory structure is commonly used for ⟦0 (entry), 1 (private package) and 2 (reusable kit).
4. Tool chain: ⟦ Unique format, statistical inspection, 2 competitive testing.
5. Optimization of performance first (CPU/RAM) and then change the code.

## Common pits

1. Cycle variable capture (go 1.22 requires visible reproduction).
2. nil map writing will panic, must make initialization.
3. Goroutine Leak: Unrecovered after start-up, control life cycle with context.
4. The interface value is nil, but the bottom type is not nitl and can be judged by error.

## It's the end of this class.
The design philosophy of Go is ** less than **: small syntax, unified tool chain and infra-linguistic.The Goroutine + chanel + visible error process allows for the maintenance of cloud-based services.

<!-- appendix:v1 -->

## Basic Syntax:

|Concept|Writing|Annotations|
| --- | --- | --- |
|Variable declaration| `var name string` / `name := "x"` |⟦0 can only be used in a function|
|Constant| `const Pi = 3.14` |Compiled|
|Multiple return value| `func f() (int, error)` |Error as Last Return|
|zero|Declare value as zero|Zero, zero, one, two.|
|Slice| `s := []int{1, 2, 3}` |Dynamic array, most commonly used|
|Numeric| `a := [3]int{}` |Fixed length. Entrusted as a whole.|
|Map| `m := map[string]int{}` |It has to be zero before it's written.|
|Structure| `type User struct { ID int }` |Value semantics, cross-referenced copies|
|Pointer| `&user`、`*p` |Use when changing object|
|Interface| `type Reader interface { Read() }` |Invisible|
|Type assertion| `v, ok := x.(T)` |Double Return Value Avoids Panic|
|Empty interface| `any` |Any type to store, pre-use|

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

## Common command quick check.

|Purpose|Command|
| --- | --- |
|Initializing Modules| `go mod init example.com/app` |
|Collapse Dependence| `go mod tidy` |
|Run| `go run .` |
|Build| `go build -o bin/app .` |
|Test| `go test ./...` |
|Contest| `go test -race ./...` |
|Coverage| `go test -coverprofile=cover.out ./...` |
|Formatting| `gofmt -w .`、`go fmt ./...` |
|Static check| `go vet ./...` |
|Cross-compilation| `GOOS=linux GOARCH=amd64 go build` |
|View Documents| `go doc fmt.Println` |

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Write to nil Map| panic：`assignment to entry in nil map` |Initialize with ⟦0|
|Read nil Map|Return Zero, no panic|Read secure, write to start|
|Ignore returned ⟦0|The problem is hidden.|Visible check and process or return|
|Discard the wrong variable name with ⟦0|Cover your mistakes.|Use only when deciding not to process|
|Unused Variables or Organisation|Compiler error|Go Force cleanness, delete or use ⟦0|
|Repeat the same variable.|At least one new variable.|Check if there are any new variables on the left|
|Slice added unupdated|Data lost|It's got to be worth it.|
|Take the address of ⟦|Get the same address.|Use bottom-marked address or copy to local variable|
|A structure that contains non-comparable fields|Compiler error|Compare with ⟦0 or field by field|
|Use ⟦0 to determine whether the interface is empty|Outcomes are not nil|_Other Organiser|

## Self-Detected List

- [ Chuckles ] It's gonna be a zero with one.
- [ ] The function returns an error as the last value and deals with it layer by level.
- [ ] Slice, map, structure differences and initialization are clear.
- [ Chuckles ] Run before you run.
- [ ] Knows how the interface works and what it says in terms of security.

<!-- appendix:v2 -->

## Zero basics: Go Process Bones and Manifesto Philosophy

### What is it?

Go is a language of engineering**: few syntaxes, fast copying, hand-carrying and garbage recycling.
Its core philosophy is "visibility" -- error returns. Variables are visible, so don't expect the compiler to guess your intentions.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
|Package|A drawer.|Put the relevant code together.|
|Module|Item Folder|Defined by ⟦0, managing dependency|
|I'm sorry.|The gate.|The program starts at zero.|
| goroutine |Light-duty workers|How many KBs can open?|
|Return value|Sign back.|Every time you call, see if there's a mistake.|

### Dismantling first program by line

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

|Syntax:|Annotations|
| --- | --- |
| `package main` |The program has to be called Zero, by another name.|
| `import (...)` |Multiple packages in brackets, no commas|
| `:=` |Declare and extrapolate types, only in functions|
| `(string, error)` |There's no anomaly, it means failure.|
| `if err != nil` |The most common three-line code, don't be lazy.|

### Variables and Zero

```go
var a int          // 0
var s string       // ""（不是 nil）
var p *int         // nil
var m map[string]int   // nil，读可以，写会 panic！

b := 10            // 短声明，最常用
const MaxRetry = 3 // 常量
```

** Go has no "not initialized" variable, only zero.** The danger is 0 and 1:
No problem with reading.

### Tool Chain 3

```bash
go mod init example/demo    # 初始化模块，生成 go.mod
go run .                    # 编译并运行
go build -o demo .          # 生成可执行文件
go test ./...               # 跑全部测试
gofmt -w .                  # 格式化（Go 强制统一风格）
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|No, I'm not.|I can't.|Go does not allow variables to be deleted or used|
|Write to nil Map| panic |Let's go.|
|Ignore rorr|The problem is covered.|Every one of them.|
|Loop Variables for Address|All points to the same value.|Copy a ⟦0 in the cycle (above 122)|
|⟦0 Arguments for immediate value|It's the old one.|I'll take it from here.|
|First letter to export|I can't see the rest of it.|If you need external access, capitalise.|
|The package name doesn't match the directory.|Organisation|Package name is the same as directory|
|Forget it.|Dependency is missing or redundant|Implementation before submission|

### Interfaces and Wrong Practices

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

### Hand hands practice: command greeting and counting

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

### Learn how to measure yourself.

- [ Laughs ] Can you tell me how it works?
- [ ] Explain why Go does not allow unused variables.
- [ Chuckles ] Know what happens when you write to nil map.
- [ ] Can write back the function of ⟦0 and correct the error.
- [ ] Can state the order of execution and timing for parameters.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around "Go, Gooutine, Channel" with each result subject to scrutiny.

Write the smallest program and verify it with go test, then fill in the context, put a cap on it and spread it wrong.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the "Go Base" solution?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "goroutine"?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a runable applet and validates the results with ⟦0 or 1.

Mission requests:

- The result must be checked, not just “I understand”.
- At least cover the two key words "Go" and "gooutine".
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Go Basics

**Summary:** Goroutines, channels and explicit errors.

**Category:** Go  
**Level:** Foundation
**Key terms:**go, goroutine, chanel, etc.

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: Go 1.24+
- Source: Internal structured curriculum and engineering practices
- Related themes: Go, Goroutine, Channel and Error
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Go Basics** focuses on Goroutines, channels and explicit errors.

### Learning Outcomes

- Explain what **Go Basics** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Go Basics**
- Relaid terms: Go, goroutine, channel,
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Language positioning|Language positioning|
|Basic Syntax:|Basic Syntax:|
|Parallel Models| ConcurrencyModel |
|Engineering practice|Engineering practice|
|Common pits|Common pits|
|It's the end of this class.| Summary |
|Basic Syntax:|Basic Syntax:|
|Common command quick check.|Common command quick check.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

