# 本课主题

> 内容更新时间：2026-10-03

![一次请求的抓包分析流程](images/diagram_net_packet_project.webp)

![本课主题](images/remaining_network_project.webp)

## 学习目标

- 能用自己的话解释本课主题解决了什么问题，而不是只背术语。
- 能说清 「实战」、「抓包」、「tcpdump」、「openssl」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「网络」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：DNS 到 HTTP 全链路观察与三道排查题。

## 前置知识

- 先完成上一课《Web 安全攻防》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：实战、抓包、tcpdump。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 目标

从输入 URL 到页面返回，用工具把 DNS → TCP → TLS → HTTP 每一层都看清楚，并学会用它排查故障。

## 分步观察

| 阶段 | 工具 | 关键观察 |
| --- | --- | --- |
| DNS | `dig example.com +trace`、`nslookup` | 递归查询过程、A/AAAA 记录、TTL |
| TCP 握手 | `tcpdump -i any port 443 -nn` | SYN / SYN+ACK / ACK 三次握手与端口 |
| TLS 握手 | `openssl s_client -connect example.com:443 -servername example.com` | 证书链、协议版本、密码套件 |
| HTTP 交互 | `curl -vI https://example.com`、浏览器 Network 面板 | 请求头/响应头、状态码、缓存命中、HTTP 版本 |
| 路径质量 | `mtr example.com`、`traceroute` | 每跳延迟与丢包 |

## 三道排查题

1. **网站打不开**：先 `dig` 看解析，再 `curl -v` 看是连接失败、TLS 失败还是 HTTP 错误码；若超时用 `mtr` 定位是本地、出口还是目标侧。
2. **偶发慢**：在服务端用 `tcpdump` 抓包，看是否有重传（同一序号多次发送）与零窗口；重传多说明链路质量差或 MTU 有问题。
3. **只在大文件时失败**：怀疑 MTU/分片，用 `ping -M do -s 1472` 探测路径 MTU，或看是否被中间设备丢弃大包。

## 常见坑

1. 抓包没加 `-s 0` 导致内容被截断；没加 `-nn` 导致解析慢。
2. 在容器里抓不到宿主网卡流量（需 `--net=host` 或抓 `eth0`）。
3. 把 DNS 缓存当成本次解析结果，误判解析耗时。
4. 忽略代理/CDN：拿到的 IP 可能只是边缘节点。

## 交付物

一份抓包分析报告：含时间线（DNS 耗时、握手耗时、首字节时间）、关键包截图、以及**至少一个真实故障的定位过程**。

## 交付物与评分标准

**交付物**：一份抓包分析报告，含时间线（DNS/握手/首字节各段耗时）、关键包截图、以及至少一个真实故障的定位过程与结论。

**评分标准**：分层清晰 30%（能区分解析/传输/应用层问题）、证据充分 30%（每条结论对应具体包或命令输出）、定位准确 25%（能给出可执行的修复建议）、记录规范 15%（时间戳、命令、环境齐全）。

**常见失败案例**：① 只贴 tcpdump 原始输出不做解读；② 把 DNS 缓存命中的耗时当作真实解析耗时；③ 抓包时未加 `-s 0` 导致内容截断却据此下结论；④ 混淆「连接超时」与「服务拒绝」（前者无响应、后者返回 RST）。

## 本课小结
网络排障的顺序是**自下而上**：解析 → 连通 → 握手 → 应用协议；掌握抓包与分层工具，就能把"打不开""很慢"变成具体结论。

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

## 动手练习

> 本课练习重点：围绕「实战、抓包、tcpdump」完成复述、实验和交付，每个结果都要能被别人检查。

先抓一次真实请求或画出协议交互，再注入延迟或丢包，最后解释每层变化。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 本课主题解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「抓包」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

画出一张报文或时序图，标出每一跳的地址、协议、状态和可能失败点。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实战」和「抓包」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 安装依赖 | `python -m pip install -r requirements.txt` | 依赖安装完成，没有版本冲突 |
| 语法检查 | `python -m compileall .` | 所有模块编译通过 |
| 运行测试 | `python -m pytest -q` | 测试全部通过，失败用例数为 0 |
| 启动示例 | `python main.py` | 服务启动并输出监听地址 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 实战 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 实战 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 实战 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“实战 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 实战 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 抓包 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 抓包 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 抓包 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“抓包 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 抓包 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：请求偶发超时，但服务端监控看起来正常

**症状**：在本课的练习或生产场景里出现“请求偶发超时，但服务端监控看起来正常”。

## 深入补充：本课主题 的取舍与边界

### 一、把概念放回真实约束

学习本课主题时，最容易只记住结论而忽略前提。先写出三个约束：数据规模、时间预算、可接受的失败方式；再判断 实战 与 抓包 在这些约束下是否仍然成立。只要约束改变，原来的最优解就可能变成错误解。

| 场景 | 协议或方案 | 延迟与可靠性 | 排障入口 |
| --- | --- | --- | --- |
| 强一致请求 | TCP / HTTP | 可靠但可能队头阻塞 | 连接与重传指标 |
| 实时音视频 | UDP / QUIC | 低延迟但允许丢包 | 抖动与丢包率 |
| 大规模分发 | CDN 与缓存 | 就近命中 | 命中率与回源 |
| 服务间调用 | RPC 或消息队列 | 取决于确认机制 | 超时、重试与幂等 |

### 二、三个容易混淆的边界

2. **把“平均值”当成“全部”**：实战 的指标好看，不代表尾部请求、冷启动或失败重试也好看。
3. **把“当前版本”当成“永久行为”**：抓包 依赖的默认值、API 或性能特征都可能随版本变化，需要固定版本并保留回归用例。

### 三、一个生产场景

假设团队要在真实系统里使用本课主题：第一周先做小流量验证，记录 实战 的基线与异常；第二周扩大输入规模，观察 抓包 是否成为瓶颈；第三周再做故障演练，主动注入超时、重复请求和依赖不可用，确认系统能降级、能重试、能恢复。每一步都要留下指标、日志和结论，而不是只留下“感觉更快了”。

### 四、自测清单

- 能否用一句话说出本课主题解决的核心问题与不适用场景？
- 能否画出 实战 的数据流或状态变化，并标出失败路径？
- 能否给出一个反例，证明某个看似合理的结论在边界条件下不成立？
- 能否写出一条可复现的验证命令，让别人独立得到相同结论？

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「追踪 DNS 递归查询过程用？」的判断依据。
- [ ] 不看解析，能说出「检查 TLS 证书链与协议版本用？」的判断依据。
- [ ] 不看解析，能说出「请求偶发变慢，抓包时首先关注？」的判断依据。
- [ ] 不看解析，能说出「curl -w 参数在排查接口耗时时的作用是？」的判断依据。
- [ ] 不看解析，能说出「tcpdump 的 -w 参数作用是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `dig example.com +trace` | \| DNS \| `dig example.com +trace`、`nslookup` \| 递归查询过程、A/AAAA 记录、TTL \| |
| `nslookup` | \| DNS \| `dig example.com +trace`、`nslookup` \| 递归查询过程、A/AAAA 记录、TTL \| |
| `tcpdump -i any port 443 -nn` | \| TCP 握手 \| `tcpdump -i any port 443 -nn` \| SYN / SYN+ACK / ACK 三次握手与端口 \| |
| `curl -vI https://example.com` | \| HTTP 交互 \| `curl -vI https://example.com`、浏览器 Network 面板 \| 请求头/响应头、状态码、缓存命中、HTTP 版本 \| |
| `mtr example.com` | \| 路径质量 \| `mtr example.com`、`traceroute` \| 每跳延迟与丢包 \| |
| `traceroute` | \| 路径质量 \| `mtr example.com`、`traceroute` \| 每跳延迟与丢包 \| |
| `dig` | 网站打不开**：先 `dig` 看解析，再 `curl -v` 看是连接失败、TLS 失败还是 HTTP 错误码；若超时用 `mtr` 定位是本地、出口还是目标侧。 |
| `curl -v` | 网站打不开**：先 `dig` 看解析，再 `curl -v` 看是连接失败、TLS 失败还是 HTTP 错误码；若超时用 `mtr` 定位是本地、出口还是目标侧。 |
| `mtr` | 网站打不开**：先 `dig` 看解析，再 `curl -v` 看是连接失败、TLS 失败还是 HTTP 错误码；若超时用 `mtr` 定位是本地、出口还是目标侧。 |
| `tcpdump` | 偶发慢**：在服务端用 `tcpdump` 抓包，看是否有重传（同一序号多次发送）与零窗口；重传多说明链路质量差或 MTU 有问题。 |
| `ping -M do -s 1472` | 只在大文件时失败**：怀疑 MTU/分片，用 `ping -M do -s 1472` 探测路径 MTU，或看是否被中间设备丢弃大包。 |
| `-s 0` | 抓包没加 `-s 0` 导致内容被截断；没加 `-nn` 导致解析慢。 |

## 考点精讲

### 考点 1：追踪 DNS 递归查询过程用？

- **判断依据**：+trace 会依次查询根、顶级域与权威服务器。其他选项：dig +trace 展示从根服务器开始的迭代查询过程。判断这类题时，要把「dig +trace」放回题干限定的对象、输入和边界，「ping」、「ss -lnt」 等说法虽然包含相关术语，但范围或前提与本题不一致。

### 考点 2：检查 TLS 证书链与协议版本用？

- **判断依据**：本题应选「openssl s_client」。sclient 会打印证书链、协议与密码套件。解题的关键不是记住孤立术语，而是确认「openssl s_client」是否完整覆盖题干的输入、输出和失败路径，并排除「nslookup（仅部分场景成立）」、「tcpdump」这类相邻概念。

### 考点 3：围绕“实战：抓包分析一次真实请求”中的 实战、抓包、tcpdump，下列哪两项是本课强调的实践判断？

- **判断依据**：正确答案包括「验证 抓包 时要固定版本并覆盖边界输入，结论才可复现」、「学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程」。符合题干条件的是验证 抓包 时要固定版本并覆盖边界输入。在本课主题里，判断 抓包 时要固定版本与边界输入，所以“验证 抓包 时要固定版本并覆盖边界输入，结论才可复现”才可复现。如果只凭关键词作答，很容易把验证 抓包 时要固定版本并覆盖边界输入，结论才可复现、把 抓包 的单次运行结果当成所有版本和规模都成立与验证 抓包 时要固定版本并覆盖边界输入，结论才可复现。

### 考点 4：下面这段 Python 代码复现了“实战：抓包分析一次真实请求”中 实战、抓包、tcpdump 相关的一个常见故障，哪一项最准确地解释了问题？

- **判断依据**：结论应落在「循环上界多走了 1 步，最后一次访问越界（network_project 第 4 题）；应改成 range(len(data))」（network_project 第 4 题）。结论应落在循环上界多走了 1 步，最后一次访问越界（network_project 第 4 题）。应改成 range(len(data))（network_project 第 4 题）。结论应落在循环上界多走了 1 步，最后一次访问越界（networkproject 第 4 题）。

### 考点 5：tcpdump 的 -w 参数作用是？

- **判断依据**：正确答案是「把抓到的原始报文写入 pcap 文件，供 Wireshark 等工具离线分析」。正确答案是把抓到的原始报文写入 pcap 文件。生产环境抓包文件可能含敏感数据，需要控制权限并及时清理。判断这类题时，要把「把抓到的原始报文写入 pcap 文件，供 Wireshark 等工具离线…」放回题干限定的对象、输入和边界，「显示报文内容」、「过滤端口」 等说法虽然包含相关术语，但范围或前提与本题不一致。

### 考点 6：补全代码：「实战：抓包分析一次真实请求」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。

`'dns=%{____} connect=%{time_connect} '`

- **判断依据**：空格应填写「time_namelookup」。围绕 补全代码：本课主题示例中，下面这行代码缺少哪个… 作答时，先用实战建立输入与输出的基线，再把timenamelookup代入边界条件核对，结论才能复现。解题的关键不是记住孤立术语，而是确认「time_namelookup」是否完整覆盖题干的输入、输出和失败路径，并排除这类相邻概念。

## English Overview

**Title:** Project: Packet Analysis

**Summary:** DNS to HTTP analysis and troubleshooting drills.

**Category:** Networking
**Level:** 高级
**Key terms:** 实战, 抓包, tcpdump, openssl, mtr

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：TCP/IP、HTTP/2、HTTP/3 与现代网络栈
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、抓包、tcpdump、openssl、mtr
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：本课主题

### 核心场景

DNS 到 HTTP 全链路观察与三道排查题。 项目目标是把「实战、抓包、tcpdump、openssl、mtr」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | 实战、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。

## 项目交付物

### 建议仓库结构

```text
src/
tests/
docs/
README.md
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "network_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「实战、抓包、tcpdump」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Cloudflare Learning](https://www.cloudflare.com/learning/) | 网络概念与安全解释 |
| [RFC 9112 HTTP/1.1](https://www.rfc-editor.org/rfc/rfc9112) | HTTP/1.1 报文与连接 |
| [RFC 9293 TCP](https://www.rfc-editor.org/rfc/rfc9293) | TCP 连接、重传与拥塞 |

> 「实战：抓包分析一次真实请求」的链接用于离线阅读后的延伸核对；App 不会自动联网。
