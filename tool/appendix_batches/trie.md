## 模板

```python
class Trie:
    """前缀树：支持插入、整词查询与前缀查询。"""

    def __init__(self):
        # 子节点用字典，字符集大时比定长数组省空间
        self.root = {"children": {}, "is_end": False, "count": 0}

    def insert(self, word: str) -> None:
        node = self.root
        for ch in word:
            node = node["children"].setdefault(
                ch, {"children": {}, "is_end": False, "count": 0}
            )
            node["count"] += 1          # 记录经过次数，可用于前缀统计
        node["is_end"] = True

    def search(self, word: str) -> bool:
        node = self._walk(word)
        return bool(node and node["is_end"])

    def starts_with(self, prefix: str) -> bool:
        return self._walk(prefix) is not None

    def count_prefix(self, prefix: str) -> int:
        node = self._walk(prefix)
        return node["count"] if node else 0

    def _walk(self, text: str):
        node = self.root
        for ch in text:
            node = node["children"].get(ch)
            if node is None:
                return None
        return node


def find_word(board, word: str) -> bool:
    """单词搜索 II 的基础：Trie + DFS 回溯，避免重复扫描前缀。"""
    trie = Trie()
    trie.insert(word)
    rows, cols = len(board), len(board[0])
    path = set()

    def dfs(r, c, node):
        if r < 0 or r >= rows or c < 0 or c >= cols:
            return False
        if (r, c) in path:
            return False
        ch = board[r][c]
        nxt = node["children"].get(ch)
        if nxt is None:
            return False
        if nxt["is_end"]:
            return True
        path.add((r, c))
        found = (
            dfs(r + 1, c, nxt) or dfs(r - 1, c, nxt)
            or dfs(r, c + 1, nxt) or dfs(r, c - 1, nxt)
        )
        path.discard((r, c))
        return found

    return any(dfs(r, c, trie.root) for r in range(rows) for c in range(cols))
```

## 变体与应用速查

| 变体 | 说明 |
| --- | --- |
| 压缩 Trie（radix tree） | 把单链合并成一个节点，省空间 |
| 双数组 Trie | 用两个数组实现，查询快、构建复杂 |
| 后缀 Trie / 后缀树 | 处理子串查询、最长重复子串 |
| AC 自动机 | Trie + 失配指针，多模式串匹配 |
| 0-1 Trie | 按二进制位建树，求最大异或对 |

| 应用 | 说明 |
| --- | --- |
| 自动补全 | 按前缀遍历子树 |
| 拼写检查 | 前缀匹配 + 编辑距离 |
| IP 路由（前缀匹配） | 最长前缀匹配 |
| 敏感词过滤 | AC 自动机实现线性扫描 |
| 词频统计 | 节点上记录计数 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用完整字符串比较代替 Trie | 前缀查询退化 | 需要前缀能力时用 Trie |
| 忘记 `is_end` 标记 | 无法区分「单词」与「前缀」 | 结尾节点单独标记 |
| 定长数组建 26 叉树处理 Unicode | 内存爆炸 | 用哈希表存子节点 |
| 只支持小写字母却输入大写 | 查不到 | 统一大小写或扩充字符集 |
| 需要精确查找却用 Trie | 空间开销更大 | 精确查找优先哈希表 |
| DFS 搜索不回退访问标记 | 结果错误或死循环 | 成对加入与移除 |
| 前缀统计算法用错字段 | 计数不准 | 在节点上维护 `count` |
| 删除元素直接删节点 | 破坏其他单词 | 需要引用计数或标记删除 |
| 建树后修改词库 | 一致性丢失 | 明确重建时机 |
| 忽略序列化需求 | 进程重启后丢失 | 需要持久化时序列化或改用其他结构 |

## 自测清单

- [ ] 能实现 insert / search / startsWith / countPrefix。
- [ ] 知道 Trie 查询复杂度是 O(L)，与词库大小无关。
- [ ] 了解压缩 Trie、0-1 Trie 与 AC 自动机的用途。
- [ ] 精确查找场景优先选哈希表。
- [ ] 词库频繁变更时明确重建或增量更新策略。
