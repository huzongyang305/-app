## 链路层速查

| 概念 | 说明 |
| --- | --- |
| MAC 地址 | 48 位，链路内寻址，前 24 位是厂商 OUI |
| 以太网帧 | 目的 MAC + 源 MAC + 类型 + 载荷 + FCS |
| MTU | 以太网默认 1500 字节 |
| 广播 | `FF:FF:FF:FF:FF:FF`，泛洪到所有端口 |
| 单播与组播 | 一对一与一对多 |
| ARP | IPv4 地址到 MAC 的解析 |
| NDP | IPv6 中替代 ARP 的邻居发现协议 |
| VLAN | 在二层逻辑隔离广播域（802.1Q 标签） |

## 设备与转发速查

| 设备 | 工作层次 | 转发依据 | 隔离广播域 |
| --- | --- | --- | --- |
| 集线器 | 物理层 | 无（电信号广播） | 否 |
| 交换机 | 数据链路层 | MAC 地址表 | 否（VLAN 可以） |
| 路由器 | 网络层 | 路由表 | 是 |
| 三层交换机 | 二三层 | MAC 加 IP | 是 |

```bash
# 查看 ARP 与邻居表
ip neigh show
arp -an

# 查看接口 MAC 与统计
ip -br link
ip -s link show eth0 | head

# 抓取链路层信息（含 MAC 与 ARP）
tcpdump -i eth0 -e -n arp
tcpdump -i eth0 -e -n -c 20

# 查看 VLAN 接口与网桥转发表
ip -d link show type vlan
bridge link
bridge fdb show
```

```python
def parse_mac(mac: str) -> dict:
    """解析 MAC 地址：判断单播与组播、是否本地管理。"""
    parts = mac.replace("-", ":").split(":")
    if len(parts) != 6:
        raise ValueError("MAC 地址格式不正确")
    first = int(parts[0], 16)
    return {
        "normalized": ":".join(p.lower() for p in parts),
        "is_multicast": bool(first & 0x01),        # 最低位为 1 表示组播
        "is_locally_administered": bool(first & 0x02),
        "oui": ":".join(parts[:3]).upper(),
    }


print(parse_mac("00-1A-2B-3C-4D-5E"))
print(parse_mac("01:00:5e:00:00:01"))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为 MAC 能跨路由寻址 | 通信失败 | MAC 只在同一链路有效，跨网靠 IP |
| 以为交换机隔离广播域 | 广播风暴影响全网 | 需要 VLAN 或路由器隔离 |
| 忽视 ARP 表老化 | 迁移后短暂不通 | 等待老化或清理 ARP 缓存 |
| 手工写错静态 ARP | 通信中断 | 核对 MAC 与接口 |
| 只看 IP 不看 MAC 排查二层 | 定位困难 | 用 `-e` 抓包观察 MAC |
| 网线两端 MTU 不一致 | 大包丢弃 | 统一 MTU 或调整 MSS |
| 忽略双工模式不匹配 | 丢包、性能骤降 | 两端设为自协商或统一为全双工 |
| 认为 VLAN 是安全边界 | 被 VLAN 跳跃攻击 | 正确配置 trunk 与原生 VLAN |
| 未关闭未使用端口 | 未授权接入 | 端口安全与访问控制 |
| 抓包时间过短 | 漏掉周期性故障 | 延长抓包并设置文件轮转 |

## 自测清单

- [ ] 能解释 MAC 与 IP 的分工。
- [ ] 知道集线器、交换机、路由器的转发依据与广播域差异。
- [ ] 会用 `ip neigh`、`bridge fdb`、`tcpdump -e` 排查二层问题。
- [ ] 记得以太网 MTU 默认 1500 并会排查分片。
- [ ] 知道 VLAN 用于隔离广播域而非安全边界。
