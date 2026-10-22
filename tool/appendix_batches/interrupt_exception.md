## 中断与异常速查

| 类型 | 来源 | 同步性 | 例子 |
| --- | --- | --- | --- |
| 故障（Fault） | 当前指令 | 同步 | 缺页、除零 |
| 陷阱（Trap） | 当前指令 | 同步 | 系统调用、断点 |
| 中止（Abort） | 严重错误 | 同步 | 硬件校验错误 |
| 可屏蔽中断 | 外部设备 | 异步 | 网卡收包、定时器 |
| 不可屏蔽中断 | 严重硬件事件 | 异步 | 内存校验错误、看门狗 |

| 概念 | 说明 |
| --- | --- |
| 中断向量表 | 中断号到处理函数的映射 |
| 上下文保存 | 保存寄存器与程序计数器 |
| 中断延迟 | 从设备发出到开始处理的时间 |
| 中断嵌套 | 高优先级中断打断低优先级 |
| 下半部 | 把耗时工作推迟到中断之外 |
| 软中断 / tasklet / 工作队列 | Linux 中的下半部机制 |
| 中断亲和性 | 把中断绑定到指定 CPU，提升缓存命中 |
| IOMMU | 为设备 DMA 提供地址转换与隔离 |

```python
import queue
import threading
import time

class InterruptHandler:
    """模拟「上半部 + 下半部」：中断处理只做最小工作，其余交给工作线程。"""

    def __init__(self):
        self.queue: queue.Queue = queue.Queue()
        self.worker = threading.Thread(target=self._bottom_half, daemon=True)
        self.events = 0

    def start(self):
        self.worker.start()

    def top_half(self, device_event):
        """上半部：必须极快，只记录事件并排队。"""
        self.events += 1
        self.queue.put(device_event)

    def _bottom_half(self):
        while True:
            event = self.queue.get()
            try:
                self._handle(event)        # 耗时处理放在这里
            finally:
                self.queue.task_done()

    @staticmethod
    def _handle(event):
        time.sleep(0.001)


def page_fault_reason(flags: dict) -> str:
    """缺页的两类原因：页不在内存，或权限不符。"""
    if not flags.get("present"):
        return "页不在物理内存，需要从磁盘调入"
    if flags.get("write") and not flags.get("writable"):
        return "写权限不足，可能是写时复制或段错误"
    return "其他原因"


handler = InterruptHandler()
handler.start()
handler.top_half({"device": "eth0", "bytes": 1500})
print(page_fault_reason({"present": False}))
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在中断上半部做耗时工作 | 中断被长时间屏蔽，丢包卡顿 | 只做最小工作，其余交给下半部 |
| 中断上下文中睡眠 | 内核崩溃或警告 | 下半部或工作队列才能睡眠 |
| 忘记保存与恢复上下文 | 返回后寄存器错乱 | 由内核按 ABI 保存与恢复 |
| 认为中断一定会立即处理 | 延迟被低估 | 存在屏蔽、优先级与排队延迟 |
| 忽略中断风暴 | CPU 全被中断占用 | 合并中断、限速或改轮询 |
| 把所有中断绑到同一个 CPU | 单核瓶颈 | 配置中断亲和性分散 |
| 缺页当成崩溃 | 排查方向错误 | 缺页是正常机制，多数可恢复 |
| 认为 DMA 不需要 IOMMU | 设备可访问任意内存 | IOMMU 提供隔离与保护 |
| 忘记处理中断中的错误状态 | 设备卡死 | 读取并清除设备状态寄存器 |
| 用关中断保护所有临界区 | 延迟变差 | 只在极短临界区关中断 |

## 自测清单

- [ ] 能区分故障、陷阱、中止与外部中断。
- [ ] 知道中断上半部必须极短，耗时工作放下半部。
- [ ] 明白中断上下文不能睡眠。
- [ ] 知道缺页的两类原因及处理差异。
- [ ] 会用中断亲和性与 IOMMU 优化与隔离。
