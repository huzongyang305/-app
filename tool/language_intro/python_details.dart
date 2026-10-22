// Python 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _pyFirstCode = r'''# 把这一行保存成 hello.py，然后在终端执行：python hello.py
print("你好，Python")

name = "小明"
print("欢迎，" + name)''';

const String _pyIoCode = r'''name = input("请输入你的名字：")
age_text = input("请输入你的年龄：")

# input 拿回来的永远是文字，要算数就得先转成整数
age = int(age_text)
next_year = age + 1

print(f"{name}，你明年 {next_year} 岁")''';

const String _pyIfCode = r'''score = int(input("请输入成绩（0-100）："))

if score >= 90:
    print("优秀")
elif score >= 60:
    print("及格")
else:
    print("需要补考")

print("判断结束")''';

const String _pyLoopCode = r'''total = 0

for number in range(1, 6):
    total = total + number
    print(f"加入 {number} 之后，累计是 {total}")

while total < 20:
    total = total + 5

print(f"最终结果：{total}")''';

const String _pyListDictCode = r'''fruits = ["苹果", "香蕉", "橘子"]
fruits.append("葡萄")

price = {
    "苹果": 6,
    "香蕉": 3,
    "葡萄": 12,
}

for fruit in fruits:
    unit_price = price[fruit]
    print(f"{fruit} 每斤 {unit_price} 元")

print(f"最贵的价格是 {max(price.values())} 元")''';

const List<LanguageIntroDetail> pythonIntroDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'python_first_script',
    sectionTitle: 'Python 第一个脚本',
    codeLanguage: 'python',
    oneLiner:
        'Python 脚本就是一个后缀为 .py 的文本文件，里面写着一条条从上往下执行的命令；'
        'print() 负责把结果送到屏幕上让你看见。',
    analogy:
        '把脚本想成一张写给厨房的便条：你按顺序写「先洗菜、再切菜、最后下锅」，'
        '厨师（解释器）就照顺序做一遍。写错顺序或漏掉一步，结果立刻不一样，'
        '这也是为什么编程要先学会「按顺序读代码」。',
    code: _pyFirstCode,
    lineWalk: '''
- 第一行以 `#` 开头，是写给人看的注释，Python 执行时会整行跳过，只用来提醒自己运行命令。
- 第二行 `print("你好，Python")` 调用内置函数 `print`，把引号里的文字原样输出到屏幕，最后自动补一个换行。
- 第四行 `name = "小明"` 把字符串 `"小明"` 存进名为 `name` 的变量，等号在这里读作「把右边装进左边的盒子」，不是数学里的相等。
- 第五行先用 `+` 把 `"欢迎，"` 和 `name` 里的内容拼成一句完整的话，再交给 `print` 输出，所以屏幕上会出现「欢迎，小明」。
''',
    runThrough: '''
- 打开终端进入脚本所在目录，输入 `python hello.py`，解释器开始逐行读文件。
- 第二行先执行，屏幕出现第一行输出：`你好，Python`。
- 第四行执行时内存里多了一个 `name`，里面装着 `小明`，屏幕上什么都不显示。
- 第五行读取 `name` 的值并拼接字符串，屏幕出现第二行输出：`欢迎，小明`，脚本结束。
''',
    pitfalls: '''
- 把文件存成 `hello.txt` 或 `hello`：解释器只认 `.py`，后缀不对就会报「找不到文件」。
- 在 VS Code 里点「运行」却没保存：磁盘上还是旧代码，看到的输出自然是上一次的结果。
- 引号只用一半，比如 `print("你好)`：Python 会一直等到下一行找收尾引号，报 `SyntaxError`。
- 变量名写成 `Name` 又用 `name` 读：Python 大小写敏感，这两个是完全不同的变量。
- 用了中文全角引号 `“你好”`：看起来像引号，实际不是合法符号，必须用英文半角引号。
''',
    drill: '''
- 把第二行文字换成自己的名字，保存后重新运行，确认输出跟着变。
- 新加一行 `print(1 + 2)`，先在心里算结果再看屏幕，体会 `print` 既可以输出文字也可以输出计算值。
- 故意删掉一个右引号，运行一次，把完整的报错信息和出错行号抄下来。
''',
  ),
  LanguageIntroDetail(
    id: 'python_input_output',
    sectionTitle: 'Python 输入与输出',
    codeLanguage: 'python',
    oneLiner:
        'input() 负责把用户在键盘上敲的内容读进程序，而且读回来的一定是字符串；'
        '想参与计算就要先用 int() 或 float() 转换类型。',
    analogy:
        '把 input() 想成餐厅点单：服务员把客人说的话原样记在纸上交给你，'
        '纸条上写的是「3」，但那是一段文字，不是数字三；'
        '想拿这三个菜去结账，你得先把纸条上的内容翻译成真正的数量。',
    code: _pyIoCode,
    lineWalk: '''
- `input("请输入你的名字：")` 先把提示语打印出来，然后暂停程序，等用户敲完回车，再把输入内容作为字符串返回并存入 `name`。
- 第二行同样读入年龄，但此时 `age_text` 的类型是字符串。哪怕用户输入 `18`，程序拿到的也是「由 1 和 8 两个字符组成的文本」。
- `int(age_text)` 把字符串翻译成整数，赋给 `age`；如果用户输入了 `十八` 或 `18岁`，这一步会立刻抛出 `ValueError`。
- `age + 1` 此时做的是整数加法，得到 19。
- 最后一行是 f-string：字符串前面的 `f` 表示里面 `{}` 包起来的表达式会被替换成实际的值。
''',
    runThrough: '''
- 程序执行到第一个 `input` 时停住，屏幕显示提示语并等待键盘输入。假设输入 `小明`。
- 第二个 `input` 收到 `18` 这个字符串，`int` 把它变成整数 18。
- `next_year` 计算得到 19。
- `print` 把占位符 `{name}` 换成 `小明`、`{next_year}` 换成 `19`，输出「小明，你明年 19 岁」。
''',
    pitfalls: '''
- 直接写 `age + 1` 而不转换：会看到 `TypeError: can only concatenate str` 这类错误，因为字符串不能和整数相加。
- 把数字提示写成 `input(18)`：`input` 的参数必须是字符串，写数字会报 `TypeError`。
- 忘记处理非法输入：用户输入空行或乱码时 `int()` 直接崩溃，正式程序要配合 `try/except`。
- 用 `+` 拼接数字时会报错，正确写法是 f-string，例如 `f"明年 {next_year} 岁"`。
- 把 `print` 写进 `input` 里造成重复输出，例如 `input(print("提示"))`，先打印再读取，提示语会跑两遍。
''',
    drill: '''
- 运行原程序，分别输入 `18`、`18.5`、`十八`，记录三次结果有什么不同。
- 把 `int` 换成 `float`，再输入 `18.5`，观察程序是否能正常算下去。
- 增加一行，询问用户所在城市，并把它拼进最后的输出里。
''',
  ),
  LanguageIntroDetail(
    id: 'python_if_else',
    sectionTitle: 'Python 条件判断',
    codeLanguage: 'python',
    oneLiner:
        'if / elif / else 让程序按条件走不同分支：从上往下依次检查，第一个成立的分支执行完，'
        '后面的分支就全部跳过。',
    analogy:
        '像医院分诊台：先看是不是急诊（第一个条件），不是再看是不是普通门诊，都不符合才去别的窗口。'
        '一旦在某个窗口办完，就不会回头再排另一条队。',
    code: _pyIfCode,
    lineWalk: '''
- 第一行读入成绩并转换成整数，得到可以比较大小的数值。
- `if score >= 90:` 先检查最高的一档；冒号表示「下面是这个条件成立时要做的事」。
- 下一行 `print("优秀")` 前面有四个空格缩进，缩进是 Python 判断代码归属的方式，不是排版好看而已。
- `elif score >= 60:` 只有在第一条不成立时才会被检查；写成 `if` 就会变成两个独立判断。
- `else:` 不写条件，负责接住前面都不满足的情况。
- 最后一行 `print("判断结束")` 回到最左侧缩进，说明它不属于任何分支，无论走哪条路都会执行。
''',
    runThrough: '''
- 假设输入 95：第一个条件成立，输出「优秀」，`elif` 和 `else` 被跳过。
- 假设输入 72：第一个条件不成立，第二个条件成立，输出「及格」。
- 假设输入 40：两个条件都不成立，走 `else`，输出「需要补考」。
- 三种情况都会执行最后一行，屏幕最后都出现「判断结束」。
''',
    pitfalls: '''
- 用 `=` 代替 `>=`：`if score = 90` 是语法错误，`=` 是赋值，比较要用 `==`、`>=`。
- 缩进不统一：同一分支里混用 Tab 和四个空格，会报 `IndentationError`。
- 把 `elif` 写成 `else if`：那是 Java、C 的写法，Python 里只有 `elif`。
- 条件顺序颠倒：先写 `score >= 60` 再写 `score >= 90`，90 分也会被第一个条件拦下。
- 忘记冒号：`if score >= 90` 后面漏掉 `:`，下一行就会报语法错误。
''',
    drill: '''
- 输入 90 和 89，确认边界值的归属，理解 `>=` 和 `>` 的区别。
- 把两条分支顺序调换，再输入 95，解释为什么结果变错了。
- 增加一档「满分 100 时输出满分」，想清楚这一条应该放在什么位置。
''',
  ),
  LanguageIntroDetail(
    id: 'python_loops',
    sectionTitle: 'Python 循环',
    codeLanguage: 'python',
    oneLiner:
        'for 用来把一批已知的东西逐个处理一遍，while 用来在条件成立时反复做同一件事；'
        '两者都要想清楚「什么时候停」。',
    analogy:
        'for 像按清单点名：名单上有几个人就点几次，点完自动结束。'
        'while 像等水烧开：只要还没开就继续等，条件一变就得自己决定撤，没人替你喊停。',
    code: _pyLoopCode,
    lineWalk: '''
- `total = 0` 准备一个累加器，等会儿每加一笔都放回这个变量。
- `range(1, 6)` 会产生 1、2、3、4、5，注意包含起点不包含终点，所以写 6 才是到 5。
- 循环体里 `total = total + number` 是把「原来的累计值」和「本次的数字」相加，再覆盖回 `total`。
- 循环内的 `print` 每轮都执行，所以你会看到五行输出，而不是只有最后一行。
- `while total < 20:` 每轮开始前都重新检查一次条件，条件不成立才跳出循环。
- 最后一行缩进回到最左侧，属于循环之外，只在全部结束后执行一次。
''',
    runThrough: '''
- for 循环五轮结束时 `total` 是 15（1+2+3+4+5）。
- 进入 while：15 小于 20，加 5 变成 20。
- 再次检查条件，20 不小于 20，循环立刻停止。
- 最后输出「最终结果：20」，屏幕上一共出现 6 行内容。
''',
    pitfalls: '''
- 写成 `range(1, 5)` 却以为会到 5：终点始终不包含，这是最常见的差一错误。
- while 里忘记修改变量：条件永远为真，程序卡死，只能强制中断。
- 循环体内缩进不一致：要么报错，要么 `print` 跑到循环外，只输出一次。
- 在循环里用 `total = number` 而不是 `+=`：每轮都把之前的结果冲掉，最后只剩最后一个数。
- 分不清 `break` 和 `continue`：`break` 直接结束整个循环，`continue` 只是跳过本轮剩余语句。
''',
    drill: '''
- 把 `range(1, 6)` 改成 `range(1, 11)`，先算出总和再看输出。
- 在 for 循环里加一条判断，遇到 3 就跳过，比较加上 `continue` 前后的结果。
- 把 while 的条件改成 `total < 100` 并把每次加 5 改成加 0，观察死循环现象后强制停止。
''',
  ),
  LanguageIntroDetail(
    id: 'python_list_dict_basics',
    sectionTitle: 'Python 列表与字典',
    codeLanguage: 'python',
    oneLiner: '列表按顺序存放一串东西，用下标或循环取用；字典按名字存放键值对，用键直接找到对应的值。',
    analogy:
        '列表像排队的队伍，位置决定顺序，插队和离队都会影响前后关系；'
        '字典像手机通讯录，不关心第几个，只关心「名字」这个键能不能对到号码。',
    code: _pyListDictCode,
    lineWalk: '''
- `fruits = ["苹果", "香蕉", "橘子"]` 用方括号建立列表，元素之间用逗号分隔，顺序就是它们排列的顺序。
- `fruits.append("葡萄")` 把新元素加到列表末尾，列表长度从 3 变成 4。
- 花括号包围的 `price` 是字典，每一项都是 `键: 值`，这里用水果名当键、单价当值。
- `for fruit in fruits:` 逐个取出列表里的水果名，变量 `fruit` 每轮换一个值。
- `price[fruit]` 用方括号加键取出对应的价格；如果键不存在，会抛出 `KeyError`。
- `max(price.values())` 先取出所有价格，再从中找最大值。
''',
    runThrough: '''
- 列表里先有苹果、香蕉、橘子，追加葡萄之后共四项。
- 第一轮 `fruit` 是苹果，查出价格 6，输出「苹果 每斤 6 元」。
- 之后依次输出香蕉和葡萄的价格；橘子不在字典里，这一轮会直接报 `KeyError` 中断程序。
- 若把字典补上橘子，四轮都能跑完，最后输出「最贵的价格是 12 元」。
''',
    pitfalls: '''
- 用 `fruits[4]` 访问第四个位置：下标从 0 开始，越界会报 `IndexError`。
- 字典取到不存在的键不放兜底：应该用 `price.get("橘子", 0)`，取不到时返回默认值而不是崩溃。
- 把列表当字典用：`fruits["苹果"]` 是类型错误，列表只接受整数下标。
- 在遍历列表的同时删除元素：会跳过部分元素，应该先生成新列表再替换。
- 忘记字典的键必须可哈希：列表不能当键，元组和字符串可以。
''',
    drill: '''
- 给字典补上「橘子」的价格，让程序跑完并核对输出。
- 用 `price.get("橘子", 0)` 替换直接取值，再把橘子价格删掉，比较两种写法的结果。
- 增加一个「统计有多少种水果」的输出，用 `len(fruits)` 验证答案。
''',
  ),
];
