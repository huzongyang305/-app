# gRPC 与 Protobuf 实践

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![gRPC 的四种调用方式](images/diagram_go_grpc.webp)

![gRPC 与 Protobuf 实践](images/remaining_go_grpc.webp)

## 本节知识框架

**课程定位**：所属分类为「Go」，课程主题为「gRPC 与 Protobuf 实践」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：四种调用方式、契约演进规则与拦截器工程实践。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「gRPC 与 Protobuf 实践」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「gRPC 与 Protobuf 实践」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「gRPC」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Go 性能剖析与调优实战》

**学习位置**：本课位于《Go 性能剖析与调优实战》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Go 测试进阶：基准、模糊与集成》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释gRPC 与 Protobuf 实践解决了什么问题，而不是只背术语。
- 能说清 「gRPC」、「Protobuf」、「流式」、「契约」 之间的关系，并分别举出一个例子。
- 能把 gRPC 放回「gRPC 与 Protobuf 实践」的知识体系，说明它和 Protobuf 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：四种调用方式、契约演进规则与拦截器工程实践。

**教材衔接：前置知识**

- 先完成上一课《Go 性能剖析与调优实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Go 性能剖析与调优实战」，或确认自己能独立跑通正文里的 OrderService 示例。
- 开始前先复习：gRPC、Protobuf、流式。
- 如果 与 REST 的取舍速查 这一步看不懂，先记录具体卡点，再用 OrderService 复现一遍。

**教材衔接：本课小结**

- 核心问题：gRPC 与 Protobuf 实践不是孤立术语，而是在「Go」中解决一类具体问题。
- 关键关系：先分清「gRPC」与「Protobuf」的职责，再理解「流式」的适用边界。
- 判断标准：能举出 Protobuf 的一个反例并解释原因。
- 下一步：把 OrderService 的实验结论记成三句话，然后进入测验。

## 核心概念定义

> 阅读约定：本课先给「gRPC 与 Protobuf 实践」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| gRPC | gRPC 是「用接口定义文件驱动」的服务间通信方式：先写 .proto，再自动生成客户端与服务端代码。 | 仅在「gRPC 与 Protobuf 实践」明确给出的输入、版本与资源条件下成立。 |
| Protocol Buffers | gRPC 默认的接口定义与序列化格式，用 .proto 描述消息与服务之后生成代码。 | 仅在「gRPC 与 Protobuf 实践」明确给出的输入、版本与资源条件下成立。 |
| 一元 RPC | 一次请求对应一次响应的调用模型，最简单也最常用。 | 仅在「gRPC 与 Protobuf 实践」明确给出的输入、版本与资源条件下成立。 |
| 流式 RPC | 客户端流、服务端流或双向流，用同一条连接连续发送多条消息。 | 仅在「gRPC 与 Protobuf 实践」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「gRPC 与 Protobuf 实践」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「gRPC」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「Protocol Buffers」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「一元 RPC」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「gRPC 与 Protobuf 实践」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | gRPC | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | Protocol Buffers | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 一元 RPC | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「gRPC 与 Protobuf 实践」自己的示例验证。「gRPC 与 Protobuf 实践」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：与 REST 的取舍速查**

| 维度 | gRPC | REST + JSON |
| --- | --- | --- |
| 协议 | HTTP/2 加 Protobuf | HTTP/1.1 或 2 加 JSON |
| 契约 | `.proto` 强类型 | OpenAPI 或约定 |
| 代码生成 | 客户端与服务端都生成 | 通常只生成客户端 |
| 性能 | 序列化小、支持多路复用与流式 | 可读性好、调试方便 |
| 浏览器支持 | 需 grpc-web 代理 | 原生支持 |
| 适用 | 内部服务间高频调用 | 对外接口、第三方集成 |

经验：**内部服务用 gRPC，对外接口用 REST**；需要双向流式时优先 gRPC。

**教材衔接：工程实践速查**

| 主题 | 做法 |
| --- | --- |
| 契约演进 | 只做向后兼容变更：加字段、不改字段号、不删必填 |
| 字段编号 | 一经使用不可复用，废弃字段用 `reserved` |
| 超时与重试 | 客户端设置 deadline；只重试幂等方法 |
| 错误模型 | 用标准状态码加结构化 details，而不是靠字符串 |
| 拦截器 | 统一处理日志、鉴权、限流、恢复 panic |
| 负载均衡 | 客户端侧 LB 或服务网格，注意长连接复用 |
| 可观测 | 透传 trace id，记录方法名、状态码与耗时 |
| 兼容浏览器 | 通过 grpc-web 或网关转 REST |

**教材衔接：版本与时效**

- 升级「gRPC 与 Protobuf 实践」涉及的依赖前，先用 OrderService 复现当前行为，再逐项核对版本说明与破坏性变更。
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 OrderService 记录构建与运行结果。
- 升级后重点回归 gRPC 的默认值、警告信息与错误格式。
- 升级后把 OrderService 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 gRPC、Protobuf | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「gRPC 与 Protobuf 实践」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「gRPC 与 Protobuf 实践」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:go`，用于动手验证《gRPC 与 Protobuf 实践》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《gRPC 与 Protobuf 实践》原文中的最小示例。先预测《gRPC 与 Protobuf 实践》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```protobuf
syntax = "proto3";

package order.v1;

option go_package = "example.com/api/gen/order/v1;orderv1";

service OrderService {
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse);
  rpc ListOrders(ListOrdersRequest) returns (stream Order);
  rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse);
}

message GetOrderRequest {
  int64 id = 1;
}

message Order {
  int64 id = 1;
  int64 user_id = 2;
  string status = 3;
  int64 amount_cents = 4;
}

message GetOrderResponse {
  Order order = 1;
}
```

**教材衔接：四种调用方式**

| 方式 | 语义 | 适用 |
| --- | --- | --- |
| Unary | 一问一答 | 普通 RPC |
| Server streaming | 一个请求多个响应 | 大结果集、日志推送 |
| Client streaming | 多个请求一个响应 | 批量上传、聚合计算 |
| Bidirectional | 双向流 | 实时通信、协作编辑 |

```protobuf
syntax = "proto3";

package order.v1;

option go_package = "example.com/api/gen/order/v1;orderv1";

service OrderService {
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse);
  rpc ListOrders(ListOrdersRequest) returns (stream Order);
  rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse);
}

message GetOrderRequest {
  int64 id = 1;
}

message Order {
  int64 id = 1;
  int64 user_id = 2;
  string status = 3;
  int64 amount_cents = 4;
}

message GetOrderResponse {
  Order order = 1;
}
```

```go
// 服务端要点：参数校验、标准错误码、明确区分内部错误
func (s *orderServer) GetOrder(ctx context.Context, req *orderv1.GetOrderRequest) (
	*orderv1.GetOrderResponse, error) {
	if req.GetId() <= 0 {
		return nil, status.Error(codes.InvalidArgument, "id 必须为正")
	}
	order, err := s.repo.Find(ctx, req.GetId())
	if errors.Is(err, ErrNotFound) {
		return nil, status.Error(codes.NotFound, "订单不存在")
	}
	if err != nil {
		return nil, status.Error(codes.Internal, "查询失败")
	}
	return &orderv1.GetOrderResponse{Order: toProto(order)}, nil
}

// 客户端要点：每次调用都带超时与元数据
func FetchOrder(client orderv1.OrderServiceClient, id int64) (*orderv1.Order, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 800*time.Millisecond)
	defer cancel()
	ctx = metadata.AppendToOutgoingContext(ctx, "x-request-id", requestID())

	resp, err := client.GetOrder(ctx, &orderv1.GetOrderRequest{Id: id})
	if err != nil {
		return nil, fmt.Errorf("GetOrder(%d): %w", id, err)
	}
	return resp.GetOrder(), nil
}
```

**教材衔接：零基础详解：gRPC 与 Protobuf**

### 一句话说清它是什么

gRPC 是「用接口定义文件驱动」的服务间通信方式：先写 `.proto`，再自动生成客户端与服务端代码。
它基于 HTTP/2 + Protobuf，天然支持强类型与流式调用。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `.proto` | 合同模板 | 双方都按它生成代码 |
| Protobuf | 压缩表格 | 比 JSON 更小更快 |
| 生成代码 | 双方的对讲机 | 不用手写序列化 |
| 一元调用 | 一问一答 | 最常见的模式 |
| 流式调用 | 持续通话 | 单向或双向持续传数据 |
| 拦截器 | 安检 | 统一做日志、鉴权、超时 |

### 一个完整的 proto 文件

```protobuf
syntax = "proto3";

package user.v1;

option go_package = "example.com/myapp/gen/user/v1;userv1";

message GetUserRequest {
  int64 id = 1;
}

message User {
  int64 id = 1;
  string name = 2;
  string email = 3;
}

service UserService {
  rpc GetUser(GetUserRequest) returns (User);
  rpc ListUsers(ListUsersRequest) returns (stream User);   // 服务端流
}
```

| 要点 | 说明 |
| --- | --- |
| 字段编号 | 一旦发布不要改，改了就不兼容 |
| `package` | 带版本号，便于演进（`user.v1`） |
| 保留字段 | 删除字段时用 `reserved` 占位，防止被复用 |

### 生成代码与运行

```bash
# 安装工具
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# 生成
protoc --go_out=. --go-grpc_out=. proto/user.proto

# 或用 buf（更现代，配置集中）
buf generate
```

### 服务端实现

```go
type Server struct {
    userv1.UnimplementedUserServiceServer     // 向前兼容：以后加方法不会编译失败
    store *Store
}

func (s *Server) GetUser(ctx context.Context, req *userv1.GetUserRequest) (*userv1.User, error) {
    if req.GetId() <= 0 {
        return nil, status.Error(codes.InvalidArgument, "id 必须为正数")
    }

    u, err := s.store.Find(ctx, req.GetId())
    if errors.Is(err, ErrNotFound) {
        return nil, status.Error(codes.NotFound, "用户不存在")
    }
    if err != nil {
        return nil, status.Error(codes.Internal, "内部错误")
    }
    return &userv1.User{Id: u.ID, Name: u.Name, Email: u.Email}, nil
}

func main() {
    lis, _ := net.Listen("tcp", ":50051")
    s := grpc.NewServer(
        grpc.UnaryInterceptor(LoggingInterceptor),
    )
    userv1.RegisterUserServiceServer(s, &Server{})
    log.Fatal(s.Serve(lis))
}
```

### 状态码：别只会 return err

| 码 | 含义 | 使用场景 |
| --- | --- | --- |
| `OK` | 成功 | 正常返回 |
| `InvalidArgument` | 参数错误 | 校验失败 |
| `NotFound` | 不存在 | 资源没找到 |
| `AlreadyExists` | 已存在 | 唯一键冲突 |
| `PermissionDenied` | 无权限 | 越权访问 |
| `Unauthenticated` | 未认证 | token 无效 |
| `DeadlineExceeded` | 超时 | 上游超时 |
| `Unavailable` | 暂时不可用 | 下游挂了 |
| `Internal` | 内部错误 | 未预期异常 |

**要点**：不要用 `Internal` 表示「用户不存在」，客户端需要靠状态码决定要不要重试。

### 客户端调用与超时

```go
conn, err := grpc.NewClient("localhost:50051",
    grpc.WithTransportCredentials(insecure.NewCredentials()))
if err != nil {
    return err
}
defer conn.Close()

client := userv1.NewUserServiceClient(conn)

ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

user, err := client.GetUser(ctx, &userv1.GetUserRequest{Id: 1})
if err != nil {
    st, ok := status.FromError(err)
    if ok && st.Code() == codes.NotFound {
        return ErrNotFound
    }
    return fmt.Errorf("调用失败: %w", err)
}
```

### gRPC 与 REST 怎么选

| 维度 | gRPC | REST + JSON |
| --- | --- | --- |
| 性能 | 高（二进制、多路复用） | 一般 |
| 类型安全 | 强（代码生成） | 弱（手写类型） |
| 浏览器支持 | 需 grpc-web | 原生支持 |
| 可调试性 | 需专门工具 | curl 即可 |
| 适合 | **服务间内部调用** | 对外公开 API |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 改已发布字段编号 | 线上数据错乱 | 编号永不复用，用 `reserved` |
| 用 `Internal` 表示业务错误 | 客户端无法正确处理 | 用语义化状态码 |
| 不设超时 | 调用永久挂起 | 全部带 context 超时 |
| 直接在循环里逐个调用 | N 次往返，慢 | 用流式或批量接口 |
| 忘记实现 `Unimplemented` 嵌入 | 加方法后编译失败 | 嵌入它保证向前兼容 |
| 大消息单次传输 | 内存暴涨 | 用流式或分页 |
| 拦截器里做重活 | 每个请求都慢 | 只做轻量横切逻辑 |
| 用 gRPC 直接对外 | 浏览器与调试困难 | 对外暴露 REST 或 grpc-web |

### 手把手练习：带分页的列表接口

```protobuf
message ListUsersRequest {
  int32 page = 1;
  int32 size = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
}

service UserService {
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
}
```

```go
func (s *Server) ListUsers(ctx context.Context, req *userv1.ListUsersRequest) (*userv1.ListUsersResponse, error) {
    page, size := int(req.GetPage()), int(req.GetSize())
    if page < 1 {
        page = 1
    }
    if size <= 0 || size > 100 {
        size = 20
    }

    users, total, err := s.store.List(ctx, page, size)
    if err != nil {
        return nil, status.Error(codes.Internal, "查询失败")
    }

    out := make([]*userv1.User, 0, len(users))
    for _, u := range users {
        out = append(out, &userv1.User{Id: u.ID, Name: u.Name, Email: u.Email})
    }
    return &userv1.ListUsersResponse{Users: out, Total: int32(total)}, nil
}
```

### 学完自测

- [ ] 能说出 gRPC 相比 REST 的三个优势与两个劣势。
- [ ] 知道为什么 proto 字段编号不能复用。
- [ ] 能说出 `NotFound` 与 `Internal` 的区别。
- [ ] 知道客户端为什么必须设超时。
- [ ] 能说出 `Unimplemented...Server` 的作用。

## 时间/空间复杂度或性能分析

**复杂度证据**：「gRPC 与 Protobuf 实践」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「gRPC 与 Protobuf 实践」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「gRPC 与 Protobuf 实践」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《gRPC 与 Protobuf 实践》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「gRPC 与 Protobuf 实践」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 修改已用字段编号 | 新旧版本解析错乱 | 编号不可复用，废弃用 `reserved` |
| 不设 deadline | 请求无限挂起 | 每次调用都带超时 |
| 用错误字符串区分错误类型 | 调用方无法可靠判断 | 使用标准 status code |
| 拦截器 recover 后不记录 | 问题被隐藏 | 记录堆栈并返回 Internal |
| 流式接口无背压处理 | 内存暴涨 | 控制发送速率与缓冲 |
| 大消息不分片 | 超限或内存问题 | 拆分或改用流式 |
| 直接对外暴露 gRPC | 浏览器与第三方难接入 | 加网关或提供 REST 接口 |

**教材衔接：故障现场**

### 现场 1：修改已用字段编号

**症状**：在《gRPC 与 Protobuf 实践》的复现场景中，新旧版本解析错乱。

**根因**：触发点是把“修改已用字段编号”当成安全做法。它没有满足《gRPC 与 Protobuf 实践》要求的前提，因此先表现为“新旧版本解析错乱”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《gRPC 与 Protobuf 实践》的问题，编号不可复用，废弃用 reserved。

**验证**：在《gRPC 与 Protobuf 实践》中按“编号不可复用，废弃用 reserved”调整后，从“修改已用字段编号”的触发条件重放同一条路径，确认“新旧版本解析错乱”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：不设 deadline

**症状**：在《gRPC 与 Protobuf 实践》的复现场景中，请求无限挂起。

**根因**：当出现“不设 deadline”时，执行路径已经绕过了《gRPC 与 Protobuf 实践》的关键约束，最终以“请求无限挂起”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《gRPC 与 Protobuf 实践》的问题，每次调用都带超时。

**验证**：先在《gRPC 与 Protobuf 实践》中记录“不设 deadline”留下的失败证据，再执行“每次调用都带超时”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：用错误字符串区分错误类型

**症状**：在《gRPC 与 Protobuf 实践》的复现场景中，调用方无法可靠判断。

**根因**：当出现“用错误字符串区分错误类型”时，执行路径已经绕过了《gRPC 与 Protobuf 实践》的关键约束，最终以“调用方无法可靠判断”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《gRPC 与 Protobuf 实践》的问题，使用标准 status code。

**验证**：在《gRPC 与 Protobuf 实践》中按“使用标准 status code”调整后，从“用错误字符串区分错误类型”的触发条件重放同一条路径，确认“调用方无法可靠判断”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Go 性能剖析与调优实战》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Go 并发模式与 errgroup》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Go 性能剖析与调优实战》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Go 测试进阶：基准、模糊与集成》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「gRPC 与 Protobuf 实践」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《gRPC 与 Protobuf 实践》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“gRPC 与 Protobuf 实践”中的 gRPC、Protobuf、流式，下列哪两项是本课强调的实践判断？

A. 把 Protobuf 的单次运行结果当成所有版本和规模都成立
B. 学习 gRPC 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 gRPC 的常规示例通过，就可以跳过边界与异常路径
D. 验证 Protobuf 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 gRPC 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Protobuf 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把gRPC 与 Protobuf 实践拆成概念、示例与故障现场三部分，因此判断 gRPC 时必须同时交代输入、输出和失败路径，这使“学习 gRPC 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在gRPC 与 Protobuf 实践里，判断 Protobuf 时要固定版本与边界输入，所以“验证 Protobuf 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

修改 .proto 时，哪种做法是安全的？

A. 删除字段后复用其编号
B. 把可选字段改成必填
C. 修改已使用字段的编号
D. 新增字段并给新编号

**参考答案**：新增字段并给新编号

**解析**：在「gRPC 与 Protobuf 实践」里，新增字段并给新编号。只有向后兼容的变更（新增字段、不改变已有编号与类型）才能保证新旧版本互通。在「gRPC 与 Protobuf 实践」里判断这道题，要把gRPC、Protobuf、流式的条件、过程与失败路径逐项对齐，换成“修改 .proto 时”这个场景，只有满足前提的结论才成立。

### 自测 3

阅读「gRPC 与 Protobuf 实践」正文里的这段 Go 代码，下面哪一项判断是正确的？

```go
conn, err := grpc.NewClient("localhost:50051",
    grpc.WithTransportCredentials(insecure.NewCredentials()))
if err != nil {
    return err
}
defer conn.Close()

client := userv1.NewUserServiceClient(conn)

ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

user, err := client.GetUser(ctx, &userv1.GetUserRequest{Id: 1})
if err != nil {
    st, ok := status.FromError(err)
    if ok && st.Code() == codes.NotFound {
        return ErrNotFound
    }
    return fmt.Errorf("调用失败: %w", err)
}
```

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码包含循环结构，同一段逻辑会被重复执行。
C. 这段代码包含条件分支，不同输入会走不同的执行路径。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码包含条件分支，不同输入会走不同的执行路径。

**解析**：在「gRPC 与 Protobuf 实践」里，这段代码包含条件分支，不同输入会走不同的执行路径。这段代码出自「gRPC 与 Protobuf 实践」的正文示例，围绕gRPC、Protobuf、流式展开；把输入或边界换成空值、极值或失败情况后，结论要以「gRPC 与 Protobuf 实践」的实际运行结果为准。

**教材衔接：复习与自测**

- [ ] 能说清 gRPC 与 REST 的取舍。
- [ ] 熟悉四种调用方式并会选型。
- [ ] 契约演进遵循向后兼容规则，字段编号不复用。
- [ ] 客户端调用都设置 deadline，错误用标准状态码。
- [ ] 拦截器统一处理日志、鉴权与 panic 恢复。

**教材衔接：动手练习**

> 本课练习重点：围绕「gRPC、Protobuf、流式」完成复述、实验和交付，每个结果都要能被别人检查。

写一个只包含 gRPC 的最小程序，先验证正常路径，再制造一次失败。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. gRPC 与 Protobuf 实践解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Protobuf」是什么关系？

验收标准：说明 gRPC 与 Protobuf 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「与 REST 的取舍速查」小节做一次五步记录，原例取自 OrderService，改动只允许动一处gRPC，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

写一个只包含 gRPC 的最小程序，先验证正常路径，再制造一次失败。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「gRPC」和「Protobuf」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```bash
# 安装工具
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# 生成
protoc --go_out=. --go-grpc_out=. proto/user.proto

# 或用 buf（更现代，配置集中）
buf generate
```

### 任务 2：只改一个条件

把「gRPC 与 Protobuf 实践」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只调整 OrderService 的一个参数，其余条件一律不动。
- 预测：先写下「gRPC 与 Protobuf 实践」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响gRPC。

### 任务 3：迁移到自己的数据

把 OrderService 换成你自己的输入，先保持步骤不变，再比较输出差异。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「内部服务间高频调用，通常优先选择？」的判断依据。
- [ ] 不看解析，能说出「修改 .proto 时，哪种做法是安全的？」的判断依据。
- [ ] 不看解析，能说出「客户端调用 gRPC 时必须注意？」的判断依据。
- [ ] 不看解析，能说出「服务端想把「参数非法」与「内部错误」区分开，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「需要「一次请求、服务端持续推送多条结果」时，应该用？」的判断依据。
- [ ] 跑通「gRPC 与 Protobuf 实践」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `gRPC` | gRPC 是「用接口定义文件驱动」的服务间通信方式：先写 .proto，再自动生成客户端与服务端代码。 |
| `Protocol Buffers` | gRPC 默认的接口定义与序列化格式，用 .proto 描述消息与服务之后生成代码。 |
| `一元 RPC` | 一次请求对应一次响应的调用模型，最简单也最常用。 |
| `流式 RPC` | 客户端流、服务端流或双向流，用同一条连接连续发送多条消息。 |

## 考点精讲

### 考点 1：多选辨析·gRPC

- **题目**：围绕“gRPC 与 Protobuf 实践”中的 gRPC、Protobuf、流式，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把gRPC 与 Protobuf 实践拆成概念、示例与故障现场三部分，因此判断 gRPC 时必须同时交代输入、输出和失败路径，这使“学习 gRPC 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在gRPC 与 Protobuf 实践里，判断 Protobuf 时要固定版本与边界输入，所以“验证 Protobuf 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·gRPC

- **题目**：修改 .proto 时，哪种做法是安全的？
- **判断依据**：在「gRPC 与 Protobuf 实践」里，新增字段并给新编号。只有向后兼容的变更（新增字段、不改变已有编号与类型）才能保证新旧版本互通。在「gRPC 与 Protobuf 实践」里判断这道题，要把gRPC、Protobuf、流式的条件、过程与失败路径逐项对齐，换成“修改 .proto 时”这个场景，只有满足前提的结论才成立。

### 考点 3：概念判断·gRPC

- **题目**：客户端调用 gRPC 时必须注意？
- **判断依据**：在「gRPC 与 Protobuf 实践」里，每次调用都设置 deadline。没有 deadline 的调用可能永久挂起并耗尽连接与协程。把“每次调用都设置 deadline”代回「gRPC 与 Protobuf 实践」里“客户端调用 gRPC 时必须注意”的例子核对，条件一旦改变，结论就要用gRPC、Protobuf、流式重新推导。

### 考点 4：概念判断·参数非法

- **题目**：服务端想把「参数非法」与「内部错误」区分开，正确做法是？
- **判断依据**：在「gRPC 与 Protobuf 实践」里，结论应落在「使用标准 status code」。标准状态码是跨语言可识别的契约，客户端能据此做重试或提示。在「gRPC 与 Protobuf 实践」里判断这道题，要把gRPC、Protobuf、流式的条件、过程与失败路径逐项对齐，换成“服务端想把参数非法与内部错误区分开”这个场景，只有满足前提的结论才成立。

### 考点 5：代码补全·gRPC

- **题目**：阅读「gRPC 与 Protobuf 实践」正文里的这段 Go 代码，下面哪一项判断是正确的？
- **判断依据**：在「gRPC 与 Protobuf 实践」里，这段代码包含条件分支，不同输入会走不同的执行路径。这段代码出自「gRPC 与 Protobuf 实践」的正文示例，围绕gRPC、Protobuf、流式展开；把输入或边界换成空值、极值或失败情况后，结论要以「gRPC 与 Protobuf 实践」的实际运行结果为准。

### 考点 6：填空·gRPC

- **题目**：补全代码：「gRPC 与 Protobuf 实践」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `return nil, status.Error(codes.____, "id 必须为正")`
- **判断依据**：空格应填写「InvalidArgument」、「invalidargument」。这道题的关键在「gRPC 与 Protobuf 实践」的gRPC、Protobuf、流式：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。把“InvalidArgument”代回「gRPC 与 Protobuf 实践」里“gRPC 与 Protobuf 实践示例中”的例子核对，条件一旦改变，结论就要用gRPC、Protobuf、流式重新推导。

## English Overview

**Title:** gRPC & Protobuf

**Summary:** Call types, contract evolution and interceptors.

**Category:** Go
**Level:** 进阶
**Key terms:** gRPC, Protobuf, 流式, 契约, 拦截器, 状态码

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Go 1.24+
；本课聚焦 gRPC。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：gRPC、Protobuf、流式、契约、拦截器、状态码
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Effective Go](https://go.dev/doc/effective_go) | 惯用写法与接口设计 |
| [Go 测试](https://go.dev/doc/tutorial/add-a-test) | 测试、基准与覆盖率 |
| [database/sql](https://pkg.go.dev/database/sql) | 数据库连接、事务与预编译 |

> 「gRPC 与 Protobuf 实践」的链接用于离线阅读后的延伸核对；App 不会自动联网。
