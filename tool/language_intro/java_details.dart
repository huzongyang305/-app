// Java 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _javaFirstCode = r'''public class Main {
    public static void main(String[] args) {
        System.out.println("你好，Java");
    }
}''';

const String _javaVarCode = r'''public class Main {
    public static void main(String[] args) {
        String name = "小明";
        int age = 18;
        double height = 1.75;
        boolean beginner = true;

        System.out.println(name + " 今年 " + age + " 岁");
        System.out.println("身高 " + height + " 米，是初学者：" + beginner);
    }
}''';

const String _javaIfCode = r'''public class Main {
    public static void main(String[] args) {
        int score = 72;

        if (score >= 90) {
            System.out.println("优秀");
        } else if (score >= 60) {
            System.out.println("及格");
        } else {
            System.out.println("需要补考");
        }
    }
}''';

const String _javaLoopCode = r'''public class Main {
    public static void main(String[] args) {
        int total = 0;

        for (int i = 1; i <= 5; i++) {
            total += i;
            System.out.println("加入 " + i + " 后累计 " + total);
        }

        while (total < 20) {
            total += 5;
        }

        System.out.println("最终结果：" + total);
    }
}''';

const String _javaMethodCode = r'''public class Main {
    static int add(int a, int b) {
        return a + b;
    }

    static void printResult(int value) {
        System.out.println("结果是 " + value);
    }

    public static void main(String[] args) {
        printResult(add(3, 4));
        printResult(add(10, 20));
    }
}''';

const List<LanguageIntroDetail> javaIntroDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'java_first_class',
    sectionTitle: 'Java 第一个类',
    codeLanguage: 'java',
    oneLiner:
        'Java 程序由类组织，main 方法是程序入口；'
        '类名 Main 必须和文件名 Main.java 完全一致。',
    analogy:
        '把类想成一个抽屉，方法就是抽屉里的工具。'
        'main 是抽屉上唯一被贴了「启动」标签的工具，运行程序就是拉开这个抽屉、按一下启动键。',
    code: _javaFirstCode,
    lineWalk: '''
- `public class Main` 定义一个公开的类，类名首字母大写；文件名必须是 `Main.java`，否则编译直接失败。
- `public static void main(String[] args)` 是 Java 规定的入口方法签名，少一个关键字 JVM 都找不到入口。
- `public` 表示任何地方都能访问，`static` 表示不用先创建对象就能调用，`void` 表示不返回值。
- `String[] args` 接收命令行参数，不传参数时它是空数组，但必须写在签名里。
- `System.out.println(...)` 把括号里的内容输出到标准输出并换行；`System` 是类，`out` 是它的静态字段，`println` 是方法。
- 每条语句结尾的分号不能省，这是 Java 和 Python 最明显的区别之一。
''',
    runThrough: '''
- 编译：`javac Main.java`，成功后同目录生成 `Main.class` 字节码文件。
- 运行：`java Main`，注意这里写的是类名，不加 `.class` 后缀。
- JVM 加载 Main 类，找到 main 方法并执行。
- 屏幕输出「你好，Java」并换行，程序结束。
''',
    pitfalls: '''
- 文件名和类名不一致：`Main` 类存成 `main.java`，javac 会报「类名与文件名不符」。
- 写成 `public static void main()`：参数列表不能省略，否则 JVM 找不到入口。
- 把 `main` 拼成 `Main` 或 `mian`：Java 区分大小写，方法名必须是全小写 main。
- 运行时报 `NoClassDefFoundError`：通常是 javac 编译失败后仍去运行，或者当前目录不对。
- 把 `println` 写成 `printIn`：字母 l 和 I 长得像，编译器会提示找不到符号。
''',
    drill: '''
- 把输出文字改成自己的名字，重新编译运行，观察必须重新 javac 才能生效。
- 加一条 `System.out.println` 输出第二行，注意分号。
- 故意把类名改成 Demo 而不改文件名，记录完整报错。
''',
  ),
  LanguageIntroDetail(
    id: 'java_variables_output',
    sectionTitle: 'Java 变量与输出',
    codeLanguage: 'java',
    oneLiner:
        'Java 是静态类型语言，变量必须先声明类型再使用；'
        '基本类型存值，String 是引用类型，但拼接和输出用起来很自然。',
    analogy:
        '声明类型像给盒子贴标签：贴了 int 就只能放整数，贴了 String 就只能放文字。'
        '贴错标签编译器当场拦下，不会等到运行才发现。',
    code: _javaVarCode,
    lineWalk: '''
- `String name = "小明";` 声明一个字符串变量，Java 的字符串用双引号，单个字符才用单引号。
- `int age = 18;` 用 32 位整数保存年龄；常用基本类型还有 long、short、byte。
- `double height = 1.75;` 保存小数；写 `1.75f` 才是 float，不写后缀的浮点字面量默认是 double。
- `boolean beginner = true;` 只有 true 和 false 两个取值，不能像 C 那样用 0 和 1 代替。
- `+` 既能做加法又能拼接字符串：只要有一边是字符串，另一边就会被转成文字拼上去。
- 输出时 `name + " 今年 " + age` 从左到右依次拼接，最后交给 println。
''',
    runThrough: '''
- 四个变量依次写入内存，类型各不相同。
- 第一行输出把字符串、整数和文字拼成一句完整的话。
- 第二行把 double 和 boolean 也转成文字拼接，输出「身高 1.75 米，是初学者：true」。
- 程序结束；如果把 `1.75` 换成 `"1.75"`，输出看起来一样，但类型已经变成字符串，不能再参与算术。
''',
    pitfalls: '''
- 想用 `int` 装小数：`int price = 9.9;` 编译不过，要换成 double。
- 字符串比较用 `==`：`name == "小明"` 比较的是引用地址，应该用 `name.equals("小明")`。
- 整数相除得到整数：`5 / 2` 的结果是 2 而不是 2.5，要写 `5 / 2.0`。
- 变量未初始化就使用：局部变量不会自动给默认值，编译器直接报「可能尚未初始化」。
- 超过 int 范围：`int` 最大约 21 亿，再大的数要用 long 并在字面量后加 L。
''',
    drill: '''
- 增加一个 `char initial = 'M';` 并打印出来，注意用单引号。
- 计算 `5 / 2` 和 `5 / 2.0` 并输出，解释两者为什么不同。
- 把某一行末尾的分号删掉，观察编译错误指向哪一行。
''',
  ),
  LanguageIntroDetail(
    id: 'java_conditions',
    sectionTitle: 'Java 条件判断',
    codeLanguage: 'java',
    oneLiner:
        'if / else if / else 按顺序判断条件，Java 的条件必须是 boolean 类型，'
        '不能像 C 那样用整数代替真假。',
    analogy:
        '像分拣包裹：先看是不是加急件，再看是不是同城件，都不符合才走普通通道。'
        '分拣员一次只走一条通道，不会回头重分。',
    code: _javaIfCode,
    lineWalk: '''
- `int score = 72;` 声明并初始化，Java 的局部变量必须显式赋值才能使用。
- `if (score >= 90)` 括号里必须是布尔表达式，比较运算的结果天然就是 boolean。
- `else if (score >= 60)` 只在前一个条件为 false 时才求值。
- `else` 不需要条件，兜住所有剩下的分支。
- 每个分支都用花括号包住，即使只有一行也建议保留，后续加代码时不容易出错。
- Java 还提供 switch 表达式和三目运算符，适合更简单的分支。
''',
    runThrough: '''
- score 为 72：第一个条件 false，第二个条件 true，输出「及格」。
- 如果把 score 改成 95，第一个条件成立，输出「优秀」，第二个分支不再计算。
- 改成 40 时两个条件都 false，走 else 输出「需要补考」。
- 三种情况程序都正常结束，没有任何返回值需要处理。
''',
    pitfalls: '''
- 用 `if (score)` 代替比较：Java 不接受整数当条件，编译直接报错。
- 把 `==` 写成 `=`：`if (score = 90)` 也是编译错误，因为赋值表达式的类型是 int 不是 boolean，这一点比 C 安全。
- 分支顺序不合理：先判断低档会让高档永远进不去。
- 漏写花括号又加第二行：第二行跑到了分支外面，逻辑和预期不同。
- 浮点数比较用 `==`：二进制表示无法精确表示 0.1，应比较差值的绝对值。
''',
    drill: '''
- 用 90、89、60、59 四个值测试，确认每条分支的边界。
- 把前两个分支调换顺序，用 95 验证结果变错。
- 用三目运算符重写最简单的一档判断，比较可读性。
''',
  ),
  LanguageIntroDetail(
    id: 'java_loops',
    sectionTitle: 'Java 循环',
    codeLanguage: 'java',
    oneLiner:
        'Java 的 for 和 while 与 C 家族语法一致，'
        '增强 for 循环可以直接遍历数组和集合，不用自己管理下标。',
    analogy:
        '普通 for 像按座位号找座位：你知道第几排第几号。'
        '增强 for 像工作人员依次把每个人手里的票收走：不用管编号，把每个元素都过一遍就行。',
    code: _javaLoopCode,
    lineWalk: '''
- `int total = 0;` 初始化累加器。
- `for (int i = 1; i <= 5; i++)` 中 i 只在循环内可见，出了循环就不能再用。
- `total += i;` 把当前数字累加进 total。
- 循环体里的 println 每轮执行，输出五行累计过程。
- `while (total < 20)` 每轮开头重新检查条件，条件为 false 时立刻退出。
- 循环外的 println 只执行一次，输出最终值。
''',
    runThrough: '''
- for 结束后 total 是 15。
- while 第一轮把 15 加到 20，再检查条件不成立，循环结束。
- 输出「最终结果：20」。
- 如果 while 里忘了修改 total，循环永远不会退出，只能手动终止进程。
''',
    pitfalls: '''
- 循环变量在循环外使用：`i` 的作用域只在 for 里，出了循环就报「找不到符号」。
- 条件里用 `i <= array.length`：数组下标从 0 到 length-1，写成 <= 会越界。
- 增强 for 里想修改原数组元素：遍历变量只是副本，改它不会写回数组。
- 在循环里做字符串拼接：每轮都新建对象，量大时应改用 StringBuilder。
- 死循环没有退出条件：正式代码里要有 break 或明确的终止判断。
''',
    drill: '''
- 用增强 for 遍历数组 `{1, 2, 3, 4, 5}` 并累加，比较和普通 for 的写法差异。
- 加入 `if (i == 3) continue;`，解释总和为何少 3。
- 把 while 的增量改成 0，复现死循环并说明如何中止。
''',
  ),
  LanguageIntroDetail(
    id: 'java_methods_intro',
    sectionTitle: 'Java 方法入门',
    codeLanguage: 'java',
    oneLiner:
        '方法把一段逻辑封装起来，通过参数接收数据、通过返回值交出结果；'
        'static 方法属于类本身，可以直接在 main 里调用。',
    analogy:
        '方法像公司里的标准流程单：填好输入交给它，它按流程处理，最后把结果交回来。'
        '谁调用都一样，流程本身只维护一份。',
    code: _javaMethodCode,
    lineWalk: '''
- `static int add(int a, int b)` 定义静态方法，返回 int，接收两个 int 参数。
- `return a + b;` 计算并结束方法，同时把结果返回给调用者。
- `static void printResult(int value)` 返回类型是 void，只负责输出。
- 两个方法都写在类里面、main 外面；Java 不允许方法嵌套定义。
- 在 main 里调用 `add(3, 4)`，实参按顺序复制给形参 a 和 b。
- Java 的参数传递永远是值传递：传基本类型复制值，传对象复制引用地址。
''',
    runThrough: '''
- `add(3, 4)` 进入方法体算得 7，返回后作为实参传给 printResult。
- printResult 输出「结果是 7」，方法结束返回到 main。
- 第二次调用 `add(10, 20)` 得到 30，输出「结果是 30」。
- main 执行完，JVM 正常退出。
''',
    pitfalls: '''
- 把方法写在 main 里面：Java 不支持嵌套方法，编译直接报错。
- 非 static 方法直接在 main 里调用：需要先创建对象，否则报「非静态方法不能在静态上下文中引用」。
- 方法签名写好后忘记 return：有返回类型的方法必须保证所有路径都有返回语句。
- 以为方法能改基本类型参数：传进去的是副本，改副本不影响调用方。
- 方法重载只看返回类型：重载必须参数列表不同，只改返回类型算重复定义。
''',
    drill: '''
- 增加一个 `static int multiply(int a, int b)` 并调用打印。
- 写一个带 String 参数的方法，输出问候语。
- 把 add 的返回类型改成 void，观察编译器在调用处报什么错。
''',
  ),
];
