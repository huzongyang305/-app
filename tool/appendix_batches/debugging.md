## 调试手段速查

| 手段 | 适用 | 说明 |
| --- | --- | --- |
| 断点 | 逻辑分支 | 逐行观察变量 |
| 条件断点 | 循环中特定情况 | 表达式为真才暂停 |
| 日志 | 生产环境 | 结构化、带追踪 ID |
| 二分定位 | 大范围改动 | 逐步缩小到具体变更 |
| 最小复现 | 复杂问题 | 剥离无关依赖 |
| 对比实验 | 环境差异 | 只改一个变量 |
| 抓包/追踪 | 跨服务问题 | 全链路观察 |
| 性能剖析 | 慢 | profiler 找热点 |
| 内存分析 | 泄漏 | 堆快照对比 |

## 日志设计速查

| 要点 | 做法 |
| --- | --- |
| 结构化 | JSON 或键值对，便于检索 |
| 级别 | ERROR、WARN、INFO、DEBUG 分级 |
| 追踪 | 每请求一个 trace ID 并全链路透传 |
| 上下文 | 记录关键参数与用户标识（脱敏） |
| 不记录 | 口令、令牌、身份证等敏感信息 |
| 采样 | 高频日志采样，避免成本失控 |
| 轮转 | 按大小与时间轮转并保留期限 |

```python
import bisect
import logging
import uuid
from contextlib import contextmanager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s trace=%(trace_id)s %(message)s",
)

@contextmanager
def log_context(**fields):
    """给一次操作绑定 trace id 与上下文，便于全链路检索。"""
    logger = logging.LoggerAdapter(
        logging.getLogger("app"),
        {"trace_id": fields.pop("trace_id", uuid.uuid4().hex[:8]), **fields},
    )
    try:
        yield logger
    except Exception:
        logger.exception("操作失败")
        raise

def bisect_change(items: list, is_bad) -> int:
    """二分定位：找出第一个判定为「坏」的提交或输入。"""
    low, high = 0, len(items)
    while low < high:
        mid = (low + high) // 2
        if is_bad(items[mid]):
            high = mid
        else:
            low = mid + 1
    return low

def minimal_repro(cases: list, reproduces) -> list:
    """最小复现：逐项剔除仍能复现的输入。"""
    result = list(cases)
    index = 0
    while index < len(result):
        candidate = result[:index] + result[index + 1:]
        if candidate and reproduces(candidate):
            result = candidate
        else:
            index += 1
    return result

with log_context(request_id="r-1") as log:
    log.info("开始处理")

print(bisect_change([1, 2, 3, 4, 5], lambda x: x >= 4))
print(minimal_repro([1, 2, 3, 4], lambda c: 4 in c))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 靠猜改代码 | 问题反复出现 | 先复现，再定位，最后修复 |
| 一次改多处 | 无法归因 | 一次只改一个变量 |
| 只看报错最后一行 | 漏掉根因 | 从最底层 `Caused by` 看起 |
| 日志无追踪 ID | 跨服务无法串起来 | 全链路透传 trace ID |
| 日志打印敏感信息 | 泄漏 | 脱敏并禁止记录凭证 |
| 用 `print` 调试生产 | 无法检索与轮转 | 用日志框架分级输出 |
| 生产开启 DEBUG | 磁盘与性能受影响 | 按需动态调整级别 |
| 忽略时间同步 | 时序错乱 | 统一 NTP 与时区 |
| 只修症状不修根因 | 同类问题再发 | 找到根因并加回归测试 |
| 不复盘不沉淀 | 重复排查 | 记 runbook 与自动化脚本 |

## 自测清单

- [ ] 调试遵循「复现、定位、修复、验证、沉淀」流程。
- [ ] 日志结构化并带 trace ID，敏感信息脱敏。
- [ ] 会用二分定位与最小复现缩小范围。
- [ ] 生产环境按需调整日志级别并做好轮转。
- [ ] 每次问题都沉淀为文档或自动化脚本。
