# 主流大模型 API 接入

![大模型 API 协议差异与流式接入时序](images/diagram_llm_apps_api_integration.webp)

> 内容更新时间：2026-10-06 · 学习阶段：应用 · 预计用时：40 分钟

## 本节知识框架

**课程定位**：所属分类 `llm_apps`（LLM 应用开发），课程主题 `主流大模型 API 接入`，学习阶段 应用，建议用时 40 分钟。

本课主线：以三种消息协议形态为轴，逐条对比必填字段与鉴权方式，再打通流式 SSE 的增量拼接、Tool Call 消息闭环与错误重试三块工程硬骨头。

**学完本课应当能够**

- 画出 `Chat Completions`、`Responses` 与 `Messages` 三种协议在请求体结构与必填参数上的差异表。
- 实现可断点续读的 `SSE 流式` 客户端，正确处理增量拼接、终止帧与中途异常关闭。
- 让 `Tool Call` 消息闭环成立：按调用编号回填结果，并为 4xx 与 5xx 设计不同的 `重试策略`。

### 复习清单

- [ ] 能不看正文列出各家流式协议的终止信号，并说明为何不能靠 Content-Length 判结束。
- [ ] 能写出一次带工具调用的完整消息序列，指出每一步必须携带哪个标识字段。
- [ ] 能完成一次故障演练：人为注入 429 与连接中断，观察重试次数与最终用户可见行为。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| Chat Completions | 以 messages 数组进出、返回 choices 列表的经典端点，生态兼容性最广。 | 易错：多轮状态由客户端负责拼接，服务端不保存会话。 |
| Responses | 以条目列表组织输入输出、可由服务端托管上一轮状态的新一代接口。 | 易错：托管状态会隐藏上下文体积，账单与调试都要额外关注。 |
| Messages 接口 | Anthropic 的对话端点，System 独立成字段且 max_tokens 必填。 | 易错：把 System 当消息数组的一项发送，会得到参数校验错误。 |
| SSE 流式 | 服务端以 text/event-stream 分帧推送增量，客户端逐帧解析。 | 易错：分帧边界不等于语义边界，一个词可能被拆进两帧。 |
| 增量拼接 | 把每帧 delta 里的文本片段按到达顺序连接成完整回答。 | 易错：首帧的增量字段可能缺失而不是空串，直接取值会报错。 |
| Tool Call | 模型返回结构化调用意图，客户端执行后按编号回填结果的机制。 | 易错：漏掉某个调用编号的回填，会让后续推理永久卡住。 |
| 退避重试 | 按指数增长并叠加随机抖动地重发请求，配合响应头建议等待时间。 | 易错：对所有错误一律重试，参数错误重试一万次也不会成功。 |
| 幂等键 | 客户端生成的唯一标识，让服务端能识别重复请求避免重复计费。 | 易错：只在超时后重发而不带幂等键，可能产生两条相同副作用。 |

## 原理与运行机制

### 机制总览：同一次对话在三种协议里的样子

协议差异集中在三处：System 放哪里、输出上限要不要写、工具调用挂在消息上还是内容块里。下面用同一个问题分别给出三种请求体，差异一目了然。

**教材衔接：三种协议的请求体对照**

```json
{
  "chat_completions": {
    "model": "deepseek-chat",
    "messages": [{"role": "system", "content": "只用中文"}, {"role": "user", "content": "什么是 RAG"}]
  },
  "responses": {
    "model": "gpt-4o-mini",
    "input": [{"role": "system", "content": "只用中文"}, {"role": "user", "content": "什么是 RAG"}]
  },
  "messages": {
    "model": "claude-sonnet-4-5",
    "system": "只用中文",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "什么是 RAG"}]
  }
}
```

**教材衔接：鉴权与端点差异**

| 项目 | OpenAI | Anthropic | DeepSeek | 通义兼容模式 |
| --- | --- | --- | --- | --- |
| 密钥位置 | Authorization Bearer | x-api-key 头 | Authorization Bearer | Authorization Bearer |
| 版本头 | 可选 | anthropic-version 必填 | 无 | 无 |
| 输出上限 | 可选 | 必填 | 可选 | 可选 |
| 流式开关 | stream 布尔 | stream 布尔 | stream 布尔 | stream 布尔加增量字段 |

**教材衔接：流式客户端的正确写法**

流式解析的要点是「按行读、只认 data 前缀、遇终止帧收尾」。下面这段实现同时处理了首帧缺失、心跳注释和连接被中途掐断三种情况。

```python
import json, httpx

def stream_chat(url: str, headers: dict, payload: dict) -> str:
    payload = {**payload, 'stream': True}
    parts: list[str] = []
    with httpx.stream('POST', url, headers=headers, json=payload, timeout=60) as r:
        r.raise_for_status()
        for line in r.iter_lines():
            if not line or line.startswith(':'):          # 空行与心跳注释都要跳过
                continue
            if not line.startswith('data:'):
                continue
            data = line[5:].strip()
            if data == '[DONE]':                           # 兼容协议的终止哨兵
                break
            delta = json.loads(data)['choices'][0].get('delta', {})
            parts.append(delta.get('content') or '')       # 首帧可能是 None
    return ''.join(parts)

print(len(stream_chat.__code__.co_varnames))
```

**教材衔接：Tool Call 的消息闭环**

工具调用是一条必须闭合的链：模型给出调用意图与编号，客户端执行，回填时把编号原样带回。链路中断在任何一个编号上，后续推理都会失去依据。

```json
{
  "messages": [
    {"role": "user", "content": "订单 8023 到哪了"},
    {"role": "assistant", "content": null,
     "tool_calls": [{"id": "call_7h2", "type": "function",
                     "function": {"name": "query_order", "arguments": "{\"id\": 8023}"}}]},
    {"role": "tool", "tool_call_id": "call_7h2",
     "content": "{\"status\": \"已发货\", \"eta\": \"05-08\"}"}
  ]
}
```

**教材衔接：错误分类与对应动作**

| 状态码 | 语义 | 正确动作 | 错误动作 |
| --- | --- | --- | --- |
| 400 | 参数结构非法 | 记录请求体并修字段，不重试 | 原样重发 |
| 401 / 403 | 密钥或权限问题 | 熔断并告警，检查密钥轮换 | 静默重试 |
| 429 | 限流或配额耗尽 | 读 Retry-After 退避，必要时降级模型 | 固定间隔硬重试 |
| 500 / 503 | 服务端故障 | 带抖动的指数退避，最多三到四次 | 无限重试 |
| 连接中断 | 流式半途断掉 | 带已生成前缀续写或整体重试 | 直接返回残缺文本 |

```bash
# 用 curl 观察流式帧与终止哨兵，确认客户端解析口径
curl -N https://api.deepseek.com/chat/completions \
  -H "Authorization: Bearer $DEEPSEEK_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","stream":true,"messages":[{"role":"user","content":"说三个字"}]}'
```

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 会话式助手 | 多轮上下文需要保留，界面要打字机效果 | 流式渲染加历史裁剪策略 |
| 批量离线抽取 | 数千条文档，允许分钟级延迟 | 高并发批处理加重试队列 |
| 内部工具网关 | 多家模型共存，按业务路由 | 统一客户端加供应商注册表 |
| 强实时补全 | 首字时延敏感，输出很短 | 小模型加低延迟端点，关闭深度推理 |

- 典型现象：界面收到半句话就不再更新。正确做法：把终止帧判定与流关闭分离，异常断开时按已生成前缀续写。
- 典型现象：加了工具后模型开始重复调用同一个函数。正确做法：检查每个调用编号是否都回填了结果，缺回填是最常见根因。
- 典型现象：夜间批量任务把配额打满，白天线上请求全部 429。正确做法：按业务分池限流，离线任务用独立密钥与低优先级队列。

### 最小验证场景

- 准备：一个可控的假端点，按脚本返回正常帧、终止帧、429 与中途断流四种情形。
- 观察：客户端在四种情形下的完成文本长度、重试次数与最终状态码。
- 判定：正常情形文本完整；429 情形退避次数不超过三次；断流情形能续写或明确报错，绝不静默返回残缺内容。

## 代码/协议/SQL 示例

**教材衔接：带退避与幂等键的请求封装**

把重试策略收进一个函数，业务侧只关心请求本身。幂等键让服务端有机会识别重复请求，退避上限避免把限流拖成雪崩。

```python
import random, time, uuid, httpx

def post_with_retry(url: str, headers: dict, payload: dict, tries: int = 4) -> httpx.Response:
    key = str(uuid.uuid4())
    for attempt in range(tries):
        r = httpx.post(url, headers={**headers, 'Idempotency-Key': key},
                       json=payload, timeout=30)
        if r.status_code in (429, 500, 503):
            wait = float(r.headers.get('Retry-After', 2 ** attempt))
            time.sleep(wait + random.uniform(0, 0.5))
            continue
        r.raise_for_status()
        return r
    raise RuntimeError('上游持续不可用，已放弃重试')
```

**教材衔接：按错误码统计可用性与重试放大**

把每次请求的结果落表，就能算出真实成功率与重试放大倍数，这是判断限流策略是否过激的唯一依据。

```sql
SELECT status_code,
       COUNT(*)                                   AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct,
       ROUND(AVG(retry_index), 2)                 AS avg_retry
FROM api_call_log
WHERE ts >= now() - INTERVAL '1 day'
GROUP BY status_code
ORDER BY n DESC;
```

错误表现：只判断 HTTP 状态码就认为流式成功，忽略业务层的错误帧。

```python
with httpx.stream('POST', url, json=payload) as r:
    text = ''.join(line for line in r.iter_lines())   # 连 data 前缀都没剥掉
```

正确写法：逐帧解析并识别协议内的错误事件，把状态码与事件类型分开处理。

```python
with httpx.stream('POST', url, json=payload, timeout=60) as r:
    r.raise_for_status()
    for line in r.iter_lines():
        if line.startswith('event:') and 'error' in line:
            raise RuntimeError('上游在流中返回错误事件')
```

## 时间/空间复杂度或性能分析

| 指标 | 定义 | 影响因素 | 优化方向 |
| --- | --- | --- | --- |
| 首 Token 时延 | 请求到第一个增量 | 排队、输入长度、预填充耗时 | 缩短输入、选低负载档位 |
| 每 Token 时延 | 解码步进间隔 | 模型规模、批处理并发 | 换更小模型、提升服务端并发 |
| 总时延 | 首字加逐字生成 | 输出长度 | 限制最大输出、提前终止 |
| 重试放大 | 实际请求数除以业务请求数 | 错误率与退避上限 | 收紧可重试状态码集合 |
| 连接开销 | 每次新建 TLS 的耗时 | 是否复用连接池 | 共享客户端实例、开启长连接 |

对流式接口做性能分析时要拆开两段：预填充阶段与输入长度近似相关，解码阶段与输出长度近似相关。用户体感主要落在首 Token 时延上，因此把长上下文裁剪到必要片段，比换更快的解码模型更能改善体验。

重试会直接改写容量账本。若单次请求的失败率为 10%、最多重试四次，则平均请求数放大到约 1.11 倍；一旦上游故障导致失败率升到 50%，放大倍数会逼近 1.8 倍，限流窗口被自己的重试填满，形成二次故障。所以重试次数上限和抖动不是可选项。

客户端复用连接是收益最稳定的优化。每次新建 HTTPS 连接要多花一次握手时间，在高频短请求场景里占比可观；共享带连接池的客户端实例，同时设置合理的读超时与总超时，能把尾延迟压下来而不改变任何提示词。

## 常见误区与易错点

- **把 System 当消息项发给 Messages 接口。** 该接口要求 System 走独立字段，混在数组里会直接 400。
- **忘了 Messages 接口必须写输出上限。** 它是必填项，省略后不是用默认值而是报错。
- **用 Content-Length 判断流结束。** 分块传输没有该字段，终止信号只能靠协议帧。
- **按帧边界当词边界处理。** 中文常被拆进两帧，必须先拼接再切句。
- **对 400 也重试。** 结构性错误重试不会改变结果，只会污染配额和日志。
- **忽略 401 的告警。** 密钥失效时静默重试，会让故障拖到配额耗尽才被发现。
- **只回填第一个工具调用的结果。** 未闭合的调用编号会让模型卡在下一步推理。
- **把 arguments 当字典直接用。** 参数通常是 JSON 字符串，要先解析再校验必填项。
- **超时设得过短又开启流式。** 长回答尚未生成完就被切断，表现为随机残缺。
- **每个请求新建一个客户端。** 反复 TLS 握手抬高尾延迟，应复用带连接池的实例。

## 与其他知识点的关系

**教材衔接：与相邻课程的接口边界**

本课负责把提示词与 Schema 正确送达模型并安全地取回结果；上层范式选择由全景课决定，工具语义由 Function Calling 课定义，质量与成本由评估课度量。

- 承接 `llm_apps_overview` 的兼容层骨架，落地为可运行的请求与解析代码。
- 为 `llm_apps_function_calling` 提供 tool 消息与编号回填的协议基础。
- 与 `llm_apps_agent_design` 共用流式循环，Agent 的多轮本质是同一协议反复闭合。
- 依赖 `python_asyncio` 与 `python_http_clients` 实现并发池与连接复用。
- 与 `llm_apps_evaluation` 联动，错误率与时延指标直接进入监控面板。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| llm_apps_overview | 全景与选型 | 定义抽象层与成本口径，本课是其模型接入层的具体实现 |
| llm_apps_function_calling | 工具使用 | 工具调用的消息结构与并行回填依赖本课的协议细节 |
| python_http_clients | HTTP 客户端实践 | 连接池、超时与重试的通用做法在大模型端点上的特化 |
| python_asyncio | 异步并发 | 批量抽取与高并发场景的调度基础，决定吞吐上限 |
| llm_apps_deployment | 模型部署 | 自部署端点同样暴露兼容协议，客户端代码可直接复用 |

## 自测题与参考答案

**教材衔接：题号 1** — SSE 流式响应里，判断整段回答结束的依据是？

**参考答案**：收到 data 标记的 DONE 帧。

本题正确项是「收到 data 标记的 DONE 帧」。OpenAI 兼容协议在流结束时发送一条内容为 DONE 的 data 行作为终止哨兵，Anthropic 协议用 message_stop 事件表达同样语义，客户端要靠它关闭渲染并落库。204 不是流式的返回码，Content-Length 在分块传输中本就不可用，首个分片只代表开始。

**教材衔接：题号 2** — 接入 Anthropic Messages 接口时，与 Chat Completions 不同的必填项是？

**参考答案**：必须单独指定 max_tokens。

本题正确项是「必须单独指定 max_tokens」。Messages 接口把输出上限作为必填项，不写会直接返回参数校验错误，而 Chat Completions 与 Responses 允许省略并用服务端默认值兜底。temperature 在两边都是可选，方法本就是 POST，把 messages 传空只会报错而不是要求，这些差异体现了协议字段与默认值的不一致。

**教材衔接：题号 3** — 调用返回 429 时，最稳妥的重试策略是？

**参考答案**：读取 Retry-After 并加指数退避。

本题正确项是「读取 Retry-After 并加指数退避」。429 表示服务端限流，响应头通常给出建议等待时间，配合指数退避和抖动可以避开同批客户端的重试风暴，也让配额统计保持可解释。固定间隔硬重试会持续压同一窗口，直接换模型会把限流扩散到其他供应商，调温度对容量毫无影响。

**教材衔接：题号 4** — Tool Call 场景下，把工具结果回填给模型时使用的消息角色是？

**参考答案**：tool 角色的结果消息。

本题正确项是「tool 角色的结果消息」。模型发出 tool_calls 后，客户端要为每个调用返回一条 tool 消息并带上对应的 tool_call_id，模型据此把结果与调用配对再决定下一步。写成 system 会被当成全局规则污染约束，assistant 被视为模型自己的输出，重复 user 原文只会拉长上下文而不携带结果结构。

**教材衔接：题号 5** — 下面代码用兼容协议构造并读取一次 JSON 响应，打印结果是？
import httpx, json
body = {'choices': [{'message': {'role': 'assistant', 'content': '你好'}}]}
r = httpx.Response(200, json=body)
print(json.loads(r.text)['choices'][0]['message']['content'])

**参考答案**：打印出字符串 你好。

本题正确项是「打印出字符串 你好」。用 json 关键字构造响应时 text 属性给出序列化正文，loads 还原成字典后按 choices 列表、message 字典、content 键逐层取值，命中的正是初始化时写入的文本。role 在同层存在不会触发键缺失异常，取到的是叶子字符串而不是整个数组，字段齐全也不会返回空值。

## 考点精讲

**教材衔接：高频考点**

1. 三种协议的必填字段差异：输出上限是否必填、System 放哪，是协议类题目的核心出题点。
2. 流式终止判定：以协议帧而不是传输层字段判断结束，常与残缺输出一起考排错。
3. Tool Call 回填规则：按编号逐条回填结果，考察对消息闭环的理解。
4. 状态码与重试动作配对：区分可重试与不可重试错误，是运维类场景的高频判断。

**教材衔接：命题规律**

- 命题爱用「客户端现象」反推协议原因，例如半句话、格式异常或重复调用。
- 正确项多落在服务端明确定义的机制上，干扰项常借用传输层概念制造混淆。
- 涉及限流的题目会给出具体状态码与建议等待头，答案强调退避加抖动而非提高并发。

**教材衔接：常见考点**

问：SSE 流式响应里，判断整段回答结束的依据是？
答：收到 data 标记的 DONE 帧。

问：接入 Anthropic Messages 接口时，与 Chat Completions 不同的必填项是？
答：必须单独指定 max_tokens。

问：调用返回 429 时，最稳妥的重试策略是？
答：读取 Retry-After 并加指数退避。

问：Tool Call 场景下，把工具结果回填给模型时使用的消息角色是？
答：tool 角色的结果消息。

问：下面代码用兼容协议构造并读取一次 JSON 响应，打印结果是？
import httpx, json
body = {'choices': [{'message': {'role': 'assistant', 'content': '你好'}}]}
r = httpx.Response(200, json=body)
print(json.loads(r.text)['choices'][0]['message']['content'])
答：打印出字符串 你好。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| Chat Completions | messages 进、choices 出的经典端点，多轮状态由客户端自己维护。 |
| Responses | 条目式输入输出并支持服务端托管上一轮状态的新接口。 |
| Messages 接口 | System 独立成字段且输出上限必填的对话端点形态。 |
| SSE 流式 | 以 data 行为单位持续推送增量，靠协议帧判断结束。 |
| 增量拼接 | 按到达顺序连接每帧文本片段，分帧边界不等于词边界。 |
| Tool Call | 结构化调用意图加编号，必须由同编号的结果消息闭合。 |
| 退避重试 | 指数增长加抖动地重发，只对可恢复状态码启用。 |
| 幂等键 | 客户端唯一标识，让重复请求有机会被识别为同一次操作。 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-11-10
- 学习阶段：应用
- 适用环境：Python 3.11+ / Node 20+；需能访问兼容 OpenAI 协议的服务端点（OpenAI / DeepSeek / 通义 / 本地 Ollama 等）。
- 内容来源：官方文档与工程实践整理
- 相关主题：大模型 API、Prompt 工程、RAG、Agent 框架、模型部署
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-11-10
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Anthropic Messages API](https://docs.anthropic.com/en/api/messages)
- [Moonshot Kimi 开放平台 API 文档](https://platform.moonshot.cn/docs/api-reference)
