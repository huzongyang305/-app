## 算法选型速查

| 算法 | 预处理 | 匹配 | 适用 |
| --- | --- | --- | --- |
| 朴素匹配 | 无 | O(nm) | 极短文本 |
| KMP | O(m) | O(n+m) | 单模式、需要线性保证 |
| Rabin-Karp | O(m) | 平均 O(n+m) | 多模式、二维匹配、滚动哈希 |
| Z 算法 | O(n+m) | O(n+m) | 与前缀相关的问题 |
| AC 自动机 | O(总模式长) | O(n + 匹配数) | 多模式匹配（敏感词过滤） |
| 后缀数组 / 后缀自动机 | O(n log n) | O(m log n) | 子串统计、最长重复子串 |

## KMP 模板

```python
def build_lps(pattern: str):
    """lps[i] = pattern[0..i] 的最长相等前后缀长度。"""
    lps = [0] * len(pattern)
    length = 0                      # 当前最长前缀长度
    i = 1
    while i < len(pattern):
        if pattern[i] == pattern[length]:
            length += 1
            lps[i] = length
            i += 1
        elif length:
            length = lps[length - 1]   # 失配：回退到次长前后缀
        else:
            lps[i] = 0
            i += 1
    return lps


def kmp_search(text: str, pattern: str):
    """返回所有匹配起始下标，O(n + m)。"""
    if not pattern:
        return [0]
    lps = build_lps(pattern)
    result, j, i = [], 0, 0
    while i < len(text):
        if text[i] == pattern[j]:
            i += 1
            j += 1
            if j == len(pattern):
                result.append(i - j)
                j = lps[j - 1]          # 继续找下一次匹配
        elif j:
            j = lps[j - 1]
        else:
            i += 1
    return result


def rabin_karp(text: str, pattern: str, base: int = 131, mod: int = 10**9 + 7):
    """滚动哈希：平均线性，哈希相同时再精确比较，避免碰撞误判。"""
    n, m = len(text), len(pattern)
    if m == 0 or m > n:
        return []
    power = pow(base, m - 1, mod)
    target = 0
    window = 0
    for ch in pattern:
        target = (target * base + ord(ch)) % mod
    for ch in text[:m]:
        window = (window * base + ord(ch)) % mod
    result = []
    for i in range(n - m + 1):
        if window == target and text[i:i + m] == pattern:
            result.append(i)
        if i < n - m:
            window = ((window - ord(text[i]) * power) * base + ord(text[i + m])) % mod
    return result
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| KMP 失配时把 `i` 回退 | 退化成 O(nm) | 失配只回退 `j`，`i` 不回退 |
| `lps` 定义记错（长度 vs 位置） | 跳转错位 | 明确 `lps[i]` 表示前缀长度并统一 |
| 忘记处理后缀重叠匹配 | 漏掉重叠出现 | 匹配成功后 `j = lps[j-1]` 继续 |
| 空模式串未处理 | 越界或死循环 | 单独返回 `[0]` 或按约定处理 |
| Rabin-Karp 只比哈希不验证 | 碰撞导致误报 | 哈希相等后再逐字符比较 |
| 滚动哈希忘记取模 | 整数溢出 | 每步取模 |
| 减法后出现负数 | 哈希错误 | 加模数再取模 |
| 用哈希值判断子串相等 | 可能误判 | 需要确定性时用 KMP 或后缀结构 |
| 模式串比文本长 | 越界 | 先判断长度 |
| 用 `str.find` 却要求线性最坏 | 实现依赖具体引擎 | 有严格要求时自己实现 KMP |

## 自测清单

- [ ] 能独立写出 `build_lps` 与 `kmp_search`。
- [ ] 说明 KMP 为什么是 O(n+m)。
- [ ] 会用滚动哈希处理多模式或二维匹配。
- [ ] 知道哈希碰撞的处理方式。
- [ ] 多模式匹配优先考虑 AC 自动机。
