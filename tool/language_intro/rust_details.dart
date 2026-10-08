// Rust 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _rustFirstCode = r'''fn main() {
    println!("你好，Rust");
}''';

const String _rustVarCode = r'''fn main() {
    let name: &str = "小明";
    let mut age: u32 = 18;
    let height: f64 = 1.75;

    age += 1;

    println!("{name} 明年 {age} 岁，身高 {height} 米");
}''';

const String _rustIfCode = r'''fn main() {
    let score = 72;

    if score >= 90 {
        println!("优秀");
    } else if score >= 60 {
        println!("及格");
    } else {
        println!("需要补考");
    }

    let level = if score >= 60 { "通过" } else { "未通过" };
    println!("结果：{level}");
}''';

const String _rustLoopCode = r'''fn main() {
    let mut total = 0;

    for i in 1..=5 {
        total += i;
        println!("加入 {i} 后累计 {total}");
    }

    while total < 20 {
        total += 5;
    }

    println!("最终结果：{total}");
}''';

const String _rustFuncCode = r'''fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn print_result(value: i32) {
    println!("结果是 {value}");
}

fn main() {
    print_result(add(3, 4));
    print_result(add(10, 20));
}''';

const List<LanguageIntroDetail> rustIntroDetails = <LanguageIntroDetail>[
  ..._rustFirstDetails,
  ..._rustVarDetails,
  ..._rustIfDetails,
  ..._rustLoopDetails,
  ..._rustFuncDetails,
];

const List<LanguageIntroDetail> _rustFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'rust_cargo_first',
    sectionTitle: 'Rust 与 Cargo 第一个项目',
    codeLanguage: 'rust',
    oneLiner:
        'Rust 用 cargo 管理项目：cargo new 建工程、cargo run 编译并运行、cargo build 只编译；'
        '程序入口是 fn main。',
    analogy:
        '把 cargo 想成装修队：你只说要建什么，它负责买材料（依赖）、施工（编译）和交钥匙（运行）。'
        '你不用手动搬每一块砖。',
    code: _rustFirstCode,
    lineWalk: '''
- `fn main()` 定义程序入口，fn 是 function 的缩写，函数体用花括号包围。
- `println!` 末尾的叹号表示这是一个宏，不是普通函数；它负责把格式化内容打印到标准输出。
- 字符串字面量用双引号，Rust 的字符串是 UTF-8 编码，中文可以直接写。
- Rust 语句以分号结尾，但表达式块的值可以省略分号作为返回值。
- 用 cargo new 生成的项目里有 src/main.rs 和 Cargo.toml，后者记录项目名和依赖。
''',
    runThrough: '''
- 执行 `cargo new hello` 创建项目目录。
- 进入目录执行 `cargo run`，cargo 先编译再运行。
- 程序进入 main，执行 println 宏，屏幕输出「你好，Rust」。
- 编译产物放在 target/debug 下，正式发布用 `cargo build --release`。
''',
    pitfalls: '''
- 把 `println!` 的叹号漏掉：编译器会提示找不到名为 println 的函数。
- 用 rustc 单独编译带依赖的项目：依赖不会自动下载，应该用 cargo。
- 在函数外部写语句：Rust 只允许在函数里执行代码，顶层只能写声明。
- 以为调试构建够快：debug 与 release 的性能差距可能达到数倍。
- 修改 Cargo.toml 后忘记重新编译：旧产物不会自动反映新依赖。
''',
    drill: '''
- 修改输出文字，重新执行 cargo run。
- 用 cargo build 编译一次，找到生成的可执行文件路径。
- 在 Cargo.toml 里改项目名，观察编译产物的名字变化。
''',
  ),
];

const List<LanguageIntroDetail> _rustVarDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'rust_variables_mutability',
    sectionTitle: 'Rust 变量与可变性',
    codeLanguage: 'rust',
    oneLiner:
        'Rust 的变量默认不可变，要修改必须写 mut；'
        '这种默认值让编译器帮你挡住大量意外改写。',
    analogy:
        '默认不可变像合同上的条款：想改必须先在合同上标明「此处可修改」。'
        '没标注的地方被改了，审查员（编译器）立刻拦下。',
    code: _rustVarCode,
    lineWalk: '''
- `let name: &str = "小明";` 声明一个字符串切片引用，类型标注写在冒号后面。
- `let mut age: u32 = 18;` 加 mut 才是可变的，u32 表示 32 位无符号整数。
- `let height: f64 = 1.75;` f64 是 64 位浮点数，也是 Rust 的默认浮点类型。
- `age += 1;` 因为声明时写了 mut，这行才合法；去掉 mut 会编译失败。
- `println!("{name} 明年 {age} 岁")` 用花括号直接引用变量名，这是较新的格式化语法。
- 同名变量可以再次 let 覆盖，这叫遮蔽，类型甚至可以改变。
''',
    runThrough: '''
- 三个变量依次绑定：name 不可变，age 可变，height 不可变。
- age 从 18 加到 19。
- println 依次填入 name、age、height 的值。
- 输出「小明 明年 19 岁，身高 1.75 米」；如果删掉 mut，编译阶段就会报错。
''',
    pitfalls: '''
- 忘记 mut：想修改不可变变量时编译器直接报错，这是 Rust 新手最常见的问题。
- 整数类型选太小：u8 只能装 0 到 255，溢出在调试构建会直接 panic。
- 变量未使用：编译器给出警告，提醒你可能写错了名字。
- 整数除法丢失精度：`5 / 2` 得到 2，要小数必须先把类型转成 f64。
- 混淆字符串和字符串切片：String 可增长，&str 是借用的视图，用途不同。
''',
    drill: '''
- 去掉一个 mut，记录完整的编译错误。
- 把 age 的类型改成 u8 并赋值 300，观察编译器的报错。
- 用遮蔽重新绑定同名变量并改变类型，说明和 mut 的区别。
''',
  ),
];

const List<LanguageIntroDetail> _rustIfDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'rust_conditions',
    sectionTitle: 'Rust 条件判断',
    codeLanguage: 'rust',
    oneLiner:
        'Rust 的 if 条件必须是 bool 类型，不会自动把数字当作真假；'
        'if 还是表达式，可以直接把结果赋给变量。',
    analogy:
        '把 if 想成自动售货机的两条出货通道：两条通道都必须吐出同一类商品，'
        '机器才能把它统一放进你的袋子里。所以两个分支的返回类型必须一致。',
    code: _rustIfCode,
    lineWalk: '''
- `let score = 72;` 类型由整数默认推断为 i32。
- `if score >= 90 {` 条件不需要括号，花括号必需。
- 分支里的 println 宏返回单元类型，所以这里只做副作用，不产出值。
- 把 if 当表达式赋值时，两个分支都返回字符串切片。
- 如果两个分支返回类型不同，编译器会报错，这是 Rust 类型安全的一部分。
- 输出时用花括号直接引用变量名。
''',
    runThrough: '''
- score 为 72：第一个条件假，第二个真，输出「及格」。
- 计算 level 时条件为真，得到「通过」。
- 输出「结果：通过」。
- 如果把 score 改成 95，会先输出「优秀」，level 仍是「通过」。
''',
    pitfalls: '''
- 用整数直接当条件：`if score { }` 编译失败，必须写成明确比较。
- 两个分支返回不同类型：编译器会要求统一类型，需要显式转换。
- 在分支表达式里加分号：加了分号就变成语句，返回单元类型，赋值会失败。
- 混淆两个等号和一个等号：Rust 会把赋值当语句，写在条件位置直接报错。
- 忘记 else 分支：把 if 当表达式赋值时，else 是必需的。
''',
    drill: '''
- 用 90、89、60、59 四个值测试分支。
- 用 if 表达式把分数映射成等级字符串，然后打印。
- 故意让两个分支返回不同类型，记录编译错误。
''',
  ),
];

const List<LanguageIntroDetail> _rustLoopDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'rust_loops',
    sectionTitle: 'Rust 循环',
    codeLanguage: 'rust',
    oneLiner:
        'Rust 有 for、while 和 loop 三种循环；'
        'loop 是无限循环，但可以带 break 返回值，非常适合重试逻辑。',
    analogy:
        'loop 像一个带投币口的抓娃娃机：一直运转，直到你按下停止，'
        '而按下的一瞬间机器还能把奖品交给你。',
    code: _rustLoopCode,
    lineWalk: '''
- `let mut total = 0;` 必须写 mut，因为循环里要修改它。
- `for i in 1..=5` 中两个点表示范围，等号表示包含终点，所以 i 依次是 1 到 5。
- `total += i;` 每轮累加，分号不能省。
- 循环体里的 println 用花括号直接引用 i 和 total。
- `while total < 20 {` 每轮开始前判断条件。
- 循环外的 println 只执行一次，输出最终结果。
''',
    runThrough: '''
- for 五轮结束后 total 是 15。
- while 第一轮把 15 加到 20。
- 再判断条件不成立，循环结束。
- 输出「最终结果：20」；如果写成 `1..5` 则不含 5，结果会少 5。
''',
    pitfalls: '''
- 把 `1..=5` 写成 `1..5`：右开区间不包含终点，累加结果不同。
- 忘记 mut：循环里修改累加器会编译失败。
- 在 for 里修改被遍历的集合：借用检查器会拒绝，需要先收集或用索引。
- 用 loop 却没有 break：程序永远不会结束。
- 在循环里持有可变借用又读取同一个值：借用规则会直接报错。
''',
    drill: '''
- 把范围改成 `1..=100`，先估算结果再运行。
- 用 loop 改写 while，并用 break 返回累计值。
- 在循环里加 `if i == 3 { continue; }`，解释总和的变化。
''',
  ),
];

const List<LanguageIntroDetail> _rustFuncDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'rust_functions_intro',
    sectionTitle: 'Rust 函数入门',
    codeLanguage: 'rust',
    oneLiner:
        'Rust 函数用 fn 声明，参数和返回值都必须写类型；'
        '函数体最后一个不带分号的表达式就是返回值。',
    analogy:
        '把不带分号的最后一行想成快递单上的签收栏：它是函数交出去的东西。'
        '一旦在末尾加了分号，签收栏就变成一张废纸，函数什么都不交。',
    code: _rustFuncCode,
    lineWalk: '''
- `fn add(a: i32, b: i32) -> i32` 声明函数，箭头后面是返回类型。
- 函数体里 `a + b` 没有分号，作为表达式直接成为返回值。
- `fn print_result(value: i32)` 没有箭头，返回类型是单元类型，相当于不返回值。
- 调用 `add(3, 4)` 得到 7，作为实参传给 print_result。
- Rust 函数名的命名规范是全小写加下划线，这也是编译器会提醒的风格。
- 参数默认按值移动或复制，借用需要显式写引用符号。
''',
    runThrough: '''
- `add(3, 4)` 进入函数体，表达式求值为 7 并返回。
- 7 传给 print_result，输出「结果是 7」。
- 第二次调用得到 30，输出「结果是 30」。
- main 返回单元类型，进程退出。
''',
    pitfalls: '''
- 在最后一行加分号：返回值变成单元类型，调用处类型不匹配。
- 参数不写类型：Rust 不允许在函数签名里省略类型。
- 函数名用驼峰：编译能过，但编译器给出命名风格警告。
- 把 String 直接传进函数后又想使用原变量：所有权已经移动，需要传引用或克隆。
- 忘记写 return 又想提前返回：非末尾位置必须显式写 return。
''',
    drill: '''
- 增加一个 `fn multiply(a: i32, b: i32) -> i32` 并调用。
- 故意在表达式末尾加分号，观察编译器的报错信息。
- 写一个返回 String 的函数，说明所有权如何转移给调用方。
''',
  ),
];
