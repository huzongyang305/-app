// Go 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _goFirstCode = r'''package main

import "fmt"

func main() {
    fmt.Println("你好，Go")
}''';

const String _goVarCode = r'''package main

import (
    "bufio"
    "fmt"
    "os"
    "strconv"
    "strings"
)

func main() {
    reader := bufio.NewReader(os.Stdin)

    fmt.Print("请输入年龄：")
    line, _ := reader.ReadString('\n')
    line = strings.TrimSpace(line)

    age, err := strconv.Atoi(line)
    if err != nil {
        fmt.Println("这不是一个整数：", err)
        return
    }

    fmt.Printf("明年你 %d 岁\n", age+1)
}''';

const String _goIfCode = r'''package main

import "fmt"

func main() {
    score := 72

    if score >= 90 {
        fmt.Println("优秀")
    } else if score >= 60 {
        fmt.Println("及格")
    } else {
        fmt.Println("需要补考")
    }
}''';

const String _goLoopCode = r'''package main

import "fmt"

func main() {
    total := 0

    for i := 1; i <= 5; i++ {
        total += i
        fmt.Printf("加入 %d 后累计 %d\n", i, total)
    }

    for total < 20 {
        total += 5
    }

    fmt.Println("最终结果：", total)
}''';

const String _goFuncCode = r'''package main

import "fmt"

func add(a int, b int) int {
    return a + b
}

func printResult(value int) {
    fmt.Println("结果是", value)
}

func main() {
    printResult(add(3, 4))
    printResult(add(10, 20))
}''';

const List<LanguageIntroDetail> goIntroDetails = <LanguageIntroDetail>[
  ..._goFirstDetails,
  ..._goVarDetails,
  ..._goIfDetails,
  ..._goLoopDetails,
  ..._goFuncDetails,
];

const List<LanguageIntroDetail> _goFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'go_first_program',
    sectionTitle: 'Go 第一个程序',
    codeLanguage: 'go',
    oneLiner:
        'Go 程序必须放在 package main 里，入口函数是 main；'
        '它编译成一个不需要额外运行时的独立可执行文件。',
    analogy:
        '把 package main 想成大楼的门牌号，func main 想成唯一的正门。'
        '整栋楼可以有很多房间（函数），但进出只能走这道门。',
    code: _goFirstCode,
    lineWalk: '''
- `package main` 声明当前文件属于 main 包，只有 main 包才会被编译成可执行程序。
- `import "fmt"` 引入格式化输入输出包，Println 这个函数来自它。
- `func main()` 是程序入口，没有参数也没有返回值，首字母小写表示只在包内可见。
- `fmt.Println("你好，Go")` 输出内容并换行。
- Go 不写分号，编译器会自动在行尾插入，但左花括号必须和函数声明写在同一行。
- 保存为 `.go` 文件后用 go run 直接跑，或 go build 生成可执行文件。
''',
    runThrough: '''
- 运行 `go run main.go`，工具链先编译再执行。
- 程序从 main 函数开始，调用 fmt.Println。
- 屏幕输出「你好，Go」并换行。
- main 返回后进程结束，退出码为 0。
''',
    pitfalls: '''
- 包名写成别的名字：编译不会报错，但无法生成可执行程序。
- 引入的包没有使用：Go 把未使用的 import 当作编译错误，不是警告。
- 左花括号另起一行：Go 会自动插入分号，导致语法错误。
- 函数名首字母大写想对外暴露：大写才是导出，小写只在包内可见。
- 忘记变量声明方式：`:=` 是短声明，只能在函数内部使用。
''',
    drill: '''
- 把输出文字改成自己的名字，用 go run 运行。
- 再写一条 fmt.Println，观察两行的效果。
- 故意增加一个未使用的 import，记录编译错误。
''',
  ),
];

const List<LanguageIntroDetail> _goVarDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'go_variables_input',
    sectionTitle: 'Go 变量与输入',
    codeLanguage: 'go',
    oneLiner:
        'Go 用 := 在函数内快速声明变量，用 var 声明包级变量；'
        '读取输入要处理换行符，转换字符串要显式调用 strconv。',
    analogy:
        '把输入流想成一条水管：ReadString 每次接一段，末尾带着换行这个包装纸，'
        'TrimSpace 就是撕掉包装纸的动作，撕干净才能正确换算成数字。',
    code: _goVarCode,
    lineWalk: '''
- `bufio.NewReader(os.Stdin)` 包一层缓冲读取器，能按行读取标准输入。
- ReadString 读到换行符为止，第二个返回值是错误；这里用下划线显式忽略。
- `strings.TrimSpace(line)` 去掉行尾的换行和空格，否则 Atoi 会失败。
- `strconv.Atoi(line)` 把字符串转成整数，同时返回错误；Go 习惯把错误作为最后一个返回值。
- `if err != nil` 是 Go 最常见的错误处理写法，必须显式判断，没有异常机制。
- `fmt.Printf` 按格式串输出，百分号 d 对应整数，反斜杠 n 表示换行。
''',
    runThrough: '''
- 输入 18 并回车，ReadString 返回带换行的字符串。
- TrimSpace 去掉换行得到「18」。
- Atoi 转换成功，err 为 nil，跳过错误分支。
- Printf 把 18+1=19 填进占位符，输出「明年你 19 岁」。
''',
    pitfalls: '''
- 忘记 TrimSpace：Atoi 会因换行字符转换失败，返回错误。
- 用下划线忽略 Atoi 的错误：非法输入时 age 是 0，程序继续跑出错结果。
- 把 bufio 和 fmt.Scan 混用：缓冲读取器可能已经预读数据，导致后续读不到输入。
- 变量声明后未使用：Go 把未使用的局部变量当作编译错误。
- 混淆短声明和赋值：短声明是声明并赋值，等号是给已有变量赋值。
''',
    drill: '''
- 输入 18、abc、空行，观察三种情况下的输出差异。
- 把 Atoi 换成 ParseFloat，读入身高并输出。
- 给错误提示加上具体原因，让用户知道应该输入什么。
''',
  ),
];

const List<LanguageIntroDetail> _goIfDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'go_conditions',
    sectionTitle: 'Go 条件判断',
    codeLanguage: 'go',
    oneLiner:
        'Go 的 if 条件不需要括号，但花括号必需；'
        'if 支持先执行一条初始化语句，再判断条件。',
    analogy:
        '像进门前先刷卡：刷卡是初始化，门开不开是条件判断。'
        'Go 允许把这两步写在同一行里，读起来像一句完整的话。',
    code: _goIfCode,
    lineWalk: '''
- `score := 72` 用短声明定义变量，类型由右边的值推断。
- `if score >= 90 {` 条件外不需要括号，这也是 Go 和 C 家族最直观的差别。
- `} else if score >= 60 {` 的 else 必须和上一个右花括号写在同一行，否则编译报错。
- `else` 同样必须紧贴前一个右花括号。
- 从 Go 1.13 起支持带初始化的 if，例如先调用函数再判断返回的错误。
- Go 没有三元运算符，简单的二选一也要写成完整的 if。
''',
    runThrough: '''
- score 为 72：第一个条件为假，第二个为真，输出「及格」。
- 改成 95：第一个条件成立，输出「优秀」。
- 改成 40：两个条件都不成立，走 else 输出「需要补考」。
- 三种情况都会执行到函数末尾，程序正常退出。
''',
    pitfalls: '''
- 给 if 加括号：语法上可以，但 gofmt 会去掉，团队风格不该保留。
- 把 else 写到下一行：Go 自动插入分号，导致语法错误。
- 条件用整数代替布尔：Go 不接受非布尔值做条件，必须写明确比较。
- 浮点数直接用等号比较：应比较差值是否小于容差。
- 在 if 里声明变量却在外面使用：作用域只到 if 语句结束为止。
''',
    drill: '''
- 用 90、89、60、59 四个值测试每条分支。
- 用带初始化的 if 改写判断，把 score 的声明放进 if 里。
- 交换前两个条件的顺序，用 95 验证结果变化。
''',
  ),
];

const List<LanguageIntroDetail> _goLoopDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'go_loops',
    sectionTitle: 'Go 循环',
    codeLanguage: 'go',
    oneLiner:
        'Go 只有一种循环关键字 for，但能写出三种形态：'
        '经典计数循环、只有条件的 while 风格循环，以及无限循环。',
    analogy:
        '像一把可调节的扳手：工具只有一件，但通过调节条件，'
        '既能拧固定圈数的螺丝，也能一直拧到某个阈值为止。',
    code: _goLoopCode,
    lineWalk: '''
- `total := 0` 声明累加器。
- `for i := 1; i <= 5; i++` 是经典三段式，初始化和自增都写在 for 里。
- `total += i` 把当前数字累加进 total。
- 循环体里的 Printf 每轮执行，百分号 d 依次替换成 i 和 total。
- `for total < 20 {` 省略初始化和自增，等价于其他语言的 while。
- 循环外的 Println 只执行一次，输出最终值。
''',
    runThrough: '''
- 第一段循环结束后 total 是 15。
- 第二段循环第一轮把 15 加到 20。
- 再次判断 20 小于 20 为假，循环结束。
- 输出「最终结果：20」；如果循环体里不修改 total，程序会一直转下去。
''',
    pitfalls: '''
- 在循环条件里调用耗时函数：每轮都执行一次，可能成为性能问题。
- for 的三个部分写颠倒了：Go 顺序固定为初始化、条件、后置语句。
- 用 for range 遍历时修改切片长度：行为不确定，应该先复制或改用索引。
- 忘记 break 的退出条件：死循环会占满一个 CPU 核心。
- 在循环里用 defer：要等函数返回才执行，可能造成资源迟迟不释放。
''',
    drill: '''
- 把循环改成从 1 累加到 100，先估算量级再运行。
- 用 for range 遍历一个整数切片并累加，比较两种写法。
- 写一个不带条件的 for 无限循环，在内部用 break 退出。
''',
  ),
];

const List<LanguageIntroDetail> _goFuncDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'go_functions_intro',
    sectionTitle: 'Go 函数入门',
    codeLanguage: 'go',
    oneLiner:
        'Go 的函数可以返回多个值，错误通常作为最后一个返回值；'
        '首字母大写的函数才能被其他包使用。',
    analogy:
        '多返回值像一次交接同时给你两样东西：结果和一张是否顺利的说明条。'
        '调用方必须两样都看，不能只看结果不看说明。',
    code: _goFuncCode,
    lineWalk: '''
- `func add(a int, b int) int` 声明函数，参数类型写在变量名后面，返回类型写在参数列表之后。
- 相邻参数类型相同可以合并写成 `a, b int`，两种写法等价。
- `return a + b` 返回计算结果，Go 不写分号。
- `func printResult(value int)` 没有返回类型，表示不返回值。
- 调用 `add(3, 4)` 得到 7，再作为实参传给 printResult。
- 首字母小写的函数只在当前包内可见，大写才能被其他包导入使用。
''',
    runThrough: '''
- `add(3, 4)` 返回 7。
- printResult 收到 7，输出「结果是 7」。
- 第二次调用 `add(10, 20)` 返回 30，输出「结果是 30」。
- main 执行完毕，进程退出。
''',
    pitfalls: '''
- 把参数类型写在变量名前面：Go 的顺序是「变量名 类型」，写成 int a 会编译失败。
- 忽略函数返回的 error：Go 不会强制你处理，但忽略错误是线上事故的常见来源。
- 返回局部变量的指针：Go 会自动把逃逸的变量分配到堆上，这一点比 C 安全，但仍有性能影响。
- 函数名首字母小写却想被别的包调用：可见性由首字母大小写决定。
- 用命名返回值时忘记 return：会导致编译错误或返回零值。
''',
    drill: '''
- 增加一个 `func multiply(a, b int) int` 并调用打印。
- 写一个返回两个值的函数，一个结果一个 error，在调用处显式判断。
- 把 add 的名字改成 Add，说明导出规则的变化。
''',
  ),
];
