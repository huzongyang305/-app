## IP 与子网速查

| 前缀 | 子网掩码 | 可用主机数 | 常见用途 |
| --- | --- | --- | --- |
| /31 | 255.255.255.254 | 2（点对点） | 链路互联 |
| /30 | 255.255.255.252 | 2 | 点对点链路 |
| /29 | 255.255.255.248 | 6 | 小网段 |
| /24 | 255.255.255.0 | 254 | 常规子网 |
| /16 | 255.255.0.0 | 65534 | 大型内网 |
| /8 | 255.0.0.0 | 约 1677 万 | 超大型 |

| 私有地址段 | 范围 |
| --- | --- |
| 10.0.0.0/8 | 10.0.0.0 到 10.255.255.255 |
| 172.16.0.0/12 | 172.16.0.0 到 172.31.255.255 |
| 192.168.0.0/16 | 192.168.0.0 到 192.168.255.255 |
| 127.0.0.0/8 | 本机回环 |
| 169.254.0.0/16 | 链路本地（DHCP 失败时出现） |

## 传输层速查

| 维度 | TCP | UDP |
| --- | --- | --- |
| 连接 | 面向连接 | 无连接 |
| 可靠性 | 确认与重传 | 不保证 |
| 顺序 | 保证有序 | 不保证 |
| 流量与拥塞控制 | 有 | 无（应用层自实现） |
| 头部开销 | 20 字节起 | 8 字节 |
| 适用 | 文件、HTTP、数据库 | DNS、音视频、游戏、QUIC |

```bash
# 查看路由与接口
ip route show
ip -br addr
traceroute -n 8.8.8.8        # 逐跳观察路径
mtr -n 8.8.8.8               # 持续观察每跳丢包与延迟

# 查看连接与监听
ss -tan state established | head
ss -s                        # 汇总各类 socket 数量

# 排查 MTU 与分片（禁止分片 + 指定大小）
ping -M do -s 1472 8.8.8.8   # 1472 + 28 = 1500，成功说明路径 MTU 至少 1500
```

```python
import ipaddress

def subnet_info(cidr: str) -> dict:
    """子网信息速算：网络号、广播地址、可用主机范围与数量。"""
    net = ipaddress.ip_network(cidr, strict=False)
    hosts = list(net.hosts()) if net.num_addresses > 2 else []
    return {
        "network": str(net.network_address),
        "netmask": str(net.netmask),
        "broadcast": str(net.broadcast_address),
        "first_host": str(hosts[0]) if hosts else None,
        "last_host": str(hosts[-1]) if hosts else None,
        "usable_hosts": len(hosts),
    }


def same_subnet(ip_a: str, ip_b: str, cidr: str) -> bool:
    """判断两个地址是否在同一子网（不依赖能否 ping 通）。"""
    net = ipaddress.ip_network(cidr, strict=False)
    return ipaddress.ip_address(ip_a) in net and ipaddress.ip_address(ip_b) in net


print(subnet_info("192.168.10.0/24"))
print(same_subnet("192.168.10.5", "192.168.10.200", "192.168.10.0/24"))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把广播地址当可用主机 | 地址冲突 | 网络号与广播地址不可分配给主机 |
| 认为 /24 有 256 个可用地址 | 少算了两个 | 可用 254 个 |
| 忽略 169.254 地址 | 网络不可用却查不出原因 | 说明 DHCP 失败，检查获取流程 |
| 用 `ping` 判断端口是否开放 | 结论不准确 | 用 `nc -zv` 或 `ss` 验证 |
| 忽视 MTU 与分片 | 大包超时、小包正常 | 检查路径 MTU，必要时调整 MSS |
| 认为 UDP 一定更快 | 应用层补偿开销被忽略 | 需要可靠性时选 TCP 或 QUIC |
| 混淆流量控制与拥塞控制 | 优化方向错误 | 流量控制面向接收方，拥塞控制面向网络 |
| 只用 `netstat` 不用 `ss` | 大连接数下很慢 | 用 `ss`（内核 netlink 实现） |
| 忽略 TIME_WAIT 与端口耗尽 | 客户端无法新建连接 | 使用连接池，必要时调整内核参数 |
| 认为 NAT 后能直接被外部访问 | 连接失败 | 需要端口映射或反向通道 |

## 自测清单

- [ ] 能快速判断子网的网络号、广播地址与可用主机数。
- [ ] 知道私有地址段与回环、链路本地地址范围。
- [ ] 能按需求在 TCP 与 UDP 之间选择。
- [ ] 会用 `ip`、`ss`、`traceroute`、`mtr` 排查网络。
- [ ] 知道如何验证路径 MTU 与排查分片问题。
