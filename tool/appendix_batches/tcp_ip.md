## TCP 状态速查

| 状态 | 出现位置 | 含义 |
| --- | --- | --- |
| `LISTEN` | 服务端 | 等待连接 |
| `SYN_SENT` | 客户端 | 已发 SYN，等 SYN+ACK |
| `SYN_RCVD` | 服务端 | 收到 SYN 并回复，等 ACK |
| `ESTABLISHED` | 双方 | 连接已建立，可传数据 |
| `FIN_WAIT_1` / `FIN_WAIT_2` | 主动关闭方 | 已发 FIN，等待对方确认或关闭 |
| `CLOSE_WAIT` | 被动关闭方 | 收到 FIN，等应用程序调用 `close` |
| `LAST_ACK` | 被动关闭方 | 已发 FIN，等最后 ACK |
| `TIME_WAIT` | 主动关闭方 | 等 2MSL，确保对方收到 ACK、旧报文消散 |
| `CLOSED` | 双方 | 连接完全结束 |

`CLOSE_WAIT` 堆积说明应用忘记关闭连接；`TIME_WAIT` 过多通常来自短连接，可以复用连接或调整内核参数。

## 握手挥手速查

| 阶段 | 报文 | 关键信息 |
| --- | --- | --- |
| 三次握手 1 | SYN | 客户端初始序号 seq=x |
| 三次握手 2 | SYN + ACK | 服务端 seq=y，ack=x+1 |
| 三次握手 3 | ACK | 客户端 ack=y+1，连接建立 |
| 四次挥手 1 | FIN | 主动方不再发送数据 |
| 四次挥手 2 | ACK | 被动方确认收到 |
| 四次挥手 3 | FIN | 被动方数据也发完 |
| 四次挥手 4 | ACK | 主动方确认，进入 TIME_WAIT |

## 排查命令速查

| 目的 | 命令 | 说明 |
| --- | --- | --- |
| 看连接状态统计 | `ss -s` | 各类 socket 数量总览 |
| 看 TCP 连接列表 | `ss -tanp` | `-p` 显示进程，`-t` 只看 TCP |
| 看监听端口 | `ss -tlnp` | 确认服务是否真的在监听 |
| 统计 TIME_WAIT | `ss -tan \| awk '{print $1}' \| sort \| uniq -c` | 判断短连接是否过多 |
| 看丢包与重传 | `netstat -s \| grep -i retrans` | 重传率高说明网络质量差 |
| 抓包看三次握手 | `tcpdump -i any port 8080 -w a.pcap` | 用 Wireshark 逐包分析 |
| 测连通与延迟 | `ping`、`mtr` | `mtr` 能看每一跳丢包 |
| 测端口可达 | `nc -zv host port` | 快速验证防火墙与监听 |

## 常见错误对照表

| 现象 | 常见原因 | 处理方式 |
| --- | --- | --- |
| 连接建立失败、`Connection refused` | 服务未监听或端口不对 | `ss -tlnp` 确认监听地址与端口 |
| 连接一直卡住、`timeout` | 防火墙丢包或路由不可达 | 用 `nc` 与 `mtr` 逐段排查 |
| `CLOSE_WAIT` 大量堆积 | 代码没关闭连接 | 检查 `finally` 中是否 `close`，连接池是否泄漏 |
| `TIME_WAIT` 大量堆积 | 频繁短连接 | 启用长连接与连接池，必要时调整内核参数 |
| 请求偶发超时、重传高 | 网络抖动或 MTU 不匹配 | 抓包看重传，检查 MTU 与中间设备 |
| 大量连接时服务端拒绝 | `backlog` 太小 | 调大 `listen` 的 backlog 与 `somaxconn` |
| 延迟忽高忽低 | 启用了 Nagle 与小包混合 | 交互场景开启 `TCP_NODELAY` |
| 上传大文件中途失败 | 中间设备超时断开 | 加心跳、分块重传与断点续传 |

## 自测清单

- [ ] 能画出三次握手与四次挥手，并说出每步序号变化。
- [ ] 知道 `TIME_WAIT` 存在的原因，以及它与 `CLOSE_WAIT` 的区别。
- [ ] 会用 `ss` 查看监听端口、连接状态与所属进程。
- [ ] 排查连接问题时会先确认「服务是否监听、网络是否可达」。
- [ ] 知道 `TCP_NODELAY` 与 Nagle 算法的取舍。
