## 记录类型速查

| 类型 | 作用 | 示例 |
| --- | --- | --- |
| A | 域名到 IPv4 | `example.com` 到 `93.184.216.34` |
| AAAA | 域名到 IPv6 | `example.com` 到 `2606:2800::1` |
| CNAME | 域名到另一个域名 | `www` 指向 `example.com` |
| MX | 邮件服务器 | `mail.example.com`（带优先级） |
| TXT | 文本记录 | SPF、DKIM、域名验证 |
| NS | 权威服务器 | 指定该域的权威解析方 |
| SOA | 区域起始信息 | 主服务器与默认 TTL |
| SRV | 服务位置 | 指定主机与端口 |
| PTR | IP 到域名 | 反向解析 |

## 解析过程速查

```text
浏览器缓存 → 系统缓存 → hosts 文件 → 本地递归解析器
   → 根服务器 → 顶级域服务器 → 权威服务器
   → 返回结果并按 TTL 缓存
```

| 查询方式 | 说明 |
| --- | --- |
| 递归查询 | 客户端要求解析器给出最终结果 |
| 迭代查询 | 解析器逐级询问，每级返回下一步该问谁 |
| 正向解析 | 域名到 IP |
| 反向解析 | IP 到域名（PTR） |

```bash
# 常用排查命令
dig example.com A +short                  # 查询 A 记录
dig example.com AAAA +short               # 查询 IPv6
dig www.example.com CNAME +short          # 看 CNAME 链
dig example.com MX +short                 # 邮件记录
dig +trace example.com                    # 从根开始的完整迭代过程
dig @8.8.8.8 example.com                  # 指定解析器
dig -x 93.184.216.34 +short               # 反向解析
dig example.com +noall +answer +ttlunits  # 查看 TTL
```

```python
import socket
import time

def resolve_with_timing(host: str):
    """测量解析耗时并返回全部地址（含 IPv6）。"""
    start = time.perf_counter()
    infos = socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)
    elapsed_ms = (time.perf_counter() - start) * 1000
    addresses = sorted({info[4][0] for info in infos})
    return {"host": host, "addresses": addresses, "elapsed_ms": round(elapsed_ms, 2)}


print(resolve_with_timing("example.com"))
```

## DNS 优化与安全速查

| 主题 | 做法 |
| --- | --- |
| 降低延迟 | 就近解析、Anycast、减少 CNAME 层级 |
| 故障切换 | 多 A 记录 + 健康检查 + 低 TTL |
| 负载均衡 | 轮询、加权、地理与延迟调度 |
| 缓存 | 合理设置 TTL，兼顾切换速度与解析压力 |
| 防劫持 | DNSSEC 校验、DoH 或 DoT 加密解析 |
| 防投毒 | 随机化查询 ID 与源端口，启用 DNSSEC |
| 防放大攻击 | 限制递归查询开放范围、响应限速 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 修改 DNS 后立即验证 | 看到旧结果 | 等待 TTL 过期或刷新本地缓存 |
| CNAME 链太长 | 解析变慢、易失败 | 减少层级，直接指向目标 A 记录 |
| 根域使用 CNAME | 违反规范 | 根域用 A / AAAA 或 ALIAS |
| TTL 设得过长 | 故障切换慢 | 关键服务 TTL 设短（如 60 秒） |
| 只配 A 不配 AAAA | IPv6 用户走降级路径 | 双栈配置 A 与 AAAA |
| 忽略解析器缓存差异 | 各地结果不一致 | 用多地 `dig` 验证权威与递归结果 |
| 用 `ping` 判断 DNS 是否正常 | 结论不准确 | 用 `dig` 直接验证解析结果 |
| 邮件域名无 SPF 与 DKIM | 邮件被判垃圾 | 配 TXT 记录与 DKIM 签名 |
| 只依赖单台权威服务器 | 解析中断 | 至少两台不同网络的权威服务器 |
| 开放递归解析 | 被用作放大攻击源 | 只对可信网段开放递归 |

## 自测清单

- [ ] 能说出 A、AAAA、CNAME、MX、TXT、NS 的作用。
- [ ] 能描述一次完整解析的递归与迭代过程。
- [ ] 会用 `dig +trace`、`dig -x`、指定解析器排查。
- [ ] TTL 设置兼顾切换速度与解析压力。
- [ ] 知道 DNSSEC 与 DoH/DoT 分别解决什么问题。
