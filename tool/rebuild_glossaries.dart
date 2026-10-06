// P2 术语表重建：清掉旧模板词条，给入门课换上人工校准的术语表，
// 并把全站术语表表头统一为「| 术语 | 一句话说明 |」。
//
// 用法：
//   dart tool/rebuild_glossaries.dart --dry-run
//   dart tool/rebuild_glossaries.dart --preview=<lessonId>
//   dart tool/rebuild_glossaries.dart
//
// 词条选择标准：
// - 术语必须是本课真实出现的概念（语法关键字、机制名、模型名），
//   不能是命令、代码片段、通用词（如「入门练习」）或课程标题本身；
// - 说明必须是一句可独立理解的解释，不引用测验题干，不使用「关键术语」这类空话；
// - 每课 4~6 条，覆盖本课主干，不追求把边角细节都塞进去。
import 'dart:convert';
import 'dart:io';

import 'markdown_fences.dart';

const String manifestPath = 'assets/content/manifest.json';
const String glossaryHeading = '术语速查';
const String canonicalHeader = '| 术语 | 一句话说明 |';
const String canonicalSeparator = '| --- | --- |';

/// 旧表头：P2 统一替换为 canonicalHeader。
const List<String> legacyHeaders = <String>[
  '| 术语 | 本课语境 |',
  '| 术语 | 解释 |',
  '| 术语 | 说明 |',
];

/// 人工校准的入门课术语表（课程 id → 术语、一句话说明）。
const Map<String, List<List<String>>> curatedGlossaries =
    <String, List<List<String>>>{
  // ---- Flutter ----
  'flutter_widget_intro': <List<String>>[
    <String>['Widget', 'Flutter 界面的基本单元，用不可变的配置描述界面的一部分。'],
    <String>['Widget 树', 'Widget 按父子关系组成的树，框架沿树向下传约束、向上收尺寸。'],
    <String>['约束（Constraints）', '父节点向下传递的尺寸范围，子节点只能在范围内决定自身大小。'],
    <String>['StatelessWidget', '没有内部状态的 Widget，相同输入总是渲染出相同结果。'],
    <String>['StatefulWidget', '带可变状态的 Widget，状态改变后用 setState 触发重建。'],
  ],
  'flutter_layout_intro': <List<String>>[
    <String>['Row', '把子节点沿水平方向排列的弹性布局组件。'],
    <String>['Column', '把子节点沿垂直方向排列的弹性布局组件。'],
    <String>['主轴与交叉轴', 'Row/Column 排列子节点的方向叫主轴，与之垂直的方向叫交叉轴。'],
    <String>['Expanded', '按比例瓜分主轴剩余空间的组件，放在 Row/Column 的子节点上。'],
    <String>['溢出（Overflow）', '子节点总尺寸超过父节点约束时出现的黄黑警示条纹。'],
  ],
  // ---- HTML 与 CSS ----
  'html_tags_intro': <List<String>>[
    <String>['标签（Tag）', '尖括号包起来的元素标记，成对的开始与结束标签界定内容范围。'],
    <String>['属性（Attribute）', '写在开始标签里的键值对，描述 id、链接、图片地址等附加信息。'],
    <String>['语义化标签', '用 header、nav、main、article 等表达结构含义，而不是一律用 div。'],
    <String>['文档骨架', 'html、head、body 三层结构：head 放元信息，body 放可见内容。'],
    <String>['alt 文本', '图片的替代文字，加载失败或被屏幕阅读器朗读时使用。'],
  ],
  'css_selectors_intro': <List<String>>[
    <String>['选择器（Selector）', '指定样式作用于哪些元素的模式，如 .class、#id、标签名。'],
    <String>['类选择器与 ID 选择器', '.name 可以复用于多个元素，#name 在文档里应当唯一。'],
    <String>['优先级（Specificity）', '多个选择器命中同一元素时的权重比较：id > class > 标签。'],
    <String>['伪类（Pseudo-class）', '描述元素状态的选择器，如 :hover、:focus、:first-child。'],
    <String>['盒模型（Box Model）', '内容、内边距、边框、外边距四层共同决定元素的占位大小。'],
  ],
  // ---- Python ----
  'python_first_script': <List<String>>[
    <String>['Python', '一种解释型通用编程语言，用缩进划分代码块，标准库覆盖面广。'],
    <String>['解释器', '逐行执行 Python 源码的程序，命令行输入 python 启动的就是它。'],
    <String>['脚本文件', '以 .py 结尾、保存后可重复执行的源码文件。'],
    <String>['print', '把内容输出到标准输出，是观察程序状态最直接的工具。'],
    <String>['缩进', 'Python 用缩进表示代码块层级，同一块内缩进必须一致。'],
  ],
  'python_input_output': <List<String>>[
    <String>['input', '从标准输入读入一行文本，返回值始终是字符串。'],
    <String>['类型转换', '用 int()、float() 把输入的字符串转成需要参与计算的数据类型。'],
    <String>['f-string', '以 f 开头的字符串，用 {} 直接嵌入变量或表达式。'],
    <String>['标准输入输出', '程序与终端交换数据的默认通道，对应 input 与 print。'],
    <String>['格式化输出', '控制小数位、宽度与对齐，让结果更易读。'],
  ],
  'python_if_else': <List<String>>[
    <String>['布尔值', '只有 True 与 False 两个取值，是条件判断的结果类型。'],
    <String>['比较运算符', '==、!=、>、< 等，用来比较两个值并得到布尔结果。'],
    <String>['if-elif-else', '从上到下判断条件，命中第一个为真的分支后跳过其余分支。'],
    <String>['真值判断', '空列表、0、None 等在条件里等价于假，其余多数对象为真。'],
    <String>['逻辑运算符', 'and、or、not 用来组合或取反条件。'],
  ],
  'python_loops': <List<String>>[
    <String>['for 循环', '遍历序列或可迭代对象，次数由元素个数决定。'],
    <String>['while 循环', '条件为真时反复执行循环体，需要自己保证条件最终会变假。'],
    <String>['range', '生成整数序列，常用 range(n) 或 range(start, stop, step) 控制次数。'],
    <String>['break 与 continue', 'break 立即结束整个循环，continue 跳过本次进入下一轮。'],
    <String>['死循环', '条件永远为真导致循环无法结束，通常要检查更新语句是否被执行。'],
  ],
  'python_list_dict_basics': <List<String>>[
    <String>['列表（list）', '有序可变的序列，用下标访问，可增删元素。'],
    <String>['字典（dict）', '键值对集合，按键查找，键必须可哈希且唯一。'],
    <String>['索引', '用从 0 开始的位置取元素，负数下标表示从末尾倒数。'],
    <String>['切片', '用 list[a:b] 取出一段子序列，区间左闭右开。'],
    <String>['遍历', '用 for 逐个访问元素，遍历字典时默认拿到键。'],
  ],
  // ---- C++ ----
  'cpp_first_program': <List<String>>[
    <String>['#include 预处理指令', '在编译前把头文件内容引入源文件，如 #include <iostream>。'],
    <String>['main 函数', '程序入口，返回 0 表示正常结束。'],
    <String>['编译与链接', '先把源码翻译成目标文件，再把库和多个目标文件合成可执行程序。'],
    <String>['std::cout', '标准输出流，用 << 把内容依次写到终端。'],
    <String>['命名空间 std', '标准库所在的命名空间，std:: 前缀用于避免名字冲突。'],
  ],
  'cpp_variables_io': <List<String>>[
    <String>['变量与类型', 'C++ 是静态类型语言，变量声明时必须给出类型。'],
    <String>['初始化', '定义变量的同时给初值，未初始化的局部变量内容是未定义的。'],
    <String>['std::cin', '标准输入流，用 >> 按类型读取数据。'],
    <String>['类型安全', '读取时类型不匹配会让流进入失败状态，需要检查或清理。'],
    <String>['字符串类型', 'std::string 负责管理字符序列，比 C 风格字符数组更安全。'],
  ],
  'cpp_conditions': <List<String>>[
    <String>['bool 类型', '只有 true 与 false，条件表达式的结果类型。'],
    <String>['if-else', '按条件选择分支执行，else 绑定最近的未配对 if。'],
    <String>['逻辑运算符', '&&、\\|\\|、! 组合条件，&& 与 \\|\\| 具有短路特性。'],
    <String>['作用域', '花括号形成的作用域决定变量的可见范围与生命周期。'],
    <String>['三元运算符', '条件 ? 值1 : 值2，用于在表达式位置做二选一。'],
  ],
  'cpp_loops': <List<String>>[
    <String>['for 循环', '把初始化、条件、更新写在一行，适合次数确定的循环。'],
    <String>['while 循环', '条件为真就执行，适合次数由运行情况决定的循环。'],
    <String>['do-while', '先执行一次再判断条件，循环体至少执行一次。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
    <String>['循环变量作用域', '在 for 的括号里声明的变量只在循环内可见。'],
  ],
  'cpp_functions_intro': <List<String>>[
    <String>['函数声明与定义', '声明给出签名供调用方使用，定义提供函数体。'],
    <String>['参数与返回值', '参数是输入，返回值是输出，类型都要显式写出。'],
    <String>['void', '表示函数不返回任何值。'],
    <String>['值传递与引用传递', '值传递复制实参，引用传递直接操作原对象，用 & 声明。'],
    <String>['函数重载', '同名函数通过参数列表不同来区分，编译器按实参选择。'],
  ],
  // ---- C ----
  'c_first_program': <List<String>>[
    <String>['#include <stdio.h>', '引入标准输入输出库的声明，printf 和 scanf 都由它提供。'],
    <String>['main 函数', 'C 程序的入口，操作系统从这里开始执行。'],
    <String>['编译', '把 .c 源文件翻译成机器码可执行文件的过程，如 gcc hello.c -o hello。'],
    <String>['printf', '按格式串把内容输出到标准输出。'],
    <String>['语句与分号', 'C 的每条语句以分号结束，漏写分号会直接编译报错。'],
  ],
  'c_variables_io': <List<String>>[
    <String>['数据类型', 'int、double、char 等决定变量占用的字节数与可表示范围。'],
    <String>['变量声明与初始化', '声明给出类型和名字，初始化在声明时给初值。'],
    <String>['scanf', '按格式串从标准输入读取数据，参数要传变量地址。'],
    <String>['格式化占位符', '%d、%f、%c 分别对应整数、浮点数、字符，类型不匹配会读错数据。'],
    <String>['输入缓冲区', '输入先进入缓冲区再被读取，残留换行符常导致后续读取被跳过。'],
  ],
  'c_conditions': <List<String>>[
    <String>['关系运算符', '==、!=、>、< 比较两个值，结果是整数 1 或 0。'],
    <String>['if-else', '按条件选择分支，else 与最近的未配对 if 结合。'],
    <String>['逻辑运算符', '&&、\\|\\|、! 组合条件，&& 与 \\|\\| 会短路求值。'],
    <String>['真假值', 'C 里 0 为假、非 0 为真，没有独立的布尔类型。'],
    <String>['代码块', '用花括号把多条语句合成一个分支体，同时形成作用域。'],
  ],
  'c_loops': <List<String>>[
    <String>['for 循环', '把初始化、条件、更新写在一起，适合次数确定的遍历。'],
    <String>['while 循环', '先判断后执行，适合次数由运行情况决定的场景。'],
    <String>['do-while', '先执行一次再判断，循环体至少执行一次。'],
    <String>['break 与 continue', 'break 跳出整个循环，continue 跳过本轮剩余语句。'],
    <String>['数组与下标', '用连续内存保存同类型元素，下标从 0 开始且越界不会自动报错。'],
  ],
  'c_functions_intro': <List<String>>[
    <String>['函数原型', '在调用前声明函数的参数与返回类型，让编译器能做类型检查。'],
    <String>['参数与返回值', '参数是输入，return 把结果交回调用方。'],
    <String>['void', '表示函数没有返回值。'],
    <String>['值传递', 'C 的参数默认按值传递，函数内修改形参不影响实参。'],
    <String>['函数定义与分离编译', '函数体可以放在其他源文件，通过头文件共享声明。'],
  ],
  // ---- Java ----
  'java_first_class': <List<String>>[
    <String>['class', 'Java 的基本组织单位，一个文件可以定义多个类，公开类名要与文件名一致。'],
    <String>['main 方法', '入口方法，签名固定为 public static void main(String[] args)。'],
    <String>['System.out.println', '向标准输出打印一行文本并换行。'],
    <String>['javac 与 java', '先用 javac 编译成字节码，再用 java 在 JVM 上运行。'],
    <String>['JVM', '执行字节码的虚拟机，让同一份字节码可以跨平台运行。'],
  ],
  'java_variables_output': <List<String>>[
    <String>['基本类型', 'int、double、boolean、char 等直接存值的类型，共八种。'],
    <String>['变量声明与初始化', '先声明类型和名字，再赋初值，局部变量使用前必须赋值。'],
    <String>['String', '不可变的字符串类型，属于引用类型，用 + 可以拼接。'],
    <String>['类型转换', '小范围到大范围自动提升，反向需要显式强制转换。'],
    <String>['格式化输出', 'printf 或 String.format 用 %d、%s 控制输出格式。'],
  ],
  'java_conditions': <List<String>>[
    <String>['boolean', '只有 true 与 false 的类型，条件表达式必须得到它。'],
    <String>['if-else', '按条件选择分支，else if 依次判断直到命中。'],
    <String>['比较与逻辑运算符', '==、!=、>、< 比较值，&&、\\|\\|、! 组合条件且短路求值。'],
    <String>['switch', '按离散取值分支，case 后要用 break 或新式箭头写法避免贯穿。'],
    <String>['三元运算符', '条件 ? 值1 : 值2，用于在表达式位置二选一。'],
  ],
  'java_loops': <List<String>>[
    <String>['for 循环', '把初始化、条件、更新写在一行，适合次数确定的循环。'],
    <String>['while 循环', '条件为真就执行，适合次数取决于运行状态的循环。'],
    <String>['do-while', '先执行一次再判断条件，循环体至少执行一次。'],
    <String>['增强 for', 'for (元素 : 集合) 形式，直接遍历数组或集合，不需要下标。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
  ],
  'java_methods_intro': <List<String>>[
    <String>['方法签名', '方法名加参数列表共同构成签名，是重载区分的依据。'],
    <String>['参数与返回值', '参数是输入，return 把结果交回调用方，类型必须匹配。'],
    <String>['void', '表示方法不返回任何值。'],
    <String>['方法重载', '同一个类里同名方法通过参数列表不同来区分。'],
    <String>['访问修饰符', 'public 对外可见，private 只在本类内可见，用来约束调用范围。'],
  ],
  // ---- Kotlin ----
  'kotlin_first_program': <List<String>>[
    <String>['fun main', 'Kotlin 程序的入口函数，可以不写在类里面。'],
    <String>['println', '输出一行文本，是 Kotlin 里最常用的调试输出。'],
    <String>['val 与 var', 'val 声明只读引用，var 声明可重新赋值的变量。'],
    <String>['顶层函数', '直接写在文件里的函数，不需要包在类中。'],
    <String>['字符串模板', '在字符串里用 \$name 或 \${表达式} 直接嵌入值。'],
  ],
  'kotlin_variables_null': <List<String>>[
    <String>['val 与 var', 'val 只能赋值一次，var 可以重新赋值，优先用 val。'],
    <String>['类型推断', '编译器根据初值推断类型，也可以显式写出类型注解。'],
    <String>['可空类型', '在类型后加 ?，如 String?，表示这个变量可能为 null。'],
    <String>['安全调用 ?.', '左边为 null 时直接返回 null，不会抛出异常。'],
    <String>['非空断言 !!', '强制断言不为 null，一旦为 null 会抛 NullPointerException。'],
  ],
  'kotlin_conditions': <List<String>>[
    <String>['if 表达式', 'Kotlin 的 if 有返回值，可以直接赋给变量。'],
    <String>['when', '多分支匹配，既能当语句也能当表达式，比 switch 更灵活。'],
    <String>['比较与逻辑运算符', '== 比较结构相等，=== 比较引用，&&、\\|\\|、! 组合条件。'],
    <String>['区间与 in', '用 1..10 表示闭区间，in 判断值是否落在区间或集合里。'],
    <String>['智能转换', '判断过类型或非空后，编译器自动按更精确的类型处理。'],
  ],
  'kotlin_loops': <List<String>>[
    <String>['for 与区间', 'for (i in 1..5) 按区间逐个取值，是最常用的计数循环。'],
    <String>['until、downTo、step', '分别表示左闭右开、倒序和步长，用来控制区间遍历方式。'],
    <String>['while 循环', '条件为真时反复执行，适合次数不确定的场景。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
    <String>['遍历集合', 'for (item in list) 直接取元素，需要下标时用 withIndex()。'],
  ],
  'kotlin_functions_intro': <List<String>>[
    <String>['fun', '声明函数的关键字，后面跟函数名与参数列表。'],
    <String>['参数与默认值', '参数可以带默认值，调用时省略即使用默认值。'],
    <String>['返回值', '函数体最后一个表达式的值可以作为返回值，也可以显式 return。'],
    <String>['具名参数', '调用时写参数名，可读性更好，也可以跳过有默认值的参数。'],
    <String>['单表达式函数', '函数体只有一个表达式时，用 = 直接写，省略花括号。'],
  ],
  // ---- Swift ----
  'swift_first_program': <List<String>>[
    <String>['print', '把内容输出到控制台，是观察程序行为的最快方式。'],
    <String>['let 与 var', 'let 声明常量，var 声明变量，编译器会推荐优先使用 let。'],
    <String>['类型推断', '编译器根据初值推断类型，也可以显式写类型注解。'],
    <String>['字符串插值', '在字符串里用 \\(表达式) 嵌入值。'],
    <String>['可选类型', '用 ? 标记可能没有值的变量，取值前需要解包。'],
  ],
  'swift_constants_variables': <List<String>>[
    <String>['常量 let', '一旦赋值就不能再改，默认应当优先使用。'],
    <String>['变量 var', '需要修改时才用 var 声明。'],
    <String>['类型注解', '在名字后写 : 类型，如 var count: Int = 0。'],
    <String>['类型推断', '省略类型注解时由编译器根据初值推断。'],
    <String>['可选类型 Optional', '表示「有值或没有值」，用 if let 或 guard let 安全解包。'],
  ],
  'swift_conditions': <List<String>>[
    <String>['Bool', 'Swift 的条件必须是真正的布尔值，没有隐式真假转换。'],
    <String>['if-else', '按条件选择分支，条件不写括号但必须写花括号。'],
    <String>['guard', 'guard 条件不成立时提前退出，用于减少嵌套层级。'],
    <String>['switch', '多分支匹配，要求覆盖所有情况，且默认不贯穿。'],
    <String>['可选绑定', 'if let / guard let 把可选值解包成非空常量后再使用。'],
  ],
  'swift_loops': <List<String>>[
    <String>['for-in', '遍历区间、数组或字典，是最常用的循环写法。'],
    <String>['while 循环', '条件为真时执行，适合次数不确定的场景。'],
    <String>['repeat-while', '先执行一次再判断条件，循环体至少执行一次。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
    <String>['区间运算符', 'a...b 是闭区间，a..<b 是左闭右开区间。'],
  ],
  'swift_functions_intro': <List<String>>[
    <String>['func', '声明函数的关键字，后面跟函数名与参数列表。'],
    <String>['参数标签', '调用时写在参数前的说明性标签，让调用语句更像自然语言。'],
    <String>['返回值', '用 -> 声明返回类型，函数体用 return 交出结果。'],
    <String>['默认参数', '参数可以带默认值，调用时省略即使用默认值。'],
    <String>['可变参数', '用 ... 声明同类型不定个数参数，在函数体内当作数组使用。'],
  ],
  // ---- JavaScript ----
  'js_console_start': <List<String>>[
    <String>['控制台（Console）', '浏览器开发者工具里查看日志与报错的面板。'],
    <String>['console.log', '把值打印到控制台，是排查 JavaScript 的第一步。'],
    <String>['脚本引入方式', '用 <script> 内联或引入外部 .js 文件，由浏览器按顺序执行。'],
    <String>['表达式与语句', '表达式产生值，语句执行动作，分号可选但换行规则要注意。'],
    <String>['浏览器运行环境', 'JavaScript 在浏览器里能访问 window、document 等宿主对象。'],
  ],
  'js_variables_types_intro': <List<String>>[
    <String>['let 与 const', 'let 声明可重新赋值的变量，const 声明不可重新赋值的绑定。'],
    <String>['动态类型', '变量本身没有类型，类型跟着当前保存的值走。'],
    <String>['原始类型与引用类型', '数字、字符串等按值比较，对象与数组按引用比较。'],
    <String>['typeof', '返回值的类型字符串，注意 typeof null 会得到 "object"。'],
    <String>['模板字符串', '用反引号与 \${} 拼接变量，支持多行文本。'],
  ],
  'js_conditions_loops': <List<String>>[
    <String>['真值与假值', '0、空字符串、null、undefined、NaN 在条件里等价于假。'],
    <String>['严格相等 ===', '先比较类型再比较值，避免 == 带来的隐式类型转换。'],
    <String>['if-else', '按条件选择分支执行，条件不成立时走 else。'],
    <String>['for 与 while', 'for 适合次数确定的循环，while 适合条件驱动的循环。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
  ],
  'js_functions_intro': <List<String>>[
    <String>['函数声明', '用 function 关键字定义，存在提升，可在定义前调用。'],
    <String>['箭头函数', '更简洁的函数写法，不绑定自己的 this。'],
    <String>['参数与返回值', '参数是输入，return 交回结果，没有 return 时返回 undefined。'],
    <String>['作用域与闭包', '函数可以访问定义时的外层变量，形成闭包并延长其生命周期。'],
    <String>['回调函数', '作为参数传入、在合适时机被调用的函数。'],
  ],
  'js_dom_intro': <List<String>>[
    <String>['DOM', '浏览器把 HTML 解析成的对象树，JavaScript 通过它读写页面。'],
    <String>['querySelector', '用 CSS 选择器找到第一个匹配元素，querySelectorAll 返回全部。'],
    <String>['textContent 与 innerHTML', '前者按纯文本读写，后者会解析 HTML，有注入风险。'],
    <String>['事件监听', 'addEventListener 把处理函数绑定到事件，回调里用 event 取详情。'],
    <String>['事件冒泡', '事件从触发元素向上传播，可用 stopPropagation 阻止。'],
  ],
  // ---- C# ----
  'csharp_dotnet_first': <List<String>>[
    <String>['.NET 运行时', '执行 C# 程序的运行时，负责内存管理与即时编译。'],
    <String>['namespace 与 using', '命名空间组织类型，using 引入后可直接写类型名。'],
    <String>['Console.WriteLine', '向标准输出打印一行内容。'],
    <String>['dotnet run', '还原依赖、编译并运行项目的一条命令。'],
    <String>['项目文件 csproj', '描述目标框架与依赖，dotnet 工具链据此构建。'],
  ],
  'csharp_variables_input': <List<String>>[
    <String>['强类型', '变量类型在编译期确定，类型不匹配不能通过编译。'],
    <String>['var 与显式类型', 'var 让编译器推断类型，类型本身仍然是静态的。'],
    <String>['Console.ReadLine', '从标准输入读一行，返回 string?，可能为 null。'],
    <String>['类型转换', '用 int.Parse 或 int.TryParse 把字符串转成数字，后者不会抛异常。'],
    <String>['字符串插值', '用 \$"..." 与 {} 在字符串里嵌入表达式。'],
  ],
  'csharp_conditions': <List<String>>[
    <String>['bool', '只有 true 与 false，条件表达式必须是它。'],
    <String>['if-else', '按条件选择分支，else if 依次判断。'],
    <String>['switch 与模式匹配', '按取值或模式分支，case 用 break 或 return 结束。'],
    <String>['逻辑运算符', '&&、\\|\\|、! 组合条件，&& 与 \\|\\| 会短路求值。'],
    <String>['可空类型判断', '用 is null、?? 与 ?. 处理可能为 null 的引用。'],
  ],
  'csharp_loops': <List<String>>[
    <String>['for 循环', '把初始化、条件、更新写在一行，适合按下标遍历。'],
    <String>['foreach', '直接遍历集合元素，不需要下标，也不能在遍历中修改集合。'],
    <String>['while 循环', '条件为真时执行，适合次数不确定的场景。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
    <String>['循环与集合', 'List<T> 等集合可以配合 Count 与索引使用。'],
  ],
  'csharp_methods_intro': <List<String>>[
    <String>['方法签名', '方法名加参数列表构成签名，是重载区分的依据。'],
    <String>['参数与返回值', '参数是输入，return 交回结果，类型必须匹配。'],
    <String>['void', '表示方法不返回值。'],
    <String>['方法重载', '同一个类里同名方法通过参数列表不同来区分。'],
    <String>['可选参数与命名参数', '带默认值的参数可以省略，也可以按名字指定实参。'],
  ],
  // ---- Go ----
  'go_first_program': <List<String>>[
    <String>['package main', '声明可执行程序的主包，编译后产出可执行文件。'],
    <String>['func main', '程序入口函数，没有参数也没有返回值。'],
    <String>['go run', '编译并直接运行源文件，适合开发阶段快速验证。'],
    <String>['fmt 包', '标准库里负责格式化输入输出的包，如 fmt.Println。'],
    <String>['静态编译', 'Go 把依赖打进单个二进制文件，部署时不需要额外运行时。'],
  ],
  'go_variables_input': <List<String>>[
    <String>['var 与 :=', 'var 显式声明变量，:= 在函数内声明并推断类型。'],
    <String>['静态类型', '变量类型在编译期确定，不同类型之间需要显式转换。'],
    <String>['fmt.Scan', '从标准输入按空白分隔读取数据，参数要传变量地址。'],
    <String>['零值', '变量声明后自动得到该类型的零值，如 0、""、nil。'],
    <String>['类型转换', '用 int(x) 这类显式转换，Go 不做隐式类型提升。'],
  ],
  'go_conditions': <List<String>>[
    <String>['if 语句', '条件不写括号，但必须写花括号；条件里可以带初始化语句。'],
    <String>['switch', '默认不贯穿，case 命中后自动结束，可以不带条件当多分支用。'],
    <String>['逻辑运算符', '&&、\\|\\|、! 组合条件，并且短路求值。'],
    <String>['没有三元运算符', 'Go 只保留 if-else，需要用变量接收分支结果。'],
    <String>['错误即返回值', '函数把错误作为返回值层层上交，而不是抛异常。'],
  ],
  'go_loops': <List<String>>[
    <String>['for 是唯一的循环', 'Go 只有 for，通过不同写法覆盖计数循环与条件循环。'],
    <String>['for range', '遍历数组、切片、map 与字符串，返回下标和元素副本。'],
    <String>['无限循环', '写 for { } 即可，配合 break 在条件满足时退出。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
    <String>['循环变量作用域', '每次迭代的循环变量是复用的，闭包捕获时要显式复制。'],
  ],
  'go_functions_intro': <List<String>>[
    <String>['func', '声明函数的关键字，参数类型写在名字后面。'],
    <String>['多返回值', '函数可以一次返回多个值，最常见的是「结果 + 错误」。'],
    <String>['错误处理', '调用后先判断 err != nil，再使用结果。'],
    <String>['命名返回值', '给返回值起名字，函数内可以直接赋值，return 可省参数。'],
    <String>['defer', '把清理动作推迟到函数返回前执行，常用于关闭文件与解锁。'],
  ],
  'go_profiling_deep': <List<String>>[
    <String>['pprof', 'Go 自带的性能剖析工具，可采集 CPU、内存与阻塞 profile。'],
    <String>['trace', '记录运行时事件的追踪工具，用来观察调度与 GC 时间线。'],
    <String>['基准测试', '以 Benchmark 开头的测试函数，重复执行并报告每次耗时与内存分配。'],
    <String>['逃逸分析', '编译器判断变量能否分配在栈上，用 -gcflags=-m 查看结果。'],
    <String>['内存分配剖析', '用 -benchmem 与 memprofile 找出分配热点，减少不必要的堆分配。'],
  ],
  // ---- Rust ----
  'rust_cargo_first': <List<String>>[
    <String>['cargo new', '创建新项目，同时生成 Cargo.toml 与 src/main.rs。'],
    <String>['Cargo.toml', '项目清单，记录包名、版本与依赖。'],
    <String>['fn main', '可执行程序的入口函数。'],
    <String>['println! 宏', '带格式化能力的输出宏，末尾的 ! 表示它是宏而不是函数。'],
    <String>['cargo check', '只做类型与借用检查、不产出二进制，是最快的反馈手段。'],
  ],
  'rust_variables_mutability': <List<String>>[
    <String>['let 默认不可变', 'Rust 变量默认不能重新赋值，这是编译期保证的一部分。'],
    <String>['let mut', '加 mut 才能修改，可变性越小越容易推理。'],
    <String>['类型推断与标注', '编译器通常能推断类型，必要时用 : 显式标注。'],
    <String>['遮蔽（shadowing）', '用同名 let 重新绑定，可以改变类型，与 mut 赋值不同。'],
    <String>['const 常量', '编译期求值，必须写类型，命名习惯是全大写。'],
  ],
  'rust_conditions': <List<String>>[
    <String>['bool', '条件必须是真正的布尔值，不会隐式转换数字。'],
    <String>['if 是表达式', 'if-else 有值，可以直接赋给变量，各分支类型必须一致。'],
    <String>['比较与逻辑运算符', '==、!=、< 比较，&&、\\|\\|、! 组合条件。'],
    <String>['match', '按模式分支，必须覆盖所有可能，编译器会检查是否穷尽。'],
    <String>['代码块表达式', '花括号块的最后一个表达式就是块的值，不加分号。'],
  ],
  'rust_loops': <List<String>>[
    <String>['loop', '无条件循环，用 break 退出，可以带值返回。'],
    <String>['while 循环', '条件为真时执行，适合次数不确定的场景。'],
    <String>['for 与区间', 'for i in 0..5 遍历左闭右开区间，是推荐的计数写法。'],
    <String>['迭代器', 'iter()、into_iter() 配合 map、filter 完成声明式遍历。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
  ],
  'rust_functions_intro': <List<String>>[
    <String>['fn', '声明函数的关键字，参数与返回类型都要标注。'],
    <String>['表达式与语句', '表达式有值，语句没有；函数体最后一个表达式作为返回值。'],
    <String>['返回值与分号', '末尾表达式后加分号会变成语句，导致返回值类型不匹配。'],
    <String>['所有权入门', '值有唯一所有者，离开作用域即释放，移动后原变量不可再用。'],
    <String>['借用与引用', '用 &T 借用而不取得所有权，同一作用域内可变借用只能有一个。'],
  ],
  // ---- TypeScript ----
  'ts_first_types': <List<String>>[
    <String>['类型注解', '在变量或参数后写 : 类型，让编译器据此检查。'],
    <String>['类型推断', '有初值时 TypeScript 能自动推断类型，不必处处手写。'],
    <String>['基础类型', 'string、number、boolean 等，与 JavaScript 的原始类型对应。'],
    <String>['编译到 JavaScript', 'tsc 把类型擦除后产出浏览器和 Node 能直接运行的 JS。'],
    <String>['编译期与运行期', '类型只在编译期存在，运行时没有任何类型检查。'],
  ],
  'ts_basic_types': <List<String>>[
    <String>['联合类型', '用 A \\| B 表示取值属于其中一种，使用前要先收窄。'],
    <String>['字面量类型', '把具体值当类型，如 "left" \\| "right"，常配合联合使用。'],
    <String>['any 与 unknown', 'any 关闭检查，unknown 强制先收窄，新代码优先用 unknown。'],
    <String>['类型别名 type', '给复杂类型起名字，便于复用与阅读。'],
    <String>['null 与 undefined', '在 strictNullChecks 下它们是独立类型，需要显式处理。'],
  ],
  'ts_interface_intro': <List<String>>[
    <String>['interface', '描述对象应该有哪些属性与类型，只存在于编译期。'],
    <String>['可选属性 ?', '表示该属性可能不存在，读取时要先判断。'],
    <String>['readonly', '禁止在初始化后重新赋值该属性。'],
    <String>['函数类型成员', '接口里可以声明方法签名，描述对象能接受怎样的调用。'],
    <String>['结构化类型', '只要结构兼容就算类型兼容，不要求显式继承。'],
  ],
  'ts_function_types': <List<String>>[
    <String>['参数与返回类型', '函数签名要写清参数类型和返回类型，返回值可省略由编译器推断。'],
    <String>['可选参数与默认值', '用 ? 或默认值表示可以不传，可选参数必须排在必选参数之后。'],
    <String>['箭头函数类型', '用 (a: number) => string 描述函数类型，可直接标注变量。'],
    <String>['void 与 never', 'void 表示不返回值，never 表示永远不会正常返回。'],
    <String>['泛型入门', '用 <T> 让函数对多种类型复用，同时保留类型关系。'],
  ],
  'ts_arrays_objects': <List<String>>[
    <String>['数组类型', '用 T[] 或 Array<T> 描述同类型元素组成的数组。'],
    <String>['元组 tuple', '固定长度且每个位置类型可以不同的数组，如 [string, number]。'],
    <String>['对象类型', '用 {} 描述属性结构，属性名与类型一一对应。'],
    <String>['索引签名', '用 [key: string]: T 描述不定数量的同类属性。'],
    <String>['解构', '从数组或对象里直接取出需要的值，同时可以给默认值。'],
  ],
  // ---- Shell ----
  'shell_first_script': <List<String>>[
    <String>['shebang', '脚本第一行的 #!/bin/bash，指定用哪个解释器执行。'],
    <String>['chmod +x', '给脚本加上可执行权限，之后才能直接 ./script.sh 运行。'],
    <String>['变量与引用', '赋值写 name=value（等号两边不能有空格），引用写 \$name。'],
    <String>['echo', '把内容输出到标准输出，常用于查看变量与调试。'],
    <String>['退出码 \$?', '上一条命令的结束状态，0 表示成功，非 0 表示失败。'],
  ],
  'shell_variables_args': <List<String>>[
    <String>['位置参数', '\$1、\$2 是脚本收到的参数，\$0 是脚本名，\$@ 是全部参数。'],
    <String>['引号规则', '双引号保留变量展开，单引号原样输出，变量要用 "\$var" 包裹。'],
    <String>['环境变量', '由父进程传下来的变量，用 export 让子进程也能看到。'],
    <String>['默认值展开', '\${var:-默认值} 在变量为空时使用默认值。'],
    <String>['命令替换', '用 \$(命令) 把命令输出取回当作值使用。'],
  ],
  'shell_conditions': <List<String>>[
    <String>['if 与退出码', 'if 判断的是命令退出码，0 为真、非 0 为假。'],
    <String>['test 与 [ ]', '用 test 或 [ ] 比较数值、字符串与判断文件属性。'],
    <String>['[[ ]]', 'bash 的增强条件语法，支持模式匹配且不需要担心分词。'],
    <String>['文件测试', '-f 判断普通文件，-d 判断目录，-x 判断可执行权限。'],
    <String>['elif 与 else', '多分支按顺序判断，命中一个就跳过其余分支。'],
  ],
  'shell_loops': <List<String>>[
    <String>['for 循环', '遍历列表或通配符展开的结果，逐个执行循环体。'],
    <String>['while read', '逐行读取文件或管道输入，是处理文本的常见写法。'],
    <String>['通配符展开', '* 与 ? 由 shell 先展开成文件名列表，再交给命令。'],
    <String>['break 与 continue', 'break 结束整个循环，continue 跳过本轮剩余语句。'],
    <String>['循环中的引号', '遍历文件名时必须写 "\$file"，否则含空格的名字会被拆开。'],
  ],
  'shell_pipeline_intro': <List<String>>[
    <String>['管道 \\|', '把上一条命令的标准输出接到下一条命令的标准输入。'],
    <String>['重定向 > 与 >>', '把输出写入文件，> 覆盖、>> 追加。'],
    <String>['标准错误 2>', '错误信息走独立通道，常用 2>&1 合并到标准输出。'],
    <String>['grep、sort、uniq', '过滤、排序与去重，是管道里最常用的三个过滤器。'],
    <String>['xargs', '把上一条命令的输出转换成下一条命令的参数列表。'],
  ],
  // ---- 计算机基础 ----
  'binary_intro': <List<String>>[
    <String>['位与字节', '一位只能是 0 或 1，八位组成一个字节，是存储与寻址的基本单位。'],
    <String>['二进制与十进制', '二进制逢二进一，按位权展开即可换算成十进制。'],
    <String>['十六进制', '每四位二进制对应一位十六进制，写法短且与位模式一一对应。'],
    <String>['补码', '用取反加一表示负数，让减法可以复用加法电路。'],
    <String>['位运算', '与、或、异或、移位直接操作二进制位，常用于掩码与标志位。'],
  ],
  // ---- 算法与数据结构 ----
  'algorithm_intro': <List<String>>[
    <String>['算法', '把输入转换成输出的一组有限、确定的步骤。'],
    <String>['正确性与边界', '除了常规输入，还要验证空输入、单元素与极值。'],
    <String>['时间复杂度', '描述运行时间随输入规模增长的趋势，用大 O 表示上界。'],
    <String>['空间复杂度', '描述额外内存随输入规模增长的趋势。'],
    <String>['暴力解法与优化', '先写出能正确解决问题的朴素解法，再定位瓶颈做优化。'],
  ],
  'linear_search_intro': <List<String>>[
    <String>['线性查找', '从一端开始逐个比较，直到找到目标或遍历结束。'],
    <String>['遍历', '按下标依次访问每个元素，是线性查找的实现方式。'],
    <String>['最坏与平均情况', '目标在末尾或不存在时比较次数最多，平均约为长度的一半。'],
    <String>['提前返回', '命中目标立即返回下标，避免无意义的后续比较。'],
    <String>['适用场景', '数据量小或没有排序时最直接，有序数据应改用二分查找。'],
  ],
  'union_find': <List<String>>[
    <String>['并查集（DSU）', '维护不相交集合的数据结构，支持合并与查询是否同属一个集合。'],
    <String>['代表元（根）', '每个集合选一个代表元素，判断是否连通就是比较两个根。'],
    <String>['路径压缩', '查询时把沿途节点直接挂到根上，让后续查询接近常数时间。'],
    <String>['按秩合并', '合并时把矮树挂到高树下，避免树退化成链。'],
    <String>['连通分量', '并查集里的每个集合就是一个连通分量，常用于 Kruskal 建最小生成树。'],
  ],
  'binary_answer': <List<String>>[
    <String>['二分答案', '在答案的取值范围内二分，用可行性判断决定往哪一半收缩。'],
    <String>['单调性', '答案越大（或越小）越容易满足条件，这是能用二分的前提。'],
    <String>['可行性判定 check(x)', '给定候选答案，判断是否存在满足约束的方案。'],
    <String>['下界与上界', '二分前要确定答案的最小可能值和最大可能值，边界不能漏。'],
    <String>['最小化最大值', '典型题型：把最大代价压到最小，答案本身单调，适合二分答案。'],
  ],
  // ---- 网络 ----
  'network_layers_intro': <List<String>>[
    <String>['分层模型', '把网络功能拆成若干层，每层只依赖下层提供的服务。'],
    <String>['封装与解封装', '发送时逐层加头，接收时逐层去掉并交给上层。'],
    <String>['应用层', 'HTTP、DNS 等直接面向应用的协议所在层。'],
    <String>['传输层', 'TCP 与 UDP 所在层，负责端到端的可靠或高效传输。'],
    <String>['网络层与链路层', 'IP 负责寻址与路由，链路层负责在同一网段上真正发送帧。'],
  ],
  'ip_port_intro': <List<String>>[
    <String>['IP 地址', '标识网络中一台主机的地址，IPv4 为 32 位，IPv6 为 128 位。'],
    <String>['子网与掩码', '掩码划分网络号与主机号，决定哪些地址在同一网段。'],
    <String>['端口', '同一主机上区分不同服务的编号，0~1023 多为知名端口。'],
    <String>['客户端与服务器', '客户端主动发起连接，服务器在固定端口上监听。'],
    <String>['NAT', '把内网地址转换成公网地址，让多台设备共享一个出口 IP。'],
  ],
  // ---- 安全与合规 ----
  'security_concept_intro': <List<String>>[
    <String>['机密性、完整性与可用性', '安全的三条基本目标：不被未授权读取、不被篡改、需要时可用。'],
    <String>['威胁与攻击面', '威胁是可能造成损害的因素，攻击面是系统暴露给外部的入口总和。'],
    <String>['认证', '确认「你是谁」，常见手段是口令、令牌、证书。'],
    <String>['授权', '确认「你能做什么」，认证之后按权限决定可访问的资源。'],
    <String>['最小权限', '每个主体只拿完成当前任务所需的权限，把事故影响限制在最小范围。'],
  ],
  'password_hash_intro': <List<String>>[
    <String>['哈希函数', '把任意长度输入压缩成固定长度摘要，单向且对输入敏感。'],
    <String>['加盐', '为每个口令拼接随机值再哈希，让相同口令得到不同摘要。'],
    <String>['慢哈希', 'bcrypt、Argon2 等故意消耗算力的算法，用来抵抗离线爆破。'],
    <String>['不要明文存口令', '一旦数据库泄露，明文口令会直接导致账号被登录。'],
    <String>['彩虹表', '预先算好的摘要对照表，加盐后即失效。'],
  ],
  'security_sdl': <List<String>>[
    <String>['SDL', '安全开发生命周期：把安全活动嵌入需求、设计、编码、测试与发布各阶段。'],
    <String>['安全需求', '在写代码前明确要防住什么威胁，以及可接受的残余风险。'],
    <String>['威胁建模', '按资产、攻击面与攻击路径梳理风险，并给出对应缓解措施。'],
    <String>['代码扫描', '用 SAST/依赖扫描在提交或构建阶段自动发现已知缺陷。'],
    <String>['上线门禁', '把扫描与测试结果设为发布前置条件，高危问题未修复不放行。'],
  ],
  // ---- 数据库 ----
  'sql_table_intro': <List<String>>[
    <String>['表、行与列', '表由若干行记录组成，每一列定义字段名与数据类型。'],
    <String>['主键', '唯一标识一行的列或列组合，不允许重复也不能为空。'],
    <String>['数据类型与约束', '类型限制可存的值，NOT NULL、UNIQUE、CHECK 等约束保证数据有效。'],
    <String>['CREATE TABLE', '用 DDL 语句建表，一次写清列、类型与约束。'],
    <String>['外键', '指向另一张表主键的列，用来维护表之间的引用完整性。'],
  ],
  'sql_query_intro': <List<String>>[
    <String>['SELECT', '指定要取哪些列，写星号通配符表示取全部列。'],
    <String>['WHERE', '在分组前过滤行，只保留满足条件的记录。'],
    <String>['ORDER BY', '按指定列排序，ASC 升序、DESC 降序，可以多列组合。'],
    <String>['聚合与 GROUP BY', 'SUM、COUNT 等把多行汇总成一行，GROUP BY 决定按什么分组。'],
    <String>['JOIN', '按关联条件把多张表拼在一起，最常用的是 INNER 与 LEFT JOIN。'],
  ],
  // ---- 操作系统 ----
  'process_thread_intro': <List<String>>[
    <String>['进程', '操作系统分配资源的基本单位，拥有独立的地址空间。'],
    <String>['线程', '进程内的执行单元，共享地址空间，切换开销比进程小。'],
    <String>['上下文切换', '保存当前执行现场并恢复另一个，频繁切换会带来额外开销。'],
    <String>['共享内存与竞态', '多线程共享数据时执行顺序不确定，需要锁或原子操作保护。'],
    <String>['调度', '内核决定哪个线程何时占用 CPU，策略影响吞吐与响应时间。'],
  ],
  // ---- 工具链 ----
  'git_intro': <List<String>>[
    <String>['仓库', '由 .git 目录保存全部提交历史的项目目录。'],
    <String>['提交（commit）', '一次带说明的历史快照，记录作者、时间与改动内容。'],
    <String>['暂存区', '用 git add 把改动放进暂存区，再一次性提交，便于挑选改动。'],
    <String>['分支', '指向某次提交的可移动指针，用来隔离并行开发。'],
    <String>['远程仓库', '托管在服务器上的副本，push 上传、pull 拉取并合并。'],
  ],
  'cli_intro': <List<String>>[
    <String>['路径与目录', '绝对路径从根开始，相对路径基于当前目录，. 与 .. 分别表示当前和上级。'],
    <String>['命令与参数', '命令是程序名，参数控制它的行为，选项通常以 - 或 -- 开头。'],
    <String>['管道与重定向', '管道把前一条命令的输出接给下一条，重定向写入或读取文件。'],
    <String>['权限', '读、写、执行三类权限分别作用于所有者、组和其他用户。'],
    <String>['环境变量', '进程启动时继承的键值配置，如 PATH 决定去哪些目录找命令。'],
  ],
  'debugging': <List<String>>[
    <String>['断点', '让程序在指定位置暂停，便于查看当时的变量与调用栈。'],
    <String>['日志分级', '按 DEBUG、INFO、WARN、ERROR 输出，线上通常只保留后几级。'],
    <String>['异常与堆栈', '堆栈记录异常发生时的调用链，是定位根因的第一手线索。'],
    <String>['二分定位', '通过注释或开关逐步缩小范围，快速锁定引入问题的那次改动。'],
    <String>['最小复现', '把问题压缩成最短的、可稳定触发的例子，再着手修复。'],
  ],
  // ---- AI 与智能体 ----
  'ai_concept_intro': <List<String>>[
    <String>['模型与参数', '模型是带大量可调参数的函数，训练就是调整这些参数。'],
    <String>['训练与推理', '训练用数据调整参数，推理用固定参数对新输入给出结果。'],
    <String>['特征与标签', '特征描述样本，标签是希望模型预测的答案。'],
    <String>['大语言模型', '在海量文本上训练、按上下文逐词预测的语言模型。'],
    <String>['提示词', '交给模型的输入文本，决定任务描述与输出格式。'],
  ],
  'prompt_intro': <List<String>>[
    <String>['提示词', '发给模型的完整输入，通常包含角色、任务、约束与示例。'],
    <String>['任务描述', '用一句话说清要模型做什么，避免含糊的开放式要求。'],
    <String>['示例（few-shot）', '给出一两个输入输出样例，让模型模仿格式与判断标准。'],
    <String>['输出格式约束', '要求返回 JSON 或固定字段，方便程序解析与校验。'],
    <String>['温度（temperature）', '控制随机性，越低越稳定，越高越发散。'],
  ],
  // ---- 数学基础 ----
  'math_set_function_intro': <List<String>>[
    <String>['集合', '把确定对象看成一个整体的数学结构，元素之间不重复、无顺序。'],
    <String>['属于与包含', '∈ 表示元素属于集合，⊆ 表示一个集合完全包含在另一个集合里。'],
    <String>['函数与映射', '把每个输入对应到唯一输出的规则。'],
    <String>['定义域与值域', '定义域是所有合法输入，值域是所有实际取到的输出。'],
    <String>['单射与满射', '单射保证不同输入得到不同输出，满射保证每个目标值都被取到。'],
  ],
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final preview = _stringOption(args, '--preview=', '');
  final invalid = _validateCuratedGlossaries();
  if (invalid.isNotEmpty) {
    stderr.writeln('词条数据不合法：${invalid.join('、')}');
    exitCode = 3;
    return;
  }
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Map<String, dynamic>>[
    for (final rawCategory in manifest['categories'] as List<dynamic>)
      for (final raw in (rawCategory as Map)['lessons'] as List<dynamic>)
        (raw as Map).cast<String, dynamic>(),
  ];
  final ids = <String>{for (final lesson in lessons) lesson['id'].toString()};
  final unknown = curatedGlossaries.keys.where((id) => !ids.contains(id)).toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('词条表里有清单中不存在的课程：${unknown.join('、')}');
    exitCode = 4;
    return;
  }

  if (preview.isNotEmpty) {
    final lesson = lessons.firstWhere(
      (item) => item['id'].toString() == preview,
      orElse: () => const <String, dynamic>{},
    );
    if (lesson.isEmpty) {
      stderr.writeln('找不到课程：$preview');
      exitCode = 2;
      return;
    }
    final rebuilt = rebuildGlossary(
      File(lesson['file'].toString()).readAsStringSync(),
      preview,
    );
    stdout.writeln(_glossarySection(rebuilt) ?? '(没有术语速查章节)');
    return;
  }

  var rebuiltLessons = 0;
  var standardizedLessons = 0;
  var unchanged = 0;
  for (final lesson in lessons) {
    final id = lesson['id'].toString();
    final file = File(lesson['file'].toString());
    final before = file.readAsStringSync();
    final after = rebuildGlossary(before, id);
    if (after == before) {
      unchanged++;
      continue;
    }
    if (curatedGlossaries.containsKey(id)) {
      rebuiltLessons++;
    } else {
      standardizedLessons++;
    }
    if (!dryRun) file.writeAsStringSync(after, flush: true);
  }
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}人工重建术语表 $rebuiltLessons 篇，'
    '统一表头 $standardizedLessons 篇，未变化 $unchanged 篇',
  );
}

/// 重建一门课的术语表：人工词条优先，其余课程只统一表头。
String rebuildGlossary(String markdown, String lessonId) {
  final lines = markdown.split('\n');
  final mask = markdownFenceMask(markdown);
  final range = _glossaryRange(lines, mask);
  if (range == null) return markdown;
  final curated = curatedGlossaries[lessonId];
  if (curated == null) {
    var changed = false;
    for (var index = range.heading + 1; index < range.end; index++) {
      if (!legacyHeaders.contains(lines[index].trim())) continue;
      lines[index] = canonicalHeader;
      changed = true;
    }
    return changed ? lines.join('\n') : markdown;
  }
  // 保留表前的导语，表头与词条整体换成人工版本。
  final intro = <String>[
    for (var index = range.heading + 1; index < range.end; index++)
      if (lines[index].trim().isNotEmpty &&
          !lines[index].trimLeft().startsWith('|'))
        lines[index],
  ];
  final output = <String>[
    ...lines.sublist(0, range.heading + 1),
    '',
    if (intro.isNotEmpty) ...<String>[...intro, ''],
    canonicalHeader,
    canonicalSeparator,
    for (final row in curated) '| `${row[0]}` | ${row[1]} |',
    '',
    ...lines.sublist(range.end),
  ];
  return '${output.join('\n').trimRight()}\n';
}

({int heading, int end})? _glossaryRange(List<String> lines, List<bool> mask) {
  final headingPattern = RegExp('^##\\s+$glossaryHeading\\s*\$');
  final sectionPattern = RegExp(r'^##\s+');
  var heading = -1;
  for (var index = 0; index < lines.length; index++) {
    if (mask[index]) continue;
    if (headingPattern.hasMatch(lines[index])) {
      heading = index;
      break;
    }
  }
  if (heading < 0) return null;
  var end = lines.length;
  for (var index = heading + 1; index < lines.length; index++) {
    if (mask[index]) continue;
    if (sectionPattern.hasMatch(lines[index])) {
      end = index;
      break;
    }
  }
  return (heading: heading, end: end);
}

String? _glossarySection(String markdown) {
  final lines = markdown.split('\n');
  final range = _glossaryRange(lines, markdownFenceMask(markdown));
  if (range == null) return null;
  return lines.sublist(range.heading, range.end).join('\n').trimRight();
}

List<String> _validateCuratedGlossaries() {
  final invalid = <String>[];
  for (final entry in curatedGlossaries.entries) {
    if (entry.value.length < 4) {
      invalid.add('${entry.key}(只有 ${entry.value.length} 条)');
    }
    for (final row in entry.value) {
      if (row.length != 2 || row[0].trim().isEmpty || row[1].trim().isEmpty) {
        invalid.add('${entry.key}(词条格式错误)');
        break;
      }
      if (_hasUnescapedPipe(row[0]) || _hasUnescapedPipe(row[1])) {
        invalid.add('${entry.key}(竖线未转义)');
        break;
      }
    }
  }
  return invalid;
}

/// 表格单元格里的竖线必须写成 \|，否则会把表格撑成多列。
bool _hasUnescapedPipe(String text) {
  for (var index = 0; index < text.length; index++) {
    if (text[index] != '|') continue;
    if (index > 0 && text[index - 1] == r'\') continue;
    return true;
  }
  return false;
}

String _stringOption(List<String> args, String prefix, String fallback) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    return arg.substring(prefix.length);
  }
  return fallback;
}
