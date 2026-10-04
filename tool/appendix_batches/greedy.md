## 经典贪心问题速查

| 问题 | 贪心策略 | 是否总能最优 |
| --- | --- | --- |
| 活动选择 / 最多不重叠会议 | 按结束时间升序选 | 是 |
| 区间覆盖 | 按起点排序，尽量延伸 | 是 |
| 最小硬币数 | 每次取最大面值 | 仅面值体系规范时（如 1/5/10/25） |
| 分数背包 | 按单位价值降序装 | 是 |
| 0/1 背包 | 无法贪心 | 需要 DP |
| 哈夫曼编码 | 每次合并最小的两个 | 是 |
| 最小生成树（Kruskal） | 按边权升序加边且不成环 | 是 |
| 最小生成树（Prim） | 每次选连接已选集合的最小边 | 是 |
| 最短路（Dijkstra） | 每次确定最小距离节点 | 是（边权非负） |
| 任务调度 | 按截止时间排序，用堆维护 | 是 |

## 贪心与动态规划对照

| 维度 | 贪心 | 动态规划 |
| --- | --- | --- |
| 决策方式 | 每步只做局部最优且不回溯 | 保留多个子问题解并比较 |
| 是否需证明 | 必须证明贪心选择性质与最优子结构 | 只需最优子结构与重叠子问题 |
| 复杂度 | 通常 O(n log n) 或 O(n) | 常为 O(n²) 或 O(nW) |
| 风险 | 直觉错误就得到次优解 | 较难写错但更慢 |
| 验证方法 | 找反例、数学归纳、交换论证 | 与暴力搜索对比小规模结果 |

```python
import heapq

def max_meetings(intervals):
    """最多不重叠会议：按结束时间升序贪心。"""
    intervals = sorted(intervals, key=lambda x: x[1])
    count, last_end = 0, float("-inf")
    for start, end in intervals:
        if start >= last_end:
            count += 1
            last_end = end
    return count


def min_coins(coins, amount):
    """硬币找零：面值不保证规范时必须用 DP，这里给出通用解。"""
    dp = [float("inf")] * (amount + 1)
    dp[0] = 0
    for value in range(1, amount + 1):
        for coin in coins:
            if coin <= value:
                dp[value] = min(dp[value], dp[value - coin] + 1)
    return -1 if dp[amount] == float("inf") else dp[amount]


def schedule_tasks(tasks):
    """按截止时间安排任务，超期时丢弃最耗时的任务。"""
    tasks.sort(key=lambda t: t[1])
    chosen, total = [], 0
    for duration, deadline in tasks:
        total += duration
        heapq.heappush(chosen, -duration)
        if total > deadline:
            total += heapq.heappop(chosen)   # 弹出的负数等于减去该耗时
    return len(chosen)
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 凭直觉用贪心不验证 | 得到次优解 | 先找反例或用小规模暴力对比 |
| 硬币问题默认贪心可行 | 面值 1/3/4 凑 6 时出错 | 只有规范体系才成立，否则用 DP |
| 活动选择按开始时间排序 | 结果不是最多 | 应按结束时间排序 |
| 0/1 背包用单位价值贪心 | 超重或次优 | 用 DP |
| 贪心选择后无法回退 | 后续无解 | 确认问题具备贪心选择性质 |
| 忽略排序成本 | 复杂度估计偏低 | 通常需 O(n log n) 排序 |
| 用贪心求全局最优但不证明 | 隐含错误 | 用交换论证或归纳法证明 |
| 时间区间边界处理不清 | 端点半开半闭判断错 | 明确区间开闭并统一 |
| 只测正常用例 | 边界反例漏掉 | 覆盖相等端点、空集、单元素 |
| 用贪心替代匹配类算法 | 结果不是最优 | 匹配问题用匈牙利或网络流 |

## 自测清单

- [ ] 能说出贪心成立的两个条件。
- [ ] 活动选择按结束时间排序。
- [ ] 知道硬币找零何时贪心成立、何时必须 DP。
- [ ] 会用交换论证或反例验证贪心正确性。
- [ ] 能区分贪心与 DP 的适用边界。
