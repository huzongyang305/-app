## IEEE 754 速查

| 格式 | 符号位 | 指数位 | 尾数位 | 十进制有效位 |
| --- | --- | --- | --- | --- |
| 单精度 float | 1 | 8 | 23 | 约 7 位 |
| 双精度 double | 1 | 11 | 52 | 约 15 到 16 位 |
| 半精度 half | 1 | 5 | 10 | 约 3 位 |

| 特殊值 | 条件 | 说明 |
| --- | --- | --- |
| 零 | 指数与尾数全 0 | 有 +0 与 -0 |
| 次正规数 | 指数全 0、尾数非 0 | 表示极小数，精度下降 |
| 无穷 | 指数全 1、尾数全 0 | 溢出或除以 0 产生 |
| NaN | 指数全 1、尾数非 0 | 0/0、无穷减无穷产生 |

```python
import math

# 1. 不要用 == 比较浮点
print(0.1 + 0.2 == 0.3)                       # False
print(math.isclose(0.1 + 0.2, 0.3))           # True

# 2. 金额用整数分或 Decimal
from decimal import Decimal, ROUND_HALF_UP
total = Decimal("19.9") * 3
print(total.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))   # 59.70

# 3. 判 NaN 与无穷
nan_value = float("nan")
print(nan_value != nan_value, math.isnan(nan_value))             # True True
print(math.isinf(float("inf")))                                  # True

# 4. 求和误差：大数吃小数
values = [1e16, 1.0, -1e16]
print(sum(values))                                               # 0.0，丢失了 1.0
print(math.fsum(values))                                         # 1.0，精确求和

# 5. 比较要给出容差
def almost_equal(a, b, rel_tol=1e-9, abs_tol=1e-12) -> bool:
    return math.isclose(a, b, rel_tol=rel_tol, abs_tol=abs_tol)

assert almost_equal(0.1 + 0.2, 0.3)
```

## 校验码速查

| 编码 | 检错能力 | 纠错能力 | 典型用途 |
| --- | --- | --- | --- |
| 奇偶校验 | 检奇数位错误 | 无 | 内存、串口 |
| 校验和 | 检部分错误 | 无 | 简单协议 |
| CRC-32 | 检突发错误强 | 无 | 网络帧、文件校验 |
| 海明码 | 检两位错 | 纠一位错 | ECC 内存 |
| 里德-所罗门 | 检多个符号错 | 纠多个符号错 | 二维码、光盘、深空通信 |
| BCH 码 | 可参数化 | 可参数化 | NAND 闪存 |

```python
import zlib

def crc32_hex(data: bytes) -> str:
    """CRC-32：网络与文件校验的常用实现。"""
    return f"{zlib.crc32(data) & 0xFFFFFFFF:08X}"


def hamming_encode_nibble(nibble: int) -> int:
    """海明(7,4)：4 位数据加 3 位校验，可纠 1 位错。"""
    d1, d2, d3, d4 = ((nibble >> i) & 1 for i in range(4))
    p1 = d1 ^ d2 ^ d4
    p2 = d1 ^ d3 ^ d4
    p3 = d2 ^ d3 ^ d4
    return (p1 << 6) | (p2 << 5) | (d1 << 4) | (p3 << 3) | (d2 << 2) | (d3 << 1) | d4


assert hamming_encode_nibble(0b1011) >= 0
print(f"CRC-32 of 'hello' = {crc32_hex(b'hello')}")
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `==` 比较浮点结果 | 明明相等却判为不等 | 用 `math.isclose` 或容差 |
| 用 `double` 算金额 | 分位出现 0.0000000001 偏差 | 用整数分或 `Decimal` |
| 用 `x != x` 以外的值判 NaN | 判断错误 | 用 `math.isnan` |
| 大数小数混合求和 | 小数被吃掉 | 用 `math.fsum` 或按量级排序累加 |
| 认为 `0.1` 精确可表示 | 精度分析错误 | 十进制小数多为二进制无限循环 |
| 直接相减判断相等 | 误差被放大 | 用相对容差 |
| 认为 CRC 能纠错 | 期望落空 | CRC 只检错，纠错需海明/RS |
| 校验和不加长度与顺序信息 | 漏检换位错误 | 用带位置的校验或更强的校验算法 |
| 用 MD5 做完整性校验 | 碰撞风险 | 安全场景用 SHA-256 及以上 |
| 忽略次正规数与精度下降 | 极小值计算异常 | 注意数值范围并做缩放 |

## 自测清单

- [ ] 记得双精度是 1 + 11 + 52 位结构。
- [ ] 浮点比较一律使用容差，不用 `==`。
- [ ] 金额使用整数分或 `Decimal`。
- [ ] 知道 NaN 与自身比较为 false。
- [ ] 分得清检错码（CRC）与纠错码（海明、RS）。
