# Go Engineering Practice

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundations -- Expected duration: 16 minutes

## Learning objectives

- It's possible to explain in its own words what "Go Engineering Practice" solves, not just the term.
- The relationship between "go", "go mod," "test" and "ppof" is clear, with one example.
- It's a way to put the knowledge back into "Go" and tell us how it works.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: module catalogues, table-driven tests, approf and static single file deployment.

## Pre-knowledge

- The first lesson is " Go interface and error processing " ; if available, this course can be used for self-measurement.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Before we begin: Go, go, test.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Modules & Directory

⟦ Initialization module; Catalogue engagements: ⟦1 (enabled entrance), 2 (visible only in this module) 3 (external re-useability); 4 (interfacing definition); and 5 (test data).

## Quality Tool Chain

|Command|Role|
| --- | --- |
| `go fmt ./...` |Uniform format (official style, non-controversial)|
| `go vet ./...` |Static check for suspicious code|
| `go test ./... -race -cover` |Test + Contest + Coverage|
| `go test -bench=. -benchmem` |Benchmark testing and memory allocation|
| `golangci-lint run` |Multiple|
| `go mod tidy` |Clean-up and completion dependencies|

## Tests and benchmarks

Table driver test (table-driving) is the main way for Go to be written in slices, recyclable subtest ⟦. The benchmark tests are 1 ⟧ and look at ns/op with allocs/p;Write before it is optimized, otherwise the gains cannot be judged.

## Performance Analysis

The standard library contains ⟦0 or 1 and collects CPU, memory, blocking, logoutine and mutex profile.Queuing order: First look at the indicator's resource type, then use the program to find hotspot functions.

## Build and deploy

```text
CGO_ENABLED=0 go build -ldflags "-s -w" -o app   # 静态单文件，体积更小
GOOS=linux GOARCH=amd64 go build                 # 交叉编译
```

The multiple-stage Docker build (compiled by scratch/alpine) can produce several MB images.

## It's the end of this class.
The key to the engineering of Go is** unified tool chain + table-driven testing + prof positioning + static single file deployment**; language itself is simple, and project specifications are a source of team efficiency.

<!-- appendix:v1 -->

## Project structure check.

```text
project/
├── go.mod
├── go.sum
├── cmd/
│   └── api/main.go          # 可执行入口，只做装配
├── internal/                # 只允许本模块导入
│   ├── order/
│   │   ├── service.go
│   │   ├── repository.go
│   │   └── service_test.go
│   └── platform/
│       ├── config/
│       └── logging/
├── migrations/              # 数据库迁移脚本
├── Dockerfile
└── Makefile                 # 常用命令入口
```

|Contents|A promise.|
| --- | --- |
| `cmd/` |One subdirectories for each executable|
| `internal/` |Compiler Force External Import|
| `pkg/` |It does need to be exposed.|
|Field bag.|Subcontract by operational capacity, not "controller/service/dao"|
|Test Files with Directory|Zero, put it with the code.|

## Test & Build Scanning

|Purpose|Writing|
| --- | --- |
|Table driver test| `tests := []struct{ ... }{}` + `t.Run` |
|Subtest Parallel| `t.Parallel()` |
|Temporary Directory| `t.TempDir()` |
|Benchmark testing| `func BenchmarkX(b *testing.B)` + `b.ReportAllocs()` |
|Example Test|I'm sorry, sir.|
|Coverage| `go test -coverprofile=cover.out ./...` |
|Static Construction| `CGO_ENABLED=0 go build -trimpath -ldflags="-s -w"` |
|Version Injection| `-ldflags "-X main.version=$(git describe --tags)"` |

```go
func TestParseAmount(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		input   string
		want    int
		wantErr bool
	}{
		{name: "正常", input: "100", want: 100},
		{name: "空字符串", input: "", wantErr: true},
		{name: "负数", input: "-1", wantErr: true},
	}

	for _, tt := range tests {
		tt := tt // Go 1.22 之前必须复制，避免闭包捕获同一个变量
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			got, err := ParseAmount(tt.input)
			if (err != nil) != tt.wantErr {
				t.Fatalf("err = %v, wantErr = %v", err, tt.wantErr)
			}
			if got != tt.want {
				t.Errorf("got = %d, want = %d", got, tt.want)
			}
		})
	}
}
```

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Write business logic to zero.|It's not possible to test, it's difficult to reuse.|It's only for assembly and startup.|
|The package name doesn't match the directory.|Reading & Import Chaos|The package name corresponds to the directory name.|
|Loop Import|Compiler error|Draw a public bag, or use an interface to reverse it.|
|Global Variable Configuration|The test interacts.|Visibility or dependence on injection|
|Forget it.|Dependence on missing or redundant|Implementation before submission|
|Follow the GOPATH directory structure|Modern tool chain not recognized|Use module ⟦0|
|Test relies on a real database|Slow and unstable.|Use interface or test container|
|Not running.|The race is on the line.|C1 plus 0|
|Build without ⟦|Local path of the product|Publish Build Unified Parameters|
|The version number is in the code.|Unrecoverable|Injecting version with ⟦0|

## Self-Detected List

- [ ] The project uses ⟦0 and 1 structures, 2 only for assembly.
- [ ] Tests are table-driven and cover error branches.
- [ Chuckles ] CI runs the zero, the one with coverage.
- [ ] Release the building to use ⟦0.
- [ ] Reliance on management and execution of ⟦1.

<!-- appendix:v3 -->

## Zero-basic details: Go Project Structure and Testing

### What is it?

The contract for Go is very fixed: **cmd, internal, pkg.
The test is based on the standard library's own kit, which does not depend on a third-party framework.

### It's a life metaphor.

|Contents|A metaphor.|Annotations|
| --- | --- | --- |
| `cmd/` |The gate.|One subdirectories for each executable|
| `internal/` |Internal workshop|Compiler forces only this module to import|
| `pkg/` |Open counter.|Allow external items|
| `go.mod` |Project ID|Module name and dependent version|
| `_test.go` |Receipt and inspection forms|Put it with the source.|

### A standard project skeleton.

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

### Table driver test: Go standard

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

### Test 4 sets

|Functions|Writing|Annotations|
| --- | --- | --- |
|Normal| `func TestXxx(t *testing.T)` |It has to start with Test.|
|Benchmark testing| `func BenchmarkXxx(b *testing.B)` |Use Zero.|
|Example Test| `func ExampleXxx()` |Write aspirational output in notes|
|Fuzzy Test| `func FuzzXxx(f *testing.F)` |Automatically generate input for boundary questions|

```bash
go test ./...                    # 跑全部包
go test -race ./...              # 检测数据竞争
go test -cover ./...             # 查看覆盖率
go test -run TestValidate -v     # 只跑指定测试
go test -bench . -benchmem       # 基准测试并显示内存分配
```

### Dependency and interface: to replace the test

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

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Relative Import Path|Failed to compile|Full path starting with module name|
|Let's go!|External exposure of internal details|Privateization|
|Test relies on a real database|Slow and unstable.|With an interface and memory.|
|It's only a zero. It doesn't fail.|The test will pass forever.|Use ⟦0/ 1|
|No name for the watch drive test.|I don't know which one to lose.|Use Zero.|
|I don't remember.|Data Competition Leak|I, Riga, zero.|
|Cycle variable in sub-test|The old version will all use the last one.|Go 1.22 Recovered, old version plus 0|
|Do Not Collate|Go.mod doesn't match the code.|Before submitting|

### Handheld practice: write for the money tool

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

### Learn how to measure yourself.

- [ ] Can you tell me what it's for?
- [ ] Can write a table-driven test and name the subtest.
- [ ] Know why to replace it with an interface.
- [ ] Can you say the role of ⟦1?
- [ Chuckles ] Know to run before submitting.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: repeat, experiment and deliver around Go, go, test. Each result is checked by someone else.

Write the smallest program and verify it with go test, then fill in the context, put a cap on it and spread it wrong.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with "Go Engineering Practice"?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "go mod"?

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
- This post is part of our special coverage Syria Protests 2011.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Formatting check| `gofmt -l .` |No file to format|
|Static check| `go vet ./...` |No vet report|
|Run Test| `go test ./... -count=1` |All packages passed.|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication orders after a logical change to confirm that they are not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Go Project Practices

**Summary:** Layout, table-driven tests, pprof and static builds.

**Category:** Go  
**Level:** Foundation
**Key terms:** Go go mod, test, program, cross-compile

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: Go 1.24+
- Source: Internal structured curriculum and engineering practices
- Related themes: Go, go mod, testing, ppof, cross-compilation
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Project specification: Go Engineering practice

### Core scene

The objective of the module catalogue, table-driven testing, approf and static single file deployment is to translate "go, go, mod, test, prof, cross compile" into a runable, testable, rolling delivery.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Go, time and source|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Rollback path: Backroll data are consistent and indicate recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
cmd/app/
internal/domain/
internal/infra/
pkg/
go.mod
```

### Test Matrix

|Level|Overwrite|Minimum|Adoption of standards|
| --- | --- | ---: | --- |
|Unit Test|Field rules, boundaries and misclassification| 8 |It's normal. The border, the path to failure.|
|Integrated testing|Database, network, document or platform boundary| 3 |Use real boundaries and run again|
|End-to-end testing|Core User Path| 1 |Full run from input to output|
|Manually.|5 scenes listed in the document| 5 |Orders, output and conclusion records|

### Receiving and Inspection Data

```json
{
  "project": "go_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### Duplicate Template

|Problem|Records|
| --- | --- |
|What was the original target?|I'll give you a description of the acceptable target.|
|What's going on?|Timeline, indicators and key logs|
|Which assumption was overturned?|Root causes and contributing factors|
|How do you roll back?|Steps, time-consuming and data validation|
|What's next?|Responsible persons, duration and certification|

> Project acceptance revolved around "Go, go, test": at least one normal path, one border entry, one failed recovery and one check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Go Project Practices** focuses on Layout, table-driven tests, pprof and static builds.

### Learning Outcomes

- Explain what **Go Project Practices** solves and when it should be used.
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

- Topic: **Go Project Practices**
- Relaid terms: Go, go mod, test, prof
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Modules & Directory|Modules and Directory|
|Quality Tool Chain|QualityTools|
|Tests and benchmarks|Testing and Benchmarks|
|Performance Analysis|Performance analysis|
|Build and deploy|Build and Deloyment|
|It's the end of this class.| Summary |
|Project structure check.|Project structure check.|
|Test & Build Scanning|Testing and Build.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

