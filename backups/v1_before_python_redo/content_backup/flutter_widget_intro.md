# Flutter Widget 入门

> 内容更新时间：2026-10-06 · 学习阶段：intermediate · 预计用时：45 分钟

![Flutter Widget 树结构示意图](images/diagram_mobile_flutter_widget.webp)

## 本节知识框架

欢迎来到 Flutter Widget 的世界！如果你用过乐高积木，那 Widget 对你来说就很好理解了——每一个小积木块就是一个 Widget，你把它们拼在一起，就搭出了整个界面。本课会带你从零开始，搞清楚 Widget 到底是什么、build 方法在干什么、以及一个最小的 Flutter 应用长什么样。

**学习目标**

- 理解 Widget 和 Widget 树的含义，能用自己的话解释给小伙伴听
- 跑通本课的最小示例，看到屏幕上出现 "Hello Flutter"
- 分清 StatelessWidget 和 StatefulWidget 的差别，知道什么时候该用哪个
- 遇到「build 里发请求导致界面卡死」这类问题，能说清原因并修复

**前置基础**

- 了解 Dart 语言基本语法（变量、函数、类）
- 电脑上已经装好 Flutter SDK，能运行 `flutter doctor`
- 对「声明式 UI」有模糊印象就够了，没接触过也没关系

**复习清单**

- [ ] 能不看正文说出 Widget、build、StatelessWidget、StatefulWidget 分别是什么
- [ ] 能独立运行本课的最小示例，并修改文本内容观察变化
- [ ] 能完成自测题和考点精讲，把错题对照误区表找到原因

## 核心概念定义

先快速认识几个核心术语，后面会反复遇到它们：

| 术语 | 一句话说明 |
| --- | --- |
| Widget | Flutter 界面的基本积木块，你用不可变的配置描述界面的一部分 |
| Widget 树 | 所有 Widget 按父子关系拼成的树形结构，就像家谱一样层层嵌套 |
| 约束（Constraints） | 父 Widget 告诉子 Widget「你最大能多大、最小得多小」的尺寸范围 |
| build 方法 | 每个 Widget 的核心方法，负责根据当前状态返回这一帧的界面描述 |
| StatelessWidget | 没有可变状态的 Widget，同样的输入永远得到同样的输出，像一张照片 |
| StatefulWidget | 带可变状态的 Widget，状态改变后调用 setState 触发界面重建，像一块可擦写的白板 |

## 原理与运行机制

### 像乐团一样的 Flutter

想象你是一个乐团的指挥（也就是 Flutter 框架），手里拿着一份乐谱（Widget 配置）。你不需要自己去吹拉弹唱——你只需要告诉每个乐手（渲染引擎）该演奏什么。每次乐谱变了，你就更新对应的部分，不用让整个乐团从头来过。

在 Flutter 里，你写的每一个 Widget 就像乐谱上的一个音符。你把它们组合在一起，形成一棵 Widget 树。框架拿着这棵树，去跟上一帧的树做比较，只把变化的部分更新到屏幕上。这个过程叫做「差异化重建」，听起来很高级，其实核心思想就是：别做无用功。

### build 方法到底在干什么？

很多初学者以为 `build` 方法是「把东西画到屏幕上」，其实不是。`build` 方法只是「描述这一帧应该长什么样」——它返回一份 Widget 配置清单，真正的绘制工作由框架在底层完成。

打个比方：你去餐厅点菜，你写的菜单就是 `build` 的返回值。厨房（框架）拿到菜单后才开始做菜。你不会跑到厨房里自己炒菜，对吧？

```text
你写的代码            Flutter 框架             屏幕
   │                      │                    │
   │  Widget 配置          │                    │
   ├─────────────────────>│                    │
   │  (描述"要什么")        │  比较新旧两棵树     │
   │                      ├───────────────>│   │
   │                      │  只更新差异部分     │
   │                      │<───────────────│   │
   │                      │  渲染到屏幕       │   │
   │                      ├───────────────────>│
```

### 布局是怎么工作的？

Flutter 的布局规则用一句话就能概括：约束向下传，尺寸向上报，父决定位置。

就像整理书架：你（父 Widget）给每一层定一个高度范围（约束），书（子 Widget）在这个范围内选择自己的厚度（尺寸），最后你决定每本书放在层的哪个位置。

### 状态和重建

StatelessWidget 就像一张照片——拍好了就不会变，每次看都是同一个样子。StatefulWidget 则像一块白板——你可以随时用 `setState` 擦掉旧内容、写上新内容，框架看到变化后会自动重新「拍照」显示。

关键点：需要跨帧保留的数据要放在 `State` 类里，不要直接存在 Widget 的字段里，否则重建时状态就丢了。

## 典型应用场景

学了这些概念，实际什么时候用呢？来看几个常见场景：

- **纯展示组件**：一段文字标签、一个图标、一条分割线——这些不需要变化的界面用 StatelessWidget 就够了。比如 `Text('Hello')`、`Icon(Icons.home)` 都是典型的无状态组件。
- **计数器、表单、开关**：需要响应用户操作、内容会变化的场景，用 StatefulWidget。比如点击按钮数字加一，或者输入框里的文字随用户打字实时更新。
- **最小应用骨架**：每个 Flutter App 都需要一个 `main` 函数和 `runApp`，再加上 `MaterialApp`、`Scaffold` 这些基础 Widget 来搭建骨架。这就像盖房子先打地基——不管房子后面装修成什么样，地基的结构是固定的。
- **列表和滚动**：显示一长串数据时用 `ListView`，它只会构建屏幕上看得见的部分（懒加载），不会一次性把所有内容都塞进内存，就像你翻通讯录时不需要把所有人的照片都加载出来。

## 代码/协议/SQL 示例

### 最小可运行示例

这是你能写出的最简单的 Flutter 应用，保存为 `.dart` 文件放到 Flutter 工程的 `lib/` 目录下即可运行：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Hello Flutter')),
      ),
    ),
  );
}
```

运行后，屏幕中央会显示一行文本：Hello Flutter。

逐行解读一下这段代码在做什么：

- `import 'package:flutter/material.dart'`：引入 Material Design 风格的组件库，就像打开一箱乐高积木。
- `void main()`：程序入口，Dart 和很多语言一样，从 `main` 函数开始执行。
- `runApp(...)`：把根 Widget 挂载到 Flutter 引擎上，相当于告诉系统「开始渲染吧」。
- `MaterialApp`：Material 风格的应用容器，提供了主题、导航等基础能力。
- `Scaffold`：页面骨架，自带 AppBar、Body 等常见布局区域。
- `Center`：让子组件居中显示。
- `Text('Hello Flutter')`：显示一段文字，内容就是 `'Hello Flutter'`。

### 渐进示例一：给文本加上样式

在最小示例的基础上，我们给文字加点样式，让它更好看：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Hello Flutter',
            style: TextStyle(fontSize: 28, color: Colors.blue),
          ),
        ),
      ),
    ),
  );
}
```

这段代码和最小示例的区别只在 `Text` 组件里多了一个 `style` 参数。`TextStyle` 让你控制字号、颜色、字体等外观属性。运行后你会看到屏幕中央显示一行蓝色的大号文字。

### 渐进示例二：加入按钮和状态

现在让界面「活」起来——加一个按钮，点击后计数器加一。这就需要用到 StatefulWidget 了：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: CounterApp()));
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计数器')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('当前计数：$_count', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: const Text('点我加一'),
            ),
          ],
        ),
      ),
    );
  }
}
```

这个例子展示了 StatefulWidget 的核心用法：

- `_count` 存在 `State` 类里，而不是 Widget 里——这样重建时值不会丢。
- 点击按钮时调用 `setState(() => _count++)`，告诉框架「状态变了，请重新 build」。
- `build` 方法根据最新的 `_count` 值生成新的 Widget 描述，框架自动更新屏幕。

### 渐进示例三：体验一下 StatelessWidget

再看一个纯展示的场景——一个显示用户信息的卡片，数据从构造参数传进来：

```dart
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String name;
  final int age;

  const UserCard({super.key, required this.name, required this.age});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$name, $age 岁'),
      ),
    );
  }
}
```

`UserCard` 是 StatelessWidget——只要 `name` 和 `age` 确定了，它显示的内容就确定了。如果数据要变，父 Widget 会创建一个新的 `UserCard` 实例，而不是修改旧的。

## 时间/空间复杂度或性能分析

很多新手担心「频繁重建 Widget 会不会很卡」？其实不用太担心。Widget 本身非常轻量——它只是一个配置描述，不是真正的渲染对象。框架在底层做了大量优化，只更新真正变化的部分。

真正影响性能的是这几件事：

- **重建范围过大**：如果把状态放在很高的位置（比如整个 App 的根部），一次 `setState` 会导致大量 Widget 重建。解决办法是把状态尽量放在靠近使用它的地方。
- **build 方法里做重活**：`build` 方法可能被频繁调用，不要在里边做网络请求、数据库查询或复杂计算。这些操作应该放在 `initState` 或单独的服务层。
- **图片解码**：大图解码是常见的性能杀手，使用 `cached_network_image` 等库做缓存和解码优化。
- **列表没有懒加载**：用 `ListView.builder` 代替直接放一Column 子组件，只构建看得见的部分。

测量性能可以用 Flutter DevTools 的 Performance 面板，先看帧时间有没有异常尖峰，再针对性优化，不要凭感觉猜测瓶颈在哪。

## 常见误区与易错点

| 错误 | 现象 | 修法 |
| --- | --- | --- |
| 在 build 里发网络请求或改状态 | 每帧重复触发，界面疯狂闪烁甚至死循环 | 初始化逻辑放 initState 或数据层，build 只负责描述界面 |
| 把可变状态存在 Widget 字段里 | 重建后状态丢失或显示错乱 | 需要跨帧保留的状态放 State 类或状态管理容器 |
| setState 只更新了一部分字段 | 界面显示旧数据，看起来像没刷新 | 在 setState 回调里一次性更新所有相关字段 |
| 用 StatelessWidget 却想修改内部数据 | 编译器报错，因为 final 字段不能改 | 换成 StatefulWidget，把可变数据放 State 里 |
| 全局状态放太高导致整棵树重建 | 每次小改动都触发大量重建，界面卡顿 | 把状态下沉到真正需要它的子组件 |

重点说说第一个误区，因为它最容易让初学者崩溃。`build` 方法在每次需要刷新界面时都会被调用——如果用户在滑动屏幕，一秒钟可能调用几十次。如果你在 build 里写了 `http.get(...)` 或者 `setState(...)`，那就相当于每次刷新都重新发一次请求或触发一次新刷新，形成无限循环。记住：build 只「描述」界面，不「执行」副作用。

## 与其他知识点的关系

本课的知识点是一条链子的起点，后续很多概念都会建立在它之上：

- **Widget → Widget 树**：单个 Widget 是积木块，多个 Widget 按父子关系拼成 Widget 树。框架沿着这棵树向下传约束、向上收尺寸。
- **Widget 树 → 约束（Constraints）**：理解了树的结构，才能理解约束是怎么在节点之间传递的。
- **StatelessWidget → StatefulWidget**：先掌握「没有状态」的简单情况，再理解「有状态」的复杂情况。StatefulWidget 本质上就是 StatelessWidget 加了一个可以变化的 State 对象。
- **StatefulWidget → Future**：当你在 StatefulWidget 里需要加载网络数据时，就会遇到 Future 和 async/await。

与本课直接衔接的后续内容是《Flutter 布局入门》，那里会深入讲解 Row、Column、Stack 等布局 Widget 的具体规则。术语定义以本课为准，到了后续课程如果发现同一个词有不同含义，记得回来对照。

## 自测题与参考答案

> 先独立作答，再对照参考答案。每道题的答案都能在正文或误区表里找到依据。

### 自测 1：概念复述

不看正文，用自己的话写出 Widget 是什么，并说明 Widget 树是怎么形成的。

**参考答案**：Widget 是 Flutter 界面的基本构建单元，你用不可变的配置来描述界面的一部分。就像乐高积木一样，每个 Widget 描述界面的一小块，把它们按父子关系拼在一起就形成了 Widget 树。

### 自测 2：运行结果

运行本课的最小示例后，屏幕上会显示什么？如果我把 `Center` 去掉，结果会怎么变？

**参考答案**：屏幕中央显示一行文本 Hello Flutter。如果去掉 `Center`，文本会出现在左上角（Scaffold 的 body 默认从左上角开始布局）。

### 自测 3：排错练习

本课误区表记录了「在 build 里发网络请求」这个错误。请描述它会出现的现象、根因和修复方法。

**参考答案**：现象是每帧重复触发请求，界面疯狂闪烁甚至死循环。原因是 build 方法会被反复调用，不适合放副作用代码。修复方法是把网络请求放在 `initState` 或单独的数据层，build 只负责根据已有数据描述界面。

### 自测 4：代码阅读

阅读本课的计数器示例，说明为什么 `_count` 要放在 `_CounterAppState` 里而不是 `CounterApp` 里。

**参考答案**：因为 `CounterApp` 是 StatefulWidget，它的实例是不可变的配置对象。每次状态变化时，框架会创建新的 Widget 实例，但 State 对象会保留。如果把 `_count` 放在 Widget 里，重建时值就丢了。放在 State 里才能跨帧保留。

## 考点精讲

下面 6 道题覆盖了本课的核心知识点。先自己作答，再核对答案，最后回到正文对应部分复习。

### 考点 1

题目：Flutter 中 build 方法的核心职责是什么？
A. 根据当前状态描述这一帧要显示的 Widget 结构
B. 直接调用底层图形接口把像素画到屏幕上
C. 负责在后台线程里下载并缓存网络图片
D. 把 Dart 代码编译成各平台的原生机器码
正确答案：A

**解析**：build 方法只负责「描述」——根据当前状态返回这一帧的 Widget 配置。它不会直接绘制像素（那是渲染引擎的工作），不会下载图片（那是网络层的工作），也不会编译代码（那是编译器的工作）。记住：build 是写菜单，不是下厨房。

### 考点 2

题目：下面这段 `dart` 代码来自 `Flutter Widget 入门`。课程主线是理解 Widget、build 和最小应用结构。代码与 `Widget` 有关。哪一项是代码里真实出现的内容？
A. 出现字面量 `123`
B. 出现字面量 `Hello Flutter`
C. 出现字面量 `Evaluation`
D. 出现字面量 `收集一个可执行文件的基础诊断信息。`
正确答案：B

**解析**：回到最小示例，`Text('Hello Flutter')` 里出现了字面量 `Hello Flutter`。代码里没有数字 `123`，没有 `Evaluation`，也没有中文长句。做这类题最好的办法就是回原文逐行核对。

### 考点 3

题目：StatelessWidget 与 StatefulWidget 最本质的差别是？
A. StatefulWidget 不能在 const 构造中使用
B. StatefulWidget 通过 State 保存可变状态并触发重建
C. StatelessWidget 无法接收构造参数和子 Widget
D. StatelessWidget 的 build 只会执行一次
正确答案：B

**解析**：本质差别在于状态的有无。StatelessWidget 没有可变状态，同样的输入永远得到同样的输出。StatefulWidget 通过 State 对象保存可变状态，调用 `setState` 后框架会重新 build。A 不是本质差别，C 是错的（StatelessWidget 可以接收参数和子 Widget），D 也是错的（build 可以被多次调用）。

### 考点 4

题目：运行本课最小示例后，屏幕上会看到什么？
A. 屏幕中央显示一行文本 Hello Flutter
B. 左上角显示一行文本 Hello Flutter
C. 依次显示文本、按钮和输入框三个组件
D. 只显示蓝色背景，没有任何文字
正确答案：A

**解析**：最小示例中 `Center` 包裹了 `Text('Hello Flutter')`，所以文本会居中显示。B 不对是因为有 `Center`；C 不对是因为示例里只有文本，没有按钮和输入框；D 不对是因为确实有文字内容。

### 考点 5

题目：填空：补齐下面这段术语说明中的空缺。课程 `理解 Widget、build 和最小应用结构。`，这段说明是：`____`：带可变状态的 Widget，状态改变后用 setState 触发重建。空缺处应填哪个术语？
正确答案：StatefulWidget

**解析**：看到「带可变状态」和「setState 触发重建」这两个关键词，就能确定答案是 StatefulWidget。这是本课最核心的术语之一。

### 考点 6

题目：关于 `Widget`，下列哪些说法与 `Flutter Widget 入门` 的正文一致？判断时以理解 Widget、build 和最小应用结构。为主线。（多选）
A. 根据当前状态描述这一帧要显示的 Widget 结构
B. main 是程序入口，runApp 把根 Widget 挂载到引擎
C. 直接调用底层图形接口把像素画到屏幕上
D. 负责在后台线程里下载并缓存网络图片
正确答案：AB

**解析**：A 正确——这正是 build 方法的核心职责，也是 Widget 配置描述的本质。B 正确——最小示例中 `main` 是入口函数，`runApp` 负责把根 Widget 交给引擎。C 错误——Widget 不直接操作底层图形接口，那是渲染引擎的事。D 错误——Widget 不负责下载和缓存网络图片。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| Widget | Flutter 界面的基本积木块，用不可变配置描述界面的一部分 |
| Widget 树 | 所有 Widget 按父子关系组成的树形结构 |
| build | 每个 Widget 的核心方法，返回当前帧的界面描述 |
| State | StatefulWidget 的状态对象，保存跨帧的可变数据 |
| setState | 通知框架状态已变化，触发 Widget 重新 build |
| const 构造 | 编译期创建不可变对象，减少不必要的重建开销 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：intermediate
- 适用环境：Flutter 3.x / Dart 3.x
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Flutter Widget 入门、移动开发、入门练习

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：Widget 机制、布局规则、状态管理、性能优化

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter Widget 文档](https://docs.flutter.dev/ui/widgets) | Widget 基础与分类 |
| [Dart 语言指南](https://dart.dev/guides) | Dart 语法基础 |
| [Flutter Widget 库 API](https://api.flutter.dev/flutter/widgets/widgets-library.html) | Widget API 查询 |
