## 补充：四种算法实现与配额分配

### 四种算法的伪代码与对照

```text
① 固定窗口
  key = f"{user}:{now // window}"
  count = INCR(key)
  if count == 1: EXPIRE(key, window)
  return count <= limit
  缺点：窗口边界处可能放过 2 倍流量

② 滑动窗口（用两个窗口加权）
  cur = GET(cur_key); prev = GET(prev_key)
  ratio = (window - elapsed) / window
  approx = cur + prev * ratio
  return approx < limit
  优点：平滑，内存只需两个计数器

③ 漏桶：请求入队，按固定速率流出
  适合严格平滑输出，不允许突发

④ 令牌桶：按速率补令牌，桶内容量即突发上限
  允许突发，最常用
```

| 算法 | 允许突发 | 内存 | 精度 | 推荐场景 |
| --- | --- | --- | --- | --- |
| 固定窗口 | 边界处会 | 1 个计数 | 低 | 粗粒度保护 |
| 滑动窗口 | 轻微 | 2 个计数 | 中 | 通用限流 |
| 漏桶 | 不允许 | 队列长度 | 高 | 保护脆弱下游 |
| 令牌桶 | 允许（有上限） | 桶状态 | 高 | **默认选择** |

### 分布式令牌桶（Redis + Lua）

```lua
-- KEYS[1]=桶 key  ARGV: rate（每秒补充）, capacity, now（秒，含小数）, cost
local data = redis.call('HMGET', KEYS[1], 'tokens', 'ts')
local tokens = tonumber(data[1]) or tonumber(ARGV[2])
local ts = tonumber(data[2]) or tonumber(ARGV[3])

local delta = math.max(0, tonumber(ARGV[3]) - ts)
tokens = math.min(tonumber(ARGV[2]), tokens + delta * tonumber(ARGV[1]))

local allowed = 0
if tokens >= tonumber(ARGV[4]) then
  tokens = tokens - tonumber(ARGV[4])
  allowed = 1
end

redis.call('HMSET', KEYS[1], 'tokens', tokens, 'ts', ARGV[3])
redis.call('EXPIRE', KEYS[1], math.ceil(tonumber(ARGV[2]) / tonumber(ARGV[1]) * 2))
return allowed
```

```text
为什么必须用 Lua
  · 读取令牌数 → 计算 → 写回 三步若分开执行，并发下会互相覆盖
  · Lua 在 Redis 中原子执行，保证「检查并扣减」不可分割
  · 同时设置过期时间，避免冷 key 永久占内存
```

### 配额怎么在实例之间分配

| 方式 | 做法 | 问题 |
| --- | --- | --- |
| 全局限流 | 所有实例共用一个 Redis 计数 | Redis 成为瓶颈与单点 |
| 本地限流 | 每实例各自限额 | 总量随实例数放大 |
| 混合（推荐） | 本地挡突发 + 全局控总量 | 实现稍复杂 |

```text
混合方案示例（目标：全局 10000 QPS，10 个实例）
  ① 本地令牌桶：每实例 1200 QPS（留 20% 余量吸收突发）
  ② 全局令牌桶：Redis 中 10000 QPS
  ③ Redis 不可用时：降级为纯本地限流（宁可放过也不打垮自身）
```

### 多维度限流的组合

```text
按优先级从外到内
  ① 全局总配额（保护整个系统）
  ② 接口维度（保护单个热点接口）
  ③ 用户 / 租户维度（防单用户刷爆）
  ④ IP 维度（对未登录请求兜底）

提示：维度越多，Redis 的 key 越多，注意内存与热点问题。
大租户可单独配额，避免「一个租户吃掉全部额度」。
```

### 限流返回什么

| 响应 | 说明 |
| --- | --- |
| HTTP 429 | 标准状态码，明确表示限流 |
| `Retry-After` 头 | 告诉客户端多久后重试，避免立刻重试 |
| 明确的错误码 | 让客户端区分「限流」与「服务异常」 |

```text
与熔断的区别
  限流：保护自己（入口流量控制）
  熔断：保护调用方（下游故障时快速失败）
  二者组合，再加降级，才构成完整保护网
```

### 自查清单

- [ ] 默认使用令牌桶，允许有上限的突发
- [ ] 分布式限流用 Lua 保证原子性
- [ ] 有本地兜底，Redis 不可用时不至于全站拒绝
- [ ] 按用户与接口双维度限流，大租户单独配额
- [ ] 限流返回 429 并带 `Retry-After`

