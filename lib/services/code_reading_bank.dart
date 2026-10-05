import '../models/lesson.dart';

/// 代码阅读题库：为「有代码块但没有代码题」的课程补一道代码理解题。
///
/// 每题只存「语言 + 槽位」到 manifest（`code_quiz` 字段），题干、代码与
/// 选项在运行时由本文件生成，因此：
/// · manifest 体积几乎不增加；
/// · 题库可以随版本升级，老课程立即获得新题；
/// · 每道题的代码都是该语言里可直接验证的最小示例，答案唯一且可判定。
///
/// [pattern] 供开发工具在课程 Markdown 中挑选最贴近本课代码的槽位。
class CodeReadingEntry {
  const CodeReadingEntry(
    this.slot,
    this.pattern,
    this.code,
    this.answer,
    this.explanation,
  );

  /// 槽位名，写入 manifest 的 `code_quiz.slot`。
  final String slot;

  /// 开发工具用来匹配课程代码块的正则（运行时不用）。
  final String pattern;

  /// 展示给用户的示例代码。
  final String code;

  /// 正确选项文案。
  final String answer;

  /// 解析：说明语法点为什么正确。
  final String explanation;
}

/// 围栏语言名 → 界面展示名。
const Map<String, String> codeLanguageLabels = <String, String>{
  'python': 'Python',
  'javascript': 'JavaScript',
  'js': 'JavaScript',
  'typescript': 'TypeScript',
  'ts': 'TypeScript',
  'java': 'Java',
  'c': 'C',
  'cpp': 'C++',
  'csharp': 'C#',
  'go': 'Go',
  'rust': 'Rust',
  'kotlin': 'Kotlin',
  'swift': 'Swift',
  'dart': 'Dart',
  'bash': 'Shell',
  'shell': 'Shell',
  'sql': 'SQL',
  'html': 'HTML',
  'css': 'CSS',
  'json': 'JSON',
  'yaml': 'YAML',
  'xml': 'XML',
  'http': 'HTTP',
  'dockerfile': 'Dockerfile',
};

/// 语言 → 槽位列表。
const Map<String, List<CodeReadingEntry>>
codeReadingBank = <String, List<CodeReadingEntry>>{
  'python': <CodeReadingEntry>[
    CodeReadingEntry(
      'def',
      r'^\s*def\s+\w+',
      'def add(a, b):\n    return a + b\n\nprint(add(2, 3))',
      '定义一个函数并调用它输出结果',
      'def 用来定义函数，调用时把实参传给形参并返回结果。',
    ),
    CodeReadingEntry(
      'class',
      r'^\s*class\s+\w+',
      'class Point:\n    def __init__(self, x):\n        self.x = x\n\np = Point(3)\nprint(p.x)',
      '定义一个类，创建实例并访问属性',
      '__init__ 是实例初始化方法，Point(3) 创建对象后可以通过 p.x 访问属性。',
    ),
    CodeReadingEntry(
      'for',
      r'^\s*for\s+.+\s+in\s+',
      'for i in range(3):\n    print(i)',
      '使用 for 循环重复执行代码块',
      'range(3) 依次产生 0、1、2，循环体对每个值各执行一次。',
    ),
    CodeReadingEntry(
      'while',
      r'^\s*while\s+',
      'n = 3\nwhile n > 0:\n    n -= 1\nprint(n)',
      '使用 while 循环，条件不满足时退出',
      '每轮循环都会重新判断 n > 0，n 递减到 0 后循环结束并打印 0。',
    ),
    CodeReadingEntry(
      'if',
      r'^\s*if\s+.*:\s*$',
      'score = 75\nif score >= 60:\n    print("pass")\nelse:\n    print("fail")',
      '根据条件分支选择不同的代码路径',
      'if/else 只会执行其中一个分支；这里 75 >= 60，因此输出 pass。',
    ),
    CodeReadingEntry(
      'import',
      r'^\s*(import|from)\s+\w+',
      'import math\nprint(math.sqrt(16))',
      '导入模块并使用其中的函数',
      'import 把模块引入当前命名空间，之后用 math.sqrt 调用模块内的函数。',
    ),
    CodeReadingEntry(
      'try',
      r'^\s*try\s*:',
      'try:\n    value = int("12")\nexcept ValueError:\n    value = 0\nprint(value)',
      '用 try/except 捕获并处理异常',
      'try 中的代码一旦抛出 ValueError，就转到 except 分支兜底，程序不会直接崩溃。',
    ),
    CodeReadingEntry(
      'with',
      r'\bwith\s+open\(',
      'with open("data.txt", encoding="utf-8") as f:\n    print(f.read())',
      '用 with 打开文件并在语句结束时自动关闭',
      'with 是上下文管理器语法，离开代码块时会自动调用 close，避免文件句柄泄漏。',
    ),
    CodeReadingEntry(
      'listcomp',
      r'\[[^\]]*\bfor\b[^\]]*\]',
      'numbers = [1, 2, 3]\nsquares = [n * n for n in numbers]\nprint(squares)',
      '用列表推导式生成新的列表',
      '列表推导式在一行里完成遍历与表达式求值，输出 [1, 4, 9]。',
    ),
    CodeReadingEntry(
      'lambda',
      r'\blambda\b',
      'double = lambda x: x * 2\nprint(double(4))',
      '定义一个匿名函数并调用它',
      'lambda 产生没有名字的函数对象，赋给变量后可以像普通函数一样调用。',
    ),
  ],
  'javascript': <CodeReadingEntry>[
    CodeReadingEntry(
      'declare',
      r'\b(const|let)\s+\w+',
      'const name = "Ada";\nlet count = 3;\nconsole.log(name, count);',
      '用 const/let 声明变量并输出',
      'const 声明的绑定不能重新赋值，let 声明的变量可以修改；console.log 打印到控制台。',
    ),
    CodeReadingEntry(
      'arrow',
      r'=>\s*',
      'const double = (n) => n * 2;\nconsole.log(double(4));',
      '用箭头函数定义函数',
      '箭头函数把参数与函数体用 => 连接，适合作为回调或短小的工具函数。',
    ),
    CodeReadingEntry(
      'await',
      r'\bawait\b',
      'async function load() {\n  const res = await fetch("/api");\n  return res.json();\n}',
      '用 async/await 等待异步操作完成',
      'await 会暂停当前 async 函数的执行，直到 Promise 完成，让异步代码读起来像同步代码。',
    ),
    CodeReadingEntry(
      'then',
      r'\.then\(',
      'fetch("/api")\n  .then((res) => res.json())\n  .then((data) => console.log(data));',
      '用 Promise 链依次处理异步结果',
      '每个 then 都返回新的 Promise，因此可以串联多步异步处理。',
    ),
    CodeReadingEntry(
      'trycatch',
      r'\btry\s*\{',
      'try {\n  JSON.parse(text);\n} catch (error) {\n  console.error(error);\n}',
      '用 try/catch 捕获运行时错误',
      'JSON.parse 遇到非法字符串会抛异常，catch 分支负责记录并恢复。',
    ),
    CodeReadingEntry(
      'dom',
      r'document\.querySelector',
      'const box = document.querySelector("#box");\nbox.textContent = "hello";',
      '查询 DOM 元素并修改它的文本内容',
      'querySelector 用 CSS 选择器找到元素，textContent 会替换元素内的文本。',
    ),
    CodeReadingEntry(
      'event',
      r'addEventListener',
      'button.addEventListener("click", () => {\n  console.log("clicked");\n});',
      '为元素绑定事件监听器',
      'addEventListener 在指定事件发生时执行回调，这里监听的是 click 事件。',
    ),
    CodeReadingEntry(
      'map',
      r'\.map\(',
      'const nums = [1, 2, 3];\nconst doubled = nums.map((n) => n * 2);\nconsole.log(doubled);',
      '用 map 遍历数组并生成新数组',
      'map 不会修改原数组，而是按回调的返回值生成等长的新数组。',
    ),
    CodeReadingEntry(
      'object',
      r'const\s+\w+\s*=\s*\{',
      'const user = { name: "Ada", age: 36 };\nconsole.log(user.name);',
      '定义对象并通过属性名读取数据',
      '对象用键值对组织数据，user.name 或 user["name"] 都能读取属性。',
    ),
  ],
  'typescript': <CodeReadingEntry>[
    CodeReadingEntry(
      'interface',
      r'\binterface\s+\w+',
      'interface User {\n  name: string;\n  age: number;\n}',
      '用 interface 描述对象的类型结构',
      'interface 只存在于编译期，用来约束对象必须包含哪些字段及其类型。',
    ),
    CodeReadingEntry(
      'generic',
      r'<\s*[A-Z]\w*\s*>',
      'function first<T>(items: T[]): T | undefined {\n  return items[0];\n}',
      '用泛型让函数适配多种元素类型',
      'T 是类型参数，调用 first<string>([...]) 时会替换成具体类型。',
    ),
    CodeReadingEntry(
      'union',
      r'\|\s*"',
      'type Result = "ok" | "error";\nconst value: Result = "ok";',
      '用联合类型限定变量允许的取值',
      '联合类型把多个候选类型合并，赋成列表之外的值会编译报错。',
    ),
    CodeReadingEntry(
      'annotate',
      r':\s*(string|number|boolean)\b',
      'let title: string = "hello";\nlet count: number = 3;',
      '给变量标注明确的类型',
      '类型标注写在变量名之后，让编译器在赋值和调用时做静态检查。',
    ),
    CodeReadingEntry(
      'optional',
      r'\?\s*:',
      'interface Config {\n  timeout?: number;\n}\nconst config: Config = {};',
      '用可选属性表示字段可以缺省',
      '? 表示该属性不是必填，缺省时它的类型是 number | undefined。',
    ),
    CodeReadingEntry(
      'enum',
      r'\benum\s+\w+',
      'enum Status {\n  Idle,\n  Running,\n}\nconst s: Status = Status.Idle;',
      '用枚举为一组命名常量建立类型',
      '枚举让状态取值集中定义，避免在代码里散落魔法数字。',
    ),
  ],
  'java': <CodeReadingEntry>[
    CodeReadingEntry(
      'main',
      r'public\s+static\s+void\s+main',
      'public class Main {\n    public static void main(String[] args) {\n        System.out.println("hello");\n    }\n}',
      '定义 Java 程序入口并打印输出',
      'main 方法是 JVM 的固定入口签名，System.out.println 输出一行文本。',
    ),
    CodeReadingEntry(
      'override',
      r'@Override',
      'class Dog extends Animal {\n    @Override\n    void speak() {\n        System.out.println("woof");\n    }\n}',
      '继承父类并重写它的方法',
      '@Override 让编译器检查方法签名确实覆盖了父类方法。',
    ),
    CodeReadingEntry(
      'trycatch',
      r'\btry\s*\{',
      'try {\n    int value = Integer.parseInt("12");\n} catch (NumberFormatException e) {\n    value = 0;\n}',
      '捕获并处理可能抛出的异常',
      '受检或运行时异常都可以用 try/catch 处理，避免异常沿调用栈向上传播。',
    ),
    CodeReadingEntry(
      'collection',
      r'new\s+ArrayList|List<',
      'List<String> names = new ArrayList<>();\nnames.add("Ada");\nfor (String name : names) {\n    System.out.println(name);\n}',
      '创建集合，添加元素并用增强 for 遍历',
      '增强 for（for-each）会依次取出集合中的每个元素，无需手写下标。',
    ),
    CodeReadingEntry(
      'stream',
      r'\.stream\(\)',
      'List<Integer> nums = List.of(1, 2, 3);\nnums.stream().filter(n -> n > 1).forEach(System.out::println);',
      '用 Stream 过滤集合并遍历结果',
      'filter 保留满足条件的元素，forEach 对每个结果执行动作，链式调用不修改原集合。',
    ),
    CodeReadingEntry(
      'thread',
      r'new\s+Thread',
      'Thread t = new Thread(() -> System.out.println("run"));\nt.start();',
      '创建线程并启动并发执行',
      'start() 会开启新线程执行 run 方法，直接调用 run() 只是普通方法调用。',
    ),
  ],
  'c': <CodeReadingEntry>[
    CodeReadingEntry(
      'include',
      r'#include',
      '#include <stdio.h>\n\nint main(void) {\n    printf("hi\\n");\n    return 0;\n}',
      '引入标准库头文件并定义主函数输出文本',
      '#include 把头文件内容引入编译单元，printf 声明来自 stdio.h。',
    ),
    CodeReadingEntry(
      'pointer',
      r'\*\s*\w+\s*=|\&\w+',
      'int value = 3;\nint *p = &value;\nprintf("%d", *p);',
      '用指针保存变量地址，并通过解引用读取值',
      '&value 取得地址，*p 解引用后读到的就是 value 的值。',
    ),
    CodeReadingEntry(
      'malloc',
      r'\bmalloc\s*\(',
      'int *data = malloc(3 * sizeof(int));\nif (data == NULL) return 1;\nfree(data);',
      '在堆上申请内存，并在用完后释放',
      'malloc 返回 void*，失败时为 NULL；free 必须与分配一一对应，否则会泄漏内存。',
    ),
    CodeReadingEntry(
      'struct',
      r'\bstruct\s+\w+\s*\{',
      'struct Point { int x; int y; };\nstruct Point p = {1, 2};',
      '定义结构体类型并初始化变量',
      '结构体把多个字段打包成一个类型，初始化列表按字段顺序赋值。',
    ),
    CodeReadingEntry(
      'array',
      r'\w+\s+\w+\[\d+\]\s*=',
      'int nums[3] = {1, 2, 3};\nfor (int i = 0; i < 3; i++) printf("%d", nums[i]);',
      '声明数组并用下标循环遍历元素',
      '数组下标从 0 开始，循环边界 i < 3 保证不会越界访问。',
    ),
    CodeReadingEntry(
      'string',
      r'char\s+\w+\[',
      'char name[8] = "Ada";\nprintf("%s", name);',
      '用字符数组保存以 \\0 结尾的字符串',
      'C 字符串以空字符结尾，数组长度至少要能容纳字符加上结尾的 \\0。',
    ),
  ],
  'cpp': <CodeReadingEntry>[
    CodeReadingEntry(
      'iostream',
      r'#include\s*<iostream>',
      '#include <iostream>\n\nint main() {\n    std::cout << "hi" << std::endl;\n    return 0;\n}',
      '引入 iostream 并用 std::cout 输出',
      '<< 是流插入运算符，把右侧内容送到输出流；std::endl 换行并刷新缓冲。',
    ),
    CodeReadingEntry(
      'vector',
      r'std::vector|vector<',
      'std::vector<int> nums{1, 2, 3};\nnums.push_back(4);\nfor (int n : nums) std::cout << n;',
      '使用 vector 动态数组并追加、遍历元素',
      'vector 会自动管理容量，push_back 在尾部追加，范围 for 依次访问元素。',
    ),
    CodeReadingEntry(
      'class',
      r'\bclass\s+\w+',
      'class Counter {\npublic:\n    explicit Counter(int start) : value_(start) {}\n    int value() const { return value_; }\n\nprivate:\n    int value_;\n};',
      '定义类，用构造函数初始化成员并提供访问方法',
      'explicit 阻止隐式转换，初始化列表 : value_(start) 在构造阶段直接初始化成员。',
    ),
    CodeReadingEntry(
      'move',
      r'std::move\(',
      'std::string a = "hello";\nstd::string b = std::move(a);',
      '用 std::move 把资源转移到另一个对象',
      'std::move 只是类型转换，真正的转移由移动构造函数完成；移动后不应再依赖原对象的值。',
    ),
    CodeReadingEntry(
      'smartptr',
      r'std::(unique_ptr|shared_ptr)',
      'auto p = std::make_unique<int>(42);\nstd::cout << *p;',
      '用智能指针自动管理堆对象生命周期',
      'unique_ptr 独占所有权，离开作用域自动 delete，避免手写 delete 造成泄漏。',
    ),
    CodeReadingEntry(
      'lambda',
      r'\[.*\]\s*\(',
      'auto add = [](int a, int b) { return a + b; };\nstd::cout << add(2, 3);',
      '定义 lambda 闭包并像函数一样调用',
      '方括号是捕获列表，圆括号是参数列表；capture 决定 lambda 能访问哪些外部变量。',
    ),
    CodeReadingEntry(
      'raii',
      r'\b(std::lock_guard|std::ifstream|std::ofstream)\b',
      'std::ifstream file("data.txt");\nstd::string line;\nwhile (std::getline(file, line)) {\n    std::cout << line;\n}',
      '用 RAII 对象管理资源，离开作用域自动释放',
      '文件流析构时会自动关闭文件，这就是 RAII：资源生命周期绑定到对象生命周期。',
    ),
  ],
  'csharp': <CodeReadingEntry>[
    CodeReadingEntry(
      'main',
      r'static\s+void\s+Main',
      'using System;\n\nclass Program {\n    static void Main() {\n        Console.WriteLine("hi");\n    }\n}',
      '定义程序入口并用 Console.WriteLine 输出',
      'Main 是 .NET 控制台程序的入口点，using 指令引入命名空间。',
    ),
    CodeReadingEntry(
      'property',
      r'\{\s*get;\s*set;\s*\}',
      'class User {\n    public string Name { get; set; } = "";\n}\nvar user = new User { Name = "Ada" };',
      '用自动属性封装字段并支持对象初始化器',
      '自动属性让编译器生成隐藏字段与取值/赋值方法，对象初始化器在创建时直接赋值。',
    ),
    CodeReadingEntry(
      'async',
      r'\basync\b',
      'async Task<string> LoadAsync() {\n    await Task.Delay(100);\n    return "done";\n}',
      '用 async/await 编写异步方法',
      'async 方法返回 Task，await 在等待期间释放线程而不是阻塞它。',
    ),
    CodeReadingEntry(
      'linq',
      r'\.Where\(|\.Select\(|from\s+\w+\s+in',
      'var nums = new[] { 1, 2, 3 };\nvar even = nums.Where(n => n % 2 == 0).ToList();',
      '用 LINQ 查询表达式筛选集合',
      'Where 保留满足条件的元素，ToList 把惰性查询物化成列表。',
    ),
    CodeReadingEntry(
      'using',
      r'\busing\s+var\b',
      'using var stream = File.OpenRead("data.bin");\nConsole.WriteLine(stream.Length);',
      '用 using 声明确保对象在作用域结束时释放',
      'using 声明会在作用域退出时自动调用 Dispose，等价于 try/finally 的简化写法。',
    ),
    CodeReadingEntry(
      'record',
      r'\brecord\s+\w+',
      'public record Point(int X, int Y);\nvar p = new Point(1, 2);',
      '用 record 定义不可变的值对象',
      'record 自动生成构造函数、属性、相等比较与 ToString，适合承载数据。',
    ),
  ],
  'go': <CodeReadingEntry>[
    CodeReadingEntry(
      'main',
      r'func\s+main\s*\(',
      'package main\n\nimport "fmt"\n\nfunc main() {\n    fmt.Println("hi")\n}',
      '定义 main 包与入口函数并输出文本',
      'package main 加 func main 构成可执行程序入口，fmt.Println 打印一行。',
    ),
    CodeReadingEntry(
      'shortvar',
      r':=',
      'name := "Ada"\ncount := 3\nfmt.Println(name, count)',
      '用 := 做短变量声明并自动推断类型',
      ':= 只能用在函数内部，它同时声明变量并根据右侧值推断类型。',
    ),
    CodeReadingEntry(
      'goroutine',
      r'go\s+func|go\s+\w+\(',
      'go func() {\n    fmt.Println("worker")\n}()',
      '用 go 关键字启动一个并发执行的 goroutine',
      'goroutine 由 Go 运行时调度，启动后主函数若立即结束，它可能来不及执行。',
    ),
    CodeReadingEntry(
      'channel',
      r'\bchan\b',
      'ch := make(chan int, 1)\nch <- 42\nfmt.Println(<-ch)',
      '用带缓冲通道在 goroutine 之间传递数据',
      'chan 是类型安全的通信管道，容量为 1 时发送一次不会阻塞。',
    ),
    CodeReadingEntry(
      'defer',
      r'\bdefer\s+',
      'f, _ := os.Open("data.txt")\ndefer f.Close()',
      '用 defer 把清理动作推迟到函数返回前执行',
      'defer 按后进先出顺序执行，常用来关闭文件、解锁与回收资源。',
    ),
    CodeReadingEntry(
      'error',
      r'if\s+err\s*!=\s*nil',
      'value, err := strconv.Atoi("12")\nif err != nil {\n    log.Fatal(err)\n}\nfmt.Println(value)',
      '显式检查并处理返回的错误值',
      'Go 用返回值传递错误而不是异常，调用方必须显式判断 err != nil。',
    ),
    CodeReadingEntry(
      'struct',
      r'type\s+\w+\s+struct\s*\{',
      'type User struct {\n    Name string\n}\n\nuser := User{Name: "Ada"}\nfmt.Println(user.Name)',
      '定义结构体类型并用字段名初始化',
      '结构体把相关字段组合成新类型，字段名初始化不依赖字段顺序。',
    ),
  ],
  'rust': <CodeReadingEntry>[
    CodeReadingEntry(
      'main',
      r'fn\s+main\s*\(',
      'fn main() {\n    println!("hi");\n}',
      '定义 main 函数并打印输出',
      'fn 定义函数，main 是可执行程序的入口，println! 是格式化输出宏。',
    ),
    CodeReadingEntry(
      'mut',
      r'let\s+mut\s+',
      'let mut count = 0;\ncount += 1;\nprintln!("{count}");',
      '用 let mut 声明可变绑定',
      'Rust 变量默认不可变，加 mut 之后才允许重新赋值。',
    ),
    CodeReadingEntry(
      'match',
      r'\bmatch\s+',
      'let value = Some(3);\nmatch value {\n    Some(n) => println!("{n}"),\n    None => println!("none"),\n}',
      '用 match 对枚举做穷尽模式匹配',
      'match 会检查所有分支是否覆盖完整，Option 的 Some 与 None 都必须处理。',
    ),
    CodeReadingEntry(
      'result',
      r'\b(Result|Option)<',
      'fn parse(text: &str) -> Result<i32, std::num::ParseIntError> {\n    text.parse::<i32>()\n}',
      '用 Result 表示可能失败并携带错误信息的返回值',
      'Result<T, E> 的 Ok/Err 逼调用方处理失败分支，而不是忽略错误。',
    ),
    CodeReadingEntry(
      'borrow',
      r'&\w+',
      'fn length(text: &str) -> usize {\n    text.len()\n}',
      '用引用借用数据而不取得所有权',
      '&str 是借用视图，函数返回后原字符串仍然可用，所有权没有转移。',
    ),
    CodeReadingEntry(
      'impl',
      r'\bimpl\s+\w+',
      'struct Counter { value: i32 }\n\nimpl Counter {\n    fn inc(&mut self) {\n        self.value += 1;\n    }\n}',
      '用 impl 为类型实现方法',
      'impl 块把方法绑定到类型上，&mut self 表示方法可以修改实例。',
    ),
    CodeReadingEntry(
      'trait',
      r'\btrait\s+\w+',
      'trait Greet {\n    fn hello(&self) -> String;\n}\n\nimpl Greet for User {\n    fn hello(&self) -> String { "hi".into() }\n}',
      '定义 trait 并为类型提供实现',
      'trait 描述共享行为契约，任何类型都可以 impl 它，从而支持泛型与动态分发。',
    ),
  ],
  'kotlin': <CodeReadingEntry>[
    CodeReadingEntry(
      'main',
      r'fun\s+main\s*\(',
      'fun main() {\n    println("hi")\n}',
      '定义 main 函数并打印输出',
      'fun 声明函数，println 是 Kotlin 标准库的输出函数。',
    ),
    CodeReadingEntry(
      'valvar',
      r'\b(val|var)\s+\w+',
      'val name = "Ada"\nvar count = 3\ncount += 1',
      '用 val 声明只读变量、var 声明可变变量',
      'val 绑定后不能重新赋值，var 可以；优先用 val 能减少意外修改。',
    ),
    CodeReadingEntry(
      'dataclass',
      r'\bdata\s+class\s+\w+',
      'data class User(val name: String, val age: Int)',
      '用 data class 定义只承载数据的值对象',
      'data class 自动生成 equals、hashCode、toString 与 copy，适合做数据模型。',
    ),
    CodeReadingEntry(
      'nullsafe',
      r'\?\.',
      'val length: Int? = name?.length',
      '用安全调用运算符避免空指针异常',
      '?. 在接收者为 null 时直接返回 null，而不是抛 NullPointerException。',
    ),
    CodeReadingEntry(
      'when',
      r'\bwhen\s*\(',
      'val label = when (status) {\n    200 -> "ok"\n    404 -> "missing"\n    else -> "unknown"\n}',
      '用 when 表达式做多分支匹配',
      'when 可以直接作为表达式返回结果，else 分支保证覆盖所有情况。',
    ),
    CodeReadingEntry(
      'suspend',
      r'\bsuspend\s+fun',
      'suspend fun load(): String {\n    delay(100)\n    return "done"\n}',
      '定义挂起函数，在协程中执行异步任务',
      'suspend 函数只能在协程或另一个挂起函数里调用，等待时不会阻塞线程。',
    ),
  ],
  'swift': <CodeReadingEntry>[
    CodeReadingEntry(
      'func',
      r'\bfunc\s+\w+',
      'func greet(name: String) -> String {\n    return "hi, " + name\n}',
      '定义带参数与返回值的函数',
      'Swift 用 func 声明函数，参数标签与类型写在参数名之后，箭头后是返回类型。',
    ),
    CodeReadingEntry(
      'letvar',
      r'\b(let|var)\s+\w+',
      'let name = "Ada"\nvar count = 3\ncount += 1',
      '用 let 声明常量、var 声明变量',
      'let 一旦赋值不能修改，编译器会强制你区分常量与变量。',
    ),
    CodeReadingEntry(
      'guard',
      r'\bguard\s+let',
      'guard let value = Int(text) else {\n    return nil\n}\nprint(value)',
      '用 guard let 提前退出并解包可选值',
      'guard 的条件不成立时必须离开当前作用域，之后的代码可以安全使用解包结果。',
    ),
    CodeReadingEntry(
      'optional',
      r'var\s+\w+\s*:\s*\w+\?',
      'var nickname: String? = nil\nprint(nickname?.count ?? 0)',
      '用可选类型表示可能没有值',
      '可选值必须解包后使用，?. 与 ?? 分别提供安全访问与默认值。',
    ),
    CodeReadingEntry(
      'protocol',
      r'\bprotocol\s+\w+',
      'protocol Greet {\n    func hello() -> String\n}',
      '定义协议，描述类型需要实现的能力',
      '协议只声明要求，任何类型都可以通过 extension 或直接实现来遵守它。',
    ),
    CodeReadingEntry(
      'async',
      r'\basync\b',
      'func load() async throws -> String {\n    try await Task.sleep(nanoseconds: 1)\n    return "done"\n}',
      '定义异步函数并用 try await 等待可能失败的操作',
      'async 标记异步函数，await 挂起等待，throws 表示失败会向上传播。',
    ),
  ],
  'dart': <CodeReadingEntry>[
    CodeReadingEntry(
      'widget',
      r'extends\s+StatelessWidget',
      'class Badge extends StatelessWidget {\n  const Badge({super.key, required this.text});\n  final String text;\n\n  @override\n  Widget build(BuildContext context) {\n    return Text(text);\n  }\n}',
      '定义无状态组件并在 build 中返回界面',
      'StatelessWidget 的 build 方法只依赖构造参数，界面随参数变化自动重建。',
    ),
    CodeReadingEntry(
      'stateful',
      r'extends\s+StatefulWidget',
      'class Counter extends StatefulWidget {\n  @override\n  State<Counter> createState() => _CounterState();\n}',
      '定义有状态组件并创建对应的 State',
      'StatefulWidget 本身不可变，可变状态放在 State 对象里，通过 createState 关联。',
    ),
    CodeReadingEntry(
      'setstate',
      r'\bsetState\s*\(',
      'setState(() {\n  _count += 1;\n});',
      '用 setState 通知框架状态变化并重建界面',
      'setState 回调里修改状态，框架据此把对应的 Widget 标记为需要重建。',
    ),
    CodeReadingEntry(
      'await',
      r'\bawait\b',
      'Future<String> load() async {\n  final data = await http.get(uri);\n  return data.body;\n}',
      '用 async/await 等待 Future 完成',
      'await 会挂起当前异步函数直到 Future 完成，不会阻塞 UI 线程。',
    ),
    CodeReadingEntry(
      'listview',
      r'ListView\.builder',
      'ListView.builder(\n  itemCount: items.length,\n  itemBuilder: (context, index) => Text(items[index]),\n)',
      '用 ListView.builder 按需构建列表项',
      'builder 只为可见区域创建条目，因此长列表也能保持较低的内存占用。',
    ),
  ],
  'bash': <CodeReadingEntry>[
    CodeReadingEntry(
      'pipe',
      r'\|',
      'cat access.log | grep "500" | wc -l',
      '用管道把上一条命令的输出交给下一条命令处理',
      '管道连接多个命令，grep 过滤出包含 500 的行，wc -l 统计行数。',
    ),
    CodeReadingEntry(
      'variable',
      r'^\w+=\S+',
      'name="app"\necho "hello \$name"',
      '定义 Shell 变量并在字符串中引用',
      'Shell 赋值等号两边不能有空格，\$name 会被替换成变量值。',
    ),
    CodeReadingEntry(
      'for',
      r'\bfor\s+\w+\s+in\b',
      'for file in *.log; do\n  echo "checking \$file"\ndone',
      '用 for 循环遍历一组文件',
      '通配符会先展开成文件列表，循环体对每个文件各执行一次。',
    ),
    CodeReadingEntry(
      'if',
      r'^\s*if\s+\[',
      'if [ -f config.yml ]; then\n  echo "exists"\nfi',
      '用 if 判断条件并按结果执行分支',
      '-f 判断路径是否是普通文件，条件成立时执行 then 分支。',
    ),
    CodeReadingEntry(
      'redirect',
      r'>>?\s*\S+',
      'echo "start" > run.log\necho "done" >> run.log',
      '用重定向把命令输出写入文件',
      '> 覆盖写入，>> 追加写入；重定向只改变标准输出的去向。',
    ),
    CodeReadingEntry(
      'chmod',
      r'\bchmod\s+',
      'chmod +x deploy.sh\n./deploy.sh',
      '给脚本添加可执行权限',
      'chmod +x 增加执行位，之后才能用 ./deploy.sh 直接运行。',
    ),
    CodeReadingEntry(
      'sete',
      r'set\s+-e',
      'set -euo pipefail\ncp config.yml backup/',
      '让脚本在命令失败时立即退出，避免错误被掩盖',
      '-e 遇错退出，-u 使用未定义变量时报错，-o pipefail 让管道中任一失败都算失败。',
    ),
  ],
  'sql': <CodeReadingEntry>[
    CodeReadingEntry(
      'select',
      r'\bSELECT\b',
      'SELECT id, name\nFROM users\nWHERE age >= 18\nORDER BY name;',
      '查询满足条件的行，并按指定列排序',
      'WHERE 先过滤行，ORDER BY 对结果排序，SELECT 决定返回哪些列。',
    ),
    CodeReadingEntry(
      'join',
      r'\bJOIN\b',
      'SELECT u.name, o.total\nFROM users u\nJOIN orders o ON o.user_id = u.id;',
      '用 JOIN 按关联字段把两张表连接起来',
      'ON 指定连接条件，只有两边都能匹配的行才会出现在结果中。',
    ),
    CodeReadingEntry(
      'groupby',
      r'\bGROUP\s+BY\b',
      'SELECT status, COUNT(*) AS total\nFROM orders\nGROUP BY status\nHAVING COUNT(*) > 10;',
      '按列分组统计，并用 HAVING 过滤分组结果',
      'GROUP BY 先把行分组，聚合函数在组内计算，HAVING 作用于分组后的结果。',
    ),
    CodeReadingEntry(
      'insert',
      r'\bINSERT\s+INTO\b',
      "INSERT INTO users (name, age)\nVALUES ('Ada', 36);",
      '向表中插入一行数据',
      '列清单与 VALUES 一一对应，数据库会按表定义校验类型与约束。',
    ),
    CodeReadingEntry(
      'update',
      r'\bUPDATE\s+\w+',
      'UPDATE users\nSET age = age + 1\nWHERE id = 42;',
      '更新满足条件的行的字段值',
      'WHERE 决定影响范围，缺少 WHERE 会更新整张表，是最常见的误操作。',
    ),
    CodeReadingEntry(
      'index',
      r'CREATE\s+(UNIQUE\s+)?INDEX',
      'CREATE INDEX idx_users_age\nON users (age);',
      '为列创建索引以加速查询',
      '索引让数据库不必全表扫描，但会占用空间并让写入变慢，需要权衡。',
    ),
    CodeReadingEntry(
      'transaction',
      r'\b(BEGIN|START\s+TRANSACTION|COMMIT|ROLLBACK)\b',
      'BEGIN;\nUPDATE accounts SET balance = balance - 100 WHERE id = 1;\nCOMMIT;',
      '把写操作放进事务，提交或回滚作为一个整体生效',
      '事务保证原子性：中途失败时 ROLLBACK 会撤销所有未提交的修改。',
    ),
    CodeReadingEntry(
      'explain',
      r'\bEXPLAIN\b',
      'EXPLAIN SELECT * FROM users WHERE age > 30;',
      '查看查询的执行计划，判断是否使用了索引',
      'EXPLAIN 会显示扫描方式与估算行数，是排查慢查询的第一步。',
    ),
  ],
  'html': <CodeReadingEntry>[
    CodeReadingEntry(
      'anchor',
      r'<a\s[^>]*href=',
      '<a href="/docs">查看文档</a>',
      '用 a 标签和 href 属性创建超链接',
      'href 指定点击后跳转的目标地址，标签之间的文字是链接文本。',
    ),
    CodeReadingEntry(
      'image',
      r'<img\s',
      '<img src="logo.png" alt="站点标志" width="120">',
      '用 img 标签插入图片，并用 alt 提供替代文本',
      'src 指向图片资源，alt 在图片无法显示时提供文字说明，也是无障碍的基础。',
    ),
    CodeReadingEntry(
      'list',
      r'<ul[\s>]|<ol[\s>]',
      '<ul>\n  <li>第一项</li>\n  <li>第二项</li>\n</ul>',
      '用 ul/li 组织无序列表',
      'ul 表示列表容器，每个 li 是一个列表项，浏览器会据此生成项目符号。',
    ),
    CodeReadingEntry(
      'form',
      r'<form[\s>]|<input[\s>]',
      '<form action="/login" method="post">\n  <input name="user" required>\n  <button type="submit">登录</button>\n</form>',
      '用 form 收集输入并提交给服务器',
      'action 是提交地址，method 决定请求方法，required 让浏览器先做必填校验。',
    ),
    CodeReadingEntry(
      'table',
      r'<table[\s>]',
      '<table>\n  <tr><th>姓名</th><th>年龄</th></tr>\n  <tr><td>Ada</td><td>36</td></tr>\n</table>',
      '用 table 组织行列数据',
      'th 是表头单元格，td 是数据单元格，浏览器按行渲染表格。',
    ),
    CodeReadingEntry(
      'semantic',
      r'<(header|nav|main|article|section|footer)[\s>]',
      '<main>\n  <article>\n    <h1>标题</h1>\n    <p>正文</p>\n  </article>\n</main>',
      '用语义化标签描述页面结构',
      '语义标签让结构和可访问性更清晰，屏幕阅读器与搜索引擎都能理解页面层次。',
    ),
  ],
  'css': <CodeReadingEntry>[
    CodeReadingEntry(
      'flex',
      r'display\s*:\s*flex',
      '.toolbar {\n  display: flex;\n  gap: 8px;\n  align-items: center;\n}',
      '用 flex 布局让子元素在一维方向排列',
      'display:flex 把容器变成弹性容器，gap 与 align-items 控制间距与对齐。',
    ),
    CodeReadingEntry(
      'grid',
      r'display\s*:\s*grid',
      '.cards {\n  display: grid;\n  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));\n  gap: 16px;\n}',
      '用 grid 布局构建二维网格并自适应列数',
      'auto-fill 加 minmax 让卡片在窄屏换行，无需写多个媒体查询。',
    ),
    CodeReadingEntry(
      'media',
      r'@media\s',
      '@media (max-width: 600px) {\n  .sidebar { display: none; }\n}',
      '用媒体查询在特定屏幕条件下应用样式',
      '只有视口宽度不超过 600px 时，大括号内的规则才生效，实现响应式布局。',
    ),
    CodeReadingEntry(
      'boxsizing',
      r'box-sizing\s*:\s*border-box',
      '* { box-sizing: border-box; }\n.card { width: 100%; padding: 16px; border: 1px solid #ddd; }',
      '用 border-box 让宽高包含内边距与边框',
      '默认 content-box 会把 padding 和 border 加到宽度之外，border-box 更符合直觉。',
    ),
    CodeReadingEntry(
      'position',
      r'position\s*:\s*(relative|absolute|fixed|sticky)',
      '.wrap { position: relative; }\n.badge { position: absolute; top: 8px; right: 8px; }',
      '用定位把元素相对参照物摆放',
      'absolute 元素相对最近的定位祖先定位，这里就是 position:relative 的父元素。',
    ),
    CodeReadingEntry(
      'hover',
      r':hover',
      '.button:hover {\n  background: #1d4ed8;\n}',
      '用 :hover 伪类定义鼠标悬停时的样式',
      '伪类描述元素的特定状态，悬停反馈能让可点击区域更容易被识别。',
    ),
  ],
  'json': <CodeReadingEntry>[
    CodeReadingEntry(
      'object',
      r'^\s*\{',
      '{\n  "name": "Ada",\n  "age": 36,\n  "active": true\n}',
      '用对象保存一组键值对，值可以是字符串、数字或布尔值',
      'JSON 的键必须用双引号包裹，对象用花括号表示，是最常见的配置文件结构。',
    ),
    CodeReadingEntry(
      'array',
      r'^\s*\[',
      '[\n  { "id": 1, "name": "Ada" },\n  { "id": 2, "name": "Linus" }\n]',
      '用数组保存有序的元素列表',
      '数组用方括号表示，元素可以是对象，顺序在解析后保持不变。',
    ),
    CodeReadingEntry(
      'nested',
      r'"\w+"\s*:\s*\{',
      '{\n  "server": {\n    "host": "127.0.0.1",\n    "ports": [80, 443]\n  }\n}',
      '用嵌套对象与数组表达层次结构',
      '嵌套让一份配置表达树状数据，取值时按层级逐级访问。',
    ),
  ],
  'yaml': <CodeReadingEntry>[
    CodeReadingEntry(
      'k8s',
      r'apiVersion\s*:|kind\s*:',
      'apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: web',
      '声明 Kubernetes 资源的接口版本、类型与元数据',
      'apiVersion 与 kind 决定这个清单要创建什么资源，metadata 提供名称等标识。',
    ),
    CodeReadingEntry(
      'compose',
      r'services\s*:',
      'services:\n  web:\n    image: nginx:alpine\n    ports:\n      - "8080:80"',
      '用 services 定义一组容器服务及其端口映射',
      '缩进表示层级，列表用 - 开头，这里把容器 80 端口映射到主机 8080。',
    ),
    CodeReadingEntry(
      'workflow',
      r'\bon\s*:|jobs\s*:',
      'on:\n  push:\n    branches: [main]\njobs:\n  build:\n    runs-on: ubuntu-latest',
      '定义 CI 工作流的触发条件与任务',
      'on 描述何时触发，jobs 描述要执行的任务，runs-on 指定运行环境。',
    ),
    CodeReadingEntry(
      'env',
      r'\benv\s*:',
      'env:\n  LOG_LEVEL: info\n  TIMEOUT: "30"',
      '用 env 集中声明环境变量',
      '环境变量以键值对书写，值建议加引号以避免被解析成数字或布尔值。',
    ),
  ],
  'http': <CodeReadingEntry>[
    CodeReadingEntry(
      'request',
      r'^(GET|POST|PUT|DELETE|PATCH)\s',
      'GET /api/users?page=1 HTTP/1.1\nHost: example.com\nAccept: application/json',
      '构造一个带查询参数与请求头的 GET 请求',
      '首行是请求行（方法、路径、版本），Host 等请求头描述客户端期望。',
    ),
    CodeReadingEntry(
      'status',
      r'HTTP/1\.1\s+\d{3}',
      'HTTP/1.1 200 OK\nContent-Type: application/json\n\n{"ok": true}',
      '返回状态行、响应头与响应体',
      '状态码 200 表示成功，响应头描述内容类型，空行之后是响应体。',
    ),
    CodeReadingEntry(
      'cache',
      r'Cache-Control|ETag|Last-Modified',
      'Cache-Control: max-age=3600\nETag: "abc123"',
      '用缓存相关响应头控制客户端复用资源',
      'max-age 指定新鲜期，ETag 用于条件请求，命中时服务器可以返回 304 省流量。',
    ),
  ],
  'dockerfile': <CodeReadingEntry>[
    CodeReadingEntry(
      'from',
      r'FROM\s+\S+',
      'FROM node:20-alpine\nWORKDIR /app\nCOPY package.json .\nRUN npm ci\nCOPY . .\nCMD ["node", "server.js"]',
      '以基础镜像构建应用镜像，并声明启动命令',
      'FROM 选择基础镜像，COPY/RUN 分层构建，CMD 提供容器启动时的默认命令。',
    ),
    CodeReadingEntry(
      'multistage',
      r'FROM\s+\S+\s+AS\s+\w+',
      'FROM golang:1.22 AS build\nWORKDIR /src\nRUN go build -o /out/app .\n\nFROM gcr.io/distroless/base\nCOPY --from=build /out/app /app\nENTRYPOINT ["/app"]',
      '用多阶段构建把编译环境和运行环境分开',
      '多阶段构建只把产物复制到最终镜像，能显著减小体积并减少攻击面。',
    ),
    CodeReadingEntry(
      'user',
      r'USER\s+\S+',
      'RUN adduser --system app\nUSER app',
      '切换到非 root 用户运行容器',
      '默认 root 运行风险更高，最小权限原则要求容器以专用低权限用户启动。',
    ),
  ],
};

/// 与题目无关但一定错误的兜底干扰项，用于干扰项不足的语言。
const List<String> _genericDistractors = <String>[
  '这段代码在解析或编译阶段就会直接报错',
  '这段代码不会产生任何可观察的结果',
  '这段代码必须注释掉之后才能正常运行',
  '这段代码只有删除最后一行才能通过检查',
];

/// 把围栏语言名归一化成题库键。
String canonicalCodeLanguage(String language) {
  switch (language.trim().toLowerCase()) {
    case 'js':
      return 'javascript';
    case 'ts':
      return 'typescript';
    case 'shell':
      return 'bash';
    default:
      return language.trim().toLowerCase();
  }
}

/// 开发工具用：在课程代码块里挑出最贴近的槽位，返回 null 表示语言未收录。
String? codeReadingSlotFor(String language, String code) {
  final entries = codeReadingBank[canonicalCodeLanguage(language)];
  if (entries == null || entries.isEmpty) return null;
  for (final entry in entries) {
    try {
      if (RegExp(entry.pattern, multiLine: true).hasMatch(code)) {
        return entry.slot;
      }
    } on FormatException {
      continue;
    }
  }
  return null;
}

/// 生成代码阅读题；slot 找不到时回退到该语言的第一个槽位。
///
/// 同一门课每次生成的题干、选项顺序与解析都一致，因此可以安全地
/// 写入错题本、参与组卷，并在重新进入时保持相同的判分结果。
QuizQuestion? buildCodeReadingQuestion({
  required String lessonId,
  required String lessonTitle,
  required String language,
  required String slot,
}) {
  final key = canonicalCodeLanguage(language);
  final entries = codeReadingBank[key];
  if (entries == null || entries.isEmpty) return null;
  final entry = entries.firstWhere(
    (item) => item.slot == slot,
    orElse: () => entries.first,
  );
  final seed = _stableHash('$lessonId:${entry.slot}');
  final distractors = <String>[];
  for (final other in entries) {
    if (other.slot == entry.slot || other.answer == entry.answer) continue;
    if (!distractors.contains(other.answer)) distractors.add(other.answer);
  }
  for (final generic in _genericDistractors) {
    if (!distractors.contains(generic)) distractors.add(generic);
  }
  final picked = <String>[];
  var cursor = seed;
  while (picked.length < 3 && distractors.isNotEmpty) {
    final index = cursor % distractors.length;
    final candidate = distractors.removeAt(index);
    if (candidate != entry.answer && !picked.contains(candidate)) {
      picked.add(candidate);
    }
    cursor = cursor ~/ 3 + 11;
  }
  final correctPosition = seed % 4;
  final options = <String>[];
  for (var index = 0; index < 4; index++) {
    if (index == correctPosition) {
      options.add(entry.answer);
    } else {
      options.add(picked[index > correctPosition ? index - 1 : index]);
    }
  }
  const stems = <String>[
    '阅读下面这段代码，选出正确的描述。',
    '下面这段示例代码主要演示了什么？',
    '这段代码体现了哪个语法点？',
  ];
  return QuizQuestion(
    question: stems[seed % stems.length],
    options: options,
    answerIndex: correctPosition,
    explanation: '本题对应《$lessonTitle》。${entry.explanation}',
    type: 'code',
    code: entry.code,
    language: key,
  );
}

int _stableHash(String value) {
  var hash = 7;
  for (final codeUnit in value.codeUnits) {
    hash = 31 * hash + codeUnit;
    hash &= 0x7fffffff;
  }
  return hash;
}
