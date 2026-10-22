## 中间表示速查

| IR 形式 | 特点 | 用途 |
| --- | --- | --- |
| 三地址码 | 每条指令最多一个运算 | 教学与基础优化 |
| SSA | 每个变量只赋值一次 | 现代编译器主流 |
| 控制流图（CFG） | 基本块 + 边 | 数据流分析与优化 |
| 有向无环图（DAG） | 复用公共子表达式 | 局部优化 |
| 字节码 | 面向虚拟机 | Java、Python、C# |

## 常用优化速查

| 优化 | 说明 | 前提 |
| --- | --- | --- |
| 常量折叠 | `3 * 4` 直接算成 12 | 编译期可求值 |
| 常量传播 | 把已知常量代入后续使用 | 数据流分析支持 |
| 公共子表达式消除 | 相同表达式只算一次 | 中间无副作用 |
| 死代码消除 | 删除不影响结果的代码 | 可观察行为不变 |
| 循环不变式外提 | 循环内不变的计算移到外面 | 无副作用、循环必达 |
| 强度削弱 | 乘法换成移位或加法 | 语义等价 |
| 内联 | 把函数体展开 | 权衡代码体积 |
| 循环展开 | 减少循环开销 | 增加代码体积 |
| 向量化 | 用 SIMD 批量处理 | 数据连续且无依赖 |
| 尾调用优化 | 复用栈帧 | 尾位置调用 |

```python
import ast

class ConstantFolder(ast.NodeTransformer):
    """极简常量折叠：把字面量的二元运算在编译期算好。"""

    def visit_BinOp(self, node):
        self.generic_visit(node)
        left, right = node.left, node.right
        if isinstance(left, ast.Constant) and isinstance(right, ast.Constant):
            try:
                value = eval(compile(ast.Expression(node), "<const>", "eval"))
            except Exception:
                return node
            return ast.copy_location(ast.Constant(value=value), node)
        return node


source = "result = 3 * 4 + 2"
tree = ConstantFolder().visit(ast.parse(source))
ast.fix_missing_locations(tree)
print(ast.unparse(tree))          # result = 14
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 忽略副作用就做消除 | 程序行为改变 | 只有无副作用且结果未被使用的代码才能删 |
| 存在未定义行为仍激进优化 | 结果与预期完全不符 | 先消除 UB，再谈优化 |
| 不做别名分析就重排访存 | 读写顺序被破坏 | 需要别名分析确认安全 |
| 浮点优化假设结合律 | 结果精度变化 | 浮点不满足结合律，需要 `-ffast-math` 才允许 |
| 认为 SSA 只能表示标量 | 无法表达数组与内存 | 内存可用 SSA 形式 + 别名分析表达 |
| 优化改变异常语义 | 异常抛出时机变化 | 保持可观察行为（含异常与日志） |
| 只做局部优化 | 收益有限 | 配合过程间优化（内联、IPA） |
| 忽略代码体积 | 指令缓存命中率下降 | 权衡性能与体积 |
| 手工优化替代编译器 | 收益小且易错 | 先写清晰代码，再依赖剖析数据 |
| 不看优化日志就断言 | 优化假设错误 | 用 `-O -R`、LLVM 优化记录验证 |

## 自测清单

- [ ] 能说出三地址码与 SSA 的区别。
- [ ] 能列举五种以上常见优化及其前提。
- [ ] 知道未定义行为会让优化结果不可预期。
- [ ] 明白浮点不满足结合律。
- [ ] 优化以「不改变可观察行为」为底线。
