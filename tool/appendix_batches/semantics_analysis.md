## 语义分析任务速查

| 任务 | 作用 | 典型错误 |
| --- | --- | --- |
| 名称解析 | 把标识符绑定到声明 | 未定义变量、重复定义 |
| 类型检查 | 验证运算与赋值的类型合法 | 类型不匹配、缺少转换 |
| 隐式转换标注 | 插入必要的转换节点 | 精度丢失未告警 |
| 作用域处理 | 按嵌套层级查找名字 | 遮蔽外层变量 |
| 可访问性检查 | 校验 private / protected | 越权访问 |
| 常量求值 | 编译期计算常量表达式 | 溢出、除零 |
| 确定求值顺序 | 明确副作用顺序 | 未定义求值顺序 |
| 流程检查 | 未初始化变量、不可达代码 | 使用未初始化值 |

## 符号表速查

| 结构 | 适用 | 查找复杂度 |
| --- | --- | --- |
| 线性表 | 极小作用域 | O(n) |
| 哈希表 | 一般语言 | 平均 O(1) |
| 树 / 有序结构 | 需要按名字排序输出 | O(log n) |
| 作用域栈 + 哈希表 | 嵌套作用域 | 平均 O(1) |

```python
class SymbolTable:
    """带作用域的符号表：进入作用域压栈，退出时弹出。"""

    def __init__(self):
        self.scopes = [{}]

    def enter_scope(self) -> None:
        self.scopes.append({})

    def leave_scope(self) -> None:
        if len(self.scopes) == 1:
            raise RuntimeError("不能退出全局作用域")
        self.scopes.pop()

    def declare(self, name: str, info: dict) -> None:
        if name in self.scopes[-1]:
            raise SyntaxError(f"重复定义：{name}")
        self.scopes[-1][name] = info

    def lookup(self, name: str):
        for scope in reversed(self.scopes):        # 从内层向外层查找
            if name in scope:
                return scope[name]
        raise NameError(f"未定义的标识符：{name}")

    def lookup_current(self, name: str):
        return self.scopes[-1].get(name)


def type_check_binary(left: str, op: str, right: str) -> str:
    """极简类型检查规则表。"""
    rules = {
        ("int", "+", "int"): "int",
        ("int", "+", "float"): "float",     # 隐式提升
        ("float", "+", "float"): "float",
        ("str", "+", "str"): "str",
    }
    if (left, op, right) in rules:
        return rules[(left, op, right)]
    raise TypeError(f"类型不匹配：{left} {op} {right}")
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 符号表不区分作用域 | 内层同名变量覆盖外层 | 用作用域栈，退出时弹出 |
| 查找只查当前作用域 | 找不到外层变量 | 从内向外逐层查找 |
| 声明前使用变量 | 结果不可预期 | 语义分析阶段报「使用未初始化」 |
| 类型检查只看字面量 | 变量类型漏检 | 用符号表记录每个变量的类型 |
| 隐式转换无告警 | 精度悄悄丢失 | 对窄化转换发出警告 |
| 忽略控制流 | 不可达代码与未初始化漏检 | 构建 CFG 并做数据流分析 |
| 报错只给一行信息 | 用户难以定位 | 包含文件、行号、列号与源码片段 |
| 语义分析与语法分析混在一起 | 难以维护与测试 | 分阶段处理，各自独立测试 |
| 常量求值不检查溢出 | 编译期结果错误 | 按目标类型范围检查 |
| 忽略求值顺序 | 有副作用的表达式结果不同 | 明确定义顺序并在文档中说明 |

## 自测清单

- [ ] 能列出语义分析的主要任务。
- [ ] 会实现带作用域栈的符号表。
- [ ] 能说出类型检查与隐式转换的处理方式。
- [ ] 知道控制流分析能发现哪些问题。
- [ ] 报错信息包含位置与上下文。
