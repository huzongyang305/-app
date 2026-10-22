## 版本对照速查

| 维度 | HTTP/1.1 | HTTP/2 | HTTP/3 |
| --- | --- | --- | --- |
| 传输层 | TCP | TCP | QUIC（基于 UDP） |
| 并发方式 | 多连接或流水线 | 单连接多路复用 | 单连接多路复用（独立流） |
| 队头阻塞 | 有（连接级） | TCP 层仍有 | 基本消除（流级独立） |
| 头部压缩 | 无 | HPACK | QPACK |
| 建连 | TCP + TLS | TCP + TLS（ALPN 协商） | TLS 集成在 QUIC 内 |
| 握手往返 | 3 次以上 | 2 到 3 次 | 1 次（会话复用可 0 次） |
| 连接迁移 | 不支持 | 不支持 | 支持（连接 ID） |

## 关键概念速查

| 概念 | 说明 |
| --- | --- |
| 流（Stream） | 逻辑上的独立请求响应通道 |
| 帧（Frame） | HTTP/2 的最小传输单位 |
| 多路复用 | 多个流在同一连接上交错传输 |
| HPACK / QPACK | 头部压缩算法，QPACK 解决 QUIC 乱序问题 |
| 服务器推送 | HTTP/2 特性，实践中收益有限，已逐步弃用 |
| 优先级 | HTTP/2 的优先级树；HTTP/3 用紧急度 + 增量 |
| ALPN | TLS 握手时协商应用协议（h2、h3） |
| 0-RTT | 会话复用下提前发送数据，需防重放 |

```bash
# 检查服务端支持的协议版本
curl -I --http2 https://example.com
curl -I --http3 https://example.com          # 需要 curl 支持 HTTP/3
openssl s_client -connect example.com:443 -alpn h2 -brief

# 查看协商结果与连接复用情况
curl -v -o /dev/null -s https://example.com 2>&1 | grep -E 'ALPN|HTTP/'
```

```nginx
# Nginx 开启 HTTP/2 与 HTTP/3 的配置骨架
server {
    listen 443 ssl;
    listen 443 quic reuseport;            # HTTP/3 基于 UDP
    http2 on;
    server_name example.com;

    ssl_certificate     /etc/ssl/fullchain.pem;
    ssl_certificate_key /etc/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    add_header Alt-Svc 'h3=":443"; ma=86400';   # 告知客户端可升级到 HTTP/3
}
```

## 优化与迁移要点

| 要点 | 说明 |
| --- | --- |
| 域名收敛 | HTTP/2 下单连接多路复用，域名分片反而有害 |
| 资源合并 | 不再为减少请求数而过度合并，避免缓存粒度变粗 |
| 服务端推送替代方案 | 用 `preload` / `103 Early Hints` |
| 头部体积 | 压缩后仍需精简 Cookie 与自定义头 |
| 拥塞控制 | QUIC 可插拔，常见 CUBIC 与 BBR |
| 中间设备 | HTTP/3 依赖 UDP，需确认防火墙与负载均衡支持 |
| 降级策略 | 客户端先用 HTTP/2，Alt-Svc 探测成功后再走 h3 |
| 观测 | 记录协商版本、握手耗时、流取消与重传率 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为 HTTP/2 没有队头阻塞 | 丢包时全部流受影响 | TCP 层队头阻塞仍存在，需 HTTP/3 |
| 继续做域名分片 | 连接数增加、收益为负 | HTTP/2 下收敛域名 |
| 无脑使用 0-RTT | 重放攻击风险 | 只对幂等请求启用 |
| 防火墙未放行 UDP | HTTP/3 一直不可用 | 放行 UDP 并验证 Alt-Svc |
| 服务端推送滥用 | 带宽浪费 | 改用 preload 与 Early Hints |
| 忽略协商失败 | 用户走旧协议且无人知 | 监控协商版本分布 |
| 认为 HTTP/3 一定更快 | 高丢包与移动网络才明显 | 按场景实测对比 |
| 头部不做精简 | 压缩成本仍高 | 减少 Cookie 与冗余头 |
| 未更新负载均衡配置 | 连接异常或降级 | 确认七层网关支持并开启 h3 |
| 缺少回退与超时 | h3 探测失败后长时间不可用 | 设短探测超时并回退 h2 |

## 自测清单

- [ ] 能说清 HTTP/1.1、2、3 在并发与队头阻塞上的差异。
- [ ] 知道 HPACK 与 QPACK 的区别与原因。
- [ ] 会用 `curl` 与 `openssl` 检查协议协商。
- [ ] 明白 0-RTT 的重放风险与适用条件。
- [ ] 上线 HTTP/3 时配置好 Alt-Svc 与回退策略。
