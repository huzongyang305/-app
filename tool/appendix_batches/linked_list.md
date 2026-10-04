## 常用操作速查

| 操作 | 单链表 | 双向链表 | 说明 |
| --- | --- | --- | --- |
| 头部插入/删除 | O(1) | O(1) | 最擅长的场景 |
| 尾部插入 | O(n)（无尾指针） | O(1) | 有尾指针也是 O(1) |
| 已知节点后插入 | O(1) | O(1) | 需要先拿到节点 |
| 删除已知节点 | O(n)（需前驱） | O(1) | 双向链表可直接删 |
| 按下标访问 | O(n) | O(n) | 链表不适合随机访问 |
| 反转 | O(n) | O(n) | 迭代改指针 |

```python
class Node:
    __slots__ = ("value", "next")

    def __init__(self, value, next=None):
        self.value = value
        self.next = next


def reverse(head):
    """迭代反转单链表，空间 O(1)。"""
    prev, cur = None, head
    while cur:
        nxt = cur.next
        cur.next = prev
        prev, cur = cur, nxt
    return prev


def has_cycle(head):
    """快慢指针判环；相遇后一指针回头可找环入口。"""
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            return True
    return False


def merge_sorted(a, b):
    """合并两个有序链表，复用节点不新建。"""
    dummy = Node(0)
    tail = dummy
    while a and b:
        if a.value <= b.value:      # <= 保证稳定
            tail.next, a = a, a.next
        else:
            tail.next, b = b, b.next
        tail = tail.next
    tail.next = a or b
    return dummy.next
```

## 快慢指针适用问题

| 问题 | 做法 |
| --- | --- |
| 判断是否有环 | 快指针每次走 2 步，相遇即有环 |
| 找环入口 | 相遇后一指针回到头部，二者同速前进 |
| 找中间节点 | 快指针到尾时慢指针在中间 |
| 找倒数第 k 个 | 快指针先走 k 步，再同速前进 |
| 判断回文链表 | 找中点 + 反转后半段 + 比较 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 改指针前不保存 `next` | 链表断裂、丢失后续节点 | 先 `nxt = cur.next` 再改指向 |
| 删除节点时没更新前驱 | 节点仍被引用 | 让 `prev.next = cur.next` |
| 快慢指针没检查 `fast.next` | 空指针异常 | 条件写 `while fast and fast.next:` |
| 用哨兵节点后又返回 `dummy` | 结果多一个假节点 | 返回 `dummy.next` |
| 头节点被删除时忘记更新 head | 结果丢头 | 用哨兵节点简化边界 |
| 认为链表插入总是 O(1) | 忽略了查找前驱的成本 | 明确「已知位置」才是 O(1) |
| 用链表替代数组做随机访问 | 性能极差 | 数组更适合下标访问 |
| 忘记处理空链表与单节点 | 边界崩溃 | 专门测试这两种输入 |
| 反转后没更新头指针 | 遍历不到 | 返回新的头（原尾节点） |
| 链表节点无 `__slots__` | 内存开销大 | 大量节点时用 `__slots__` 优化 |

## 自测清单

- [ ] 能手写迭代版反转链表。
- [ ] 会用快慢指针判环并找入口。
- [ ] 合并有序链表用哨兵节点简化边界。
- [ ] 知道链表与数组各自的适用场景。
- [ ] 测试覆盖空链表、单节点、偶数与奇数长度。
