## 零基础详解：Go 微服务的工程要点

### 一句话说清它是什么

一个能上线的 Go 服务，除了业务逻辑，还必须具备四件事：
**能启动、能探活、能优雅退出、能被观测**。缺一件就会在发布或故障时出问题。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 健康检查 | 体检报告 | 告诉编排系统能不能接流量 |
| 优雅关闭 | 收摊流程 | 不再接单，把手上活干完 |
| 中间件 | 安检通道 | 统一做日志、恢复、鉴权 |
| 指标 | 仪表盘 | 用数字描述运行状态 |
| 配置校验 | 出发前检查 | 启动时就把错误暴露出来 |

### 一个标准的服务骨架

```go
package main

import (
    "context"
    "errors"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    cfg, err := LoadConfig()                 // 1. 启动就校验配置
    if err != nil {
        slog.Error("配置无效", "err", err)
        os.Exit(1)
    }

    mux := http.NewServeMux()
    mux.HandleFunc("/healthz/live", func(w http.ResponseWriter, _ *http.Request) {
        w.WriteHeader(http.StatusOK)
    })
    mux.HandleFunc("/healthz/ready", func(w http.ResponseWriter, _ *http.Request) {
        if err := checkDependencies(ctx); err != nil {
            http.Error(w, "未就绪", http.StatusServiceUnavailable)
            return
        }
        w.WriteHeader(http.StatusOK)
    })
    mux.Handle("/api/", WithRecovery(WithLogging(apiHandler())))

    srv := &http.Server{
        Addr:              cfg.Addr,
        Handler:           mux,
        ReadHeaderTimeout: 5 * time.Second,   // 2. 必须设超时
        ReadTimeout:       15 * time.Second,
        WriteTimeout:      15 * time.Second,
        IdleTimeout:       60 * time.Second,
    }

    go func() {
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            slog.Error("服务启动失败", "err", err)
            stop()
        }
    }()
    slog.Info("服务已启动", "addr", cfg.Addr)

    <-ctx.Done()                             // 3. 等待退出信号
    slog.Info("开始优雅关闭")

    shutdownCtx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
    defer cancel()
    if err := srv.Shutdown(shutdownCtx); err != nil {
        slog.Error("关闭超时", "err", err)
    }
}
```

### 两个探针的分工

| 路径 | 检查内容 | 失败后果 |
| --- | --- | --- |
| `/healthz/live` | 进程是否还活着（不查依赖） | 重启容器 |
| `/healthz/ready` | 依赖是否可用、是否完成预热 | 只摘流量 |

**把数据库检查放进 liveness 会引起重启风暴**：数据库抖一下，所有实例全部重启。

### 中间件的两个必备件

```go
func WithRecovery(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if rec := recover(); rec != nil {
                slog.Error("请求 panic", "path", r.URL.Path, "err", rec)
                http.Error(w, "内部错误", http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}

func WithLogging(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        slog.Info("请求完成",
            "method", r.Method, "path", r.URL.Path,
            "cost", time.Since(start).String())
    })
}
```

### 可观测性三件套

| 支柱 | Go 里的常见做法 | 回答什么问题 |
| --- | --- | --- |
| 指标 | Prometheus + 直方图 | 整体趋势、告警 |
| 日志 | `log/slog` 结构化输出 | 发生了什么 |
| 链路 | OpenTelemetry + trace id | 这次请求慢在哪 |

**延迟要用直方图而不是平均值**，否则 P95、P99 根本算不出来。

### 配置与依赖

```go
type Config struct {
    Addr        string
    DatabaseURL string
    JWTSecret   string
}

func LoadConfig() (Config, error) {
    cfg := Config{
        Addr:        envOr("ADDR", ":8080"),
        DatabaseURL: os.Getenv("DATABASE_URL"),
        JWTSecret:   os.Getenv("JWT_SECRET"),
    }
    if cfg.DatabaseURL == "" {
        return cfg, errors.New("缺少 DATABASE_URL")
    }
    if len(cfg.JWTSecret) < 32 {
        return cfg, errors.New("JWT_SECRET 至少要 32 个字符")
    }
    return cfg, nil
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 不设 HTTP 超时 | 慢连接耗尽连接数 | 至少设 ReadHeaderTimeout |
| liveness 检查依赖 | 下游抖动引发重启风暴 | 依赖放 readiness |
| 直接 `os.Exit` | 在途请求被中断 | 用 `srv.Shutdown` |
| panic 不恢复 | 单个请求打挂整个进程 | 加 Recovery 中间件 |
| 配置不校验 | 运行到一半才崩 | 启动时全量校验 |
| 日志用字符串拼接 | 无法检索字段 | 用结构化日志 |
| 指标只有平均值 | 长尾问题看不见 | 用直方图算分位数 |
| 关闭没有超时 | 卡住不退出 | 给 Shutdown 带 context 超时 |

### 学完自测

- [ ] 能说出 liveness 与 readiness 的分工。
- [ ] 知道为什么 HTTP 服务必须设置超时。
- [ ] 能说出优雅关闭的三个步骤。
- [ ] 知道为什么延迟指标要用直方图。
- [ ] 能说出启动时校验配置的好处。
