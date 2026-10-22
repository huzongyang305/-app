## 补充：HTTP 版本差异、缓存协商与分段测量

### 三个版本的连接模型

```text
HTTP/1.1
  一个连接同时只处理一个请求
  → 浏览器开 6 条并发连接，队头阻塞（HOL）明显

HTTP/2
  单连接多路复用：多个流交织在同一连接上
  → 解决了应用层队头阻塞
  → 但 TCP 层丢包仍会阻塞所有流（TCP 层 HOL）

HTTP/3
  基于 QUIC（UDP）：流之间真正独立
  → 一个流丢包不影响其他流
  → 连接建立更快（0-RTT/1-RTT），并内置加密
```

| 维度 | HTTP/1.1 | HTTP/2 | HTTP/3 |
| --- | --- | --- | --- |
| 传输层 | TCP | TCP | QUIC over UDP |
| 多路复用 | 无 | 有 | 有 |
| 队头阻塞 | 应用层 | TCP 层 | 基本消除 |
| 握手往返 | TCP+TLS 多次 | 同左（可复用） | 1-RTT，复用到 0-RTT |
| 部署要求 | 无 | TLS 基本必须 | UDP 可达 |

### 缓存协商的完整流程

```text
第一次请求
  GET /app.js
  ← 200 OK + Cache-Control: max-age=3600 + ETag: "abc123"

一小时内再次请求
  → 直接用本地缓存，不发请求

一小时后
  GET /app.js
  If-None-Match: "abc123"
  ← 304 Not Modified（无正文，省带宽）

内容变了
  ← 200 OK + 新 ETag: "def456"
```

| 头 | 作用 | 注意 |
| --- | --- | --- |
| `Cache-Control` | 缓存策略 | `no-cache` 仍需校验，`no-store` 完全不存 |
| `ETag` / `If-None-Match` | 内容指纹校验 | 精度高，推荐 |
| `Last-Modified` / `If-Modified-Since` | 时间校验 | 秒级精度 |
| `Vary` | 按哪些请求头区分缓存 | 设置过宽会降低命中率 |

### 分段测量：三条命令

```bash
# 1. 分段耗时（DNS / 连接 / TLS / 首字节 / 总时长）
curl -w "\nDNS %{time_namelookup}s\nTCP %{time_connect}s\nTLS %{time_appconnect}s\nTTFB %{time_starttransfer}s\n总 %{time_total}s\n" \
  -o /dev/null -s https://example.com

# 2. 看响应头是否可缓存、是否命中 CDN
curl -sI https://example.com | grep -iE 'cache-control|etag|age|via|x-cache'

# 3. 复现压缩与协议差异
curl -s -o /dev/null -w '%{size_download} 字节 %{http_version}\n' \
  -H 'Accept-Encoding: br,gzip' https://example.com
```

```text
四个头部的诊断含义
  Age: 120          → 由 CDN 缓存的副本，已存在 120 秒
  X-Cache: HIT      → 边缘节点命中
  Via: 1.1 varnish  → 经过了缓存代理
  Content-Encoding: br  → 使用了 Brotli 压缩
```

### 浏览器侧的三个关键观察

| 工具/面板 | 看什么 | 常见结论 |
| --- | --- | --- |
| Network → Timing | 五段耗时分布 | 哪一段最长就优化哪一段 |
| Performance → Frames | 是否掉帧 | 掉帧通常来自长任务 |
| Lighthouse | LCP/CLS/INP | 按指标定位具体资源 |

```text
常见因果关系速查
  TTFB 高 → 服务端或数据库慢，或未命中缓存
  内容下载慢 → 未压缩、资源太大、未用 CDN
  渲染慢 → 关键 CSS 阻塞、脚本同步加载
  交互慢 → 主线程长任务
```

### 自查清单

- [ ] 能说出 HTTP/1.1、2、3 的队头阻塞分别在哪一层
- [ ] 能为静态资源设计「长缓存 + 哈希文件名」策略
- [ ] 会用 `curl -w` 分段定位耗时
- [ ] 能从响应头判断是否命中 CDN 缓存
- [ ] 知道 TTFB、LCP、INP 各自对应哪一段

