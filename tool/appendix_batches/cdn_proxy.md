## 缓存策略速查

| 头部 | 作用 |
| --- | --- |
| `Cache-Control: max-age=31536000, immutable` | 强缓存一年，适合带指纹的静态资源 |
| `Cache-Control: no-cache` | 可缓存但每次要校验 |
| `Cache-Control: no-store` | 完全不缓存，适合敏感数据 |
| `Cache-Control: private` | 只允许浏览器缓存，CDN 不缓存 |
| `Cache-Control: s-maxage=60` | 仅对共享缓存（CDN）生效 |
| `ETag` 与 `If-None-Match` | 协商缓存，未变返回 304 |
| `Last-Modified` 与 `If-Modified-Since` | 时间维度协商缓存 |
| `Vary: Accept-Encoding` | 按编码维度区分缓存 |
| `stale-while-revalidate=30` | 过期后先用旧值并后台刷新 |

## 代理类型速查

| 类型 | 代表谁 | 典型用途 |
| --- | --- | --- |
| 正向代理 | 客户端 | 出网统一管控、缓存、审计 |
| 反向代理 | 服务端 | 负载均衡、TLS 卸载、限流、灰度 |
| 透明代理 | 客户端（不可见） | 企业网关、运营商缓存 |
| API 网关 | 服务端 | 鉴权、配额、路由、协议转换 |

```nginx
# 反向代理 + 缓存 + 回源超时的配置骨架
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=app_cache:100m max_size=10g inactive=24h use_temp_path=off;

server {
    listen 443 ssl;
    server_name cdn.example.com;

    # 带指纹的静态资源：长期强缓存
    location ~* \.(js|css|png|jpg|woff2)$ {
        proxy_pass http://origin;
        proxy_cache app_cache;
        proxy_cache_valid 200 301 302 30d;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header X-Cache-Status $upstream_cache_status;
    }

    # 接口：不缓存，并限制回源超时
    location /api/ {
        proxy_pass http://origin;
        proxy_cache off;
        add_header Cache-Control "no-store";
        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
    }
}
```

## 缓存问题与对策

| 问题 | 现象 | 对策 |
| --- | --- | --- |
| 缓存穿透 | 请求不存在的内容，全部回源 | 缓存空值、参数校验、布隆过滤器 |
| 缓存击穿 | 热点失效瞬间回源激增 | 互斥回源、逻辑过期、预热 |
| 缓存雪崩 | 大范围同时过期 | 过期时间加随机、分层缓存 |
| 缓存污染 | 长尾内容挤掉热点 | 分层策略与容量规划 |
| 回源带宽打满 | 源站被压垮 | 提高命中率、限速、合并回源 |
| 内容更新不及时 | 用户看到旧版本 | 主动刷新（purge）加版本化路径 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 静态资源不带指纹却设长缓存 | 发版后用户仍加载旧文件 | 文件名带哈希加长缓存 |
| 接口响应设 `max-age` | 用户看到过期数据 | 接口用 `no-store` 或短缓存加校验 |
| 用 `no-cache` 当「不缓存」 | 理解错误 | 它是每次校验，不缓存要用 `no-store` |
| 忘记 `Vary` | 压缩与非压缩内容串用 | 按 `Accept-Encoding` 等维度区分 |
| 私有数据被 CDN 缓存 | 数据泄漏 | 加 `private` 或 `no-store` |
| 刷新缓存不及时 | 用户看到旧内容 | 发版时主动 purge 或改路径 |
| 回源超时设得过长 | 慢请求拖垮连接 | 设置连接与读取超时并降级 |
| 不做命中率监控 | 优化无依据 | 记录 `X-Cache-Status` 与命中率 |
| 忽略跨域头与缓存的关系 | 偶发 CORS 失败 | 明确 `Vary: Origin` 或统一配置 |
| 认为加了 CDN 就一定快 | 回源率过高反而更慢 | 优化命中率与边缘节点覆盖 |

## 自测清单

- [ ] 能区分强缓存、协商缓存与 `no-store`。
- [ ] 静态资源用「指纹加长缓存」，接口用短缓存或不缓存。
- [ ] 知道 `s-maxage` 只对共享缓存生效。
- [ ] 会通过 `X-Cache-Status` 判断命中情况。
- [ ] 发版有主动刷新缓存的流程。
