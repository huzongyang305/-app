## 词法与语法分析速查

| 阶段 | 输入 | 输出 | 关键技术 |
| --- | --- | --- | --- |
| 词法分析 | 字符流 | Token 流 | 正则、DFA、最长匹配 |
| 语法分析 | Token 流 | 语法树 / AST | LL、LR、递归下降 |
| 语义分析 | AST | 带类型 AST | 符号表、类型检查 |

| 文法 | 分析方式 | 特点 |
| --- | --- | --- |
| 正则文法 | 有限自动机 | 只需线性扫描 |
| LL(1) | 自顶向下、预测分析表 | 不能有左递归 |
| LR(1) / LALR | 自底向上、移进归约 | 表达能力更强，工具生成 |
| 算符优先 | 处理表达式 | 依赖优先级与结合性 |

```python
import re
from dataclasses import dataclass

@dataclass
class Token:
    kind: str
    value: str
    position: int


# 词法分析：按正则规则切分，注意规则顺序（关键字先于标识符）
TOKEN_RULES = [
    ("NUMBER", re.compile(r"\d+(\.\d+)?")),
    ("IDENT", re.compile(r"[A-Za-z_]\w*")),
    ("OP", re.compile(r"[+\-*/=<>!]+")),
    ("PUNCT", re.compile(r"[(){};,.]")),
    ("SPACE", re.compile(r"\s+")),
]
KEYWORDS = {"if", "else", "while", "return"}


def tokenize(source: str):
    tokens, index = [], 0
    while index < len(source):
        for kind, pattern in TOKEN_RULES:
            match = pattern.match(source, index)
            if not match:
                continue
            text = match.group()
            if kind != "SPACE":                       # 跳过空白
                if kind == "IDENT" and text in KEYWORDS:
                    kind = "KEYWORD"
                tokens.append(Token(kind, text, index))
            index = match.end()
            break
        else:
            raise SyntaxError(f"无法识别的字符 {source[index]!r}（位置 {index}）")
    return tokens


for token in tokenize("if count >= 10 { total = total + 1 }"):
    print(token)
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 词法器不跳过空白与注释 | 充斥无用 Token | 单独规则处理并在输出中忽略 |
| 关键字规则排在标识符之后 | 关键字被识别为标识符 | 顺序或优先级要明确 |
| 忽略最长匹配原则 | `>=` 被切成 `>` 与 `=` | 每个位置取最长可行匹配 |
| 用正则处理嵌套结构 | 无法匹配或栈溢出 | 嵌套交给语法分析阶段 |
| 递归下降处理左递归文法 | 无限递归 | 先消除左递归 |
| 报错信息不含位置 | 用户无法定位 | 记录行、列与原始片段 |
| 语法分析器不做错误恢复 | 一处错误报一堆 | 同步到分号或右括号后继续 |
| 分词与解析耦合在一起 | 难以测试与复用 | 分阶段实现，各自有单元测试 |
| 忽略 Unicode 标识符 | 国际化标识符报错 | 统一按 Unicode 类别判断 |
| 用正则解析整个语言 | 复杂度爆炸 | 只用于词法层，语法层用正式文法 |

## 自测清单

- [ ] 能写出从字符流到 AST 的分阶段流程。
- [ ] 知道最长匹配与关键字优先原则。
- [ ] 能说出 LL 与 LR 的差异与限制。
- [ ] 报错信息包含位置与上下文。
- [ ] 会为词法器与解析器分别写单元测试。
