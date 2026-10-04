## 非比较排序对照

| 算法 | 复杂度 | 空间 | 稳定 | 适用 |
| --- | --- | --- | --- | --- |
| 计数排序 | O(n+k) | O(n+k) | 是 | 整数、范围小（k 与 n 同量级） |
| 桶排序 | 平均 O(n+k) | O(n+k) | 取决于桶内排序 | 数据均匀分布 |
| 基数排序 LSD | O(d(n+k)) | O(n+k) | 是 | 定长整数、字符串 |
| 基数排序 MSD | O(d(n+k)) | O(n+k) | 是 | 字符串字典序 |

## 模板

```python
def counting_sort(nums, max_value=None):
    """计数排序：适用于整数且值域不大。"""
    if not nums:
        return []
    top = max_value if max_value is not None else max(nums)
    counts = [0] * (top + 1)
    for value in nums:
        counts[value] += 1
    for i in range(1, len(counts)):        # 前缀和，得到每个值的结束位置
        counts[i] += counts[i - 1]
    result = [0] * len(nums)
    for value in reversed(nums):           # 逆序保证稳定性
        counts[value] -= 1
        result[counts[value]] = value
    return result


def radix_sort(nums):
    """LSD 基数排序：按位从低到高，每位必须是稳定排序。"""
    if not nums:
        return []
    arr = nums[:]
    exp = 1
    top = max(arr)
    while top // exp > 0:
        buckets = [[] for _ in range(10)]
        for value in arr:
            buckets[(value // exp) % 10].append(value)
        arr = [value for bucket in buckets for value in bucket]
        exp *= 10
    return arr


def external_sort_chunks(records, chunk_size):
    """外部排序第一步：分块排序后写临时文件（示意）。"""
    chunks = []
    for start in range(0, len(records), chunk_size):
        chunk = sorted(records[start:start + chunk_size])
        chunks.append(chunk)               # 实际实现应写入磁盘
    return chunks                          # 第二步：用最小堆做多路归并


import heapq

def k_way_merge(chunks):
    """多路归并：最小堆维护每路当前最小值。"""
    heap = []
    for index, chunk in enumerate(chunks):
        if chunk:
            heapq.heappush(heap, (chunk[0], index, 0))
    result = []
    while heap:
        value, chunk_index, offset = heapq.heappop(heap)
        result.append(value)
        nxt = offset + 1
        chunk = chunks[chunk_index]
        if nxt < len(chunk):
            heapq.heappush(heap, (chunk[nxt], chunk_index, nxt))
    return result
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 计数排序用于值域极大的数据 | 数组开不下 | 值域 k 必须与 n 同量级 |
| 直接排序负数 | 下标为负越界 | 先求最小值并整体平移 |
| 计数排序不逆序写回 | 失去稳定性 | 逆序遍历原数组 |
| 基数排序某位用不稳定排序 | 结果错乱 | 每位必须稳定（常用计数排序） |
| 基数排序处理负数 | 分组错误 | 分离符号或用偏移 |
| 桶排序数据分布不均匀 | 退化成 O(n²) | 数据需近似均匀，或桶内换更好算法 |
| 外部排序一次读入全量 | 内存溢出 | 分块排序 + 多路归并 |
| 多路归并每轮扫所有路 | 复杂度升高 | 用最小堆取当前最小 |
| 认为非比较排序通用 | 只能用于整数或可分解的键 | 需要比较语义时仍用比较排序 |
| 忽略稳定性需求 | 结果顺序不符合业务预期 | 明确是否需要稳定 |

## 自测清单

- [ ] 能说出计数/桶/基数排序的适用条件。
- [ ] 计数排序用前缀和确定位置并逆序写回。
- [ ] 基数排序每位使用稳定排序。
- [ ] 外部排序 = 分块排序 + 多路归并。
- [ ] 能用最小堆实现 k 路归并。
