# Java WebSocket 实时通信

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：30 分钟


![WebSocket 实时通信链路](images/diagram_javaweb_websocket.webp)

## 本节知识框架

### 学习目标
- 理解 WebSocket 协议与 HTTP 的区别
- 掌握 Spring WebSocket 服务端实现
- 学会使用 STOMP 协议进行消息路由
- 了解 WebSocket 在生产环境中的部署策略

### 前置知识
- Spring Boot 基础（javaweb_spring_boot）
- RESTful API 设计（javaweb_restful）
- HTTP 协议基础

### 复习清单
- [ ] HTTP 的无状态特性与长连接需求
- [ ] Spring Boot 自动配置原理
- [ ] REST 请求-响应模式的局限性

## 核心概念定义

| 术语 | 一句话说明 |
|------|-----------|
| WebSocket | 全双工通信协议，客户端和服务器可同时发送数据 |
| STOMP | 简单文本导向消息协议，为 WebSocket 提供消息路由框架 |
| 全双工 | 通信双方可以同时发送和接收数据 |
| 心跳机制 | 定期发送探测包以维持连接和检测连接状态 |
| 消息代理 | 接收、路由和分发消息的中间件（如 RabbitMQ、ActiveMQ） |

## 原理与运行机制

### 生活类比
把 WebSocket 想象成打电话：HTTP 像发短信（你发一条，对方回一条），WebSocket 像打电话（双方可以随时说话，不用等对方说完再发）。

STOMP 则像电话里的"转接分机"——你说"我要找 101 房间的人"，交换机就帮你把消息送到正确的地方。

### WebSocket 握手流程

```text
客户端                          服务器
  |                              |
  |-- HTTP Upgrade Request ----->|  (Sec-WebSocket-Key)
  |                              |
  |<-- 101 Switching Protocols --|  (Sec-WebSocket-Accept)
  |                              |
  |<==== 全双工 WebSocket 连接 ====>|
  |                              |
```

### 连接建立后发生了什么

握手成功后，连接从 HTTP 的"一问一答"切换为帧（frame）的双向传输。客户端和服务器发送的每条消息都会被拆成一个或多个帧，帧头用 1 个比特标记 FIN（是否最后一帧）、7 个比特表示 opcode（文本、二进制、关闭、Ping、Pong），后面的掩码位说明载荷是否由客户端加密。浏览器发出的帧必须带掩码，服务器返回的帧不带掩码，这条规则可以防止缓存代理把 WebSocket 流量误当成普通 HTTP 响应。

一条连接的生命周期分为建立、活跃、半关闭和关闭四个阶段。任意一方调用 close() 会发送 opcode 为 0x8 的关闭帧，另一方回复关闭帧后 TCP 连接才真正断开；如果只关 TCP 而不走关闭帧，对端只能看到连接重置，无法区分"正常下线"和"网络故障"。Ping/Pong 帧（opcode 0x9/0xA）用于探测对端是否还活着：收到 Ping 必须尽快回 Pong，业务代码通常不需要手动处理，容器和 STOMP 心跳会代劳。

理解帧结构的意义在于排查问题：抓包时看到 101 之后的二进制流量并不是"乱码"，而是按帧格式编码的文本或心跳；连接空闲一段时间后被中间设备切断，往往是因为代理只认 Ping/Pong，而应用层没有配置心跳。

### Spring WebSocket 架构

```text
┌─────────────┐
│  客户端      │
│  (浏览器)    │
└──────┬──────┘
       │ WebSocket
       │ + STOMP
┌──────▼──────┐
│  Spring     │
│  WebSocket  │
│  Handler    │
└──────┬──────┘
       │
┌──────▼──────┐
│  消息代理    │
│  (内置/外部) │
└──────┬──────┘
       │
┌──────▼──────┐
│  订阅客户端  │
└─────────────┘
```

## 典型应用场景

### 实时聊天系统
- 在线客服、即时通讯
- 群聊消息广播
- 消息已读/未读状态同步

### 实时数据推送
- 股票行情、汇率变动
- 体育比分实时更新
- 服务器监控告警

### 协作编辑
- 多人文档协同编辑（如 Google Docs）
- 代码实时协作（如 VS Code Live Share）
- 白板绘图同步

### 在线游戏
- 多人实时对战
- 游戏状态同步
- 聊天室功能

## 代码/协议/SQL 示例

### 最小示例：Spring WebSocket 配置

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }
    
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}
```

### 完整示例：消息控制器

```java
@Controller
public class ChatController {
    
    @MessageMapping("/chat.sendMessage")
    @SendTo("/topic/public")
    public ChatMessage sendMessage(@Payload ChatMessage chatMessage) {
        chatMessage.setTimestamp(LocalDateTime.now());
        return chatMessage;
    }
    
    @MessageMapping("/chat.addUser")
    @SendTo("/topic/public")
    public ChatMessage addUser(@Payload ChatMessage chatMessage,
                               SimpMessageHeaderAccessor headerAccessor) {
        headerAccessor.getSessionAttributes()
                      .put("username", chatMessage.getSender());
        chatMessage.setType(ChatMessage.MessageType.JOIN);
        chatMessage.setTimestamp(LocalDateTime.now());
        return chatMessage;
    }
}
```

### 客户端连接示例（JavaScript）

```javascript
const socket = new SockJS('/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({}, function(frame) {
    // 订阅公共频道
    stompClient.subscribe('/topic/public', function(message) {
        const chatMessage = JSON.parse(message.body);
        displayMessage(chatMessage);
    });
    
    // 发送消息
    stompClient.send("/app/chat.sendMessage", {}, 
        JSON.stringify({sender: 'Alice', content: 'Hello!'}));
});
```

### 点对点消息（私聊）

```java
@MessageMapping("/chat.sendPrivateMessage")
public void sendPrivateMessage(@Payload ChatMessage chatMessage,
                                SimpMessageHeaderAccessor headerAccessor) {
    String receiverUsername = chatMessage.getReceiver();
    String senderUsername = (String) headerAccessor.getSessionAttributes()
                                                    .get("username");
    
    // 发送到特定用户的私有队列
    simpMessagingTemplate.convertAndSendToUser(
        receiverUsername,
        "/queue/messages",
        chatMessage
    );
}
```

### 心跳配置

```java
@Configuration
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Override
    public void configureWebSocketTransport(WebSocketTransportRegistry registry) {
        registry.setMessageSizeLimit(8192)
                .setSendTimeLimit(10 * 1000)
                .setSendBufferSizeLimit(512 * 1024);
    }
    
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue")
                .setHeartbeatValue(new long[]{10000, 10000})
                .setTaskScheduler(new DefaultManagedTaskScheduler());
    }
}
```

### 断线重连与消息补偿

心跳只能让连接"晚一点断"，不能保证永不断线。移动网络切换、Wi-Fi 掉线、服务器发布重启都会让连接突然消失，所以客户端必须实现指数退避重连：第一次失败后等待 1 秒，之后 2、4、8 秒递增，设置上限（如 30 秒）并加入随机抖动，避免大量客户端在同一时刻重连把服务器打垮。重连成功后要重新订阅 /topic 和 /queue，因为订阅关系保存在连接会话里，新连接不会自动继承旧订阅。

重连期间的消息需要补偿机制。最简做法是服务端为每个会话维护自增序号，客户端重连时带上最后收到的序号，服务端从该序号之后补发；更完整的方案是把消息先写入数据库或消息队列，客户端用消息 ID 去重，确保"至少一次"投递不会造成重复展示。聊天、订单状态这类不能丢消息的场景，不能只依赖 WebSocket 的内存广播。

还需要区分"可重试"和"不可重试"的失败：网络超时、502、连接被重置可以退避重连；握手返回 401/403 则说明凭证失效，应停止重连并引导用户重新登录，否则会在后台形成无效重连风暴。

## 时间/空间复杂度或性能分析

### 连接资源消耗
- **内存**：每个 WebSocket 连接约占用 2-5KB 内存
- **CPU**：空闲连接几乎不消耗 CPU，消息处理时按需使用
- **带宽**：帧头仅 2-14 字节，比 HTTP 请求头（数百字节）轻量得多

### 可扩展性考虑
- **单机连接数**：普通服务器可支撑 10 万+ 并发连接
- **水平扩展**：需要外部消息代理（Redis/RabbitMQ）实现跨节点消息广播
- **负载均衡**：使用 sticky session 确保同一客户端连接到同一服务器

### 性能优化建议
1. 启用消息压缩（permessage-deflate 扩展）
2. 合理设置心跳间隔（避免过频增加负载）
3. 使用连接池管理数据库访问
4. 对高频消息做节流/去抖处理

按 Little 定律估算：若平均每条消息处理耗时 2ms、单机目标 5000 条/秒，则需要约 10 个工作线程才能把消息队列排空；线程再多会因上下文切换抵消收益。实际压测时应同时观察连接数、消息速率和 P99 延迟，三者任一先到瓶颈就停止加机器，先优化慢消费者或拆分主题。

## 常见误区与易错点

| 错误 | 现象 | 修法 |
|------|------|------|
| 用 WebSocket 替代所有 HTTP | 页面加载也用 WS，增加复杂度 | 静态资源仍用 HTTP，仅实时数据用 WS |
| 忽略连接断开处理 | 用户离线后消息丢失 | 实现重连机制 + 消息持久化 |
| 未做消息大小限制 | 大消息导致 OOM | 配置 `setMessageSizeLimit()` |
| 心跳缺失 | 代理/防火墙断开空闲连接 | 启用 STOMP 心跳（10-30 秒间隔） |
| 认为 WebSocket 一定比 HTTP 快 | 小数据量、低频请求下两者差距很小，握手和连接维护反而更贵 | 低频场景继续用 HTTP，按业务选择 |
| 重连后未恢复订阅 | 重连成功但收不到消息 | 在连接建立回调里重新 SUBSCRIBE |
| 把用户输入直接当广播主题 | 任意用户可订阅他人频道，造成越权 | 服务端校验订阅目的地与用户身份 |

## 与其他知识点的关系

### 直接相关
- **javaweb_spring_boot**：WebSocket 基于 Spring Boot 自动配置
- **javaweb_restful**：REST 用于 CRUD，WebSocket 用于实时推送，互补使用
- **javaweb_spring_security**：WebSocket 连接需要身份认证和权限控制

### 间接相关
- **network**：理解 TCP/IP、HTTP 协议基础
- **distributed**：分布式系统中 WebSocket 的会话粘性
- **devops**：WebSocket 服务的部署和监控

## 自测题与参考答案

### 题目 1
WebSocket 协议与 HTTP 的主要区别是什么？
- A. WebSocket 是单向通信
- B. WebSocket 支持全双工通信
- C. WebSocket 不使用 TCP
- D. WebSocket 只能发送文本

**答案**：B  
**解析**：WebSocket 是全双工协议，客户端和服务器可同时发送数据。HTTP 是请求-响应模式，客户端发起请求，服务器返回响应。

### 题目 2
STOMP 协议在 WebSocket 中的作用是什么？
- A. 加密数据传输
- B. 提供消息路由和订阅机制
- C. 压缩消息内容
- D. 管理连接池

**答案**：B  
**解析**：STOMP（Simple Text Oriented Messaging Protocol）为 WebSocket 提供消息路由框架，支持订阅/发布模式，让消息能发送到指定的主题或队列。

### 题目 3
为什么需要配置 WebSocket 心跳？
- A. 提高传输速度
- B. 防止代理/防火墙断开空闲连接
- C. 加密通信内容
- D. 压缩数据帧

**答案**：B  
**解析**：许多代理服务器和防火墙会断开长时间无数据传输的连接。心跳机制定期发送探测包，保持连接活跃。

## 考点精讲

### 考点 1

WebSocket 协议与 HTTP 的主要区别是什么？

A. WebSocket 是单向通信

B. WebSocket 不使用 TCP，改用 UDP 传输  

C. WebSocket 支持全双工通信，双方可同时发送数据

D. WebSocket 只能发送文本

**正确答案：C**

**详细解释**：WebSocket 是全双工协议，建立连接后客户端和服务器可随时互发消息，无需反复建立连接。 HTTP 每次请求都要携带完整头部，而 WebSocket 建立一次连接后帧头只有几个字节，因此高频实时消息的传输开销更小。 握手阶段仍然复用 HTTP 的 Upgrade 机制，通过 101 状态码切换协议，因此鉴权通常放在握手请求的 Cookie 或 token 里。 本题正确项是「WebSocket 支持全双工通信，双方可同时发送数据」。

---

### 考点 2

STOMP 协议在 WebSocket 中的作用是什么？

A. 加密数据传输，对每条消息体做对称加密  

B. 提供消息路由和订阅机制（主题/队列）

C. 压缩消息内容

D. 管理连接池

**正确答案：B**

**详细解释**：STOMP 为 WebSocket 提供消息路由框架，支持 /topic（广播）和 /queue（点对点）两种消息模式。 如果不使用 STOMP，开发者需要自己设计消息格式和路由规则，STOMP 把这些约定标准化，Spring 也内置了对应的消息代理支持。 本题正确项是「提供消息路由和订阅机制（主题/队列）」。

---

### 考点 3

为什么需要配置 WebSocket 心跳？

A. 提高传输速度，合并小帧再发送  

B. 防止代理/防火墙断开空闲连接

C. 加密通信内容

D. 压缩数据帧

**正确答案：B**

**详细解释**：许多代理和防火墙会断开长时间无数据传输的连接，心跳定期发送探测包保持连接活跃。 浏览器端 WebSocket API 本身不带心跳，通常由应用层定时发送 ping 帧或业务心跳消息，并在超时后主动重连。 心跳间隔要小于中间设备的空闲超时，常见取值是 30 秒左右，同时服务端要清理超时未响应的会话，防止连接泄漏。 本题正确项是「防止代理/防火墙断开空闲连接」。

---

### 考点 4

Spring WebSocket 中 @MessageMapping 注解的作用是什么？

A. 定义 REST 端点，按路径匹配  

B. 将客户端消息路由到对应的处理方法

C. 配置数据库

D. 定义安全规则

**正确答案：B**

**详细解释**：@MessageMapping 类似 @RequestMapping，把客户端发送到特定目标地址的消息路由到对应的 Java 方法。 方法内部可以配合 @SendTo 指定广播目标，或用 SimpMessagingTemplate 向指定用户会话推送消息，灵活控制消息流向。 本题正确项是「将客户端消息路由到对应的处理方法」。

---

### 考点 5

WebSocket 连接数过多时的扩展策略是什么？

A. 增加单机内存，通过堆内存换连接数，避免跨节点广播消息  

B. 使用外部消息代理（Redis/RabbitMQ）实现跨节点消息广播

C. 减少心跳

D. 禁用压缩

**正确答案：B**

**详细解释**：单机连接数有上限，通过外部消息代理让多个服务器实例共享消息，实现水平扩展。 除了消息代理，还要考虑把连接注册表放在 Redis 中，才能知道某个用户在哪个节点上，从而定向推送点对点消息。 跨节点广播要区分广播和定向两种需求，广播用订阅主题，定向推送则要按用户标识路由到目标节点所在的会话。 本题正确项是「使用外部消息代理（Redis/RabbitMQ）实现跨节点消息广播」。

---

### 考点 6

题目：在「Java WebSocket 实时通信」的术语表里，下列术语与解释的配对哪些是正确的？（多选）
A. 「Heartbeat」：心跳包，维持连接活跃  
B. 「SockJS」：WebSocket 降级方案，不支持 WS 时自动回退  
C. 「Payload」：Simple Text Oriented Messaging Protocol，消息路由协议  
D. 「STOMP」：消息体，实际传输的数据  
正确答案：AB

**解析**：本题正确项是「Heartbeat」：心跳包，维持连接活跃，以及「SockJS」：WebSocket 降级方案，不支持 WS 时自动回退，这两组配对与术语表一致。另外两组把术语和解释张冠李戴：「Payload」被安上了Simple Text Oriented Messaging Protocol，消息路由协议的解释，「STOMP」反而拿到了消息体，实际传输的数据的定义，所以两组都不能选。复习时回到「Java WebSocket 实时通信」的术语速查表逐条核对，配对题考的是定义里描述的对象和边界，而不是术语的字面长相。

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| WebSocket | 全双工通信协议，RFC 6455 标准 |
| STOMP | Simple Text Oriented Messaging Protocol，消息路由协议 |
| SockJS | WebSocket 降级方案，不支持 WS 时自动回退 |
| Topic | 广播频道，所有订阅者接收 |
| Queue | 私有队列，仅指定用户接收 |
| Heartbeat | 心跳包，维持连接活跃 |
| Payload | 消息体，实际传输的数据 |

## 参考资料与复核

### 参考资料
1. [RFC 6455 - The WebSocket Protocol](https://datatracker.ietf.org/doc/html/rfc6455)
2. [Spring WebSocket 文档](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket)
3. [STOMP 协议规范](https://stomp.github.io/stomp-specification-1.2.html)

### 复核日期
- 内容创建：2026-10-26

- 最后复核：2026-10-04
- 下次复核：2027-10-10

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：通用开发环境；本课聚焦 WebSocket。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：javaweb websocket
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全