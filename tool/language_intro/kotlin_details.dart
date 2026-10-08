// Kotlin 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _ktFirstCode = r'''fun main() {
    println("你好，Kotlin")
}''';

const String _ktVarCode = r'''fun main() {
    val name: String = "小明"
    var age: Int = 18
    val height: Double = 1.75
    val nickname: String? = null

    age += 1

    println("$name 明年 $age 岁，身高 $height 米")
    println("昵称长度：" + (nickname?.length ?: 0))
}''';

const String _ktIfCode = r'''fun main() {
    val score = 72

    if (score >= 90) {
        println("优秀")
    } else if (score >= 60) {
        println("及格")
    } else {
        println("需要补考")
    }

    val level = when {
        score >= 90 -> 'A'
        score >= 60 -> 'B'
        else -> 'C'
    }
    println("等级：$level")
}''';

const String _ktLoopCode = r'''fun main() {
    var total = 0

    for (i in 1..5) {
        total += i
        println("加入 $i 后累计 $total")
    }

    while (total < 20) {
        total += 5
    }

    println("最终结果：$total")
}''';

const String _ktFuncCode = r'''fun add(a: Int, b: Int): Int {
    return a + b
}

fun multiply(a: Int, b: Int): Int = a * b

fun printResult(value: Int) {
    println("结果是 $value")
}

fun main() {
    printResult(add(3, 4))
    printResult(multiply(3, 4))
}''';

const List<LanguageIntroDetail> kotlinIntroDetails = <LanguageIntroDetail>[
  ..._ktFirstDetails,
  ..._ktVarDetails,
  ..._ktIfDetails,
  ..._ktLoopDetails,
  ..._ktFuncDetails,
];

const List<LanguageIntroDetail> _ktFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'kotlin_first_program',
    sectionTitle: 'Kotlin 第一个程序',
    codeLanguage: 'kotlin',
    oneLiner:
        'Kotlin 程序从顶层 main 函数开始，不需要写类；'
        'println 负责输出，语句末尾通常不写分号。',
    analogy:
        'Kotlin 像把工具直接摆在桌面上：不需要先声明一个工具箱才能取用，'
        '写个函数就能跑，省掉了大量仪式感代码。',
    code: _ktFirstCode,
    lineWalk: '''
- `fun main()` 定义顶层函数作为入口，fun 是 function 的缩写。
- 花括号包围函数体，Kotlin 不要求把函数放进类里。
- `println("你好，Kotlin")` 输出内容并换行，它来自 kotlin 标准库。
- 行尾不写分号，写了也不会报错，但惯例上省略。
- Kotlin 文件后缀是 `.kt`，用 kotlinc 编译成 JVM 字节码或用 Gradle 构建。
''',
    runThrough: '''
- 用 `kotlinc hello.kt -include-runtime -d hello.jar` 编译成可执行 jar。
- 执行 `java -jar hello.jar` 运行。
- JVM 加载 main 函数并执行 println。
- 屏幕输出「你好，Kotlin」并换行，进程结束。
''',
    pitfalls: '''
- 写 `void main()`：Kotlin 用 fun 声明函数，不写返回类型表示返回 Unit。
- 把 main 放进类里又不加注解：默认不会当作入口，需要额外的 JVM 注解配合。
- 用 System.out.println：能用但不地道，标准库的 println 更简洁。
- 忘记安装 JDK：Kotlin 编译到 JVM 字节码，没有 JDK 无法运行。
- 把文件名和入口函数名绑定：Kotlin 不像 Java 有强制对应关系。
''',
    drill: '''
- 把输出文字改成自己的名字并重新运行。
- 再写一条 println，观察两行输出。
- 把 println 改成 print，比较两者的换行差异。
''',
  ),
];

const List<LanguageIntroDetail> _ktVarDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'kotlin_variables_null',
    sectionTitle: 'Kotlin 变量与可空类型',
    codeLanguage: 'kotlin',
    oneLiner:
        'val 声明不可变引用、var 声明可变变量；'
        '类型后面加问号表示可空，使用前必须先处理 null。',
    analogy:
        '可空类型像包裹上的「可能为空」标签：快递员不会直接把盒子撕开给你，'
        '而是要求你先确认里面有没有东西，或者给出一个默认结果。',
    code: _ktVarCode,
    lineWalk: '''
- `val name: String = "小明"` 用 val 声明只读引用，之后不能重新赋值。
- `var age: Int = 18` 用 var 声明可变变量，可以再次赋值。
- `val nickname: String? = null` 的问号表示这个变量可能是 null。
- `age += 1` 修改 var 变量；如果 age 是 val，这行会编译失败。
- `nickname?.length` 是安全调用：nickname 为 null 时整个表达式返回 null，不会崩溃。
- Elvis 运算符在左边为 null 时取右边的默认值。
''',
    runThrough: '''
- name、age、height 依次绑定，nickname 绑定为 null。
- age 从 18 加到 19。
- 第一条输出直接引用变量，得到「小明 明年 19 岁，身高 1.75 米」。
- 第二条输出中安全调用返回 null，Elvis 取 0，输出「昵称长度：0」。
''',
    pitfalls: '''
- 用双叹号强行解包可空值：为 null 时抛 NullPointerException，等于放弃 Kotlin 的保护。
- 该用 val 的地方写成 var：可变范围越大越容易出错，能用 val 就用 val。
- 忘记类型后面的问号：把 null 赋给非空类型会直接编译失败。
- 对可空值直接调用方法：编译不过，必须先安全调用或判空。
- 混淆两个等号和三个等号：前者比较值等价性，后者比较引用地址。
''',
    drill: '''
- 把 val 改成 var 再尝试重新赋值，观察两种声明方式的差异。
- 用安全调用和 Elvis 组合给昵称提供一个默认显示值。
- 故意用双叹号访问 null，运行后记录异常信息。
''',
  ),
];

const List<LanguageIntroDetail> _ktIfDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'kotlin_conditions',
    sectionTitle: 'Kotlin 条件判断',
    codeLanguage: 'kotlin',
    oneLiner:
        'Kotlin 的 if 是表达式，可以直接赋值；'
        'when 取代了传统 switch，既能匹配值也能写条件分支。',
    analogy:
        'when 像分诊台的一张对照表：从上往下逐条对照，'
        '第一条匹配的规则决定去向，剩下的规则不再看。',
    code: _ktIfCode,
    lineWalk: '''
- `val score = 72` 类型自动推断为 Int。
- `if (score >= 90) {` 条件要写括号，这和 Go 正好相反。
- `else if` 和 `else` 的写法和 Java 类似，但分支体是表达式。
- when 不带参数时按条件判断，等价于链式 if/else if。
- 箭头右边的字符就是该分支的值，when 整体作为表达式赋给 level。
- 分支必须覆盖所有可能，否则作为表达式使用时编译不通过。
''',
    runThrough: '''
- score 为 72：if 链走第二个分支，输出「及格」。
- when 表达式从上往下匹配：90 分支假，60 分支真，得到字符 B。
- 输出「等级：B」。
- 如果把 score 改成 95，if 链输出「优秀」，when 得到 A。
''',
    pitfalls: '''
- when 缺少 else：作为表达式使用时必须穷尽所有情况，否则编译失败。
- 分支顺序写反：低档写在高档前面，高档永远匹配不到。
- 在分支里写多行却不加花括号：箭头分支需要花括号包围多语句。
- 用一个等号代替两个等号：Kotlin 会报类型错误，比 C 安全。
- 把 when 写成 switch：Kotlin 没有 switch 关键字，旧代码迁移时要注意。
''',
    drill: '''
- 用 90、89、60、59 四个值测试两个分支结构。
- 把 when 改成带参数的写法，用分数区间做映射。
- 尝试删掉 else，观察编译器的报错。
''',
  ),
];

const List<LanguageIntroDetail> _ktLoopDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'kotlin_loops',
    sectionTitle: 'Kotlin 循环',
    codeLanguage: 'kotlin',
    oneLiner:
        'for 用区间或集合遍历，while 按条件重复；'
        'Kotlin 的范围表达式 `1..5` 表示闭区间，包含两端。',
    analogy:
        '区间表达式像点名册上的起止编号，`1..5` 表示从 1 号到 5 号全部点到；'
        '写成 until 5 就是不含 5 号，名字虽像，点到的人却少一个。',
    code: _ktLoopCode,
    lineWalk: '''
- `var total = 0` 声明可变累加器。
- `for (i in 1..5)` 依次取 1 到 5，闭区间包含两端。
- `total += i` 把当前数字累加进去。
- 循环体里的 println 用字符串模板嵌入两个变量。
- `while (total < 20)` 每轮开始前判断条件。
- 循环外的 println 只执行一次。
''',
    runThrough: '''
- for 结束后 total 是 15。
- while 第一轮把 15 加到 20。
- 再次判断条件不成立，循环结束。
- 输出「最终结果：20」；如果写成 `1 until 5`，total 会变成 10。
''',
    pitfalls: '''
- 混淆闭区间和 until：前者含终点，后者不含，是最常见的差一错误。
- 用 downTo 时写反区间：需要从大到小遍历要用 downTo，而不是倒着写。
- 在 for 里修改迭代变量：Kotlin 的循环变量是只读的，改不了。
- 忘记 var：循环里修改 total 会编译失败。
- 在循环条件里做副作用：条件每轮求值，副作用会重复发生。
''',
    drill: '''
- 把区间改成 `1 until 5`，比较和 `1..5` 的结果差异。
- 增加 `step 2` 让循环隔一个数走一次。
- 用 downTo 从 5 累加到 1，观察结果是否相同。
''',
  ),
];

const List<LanguageIntroDetail> _ktFuncDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'kotlin_functions_intro',
    sectionTitle: 'Kotlin 函数入门',
    codeLanguage: 'kotlin',
    oneLiner:
        'Kotlin 函数用 fun 声明，参数和返回值都要写类型；'
        '单表达式函数可以用等号直接写，省掉花括号。',
    analogy:
        '单表达式函数像把菜谱压缩成一行：原料和成品都写清楚，'
        '中间步骤足够简单时就省略，读起来反而更快。',
    code: _ktFuncCode,
    lineWalk: '''
- 块体函数用花括号包围，返回类型写在参数列表之后。
- 冒号后面的 Int 是返回类型，参数类型写在参数名之后。
- 单表达式函数用等号连接，等号右边直接是返回值。
- `fun printResult(value: Int)` 不写返回类型，默认返回 Unit。
- 顶层函数不需要包在类里，Kotlin 允许文件级函数。
- 调用 `add(3, 4)` 得到 7，再作为实参传给 printResult。
''',
    runThrough: '''
- `add(3, 4)` 返回 7，输出「结果是 7」。
- `multiply(3, 4)` 返回 12，输出「结果是 12」。
- 两个函数都不依赖对象，直接调用即可。
- main 执行完毕，进程退出。
''',
    pitfalls: '''
- 参数不写类型：Kotlin 不允许在函数签名里省略类型。
- 有返回类型却忘记 return：块体函数必须显式返回，除非返回 Unit。
- 单表达式函数里写 return：等号形式不能写 return，会编译失败。
- 用 Java 的可变参数写法：Kotlin 用 vararg 关键字。
- 命名参数和位置参数混用顺序错误：命名参数之后不能再写位置参数。
''',
    drill: '''
- 增加一个 `fun subtract(a: Int, b: Int): Int = a - b`。
- 给 printResult 增加一个前缀参数，调用时使用命名参数。
- 把 multiply 改回块体写法，比较两种风格。
''',
  ),
];
