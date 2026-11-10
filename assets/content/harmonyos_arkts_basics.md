# ArkTS 语言基础

![ArkTS 静态约束层与声明式扩展层的双层结构](images/diagram_harmonyos_arkts_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：45 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `ArkTS 语言基础`，学习阶段 移动，建议用时 45 分钟。

本课主线：把 ArkTS 拆成两层来学——一层是「对 TypeScript 的收紧」，即强制静态类型、禁止动态特性、限制结构化赋值；另一层是「为 ArkUI 准备的扩展」，即装饰器、`build()` 内的声明式描述与链式属性。先用大量对照样例钉住禁令清单，再把 class、interface、联合类型与类型收窄讲透，最后给出装饰器的语法基线，为状态管理与 UI 两门课打底。

**学完本课应当能够**

- 列出 ArkTS 相对 TypeScript 的主要禁令，并解释每条禁令背后的运行期原因（无动态对象布局、AOT 编译）。
- 用 `class` 与 `interface` 正确建模一份接口返回数据，避开把对象字面量赋给接口、用 `as` 强转、动态加属性这三类典型错误。
- 写出通过类型检查的联合类型处理代码，使用 `instanceof` 与判空收窄把可选值转成确定值。
- 默写 `@Component` + `@State` + `build()` 的最小合法骨架，指出哪些语句在 `build()` 里非法。

### 复习清单

- [ ] 能不看正文写出五条 ArkTS 禁令，并各配一个错误样例与修正写法。
- [ ] 能推演本课的联合类型示例：先写预期输出，再编译并记录差异。
- [ ] 能完成一次自测，把错题对照易错点表定位是类型规则还是装饰器规则没记牢。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| 强制静态类型 | 每个变量、参数、返回值都要能推出确定类型，`any`/`unknown` 与隐式 any 被禁止。 | 易错：以为写 `: any` 只是 lint 警告，NEXT 编译期直接报错。 |
| 类型注解 | 在声明处显式标注类型，如 `let n: number = 1`，是 ArkTS 的默认而非可选项。 | 易错：省略构造参数类型会让整 struct 推断失败。 |
| 结构化赋值限制 | 不允许把结构兼容但类型不同的对象互相赋值，接口与类之间也不做结构等价。 | 易错：TS 里 `as SomeInterface` 的写法在 ArkTS 中拿不到方法。 |
| 动态属性禁令 | 不能给已定义类型的对象追加或删除属性，也不支持 `with` 语句。 | 易错：用 `obj[key] = value` 拼装数据，运行前就被拦下。 |
| 联合类型 | 用竖线把两种及以上类型并列表达多态取值，使用前必须收窄到具体分支。 | 易错：直接访问只存在于其中一个分支的成员。 |
| 类型收窄 | 通过 `instanceof`、判空、字面量比较把联合类型缩到可用范围。 | 易错：只在逻辑上收窄而没有落到变量上，编译器不认。 |
| 装饰器 | 标注在结构体、成员或方法上的元信息语法，如 `@Component`、`@State`、`@Builder`。 | 易错：把装饰器写在方法内部或漏写括号。 |
| 声明式描述 | `build()` 内通过组件构造与链式属性描述界面，不是命令式改 DOM。 | 易错：在 `build()` 里写循环副作用或普通语句。 |

## 原理与运行机制

### 机制总览：一门「收紧的 TS」为什么存在

ArkTS 的目标不是发明新语言，而是让 TypeScript 的写法在 AOT 编译与长期运行的设备上足够可预测。动态类型带来的隐藏成本在浏览器里由 JIT 与垃圾回收吸收，而在移动端要保证启动与帧率，编译器必须能在编译期确定对象布局、方法表与内存分配路径。于是 ArkTS 保留 TS 的语法外壳，砍掉运行期不可静态推导的特性，同时把 UI 描述需要的语法糖补上。

**教材衔接：约束层与扩展层的分工**

| 层 | 内容 | 何时生效 | 典型报错关键词 |
| --- | --- | --- | --- |
| 约束层 | 禁止 any、动态属性、结构化赋值、部分 ES 动态语法 | 编译期类型检查 | arkts-no-any-unknown |
| 类型层 | 类、接口、泛型、联合与交叉类型、枚举 | 编译期 | not assignable to |
| 扩展层 | 装饰器、struct、build()、链式属性 | 编译期语法转换 | Only UI component can be used here |
| 运行层 | 单线程事件循环、Promise 微任务、并发 TaskPool | 运行期 | 无报错但界面卡死 |

**教材衔接：类型系统的三条硬规则**

第一条是「一切皆有名」：对象要有类或接口名字，匿名对象字面量只能赋给显式声明了字段的可赋值目标，且不能赋给接口类型。第二条是「判空必须落地」：`T | undefined` 与 `T | null` 是不同类型，访问成员前必须用 `if`、`??`、可选链把可空性去掉，非空断言 `!` 虽然可用但等于把风险留到运行期。第三条是「联合先收窄」：`A | B` 上只允许访问两者共有的成员，其余必须先 `instanceof` 或判别字段收窄。

```typescript
interface Shape2D {
  area(): number;
}

class RectShape implements Shape2D {
  w: number = 0;
  h: number = 0;

  constructor(w: number, h: number) {
    this.w = w;
    this.h = h;
  }

  area(): number {
    return this.w * this.h;
  }
}

class CircleShape implements Shape2D {
  r: number = 0;

  constructor(r: number) {
    this.r = r;
  }

  area(): number {
    return Math.PI * this.r * this.r;
  }
}

function describe(s: Shape2D): string {
  if (s instanceof RectShape) {
    return `rect ${s.w}x${s.h}`;
  }
  return `circle r=${s.r}`;
}
```

**教材衔接：装饰器的语法基线**

装饰器写在被标注元素的前一行，紧跟无参或小括号参数。本课只需要掌握组件侧的四个：`@Entry` 标注页面入口结构体、`@Component` 标注自定义组件、`@State` 标注组件内部状态、`@Builder` 标注轻量构建函数。它们都不是运行时函数，而是给编译器生成 UI 代码的元信息，因此位置错了不会被 TS 报错却会被 ArkTS 拒绝。

```typescript
@Entry
@Component
struct CounterPage {
  @State count: number = 0;

  aboutToAppear(): void {
    console.info('page ready');
  }

  @Builder
  label(text: string) {
    Text(text).fontSize(16).fontColor('#333333')
  }

  build() {
    Column({ space: 12 }) {
      this.label(`count = ${this.count}`)
      Button('加一').onClick(() => {
        this.count += 1;
      })
    }
    .width('100%')
    .padding(16)
  }
}
```

**教材衔接：异步与并发的心智模型**

ArkTS 主线程是单线程事件循环，`async`/`await` 只是把回调切成可读形式，并不会把工作搬到别的核上。真正要并行计算时用 `TaskPool` 提交带类型签名的任务，或用 `Worker` 起长驻线程；两者的参数与返回值都必须可序列化，闭包捕获的对象不能带方法。这条规则能解释一个常见现象：把带方法的类实例传给任务后，对端拿到的只是数据壳。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 后端 JSON 转模型 | 接口返回字符串，字段可空性未知 | 带构造函数的数据类与显式转换函数，字段缺失有默认值 |
| 把 TS 开源算法库移植到鸿蒙 | 库大量使用 any 与动态属性 | 重写类型定义、补显式接口、去掉 `with` 与动态拼装 |
| 写一个可复用组件 | 有一份父级数据与两个回调 | 组件用 `@Prop` 接收只读值、用普通函数成员回调父级 |

- 典型现象：把接口结果 `as User` 后调用 `user.fullName()` 崩溃。正确做法：定义类并写 `static fromJson()` 逐字段赋值，让方法真实存在。
- 典型现象：`if (list)` 判空后访问 `list[0]` 仍报可能未定义。正确做法：用 `if (list !== undefined && list.length > 0)` 或在声明处给默认空数组。
- 典型现象：`build()` 里写 `for (let i = 0; i < n; i++)` 编译失败。正确做法：用数组 `ForEach` 或 `Repeat` 的声明式遍历形式。

### 最小验证场景

- 准备：新建一个 Empty Ability 工程，把首页替换成本课 `CounterPage` 骨架，补一个数据类与一个 `fromJson`。
- 观察：依次制造四类错误（写 `any`、给对象加未声明属性、把字面量赋给接口、`build()` 里写普通 for 循环），记录每一条的报错文案与定位行列。
- 判定：能在不看文档的情况下把这四类错误一次改对，且 `hvigorw assembleHap` 通过，说明语言基线达标。

## 代码/协议/SQL 示例

**教材衔接：把外部数据显式建模成类**

外部数据不可信，字段可能缺失或类型漂移。用类承载模型并集中做转换，既满足 ArkTS 的有名类型要求，也把容错逻辑收在一处，页面代码只处理已经确定类型的字段。

```typescript
export class Article {
  id: string = '';
  title: string = '';
  views: number = 0;
  tags: string[] = [];

  static fromJson(raw: Record<string, Object>): Article {
    const a = new Article();
    a.id = (raw['id'] ?? '').toString();
    a.title = (raw['title'] ?? '未命名').toString();
    const n = raw['views'];
    a.views = typeof n === 'number' ? n : Number(n ?? 0);
    const t = raw['tags'];
    a.tags = Array.isArray(t) ? t.map((x: Object) => x.toString()) : [];
    return a;
  }
}
```

**教材衔接：可空性与默认值的正确写法**

可选属性在类型上就是 `T | undefined`，访问时要么用可选链与空值合并，要么在赋值处收窄。把默认值写进声明可以显著减少下游的判空分支。

```typescript
interface ProfileInput {
  nickname?: string;
  age?: number;
}

function greeting(input: ProfileInput): string {
  const name: string = input.nickname ?? '旅人';
  const age: number = input.age ?? -1;
  return age >= 0 ? `${name}，${age} 岁` : name;
}

console.info(greeting({ nickname: '阿禾', age: 26 }));
console.info(greeting({}));
```

错误表现：沿用 TS 的动态写法拼装对象，编译期直接失败，运行期也拿不到期望的方法。

```typescript
const cfg: Object = {};
(cfg as Record<string, Object>)['timeout'] = 3000;   // 动态属性受限
let total: any = 0;                                    // 禁止使用 any
total = total + 1;
```

正确写法：先把形状定义清楚，再按字段写入；数值类型显式标注，聚合逻辑交给有名函数。

```typescript
class HttpCfg {
  timeout: number = 5000;
  retry: number = 2;
}

const cfg: HttpCfg = new HttpCfg();
cfg.timeout = 3000;
let total: number = 0;
total += 1;
```

## 时间/空间复杂度或性能分析

| 关注点 | 语言层原因 | 对界面性能的影响 | 写法建议 |
| --- | --- | --- | --- |
| 对象布局固定 | 无动态属性，字段在编译期确定 | 内存分配更快，GC 压力更可控 | 少建短命对象，复用容器 |
| 类型收窄成本 | 判别在编译期完成，运行期仅 instanceof | 分支开销可忽略 | 优先用类型判别而非字符串比较 |
| 大数组遍历 | `ForEach` 每项生成组件实例 | 首帧耗时随条目线性上升 | 列表用懒加载容器，键稳定 |
| 深拷贝模型 | 类实例方法不能序列化传递 | 任务池边界处转换成本高 | 边界处转成扁平数据 |
| 闭包捕获 | `build()` 中过多闭包增加重建面 | 状态变化时刷新范围扩大 | 把纯计算挪出 UI 描述 |

语言约束本身就是性能设计的一部分。由于对象形状在编译期确定，ArkTS 里频繁「造一个空对象再往里塞字段」的模式被禁止，客观上推动了显式建模，代价是转换代码变多；收益是渲染时的属性读取路径固定，组件 diff 只需比较已知字段。写大数据集时要特别注意：把一次全量转换放在页面构建路径上，会让首帧时间随数据量线性增长，正确做法是分批转换并在滚动时补齐。

从空间角度看，类实例比纯字面量多一个原型指针，但少了运行期隐藏类（shape）的碎片化，整体更可预测。需要缓存大量结构一致的小对象时，用数组或 `Map` 承载实例、把常量抽成类字段，比给每条记录都造一份配置省内存得多。

语言层的选择还会传导到启动与帧率。ArkTS 在构建期把静态类型信息编译成字节码，类型越确定，运行期需要做的形状检查越少，能力初始化阶段的耗时也就越稳定；反过来使用宽泛类型会把成本推迟到访问点。帧率方面，动态属性风格的写法往往意味着每次写入都触发一次对象重建，在列表滚动时会被逐帧放大。包体角度则是另一向收益：静态化让编译器更容易做无用代码剔除与常量折叠，未走到的分支更可能被剪掉，把建模写规范通常还能小幅减小产物体积。

## 常见误区与易错点

- **把 ArkTS 当 TS 直接搬。** `any`、动态属性、结构化赋值、部分反射写法都会被编译期拦下，移植要预留改造时间。
- **用 `as` 当类型转换器。** `as` 只做兼容断言，不会给对象补上类方法，接口返回数据必须显式构造实例。
- **误用对象字面量。** 匿名对象字面量不能赋给接口类型，需要先有类或改成有名字的构造。
- **判空只写一半。** `T | undefined` 与 `T | null` 是不同分支，`!= null` 之类宽松比较不覆盖全部可空情形。
- **非空断言满天飞。** `!` 把检查推迟到运行期，崩溃时栈上不会留类型线索，只适合确实不可能为空的场景。
- **联合类型直接访问分支成员。** 必须先用 `instanceof` 或判别字段收窄，否则编译报属性不存在。
- **装饰器位置写错。** `@State` 只能标注自定义组件的成员变量，写在普通类或全局上不生效。
- **`build()` 里塞命令式语句。** 只允许 UI 描述、组件成员调用与有限的控制语句，副作用应放生命周期回调。
- **以为 await 就是多线程。** `async`/`await` 仍在主线程，重计算要交给 TaskPool 或 Worker，且传参要可序列化。
- **忽略枚举与常量的类型。** 混用字符串枚举与字面量比较会导致分支不命中，应显式标注类型再比较。

## 与其他知识点的关系

**教材衔接：与其他语言课程的迁移提示**

已经会 TypeScript 的人，本课内容 80% 是「减法式」的提醒；已经会 Kotlin 或 Swift 的人，则会发现大量规则似曾相识——可空性显式化、禁止结构化赋值、编译期确定对象布局，都是同一类工程取舍。真正的增量只有装饰器与 `build()` 的声明式描述，那部分属于 ArkUI 而非语言本身。

- 向上承接 `harmonyos_deveco_setup`：所有语法验证都要在能编译通过的工程里做。
- 向下支撑 `harmonyos_arkui_first_page`：`build()` 的合法语句边界是 UI 课的地基。
- 向下支撑 `harmonyos_state_management`：装饰器的位置与可观察能力直接决定刷新是否生效。
- 平行对照 `kotlin_null_safety`：可空类型与收窄思路几乎可以逐条映射。
- 平行对照 `typescript_type_system`：相同语法、不同约束强度，迁移时按禁令清单逐条核对。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_arkui_first_page | ArkUI 首个页面 | 该课的组件描述建立在本课的 struct 与装饰器骨架之上 |
| harmonyos_state_management | 状态管理与数据传递 | 可观察对象与深度更新的前提是类实例建模正确 |
| harmonyos_network_data | 网络、数据与文件 | 接口返回的 JSON 在该课落地为本课定义的模型类 |
| typescript_type_system | TypeScript 类型系统 | 同一套类型语法的不同约束强度，便于对照记忆 |
| kotlin_null_safety | Kotlin 空安全 | 可空类型与收窄策略高度同构，可互相迁移 |

## 自测题与参考答案

**教材衔接：题号 1** — ArkTS 相对 TypeScript 最主要的收紧体现在哪一点？

**参考答案**：强制静态类型并限制动态特性。

本题正确项是「强制静态类型并限制动态特性」。ArkTS 保留 TypeScript 的语法外壳，但取消 any 与隐式 any、禁止给对象动态增删属性、限制结构等价赋值，目的是让编译器在编译期确定对象布局与方法表，从而支撑 AOT 与稳定的运行期性能。泛型与接口仍然存在，类与模块系统是最基础的语法单元，函数写法也没有被强制成某一种形式，三项都不是收紧点。

**教材衔接：题号 2** — 下列哪种做法符合 ArkTS 的对象建模规范？

**参考答案**：显式声明接口再实现方法。

本题正确项是「显式声明接口再实现方法」。先给对象形状命名，再用类实现行为，字段与方法都在编译期可查，这是 ArkTS 推荐的建模路径。给已有类型的对象追加新属性、用字符串键动态索引取值都触碰动态特性禁令；把匿名对象字面量直接赋给接口类型也不被结构化赋值规则允许，需要先构造有名字的类实例再传递。

**教材衔接：题号 3** — 需要把接口返回的 JSON 文本转成带方法的模型对象，ArkTS 推荐做法是？

**参考答案**：用类承载并逐字段赋值。

本题正确项是「用类承载并逐字段赋值」。在静态约束下方法必须来自真实的类原型，集中写一个转换函数还能顺带完成默认值兜底与字段容错。类型断言只做兼容检查，不会给对象补出方法，缺字段要到访问时才暴露；动态求值一类写法本就被禁用；跨语言边界类型只该出现在与原生交互的入口，把它当类型传进界面层等于放弃编译期检查。

**教材衔接：题号 4** — `@State` 装饰器允许标注在什么位置？

**参考答案**：自定义组件的成员变量上。

本题正确项是「自定义组件的成员变量上」。`@State` 表示组件内部可观察状态，编译器会在被标注的自定义组件内生成读写拦截逻辑，因此只能出现在组件成员变量声明处。写在全局常量、普通类成员或函数局部变量上都不会产生可观察效果，跨组件同步要改用单向或双向绑定装饰器，跨页面共享则交给应用级状态容器。

**教材衔接：题号 5** — 下面代码的输出是？
class Dog { bark(): string { return 'woof'; } }
class Cat { meow(): string { return 'meow'; } }
function speak(a: Dog | Cat): string {
  if (a instanceof Dog) { return a.bark(); }
  return a.meow();
}
console.info(speak(new Cat()));

**参考答案**：输出 meow。

本题正确项是「输出 meow」。入参声明为联合类型，`instanceof` 把 if 分支收窄到 Dog，else 分支自动收窄为 Cat，因此调用 Cat 独有方法是合法写法；实参传入的正是 Cat 实例，所以打印 meow。换成 Dog 实参才会走前一分支得到 woof；这段代码符合联合类型收窄规则，不会在编译期被拒绝，也不存在运行期找不到方法的异常路径。

## 考点精讲

**教材衔接：高频考点**

1. ArkTS 禁令清单：any、动态属性、结构化赋值、动态求值四类，是判断题与排错题的母题。
2. 接口返回数据的建模方式：类加显式转换，而不是断言或字面量硬套。
3. 可空类型与类型收窄：判空必须落到具体分支，`!` 属于风险转移。
4. 装饰器的位置约束与 `build()` 的合法语句范围。

**教材衔接：命题规律**

- 概念题喜欢问「最主要的收紧」，正确项一定是可解释编译期收益的那一条，而不是表面语法差异。
- 代码题常给一段联合类型或判空代码，答案落在「能否通过编译」与「实际打印什么」二者之一。
- 排错题把 TS 常见写法原样搬来，考的是禁令清单的记忆准确度。

**教材衔接：常见考点**

问：ArkTS 相对 TypeScript 最主要的收紧体现在哪一点？
答：强制静态类型并限制动态特性。

问：下列哪种做法符合 ArkTS 的对象建模规范？
答：显式声明接口再实现方法。

问：需要把接口返回的 JSON 文本转成带方法的模型对象，ArkTS 推荐做法是？
答：用类承载并逐字段赋值。

问：`@State` 装饰器允许标注在什么位置？
答：自定义组件的成员变量上。

问：下面代码的输出是？
class Dog { bark(): string { return 'woof'; } }
class Cat { meow(): string { return 'meow'; } }
function speak(a: Dog | Cat): string {
  if (a instanceof Dog) { return a.bark(); }
  return a.meow();
}
console.info(speak(new Cat()));
答：输出 meow。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 强制静态类型 | 所有声明都要能推出确定类型，禁止 any 与隐式 any。 |
| 动态属性禁令 | 不能给已有类型的对象追加或删除字段，形状在编译期固定。 |
| 结构化赋值限制 | 类型不同即使字段兼容也不能互相赋值，必须显式转换。 |
| 联合类型 | 用竖线并列多种类型表达多态取值，访问成员前必须收窄。 |
| 类型收窄 | 用 instanceof、判空或字面量比较把类型缩到可用范围。 |
| 装饰器 | 写在 struct、成员或方法前的元信息语法，如 @Component。 |
| struct | ArkUI 组件的声明载体，必须实现 build() 描述界面。 |
| TaskPool | 主线程之外的任务并发能力，参数与返回值需可序列化。 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-11-10
- 学习阶段：移动
- 适用环境：DevEco Studio NEXT / HarmonyOS API 12+；真机需 HarmonyOS 4/5 NEXT；构建产物为 HAP/HSP/AppPack
- 内容来源：华为官方文档与工程实践整理
- 相关主题：ArkTS、ArkUI、分布式软总线、上架 AppGallery

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-11-10
- [HarmonyOS NEXT 开发者官网](https://developer.huawei.com/consumer/cn/harmonyos-next/)
- [ArkTS 语言介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts)
- [ArkTS 语法适配与限制说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/typescript-to-arkts-migration-guide)
- [装饰器使用说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-decorators)
- [并发与 TaskPool 开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/concurrency-overview)
