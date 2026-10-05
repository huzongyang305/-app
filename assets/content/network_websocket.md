# WebSocket 与实时通信

![WebSocket 握手与双向通信](images/diagram_net_websocket.webp)

![WebSocket 与实时通信](images/remaining_websocket.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「WebSocket 与实时通信」解决了什么问题，而不是只背术语。
- 能说清 「WebSocket」、「SSE」、「心跳」、「重连」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「网络」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：协议升级、心跳重连与水平扩展。

## 前置知识

- 先完成上一课《CDN、代理与缓存》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：WebSocket、SSE、心跳。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 为什么需要 WebSocket

HTTP 是请求-响应模式，服务器无法主动推送。轮询（不停发请求）浪费资源，长轮询（挂起请求）实现复杂。WebSocket 通过一次 HTTP 握手升级协议，之后在**同一条 TCP 连接**上双向通信。

```text
客户端 GET /chat HTTP/1.1
       Upgrade: websocket
       Connection: Upgrade
       Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==

服务器 HTTP/1.1 101 Switching Protocols
       Upgrade: websocket
       Connection: Upgrade
       Sec-WebSocket-Accept: ...
```

## 与 HTTP、SSE 的对比

| 方式 | 方向 | 延迟 | 适用 |
| --- | --- | --- | --- |
| HTTP 轮询 | 客户端拉 | 高 | 低频状态检查 |
| 长轮询 | 半推送 | 中 | 兼容性要求极高的场景 |
| SSE | 服务器单向推 | 低 | 通知、日志流、AI 流式输出 |
| WebSocket | 双向 | 最低 | 聊天、协作、游戏、行情 |

## 前端使用

```javascript
const ws = new WebSocket('wss://example.com/chat');
ws.onopen = () => ws.send(JSON.stringify({ type: 'join', room: '42' }));
ws.onmessage = event => {
  const message = JSON.parse(event.data);
  console.log('收到', message);
};
ws.onerror = error => console.error('连接异常', error);
ws.onclose = event => {
  console.warn('连接关闭', event.code, event.reason);
  setTimeout(connect, Math.min(30000, 1000 * 2 ** retries++));   // 指数退避重连
};
```

前端必须实现：**心跳、重连、消息去重与顺序处理**。断线后要能补齐漏掉的消息（用序号或游标）。

## 服务端要点

```python
# FastAPI 示例
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI()
rooms: dict[str, set[WebSocket]] = {}

@app.websocket("/chat/{room}")
async def chat(websocket: WebSocket, room: str):
    await websocket.accept()
    rooms.setdefault(room, set()).add(websocket)
    try:
        while True:
            text = await websocket.receive_text()      # 心跳也在这里处理
            for client in rooms[room]:
                if client is not websocket:
                    await client.send_text(text)       # 广播
    except WebSocketDisconnect:
        rooms[room].discard(websocket)
```

生产环境还要考虑：

1. **水平扩展**：多实例之间用 Redis Pub/Sub、NATS 或 Kafka 转发消息。
2. **连接数**：单机连接数受文件描述符与内存限制，需要容量规划与压测。
3. **背压**：慢客户端会拖垮服务，应限制发送队列并在超限时断开。
4. **鉴权**：握手阶段校验 Token，避免连接后长时间占用资源。
5. **心跳与超时**：定期 ping/pong，清理半开连接。

## 常见问题

| 现象 | 原因与对策 |
| --- | --- |
| 连接频繁断开 | 中间代理超时，需心跳或调整 idle timeout |
| 消息丢失 | 未做确认与重发，应加序号 + ACK 或改用可靠消息队列 |
| 消息乱序 | 多路并发发送，需服务端统一排序并带序号 |
| 内存持续增长 | 连接未清理或发送队列堆积，检查断连处理与背压 |

## 本课小结
WebSocket 只提供「双向管道」，可靠性要靠自己补齐：**心跳、重连、序号、ACK、背压与鉴权**。需要更高实时性或音视频时再考虑 WebRTC。


## 协议选型速查

| 方案 | 方向 | 底层 | 适用 |
| --- | --- | --- | --- |
| 轮询 | 客户端拉 | HTTP | 更新频率低、实现最简 |
| 长轮询 | 客户端拉（挂起） | HTTP | 兼容性要求高 |
| SSE | 服务器推 | HTTP | 单向推送（通知、进度） |
| WebSocket | 双向 | HTTP 升级后 TCP | 聊天、协作、游戏 |
| WebRTC | 双向（音视频与数据） | UDP | 实时音视频、P2P |
| gRPC 流 | 双向 | HTTP/2 | 服务间流式通信 |

## WebSocket 生命周期速查

| 阶段 | 说明 |
| --- | --- |
| 握手 | 一次带 `Upgrade: websocket` 的 HTTP 请求 |
| 建立 | 服务端返回 101 Switching Protocols |
| 数据帧 | 文本帧、二进制帧、控制帧（ping、pong、close） |
| 保活 | 客户端或服务端定期发送 ping，收到 pong 确认存活 |
| 关闭 | 一方发 close 帧，另一方回应后关闭 TCP |

```javascript
// 带心跳、指数退避重连与消息队列的客户端封装
class ReconnectingSocket {
  constructor(url, { maxDelay = 30000, pingInterval = 25000 } = {}) {
    this.url = url;
    this.maxDelay = maxDelay;
    this.pingInterval = pingInterval;
    this.attempt = 0;
    this.queue = [];
    this.connect();
  }

  connect() {
    this.ws = new WebSocket(this.url);

    this.ws.onopen = () => {
      this.attempt = 0;
      this.flushQueue();
      this.startHeartbeat();
    };

    this.ws.onmessage = (event) => {
      if (event.data === "pong") return;      // 心跳响应，不交给业务
      this.onMessage?.(event.data);
    };

    this.ws.onclose = () => {
      this.stopHeartbeat();
      this.scheduleReconnect();
    };

    this.ws.onerror = () => this.ws.close();
  }

  startHeartbeat() {
    this.stopHeartbeat();
    this.timer = setInterval(() => this.send("ping"), this.pingInterval);
  }

  stopHeartbeat() {
    if (this.timer) clearInterval(this.timer);
  }

  scheduleReconnect() {
    const delay = Math.min(this.maxDelay, 1000 * 2 ** this.attempt++);
    const jitter = Math.random() * 0.3 * delay;   // 抖动避免同时重连
    setTimeout(() => this.connect(), delay + jitter);
  }

  send(payload) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(typeof payload === "string" ? payload : JSON.stringify(payload));
    } else {
      this.queue.push(payload);                   // 断线期间先入队
    }
  }

  flushQueue() {
    const pending = this.queue.splice(0);
    pending.forEach((item) => this.send(item));
  }
}
```

## 多实例部署速查

| 问题 | 方案 |
| --- | --- |
| 连接落在不同实例 | 用 Redis 发布订阅或消息队列广播 |
| 会话状态 | 存入共享存储（Redis），不放在单机内存 |
| 负载均衡 | 需要会话粘性时用一致性哈希或 `ip_hash` |
| 连接数上限 | 按内存与文件描述符调优，控制单机连接数 |
| 消息顺序 | 同一会话串行处理，避免并发写同一连接 |
| 广播风暴 | 分级主题订阅，避免全量广播 |
| 断线补偿 | 客户端带 `last_event_id` 拉取缺失消息 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不做心跳 | 半开连接长期占用 | 定期 ping/pong 并设置超时断开 |
| 重连不做退避 | 服务端被重连风暴打垮 | 指数退避 + 随机抖动 |
| 只靠 WebSocket 无兜底 | 代理阻断时完全不可用 | 提供轮询或 SSE 降级 |
| 把状态放单机内存 | 扩容后消息丢失 | 状态外置到共享存储 |
| 不做鉴权 | 任何人可连 | 握手时校验令牌并绑定用户 |
| 不限制消息大小 | 大消息打爆内存 | 限制帧大小与频率 |
| 忽略代理超时 | 连接被中间设备断开 | 心跳间隔小于空闲超时 |
| 不处理 `onclose` 清理 | 定时器与监听泄漏 | 关闭时释放资源 |
| 假设消息一定有序到达 | 逻辑错乱 | 用序号与时间戳校验，必要时重排 |
| 无消息持久化 | 断线期间消息丢失 | 离线消息落库并支持拉取 |

## 自测清单

- [ ] 能按方向与延迟要求选对推送方案。
- [ ] 客户端实现心跳、退避重连与消息队列。
- [ ] 握手阶段完成鉴权与用户绑定。
- [ ] 多实例部署用共享存储或消息广播同步。
- [ ] 有断线补偿机制（离线消息或事件重放）。

## 动手练习


> 本课练习重点：围绕「WebSocket、SSE、心跳」完成复述、实验和交付，每个结果都要能被别人检查。

先抓一次真实请求或画出协议交互，再注入延迟或丢包，最后解释每层变化。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「WebSocket 与实时通信」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「SSE」是什么关系？

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
- 至少覆盖「WebSocket」和「SSE」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：WebSocket 与 HTTP 的关键区别是？

- **正确判断**：一次握手后在同一条连接上双向通信
- **判断依据**：正确答案是「一次握手后在同一条连接上双向通信」，本课在「为什么需要 WebSocket」中说明：WebSocket 通过一次 HTTP 握手升级协议，之后在同一条 TCP 连接上双向通信。HTTP 是请求-响应，WebSocket 支持服务端主动推送。本课还在「服务端要点」中说明：鉴权：握手阶段校验 Token，避免连接后长时间占用资源。本课还在「服务端要点」中说明：心跳与超时：定期 ping/pong，清理半开连接。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：WebSocket 断线后必须实现？

- **正确判断**：心跳、指数退避重连与消息序号补齐
- **判断依据**：长连接会因网络与代理超时断开，客户端要能自愈并补齐消息。其他选项：断线后要实现心跳、指数退避重连与消息序号补齐。针对「WebSocket 断线后必须实现，」，本课在「前端使用」中说明：前端必须实现：心跳、重连、消息去重与顺序处理。本课还在「前端使用」中说明：断线后要能补齐漏掉的消息（用序号或游标）。本课还在「本课小结」中说明：WebSocket 只提供「双向管道」，可靠性要靠自己补齐：心跳、重连、序号、ACK、背压与鉴权。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：多实例部署时消息如何跨节点广播？

- **正确判断**：用 Redis Pub/Sub 或消息队列转发
- **判断依据**：正确答案是「用 Redis Pub/Sub 或消息队列转发」，本课在「服务端要点」中说明：水平扩展：多实例之间用 Redis Pub/Sub、NATS 或 Kafka 转发消息。连接分散在不同实例上，需要共享的消息总线做扇出。本课还在「为什么需要 WebSocket」中说明：HTTP 是请求-响应模式，服务器无法主动推送。本课还在「为什么需要 WebSocket」中说明：轮询（不停发请求）浪费资源，长轮询（挂起请求）实现复杂。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：WebSocket 建立连接的握手阶段使用什么协议？

- **正确判断**：一次带 Upgrade 头部的 HTTP 请求，升级成功后切换为全双工帧协议
- **判断依据**：正确答案是「一次带 Upgrade 头部的 HTTP 请求，升级成功后切换为全双工帧协议」，本课在「服务端要点」中说明：鉴权：握手阶段校验 Token，避免连接后长时间占用资源。复用 HTTP 端口与代理设施，是 WebSocket 易于部署的重要原因。本课还在「为什么需要 WebSocket」中说明：WebSocket 通过一次 HTTP 握手升级协议，之后在同一条 TCP 连接上双向通信。本课还在「服务端要点」中说明：连接数：单机连接数受文件描述符与内存限制，需要容量规划与压测。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：SSE（Server-Sent Events）与 WebSocket 的主要区别是？

- **正确判断**：SSE 是服务器到客户端的单向文本流（基于 HTTP），WebSocket 是全双工
- **判断依据**：只需要服务器推送（如通知、进度）时 SSE 更简单，且能自动重连。其他选项：SSE 是服务器到客户端的单向文本流（基于 HTTP），WebSocket 是全双工，两者并不等价。针对「SSE（Server-Sent Events）与…」，本课在「服务端要点」中说明：背压：慢客户端会拖垮服务，应限制发送队列并在超限时断开。本课还在「为什么需要 WebSocket」中说明：HTTP 是请求-响应模式，服务器无法主动推送。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「WebSocket 与实时通信」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `this.ws = new ____(this.url);`

- **正确判断**：WebSocket / websocket
- **判断依据**：正确答案是「WebSocket」，本课在「本课小结」中说明：WebSocket 只提供「双向管道」，可靠性要靠自己补齐：心跳、重连、序号、ACK、背压与鉴权。本课还在「本课小结」中说明：需要更高实时性或音视频时再考虑 WebRTC。本课示例中还能看到 `Upgrade: websocket` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「WebSocket 与 HTTP 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「WebSocket 断线后必须实现？」的判断依据。
- [ ] 不看解析，能说出「多实例部署时消息如何跨节点广播？」的判断依据。
- [ ] 不看解析，能说出「WebSocket 建立连接的握手阶段使用什么协议？」的判断依据。
- [ ] 不看解析，能说出「SSE（Server-Sent Events）与 WebSocket 的主要区别…」的判断依据。
- [ ] 不看解析，能说出「补全代码：「WebSocket 与实时通信」示例中，下面这行代码缺少哪个关键字或…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `Upgrade: websocket` | \| 握手 \| 一次带 `Upgrade: websocket` 的 HTTP 请求 \| |
| `ip_hash` | \| 负载均衡 \| 需要会话粘性时用一致性哈希或 `ip_hash` \| |
| `last_event_id` | \| 断线补偿 \| 客户端带 `last_event_id` 拉取缺失消息 \| |
| `onclose` | \| 不处理 `onclose` 清理 \| 定时器与监听泄漏 \| 关闭时释放资源 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：WebSocket 与 HTTP 的关键区别是？

**参考回答**：正确答案是「一次握手后在同一条连接上双向通信」，本课在「为什么需要 WebSocket」中说明：WebSocket 通过一次 HTTP 握手升级协议，之后在同一条 TCP 连接上双向通信。HTTP 是请求-响应，WebSocket 支持服务端主动推送。本课还在「服务端要点」中说明：鉴权：握手阶段校验 Token，避免连接后长时间占用资源。本课还在「服务端要点」中说明：心跳与超时：定期 ping/pong，清理半开连接。

### 追问 2：WebSocket 断线后必须实现？

**参考回答**：长连接会因网络与代理超时断开，客户端要能自愈并补齐消息。其他选项：断线后要实现心跳、指数退避重连与消息序号补齐。针对「WebSocket 断线后必须实现，」，本课在「前端使用」中说明：前端必须实现：心跳、重连、消息去重与顺序处理。本课还在「前端使用」中说明：断线后要能补齐漏掉的消息（用序号或游标）。本课还在「本课小结」中说明：WebSocket 只提供「双向管道」，可靠性要靠自己补齐：心跳、重连、序号、ACK、背压与鉴权。

### 追问 3：多实例部署时消息如何跨节点广播？

**参考回答**：正确答案是「用 Redis Pub/Sub 或消息队列转发」，本课在「服务端要点」中说明：水平扩展：多实例之间用 Redis Pub/Sub、NATS 或 Kafka 转发消息。连接分散在不同实例上，需要共享的消息总线做扇出。本课还在「为什么需要 WebSocket」中说明：HTTP 是请求-响应模式，服务器无法主动推送。本课还在「为什么需要 WebSocket」中说明：轮询（不停发请求）浪费资源，长轮询（挂起请求）实现复杂。

### 追问 4：WebSocket 建立连接的握手阶段使用什么协议？

**参考回答**：正确答案是「一次带 Upgrade 头部的 HTTP 请求，升级成功后切换为全双工帧协议」，本课在「服务端要点」中说明：鉴权：握手阶段校验 Token，避免连接后长时间占用资源。复用 HTTP 端口与代理设施，是 WebSocket 易于部署的重要原因。本课还在「为什么需要 WebSocket」中说明：WebSocket 通过一次 HTTP 握手升级协议，之后在同一条 TCP 连接上双向通信。本课还在「服务端要点」中说明：连接数：单机连接数受文件描述符与内存限制，需要容量规划与压测。

### 追问 5：SSE（Server-Sent Events）与 WebSocket 的主要区别是？

**参考回答**：只需要服务器推送（如通知、进度）时 SSE 更简单，且能自动重连。其他选项：SSE 是服务器到客户端的单向文本流（基于 HTTP），WebSocket 是全双工，两者并不等价。针对「SSE（Server-Sent Events）与…」，本课在「服务端要点」中说明：背压：慢客户端会拖垮服务，应限制发送队列并在超限时断开。本课还在「为什么需要 WebSocket」中说明：HTTP 是请求-响应模式，服务器无法主动推送。

## English Overview

**Title:** WebSocket & Realtime

**Summary:** Upgrade, heartbeats, reconnects and scaling.

**Category:** Networking  
**Level:** 高级  
**Key terms:** WebSocket, SSE, 心跳, 重连, 实时通信

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：TCP/IP、HTTP/2、HTTP/3 与现代网络栈
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：WebSocket、SSE、心跳、重连、实时通信
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [RFC Editor](https://www.rfc-editor.org/) | 互联网协议标准 |
| [MDN HTTP](https://developer.mozilla.org/docs/Web/HTTP) | HTTP 语义与浏览器行为 |

> 本课主题：协议升级、心跳重连与水平扩展。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
