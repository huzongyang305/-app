// C# 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _csFirstCode = r'''using System;

class Program
{
    static void Main()
    {
        Console.WriteLine("你好，C#");
    }
}''';

const String _csVarCode = r'''using System;

class Program
{
    static void Main()
    {
        Console.Write("请输入名字：");
        string name = Console.ReadLine() ?? "匿名";

        Console.Write("请输入年龄：");
        string input = Console.ReadLine() ?? "0";
        int age = int.Parse(input);

        Console.WriteLine($"{name} 明年 {age + 1} 岁");
    }
}''';

const String _csIfCode = r'''using System;

class Program
{
    static void Main()
    {
        int score = 72;

        if (score >= 90)
        {
            Console.WriteLine("优秀");
        }
        else if (score >= 60)
        {
            Console.WriteLine("及格");
        }
        else
        {
            Console.WriteLine("需要补考");
        }
    }
}''';

const String _csLoopCode = r'''using System;

class Program
{
    static void Main()
    {
        int total = 0;

        for (int i = 1; i <= 5; i++)
        {
            total += i;
            Console.WriteLine($"加入 {i} 后累计 {total}");
        }

        while (total < 20)
        {
            total += 5;
        }

        Console.WriteLine($"最终结果：{total}");
    }
}''';

const String _csMethodCode = r'''using System;

class Program
{
    static int Add(int a, int b)
    {
        return a + b;
    }

    static void PrintResult(int value)
    {
        Console.WriteLine($"结果是 {value}");
    }

    static void Main()
    {
        PrintResult(Add(3, 4));
        PrintResult(Add(10, 20));
    }
}''';

const List<LanguageIntroDetail> csharpIntroDetails = <LanguageIntroDetail>[
  ..._csFirstDetails,
  ..._csVarDetails,
  ..._csIfDetails,
  ..._csLoopDetails,
  ..._csMethodDetails,
];

const List<LanguageIntroDetail> _csFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'csharp_dotnet_first',
    sectionTitle: 'C# 第一个程序',
    codeLanguage: 'csharp',
    oneLiner:
        'C# 程序由类组织，Main 方法是入口，Console.WriteLine 把内容打印到控制台；'
        '它运行在 .NET 之上，需要先安装 SDK。',
    analogy:
        '把 .NET 想成舞台、C# 代码想成剧本、Main 想成开幕的那一页。'
        '观众（操作系统）只认开幕页，所以程序永远从 Main 开始演。',
    code: _csFirstCode,
    lineWalk: '''
- `using System;` 引入命名空间，Console 类就在 System 里，不引入就得每次都写完整名字。
- `class Program` 定义一个类，C# 的代码必须写在类型里面，不能像脚本那样随便晾着。
- `static void Main()` 是程序入口，返回 void 表示不返回退出码。
- `Console.WriteLine` 输出内容并换行；只想输出不换行时用 Console.Write。
- C# 的语句以分号结尾，代码块用花括号包围，这两点和 Java 一致。
''',
    runThrough: '''
- 用 `dotnet new console` 新建项目，或用 `csc Program.cs` 直接编译。
- 运行 `dotnet run`，.NET 运行时加载程序集并找到 Main。
- 执行 WriteLine，屏幕输出「你好，C#」并换行。
- Main 返回，进程退出码为 0。
''',
    pitfalls: '''
- 类名和文件名不一致：C# 不强制要求一致，但团队约定保持一致，便于查找。
- 把 Main 写成小写 main：C# 区分大小写，运行时找不到入口会报编译错误。
- 忘记 using System：Console 无法解析，报找不到类型或命名空间。
- 安装了运行时却编译不了：开发需要 .NET SDK，只有 Runtime 是不够的。
- 混用中文全角括号和分号：编译器报的错往往指向下一行，实际错误在上一行。
''',
    drill: '''
- 把输出文字换成自己的名字，重新运行。
- 用 Console.Write 输出一行不换行的内容，再对比 WriteLine。
- 故意把 Main 改成 main，记录编译器的报错。
''',
  ),
];

const List<LanguageIntroDetail> _csVarDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'csharp_variables_input',
    sectionTitle: 'C# 变量与输入',
    codeLanguage: 'csharp',
    oneLiner:
        'C# 是强类型语言，变量先声明类型再使用；'
        'Console.ReadLine 返回字符串，要参与计算必须先转换。',
    analogy:
        'Console.ReadLine 像前台登记：它递给你的永远是一张写着字的纸条，'
        '想当数字用，得自己把纸条上的内容换算成数值。',
    code: _csVarCode,
    lineWalk: '''
- `Console.Write("请输入名字：")` 输出提示但不换行，光标停在冒号后面等输入。
- Console.ReadLine 读取一行；输入流结束时返回 null，双问号提供兜底值。
- `int.Parse(input)` 把字符串转成整数；输入不是合法数字时抛 FormatException。
- 插值字符串以美元符号开头，花括号里可以写任意表达式。
- 更安全的转换用 int.TryParse，它返回布尔值表示是否成功，不会抛异常。
''',
    runThrough: '''
- 输入「小明」后回车，name 得到「小明」。
- 输入「18」后回车，input 是字符串「18」。
- int.Parse 把它变成整数 18，加 1 得到 19。
- 插值字符串输出「小明 明年 19 岁」；如果输入 abc，Parse 会抛出异常并中断程序。
''',
    pitfalls: '''
- 直接对 ReadLine 的结果做算术：它是字符串，编译器直接报错。
- 用 int.Parse 处理用户输入：非法输入立刻抛异常，正式代码应改用 TryParse。
- 忘记兜底：重定向输入时 ReadLine 返回 null，后续操作抛 NullReferenceException。
- 把 C# 的插值字符串和 Python 的 f-string 混淆：C# 用美元符号开头，Python 用 f 开头。
- 变量名用了关键字：变量名不能叫 int、class、static 这些保留字。
''',
    drill: '''
- 把年龄换成身高，用 double.Parse 并保留一位小数。
- 用 int.TryParse 改写输入处理，输入字母时给出提示而不是崩溃。
- 增加一行输出，把名字和年龄拼成一句自我介绍。
''',
  ),
];

const List<LanguageIntroDetail> _csIfDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'csharp_conditions',
    sectionTitle: 'C# 条件判断',
    codeLanguage: 'csharp',
    oneLiner:
        'if / else if / else 按顺序求值，第一个成立的代码块执行，其余跳过；'
        'C# 的条件必须是 bool 类型。',
    analogy:
        '像电梯分层停靠：先判断你要去的楼层是否在当前方向，符合就停，'
        '不符合就继续往上或往下，不会回头再停一次。',
    code: _csIfCode,
    lineWalk: '''
- `int score = 72;` 声明整数变量，C# 的局部变量必须先赋值才能读取。
- `if (score >= 90)` 括号里必须是布尔表达式，比较运算的结果天然满足。
- `else if` 只在前一个条件为 false 时求值，所以顺序决定优先级。
- `else` 不需要条件，负责兜底。
- C# 推荐把花括号单独成行，这是官方代码风格的常见写法。
- 从 C# 8 开始可以使用 switch 表达式，让多分支判断写得更紧凑。
''',
    runThrough: '''
- score 为 72：第一个条件 false，第二个 true，输出「及格」。
- 改成 95：第一个条件成立，输出「优秀」，第二个分支不再求值。
- 改成 40：两个条件都 false，走 else 输出「需要补考」。
- 三种情况下程序都正常退出，退出码为 0。
''',
    pitfalls: '''
- 用整数当条件：`if (score)` 在 C# 里编译不过，必须写明确的比较。
- 把 `==` 写成 `=`：C# 会报错，因为赋值表达式的类型是 int 而不是 bool，这点比 C 安全。
- 分支顺序不合理：高档判断写到低档之后，永远进不去。
- 浮点数直接用 `==` 比较：二进制无法精确表示 0.1，应比较差值是否小于容差。
- 在 if 后面多写一个分号：分支体变成空语句，后面的代码无条件执行。
''',
    drill: '''
- 用 90、89、60、59 四个值测试边界。
- 交换前两个分支顺序，用 95 复现错误结果。
- 用 switch 表达式重写这段判断，比较两种写法的可读性。
''',
  ),
];

const List<LanguageIntroDetail> _csLoopDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'csharp_loops',
    sectionTitle: 'C# 循环',
    codeLanguage: 'csharp',
    oneLiner:
        'for 适合次数确定的循环，while 适合由条件决定何时结束的循环，'
        'foreach 用来直接遍历集合中的每个元素。',
    analogy:
        'for 像按编号点名，foreach 像挨个把名单上的人叫到，while 像「只要还有人没到就继续等」。'
        '三种方式解决的是同一个问题，只是你掌握的信息不同。',
    code: _csLoopCode,
    lineWalk: '''
- `int total = 0;` 初始化累加器。
- `for (int i = 1; i <= 5; i++)` 的三段分别是初始化、条件和自增。
- `total += i;` 把当前数字累加进 total。
- 循环体里的插值字符串每轮输出一次，所以看到五行。
- `while (total < 20)` 每轮开头重新判断条件。
- 循环外的输出只执行一次，给出最终结果。
''',
    runThrough: '''
- for 结束后 total 是 15。
- while 第一轮把 15 加到 20，再判断条件不成立，退出循环。
- 输出「最终结果：20」。
- 如果 while 里忘了修改 total，循环不会结束，只能手动终止进程。
''',
    pitfalls: '''
- 用 `i <= 数组长度` 遍历数组：C# 数组下标从 0 到 length-1，会抛 IndexOutOfRangeException。
- 在 foreach 里修改集合：遍历期间修改会抛 InvalidOperationException。
- 把 foreach 的迭代变量当成引用：它是只读副本，改它不会影响集合元素。
- 循环里频繁拼接字符串：应改用 StringBuilder，避免大量临时对象。
- 死循环没有退出路径：正式代码需要 break 或明确的终止条件。
''',
    drill: '''
- 用 foreach 遍历数组并累加，比较和 for 的写法差异。
- 在循环里加 `if (i == 3) continue;`，解释总和为何变化。
- 把 while 的增量改成 0，复现死循环并说明如何中止。
''',
  ),
];

const List<LanguageIntroDetail> _csMethodDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'csharp_methods_intro',
    sectionTitle: 'C# 方法入门',
    codeLanguage: 'csharp',
    oneLiner:
        '方法把逻辑封装在类里面，通过参数接收数据、通过返回值交出结果；'
        'C# 的方法名习惯用大驼峰命名。',
    analogy:
        '方法像公司里的标准工序：输入原料、按流程加工、交出成品。'
        '工序只维护一份，谁需要就调用一次，不必重复写。',
    code: _csMethodCode,
    lineWalk: '''
- `static int Add(int a, int b)` 定义静态方法，返回 int，接收两个 int 参数。
- `return a + b;` 计算并结束方法，把结果交给调用者。
- `static void PrintResult(int value)` 返回类型是 void，只负责输出。
- 方法必须写在类里面，Main 也是类的一个方法。
- 在 Main 中调用 `Add(3, 4)`，实参按顺序复制给形参。
- C# 的参数默认按值传递，用 ref 或 out 才能把修改带回调用方。
''',
    runThrough: '''
- `Add(3, 4)` 进入方法体算出 7 并返回。
- 7 作为实参传给 PrintResult，输出「结果是 7」。
- 第二次调用 `Add(10, 20)` 得到 30，输出「结果是 30」。
- Main 执行完，进程正常退出。
''',
    pitfalls: '''
- 方法名用小写开头：C# 不强制，但大驼峰是官方命名规范，评审时会被指出。
- 非静态方法直接在 Main 里调用：需要先创建实例，否则编译报错。
- 有返回值的方法漏掉 return：编译器会直接报错，所有路径都必须有返回。
- 以为按值传递能改基本类型参数：需要改就用 ref 或 out。
- 只改返回类型做重载：重载必须参数列表不同，只改返回类型算重复定义。
''',
    drill: '''
- 增加一个 `static int Multiply(int a, int b)` 并调用打印。
- 写一个带 string 参数的方法，输出问候语。
- 把 Add 的返回类型改成 void，观察调用处的编译错误。
''',
  ),
];
