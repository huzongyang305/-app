## 语法速查

| 语法 | 写法 | 说明 |
| --- | --- | --- |
| 缩进 | 4 个空格 | 同一代码块必须一致，禁止 Tab 与空格混用 |
| 单行注释 | `# 说明` | 解释「为什么」，而不是复述代码 |
| 多行注释 | `"""说明"""` | 实际是字符串，放在函数首行即文档字符串 |
| 变量赋值 | `x = 10` | 等号两边加空格更易读 |
| 多重赋值 | `a, b = 1, 2` | 一行初始化多个变量 |
| 交换变量 | `a, b = b, a` | 不需要临时变量 |
| 输入 | `input("提示：")` | 返回值永远是 `str` |
| 输出 | `print(a, b, sep="-")` | `sep` 控制分隔符，`end` 控制结尾 |

字符串格式化速查：

| 方式 | 写法 | 建议 |
| --- | --- | --- |
| f-string | `f"{name} 今年 {age} 岁"` | **首选**，直观且性能好 |
| 格式控制 | `f"{pi:.2f}"`、`f"{n:04d}"` | 保留小数、补零 |
| `str.format` | `"{} {}".format(a, b)` | 老代码常见，可读性略差 |
| `%` 格式化 | `"%s %d" % (a, b)` | 已过时，仅用于阅读旧代码 |

```python
name = input("姓名：").strip()
age = 18
print(f"{name} 今年 {age} 岁")
print(f"圆周率约等于 {3.14159:.2f}")     # 3.14
print(f"编号 {7:04d}")                   # 编号 0007
print("a", "b", sep="-", end="!\n")      # a-b!
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| Tab 与空格混用缩进 | `TabError: inconsistent use of tabs and spaces` | 统一用 4 个空格，编辑器设置「Tab 转空格」 |
| 忘了冒号 | `SyntaxError: expected ':'` | `if`、`for`、`while`、`def`、`class` 行末都要冒号 |
| 用中文标点 | `SyntaxError: invalid character '：'` | 代码里的括号、引号、冒号必须用英文半角 |
| `input()` 直接参与算术 | `TypeError: can only concatenate str` | `input()` 返回字符串，先 `int()` / `float()` |
| `print "hello"` | `SyntaxError` | Python 3 中 `print` 是函数，必须加括号 |
| 变量未定义就使用 | `NameError: name 'x' is not defined` | 先赋值再使用，注意拼写一致 |
| 使用保留字作变量名 | `SyntaxError` | 避开 `class`、`def`、`lambda`、`None` 等关键字 |
| 用 `=` 做比较 | `SyntaxError` | 比较相等用 `==` |
| 字符串里出现未转义的引号 | `SyntaxError: unterminated string literal` | 用另一种引号包裹，或写 `\'` |
| 代码块下没有内容 | `IndentationError: expected an indented block` | 至少写 `pass` 或实际语句 |

## 入门第一周练习清单

- [ ] 写一个「输入姓名与年龄，输出问候语」的小程序。
- [ ] 用 f-string 输出保留两位小数的金额。
- [ ] 能解释 `input()` 为什么必须做类型转换。
- [ ] 遇到报错先看最后一行，再定位行号与类型。
- [ ] 代码里不出现 Tab 与中文标点。
