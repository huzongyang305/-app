## 零基础详解：gRPC 与 Protobuf

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
