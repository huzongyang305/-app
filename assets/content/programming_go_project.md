# Go 工程实践

![Go 工程实践的四个环节](images/diagram_go_project.webp)

![Go 工程实践](images/remaining_go_project.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释Go 工程实践解决了什么问题，而不是只背术语。
- 能说清 「Go」、「go mod」、「测试」、「pprof」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Go」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：模块目录、表驱动测试、pprof 与静态单文件部署。

## 前置知识

- 先完成上一课《Go 接口与错误处理》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：Go、go mod、测试。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 模块与目录

`go mod init github.com/you/app` 初始化模块；目录约定：`cmd/`（可执行入口）、`internal/`（仅本模块可见）、`pkg/`（对外可复用）、`api/`（接口定义）、`testdata/`（测试数据）。

## 质量工具链

| 命令 | 作用 |
| --- | --- |
| `go fmt ./...` | 统一格式（官方风格，无争议） |
| `go vet ./...` | 静态检查可疑代码 |
| `go test ./... -race -cover` | 测试 + 竞态检测 + 覆盖率 |
| `go test -bench=. -benchmem` | 基准测试与内存分配 |
| `golangci-lint run` | 聚合多种 linter |
| `go mod tidy` | 清理与补齐依赖 |

## 测试与基准

表驱动测试（table-driven）是 Go 的主流写法：用例写成切片，循环执行子测试 `t.Run`。基准测试用 `testing.B`，关注 ns/op 与 allocs/op；优化前先写 benchmark，否则无法判断收益。

## 性能分析

标准库自带 `net/http/pprof` 或 `runtime/pprof`，可采集 CPU、内存、阻塞、goroutine 与 mutex profile。排查顺序：先看指标定位资源类型，再用 pprof 找热点函数。

## 构建与部署

```text
CGO_ENABLED=0 go build -ldflags "-s -w" -o app   # 静态单文件，体积更小
GOOS=linux GOARCH=amd64 go build                 # 交叉编译
```

配合多阶段 Docker 构建（builder 阶段编译，scratch/alpine 运行）可产出几 MB 的镜像。

## 本课小结
Go 工程化的关键是**统一工具链 + 表驱动测试 + pprof 定位 + 静态单文件部署**；语言本身简单，工程规范才是团队效率的来源。

## 工程结构速查

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

| 目录 | 约定 |
| --- | --- |
| `cmd/` | 每个可执行程序一个子目录 |
| `internal/` | 编译器强制限制外部导入 |
| `pkg/` | 确实需要对外暴露时才用 |
| 领域包内聚 | 按业务能力分包，不按「controller/service/dao」分层 |
| 测试文件同目录 | `xxx_test.go` 与被测代码放一起 |

## 测试与构建速查

| 目的 | 写法 |
| --- | --- |
| 表驱动测试 | `tests := []struct{ ... }{}` + `t.Run` |
| 子测试并行 | `t.Parallel()` |
| 临时目录 | `t.TempDir()` |
| 基准测试 | `func BenchmarkX(b *testing.B)` + `b.ReportAllocs()` |
| 示例测试 | `func ExampleX()` 带 `// Output:` |
| 覆盖率 | `go test -coverprofile=cover.out ./...` |
| 静态构建 | `CGO_ENABLED=0 go build -trimpath -ldflags="-s -w"` |
| 版本注入 | `-ldflags "-X main.version=$(git describe --tags)"` |

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

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把业务逻辑写在 `main.go` | 无法测试、难以复用 | `main` 只做装配与启动 |
| 包名与目录不一致 | 阅读与导入混乱 | 包名与目录名保持一致 |
| 循环导入 | 编译错误 | 抽公共包，或用接口反转依赖 |
| 用全局变量存配置 | 测试相互影响 | 显式传参或依赖注入 |
| 忘记 `go mod tidy` | 依赖缺失或冗余 | 提交前执行 |
| 沿用 GOPATH 目录结构 | 现代工具链不识别 | 使用模块 `go.mod` |
| 测试依赖真实数据库 | 慢且不稳定 | 用接口替身或测试容器 |
| 未跑 `-race` | 竞态潜伏到线上 | CI 加 `go test -race` |
| 构建未加 `-trimpath` | 产物含本地路径 | 发布构建统一参数 |
| 版本号写死在代码 | 无法追溯发布 | 用 `-ldflags` 注入版本 |

## 自测清单

- [ ] 项目使用 `cmd/` 与 `internal/` 结构，`main` 只做装配。
- [ ] 测试采用表驱动并覆盖错误分支。
- [ ] CI 跑 `go vet`、`go test -race` 与覆盖率。
- [ ] 发布构建使用 `-trimpath -ldflags="-s -w"`。
- [ ] 依赖通过 `go.mod` 管理并执行 `go mod tidy`。

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

## 动手练习

> 本课练习重点：围绕「Go、go mod、测试」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小程序并用 go test 验证，再补 context、并发上限和错误传播。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Go 工程实践解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「go mod」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小程序，并用 `go test` 或 `go vet` 验证结果。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Go」和「go mod」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 格式化检查 | `gofmt -l .` | 没有文件需要格式化 |
| 静态检查 | `go vet ./...` | 没有 vet 报告 |
| 运行测试 | `go test ./... -count=1` | 所有包测试通过 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

## 可运行练习

### 任务 1：先跑通，再解释

```json
{
  "project": "go_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 任务 2：只改一个条件

把「Go 工程实践」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把Go的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「Go 工程实践」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Go。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 Go 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 Go 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 Go 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“Go 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 Go 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 go mod 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 go mod 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 go mod 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“go mod 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 go mod 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，Go 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- 升级前用 go vet、go test -race 与静态检查覆盖并发生命周期
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Go 中最主流的测试写法是？」的判断依据。
- [ ] 不看解析，能说出「交叉编译到 Linux amd64 需要设置？」的判断依据。
- [ ] 不看解析，能说出「产出体积小、无动态依赖的可执行文件常用？」的判断依据。
- [ ] 不看解析，能说出「go mod tidy 的作用是？」的判断依据。
- [ ] 不看解析，能说出「Go 项目中 cmd/ 与 internal/ 目录的约定是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「Go 工程实践」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `Go` | go mod init github.com/you/app 初始化模块；目录约定：cmd/（可执行入口）、internal/（仅本模块可见）、pkg/（对外可复用）、api/（接口定义）、testdata/（测试数据）。 |
| `go mod` | go mod init github.com/you/app 初始化模块；目录约定：cmd/（可执行入口）、internal/（仅本模块可见）、pkg/（对外可复用）、api/（接口定义）、testdata/（测试数据）。 |
| `测试` | Related terms: Go, go mod, 测试, pprof。 |
| `pprof` | Go Project Practices focuses on Layout, table-driven tests, pprof and static builds.。 |
| `交叉编译` | 它在「Go 工程实践」里是理解「交叉编译」的关键术语，用来解释定义、适用条件与失败路径；它与Go、go mod共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |

## 考点精讲

### 考点 1：多选辨析·Go

- **题目**：围绕“Go 工程实践”中的 Go、go mod、测试，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Go 工程实践」里，题干的正确项是学习 Go 时要同时说明输入、输出和失败路径，不能只看正常流程。在Go 工程实践里，判断 go mod 时要固定版本与边界输入，所以“验证 go mod 时要固定版本并覆盖边界输入，结论才可复现”才可复现。回到「Go 工程实践」的正文示例，用“围绕Go 工程实践中的 Go、go”走一遍Go、go mod、测试的完整流程，能复现的结论才可以保留。

### 考点 2：概念判断·Go

- **题目**：交叉编译到 Linux amd64 需要设置？
- **判断依据**：在「Go 工程实践」里，GOOS=linux GOARCH=amd64。GOOS/GOARCH 控制目标平台。这道题的关键在「Go 工程实践」的Go、go mod、测试：先确认题干“交叉编译到 Linux amd64”问的是哪一步，再排除偷换前提的选项。把“GOOS=linux GOARCH=am”代回「Go 工程实践」里“交叉编译到 Linux amd64 需要设置”的例子核对，条件一旦改变，结论就要用Go、go mod、测试重新推导。

### 考点 3：代码补全·Go

- **题目**：这段 Go 代码是「Go 工程实践」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「Go 工程实践」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「Go 工程实践」里封装边界决定Go从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「Go 工程实践」的实际运行结果为准。在「Go 工程实践」里判断这道题，要把Go、go mod、测试的条件、过程与失败路径逐项对齐，换成“这段 Go 代码是Go 工程实践的示”这个场景，只有满足前提的结论才成立。

### 考点 4：概念判断·Go

- **题目**：go mod tidy 的作用是？
- **判断依据**：在「Go 工程实践」里，结论应落在「补齐代码需要但缺失的依赖」。提交前跑一次 go mod tidy，能保证 go.mod / go.sum 与代码一致。在「Go 工程实践」里，这道题要求区分概念与边界，「补齐代码需要但缺失的依赖」只有在题干给出的前提下才成立，而「删除 go.sum」、「更新 Go 版本」缺少同一组条件。

### 考点 5：概念判断·Go

- **题目**：Go 项目中 cmd/ 与 internal/ 目录的约定是？
- **判断依据**：在「Go 工程实践」里，cmd 放可执行程序入口。internal 由编译器强制限制可见范围，适合放不希望对外暴露的实现。在「Go 工程实践」里判断这道题，要把Go、go mod、测试的条件、过程与失败路径逐项对齐，换成“Go 项目中 cmd/ 与 inte”这个场景，只有满足前提的结论才成立。

### 考点 6：填空·Go

- **题目**：补全代码：「Go 工程实践」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____=0 go build -ldflags "-s -w" -o app # 静态单文件，体积更小`
- **判断依据**：空格应填写「CGO_ENABLED」、「cgo_enabled」。回到「Go 工程实践」的正文示例，用“补全代码”走一遍Go、go mod、测试的完整流程，能复现的结论才可以保留。回到Go、go mod、测试本身再看一遍：只有“CGOENABLED”与题干“工程实践示例中”的前提一致，结论才成立。

## English Overview

**Title:** Go Project Practices

**Summary:** Layout, table-driven tests, pprof and static builds.

**Category:** Go
**Level:** 基础
**Key terms:** Go, go mod, 测试, pprof, 交叉编译

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Go 1.24+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Go、go mod、测试、pprof、交叉编译
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：Go 工程实践

### 核心场景

模块目录、表驱动测试、pprof 与静态单文件部署。 项目目标是把「Go、go mod、测试、pprof、交叉编译」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | Go、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。

## 项目交付物

### 建议仓库结构

```text
cmd/app/
internal/domain/
internal/infra/
pkg/
go.mod
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "go_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「Go、go mod、测试」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

## Full English Study Guide

### Overview

**Go Project Practices** focuses on Layout, table-driven tests, pprof and static builds.

### Learning Outcomes

- Explain what **Go Project Practices** solves and when it should be used.

### Glossary

- Topic: **Go Project Practices**
- Related terms: Go, go mod, 测试, pprof

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 模块与目录 | Modules与目录 |
| 质量工具链 | 质量Tools链 |
| 测试与基准 | Testing与基准 |
| 性能分析 | Performance分析 |
| 构建与部署 | Build与Deployment |
| 本课小结 | Summary |
| 工程结构速查 | 工程结构速查 |
| 测试与构建速查 | Testing与Build速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Go pprof](https://pkg.go.dev/net/http/pprof) | 性能剖析与火焰图 |
| [Effective Go](https://go.dev/doc/effective_go) | 惯用写法与接口设计 |
| [Go 并发](https://go.dev/talks/2012/concurrency.slide) | goroutine 与 channel |

> 「Go 工程实践」的链接用于离线阅读后的延伸核对；App 不会自动联网。
