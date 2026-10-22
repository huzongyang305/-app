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
