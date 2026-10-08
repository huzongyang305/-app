// C 语言入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _cFirstCode = r'''#include <stdio.h>

int main(void) {
    printf("你好，C 语言\n");
    return 0;
}''';

const String _cVarCode = r'''#include <stdio.h>

int main(void) {
    int age = 18;
    double height = 1.75;
    char grade = 'A';
    char name[16] = "小明";

    printf("%s 今年 %d 岁，身高 %.2f 米，评级 %c\n",
           name, age, height, grade);
    return 0;
}''';

const String _cIfCode = r'''#include <stdio.h>

int main(void) {
    int score = 0;
    printf("请输入成绩：");
    scanf("%d", &score);

    if (score >= 90) {
        printf("优秀\n");
    } else if (score >= 60) {
        printf("及格\n");
    } else {
        printf("需要补考\n");
    }
    return 0;
}''';

const String _cLoopCode = r'''#include <stdio.h>

int main(void) {
    int total = 0;

    for (int i = 1; i <= 5; i++) {
        total += i;
        printf("加入 %d 之后，累计是 %d\n", i, total);
    }

    while (total < 20) {
        total += 5;
    }

    printf("最终结果：%d\n", total);
    return 0;
}''';

const String _cFuncCode = r'''#include <stdio.h>

int add(int a, int b) {
    return a + b;
}

void print_result(int value) {
    printf("结果是 %d\n", value);
}

int main(void) {
    int sum = add(3, 4);
    print_result(sum);
    print_result(add(10, 20));
    return 0;
}''';

const List<LanguageIntroDetail> cIntroDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'c_first_program',
    sectionTitle: 'C 语言第一个程序',
    codeLanguage: 'c',
    oneLiner:
        '一个 C 程序必须有一个 main 函数，程序从它开始执行；'
        '#include 把工具说明书提前拿进来，printf 负责往屏幕写字。',
    analogy:
        '把 main 想成大楼唯一的正门：不管楼里有多少房间，进程每次都是从这道门进来、从这道门出去。'
        'include 则是开工前先领的工具箱，没领到工具箱，后面的螺丝刀就用不了。',
    code: _cFirstCode,
    lineWalk: '''
- `#include <stdio.h>` 是预处理指令，在真正编译前把标准输入输出库的声明贴进来，`printf` 的用法就来自这里。
- `int main(void)` 定义主函数：`int` 表示它会给操作系统返回一个整数，`void` 表示它不接受参数。
- `{` 和 `}` 圈出函数体，所有属于 main 的语句都写在这对花括号之间。
- `printf("你好，C 语言\\n");` 把引号里的内容打印出来；`\\n` 是换行符，不加它光标会停在行尾。
- 每个语句结尾的分号不能省，它是 C 用来判断「这句话说完了」的标记。
- `return 0;` 把 0 交还给操作系统，惯例上 0 表示程序正常结束，非 0 表示出错。
''',
    runThrough: '''
- 编译：`gcc hello.c -o hello`，把源码翻译成可执行文件；编译失败会直接报错行号和原因。
- 运行：Linux 或 macOS 执行 `./hello`，Windows 执行 `hello.exe`。
- 程序进入 main，执行 printf，屏幕出现 `你好，C 语言` 并换行。
- main 返回 0，进程结束；在 Linux 终端可以用 echo 加问号查看上一条命令的退出码，Windows 用 echo %ERRORLEVEL%。
''',
    pitfalls: '''
- 忘记 `#include <stdio.h>`：编译器会警告 `implicit declaration of printf`，新标准下直接报错。
- 把 `main` 拼成 `mian` 或 `Main`：C 区分大小写，链接阶段会报找不到入口。
- 语句末尾漏分号：报错行通常指向下一行，实际错误在上一行结尾。
- 忘了 `return 0;`：现代标准会默认返回 0，但显式写出来更清楚，也能避免老编译器告警。
- 用中文标点写代码：全角分号、全角括号都不是合法符号，编译器会给出难以理解的报错。
''',
    drill: '''
- 把输出的文字换成自我介绍，重新编译运行，确认输出变化。
- 在 printf 后面再加一行 printf，观察两次输出是否会换行。
- 故意删掉第一行的 `#include`，记录完整的编译错误，体会「报错要看第一条」。
''',
  ),
  LanguageIntroDetail(
    id: 'c_variables_io',
    sectionTitle: 'C 语言变量与输入输出',
    codeLanguage: 'c',
    oneLiner:
        'C 的变量必须先声明类型再用，类型决定它能装什么、占几个字节；'
        'scanf 负责读入数据，而给变量地址才能把读到的值写进去。',
    analogy:
        '变量像一排标好用途的储物柜：整型柜只能放整数，双精度柜只能放小数。'
        'scanf 像快递员，你必须把柜子的门牌号（地址）告诉它，它才知道该把包裹放进哪个柜子。',
    code: _cVarCode,
    lineWalk: '''
- `int age = 18;` 声明一个整数变量并初始化；C 里不写类型就编译不过。
- `double height = 1.75;` 用双精度浮点保存小数，日常计算比 `float` 更稳。
- `char grade = 'A';` 单个字符用单引号；双引号在 C 里表示字符串，两者不能互换。
- `char name[16] = "小明";` 这是字符数组，中文字符在 UTF-8 下占 3 个字节，所以要留出足够空间防止溢出。
- `printf` 第一个参数里的 `%s`、`%d`、`%.2f`、`%c` 是占位符，必须和后面参数的顺序、类型一一对应。
- `scanf("%d", &score)` 里的 `&` 取变量地址；漏掉它，输入的值就写不进变量，还可能直接崩溃。
''',
    runThrough: '''
- 程序先把四个变量写进内存：整数 18、小数 1.75、字符 A、字符串 小明。
- printf 按顺序把 `%s` 换成名字、`%d` 换成年龄、`%.2f` 保留两位小数、`%c` 换成字母。
- 屏幕输出「小明 今年 18 岁，身高 1.75 米，评级 A」，然后换行。
- main 返回 0，进程正常结束。
''',
    pitfalls: '''
- 占位符和参数类型不匹配：把 double 交给 `%d` 会打印出完全无关的数字，这是未定义行为。
- scanf 忘记写 `&`：程序可能立刻崩溃，也可能悄悄读不到值，属于最典型的初学者事故。
- 字符和字符串引号混用：`'A'` 是字符，`"A"` 是字符串，传给 `%c` 时要保持一致。
- 数组开得太小：`char name[4]` 装不下中文名字，会越界写坏相邻内存。
- 用 `=` 做比较：`if (a = b)` 会先赋值再判断，应该写成 `==`。
''',
    drill: '''
- 把年龄改成自己的年龄，把身高改成两位小数，确认输出跟着变。
- 故意把 `%d` 写成 `%f`，运行看看打印出什么，理解类型和占位符必须匹配。
- 增加一个整数变量保存出生年份，并把它一起打印出来。
''',
  ),
  LanguageIntroDetail(
    id: 'c_conditions',
    sectionTitle: 'C 语言条件判断',
    codeLanguage: 'c',
    oneLiner:
        'if / else if / else 让程序按条件选择分支：条件为真执行对应代码块，'
        '一旦某个分支命中，后面的分支就不再检查。',
    analogy:
        '像高速公路的出口指示牌：看到第一个出口匹配就下高速，后面的指示牌再合理也跟你无关。'
        '如果所有出口都不匹配，才会走到 else 这条默认通道。',
    code: _cIfCode,
    lineWalk: '''
- `int score = 0;` 先给变量一个初始值，避免读到内存里的随机数据。
- `printf("请输入成绩：")` 打印提示，但故意不换行，让光标停在冒号后面等输入。
- `scanf("%d", &score)` 从键盘读一个整数写进 score；返回值是成功读到的个数，正式程序应该检查它是否等于 1。
- `if (score >= 90)` 括号里是条件表达式，结果为非 0 视为真，为 0 视为假。
- `else if (score >= 60)` 只有前面条件不成立时才轮到它，所以顺序决定了结果。
- `else` 不写条件，负责兜住所有剩下的情况。
''',
    runThrough: '''
- 输入 95：第一个条件成立，输出「优秀」，后面的分支全部跳过。
- 输入 72：第一个条件不成立、第二个成立，输出「及格」。
- 输入 40：两个条件都不成立，走 else，输出「需要补考」。
- 三种情况下程序都会执行 `return 0;` 并正常退出。
''',
    pitfalls: '''
- 把 `==` 写成 `=`：`if (score = 90)` 永远为真，编译器可能只给一条警告。
- 条件顺序写反：把 `score >= 60` 放在最前面，90 分也会被判成「及格」。
- 在 if 后面多写一个分号：`if (x > 0);` 让 if 管住一条空语句，后面的代码无条件执行。
- 忘记花括号却在分支里写多行：只有第一行受 if 控制，其余代码总是执行。
- scanf 不检查返回值：用户输入字母时 score 保持旧值，判断结果会莫名其妙。
''',
    drill: '''
- 输入 90 和 89，确认边界值归属，理解 `>=` 和 `>` 的差别。
- 交换前两个判断的顺序，输入 95，解释结果为什么变错。
- 增加一条「输入非法字符时提示重新输入」的处理，先用 scanf 的返回值做判断。
''',
  ),
  LanguageIntroDetail(
    id: 'c_loops',
    sectionTitle: 'C 语言循环',
    codeLanguage: 'c',
    oneLiner:
        'for 把初始化、条件、更新写在括号里，适合次数明确的场景；'
        'while 只检查条件，适合「不知道要做几次，但知道什么时候停」的场景。',
    analogy:
        'for 像跑步机上的定时模式：设定跑 5 分钟，时间到自动停。'
        'while 像手动跑步：只要你还按着开始键它就转，停了要自己按停，忘了按就一直转下去。',
    code: _cLoopCode,
    lineWalk: '''
- `int total = 0;` 准备累加器，初始为 0。
- `for (int i = 1; i <= 5; i++)` 分成三段：只在开始执行一次的初始化、每轮开始前检查的条件、每轮结束后的自增。
- `total += i;` 是 `total = total + i` 的简写，把当前数字累加进去。
- 循环体里的 printf 每轮执行一次，所以会看到五行输出。
- `while (total < 20)` 每轮开始前重新判断，条件不成立立即退出循环。
- 循环结束后的 printf 缩进在循环之外，只在最后输出一次。
''',
    runThrough: '''
- for 循环五轮结束后 total 是 15（1+2+3+4+5），屏幕按轮次输出五次累计值。
- 进入 while：15 小于 20，加 5 变成 20。
- 再次检查条件，20 不小于 20，循环结束，一次都没多跑。
- 最后输出「最终结果：20」；如果 while 里忘了改 total，条件永远为真，程序会卡死。
''',
    pitfalls: '''
- 条件写成 `i < 5` 却以为会到 5：终点必须写成 `i <= 5` 或者从 0 开始算。
- 在 for 的括号后面加分号：循环体变成空语句，后面的代码只执行一次。
- 混用有符号和无符号整数做条件：`unsigned` 变量永远不小于 0，循环可能永远不结束。
- 在循环里修改循环变量：次数变得不可预测，调试时极难发现。
- 累加变量忘记初始化：total 会从内存里的随机值开始累加。
''',
    drill: '''
- 把循环改成累加到 10，先手算总和再验证输出。
- 在循环里加一条 `if (i == 3) break;`，解释为什么总和变了。
- 把 while 的增量改成 0，观察死循环现象后强制结束进程。
''',
  ),
  LanguageIntroDetail(
    id: 'c_functions_intro',
    sectionTitle: 'C 语言函数入门',
    codeLanguage: 'c',
    oneLiner:
        '函数把一段可复用的逻辑封起来，调用者只关心「传什么进去、拿什么回来」，'
        '不必知道内部怎么实现。',
    analogy:
        '函数像自动售货机：你投币、按键，它吐饮料。你不需要知道里面的机械结构，'
        '只要记住投什么、按什么、出什么，就能反复使用。',
    code: _cFuncCode,
    lineWalk: '''
- `int add(int a, int b)` 定义一个返回整数的函数，接受两个整型参数 a 和 b。
- 函数体里的 `return a + b;` 把计算结果交回给调用处，同时结束这次函数调用。
- `void print_result(int value)` 的返回类型是 void，表示它只做事、不返回值。
- `int sum = add(3, 4);` 调用 add，把实参 3 和 4 分别复制给形参 a 和 b，返回值 7 存入 sum。
- `print_result(sum)` 把 7 传进去打印；函数内部拿到的是一份副本，改动它不会影响外面的 sum。
- 函数必须在使用前声明或定义，否则编译器不知道该函数存在。
''',
    runThrough: '''
- 程序从 main 开始，先执行 `add(3, 4)`，控制权跳到 add 函数内部。
- a 和 b 临时得到值 3 和 4，计算出 7 并返回，这两个参数随函数结束自动销毁。
- 7 被赋给 sum，再传给 print_result，屏幕输出「结果是 7」。
- 第二次调用直接把 `add(10, 20)` 的结果交给 print_result，输出「结果是 30」。
''',
    pitfalls: '''
- 参数写错类型或个数：C 会做隐式转换，可能悄悄丢失精度而不报错。
- 声明了返回类型却没有 return：调用者拿到的是无意义的随机值。
- 以为函数能直接改外部的局部变量：C 的参数按值传递，要改必须传指针。
- 函数定义放在 main 之后却不写声明：编译器在调用处看不到它，报隐式声明错误。
- 返回局部数组的地址：函数一结束这块内存就失效，属于典型的悬空指针。
''',
    drill: '''
- 增加一个 `int multiply(int a, int b)`，先猜结果再调用验证。
- 写一个没有返回值的函数，打印一行固定文字，观察 void 的用法。
- 把 `add(3, 4)` 的参数改成 `add(3.9, 4.1)`，解释为什么结果不是你预期的 8。
''',
  ),
];
