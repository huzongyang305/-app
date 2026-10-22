// Swift 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _swiftFirstCode = r'''print("你好，Swift")''';

const String _swiftVarCode = r'''let name: String = "小明"
var age: Int = 18
let height: Double = 1.75

age += 1

print("\(name) 明年 \(age) 岁，身高 \(height) 米")''';

const String _swiftIfCode = r'''let score = 72

if score >= 90 {
    print("优秀")
} else if score >= 60 {
    print("及格")
} else {
    print("需要补考")
}

let level = score >= 60 ? "通过" : "未通过"
print("结果：\(level)")''';

const String _swiftLoopCode = r'''var total = 0

for i in 1...5 {
    total += i
    print("加入 \(i) 后累计 \(total)")
}

while total < 20 {
    total += 5
}

print("最终结果：\(total)")''';

const String _swiftFuncCode = r'''func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}

func printResult(value: Int) {
    print("结果是 \(value)")
}

printResult(value: add(3, 4))
printResult(value: add(10, 20))''';

const List<LanguageIntroDetail> swiftIntroDetails = <LanguageIntroDetail>[
  ..._swiftFirstDetails,
  ..._swiftVarDetails,
  ..._swiftIfDetails,
  ..._swiftLoopDetails,
  ..._swiftFuncDetails,
];

const List<LanguageIntroDetail> _swiftFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'swift_first_program',
    sectionTitle: 'Swift 第一个程序',
    codeLanguage: 'swift',
    oneLiner:
        'Swift 代码可以直接在脚本模式或 Playground 里运行，'
        'print 把内容输出到控制台，不需要写入口函数。',
    analogy:
        'Playground 像一块可以随时改字的电子白板：你写一行，右边立刻显示结果，'
        '非常适合刚开始学语法时快速试错。',
    code: _swiftFirstCode,
    lineWalk: '''
- `print` 是全局函数，把参数转换成文本输出并换行。
- 字符串用双引号，中文可以直接写，Swift 源码默认按 UTF-8 处理。
- 顶层语句可以直接执行，不需要包在函数或类里，这一点和脚本语言很像。
- 语句末尾不写分号，只有在同一行写多条语句时才需要用分号分隔。
- 要编译成可执行文件，用 `swiftc hello.swift -o hello` 生成二进制。
''',
    runThrough: '''
- 用 `swift hello.swift` 直接运行，或先编译再执行。
- 顶层语句从上往下依次执行。
- print 把字符串送到标准输出。
- 屏幕显示「你好，Swift」，进程结束。
''',
    pitfalls: '''
- 在没有安装 Swift 工具链的机器上直接运行：Windows 需要额外安装 Swift for Windows。
- 把 print 写成 Print：Swift 区分大小写，会提示找不到标识符。
- 用单引号写字符串：Swift 的字符和字符串都用双引号，单引号不是合法语法。
- 在 iOS 项目里期待顶层语句可执行：应用入口需要遵循 UIApplication 生命周期。
- 忽略可选值：从字典或类型转换拿到的值可能是 nil，需要先解包。
''',
    drill: '''
- 把输出改成自己的名字并重新运行。
- 加一行 print，输出两行内容。
- 用 swiftc 编译成二进制，再直接执行它。
''',
  ),
];

const List<LanguageIntroDetail> _swiftVarDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'swift_constants_variables',
    sectionTitle: 'Swift 常量与变量',
    codeLanguage: 'swift',
    oneLiner:
        'let 声明常量、var 声明变量；'
        'Swift 是强类型语言，但大多数情况下编译器能自动推断类型。',
    analogy:
        'let 像刻在石头上的字，写好就不能改；var 像白板上的字，随时能擦掉重写。'
        '能刻石头就别用白板，改动越少，出错的机会越少。',
    code: _swiftVarCode,
    lineWalk: '''
- `let name: String = "小明"` 声明常量并显式标注类型。
- `var age: Int = 18` 声明变量，后面可以重新赋值。
- `let height: Double = 1.75` Double 是 64 位浮点类型，也是 Swift 浮点字面量的默认类型。
- `age += 1` 修改 var；如果写成 let，编译器会直接报错。
- 字符串插值用反斜杠加圆括号，把表达式结果嵌进字符串。
- 类型标注可以省略，例如 `let city = "北京"` 会被推断为 String。
''',
    runThrough: '''
- 三个常量或变量依次绑定。
- age 从 18 加到 19。
- 插值表达式依次求值，拼成完整的一句话。
- 输出「小明 明年 19 岁，身高 1.75 米」。
''',
    pitfalls: '''
- 把 let 当 var 用：想修改常量时编译失败，这其实是好事，提示你该用 var。
- 整数和小数混算：Int 和 Double 不能直接相加，必须显式转换。
- 忘记类型标注又想存 nil：非可选类型不能存 nil，必须写成可空类型。
- 用等号比较浮点数：二进制表示不精确，应比较差值是否小于容差。
- 认为类型推断能跨文件生效：推断只在当前表达式的上下文里发生。
''',
    drill: '''
- 把某一行改成 var，再重新赋值。
- 用显式类型标注重新声明一个变量，对比自动推断的写法。
- 故意把 Int 和 Double 相加，记录编译错误并改正。
''',
  ),
];

const List<LanguageIntroDetail> _swiftIfDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'swift_conditions',
    sectionTitle: 'Swift 条件判断',
    codeLanguage: 'swift',
    oneLiner:
        'Swift 的 if 条件必须是布尔表达式，且括号可以省略；'
        '三目运算符适合在两种取值之间二选一。',
    analogy:
        '三目运算符像考试卷上的选择题：条件成立就选第一个答案，否则选第二个，'
        '只用一行就能表达完整的分支。',
    code: _swiftIfCode,
    lineWalk: '''
- `let score = 72` 类型推断为 Int。
- `if score >= 90 {` 条件外可以省略括号，花括号必需。
- `else if` 和 `else` 只在前面的条件为假时才会被求值。
- 三目运算符的写法是「条件 ? 取值一 : 取值二」，两个分支类型必须一致。
- 字符串插值把变量值嵌进输出文字。
- Swift 还提供 switch，而且默认不贯穿，比 C 的 switch 更安全。
''',
    runThrough: '''
- score 为 72：第一个条件假，第二个真，输出「及格」。
- 三目运算符条件为真，level 得到「通过」。
- 输出「结果：通过」。
- 如果把 score 改成 95，会先输出「优秀」，level 仍是「通过」。
''',
    pitfalls: '''
- 用整数当条件：Swift 不接受非布尔值，编译直接报错。
- 两个分支类型不一致：三目运算符会编译失败，需要显式转换。
- 在条件里写赋值：Swift 的赋值不返回值，写在条件位置会报错。
- 把 switch 当 C 的写法加 break：Swift 的 case 默认不贯穿，break 一般不需要。
- 浮点数用等号比较：应比较差值是否小于容差。
''',
    drill: '''
- 用 90、89、60、59 四个值测试每条分支。
- 用 switch 重写这段判断，体会默认不贯穿的差别。
- 把三目运算符改成完整的 if/else 语句，比较可读性。
''',
  ),
];

const List<LanguageIntroDetail> _swiftLoopDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'swift_loops',
    sectionTitle: 'Swift 循环',
    codeLanguage: 'swift',
    oneLiner:
        'for-in 用来遍历区间或集合，while 按条件重复；'
        '`1...5` 是闭区间包含两端，`1..<5` 不包含终点。',
    analogy:
        '闭区间像排队买票时说的「1 到 5 号」，含头含尾；'
        '半开区间像切蛋糕时说的「从这刀到那刀之前」，终点不在其中。',
    code: _swiftLoopCode,
    lineWalk: '''
- `var total = 0` 声明可变累加器。
- `for i in 1...5` 用闭区间依次取 1 到 5。
- `total += i` 每轮把当前值累加进去。
- 循环体里的字符串插值嵌入 i 和 total。
- `while total < 20` 每轮开始前重新判断条件。
- 循环外的 print 只执行一次。
''',
    runThrough: '''
- for 结束后 total 是 15。
- while 第一轮把 15 加到 20。
- 再次判断条件不成立，退出循环。
- 输出「最终结果：20」；如果写成 `1..<5`，结果会少 5。
''',
    pitfalls: '''
- 混淆闭区间和半开区间：写错符号会造成差一错误。
- 在 for-in 里修改被遍历的集合：会触发运行时错误。
- 用 stride 时参数写反：从大到小要用负数步长。
- 忘记 var：循环里修改累加器会编译失败。
- 在循环条件里调用耗时计算：条件每轮求值，可能拖慢程序。
''',
    drill: '''
- 把区间改成 `1..<5`，观察结果差异。
- 用 stride 每隔 2 取一个数并累加。
- 用 repeat-while 重写循环，比较与 while 的执行次数差异。
''',
  ),
];

const List<LanguageIntroDetail> _swiftFuncDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'swift_functions_intro',
    sectionTitle: 'Swift 函数入门',
    codeLanguage: 'swift',
    oneLiner:
        'Swift 函数用 func 声明，参数默认带外部标签；'
        '不想写标签时用下划线占位，调用时就直接传值。',
    analogy:
        '参数标签像点菜时报的菜名：「宫保鸡丁」让服务员知道这是什么，'
        '而数量是实际值。标签让调用处读起来像一句自然语言。',
    code: _swiftFuncCode,
    lineWalk: '''
- `func add(_ a: Int, _ b: Int) -> Int` 用下划线省略外部参数标签。
- 箭头后面的 Int 是返回类型，函数体用 return 交回结果。
- `func printResult(value: Int)` 这里 value 同时是外部标签和内部参数名。
- 调用时必须写参数标签，标签是调用约定的一部分。
- 嵌套调用先算 add，再把结果传给 printResult。
- Swift 的参数默认按值传递，类实例传递的是引用。
''',
    runThrough: '''
- `add(3, 4)` 返回 7。
- 7 作为 value 参数传给 printResult，输出「结果是 7」。
- 第二次调用得到 30，输出「结果是 30」。
- 顶层函数依次执行完毕，进程结束。
''',
    pitfalls: '''
- 忽略参数标签：定义时没写标签却按标签调用，或反过来，都会编译失败。
- 返回类型和 return 的表达式不匹配：Swift 不做隐式转换，必须显式转换。
- 函数体最后一行想省略 return：多语句函数必须显式写 return。
- 参数用 let 声明：函数参数默认不可变，想改要先复制到局部变量。
- 把闭包和函数混淆：闭包是匿名函数，语法和 func 不同。
''',
    drill: '''
- 增加一个 `func multiply(_ a: Int, _ b: Int) -> Int` 并调用。
- 给 printResult 加上外部标签，让调用处更像自然语言。
- 写一个带默认参数值的函数，分别用默认值和显式值调用一次。
''',
  ),
];
