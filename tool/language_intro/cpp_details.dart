// C++ 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _cppFirstCode = r'''#include <iostream>

int main() {
    std::cout << "你好，C++" << std::endl;
    return 0;
}''';

const String _cppVarCode = r'''#include <iostream>
#include <string>

int main() {
    std::string name;
    int age = 0;

    std::cout << "请输入名字：";
    std::cin >> name;
    std::cout << "请输入年龄：";
    std::cin >> age;

    std::cout << name << " 明年 " << age + 1 << " 岁" << std::endl;
    return 0;
}''';

const String _cppIfCode = r'''#include <iostream>

int main() {
    int score = 0;
    std::cout << "请输入成绩：";
    std::cin >> score;

    if (score >= 90) {
        std::cout << "优秀" << std::endl;
    } else if (score >= 60) {
        std::cout << "及格" << std::endl;
    } else {
        std::cout << "需要补考" << std::endl;
    }
    return 0;
}''';

const String _cppLoopCode = r'''#include <iostream>

int main() {
    int total = 0;

    for (int i = 1; i <= 5; ++i) {
        total += i;
        std::cout << "加入 " << i << " 后累计 " << total << std::endl;
    }

    while (total < 20) {
        total += 5;
    }

    std::cout << "最终结果：" << total << std::endl;
    return 0;
}''';

const String _cppFuncCode = r'''#include <iostream>

int add(int a, int b) {
    return a + b;
}

void printResult(int value) {
    std::cout << "结果是 " << value << std::endl;
}

int main() {
    printResult(add(3, 4));
    printResult(add(10, 20));
    return 0;
}''';

const List<LanguageIntroDetail> cppIntroDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'cpp_first_program',
    sectionTitle: 'C++ 第一个程序',
    codeLanguage: 'cpp',
    oneLiner:
        'C++ 程序从 main 函数开始执行，`std::cout` 是标准输出流，'
        '用 `<<` 把内容一段段送进屏幕。',
    analogy:
        '把 `std::cout` 想成一根传送带：`<<` 是把包裹放上传送带的动作，'
        '你可以连续放好几件，它们就按顺序出现在屏幕上。',
    code: _cppFirstCode,
    lineWalk: '''
- `#include <iostream>` 引入输入输出流库，`std::cout` 和 `std::endl` 都由它提供。
- `int main()` 是程序入口，返回整数给操作系统表示结束状态。
- `std::cout` 表示标准输出流，`std::` 是命名空间前缀，说明这个 cout 来自标准库而不是别人自定义的同名对象。
- `<<` 是流插入运算符，把右边的内容交给左边的流；这里依次送入字符串和 `std::endl`。
- `std::endl` 输出换行并立刻刷新缓冲区，保证内容马上显示出来。
- `return 0;` 表示程序正常结束，非 0 通常表示出现了错误。
''',
    runThrough: '''
- 编译：`g++ hello.cpp -o hello`；C++ 源码后缀是 `.cpp`，编译器是 g++ 或 clang++。
- 运行：Linux 或 macOS 执行 `./hello`，Windows 执行 `hello.exe`。
- 进入 main 后执行 cout 语句，屏幕出现「你好，C++」并换行。
- main 返回 0，进程正常退出。
''',
    pitfalls: '''
- 写成 `#include <iostream.h>`：这是几十年前的老写法，现代编译器直接报错。
- 漏掉 `std::` 前缀：报 `cout was not declared in this scope`，除非显式写了 `using namespace std;`。
- 用 `std::endl` 却拼成 `std::end`：前者是换行符，后者是迭代器函数，含义完全不同。
- C++ 也需要分号，但类定义和函数体后面不写分号，混淆时以编译器报错为准。
- 直接双击源码文件：`.cpp` 是给人看的文本，必须编译成可执行文件才能运行。
''',
    drill: '''
- 把输出文字改成自己的名字，重新编译运行。
- 再写一条 `std::cout << "第二行" << std::endl;`，观察两行的效果。
- 把 `std::endl` 换成 `"\\n"`，说明两者在刷新时机上的差别。
''',
  ),
  LanguageIntroDetail(
    id: 'cpp_variables_io',
    sectionTitle: 'C++ 变量与输入输出',
    codeLanguage: 'cpp',
    oneLiner:
        'C++ 的变量先声明类型再使用，`std::cin` 用 `>>` 把键盘输入读进变量，'
        '不用像 C 那样写地址符号。',
    analogy:
        '`>>` 像把吸管插进杯子：数据从键盘那头流进变量这头，方向正好和 `<<` 相反。'
        '一进一出两个箭头指向不同，记住「箭头指向数据要去的地方」就不会搞混。',
    code: _cppVarCode,
    lineWalk: '''
- `std::string name;` 声明一个字符串变量，`std::string` 比 C 的字符数组更安全，会自动管理长度。
- `int age = 0;` 也给了初始值，避免变量在赋值前被意外读取。
- `std::cin >> name;` 从标准输入读一个单词存进 name，遇到空格或回车就停止。
- `std::cin >> age;` 按 int 类型解析输入；如果输入的不是数字，流会进入失败状态，后续读取全部失效。
- `age + 1` 先算加法，再把结果送进输出流；多个 `<<` 会按从左到右的顺序拼接。
''',
    runThrough: '''
- 输入 `小明` 后回车，name 得到「小明」。
- 输入 `18` 后回车，age 得到整数 18。
- 表达式 `age + 1` 算出 19，依次输出「小明 明年 19 岁」。
- 如果年龄输入 `abc`，cin 会置为失败状态，age 保持 0，输出会变成「明年 1 岁」，这就是不检查输入流状态的后果。
''',
    pitfalls: '''
- 用 `std::cin >> name` 读带空格的整句：只会拿到第一个词，要读整行得用 `std::getline`。
- 输入类型不匹配不检查：cin 失败后所有后续读取都会被跳过，程序行为异常。
- 忘记 `#include <string>`：`std::string` 定义在那个头文件里，缺少会报类型不完整。
- 把 `>>` 写成 `<<`：输入输出方向反过来，编译直接失败。
- 变量未初始化就参与计算：值不确定，属于典型的未定义行为。
''',
    drill: '''
- 把输入提示改成中文并加上冒号，注意提示不需要换行。
- 增加一个输入项，让用户输入身高并打印出来，类型选 `double`。
- 故意输入字母作为年龄，记录程序的表现，再查 `std::cin.fail()` 的用法。
''',
  ),
  LanguageIntroDetail(
    id: 'cpp_conditions',
    sectionTitle: 'C++ 条件判断',
    codeLanguage: 'cpp',
    oneLiner:
        'if / else if / else 按顺序检查条件，第一个成立的分支执行，其余跳过；'
        'C++ 里条件必须是能转成 bool 的表达式。',
    analogy:
        '像机场安检通道：工作人员按顺序问「有没有带液体」「有没有带打火机」，'
        '一旦某个问题对应处理完，就继续往前走，不会回头再走别的通道。',
    code: _cppIfCode,
    lineWalk: '''
- `int score = 0;` 声明并初始化，保证即使输入失败也有确定的值。
- `std::cin >> score;` 读入整数；失败时 score 不变，所以后面的判断依然有定义行为。
- `if (score >= 90)` 判断是否达到最高档；括号里是布尔表达式。
- `else if` 只在前一个条件为假时执行判断，因此顺序等价于优先级。
- `else` 收尾所有剩余情况，不需要写条件。
- C++ 允许在 if 的括号里直接写初始化语句，例如 `if (int n = f(); n > 0)`，这是 C 没有的特性。
''',
    runThrough: '''
- 输入 95：第一个条件为真，输出「优秀」。
- 输入 72：第一个为假、第二个为真，输出「及格」。
- 输入 40：两个都假，走 else，输出「需要补考」。
- 三种情况都会执行到 `return 0;`，进程正常结束。
''',
    pitfalls: '''
- 用 `=` 代替 `==`：`if (score = 90)` 会把 90 赋给 score 并判为真，编译器多数只给警告。
- 在 if 后面多写分号：条件后面那条空语句变成了分支体。
- 分支里只写一行就不加花括号：以后加第二行时容易被误以为也在分支里。
- 用浮点数做相等比较：`0.1 + 0.2 == 0.3` 通常为假，要比较差值是否小于容差。
- 忘记条件顺序导致高档被低档拦截：分数判断必须从高到低写。
''',
    drill: '''
- 用 90 和 89 测试边界，说明 `>=` 的含义。
- 把两个分支顺序调换，用 95 复现错误结果并解释原因。
- 增加一档「满分」判断，想清楚它应该放在哪一层。
''',
  ),
  LanguageIntroDetail(
    id: 'cpp_loops',
    sectionTitle: 'C++ 循环',
    codeLanguage: 'cpp',
    oneLiner:
        'for 适合次数确定的遍历，while 适合由条件决定何时结束的循环；'
        '两者都要保证循环会向终点推进。',
    analogy:
        'for 像自动扶梯的台阶计数：上去一格、计数加一，到顶层自然停。'
        'while 像手动搅拌：只要还稠就继续搅，稠不稠由你判断，忘了停就会一直搅。',
    code: _cppLoopCode,
    lineWalk: '''
- `int total = 0;` 初始化累加器。
- `for (int i = 1; i <= 5; ++i)` 中 `++i` 是前置自增，对整数来说效果和 `i++` 相同，但习惯上循环里更常用前置形式。
- `total += i;` 等价于 `total = total + i`。
- 循环体里的 cout 每轮执行，所以会输出五行。
- `while (total < 20)` 在每轮开始前重新求值，条件为假才退出。
- 循环后的输出只执行一次，给出最终结果。
''',
    runThrough: '''
- for 五轮结束后 total 为 15。
- while 第一轮把 15 加到 20。
- 再次判断 20 不小于 20，循环结束。
- 输出「最终结果：20」；如果把 `total += 5` 删掉，条件永远为真，程序将卡死。
''',
    pitfalls: '''
- 在 for 的括号后加分号：循环体变成空语句，后面的输出只执行一次。
- 在循环条件里用 `i != n`：步长大于 1 时可能直接跳过终点，导致死循环。
- 在循环里修改 `i`：次数不可控，属于难查的逻辑错误。
- 用 `int` 累加超大结果导致溢出：需要更大范围时改用 `long long`。
- 忘记初始化累加变量：total 的值不确定，输出不可复现。
''',
    drill: '''
- 把循环改成从 1 累加到 100，先估算量级再运行。
- 加入 `break` 让循环在 i 等于 3 时提前结束，解释总和变化。
- 把 while 的增量改成 0，复现死循环并说明如何在终端中断程序。
''',
  ),
  LanguageIntroDetail(
    id: 'cpp_functions_intro',
    sectionTitle: 'C++ 函数入门',
    codeLanguage: 'cpp',
    oneLiner:
        '函数把逻辑打包成可复用的单元，调用者通过参数传入数据、通过返回值取回结果；'
        '把函数声明和定义分开写，是 C++ 工程的常见做法。',
    analogy:
        '函数像餐厅的菜谱条目：菜名是函数名，食材清单是参数，做好的菜是返回值。'
        '厨师按菜谱做，重复点同一道菜也不会重复写菜谱。',
    code: _cppFuncCode,
    lineWalk: '''
- `int add(int a, int b)` 声明返回值是 int，并接受两个 int 参数。
- `return a + b;` 计算并结束函数，把结果交给调用处。
- `void printResult(int value)` 的返回类型是 void，表示不返回任何值。
- `printResult(add(3, 4))` 是嵌套调用：先算 add 得到 7，再把 7 传进 printResult。
- 参数默认按值传递，函数里拿到的是副本，改副本不影响调用方的变量。
- C++ 支持函数重载：同名函数只要参数列表不同就能共存，编译器按实参类型选择。
''',
    runThrough: '''
- 执行 `add(3, 4)`，进入函数体算出 7 并返回。
- 7 作为实参传给 printResult，函数体输出「结果是 7」。
- 第二次调用嵌套执行 `add(10, 20)` 得到 30，输出「结果是 30」。
- main 返回 0，程序结束。
''',
    pitfalls: '''
- 函数声明和定义签名不一致：参数类型或 const 修饰不同会被当作两个函数，链接时报找不到符号。
- 返回局部变量的引用或指针：函数结束后对象销毁，调用方拿到悬空引用。
- 参数用值传递传大对象：每次调用都复制一遍，应该改成 `const T&`。
- 忘记写返回语句：有返回类型的函数走到末尾属于未定义行为。
- 头文件里直接写函数定义却不加 `inline`：多个源文件包含时会出现重复定义错误。
''',
    drill: '''
- 增加一个 `int multiply(int a, int b)` 并调用验证。
- 写一个返回 void 的函数，把一行文字打印两次，观察返回类型的作用。
- 把 `printResult` 的参数改成 `const int&`，说明这样改能省掉一次复制。
''',
  ),
];
