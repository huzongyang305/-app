## 常用选项速查

| 选项 | 作用 |
| --- | --- |
| `SO_REUSEADDR` | 允许复用处于 TIME_WAIT 的端口，便于快速重启 |
| `SO_REUSEPORT` | 多进程监听同一端口做负载均衡（Linux） |
| `SO_KEEPALIVE` | 开启 TCP 保活探测（默认 2 小时，通常需调） |
| `TCP_NODELAY` | 关闭 Nagle 算法，降低小包延迟 |
| `TCP_CORK` | 尽量聚合小包后一次发送（与 NODELAY 相反） |
| `SO_RCVBUF` / `SO_SNDBUF` | 收发缓冲区大小 |
| `TCP_QUICKACK` | 立即确认，降低延迟 |
| `SO_LINGER` | 控制 close 行为（慎用，可能产生 RST） |

## 粘包与半包速查

| 方案 | 说明 | 适用 |
| --- | --- | --- |
| 固定长度 | 每帧长度固定 | 定长协议 |
| 分隔符 | 如换行、`\r\n` | 文本协议 |
| 长度前缀 | 前 4 字节表示长度 | 二进制协议，最通用 |
| 自描述格式 | Protobuf、MessagePack 自带结构 | RPC |

注意：TCP 是字节流，没有消息边界；UDP 有数据报边界但会丢包与乱序。

```python
import socket
import struct
import threading

def send_message(sock: socket.socket, payload: bytes) -> None:
    """长度前缀协议：4 字节大端长度 + 内容。"""
    sock.sendall(struct.pack("!I", len(payload)) + payload)


def recv_exactly(sock: socket.socket, size: int) -> bytes:
    """读取恰好 size 字节，处理半包。"""
    chunks, remaining = [], size
    while remaining > 0:
        chunk = sock.recv(remaining)
        if not chunk:
            raise ConnectionError("连接已关闭")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def recv_message(sock: socket.socket) -> bytes:
    """按长度前缀读取一条完整消息。"""
    header = recv_exactly(sock, 4)
    (length,) = struct.unpack("!I", header)
    if length > 8 * 1024 * 1024:
        raise ValueError("消息过大，拒绝处理")
    return recv_exactly(sock, length)


def start_echo_server(host="127.0.0.1", port=0, backlog=128):
    """带 backlog 与超时的最小服务端，返回监听端口。"""
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(backlog)
    bound_port = server.getsockname()[1]

    def serve():
        conn, _ = server.accept()
        with conn:
            conn.settimeout(5)
            data = recv_message(conn)
            send_message(conn, data.upper())
        server.close()

    threading.Thread(target=serve, daemon=True).start()
    return bound_port


port = start_echo_server()
client = socket.create_connection(("127.0.0.1", port), timeout=3)
try:
    send_message(client, b"hello socket")
    print(recv_message(client))
finally:
    client.close()
```

## IO 多路复用速查

| 机制 | 复杂度 | 特点 |
| --- | --- | --- |
| `select` | O(n) | 有 FD 数量上限，跨平台 |
| `poll` | O(n) | 无上限，仍要遍历 |
| `epoll`（Linux） | O(1) 事件就绪 | 水平与边缘触发，适合高并发 |
| `kqueue`（BSD/macOS） | O(1) | 功能类似 epoll |
| IOCP（Windows） | 完成通知 | 真正的异步 IO 模型 |

边缘触发（ET）必须一次读到 `EAGAIN`，否则事件不再通知；水平触发（LT）未读完会持续通知，更容易写对。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为一次 `recv` 能拿到完整消息 | 偶发解析失败 | TCP 是字节流，必须处理半包 |
| 用 `send` 不检查返回值 | 数据被截断 | 用 `sendall` 或循环发送 |
| 忘记设置超时 | 请求永久挂起 | 设置连接与读写超时 |
| 无长度上限 | 被超大消息打爆内存 | 校验长度并设上限 |
| ET 模式只读一次 | 数据滞留、连接假死 | 循环读到 `EAGAIN` |
| 忘记关闭连接 | 句柄泄漏 | `with` 或 `finally` 关闭 |
| 不做心跳 | 半开连接长期占用 | 应用层心跳 + 超时回收 |
| 多进程监听同一端口用 REUSEADDR | 仍只有一个进程收到连接 | 用 `SO_REUSEPORT` |
| 盲目开启 `SO_LINGER=0` | 直接发 RST，对端丢失数据 | 一般保持默认关闭流程 |
| 忽视字节序 | 跨平台解析错误 | 网络字节序统一用大端 |

## 自测清单

- [ ] 能实现长度前缀协议并正确处理半包。
- [ ] 所有连接都有超时与大小上限。
- [ ] 知道 `SO_REUSEADDR` 与 `SO_REUSEPORT` 的区别。
- [ ] 理解 ET 与 LT 的差异及 ET 的读法要求。
- [ ] 会用连接池或长连接减少握手开销。
