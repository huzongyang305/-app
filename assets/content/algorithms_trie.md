# 字典树（Trie）

![字典树（Trie）](images/remaining_trie.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「字典树（Trie）」解决了什么问题，而不是只背术语。
- 能说清 「字典树」、「Trie」、「前缀」、「自动补全」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：前缀树结构、搜索联想与 Trie vs 哈希表。

## 前置知识

- 先完成上一课《并查集》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：字典树、Trie、前缀。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 结构与特点

字典树把字符串按字符逐层存储，公共前缀只存一份。查找、插入的时间复杂度都是 `O(L)`（L 为字符串长度），与词典规模无关。

```text
插入 cat、car、dog 后：
        root
       /    \
      c      d
      |      |
      a      o
     / \     |
    t   r    g
   (end)(end)(end)
```

## 实现

```python
class TrieNode:
    __slots__ = ("children", "is_end", "count")
    def __init__(self):
        self.children = {}
        self.is_end = False      # 是否是某个单词的结尾
        self.count = 0           # 经过该节点的单词数（用于前缀统计）

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word: str) -> None:
        node = self.root
        for ch in word:
            node = node.children.setdefault(ch, TrieNode())
            node.count += 1
        node.is_end = True

    def search(self, word: str) -> bool:
        node = self._walk(word)
        return node is not None and node.is_end

    def starts_with(self, prefix: str) -> bool:
        return self._walk(prefix) is not None

    def count_prefix(self, prefix: str) -> int:
        node = self._walk(prefix)
        return node.count if node else 0

    def _walk(self, text: str):
        node = self.root
        for ch in text:
            if ch not in node.children:
                return None
            node = node.children[ch]
        return node
```

用 `__slots__` 可以显著减少大量节点带来的内存开销。

## 典型应用

| 场景 | 说明 |
| --- | --- |
| 搜索联想 | 输入前缀返回候选词（按 count 排序） |
| 拼写检查 | 判断是否为合法单词，或找最接近的前缀 |
| IP 路由 | 二进制 Trie 做最长前缀匹配 |
| 敏感词过滤 | 一次扫描文本匹配多模式（Aho-Corasick 是 Trie 的扩展） |
| 异或最大值 | 01-Trie 按位贪心求最大异或对 |

## 用 Trie 实现搜索联想

```python
def suggest(trie: Trie, prefix: str, limit: int = 5):
    node = trie._walk(prefix)
    if node is None:
        return []
    results = []
    def dfs(current, path):
        if len(results) >= limit:
            return
        if current.is_end:
            results.append(prefix + path)
        for ch in sorted(current.children):
            dfs(current.children[ch], path + ch)
    dfs(node, "")
    return results
```

## 与哈希表的对比

| 对比 | 哈希表 | 字典树 |
| --- | --- | --- |
| 精确查找 | O(1) 平均 | O(L) |
| 前缀查询 | 不支持（需全量扫描） | 天然支持 |
| 内存 | 小 | 大（指针开销明显） |
| 有序遍历 | 需额外排序 | 按字符顺序天然有序 |

实践建议：只需要精确查找用哈希表；需要前缀、自动补全、多模式匹配时再上 Trie。

## 本课小结
字典树的本质是**用空间换前缀信息**。抓住「节点表示前缀、`is_end` 表示单词结尾」这两点，插入、查找、前缀统计都能快速写出。


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

## 动手练习


> 本课练习重点：围绕「字典树、Trie、前缀」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「字典树（Trie）」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Trie」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

给定 8～12 个手工构造的数据，写出每一步状态，并统计比较或交换次数。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「字典树」和「Trie」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：字典树相比哈希表的核心优势是？

- **正确判断**：支持前缀查询且复杂度为 O(L)
- **判断依据**：正确答案是「支持前缀查询且复杂度为 O(L)」，本课在「与哈希表的对比」中说明：需要前缀、自动补全、多模式匹配时再上 Trie。Trie 天然按前缀组织，适合自动补全与多模式匹配。本课还在「结构与特点」中说明：字典树把字符串按字符逐层存储，公共前缀只存一份。本课还在「结构与特点」中说明：查找、插入的时间复杂度都是 O(L)（L 为字符串长度），与词典规模无关。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：节点上的 is_end 标记表示？

- **正确判断**：该节点是一个单词的结尾
- **判断依据**：正确答案是「该节点是一个单词的结尾」，本课在「与哈希表的对比」中说明：需要前缀、自动补全、多模式匹配时再上 Trie。查找单词时必须同时满足路径存在且 isend 为真。本课还在「本课小结」中说明：抓住「节点表示前缀、isend 表示单词结尾」这两点，插入、查找、前缀统计都能快速写出。本课还在「结构与特点」中说明：字典树把字符串按字符逐层存储，公共前缀只存一份。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：只需要精确查找、不需要前缀能力时，应优先选择？

- **正确判断**：哈希表
- **判断依据**：哈希表平均 O(1) 且内存开销远小于 Trie。其他选项：只需精确查找时哈希表平均 O(1) 且更省空间。课程摘要指出前缀树结构，搜索联想与 Trie vs 哈希表，本课要判断的正是只需要精确查找、不需要前缀能力时，应优先选择。这道题考查 只需要精确查找、不需要前缀能力时，应优先选择 与字典树、Trie、前缀、自动补全这些概念之间的边界，判断时要把题干限定的条件逐项代入。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：Trie 的空间开销主要来自哪里？

- **正确判断**：节点数量多
- **判断依据**：正确答案是「节点数量多」，本课在「实现」中说明：用 slots 可以显著减少大量节点带来的内存开销。可用压缩 Trie（radix tree）或数组/位图代替哈希表来降低开销。本课还在「结构与特点」中说明：查找、插入的时间复杂度都是 O(L)（L 为字符串长度），与词典规模无关。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：在 Trie 中查询长度为 L 的字符串的复杂度是？

- **正确判断**：O(L)，与词库大小无关
- **判断依据**：正确答案是「O(L)，与词库大小无关」，这道题在问在Trie中查询长度为L的字符串的复杂度是，判断时要把题干限定的输入、边界与目标逐项对齐。逐字符沿边下行即可，这个特性让 Trie 非常适合前缀联想与自动补全。课程摘要指出前缀树结构，搜索联想与 Trie vs 哈希表，本课要判断的正是在Trie中查询长度为L的字符串的复杂度是。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 6：补全代码：「字典树（Trie）」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `trie.____(word)`

- **正确判断**：insert
- **判断依据**：正确答案是「insert」，这道题在问补全代码：字典树（Trie）示例中，下面这行代码缺少…__，`trie.____(word)`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `trie.insert(word)` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「字典树相比哈希表的核心优势是？」的判断依据。
- [ ] 不看解析，能说出「节点上的 is_end 标记表示？」的判断依据。
- [ ] 不看解析，能说出「只需要精确查找、不需要前缀能力时，应优先选择？」的判断依据。
- [ ] 不看解析，能说出「Trie 的空间开销主要来自哪里？」的判断依据。
- [ ] 不看解析，能说出「在 Trie 中查询长度为 L 的字符串的复杂度是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「字典树（Trie）」示例中，下面这行代码缺少哪个关键字或函数名？请填…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Trie

**Summary:** Prefix trees, autocomplete and trade-offs.

**Category:** Algorithms  
**Level:** 进阶  
**Key terms:** 字典树, Trie, 前缀, 自动补全, 多模式匹配

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：字典树、Trie、前缀、自动补全、多模式匹配
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [CP-Algorithms](https://cp-algorithms.com/) | 算法实现与复杂度 |
| [MIT OpenCourseWare 6.006](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/) | 算法设计与分析 |

> 本课主题：前缀树结构、搜索联想与 Trie vs 哈希表。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

