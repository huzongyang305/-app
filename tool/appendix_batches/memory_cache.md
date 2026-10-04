## 存储层次速查

| 层级 | 速度 | 容量 | 易失 | 说明 |
| --- | --- | --- | --- | --- |
| 寄存器 | 最快 | 极小 | 是 | 编译器分配 |
| L1 缓存 | 约 4 周期 | 32 到 64 KB | 是 | 指令与数据分开 |
| L2 缓存 | 约 12 周期 | 数百 KB | 是 | 每核独享 |
| L3 缓存 | 约 40 周期 | 数 MB 到数十 MB | 是 | 多核共享 |
| 主存（DRAM） | 约 200 周期 | GB 级 | 是 | 需刷新 |
| SSD | 微秒级 | TB 级 | 否 | 随机读性能好 |
| HDD | 毫秒级 | TB 级 | 否 | 顺序读写远快于随机 |

## 缓存与地址转换速查

| 概念 | 说明 |
| --- | --- |
| 缓存行 | 通常 64 字节，是缓存与内存交换的最小单位 |
| 相联度 | 直接映射、组相联、全相联 |
| 替换策略 | LRU、伪 LRU、随机 |
| 写策略 | 写直达、写回 |
| 虚拟地址 | 程序看到的地址，由 MMU 转换 |
| 物理地址 | 实际内存地址 |
| 页表 | 保存虚拟页到物理页的映射 |
| TLB | 缓存页表项，加速地址转换 |
| 缺页 | 访问的页不在内存，触发异常调入 |
| 伪共享 | 两个线程改同一缓存行中不同变量，导致缓存行来回失效 |

```python
# 缓存友好：按行遍历（顺序访问），命中率远高于按列
def sum_row_major(matrix):
    total = 0
    for row in matrix:            # 内存连续
        for value in row:
            total += value
    return total


def sum_col_major(matrix):
    total = 0
    rows, cols = len(matrix), len(matrix[0])
    for c in range(cols):
        for r in range(rows):     # 跨行跳跃，缓存不友好
            total += matrix[r][c]
    return total


# 分块（tiling）：把大矩阵切块，让数据留在缓存中
def transpose_blocked(matrix, block=32):
    rows, cols = len(matrix), len(matrix[0])
    result = [[0] * rows for _ in range(cols)]
    for i in range(0, rows, block):
        for j in range(0, cols, block):
            for r in range(i, min(i + block, rows)):
                for c in range(j, min(j + block, cols)):
                    result[c][r] = matrix[r][c]
    return result
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为缓存和内存一样大 | 容量估算错误 | 缓存容量以 MB 计，只能容纳热点数据 |
| 忽略局部性原理 | 优化方向错误 | 时间局部性 + 空间局部性决定命中率 |
| 多维数组按列遍历 | 命中率低、速度慢 | 按行遍历以利用连续内存 |
| 忽略缓存行大小 | 伪共享导致性能骤降 | 把高频写变量分隔到不同缓存行 |
| 频繁小对象分配 | 缓存与分配器压力大 | 用对象池或批量分配 |
| 认为 TLB 无限大 | 大内存随机访问变慢 | 大页（HugePages）可减少 TLB 未命中 |
| 混淆虚拟地址与物理地址 | 调试结论错误 | 程序用虚拟地址，MMU 负责转换 |
| 认为缺页只在首次访问发生 | 结论片面 | 换出后再访问同样会缺页 |
| 用链表遍历大数据 | 指针跳转导致缓存未命中 | 优先用连续数组 |
| 忽略写策略差异 | 数据一致性判断错 | 写直达保证一致但更慢，写回延迟写回 |

## 自测清单

- [ ] 能按速度与容量排列存储层次。
- [ ] 知道缓存行通常 64 字节，理解伪共享。
- [ ] 能解释虚拟地址到物理地址的转换与 TLB 的作用。
- [ ] 会写缓存友好的遍历与分块代码。
- [ ] 知道局部性原理是缓存有效的前提。
