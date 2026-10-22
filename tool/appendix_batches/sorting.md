## 选择依据速查

| 需求 | 推荐算法 | 原因 |
| --- | --- | --- |
| 通用排序 | 快速排序 / Timsort | 平均最快、缓存友好 |
| 要求稳定 | 归并排序 / Timsort | 相等元素保持原顺序 |
| 空间受限 | 堆排序 | O(1) 额外空间 |
| 近乎有序 | 插入排序 / Timsort | 接近 O(n) |
| 整数且范围小 | 计数排序 | O(n+k) 线性 |
| 多位数整数或字符串 | 基数排序 | 按位稳定排序 |
| 只取 TopK | 堆 / 快速选择 | 不必全排序 |
| 链表排序 | 归并排序 | 不需要随机访问 |
| 外部大文件 | 外部归并排序 | 分块 + 多路归并 |

稳定性速查：

| 稳定 | 不稳定 |
| --- | --- |
| 冒泡、插入、归并、计数、基数、Timsort | 选择、快速、堆、希尔 |

## 快速排序实现要点

```python
import random

def quick_sort(nums):
    """三路快排：处理大量重复元素更高效，最坏情况用随机主元规避。"""
    if len(nums) <= 1:
        return nums[:]

    pivot = random.choice(nums)               # 随机主元降低最坏概率
    less = [x for x in nums if x < pivot]
    equal = [x for x in nums if x == pivot]
    greater = [x for x in nums if x > pivot]
    return quick_sort(less) + equal + quick_sort(greater)


# 原地分区版（Lomuto）：额外空间 O(1)，递归栈 O(log n)
def partition(arr, low, high):
    pivot = arr[high]
    i = low - 1
    for j in range(low, high):
        if arr[j] <= pivot:
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
    arr[i + 1], arr[high] = arr[high], arr[i + 1]
    return i + 1
```

要点：随机或三数取中选主元可避免已排序数据退化成 O(n²)；小数组（<16）切换插入排序更快；重复元素多用三路分区。

## 语言内置排序速查

| 语言 | 调用 | 稳定性 | 备注 |
| --- | --- | --- | --- |
| Python | `sorted(x)` / `x.sort()` | 稳定 | Timsort，`key` 只调用一次 |
| Java | `Arrays.sort` / `Collections.sort` | 对象稳定，基本类型不稳定 | 并行排序 `parallelSort` |
| JavaScript | `arr.sort(cmp)` | 现代引擎稳定 | 默认按字符串比较，数字必须传比较函数 |
| C++ | `std::sort` / `std::stable_sort` | 前者不稳定 | `sort` 平均 O(n log n) |
| Go | `sort.Slice` / `slices.Sort` | 不稳定 | 稳定版 `slices.SortStableFunc` |
| Rust | `sort` / `sort_by` / `sort_unstable` | 前者稳定 | 不稳定版更快 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 对已排序数据用固定主元快排 | O(n²) | 随机主元或三数取中 |
| JS 里 `[10, 9, 1].sort()` | 得到 `[1, 10, 9]` | 传 `(a, b) => a - b` |
| 认为所有排序都稳定 | 结果顺序不符合预期 | 明确算法稳定性 |
| 用比较排序排小范围整数 | 不必要的 O(n log n) | 用计数排序 |
| 排序时比较函数不满足严格弱序 | 崩溃或结果错乱 | 保证 `<` 自洽、不返回 true 表示相等 |
| 用 `key` 里做重计算 | 性能下降 | Python 的 `key` 每元素只调用一次，但重活仍要避免 |
| 需要 TopK 却全量排序 | 浪费时间 | 用堆或快速选择 |
| 原地排序后需要原顺序 | 数据被破坏 | 先复制或用稳定排序 |
| 大文件一次性读入排序 | 内存溢出 | 外部归并排序 |
| 忽略比较成本 | 复杂对象比较很慢 | 先提取 key 再排序（Schwartzian 变换） |

## 自测清单

- [ ] 能按稳定性、空间、数据特征选排序算法。
- [ ] 知道快排最坏 O(n²) 的成因与规避手段。
- [ ] 记得 JS 数字排序必须传比较函数。
- [ ] 会用 `key` 提取排序依据，避免重复计算。
- [ ] TopK 问题优先考虑堆或快速选择。
