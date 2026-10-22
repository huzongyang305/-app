## 分页与地址转换速查

| 概念 | 说明 |
| --- | --- |
| 虚拟地址 | 程序看到的地址空间 |
| 物理地址 | 实际内存地址 |
| 页 / 页框 | 固定大小的块，常见 4 KB，大页 2 MB / 1 GB |
| 页表 | 虚拟页到物理页框的映射 |
| 多级页表 | 分级查找，节省空间 |
| TLB | 页表缓存，命中可省去多次访存 |
| 缺页 | 访问的页不在内存，触发异常 |
| 换页 | 把页在内存与磁盘间移动 |
| 写时复制 | 写入时才复制共享页 |
| 交换区 | 承载被换出的匿名页 |

## 页面置换算法对照

| 算法 | 依据 | 优点 | 缺点 |
| --- | --- | --- | --- |
| OPT | 未来最久不使用 | 理论最优 | 无法实现 |
| FIFO | 最早进入 | 简单 | 可能出现 Belady 异常 |
| LRU | 最久未使用 | 效果好 | 实现成本高 |
| Clock | 环形指针 + 访问位 | 近似 LRU、开销低 | 精度略低 |
| LFU | 使用频率最低 | 保护热点 | 旧热点难以淘汰 |

```python
from collections import OrderedDict

def lru_faults(pages: list, frames: int) -> int:
    """LRU 缺页次数统计。"""
    cache, faults = OrderedDict(), 0
    for page in pages:
        if page in cache:
            cache.move_to_end(page)
            continue
        faults += 1
        if len(cache) >= frames:
            cache.popitem(last=False)
        cache[page] = True
    return faults

def clock_faults(pages: list, frames: int) -> int:
    """Clock（二次机会）算法的缺页次数。"""
    slots, reference, pointer, faults = [None] * frames, [0] * frames, 0, 0
    for page in pages:
        if page in slots:
            reference[slots.index(page)] = 1
            continue
        faults += 1
        while True:
            if slots[pointer] is None or reference[pointer] == 0:
                slots[pointer] = page
                reference[pointer] = 1
                pointer = (pointer + 1) % frames
                break
            reference[pointer] = 0
            pointer = (pointer + 1) % frames
    return faults

def working_set_pages(accesses: list, window: int) -> set:
    """工作集：最近 window 次访问涉及的页集合。"""
    return set(accesses[-window:])

pages = [7, 0, 1, 2, 0, 3, 0, 4, 2, 3]
print(lru_faults(pages, 3), clock_faults(pages, 3))
print(working_set_pages(pages, 4))
```

## 性能与排查速查

| 指标 | 含义 | 命令 |
| --- | --- | --- |
| 缺页次数 | 页不在内存的次数 | `ps -o min_flt,maj_flt`、`/proc/<pid>/stat` |
| 主缺页 | 需从磁盘读入 | 关注是否持续增长 |
| 换入换出 | si/so | `vmstat 1` |
| 常驻内存 | RSS | `ps -o rss` |
| 虚拟内存 | VSZ | 包含未驻留部分 |
| TLB 命中 | 地址转换效率 | `perf stat -e dTLB-load-misses` |
| 交换使用 | 是否在换页 | `free -h` 看 swap |

抖动（thrashing）的典型信号：CPU 利用率不高但 si/so 持续非零、缺页率高、系统响应极慢。对策是减少并发进程数或增加内存，而不是继续加压。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把 VSZ 当实际内存占用 | 误判内存泄漏 | 看 RSS 与 PSS |
| 认为虚拟内存就是磁盘交换 | 概念混淆 | 虚拟内存是地址空间抽象 |
| 只看 swap 使用率 | 漏掉换页频率 | 结合 `vmstat` 的 si/so |
| 抖动时继续加并发 | 性能进一步恶化 | 减少并发或加内存 |
| 忽略大页配置 | TLB 未命中高 | 大内存与数据库场景考虑 HugePages |
| 认为 LRU 一定最优 | 顺序扫描会污染缓存 | 结合访问模式选择算法 |
| 不看缺页类型 | 优化方向错误 | 区分次缺页（小开销）与主缺页 |
| 忽略写时复制的内存开销 | fork 后内存暴涨 | 关注 COW 后实际写入量 |
| 用 `free` 的 `buff/cache` 判断泄漏 | 误判 | 缓存可回收，看 available |
| 把 OOM 只归因于内存泄漏 | 忽略配置限制 | 检查 cgroup/limit 与请求量 |

## 自测清单

- [ ] 能描述虚拟地址到物理地址的转换与 TLB 作用。
- [ ] 能对比 LRU、Clock、FIFO 的取舍。
- [ ] 会用 `vmstat`、`ps`、`perf` 观察缺页与换页。
- [ ] 知道抖动的信号与正确处理方式。
- [ ] 区分 RSS 与 VSZ，不误判内存占用。
