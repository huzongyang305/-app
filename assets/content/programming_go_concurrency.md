# Go 并发：goroutine、channel 与 context

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：40 分钟

![Go goroutine channel context](images/diagram_go_concurrency.webp)

![Go 并发：goroutine、channel 与 context](images/remaining_go_concurrency.webp)

## 本节知识框架

**课程定位**：所属分类 `go`（Go），课程主题 `Go 并发：goroutine、channel 与 context`，学习阶段 基础，建议用时 45 分钟。

本课主线：channel 通信、worker pool、context 取消与竞态检测。

**学完本课应当能够**
- 说清 `context.WithTimeout` 与 `sync.WaitGroup` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `Go` 的行为，记录输入、输出与失败条件。
- 遇到「传递数据、串起流水线」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `context.WithTimeout`：先掌握 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`，再用它解释 `sync.WaitGroup` 为什么会出现。
2. `sync.WaitGroup`：先掌握 等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait，再用它解释 `Go` 为什么会出现。
3. `Go`：先掌握 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利，再用它解释 `数据竞争` 为什么会出现。
4. `数据竞争`：先掌握 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Go」分类的第 7 课。先修内容：《Go 基础》。《Go 基础》里的 `Go`、`并发` 是本课的前提。相关或后续课程：《Go 接口与错误处理》。

### 完成判据

- **定义关**：不看正文也能说明 `context.WithTimeout` 是 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `Go 并发：goroutine、channel 与 context`，而不是只背结论。
- **示例关**：能运行或推演 `Go 并发：goroutine、channel 与 context` 的 `go` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `Go 并发：goroutine、channel 与 context` 示例里的 调用了 `worker()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 传递数据、串起流水线，记录现象并按 数据流向清晰 修复。
- **迁移关**：能把 `Go`、`goroutine`、`channel`、`context` 放进一个与 `Go 并发：goroutine、channel 与 context` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `Go 并发：goroutine、channel 与 context` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| context.WithTimeout | 超时与取消**：context.WithTimeout 传递取消信号，所有阻塞操作都要监听 ctx.Done()。 | 网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。 |
| sync.WaitGroup | 等待一组任务**：sync.WaitGroup 的 Add/Done/Wait。 | 易错：`sync.WaitGroup`；正确做法是计数归零即完成。 |
| Go | 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利。 | 易错：所有 goroutine 用同一个值；正确做法是Go 1.22 已修复，旧版本要 `v := v`。 |
| 数据竞争 | 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |

## 原理与运行机制

### 机制总览

**教材衔接：三个核心原语**

| 原语 | 作用 |
| --- | --- |
| `go f()` | 启动 goroutine，几 KB 栈，可轻松开十万个 |
| `chan T` | 类型安全管道；无缓冲同步交接，有缓冲为队列 |
| `select` | 多路等待，可配合超时与退出信号 |

Go 的并发哲学：**不要通过共享内存来通信，而要通过通信来共享内存**。

**教材衔接：常见模式**

1. **Worker Pool**：固定 N 个 worker 从 channel 取任务，控制并发度。
2. **扇出扇入**：多个 goroutine 并行处理后汇总到一个 channel。
3. **超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`。
4. **等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait。

**教材衔接：共享状态的两条路**

优先用 channel 传递所有权；确需共享时用 `sync.Mutex`/`RWMutex` 或 `sync/atomic`。读多写少用 `RWMutex`，计数器用 `atomic.Int64`。

**教材衔接：版本与时效**

- 升级「Go 并发：goroutine、channel 与 context」涉及的依赖前，先用 WithTimeout 复现当前行为，再逐项核对版本说明与破坏性变更。
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 WithTimeout 记录构建与运行结果。
- 回归范围锁定 WithTimeout 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 Go 的新旧版本差异，并据此调整下次复核时间。

### 机制拆解：每一步的输入、动作与输出

#### 1. `context.WithTimeout`
- 输入：`Go`；本步把 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()` 当作判断规则。
- 动作：围绕 `context.WithTimeout` 保留中间状态，并记录它与 `sync.WaitGroup` 的对应关系。
- 输出：`sync.WaitGroup`，它可以被下一段代码、测试或记录继续使用。
- `context.WithTimeout` 的失败条件：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。

#### 2. `sync.WaitGroup`
- 输入：`context.WithTimeout`；本步把 等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait 当作判断规则。
- 动作：围绕 `sync.WaitGroup` 保留中间状态，并记录它与 `Go` 的对应关系。
- 输出：`Go`，它可以被下一段代码、测试或记录继续使用。
- `sync.WaitGroup` 的失败条件：当等一组任务结束时，会出现`sync.WaitGroup`。

#### 3. `Go`
- 输入：`sync.WaitGroup`；本步把 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利 当作判断规则。
- 动作：围绕 `Go` 保留中间状态，并记录它与 `数据竞争` 的对应关系。
- 输出：`数据竞争`，它可以被下一段代码、测试或记录继续使用。
- `Go` 的失败条件：当循环变量被捕获时，会出现所有 goroutine 用同一个值。

#### 4. `数据竞争`
- 输入：`Go`；本步把 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除 当作判断规则。
- 动作：围绕 `数据竞争` 保留中间状态，并记录它与 `worker` 的对应关系。
- 输出：`worker`，它可以被下一段代码、测试或记录继续使用。
- `数据竞争` 的失败条件：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

### 示例中的可观察事实

1. 调用了 `worker()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
2. 调用了 `Done()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
3. 调用了 `main()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
4. 调用了 `make()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
5. 调用了 `Add()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
6. 调用了 `close()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
7. 调用了 `Wait()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。
8. 调用了 `Println()`；它对应的课程主题是 `Go 并发：goroutine、channel 与 context`。

### 复现实验记录

- 环境：`Go 并发：goroutine、channel 与 context` 使用 `go` 示例，固定 `Go`、`goroutine`、`channel`、`context` 作为第一组条件。
- 首轮输入：先确认 调用了 `worker()`，预测 `context.WithTimeout` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `Go`，观察 `数据竞争` 是否仍满足定义。
- 失败注入：复现 传递数据、串起流水线，确认现象是 channel。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `Go 并发：goroutine、channel 与 context` 时才能区分概念错误与实现错误。

## 典型应用场景

- **传递数据、串起流水线**：典型现象是channel；正确做法是数据流向清晰。
- **保护一个计数器或缓存**：典型现象是`sync.Mutex` / `atomic`；正确做法是比开 channel 更直接。
- **等一组任务结束**：典型现象是`sync.WaitGroup`；正确做法是计数归零即完成。
- **取消、超时、传请求级数据**：典型现象是`context`；正确做法是标准做法，能层层传递。

### 最小验证场景

- 准备：保留 `go` 示例的原始输入，先记录 `Go 并发：goroutine、channel 与 context` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `worker()`，再改变一个与 `context.WithTimeout` 相关的条件。
- 判定：新结果与 `Go 并发：goroutine、channel 与 context` 的基线不同不等于错误；只有当差异破坏了 `context.WithTimeout` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `context.WithTimeout` 时，先满足它的定义：超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`；网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。
- 使用 `sync.WaitGroup` 时，先满足它的定义：等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait；易错：`sync.WaitGroup`；正确做法是计数归零即完成。
- 使用 `Go` 时，先满足它的定义：由 Google 设计的静态编译语言，强调简单语法、并发和部署便利；易错：所有 goroutine 用同一个值；正确做法是Go 1.22 已修复，旧版本要 `v := v`。
- 使用 `数据竞争` 时，先满足它的定义：多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除；共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

## 代码/协议/SQL 示例

### 最小可验证示例

```go
func worker(ctx context.Context, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()
	for {
		select {
		case <-ctx.Done():
			return                       // 收到取消信号立即退出
		case job, ok := <-jobs:
			if !ok {
				return                   // channel 已关闭且取完
			}
			select {
			case results <- job * 2:
			case <-ctx.Done():
				return
			}
		}
	}
}
```

**教材衔接：goroutine 与 channel 速查**

| 目的 | 写法 | 说明 |
| --- | --- | --- |
| 启动协程 | `go worker()` | 调度开销远小于线程 |
| 等待全部完成 | `var wg sync.WaitGroup` | `Add` 要在 `go` 之前调用 |
| 无缓冲 channel | `make(chan int)` | 收发同步握手 |
| 带缓冲 channel | `make(chan int, 10)` | 缓冲满则发送阻塞 |
| 只发 / 只收类型 | `chan<- int` / `<-chan int` | 用类型表达意图，减少误用 |
| 关闭 channel | `close(ch)` | 由发送方关闭，接收方用 `v, ok := <-ch` 判断 |
| 遍历 channel | `for v := range ch` | channel 关闭且无数据时自动结束 |
| 选择分支 | `select { case v := <-ch: ... }` | 多路复用，可加 `default` 做非阻塞 |
| 超时控制 | `select` + `time.After` | 避免永久等待 |
| 取消传播 | `context.WithCancel` | 逐层传递，配合 `<-ctx.Done()` |
| 限流 | `make(chan struct{}, n)` 或 `errgroup.SetLimit` | 控制并发规模 |
| 错误汇总 | `errgroup.Group` | 任一返回错误即取消其余任务 |

**运行方式**：运行 `Go 并发：goroutine、channel 与 context` 的示例时，用 `go run 文件名.go` 运行；模块依赖由 `go mod` 管理。

### 示例精读：先找证据，再改一个条件

1. 调用了 `worker()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `Done()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `main()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `make()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `Add()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `close()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `Wait()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `Println()`；它出现在 `Go 并发：goroutine、channel 与 context` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `Go 并发：goroutine、channel 与 context` 中与 `context.WithTimeout` 对照：示例必须能支持 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`，否则说明这一段还缺少实现或验证步骤。
- 在 `Go 并发：goroutine、channel 与 context` 中与 `sync.WaitGroup` 对照：示例必须能支持 等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait，否则说明这一段还缺少实现或验证步骤。
- 在 `Go 并发：goroutine、channel 与 context` 中与 `Go` 对照：示例必须能支持 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利，否则说明这一段还缺少实现或验证步骤。
- 在 `Go 并发：goroutine、channel 与 context` 中与 `数据竞争` 对照：示例必须能支持 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**教材衔接：零基础详解：goroutine、channel 与「通过通信共享内存」**

Go 的并发口号是「**不要通过共享内存来通信，而要通过通信来共享内存**」。
具体做法就是：用 goroutine 起任务，用 channel 在任务之间传数据，而不是到处加锁改同一个变量。

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 向已关闭的 channel 发送 | panic | 只让发送方关，先关闭再停止发送 |
| 重复关闭 | panic | 用 `sync.Once` 或明确单一关闭方 |
| 没人接收就发送 | 全部 goroutine 阻塞，报 deadlock | 保证有接收方或改成带缓冲 |
| 忘了 `wg.Add` | `Wait` 立刻返回 | 起 goroutine 前先 Add |
| `wg.Add` 写在 goroutine 里 | 计数可能来不及加 | 必须在 go 之前调用 |
| goroutine 泄漏 | 内存持续增长 | 用 context 或关闭 channel 让它退出 |
| 用共享 map 不加锁 | 并发写导致崩溃 | 加 `Mutex` 或用 channel 串行化 |
| 循环变量被捕获 | 所有 goroutine 用同一个值 | Go 1.22 已修复，旧版本要 `v := v` |

- [ ] 能说出「通过通信共享内存」是什么意思。
- [ ] 知道无缓冲与带缓冲 channel 的区别。
- [ ] 能说出关闭 channel 的两条规则。
- [ ] 知道 `WaitGroup.Add` 为什么必须写在 `go` 之前。
- [ ] 能用 `select` 加 `context` 写出带超时的等待。

**测量方法**：以 `Go 并发：goroutine、channel 与 context` 的 `Go` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `Go 并发：goroutine、channel 与 context` 的 `Go`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Go 并发：goroutine、channel 与 context` 的 `goroutine`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Go 并发：goroutine、channel 与 context` 的 `channel`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Go 并发：goroutine、channel 与 context` 的 `context`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Go 并发：goroutine、channel 与 context` 的 `race`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Go 并发：goroutine、channel 与 context` 中 `context.WithTimeout` 的边界：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。达到边界时不要外推，必须重新测量。
- `Go 并发：goroutine、channel 与 context` 中 `sync.WaitGroup` 的边界：易错：`sync.WaitGroup`；正确做法是计数归零即完成。达到边界时不要外推，必须重新测量。
- `Go 并发：goroutine、channel 与 context` 中 `Go` 的边界：易错：所有 goroutine 用同一个值；正确做法是Go 1.22 已修复，旧版本要 `v := v`。达到边界时不要外推，必须重新测量。
- `Go 并发：goroutine、channel 与 context` 中 `数据竞争` 的边界：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。达到边界时不要外推，必须重新测量。
- `Go 并发：goroutine、channel 与 context` 的代码证据：先验证 调用了 `worker()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 传递数据、串起流水线 | channel | 数据流向清晰 |
| 保护一个计数器或缓存 | `sync.Mutex` / `atomic` | 比开 channel 更直接 |
| 等一组任务结束 | `sync.WaitGroup` | 计数归零即完成 |
| 取消、超时、传请求级数据 | `context` | 标准做法，能层层传递 |
| 限制并发数量 | 带缓冲 channel 当信号量 | 简洁可控 |
| 向已关闭的 channel 发送 | panic | 只让发送方关，先关闭再停止发送 |
| 重复关闭 | panic | 用 `sync.Once` 或明确单一关闭方 |
| 没人接收就发送 | 全部 goroutine 阻塞，报 deadlock | 保证有接收方或改成带缓冲 |
| 忘了 `wg.Add` | `Wait` 立刻返回 | 起 goroutine 前先 Add |
| `wg.Add` 写在 goroutine 里 | 计数可能来不及加 | 必须在 go 之前调用 |
| goroutine 泄漏 | 内存持续增长 | 用 context 或关闭 channel 让它退出 |
| 用共享 map 不加锁 | 并发写导致崩溃 | 加 `Mutex` 或用 channel 串行化 |
| 循环变量被捕获 | 所有 goroutine 用同一个值 | Go 1.22 已修复，旧版本要 `v := v` |
| wg.Add(1) 写在 go func() 内部 | Wait 提前返回。 | Add 必须在启动协程前调用。 |
| 读已关闭的 channel | 立刻返回零值。 | 用 v, ok := <-ch 区分「零值」与「已关闭」。 |
| goroutine 内 panic 未捕获 | 整个进程崩溃。 | 在 recover 中兜住并记录日志。 |

### 现场 1：传递数据、串起流水线

**症状**：channel。

**根因与修复**：数据流向清晰。

**自检**：在本课示例里复现「传递数据、串起流水线」，改成数据流向清晰后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：保护一个计数器或缓存

**症状**：`sync.Mutex` / `atomic`。

**根因与修复**：比开 channel 更直接。

**自检**：在本课示例里复现「保护一个计数器或缓存」，改成比开 channel 更直接后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：等一组任务结束

**症状**：`sync.WaitGroup`。

**根因与修复**：计数归零即完成。

**自检**：在本课示例里复现「等一组任务结束」，改成计数归零即完成后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：取消、超时、传请求级数据

**症状**：`context`。

**根因与修复**：标准做法，能层层传递。

**自检**：在本课示例里复现「取消、超时、传请求级数据」，改成标准做法，能层层传递后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：限制并发数量

**症状**：带缓冲 channel 当信号量。

**根因与修复**：简洁可控。

**自检**：在本课示例里复现「限制并发数量」，改成简洁可控后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：向已关闭的 channel 发送

**症状**：panic。

**根因与修复**：只让发送方关，先关闭再停止发送。

**自检**：在本课示例里复现「向已关闭的 channel 发送」，改成只让发送方关，先关闭再停止发送后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：重复关闭

**症状**：panic。

**根因与修复**：用 `sync.Once` 或明确单一关闭方。

**自检**：在本课示例里复现「重复关闭」，改成用 `sync.Once` 或明确单一关闭方后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：没人接收就发送

**症状**：全部 goroutine 阻塞，报 deadlock。

**根因与修复**：保证有接收方或改成带缓冲。

**自检**：在本课示例里复现「没人接收就发送」，改成保证有接收方或改成带缓冲后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：忘了 `wg.Add`

**症状**：`Wait` 立刻返回。

**根因与修复**：起 goroutine 前先 Add。

**自检**：在本课示例里复现「忘了 `wg.Add`」，改成起 goroutine 前先 Add后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`Go 基础`。本课默认这些内容已经掌握。
- **相关或后续**：`Go 接口与错误处理`。本课术语会在这些课程里继续使用。
- **术语归属**：`context.WithTimeout`、`sync.WaitGroup`、`Go` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《Go 第一个程序》也涉及 `Go`；两课衔接时先确认这个术语的定义是否一致。
- 同一分类的《Go 变量与输入》也涉及 `Go`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `Go 基础`：共享术语 `Go`，共同关键词 `Go`、`goroutine`、`channel`。
- `Go 接口与错误处理`：共享术语 `Go`，共同关键词 `Go`。

### 容易混淆的相邻概念

- `context.WithTimeout` 与 `sync.WaitGroup`：前者强调 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`；后者强调 等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `sync.WaitGroup` 与 `Go`：前者强调 等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait；后者强调 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `Go` 与 `数据竞争`：前者强调 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利；后者强调 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `context.WithTimeout` 的操作性定义，并说明它与 `sync.WaitGroup` 的区别。

**参考答案**：超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`。

`sync.WaitGroup` 的定位是：等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「传递数据、串起流水线」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是channel；正确做法是数据流向清晰。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `go` 示例，把其中的 `2` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `go` 示例应当复现正文给出的结果；把 `2` 换成边界值后，如果结果改变或报错，先核对它是否满足 `Go 并发：goroutine、channel 与 context` 中`context.WithTimeout` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `go` 示例，说明它体现了`context.WithTimeout` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`context.WithTimeout` 的定义是 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`，示例正是在实现这条定义。改动与 `context.WithTimeout` 有关的一个输入后，如果结果不再符合 `Go 并发：goroutine、channel 与 context` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `Go 并发：goroutine、channel 与 context` 的方法迁移到自己的项目：围绕 `context.WithTimeout` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「goroutine 内 panic 未捕获」，它会导致整个进程崩溃；检验方式是按在 recover 中兜住并记录日志改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `context.WithTimeout` 与 `sync.WaitGroup`：各写一行适用场景、一行失败表现。

**参考答案**：`context.WithTimeout` 的定义是超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`；`sync.WaitGroup` 的定义是等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「传递数据、串起流水线」引发的问题，请把“复现 channel → 保留证据 → 数据流向清晰 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按channel复现；第二步记录输入、版本与完整报错；第三步按数据流向清晰只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `数据竞争`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 同时要把 `数据竞争` 的定义 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `context.WithTimeout` → `sync.WaitGroup` → `Go` → `数据竞争` 的作用链。

**参考答案**：起点是 `context.WithTimeout` 的定义 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`；中间每一步都保留可观察状态；终点由 `数据竞争` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `Go 并发：goroutine、channel 与 context` 中，现象是 整个进程崩溃。请围绕 goroutine 内 panic 未捕获 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 goroutine 内 panic 未捕获，记录输入与完整错误；再按 在 recover 中兜住并记录日志 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `Go 并发：goroutine、channel 与 context`：先给主问题，再按顺序说出 `context.WithTimeout`、`sync.WaitGroup`、`Go`、`数据竞争`，最后给一个失败案例。

**自评标准**：主问题必须对应 channel 通信、worker pool、context 取消与竞态检测；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `context.WithTimeout` | 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`。 |
| `sync.WaitGroup` | 等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait。 |
| `Go` | 由 Google 设计的静态编译语言，强调简单语法、并发和部署便利。 |
| `数据竞争` | 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。 |

**术语关系**：`context.WithTimeout`（超时与取消**：`context.WithTimeout` 传递取消信号） → `sync.WaitGroup`（等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait） → `Go`（由 Google 设计的静态编译语言） → `数据竞争`（多个 goroutine 无同步地读写同一变量）。

## 考点精讲

`Go 并发：goroutine、channel 与 context` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：向已关闭的 channel 发送数据会？
- **正确项**：panic
- **判断依据**：这道题检验本课主问题：channel 通信、worker pool、context 取消与竞态检测。若写成 向已关闭的 channel 发送 就会panic，应按 只让发送方关，先关闭再停止发送 处理。

### 考点 2：第 2 题

- **题目**：`Go 并发：goroutine、channel 与 context` 的示例代码用于验证 `context.WithTimeout`，其背景是channel 通信、worker pool、context 取消与竞态检测。代码的真实内容是下面哪一项？
- **正确项**：调用了 `make()`
- **判断依据**：这道题落在术语 `context.WithTimeout` 上：超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`。复习时把 `context.WithTimeout` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：检测数据竞争的官方手段是？
- **正确项**：go test -race
- **判断依据**：这道题落在术语 `数据竞争` 上：多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。复习时把 `数据竞争` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：向无缓冲 channel 发送数据会阻塞，直到？
- **正确项**：有接收方准备好接收
- **判断依据**：这道题检验本课主问题：channel 通信、worker pool、context 取消与竞态检测。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 5：第 5 题

- **题目**：围绕“Go 并发：goroutine、channel 与 context”中的 Go、goroutine、channel，下列哪两项是本课强调的实践判断？
- **正确项**：验证 goroutine 时要固定版本并覆盖边界输入，结论才可复现；学习 Go 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `Go` 上：由 Google 设计的静态编译语言，强调简单语法、并发和部署便利。复习时把 `Go` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `channel 通信、worker pool、context 取消与竞态检测。`，这段说明是：等待一组任务**：``____`` 的 Add/Done/Wait。空缺处应填哪个术语？
- **正确项**：sync.WaitGroup
- **判断依据**：这道题落在术语 `sync.WaitGroup` 上：等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait。复习时把 `sync.WaitGroup` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`context.WithTimeout`

- **要点**：超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`。
- **context.WithTimeout 的边界**：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。

### 考点 8：`sync.WaitGroup`

- **要点**：等待一组任务**：`sync.WaitGroup` 的 Add/Done/Wait。
- **sync.WaitGroup 的边界**：易错：`sync.WaitGroup`；正确做法是计数归零即完成。

### 考点 9：`Go`

- **要点**：由 Google 设计的静态编译语言，强调简单语法、并发和部署便利。
- **Go 的边界**：易错：所有 goroutine 用同一个值；正确做法是Go 1.22 已修复，旧版本要 `v := v`。

### 考点 10：`数据竞争`

- **要点**：多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。
- **数据竞争 的边界**：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

### 考点 11：排错——传递数据、串起流水线

- **现象**：channel。
- **处理**：数据流向清晰。

### 考点 12：排错——保护一个计数器或缓存

- **现象**：`sync.Mutex` / `atomic`。
- **处理**：比开 channel 更直接。

### 考点 13：综合辨析——`context.WithTimeout` 与 `数据竞争`

- **辨析点**：`context.WithTimeout` 的定义是 超时与取消**：`context.WithTimeout` 传递取消信号，所有阻塞操作都要监听 `ctx.Done()`；`数据竞争` 的定义是 多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。
- **答题要求**：面对 `Go 并发：goroutine、channel 与 context` 的题目，先判断描述的是 `context.WithTimeout` 还是 `数据竞争`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 channel，而不是只写“程序有错”。
- **证据分**：保留触发 传递数据、串起流水线 的输入、版本和错误原文。
- **修复分**：按 数据流向清晰 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Go 1.24+
；本课聚焦 Go。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Go、goroutine、channel、context、race
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：Go、goroutine、channel、context、race。

| 参考资料 | 本课用途 |
| --- | --- |
| [Go 并发](https://go.dev/talks/2012/concurrency.slide) | goroutine 与 channel |
| [Go 内存模型](https://go.dev/ref/mem) | 并发读写与同步语义 |
| [Effective Go](https://go.dev/doc/effective_go) | 惯用写法与接口设计 |

| [本课术语索引：Go 并发：goroutine、channel 与 context](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「Go 并发：goroutine、channel 与 context」的链接用于离线阅读后的延伸核对；App 不会自动联网。