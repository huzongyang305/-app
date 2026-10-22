## 代码生成流程速查

| 阶段 | 输入 | 输出 | 关键问题 |
| --- | --- | --- | --- |
| 指令选择 | IR | 目标指令序列 | 用最合适的指令覆盖模式 |
| 指令调度 | 指令序列 | 重排后的序列 | 隐藏流水线延迟 |
| 寄存器分配 | 活跃区间 | 虚拟到物理寄存器映射 | 冲突与溢出 |
| 溢出处理 | 溢出变量 | 栈槽访问 | 插入存取指令 |
| 窥孔优化 | 局部指令序列 | 更精简的序列 | 合并冗余指令 |

## 寄存器分配速查

| 概念 | 含义 |
| --- | --- |
| 活跃变量分析 | 变量在某点之后是否还会被使用 |
| 干涉图 | 同时活跃的变量之间连边 |
| 图着色 | 用 k 种颜色（寄存器）给节点着色 |
| 溢出（spill） | 颜色不够时把变量放到栈上 |
| 溢出代价 | 按使用频率挑选代价最低的变量溢出 |
| 合并（coalescing） | 把拷贝相关变量分配到同一寄存器 |
| 调用约定 | 规定哪些寄存器跨调用必须保留 |

```python
def live_ranges(instructions):
    """极简活跃区间：返回每个变量首次与最后出现的下标。"""
    ranges = {}
    for index, (defs, uses) in enumerate(instructions):
        for name in list(defs) + list(uses):
            start, _ = ranges.get(name, (index, index))
            ranges[name] = (min(start, index), index)
    return ranges


def build_interference(ranges):
    """区间重叠即干涉，需要分配不同寄存器。"""
    names = list(ranges)
    graph = {name: set() for name in names}
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            a_start, a_end = ranges[a]
            b_start, b_end = ranges[b]
            if a_start <= b_end and b_start <= a_end:   # 区间相交
                graph[a].add(b)
                graph[b].add(a)
    return graph


def greedy_color(graph, k):
    """按度数降序贪心着色；返回 None 表示需要溢出。"""
    color = {}
    for node in sorted(graph, key=lambda n: -len(graph[n])):
        used = {color[nbr] for nbr in graph[node] if nbr in color}
        choice = next((c for c in range(k) if c not in used), None)
        if choice is None:
            return None
        color[node] = choice
    return color


instructions = [
    ({"a"}, set()),
    ({"b"}, {"a"}),
    ({"c"}, {"a", "b"}),
]
ranges = live_ranges(instructions)
graph = build_interference(ranges)
print(ranges, graph)
print(greedy_color(graph, k=2))       # 3 个活跃变量但只有 2 个寄存器时返回 None
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 活跃区间边界算错 | 干涉图错误 | 明确区间是闭区间还是半开区间 |
| 忽略调用约定 | 跨调用寄存器被破坏 | 标记易失寄存器并避免长期占用 |
| 溢出变量选择不当 | 频繁访存拖慢程序 | 优先溢出使用频率低的变量 |
| 忘记插入存取指令 | 数据不一致 | 溢出点前后要成对 load 与 store |
| 只做局部寄存器分配 | 性能差 | 使用全局图着色或线性扫描 |
| 指令选择只看单条指令 | 错过更优组合 | 做模式匹配与窥孔优化 |
| 调度破坏数据依赖 | 结果错误 | 遵守数据与控制依赖 |
| 忽略分支延迟槽 | RISC 上性能下降 | 按目标架构填充分支延迟槽 |
| 认为更多寄存器总是更快 | 结论片面 | 寄存器数量受架构限制，需要平衡 |
| 忽略调试信息 | 堆栈无法映射源码 | 生成映射表便于调试与剖析 |

## 自测清单

- [ ] 能说出代码生成的几个阶段。
- [ ] 能用活跃变量分析构建干涉图。
- [ ] 知道图着色与溢出的关系。
- [ ] 明白调用约定对寄存器分配的影响。
- [ ] 知道需要保留源码映射以便调试。
