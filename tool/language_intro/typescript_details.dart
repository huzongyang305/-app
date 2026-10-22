// TypeScript 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _tsFirstCode = r'''const name: string = "小明";
const age: number = 18;
const isBeginner: boolean = true;

console.log(`${name} 今年 ${age} 岁`);
console.log(`是否初学者：${isBeginner}`);''';

const String _tsTypesCode = r'''type UserId = string | number;
type Status = "pending" | "done" | "failed";

const id: UserId = 1001;
const status: Status = "done";
const scores: number[] = [95, 72, 40];
const names: Array<string> = ["小明", "小红"];

console.log(id, status, scores, names);''';

const String _tsInterfaceCode = r'''interface User {
  readonly id: number;
  name: string;
  age?: number;
}

const user: User = {
  id: 1,
  name: "小明",
};

function greet(target: User): string {
  const suffix = target.age === undefined ? "" : `，${target.age} 岁`;
  return `你好，${target.name}${suffix}`;
}

console.log(greet(user));''';

const String _tsFuncTypesCode = r'''function add(a: number, b: number): number {
  return a + b;
}

const multiply = (a: number, b: number): number => a * b;

type Formatter = (value: number) => string;

const toCurrency: Formatter = (value) => `¥${value.toFixed(2)}`;

console.log(add(3, 4));
console.log(multiply(3, 4));
console.log(toCurrency(19.9));''';

const String _tsArrayCode = r'''type Product = {
  name: string;
  price: number;
  tags: string[];
};

const products: Product[] = [
  { name: "键盘", price: 199, tags: ["外设"] },
  { name: "鼠标", price: 99, tags: ["外设", "热销"] },
];

const total = products.reduce((sum, item) => sum + item.price, 0);
const hotNames = products
  .filter((item) => item.tags.includes("热销"))
  .map((item) => item.name);

console.log(`总价 ${total}`);
console.log(`热销商品：${hotNames.join("、")}`);''';

const List<LanguageIntroDetail> typescriptIntroDetails = <LanguageIntroDetail>[
  ..._tsFirstDetails,
  ..._tsBasicTypeDetails,
  ..._tsInterfaceDetails,
  ..._tsFunctionTypeDetails,
  ..._tsArrayObjectDetails,
];

const List<LanguageIntroDetail> _tsFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'ts_first_types',
    sectionTitle: 'TypeScript 第一个类型标注',
    codeLanguage: 'typescript',
    oneLiner:
        'TypeScript 在 JavaScript 之上加了类型标注，写代码时就能发现类型错误；'
        '标注只存在于编译阶段，编译后生成的还是普通 JavaScript。',
    analogy:
        '类型标注像机场的安检申报单：填的时候麻烦一点，但能让问题在出门前就被拦下，'
        '而不是飞到目的地才发现行李不合规。',
    code: _tsFirstCode,
    lineWalk: '''
- `const name: string = "小明";` 冒号后面的 string 是类型标注，告诉编译器这个变量只能装字符串。
- `const age: number = 18;` TypeScript 不区分整数和小数，统一用 number。
- `const isBeginner: boolean = true;` 布尔类型只有 true 和 false。
- 模板字符串的用法和 JavaScript 完全一致，类型标注不会改变运行时行为。
- TypeScript 文件后缀是 `.ts`，需要先用 tsc 编译成 `.js` 才能在浏览器或 Node 里运行。
''',
    runThrough: '''
- 编译：`npx tsc hello.ts`，生成同名 `.js` 文件。
- 如果写 `const age: number = "18";`，编译阶段立刻报错，提示不能把 string 赋给 number。
- 运行生成的 JavaScript，控制台输出两行中文。
- 打开编译产物会发现类型标注全部消失，这正是「类型只做检查、不参与运行」的含义。
''',
    pitfalls: '''
- 以为 TypeScript 代码能直接运行：浏览器不认 `.ts`，必须先编译或用 ts-node 之类的工具。
- 到处写 any：any 会关掉该值的类型检查，等于把 TypeScript 当 JavaScript 用。
- 用叹号强行断言非空：编译通过但运行时仍可能是 undefined，应该先做判断。
- 类型标注写成 String 而不是 string：前者是包装对象类型，后者才是原始类型。
- 忘记在 tsconfig 里打开 strict：很多类型错误默认不报，等于白装 TypeScript。
''',
    drill: '''
- 把 age 的标注改成 string 并赋数字，观察编译报错。
- 增加一个变量保存身高，类型选 number。
- 编译后打开生成的 js 文件，确认类型标注已经消失。
''',
  ),
];

const List<LanguageIntroDetail> _tsBasicTypeDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'ts_basic_types',
    sectionTitle: 'TypeScript 基础类型',
    codeLanguage: 'typescript',
    oneLiner:
        '除了 string、number、boolean，TypeScript 还提供联合类型、字面量类型和数组类型，'
        '让你能精确描述「这个值只能是这几种可能」。',
    analogy:
        '联合类型像多选问卷：题目允许你从几个固定选项里挑一个，填了不在列表里的答案会被拒收。'
        '字面量类型更严格，等于只允许填 A 或 B 两个具体答案。',
    code: _tsTypesCode,
    lineWalk: '''
- `type UserId = string | number;` 用 type 给联合类型起名字，竖线读作「或」。
- `type Status = "pending" | "done" | "failed";` 这是字面量联合类型，取值只能是这三个字符串之一。
- `const id: UserId = 1001;` 赋数字合法；写成 true 就会编译报错。
- `const scores: number[] = [95, 72, 40];` 方括号写在类型后面表示由 number 组成的数组。
- `const names: Array<string> = ["小明", "小红"];` 这种写法叫泛型语法，和 string[] 等价。
- 类型别名只是给类型起名字，编译后完全消失，不影响运行。
''',
    runThrough: '''
- 编译器逐个检查赋值：1001 属于 number，合法；done 在三个字面量里，合法。
- 数组里的每个元素都会被检查是否满足声明的元素类型。
- 如果往 names 里 push 一个数字，编译阶段就会报错，不用等到运行。
- 编译产物里只剩普通 JavaScript 的变量声明。
''',
    pitfalls: '''
- 把联合类型当成任意类型：`string | number` 只接受这两种，不是什么都行。
- 对联合类型直接调用方法：`id.toFixed(2)` 编译不过，因为 string 没有这个方法，必须先缩小类型。
- 数组写成 `[number]`：这是只有一个元素的元组，和 number[] 完全不同。
- 滥用字面量类型又频繁断言：as 会绕过检查，把错误推到运行时。
- 把类型别名和接口混用时不理解区别：type 能表示联合和元组，interface 更适合描述对象并可被继承扩展。
''',
    drill: '''
- 定义 `type Weekday = "Mon" | "Tue" | "Wed";`，分别赋一个合法和一个非法值。
- 写一个 `(string | number)[]` 数组，放入两种类型的元素。
- 用类型收窄改写对联合类型的方法调用，让编译器接受。
''',
  ),
];

const List<LanguageIntroDetail> _tsInterfaceDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'ts_interface_intro',
    sectionTitle: 'TypeScript 接口入门',
    codeLanguage: 'typescript',
    oneLiner:
        'interface 用来描述一个对象应该有哪些属性、每个属性是什么类型；'
        '属性后面的问号表示可选，readonly 表示创建后不能改。',
    analogy:
        '接口像入职登记表的格式要求：必填项不填会退回来，选填项可以空着，'
        '身份证号一旦录入就不允许再改。'
        '更重要的是，登记表只规定格式，不会替你核对现实：真正来自用户或网络的数据'
        '仍然要在运行时检查，接口只负责在编译时拦下明显不符合格式的写法。',
    code: _tsInterfaceCode,
    lineWalk: '''
- `interface User` 声明一个对象形状，描述一个 User 长什么样。
- `readonly id: number;` 的 readonly 只在编译期起作用，赋值之后再改会报错。
- `name: string;` 是必填属性，创建对象时漏掉就编译失败。
- `age?: number;` 的问号表示可以不存在，读取时类型会自动带上 undefined。
- `const user: User = { id: 1, name: "小明" };` 只写必填项也合法。
- 三目表达式是类型收窄：先判断 age 是不是 undefined，再决定要不要拼接。
- `interface` 不会出现在编译后的 JavaScript 里，它只参与检查；删掉类型标注，程序的实际执行逻辑完全不变。
''',
    runThrough: '''
- 编译器检查对象字面量：id 和 name 都有且类型正确，age 缺失但它是可选项，通过。
- 调用 greet 时把 user 传进去，参数类型也满足 User。
- 函数内判断 age 为 undefined，走空字符串分支。
- 返回「你好，小明」，输出到控制台。
''',
    pitfalls: '''
- 以为 readonly 能防住运行时的修改：它只存在于编译阶段，运行时对象仍可被改。
- 可选属性直接使用：`target.age + 1` 编译不过，必须先判断是否存在。
- 在接口里写具体实现：interface 只描述形状，不带函数体。
- 对象字面量多写属性：直接赋给 interface 类型时多出的属性会报错，这叫多余属性检查。
- 需要联合类型时硬写 interface：联合类型要用 type 描述。
- 把接口当成运行时校验器：用户输入或 JSON 解析结果不会自动满足接口，仍要自己检查字段是否存在、类型是否正确。
''',
    drill: '''
- 给 User 增加一个可选属性 email，并让 greet 在有值时输出它。
- 尝试修改 user.id，观察编译器报错。
- 定义一个 Book 接口，包含书名、作者和可选页数。
- 故意多写一个 User 不存在的字段，记录报错内容，再删掉该字段确认编译通过。
''',
  ),
];

const List<LanguageIntroDetail> _tsFunctionTypeDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'ts_function_types',
    sectionTitle: 'TypeScript 函数类型',
    codeLanguage: 'typescript',
    oneLiner:
        '函数的参数和返回值都可以标注类型；给函数整体起类型别名后，'
        '就能把它当作参数传给别的函数，并保证签名一致。',
    analogy:
        '函数类型像插座标准：不管你插的是台灯还是充电器，插头形状必须匹配。'
        '类型别名就是那份插头标准，谁想接进来都得按这个形状做。',
    code: _tsFuncTypesCode,
    lineWalk: '''
- `function add(a: number, b: number): number` 中冒号后面的 number 是返回值类型。
- 参数类型不写时会被推断成 any，strict 模式下会直接报错。
- `const multiply = (a: number, b: number): number => a * b;` 箭头函数同样能标注。
- `type Formatter = (value: number) => string;` 描述一个函数形状：收 number、返回 string。
- 赋给 Formatter 类型的函数必须满足这个形状，否则编译失败。
- 参数名在类型别名里只是说明用途，实际实现可以换名字。
''',
    runThrough: '''
- `add(3, 4)` 返回 7，类型检查确认两个实参都是 number。
- `multiply(3, 4)` 返回 12。
- `toCurrency(19.9)` 内部调用 toFixed 保留两位小数，返回字符串「¥19.90」。
- 如果把 toCurrency 改成返回数字，赋值那一行立刻报类型不匹配。
''',
    pitfalls: '''
- 返回值类型写成 void 却实际返回了值：调用处拿不到结果，逻辑静默出错。
- 可选参数写在必选参数前面：TypeScript 要求必选参数在前。
- 回调函数的参数不写类型：在 strict 模式下会报隐式 any。
- 以为参数类型会在运行时校验：类型只在编译期检查，外部传入的数据仍需自己验证。
- 给函数类型加了多余参数：函数赋值时参数个数不匹配也会报错。
''',
    drill: '''
- 写一个 `type Comparator = (a: number, b: number) => boolean;` 并用它声明一个比较函数。
- 给 add 增加一个可选的第三参数，默认值为 0。
- 故意让 toCurrency 返回数字，观察是哪一行报错。
''',
  ),
];

const List<LanguageIntroDetail> _tsArrayObjectDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'ts_arrays_objects',
    sectionTitle: 'TypeScript 数组与对象',
    codeLanguage: 'typescript',
    oneLiner:
        '给数组和对象标注类型后，map、filter、reduce 这些链式操作会在每一步保留类型信息，'
        '写错属性名立刻就能发现。',
    analogy:
        '像流水线加工：原料通过 filter 筛掉不合格的，再通过 map 换个包装，最后 reduce 汇总成一件成品。'
        '每一步的输入输出类型都写在工艺卡上，接错了立刻报警。',
    code: _tsArrayCode,
    lineWalk: '''
- `type Product = { ... }` 描述商品的形状，数组里的每个元素都必须符合。
- `const products: Product[]` 说明这是一个商品数组，访问 item.price 时编译器知道它是 number。
- `reduce((sum, item) => sum + item.price, 0)` 从初始值 0 开始，把每个价格累加进去。
- `filter((item) => item.tags.includes("热销"))` 留下标签里含热销的商品，返回仍是数组。
- `map((item) => item.name)` 把每个商品转换成它的名字，结果类型自动变成 string[]。
- `join("、")` 把字符串数组用顿号连接成一句话。
''',
    runThrough: '''
- reduce 遍历两个商品，sum 依次变成 199 和 298，输出「总价 298」。
- filter 只留下鼠标这一项。
- map 把这一项转成名字「鼠标」，join 之后得到「鼠标」。
- 输出「热销商品：鼠标」；如果写错成 item.tag，编译阶段就会报属性不存在。
''',
    pitfalls: '''
- 只写 `const products = [...]` 不加标注：类型虽然能推断，但跨文件复用时不清晰。
- 在 map 里返回不同类型：结果数组会变成联合类型，后续操作需要额外判断。
- reduce 忘记给初始值：空数组时会抛运行时错误。
- 直接修改原数组：push、sort 会改变原数组，纯函数式写法应返回新数组。
- 把对象属性写成可选却直接解构：解构出来可能是 undefined，需要给默认值。
''',
    drill: '''
- 给 products 增加一个商品，确保总价结果跟着变。
- 用 map 生成一个只有名称和价格的简化数组，观察推断出的类型。
- 把 tags 里的字符串改成一个不存在的字段名，记录编译错误。
''',
  ),
];
