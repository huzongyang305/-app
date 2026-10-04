## 接口速查

| 概念 | 说明 |
| --- | --- |
| 隐式实现 | 只要方法集匹配即自动实现接口 |
| 小接口 | 单方法接口（如 `io.Reader`）更易组合 |
| 空接口 `any` | 可存任意值，使用需断言 |
| 类型断言 | `v, ok := x.(T)`，双返回值安全 |
| 类型分支 | `switch v := x.(type) { ... }` |
| 接口嵌套 | `interface { io.Reader; io.Writer }` |
| 接口即约定 | 通常在使用方定义，而非实现方 |

```go
// 小接口 + 组合，比大接口更灵活
type Notifier interface {
	Notify(ctx context.Context, message string) error
}

type MultiNotifier struct {
	notifiers []Notifier
}

func (m *MultiNotifier) Notify(ctx context.Context, message string) error {
	var errs []error
	for _, n := range m.notifiers {
		if err := n.Notify(ctx, message); err != nil {
			errs = append(errs, err) // 不中断，收集全部错误
		}
	}
	return errors.Join(errs...)
}
```

## 错误处理速查

| 目的 | 写法 |
| --- | --- |
| 创建错误 | `errors.New("msg")`、`fmt.Errorf("...: %w", err)` |
| 包装并保留链 | `fmt.Errorf("读取配置失败: %w", err)` |
| 判断错误值 | `errors.Is(err, os.ErrNotExist)` |
| 提取错误类型 | `var pathErr *os.PathError; errors.As(err, &pathErr)` |
| 合并多个错误 | `errors.Join(err1, err2)` |
| 哨兵错误 | `var ErrNotFound = errors.New("not found")` |
| 自定义错误类型 | 实现 `Error() string` 的结构体 |
| 不可恢复错误 | `panic`（仅用于程序缺陷或初始化失败） |
| 恢复 | `defer func() { if r := recover(); r != nil { ... } }()` |

```go
var ErrNotFound = errors.New("not found")

func (s *Store) Get(id int) (User, error) {
	user, ok := s.data[id]
	if !ok {
		return User{}, fmt.Errorf("store.Get(%d): %w", id, ErrNotFound)
	}
	return user, nil
}

// 调用方按错误类型分支处理
user, err := store.Get(42)
switch {
case errors.Is(err, ErrNotFound):
	// 映射成 404
case err != nil:
	// 其他错误：记录并返回 500
default:
	_ = user
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `==` 比较包装后的错误 | 判断失败 | 用 `errors.Is` 穿透包装 |
| 用 `%v` 包装错误 | 丢失错误链 | 用 `%w` |
| 到处 `panic` | 服务整体崩溃 | 只在启动期或不可恢复时 panic |
| `recover` 后不记录日志 | 问题被吞 | 记录堆栈并转成 error 返回 |
| 错误信息重复上下文 | 日志出现「读取失败: 读取失败」 | 只在跨越边界时补充上下文 |
| 定义过大的接口 | 难以 mock、实现臃肿 | 拆成小接口，按需组合 |
| 在实现方定义接口 | 依赖方向错误 | 接口定义在使用方 |
| 接口值为 nil 判断错误 | 非 nil 但调用 panic | 注意具体类型为 nil 时的接口包装 |
| 忘记 `defer` 关闭资源 | 文件与连接泄漏 | `defer f.Close()` 紧跟创建之后 |
| 忽略 `defer` 中的错误 | 写入失败未发现 | 命名返回值 + `defer` 检查错误 |

## 自测清单

- [ ] 接口按使用方需要定义，保持小而专注。
- [ ] 错误用 `%w` 包装，用 `errors.Is` 与 `errors.As` 判断。
- [ ] 只在启动期或不可恢复时使用 `panic`。
- [ ] `recover` 之后一定记录日志。
- [ ] 资源创建后立刻 `defer` 释放。
