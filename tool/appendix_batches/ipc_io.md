## 进程间通信对照

| 方式 | 方向 | 速度 | 适用 |
| --- | --- | --- | --- |
| 管道 pipe | 单向 | 快 | 父子进程流式传输 |
| 命名管道 FIFO | 单向 | 快 | 无亲缘关系进程 |
| 消息队列 | 有边界消息 | 中 | 结构化消息、解耦 |
| 共享内存 | 双向 | 最快 | 大数据量高频交换 |
| 信号量 | 同步 | 快 | 保护共享内存 |
| 信号 signal | 通知 | 快 | 终止、重载配置 |
| Unix 域套接字 | 双向 | 快 | 本地服务通信、可传 fd |
| TCP 套接字 | 双向 | 较慢 | 跨主机 |

## IO 模型对照

| 模型 | 等待数据 | 拷贝数据 | 特点 |
| --- | --- | --- | --- |
| 阻塞 IO | 阻塞 | 阻塞 | 最简单，一连接一线程 |
| 非阻塞 IO | 轮询 | 阻塞 | 需配合多路复用 |
| IO 多路复用 | 阻塞在 select/epoll | 阻塞 | 单线程管理大量连接 |
| 信号驱动 IO | 回调通知 | 阻塞 | 使用较少 |
| 异步 IO（AIO / IOCP） | 不阻塞 | 不阻塞 | 完成后通知，编程模型复杂 |

```python
import os
import select
import socket
import time

def pipe_demo():
    """管道：父进程读、子进程写。"""
    read_fd, write_fd = os.pipe()
    pid = os.fork()
    if pid == 0:
        os.close(read_fd)
        os.write(write_fd, b"child message")
        os.close(write_fd)
        os._exit(0)
    os.close(write_fd)
    data = os.read(read_fd, 1024)
    os.close(read_fd)
    os.waitpid(pid, 0)
    return data.decode()

def socketpair_demo():
    """Unix 域套接字对：双向通信，适合本地进程协作。"""
    left, right = socket.socketpair()
    try:
        left.sendall(b"ping")
        return right.recv(16)
    finally:
        left.close()
        right.close()

def epoll_echo(port: int = 0, timeout: float = 2.0):
    """epoll 边缘触发：一次读到 EAGAIN 为止。"""
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", port))
    server.listen(64)
    server.setblocking(False)
    epoll = select.epoll()
    epoll.register(server.fileno(), select.EPOLLIN)
    events, handled = [], 0
    deadline = time.monotonic() + timeout
    try:
        while time.monotonic() < deadline and handled == 0:
            for fileno, mask in epoll.poll(0.5):
                if fileno == server.fileno():
                    conn, _ = server.accept()
                    conn.setblocking(False)
                    epoll.register(conn.fileno(), select.EPOLLIN | select.EPOLLET)
                else:
                    conn = socket.socket(fileno=fileno)
                    try:
                        while True:                      # ET 必须读到 EAGAIN
                            chunk = conn.recv(4096)
                            if not chunk:
                                break
                            events.append(chunk)
                            handled += 1
                    except BlockingIOError:
                        pass
                    finally:
                        conn.close()
    finally:
        epoll.close()
        server.close()
    return events

print(socketpair_demo())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 共享内存不加同步 | 数据竞争与脏读 | 用信号量或互斥量保护 |
| 管道写入超过缓冲区 | 写阻塞或部分写 | 分段写入并处理部分写 |
| 忘记关闭无用文件描述符 | 描述符泄漏 | 关闭所有不用的 fd |
| epoll 用水平触发却只读一次 | 反复触发 | 一次读尽或改用 ET |
| ET 模式未读到 EAGAIN | 后续事件不再通知 | 循环读到 `EAGAIN` |
| 忽略 EINTR | 系统调用被信号中断 | 重试被中断的调用 |
| 用信号传递复杂数据 | 丢失且不可靠 | 信号只做通知，数据走队列或共享内存 |
| 僵尸进程堆积 | 资源泄漏 | `waitpid` 回收子进程 |
| 用 TCP 做本机通信 | 多余协议栈开销 | 优先 Unix 域套接字 |
| 无限扩张消息队列 | 内存耗尽 | 设上限与背压策略 |

## 自测清单

- [ ] 能按场景选择管道、共享内存、消息队列或套接字。
- [ ] 能区分阻塞、非阻塞、多路复用与异步 IO。
- [ ] 共享内存访问有同步保护。
- [ ] ET 模式下读到 `EAGAIN`。
- [ ] 子进程被正确回收，无僵尸进程。
