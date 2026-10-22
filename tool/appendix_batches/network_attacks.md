## 常见攻击速查

| 攻击 | 原理 | 主要防护 |
| --- | --- | --- |
| SYN Flood | 大量半开连接耗尽队列 | SYN Cookie、限速、缩短超时 |
| UDP 反射放大 | 伪造源 IP 触发大响应 | 禁用开放服务、入口过滤、限速 |
| DNS 放大 | 利用大 TXT 响应 | 限制递归、响应限速、RRL |
| ARP 欺骗 | 伪造 IP 与 MAC 映射 | 动态 ARP 检测、静态绑定、分段 |
| DDoS | 多源流量压垮服务 | 云清洗、就近拦截、弹性扩容 |
| 中间人 | 劫持流量 | 强制 HTTPS、证书校验、HSTS |
| 端口扫描 | 探测开放服务 | 最小暴露面、防火墙、隐藏版本 |
| 暴力破解 | 反复尝试口令 | 限速、多因素、锁定与告警 |
| 会话固定 | 固定会话 ID 后劫持 | 登录后重新生成会话 ID |
| 供应链投毒 | 依赖或镜像被篡改 | 锁定版本、校验签名与哈希 |

## 防护措施速查

| 层次 | 措施 |
| --- | --- |
| 网络层 | 安全组、WAF、DDoS 清洗、网络分段 |
| 传输层 | 强制 TLS、HSTS、证书透明 |
| 应用层 | 输入校验、参数化查询、输出编码、CSRF 令牌 |
| 身份层 | 多因素认证、最小权限、短会话与刷新令牌 |
| 数据层 | 加密存储、脱敏、审计日志 |
| 供应链 | 依赖扫描、签名校验、私有仓库 |
| 运营层 | 告警、演练、应急响应手册 |

```python
import time
from collections import defaultdict, deque

class SlidingWindowBlocker:
    """按来源限速：滑动窗口内超过阈值即拒绝，用于缓解暴力破解与扫描。"""

    def __init__(self, limit: int = 20, window_seconds: float = 60.0):
        self.limit = limit
        self.window = window_seconds
        self.events = defaultdict(deque)
        self.blocked = set()

    def allow(self, source: str, now: float | None = None) -> bool:
        now = time.monotonic() if now is None else now
        if source in self.blocked:
            return False
        queue = self.events[source]
        while queue and now - queue[0] >= self.window:
            queue.popleft()
        if len(queue) >= self.limit:
            self.blocked.add(source)          # 触发封禁，可配合告警
            return False
        queue.append(now)
        return True


def is_suspicious_scan(ports_hit: set[int], threshold: int = 20) -> bool:
    """同一来源短时间命中大量不同端口，判断为端口扫描。"""
    return len(ports_hit) >= threshold


blocker = SlidingWindowBlocker(limit=3, window_seconds=60)
print([blocker.allow("10.0.0.9", now=i) for i in range(5)])
print(is_suspicious_scan(set(range(100))))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只靠 IP 黑名单 | 攻击者换 IP 继续 | 叠加行为限速与业务风控 |
| 限流粒度太粗 | 正常用户被误伤 | 按账号、来源、接口多维限流 |
| 认为内网绝对可信 | 横向移动畅通无阻 | 零信任与微隔离 |
| 日志记录明文口令 | 二次泄漏 | 严禁记录敏感字段，脱敏处理 |
| 不区分人与机器流量 | 自动化攻击未被拦住 | 行为分析与验证码分级 |
| 暴露调试接口 | 被直接利用 | 生产环境关闭并限制访问 |
| 依赖默认口令 | 设备被批量入侵 | 强制修改并纳入基线检查 |
| 不做备份与演练 | 被勒索后无法恢复 | 离线备份 + 恢复演练 |
| 只在上线前做一次扫描 | 新漏洞无人跟踪 | 持续扫描与依赖更新 |
| 忽略告警疲劳 | 真事件被淹没 | 分级告警与降噪 |

## 自测清单

- [ ] 能说出常见攻击原理与对应防护。
- [ ] 有基于滑动窗口的限速与封禁能力。
- [ ] 敏感数据全链路加密且日志脱敏。
- [ ] 内网按零信任原则做微隔离。
- [ ] 有离线备份、恢复演练与应急手册。
