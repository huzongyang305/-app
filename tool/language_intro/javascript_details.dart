// JavaScript 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _jsConsoleCode = r'''console.log("你好，JavaScript");

const name = "小明";
console.log(`欢迎，${name}`);''';

const String _jsVarCode = r'''const name = "小明";
let age = 18;
let height = 1.75;
let isBeginner = true;

console.log(`${name} 今年 ${age} 岁`);
console.log(`身高 ${height} 米，是否初学者：${isBeginner}`);
console.log(typeof name, typeof age, typeof height, typeof isBeginner);''';

const String _jsCondLoopCode = r'''const scores = [95, 72, 40];

for (const score of scores) {
  if (score >= 90) {
    console.log(`${score} 分：优秀`);
  } else if (score >= 60) {
    console.log(`${score} 分：及格`);
  } else {
    console.log(`${score} 分：需要补考`);
  }
}

let total = 0;
let index = 0;
while (index < scores.length) {
  total += scores[index];
  index += 1;
}
console.log(`总分 ${total}`);''';

const String _jsFuncCode = r'''function add(a, b) {
  return a + b;
}

const multiply = (a, b) => a * b;

console.log(add(3, 4));
console.log(multiply(3, 4));

function greet(name = "同学") {
  return `你好，${name}`;
}

console.log(greet());
console.log(greet("小明"));''';

const String _jsDomCode = r'''<button id="count-button">点我加一</button>
<p id="count-text">当前计数：0</p>

<script>
  let count = 0;
  const button = document.querySelector("#count-button");
  const text = document.querySelector("#count-text");

  button.addEventListener("click", () => {
    count += 1;
    text.textContent = `当前计数：${count}`;
  });
</script>''';

const List<LanguageIntroDetail> javascriptIntroDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'js_console_start',
    sectionTitle: 'JavaScript 从控制台开始',
    codeLanguage: 'javascript',
    oneLiner:
        'console.log 把内容打印到控制台，是 JavaScript 最直接的观察手段；'
        '写好代码后可以放进浏览器控制台或 Node.js 立刻运行。',
    analogy:
        'console.log 像在代码里插了一排小灯泡：程序走到哪儿、变量是什么值，'
        '灯一亮你就看到了。排查问题时先点灯，再谈修复。',
    code: _jsConsoleCode,
    lineWalk: '''
- `console.log("你好，JavaScript");` 调用 console 对象的 log 方法，把参数打印到控制台并换行。
- `const name = "小明";` 用 const 声明一个常量，声明后不能重新赋值，适合不会变的数据。
- 反引号包起来的是模板字符串，里面用美元符号加花括号把变量嵌进文字，比用加号拼接更清楚。
- 每条语句结尾的分号可以省略，但团队项目里建议统一保留，避免个别场景下的解析歧义。
- JavaScript 文件保存为 `.js`，在浏览器里通过 `<script src="...">` 引入，或在 Node.js 里用 `node 文件名.js` 运行。
''',
    runThrough: '''
- 第一行执行，控制台出现「你好，JavaScript」。
- const 声明把「小明」存进 name。
- 模板字符串求值时把 name 换成实际内容，第二行输出「欢迎，小明」。
- 脚本执行完毕，全局作用域里留下一个名为 name 的常量。
''',
    pitfalls: '''
- 把 `console.log` 写成 `console.Log`：JavaScript 区分大小写，会报「不是函数」。
- 在浏览器里打开 HTML 却看不到输出：控制台不在页面上，要按 F12 打开开发者工具。
- 给 const 变量重新赋值：`name = "小红"` 会抛 TypeError。
- 中文全角引号或括号：看起来一样但不是合法符号，报 SyntaxError。
- 用 document.write 代替 console.log：会直接覆盖页面内容，调试时非常危险。
''',
    drill: '''
- 把输出改成自己的名字，在浏览器控制台和 Node.js 里各运行一次，比较结果。
- 用一个变量保存年龄，再用模板字符串输出一整句话。
- 故意把 `console.log` 写成 `console.logg`，记录报错信息。
''',
  ),
  LanguageIntroDetail(
    id: 'js_variables_types_intro',
    sectionTitle: 'JavaScript 变量与类型',
    codeLanguage: 'javascript',
    oneLiner:
        'JavaScript 用 let 声明可变的变量、const 声明不变的绑定；'
        '类型由值决定，同一个变量可以在不同时刻装不同类型的值。',
    analogy:
        '像没有固定标签的收纳盒：盒子本身不限定装什么，里面放的是衣服它就是衣物盒，'
        '换成书就成了书盒。类型跟着内容走，而不是跟着盒子走。',
    code: _jsVarCode,
    lineWalk: '''
- `const name = "小明";` 用 const 声明字符串常量，绑定不能再指向别的值。
- `let age = 18;` 用 let 声明可以重新赋值的变量，作用域限制在最近的一对花括号内。
- `let height = 1.75;` JavaScript 只有一种数字类型 Number，整数和小数不分家。
- `let isBeginner = true;` 布尔值只有 true 和 false 两个字面量。
- 模板字符串里的美元符号加花括号可以放任意表达式，不只是变量名。
- `typeof` 返回一个描述类型的字符串，是排查类型问题时最常用的工具。
''',
    runThrough: '''
- 四行声明依次执行，各自保存一个值。
- 两条输出把值嵌进模板字符串，屏幕显示两行中文。
- typeof 依次返回 string、number、number、boolean，注意 age 和 height 的类型都是 number。
- 如果把 18 改成 "18"，typeof 的结果会变成 string，而输出文字看不出差别，这正是 JavaScript 容易踩坑的地方。
''',
    pitfalls: '''
- 用 var 声明变量：var 没有块级作用域，循环里声明的变量会泄漏到循环外。
- 以为 `typeof null` 是 null：它其实返回 object，这是语言的历史遗留问题。
- 用 `==` 比较不同类型：`"18" == 18` 为 true，应该用 `===` 严格比较。
- 给 const 声明的对象改属性：对象属性可以改，只有整个绑定不能换，容易误解。
- 数字精度问题：`0.1 + 0.2` 得到 0.30000000000000004，金额计算要转换成整数分。
''',
    drill: '''
- 分别用 let 和 const 声明变量，尝试重新赋值，观察哪一个会报错。
- 输出 `typeof null`、`typeof []`、`typeof function () {}` 的结果，把它们记下来。
- 用 `===` 和 `==` 分别比较 `"1"` 和 1，解释差异。
''',
  ),
  LanguageIntroDetail(
    id: 'js_conditions_loops',
    sectionTitle: 'JavaScript 条件与循环',
    codeLanguage: 'javascript',
    oneLiner:
        'if 负责分支选择，for...of 依次取出数组元素，while 则在条件成立时反复执行；'
        '三者组合就能处理一批数据。',
    analogy:
        '像整理一摞试卷：for...of 是逐张拿起来看，if 是判断这份该归到哪个分数档，'
        'while 是「只要还有试卷就继续」的手动循环。',
    code: _jsCondLoopCode,
    lineWalk: '''
- `const scores = [95, 72, 40];` 用方括号声明数组，元素按顺序排列。
- `for (const score of scores)` 每次把数组里的一个元素绑定到 score，好处是不用管下标。
- if / else if / else 从上往下判断，第一个成立的分支执行后其余跳过。
- 输出里嵌入了当前分数，所以每行都能看出判定的是哪一份。
- `while (index < scores.length)` 用下标遍历，`scores.length` 是元素个数。
- 循环体里必须让 index 自增，否则条件永远为真，程序会卡死。
''',
    runThrough: '''
- for...of 依次取到 95、72、40，分别走三条分支，输出三行判定结果。
- 进入 while，index 从 0 开始，依次累加 95、72、40。
- index 变成 3，等于数组长度，条件不成立，循环结束。
- 最后输出总分 207。
''',
    pitfalls: '''
- 在 for...of 里用 index 变量：for...of 不提供下标，需要下标时应使用 entries 或普通 for。
- 把数组长度写死：用 `scores.length` 才是自适应的，写 3 在加数据后立刻出错。
- while 忘记 index 自增：条件恒为真，浏览器标签页直接卡住。
- 对对象使用 for...of：普通对象不可迭代，应该改用 Object.keys 或 for...in。
- 在遍历时删除数组元素：下标会错位，导致跳过元素。
''',
    drill: '''
- 把数组改成四个分数，确认每条分支都能命中。
- 在 for...of 里加 continue 跳过不及格的分数，观察输出变化。
- 用普通 for 重写一遍累加逻辑，比较两种循环的适用场景。
''',
  ),
  LanguageIntroDetail(
    id: 'js_functions_intro',
    sectionTitle: 'JavaScript 函数入门',
    codeLanguage: 'javascript',
    oneLiner:
        '函数是 JavaScript 的一等公民，可以用 function 声明、用箭头函数赋值，'
        '还能作为参数传给别人。',
    analogy:
        '函数像可以随手传递的遥控器：你不仅能自己按，也能把它交给别人保管，'
        '需要的时候由对方按下去。这就是回调函数的本质。',
    code: _jsFuncCode,
    lineWalk: '''
- `function add(a, b) { return a + b; }` 是函数声明，会被提升到作用域顶部，可以在定义之前调用。
- `const multiply = (a, b) => a * b;` 是箭头函数简写，表达式的结果会直接作为返回值。
- 箭头函数只有一行表达式时可以省略 return 和花括号。
- `function greet(name = "同学")` 给参数设置默认值，调用时不传参就用默认值。
- 函数没有显式 return 时，返回值是 undefined，不会报错但很容易被忽略。
''',
    runThrough: '''
- `add(3, 4)` 返回 7，控制台输出 7。
- `multiply(3, 4)` 返回 12，输出 12。
- `greet()` 没有传参，用默认值「同学」，输出「你好，同学」。
- `greet("小明")` 传入实参，默认值不生效，输出「你好，小明」。
''',
    pitfalls: '''
- 箭头函数里用 this：箭头函数不绑定自己的 this，会沿用外层的值，写对象方法时要格外小心。
- 参数传少了不报错：缺的参数是 undefined，参与运算会得到 NaN。
- 忘记 return：调用处拿到 undefined，后续计算出错却找不到原因。
- 函数声明和函数表达式提升规则不同：后者在定义之前调用会报「不是函数」。
- 箭头函数写成 `(a, b) => { a * b }`：花括号被当成函数体，必须写 return 才有返回值。
''',
    drill: '''
- 写一个 subtract 函数，分别用函数声明和箭头函数实现。
- 给 add 增加参数校验，传入非数字时返回 0。
- 故意在箭头函数里加花括号但不写 return，观察结果。
''',
  ),
  LanguageIntroDetail(
    id: 'js_dom_intro',
    sectionTitle: 'JavaScript 操作页面',
    codeLanguage: 'html',
    oneLiner:
        'DOM 是浏览器把 HTML 解析成的一棵树，JavaScript 通过选择器找到节点、'
        '修改内容或监听事件，从而让页面动起来。',
    analogy:
        '把 DOM 想成一棵家族树：每个标签是一个成员，id 是身份证号。'
        'querySelector 按身份证找人，addEventListener 是给这个人装上「听到门铃就开门」的机关。',
    code: _jsDomCode,
    lineWalk: '''
- 页面上放了一个按钮和一个段落，各自带 id 方便定位。
- `let count = 0;` 用来保存点击次数，必须放在事件函数外面，否则每次点击都会重新归零。
- `document.querySelector("#count-button")` 按 CSS 选择器语法查找第一个匹配元素并返回。
- `addEventListener("click", ...)` 注册点击监听器，事件发生时浏览器会调用后面的函数。
- 回调里先让 count 加一，再更新段落的 textContent，文字立刻反映在页面上。
- 用 textContent 而不是 innerHTML 写入纯文本，可以避免把用户内容当成 HTML 执行。
''',
    runThrough: '''
- 页面加载时执行脚本，count 初始化为 0，两个元素被找到并保存。
- 用户点一次按钮，click 事件触发，count 变成 1。
- textContent 被更新为「当前计数：1」，页面文字立刻变化。
- 再点一次，count 变成 2，如此往复。
''',
    pitfalls: '''
- 脚本写在 head 里且没有 defer：DOM 还没解析到按钮，querySelector 返回 null，调用时报错。
- id 拼写错：选择器找不到元素，报无法读取 null 的属性。
- 用 innerHTML 拼接用户输入：可能被注入脚本，存在 XSS 风险。
- 把 count 定义在回调里面：每次点击都重新初始化为 0，计数永远显示 1。
- 同一个事件重复注册监听器：一次点击触发多次处理，数字会跳着涨。
''',
    drill: '''
- 把按钮文字改成「增加」，确认点击后的行为不变。
- 再加一个重置按钮，把计数恢复为 0。
- 把 textContent 换成 innerHTML 并输入一段带有尖括号的文字，观察差异。
''',
  ),
];
