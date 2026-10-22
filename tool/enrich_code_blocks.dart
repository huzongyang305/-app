// P0：给代码块过少的课程补一组可验证的代码对照。
//
// 只处理明确列出的课程 ID，并且要求每门课至少新增 4 个代码块；
// `text` 围栏用于伪代码/命令清单，不参与编译；Python 片段会经过
// 语法校验（见 tool/verify_code_blocks.dart）。
//
// 用法：
//   dart tool/enrich_code_blocks.dart [--apply] [--lesson=id]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String sectionHeading = '## 代码对照与验证';

/// 课程 ID → 章节正文（含代码块）。
const Map<String, String> supplements = <String, String>{
  'css_layout': '''
这一节用三组对照把 `display`、`position` 与响应式断点串起来：先看默认流式布局，
再逐条替换属性，最后观察盒模型与定位的变化。

### 对照一：Flex 与 Grid 解决不同问题

```css
.row {
  display: flex;
  gap: 12px;
  align-items: center;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
}
```

Flex 适合一维排列，Grid 适合二维网格。用 `auto-fit` 搭配 `minmax` 可以在容器
变窄时自动减少列数，不需要额外媒体查询。

### 对照二：盒模型与 `box-sizing`

```css
.card {
  box-sizing: border-box;
  width: 100%;
  padding: 16px;
  border: 1px solid #d0d7de;
}
```

默认的 `content-box` 会让 `width` 再加上内边距和边框，从而撑破父容器；
`border-box` 把内边距和边框算进宽度，是布局可预测的前提。

### 对照三：定位与层叠上下文

```css
.toolbar {
  position: sticky;
  top: 0;
  z-index: 10;
  background: #ffffff;
}

.badge {
  position: absolute;
  top: 8px;
  right: 8px;
}
```

`sticky` 在滚动到阈值前表现为相对定位，之后固定在容器内；`absolute` 则相对最近的
定位祖先定位，因此父元素通常需要 `position: relative`。

### 验证清单

| 检查项 | 通过标准 |
| --- | --- |
| 一维排列 | 用 Flex 实现且间距由 `gap` 控制，没有用 margin 堆叠 |
| 二维网格 | 用 Grid 实现，窗口变窄时列数自动变化 |
| 盒模型 | 设置 `border-box` 后，加内边距不会撑破容器 |
| 定位 | `absolute` 元素相对预期的父元素定位，`z-index` 生效 |
''',
  'cryptography': '''
这一节把「对称加密、非对称加密、摘要与签名」放回可验证的代码里：先算出摘要，
再做完整性校验，最后理解 TLS 为什么需要两套密钥。

### 对照一：摘要与雪崩效应

```python
import hashlib

payload = b"transfer:100"
digest = hashlib.sha256(payload).hexdigest()
print(digest)
print(hashlib.sha256(b"transfer:101").hexdigest())
```

输入只改一个字符，摘要就会完全不同，这就是雪崩效应，也是校验数据没有被篡改的基础。

### 对照二：HMAC 完整性校验

```python
import hashlib
import hmac

key = b"shared-secret"
message = b"amount=100&to=alice"
mac = hmac.new(key, message, hashlib.sha256).hexdigest()

recomputed = hmac.new(key, message, hashlib.sha256).hexdigest()
print(mac == recomputed)
print(hmac.compare_digest(mac, recomputed))
```

直接比较摘要可能泄露时序信息，`compare_digest` 用恒定时间比较，是生产代码的默认做法。

### 对照三：混合加密的密钥分工

```text
发送方                                             接收方
  |-- 用对称密钥加密数据 --------------------------->|
  |-- 用接收方公钥加密对称密钥 -------------------->|
  |                                                 |-- 用私钥解出对称密钥
  |                                                 |-- 用对称密钥解密数据
```

对称密钥负责速度，非对称密钥负责分发。TLS 握手正是先协商出会话密钥，
再用它加密后续流量，因此证书只需要保证公钥可信。

### 验证清单

| 检查项 | 通过标准 |
| --- | --- |
| 摘要 | 改变一个字节后摘要完全不同 |
| 完整性 | 用 HMAC 或 AEAD 校验，不直接比较明文摘要 |
| 密钥管理 | 私钥不进入日志、镜像和版本库 |
| 协议 | 明确使用 AEAD 模式，避免自行拼接加密与 MAC |
''',
  'auth_oauth': '''
这一节把授权码流程拆成可观察的每一步，并给出令牌校验的最小实现。

### 对照一：授权码 + PKCE 流程

```text
浏览器                应用后端              授权服务器
  |-- 1. 生成 code_verifier 与 code_challenge -->|
  |-- 2. 跳转授权端点（带 challenge） ---------->|
  |<-- 3. 返回授权码 ----------------------------|
  |-- 4. 用授权码 + verifier 换令牌 ------------>|
  |<-- 5. 返回 access_token / refresh_token -----|
```

PKCE 让公开客户端不必内置密钥：即使授权码被截获，没有 `code_verifier` 也换不到令牌。

### 对照二：JWT 载荷校验

```python
import base64
import hashlib
import hmac
import json

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

header = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
payload = b64url(json.dumps({"sub": "u1", "exp": 1893456000}).encode())
signing_input = f"{header}.{payload}".encode()
signature = b64url(hmac.new(b"secret", signing_input, hashlib.sha256).digest())
token = f"{header}.{payload}.{signature}"
print(token.split(".")[2] == signature)
```

校验时必须先验证签名，再检查 `exp`、`aud`、`iss`；顺序颠倒会让攻击者用未签名的载荷探测系统。

### 对照三：常见错误对照

| 错误做法 | 后果 | 修正 |
| --- | --- | --- |
| 把令牌放在 URL 参数 | 进入日志与浏览器历史 | 用 Authorization 头或 HttpOnly Cookie |
| 只在前端校验过期 | 过期令牌仍可访问接口 | 服务端每次校验签名与 exp |
| refresh_token 永不过期 | 泄露后长期可用 | 轮换并绑定设备或会话 |

### 验证清单

- 授权码只能使用一次，重放会被拒绝。
- 令牌校验同时检查签名、有效期、受众与签发者。
- 退出登录会失效服务端会话，而不只是清除本地存储。
''',
  'ipc_io': '''
这一节用 Python 标准库演示进程间通信的三种典型方式，并对照它们的适用场景。

### 对照一：管道传递结构化数据

```python
from multiprocessing import Pipe, Process

def worker(sender):
    sender.send({"task": "resize", "size": [640, 480]})
    sender.close()

if __name__ == "__main__":
    receiver, sender = Pipe(duplex=False)
    process = Process(target=worker, args=(sender,))
    process.start()
    sender.close()
    print(receiver.recv())
    process.join()
```

管道适合点对点、消息量适中的场景：发送方写入的对象会被序列化，接收方按顺序读出。

### 对照二：共享内存与锁

```python
from multiprocessing import Lock, Process, Value

def increment(counter, lock):
    for _ in range(1000):
        with lock:
            counter.value += 1

if __name__ == "__main__":
    counter = Value("i", 0)
    lock = Lock()
    processes = [Process(target=increment, args=(counter, lock)) for _ in range(4)]
    [p.start() for p in processes]
    [p.join() for p in processes]
    print(counter.value)
```

共享内存避免复制开销，但并发写必须加锁；漏掉锁会出现丢失更新，且难以复现。

### 对照三：三种机制怎么选

| 机制 | 适合的数据 | 主要成本 |
| --- | --- | --- |
| 管道 / 队列 | 消息、任务派发 | 序列化与复制 |
| 共享内存 | 大块数组、图像缓冲 | 同步与生命周期管理 |
| 文件与套接字 | 跨机器、持久化数据 | 延迟与协议设计 |

### 验证清单

- 每个进程都明确退出条件，主进程会等待子进程回收。
- 共享状态都有锁或原子操作保护，并通过多次运行验证结果稳定。
- 跨机器场景优先用套接字或消息队列，而不是共享内存。
''',
  'gateway': '''
这一节给出网关的三个核心配置：路由、限流与健康检查，并说明它们的顺序。

### 对照一：声明式路由与上游

```yaml
upstream: api_cluster
  strategy: round_robin
  members:
    - http://10.0.0.11:8080
    - http://10.0.0.12:8080

routes:
  - path: /api/v1/orders
    methods: [GET, POST]
    upstream: api_cluster
    timeout_ms: 2000
```

路由先匹配请求，再把流量交给上游；超时和重试写在路由层，避免每个服务重复实现。

### 对照二：Nginx 反向代理片段

```text
location /api/ {
    proxy_pass http://api_cluster;
    proxy_connect_timeout 1s;
    proxy_read_timeout 2s;
    proxy_next_upstream error timeout http_502;
}
```

代理层负责连接与重试策略，应用层仍然要处理幂等，否则重试会放大副作用。

### 对照三：限流与降级顺序

| 顺序 | 动作 | 说明 |
| --- | --- | --- |
| 1 | 认证与鉴权 | 未通过直接拒绝，不占用后端资源 |
| 2 | 限流与配额 | 保护后端不被突发流量击穿 |
| 3 | 路由与重试 | 只对幂等请求重试，设置最大次数 |
| 4 | 熔断与降级 | 依赖持续失败时快速返回兜底结果 |

### 验证清单

- 限流阈值有压测数据支撑，而不是凭感觉设置。
- 重试只覆盖幂等接口，并设置退避与上限。
- 网关自身有健康检查与就绪探针，滚动发布不中断流量。
''',
  'distributed_fundamentals': '''
这一节把 CAP、一致性级别与复制策略放进可观察的流程里，再给出选型对照。

### 对照一：网络分区下的两种选择

```text
正常状态
  客户端 --> 节点 A <--> 节点 B

网络分区（A、B 无法互通）
  选择 CP：拒绝写入，保证读到的都是最新已提交数据
  选择 AP：各自接受写入，恢复后再按策略合并冲突
```

分区不是异常，而是分布式系统的常态；设计时要先回答「分区期间宁可拒绝还是宁可过期」。

### 对照二：一致性级别对照

| 级别 | 读取保证 | 典型代价 |
| --- | --- | --- |
| strong | 总能读到最新提交 | 延迟高、可用性受分区影响 |
| read-your-writes | 能读到自己的写入 | 需要会话粘性或版本令牌 |
| eventual | 最终一致，短期可能过期 | 需要处理冲突与过期读 |

### 对照三：幂等写入伪代码

```text
def apply(order_id, payload):
    if store.exists(order_id):
        return store.get(order_id)        # 重放直接返回旧结果
    result = execute(payload)
    store.put(order_id, result)           # 以业务 ID 作为去重键
    return result
```

至少一次投递必然带来重复，幂等键把「重复」变成可安全忽略的事件。

### 验证清单

- 明确写出一致性级别，并在压测中验证过期窗口。
- 所有会重试的写操作都有幂等键。
- 分区恢复后的冲突合并策略有测试用例覆盖。
''',
  'high_availability': '''
这一节把冗余、健康检查与故障切换串成一条可演练的链路。

### 对照一：健康检查与就绪判断

```python
import time

class Health:
    def __init__(self):
        self.last_success = time.time()

    def mark_success(self):
        self.last_success = time.time()

    def is_ready(self, timeout=3.0):
        return time.time() - self.last_success < timeout

health = Health()
health.mark_success()
print(health.is_ready())
print(health.is_ready(timeout=-1))
```

存活检查回答「进程要不要重启」，就绪检查回答「能不能接流量」。把两者混用会导致
依赖抖动时所有实例同时被摘除。

### 对照二：故障切换时序

```text
主节点心跳正常       主节点失联              新主节点选出
  |--------------------X----------------------|
  检测窗口           选举窗口             流量恢复
  （秒级）           （秒级）             （需要客户端重连）
```

切换时间等于检测加选举加上层重连，评估可用性时要把三段都算进去。

### 对照三：单点排查清单

| 层次 | 常见单点 | 冗余方式 |
| --- | --- | --- |
| 接入 | 单个网关或 VIP | 多实例 + 健康探测 |
| 应用 | 单副本部署 | 多副本 + 反亲和调度 |
| 数据 | 单主库 | 主从/多副本 + 自动切换 |
| 依赖 | 单可用区 | 跨可用区部署 |

### 验证清单

- 至少做过一次真实的主节点故障演练，而不只是理论推演。
- 切换期间客户端有重试与退避，不会雪崩。
- 演练后有记录：检测耗时、切换耗时、影响范围。
''',
  'distributed_id': '''
这一节对比常见 ID 方案，并给出可运行的生成与校验代码。

### 对照一：UUID 与自增 ID 的取舍

```python
import uuid

generated = uuid.uuid4()
print(generated)
print(len(str(generated).replace("-", "")))
```

UUID 无需中心协调，适合分库分表；代价是占用空间大、索引局部性差。

### 对照二：雪花号的结构

```text
64 位 = 1 位符号 + 41 位时间戳 + 10 位机器号 + 12 位序列号
                    |             |            |
                    |             |            +-- 同一毫秒内最多 4096 个
                    |             +-- 最多 1024 个节点
                    +-- 毫秒级，可用约 69 年
```

趋势递增让 B+ 树索引写入更友好，但时钟回拨必须显式处理，否则会生成重复 ID。

### 对照三：常见方案对照

| 方案 | 有序性 | 依赖 | 适用场景 |
| --- | --- | --- | --- |
| 数据库自增 | 强 | 单库或号段服务 | 单库、中小规模 |
| 号段模式 | 趋势递增 | 中心号段服务 | 高并发且需要有序 |
| UUID v4 | 无序 | 无 | 分布式无协调生成 |
| 雪花号 | 趋势递增 | 机器号分配 | 大规模分片表 |

### 验证清单

- 生成器在时钟回拨时有明确策略（等待、报错或降级）。
- ID 长度与索引类型匹配，不会因过长拖慢写入。
- 机器号分配有唯一性保障并记录在案。
''',
  'design_patterns': '''
这一节把设计模式还原成「问题、结构、代价」三段，并给出可运行的策略模式实现。

### 对照一：策略模式消除条件分支

```python
from dataclasses import dataclass
from typing import Callable

@dataclass
class Order:
    amount: float
    kind: str

pricing: dict[str, Callable[[Order], float]] = {
    "normal": lambda order: order.amount,
    "vip": lambda order: order.amount * 0.9,
    "promo": lambda order: order.amount - 20,
}

def total(order: Order) -> float:
    return pricing[order.kind](order)

print(total(Order(100, "vip")))
print(total(Order(100, "promo")))
```

把变化点封装成策略，新增折扣只需要注册一个函数，而不是修改调用方的分支。

### 对照二：模式选型速查

| 模式 | 解决的问题 | 引入的代价 |
| --- | --- | --- |
| 策略 | 多种算法可替换 | 类或函数数量增加 |
| 工厂 | 创建逻辑集中 | 需要维护注册表 |
| 观察者 | 一对多通知 | 事件顺序与内存泄漏风险 |
| 装饰器 | 动态叠加职责 | 调试时调用链变长 |

### 对照三：不该用模式的时候

```text
只有一个实现，且短期内不会变化      -> 直接写函数
需求尚未稳定，分支少于三处          -> 先用简单条件
模式引入的间接层无法被测试覆盖      -> 说明抽象收益不成立
```

模式是为了隔离已确认的变化点；在没有变化点的地方引入抽象，只会增加阅读成本。

### 验证清单

- 每个模式都能对应到一个具体的扩展场景。
- 新增一种实现无需修改既有调用方。
- 抽象层的单元测试覆盖了各分支，而不是只测正常路径。
''',
};

void main(List<String> args) {
  final apply = args.contains('--apply');
  final onlyLesson = _stringOption(args, '--lesson=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  var touched = 0;
  var addedBlocks = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      final supplement = supplements[id];
      if (supplement == null) continue;
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final markdown = file.readAsStringSync();
      if (markdown.contains(sectionHeading)) continue;
      final anchor = _findAnchor(markdown);
      if (anchor < 0) {
        stderr.writeln('跳过 $id：找不到插入锚点');
        continue;
      }
      final updated =
          '${markdown.substring(0, anchor)}\n$sectionHeading\n\n$supplement'
          '\n${markdown.substring(anchor + 1)}';
      final blocks =
          RegExp(r'^```', multiLine: true).allMatches(supplement).length ~/ 2;
      touched++;
      addedBlocks += blocks;
      if (apply) file.writeAsStringSync(updated);
    }
  }
  stdout.writeln(apply ? '=== 已写回代码对照 ===' : '=== 试运行（未写文件）===');
  stdout.writeln('涉及课程  $touched');
  stdout.writeln('新增代码块 $addedBlocks');
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

/// 依次尝试多个锚点，兼容没有「复习与迁移」章节的早期课程。
int _findAnchor(String markdown) {
  const anchors = <String>['\n## 复习与迁移', '\n## 考点精讲', '\n## 内容元数据'];
  for (final anchor in anchors) {
    final index = markdown.indexOf(anchor);
    if (index >= 0) return index;
  }
  return -1;
}
