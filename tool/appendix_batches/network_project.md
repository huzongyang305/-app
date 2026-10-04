## 抓包分析流程速查

| 步骤 | 动作 | 命令 |
| --- | --- | --- |
| 1 复现 | 记录时间点与请求特征 | 保存请求 ID、URL、用户标识 |
| 2 分层观测 | DNS、TCP、TLS、HTTP 各耗时多少 | `curl -w` 分解耗时 |
| 3 抓包 | 同时抓客户端与服务端 | `tcpdump -i any -w a.pcap` |
| 4 分析 | 看握手、重传、RST、状态码 | Wireshark 过滤器 |
| 5 结论 | 定位到具体环节并给出证据 | 时间线 + 关键包编号 |

```bash
# 一、耗时分解：DNS、连接、TLS、首字节、总时间
curl -o /dev/null -s -w \
  'dns=%{time_namelookup} connect=%{time_connect} tls=%{time_appconnect} ttfb=%{time_starttransfer} total=%{time_total}\n' \
  https://example.com/api/health

# 二、DNS 与路由
dig +stats example.com
mtr -n -c 20 example.com

# 三、抓包（含轮转，避免写满磁盘）
tcpdump -i any -s 0 -w /tmp/cap.pcap -C 100 -W 5 'tcp port 443'

# 四、Wireshark 常用过滤器
# http.request or http.response                   只看 HTTP 请求与响应
# tcp.analysis.retransmission                     只看重传
# tcp.flags.reset == 1                            只看 RST
# tls.handshake.type == 1 or tls.handshake.type == 2   ClientHello / ServerHello
# ip.addr == 10.0.0.5 and tcp.port == 443         指定主机与端口
# frame.time_delta_displayed > 1                  看相邻包间隔超过 1 秒

# 五、统计与提取
tshark -r /tmp/cap.pcap -q -z io,stat,1 | head      # 每秒流量统计
tshark -r /tmp/cap.pcap -Y 'http.response.code >= 500' -T fields -e http.response.code
```

```python
import subprocess
from dataclasses import dataclass

@dataclass
class Timing:
    dns: float
    connect: float
    tls: float
    ttfb: float
    total: float

    def breakdown(self) -> dict:
        """把 curl 的累计耗时换算成各阶段增量。"""
        return {
            "dns": round(self.dns, 4),
            "tcp": round(self.connect - self.dns, 4),
            "tls": round(self.tls - self.connect, 4),
            "server_wait": round(self.ttfb - self.tls, 4),
            "download": round(self.total - self.ttfb, 4),
        }

    def bottleneck(self) -> str:
        parts = self.breakdown()
        return max(parts, key=parts.get)


FORMAT = (
    'dns=%{time_namelookup} connect=%{time_connect} '
    'tls=%{time_appconnect} ttfb=%{time_starttransfer} total=%{time_total}'
)


def measure(url: str) -> Timing:
    result = subprocess.run(
        ["curl", "-o", "/dev/null", "-s", "-w", FORMAT, url],
        capture_output=True, text=True, timeout=30,
    )
    values = dict(item.split("=") for item in result.stdout.split())
    return Timing(**{key: float(value) for key, value in values.items()})


timing = measure("https://example.com")
print(timing.breakdown(), "瓶颈：", timing.bottleneck())
```

## 常见现象与原因速查

| 现象 | 常见原因 | 验证方式 |
| --- | --- | --- |
| 首次慢、后续快 | DNS 或连接未复用 | 对比 `time_namelookup` 与连接复用 |
| 部分地区慢 | 路由绕行或 CDN 未覆盖 | 多地 `mtr` 与 CDN 命中率 |
| 偶发超时 | 丢包重传、连接池耗尽 | 看重传率与连接池指标 |
| 大文件传输中断 | 中间设备空闲超时 | 抓包看 FIN/RST 时间点 |
| TLS 握手慢 | 证书链大、算法协商慢 | 看握手包数量与证书大小 |
| 502 与 504 | 上游崩溃或超时 | 查网关日志与上游耗时 |
| 请求重复 | 客户端或网关重试 | 用请求 ID 去重统计 |
| 内容不一致 | 缓存与回源版本不同 | 看 `X-Cache-Status` 与 Age |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只在一端抓包 | 无法区分是发不出去还是没收到 | 客户端与服务端同时抓包 |
| 抓包无时间戳对照 | 无法对齐日志 | 记录开始时间与请求 ID |
| 抓全量流量 | 文件巨大、分析困难 | 用过滤器限定主机与端口 |
| 只看平均耗时 | 长尾被掩盖 | 结合 P95 与慢请求样本 |
| 直接在生产长时间抓包 | 影响性能与隐私 | 限定时长与大小，注意脱敏 |
| 忽略 DNS 与 TLS 耗时 | 误判为服务端慢 | 用 `curl -w` 分解 |
| 只看 HTTP 不看 TCP | 漏掉重传与 RST | 结合 TCP 分析过滤器 |
| 结论没有证据 | 无法复现与验证 | 附上包序号与时间线 |
| 忽略中间代理 | 认为链路是直连 | 检查代理与网关配置 |
| 排查后不沉淀 | 同类问题重复排查 | 写成 runbook 与自动诊断脚本 |

## 自测清单

- [ ] 会用 `curl -w` 分解 DNS、TCP、TLS、TTFB 耗时。
- [ ] 能同时抓客户端与服务端并做时间线对照。
- [ ] 熟悉 Wireshark 的重传、RST、握手过滤器。
- [ ] 结论有包级证据与复现步骤。
- [ ] 排查过程沉淀为可复用脚本。
