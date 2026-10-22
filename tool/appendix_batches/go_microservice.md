## 服务骨架速查

| 主题 | 建议做法 |
| --- | --- |
| 配置加载 | 启动时读取环境变量并校验，缺失必填项直接失败 |
| 依赖装配 | `main` 里显式构造依赖并注入，避免全局变量 |
| 路由 | `http.ServeMux` 或轻量框架，版本前缀 `/api/v1` |
| 中间件 | 恢复 panic、日志、请求 ID、鉴权、限流 |
| 优雅关闭 | 监听 `SIGTERM`，先停止接流量再等待在途请求 |
| 健康检查 | `/livez` 只看进程，`/readyz` 检查依赖 |
| 可观测 | 结构化日志 + 指标 + 链路 ID |
| 错误返回 | 统一错误码与 HTTP 状态码映射 |

```go
func main() {
	ctx, stop := signal.NotifyContext(context.Background(),
		syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load()          // 启动即校验配置
	if err != nil {
		log.Fatalf("配置错误：%v", err)
	}

	srv := &http.Server{
		Addr:              cfg.Addr,
		Handler:           newRouter(cfg),
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("服务异常退出：%v", err)
		}
	}()

	<-ctx.Done()                        // 等待终止信号
	log.Println("开始优雅关闭")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("关闭超时：%v", err)
	}
	log.Println("已退出")
}
```

## 可观测性速查

| 维度 | 关键内容 |
| --- | --- |
| 日志 | 结构化（JSON）、带 `trace_id`、按级别输出，不打印敏感信息 |
| 指标 | QPS、错误率、P95/P99 延迟、并发数、队列长度、goroutine 数 |
| 链路 | 入口生成 trace id，跨服务透传（HTTP Header / gRPC Metadata） |
| 告警 | 基于 SLO 与错误预算，避免噪声告警 |
| 健康 | `/livez` 与 `/readyz` 分开，readiness 检查下游依赖 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 直接 `srv.Close()` 关闭 | 在途请求被中断 | 用 `Shutdown` + 超时 |
| 只监听 SIGINT | 容器里收不到停止信号 | 同时监听 SIGTERM |
| 配置缺失时用默认值硬扛 | 线上行为诡异 | 必填项启动即校验并失败 |
| readiness 检查所有依赖 | 下游抖动导致全实例摘除 | 只检查关键依赖，或分级降级 |
| 健康检查做重活 | 探针超时、误重启 | 轻量返回状态 |
| 日志用字符串拼接 | 无法结构化查询 | 用 `slog` 的键值对 |
| 缺少请求 ID | 跨服务排查困难 | 入口生成并透传 |
| goroutine 泄漏 | 内存持续上涨 | 每次请求都带 context 并可取消 |
| 不做限流与超时 | 单个慢依赖拖垮服务 | 客户端设超时、重试上限，服务端限流 |
| 重试无退避与幂等 | 放大故障、重复写入 | 指数退避 + 幂等键 |

## 自测清单

- [ ] 服务能优雅关闭并等待在途请求完成。
- [ ] 配置在启动时校验，缺失必填项直接失败。
- [ ] 日志结构化并带 trace id，指标覆盖延迟与错误率。
- [ ] 所有外部调用都有超时、限流与重试上限。
- [ ] `/livez` 与 `/readyz` 语义分离。
