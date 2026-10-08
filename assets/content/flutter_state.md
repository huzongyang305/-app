# Flutter 状态管理与性能

> 内容更新时间：2026-10-06 · 学习阶段：入门 · 预计用时：50 分钟

![状态分层与重建范围](images/diagram_mobile_flutter_state.webp)

![Flutter 状态管理与性能](images/category_flutter_state.webp)

## 本节知识框架

**课程定位**：所属分类为「移动开发」，课程主题为「Flutter 状态管理与性能」，学习阶段为「入门」，建议用时 50 分钟。

**本课要解决的主问题**：状态分层、重建范围控制与生命周期陷阱。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Flutter 状态管理与性能」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Flutter 状态管理与性能」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Flutter」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Flutter 基础与 Widget 树》

**学习位置**：本课位于《Flutter 基础与 Widget 树》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Flutter 布局入门》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Flutter 状态管理与性能解决了什么问题，而不是只背术语。
- 能说清 「Flutter」、「状态管理」、「Provider」、「性能」 之间的关系，并分别举出一个例子。
- 能把 Flutter 放回「Flutter 状态管理与性能」的知识体系，说明它和 状态管理 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：状态分层、重建范围控制与生命周期陷阱。

**教材衔接：前置知识**

- 先完成上一课《Flutter 基础与 Widget 树》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。建议先完成「Flutter 基础与 Widget 树」，或确认自己能独立跑通正文里的 ChangeNotifierProvider 示例。
- 开始前先复习：Flutter、状态管理、Provider。
- 卡在 Flutter 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

Flutter 状态管理的核心是**分层与最小重建**：局部用 setState、共享用 Provider/Riverpod、服务端数据走仓库层；再配合 const、Selector 与 RepaintBoundary 控制性能。

## 核心概念定义

> 阅读约定：本课先给「Flutter 状态管理与性能」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Flutter | Flutter 状态管理的核心是分层与最小重建：局部用 setState、共享用 Provider/Riverpod、服务端数据走仓库层；再配合 const、Selector 与 RepaintBoundary 控制性能。 | 仅在「Flutter 状态管理与性能」明确给出的输入、版本与资源条件下成立。 |
| 状态管理 | 集中或按作用域组织应用状态，并控制读取、更新与生命周期。 | 仅在「Flutter 状态管理与性能」明确给出的输入、版本与资源条件下成立。 |
| 性能 | 系统在给定负载下表现出的吞吐、延迟、资源占用和稳定性。 | 仅在「Flutter 状态管理与性能」明确给出的输入、版本与资源条件下成立。 |
| 生命周期 | 引用保持有效的区间；在 Rust 中还用于把多个引用的有效期关系写进类型。 | 仅在「Flutter 状态管理与性能」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Flutter 状态管理与性能」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Flutter」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「状态管理」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「性能」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Flutter 状态管理与性能」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Flutter | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 状态管理 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 性能 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Flutter 状态管理与性能」自己的示例验证。「Flutter 状态管理与性能」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：状态分层**

| 类型 | 例子 | 推荐方案 |
| --- | --- | --- |
| 局部 UI 状态 | 输入框内容、开关、动画 | StatefulWidget + setState |
| 跨页面共享 | 登录用户、主题、购物车 | Provider / Riverpod / Bloc |
| 服务端数据 | 列表、详情、分页 | 仓库层 + FutureBuilder/AsyncNotifier + 缓存 |

选型原则：**能局部就不全局**。全局状态越少，重建范围越小、越容易测试。Provider 适合中小项目（ChangeNotifier + Consumer），Riverpod 编译期安全、便于测试，Bloc 适合复杂业务与团队规范要求高的场景。

**教材衔接：重建范围控制**

1. 用 `const` 构造器避免无谓重建。
2. `Consumer`/`Selector` 只包裹真正依赖该状态的子树，而不是整页。
3. 长列表用 `ListView.builder` + `itemExtent`（已知行高时）减少布局计算。
4. 复杂动画或频繁重绘区域用 `RepaintBoundary` 隔离。
5. 避免在 build 里做重活（排序、网络、JSON 解析），移到 initState 或状态层。

**教材衔接：生命周期要点**

`initState` 做一次初始化（注意不能在这里用 context 依赖），`didChangeDependencies` 响应依赖变化，`dispose` 释放控制器、订阅与定时器。**忘记 dispose 是内存泄漏的常见来源**（AnimationController、TextEditingController、StreamSubscription）。

**教材衔接：异步与错误处理**

用 FutureBuilder 时务必处理三种状态：等待、错误、空数据；页面卸载后不要再 setState（用 `if (!mounted) return;`）。分页加载要注意去重与并发请求的竞态（后发先至）。

**教材衔接：状态分类速查**

| 状态类型 | 生命周期 | 推荐方案 |
| --- | --- | --- |
| 局部 UI 状态 | 单页面 | `StatefulWidget` + `setState` |
| 跨组件共享 | 多个页面 | Provider / Riverpod |
| 全局配置 | 应用级 | Provider + 持久化 |
| 派生状态 | 由其他状态计算 | 直接计算，不额外存 |
| 异步数据 | 网络请求 | `FutureBuilder` 或状态管理的异步封装 |

**教材衔接：生命周期速查**

| 阶段 | 时机 | 典型用途 |
| --- | --- | --- |
| `initState` | 组件插入树后 | 初始化控制器、首次请求 |
| `didChangeDependencies` | 依赖变化 | 读取 `InheritedWidget` 或主题 |
| `build` | 每次需要渲染 | 只做构建，不放副作用 |
| `didUpdateWidget` | 父级传入参数变化 | 对比新旧参数做响应 |
| `dispose` | 组件移除 | 取消订阅、释放控制器 |
| `deactivate` | 从树中暂时移除 | 少见，谨慎使用 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Flutter、状态管理 | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Flutter 状态管理与性能」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Flutter 状态管理与性能」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Flutter 状态管理与性能》原文中的最小示例。先预测《Flutter 状态管理与性能》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```dart
// 1. 状态：继承 ChangeNotifier，只在数据变化时通知
class CartProvider extends ChangeNotifier {
  final List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void add(Item item) {
    _items.add(item);
    notifyListeners();          // 只在这一处通知
  }
}

// 2. 注入：在应用根部提供
MultiProvider(providers: [
  ChangeNotifierProvider(create: (_) => CartProvider()),
]);

// 3. 消费：只包裹真正依赖的子树
Consumer<CartProvider>(
  builder: (context, cart, child) => Text('合计 ${cart.total}'),
);

// 4. 只读不监听（事件回调里用，避免无谓重建）
context.read<CartProvider>().add(item);
```

**教材衔接：Provider 代码骨架**

```dart
// 1. 状态：继承 ChangeNotifier，只在数据变化时通知
class CartProvider extends ChangeNotifier {
  final List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void add(Item item) {
    _items.add(item);
    notifyListeners();          // 只在这一处通知
  }
}

// 2. 注入：在应用根部提供
MultiProvider(providers: [
  ChangeNotifierProvider(create: (_) => CartProvider()),
]);

// 3. 消费：只包裹真正依赖的子树
Consumer<CartProvider>(
  builder: (context, cart, child) => Text('合计 ${cart.total}'),
);

// 4. 只读不监听（事件回调里用，避免无谓重建）
context.read<CartProvider>().add(item);
```

四条实践规则：**状态类只暴露只读视图**（`List.unmodifiable`）、**notifyListeners 只在数据真变化时调用**、**读用 read、听用 watch/Consumer**、**Selector 只订阅需要的字段**（如只关心 total 而不是整个 cart）。

**教材衔接：测试策略**

状态类不依赖 Widget，可直接单测：构造 Provider → 调用方法 → 断言状态与通知次数（用 `addListener` 计数）。Widget 测试中通过 `ChangeNotifierProvider.value` 注入假数据，避免真实网络与数据库。

**教材衔接：零基础详解：状态管理与重建范围**

### 一句话说清它是什么

状态管理要回答两个问题：**这份状态归谁管**、**变化时要重建哪一部分**。
能局部就不全局，能小范围就不整页刷新，这是 Flutter 性能与可维护性的核心。

### 用生活比喻理解

| 类型 | 比喻 | 例子 |
| --- | --- | --- |
| 局部状态 | 桌上的便签 | 输入框内容、开关状态 |
| 页面状态 | 房间里的白板 | 列表数据、加载中 |
| 全局状态 | 公司公告栏 | 登录信息、主题、购物车 |
| 临时状态 | 手里的草稿纸 | 动画进度、滚动位置 |

### 三层选型

| 范围 | 方案 | 说明 |
| --- | --- | --- |
| 单个组件 | `StatefulWidget` + `setState` | 最简单，重建范围最小 |
| 父子共享 | 回调 + `ValueNotifier` | 不必引入框架 |
| 跨页面共享 | Provider / Riverpod | 需要统一读写与生命周期 |

### Provider 的三件套

```dart
// 1. 定义可监听模型
class CartModel extends ChangeNotifier {
  final List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (sum, i) => sum + i.price);

  void add(Item item) {
    _items.add(item);
    notifyListeners();          // 通知订阅者重建
  }
}

// 2. 在顶层提供
ChangeNotifierProvider(
  create: (_) => CartModel(),
  child: const MyApp(),
)

// 3. 按需读取
class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartModel, int>((m) => m.items.length);
    return Badge(label: Text('$count'), child: const Icon(Icons.shopping_cart));
  }
}
```

`context.select` 只订阅需要的字段，**只有这个字段变化才重建**。

### 三个缩小重建范围的技巧

```dart
// 技巧一：把 Consumer 包到最小范围
Consumer<CartModel>(
  builder: (context, cart, child) => Text('${cart.items.length}'),
)

// 技巧二：child 参数复用不依赖状态的部分
Consumer<CartModel>(
  builder: (context, cart, child) => Row(
    children: [child!, Text('${cart.total}')],
  ),
  child: const Icon(Icons.shopping_cart),   // 不会重建
)

// 技巧三：读取不订阅，用 read
onPressed: () => context.read<CartModel>().add(item),
```

| 方法 | 是否订阅 | 用途 |
| --- | --- | --- |
| `watch` / `Consumer` | 是 | 需要随状态重建 |
| `select` | 是（单字段） | 只关心某个字段 |
| `read` | 否 | 事件回调里调用方法 |

### 异步状态要表达出来

```dart
sealed class UiState<T> {
  const UiState();
}

class Loading<T> extends UiState<T> { const Loading(); }
class Success<T> extends UiState<T> {
  const Success(this.data);
  final T data;
}
class Failure<T> extends UiState<T> {
  const Failure(this.message);
  final String message;
}

// 界面按状态分支，四态齐全：加载中、成功、空、失败
Widget buildBody(UiState<List<Item>> state) => switch (state) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Failure(:final message) => Center(child: Text('出错了：$message')),
      Success(:final data) when data.isEmpty => const Center(child: Text('暂无数据')),
      Success(:final data) => ItemList(items: data),
    };
```

**把「加载中 / 成功 / 空 / 失败」都写出来，界面就不会出现莫名其妙的空白。**

### 生命周期与释放

```dart
class _PageState extends State<Page> {
  late final TextEditingController _controller;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _sub = stream.listen((_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _sub?.cancel();          // 取消订阅
    _controller.dispose();   // 释放控制器
    super.dispose();
  }
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 整页 `Consumer` 包住所有内容 | 无谓重建 | 只包需要的子树 |
| 用 `watch` 在回调里读 | 报错或多余重建 | 回调用 `read` |
| 忘记 `notifyListeners` | 界面不更新 | 改完状态必须通知 |
| 忘记 `dispose` | 内存泄漏、后台继续跑 | 控制器与订阅都要释放 |
| 状态放得太高 | 到处都是依赖 | 状态尽量下沉 |
| 没有失败态 | 出错时白屏 | 四态齐全 |
| 异步回调里 setState | 组件已卸载 | 加 `mounted` 判断 |
| 全局单例存临时状态 | 页面间互相污染 | 临时状态留在页面内 |

### 手把手练习：带四态的列表页

```dart
class ItemPage extends StatefulWidget {
  const ItemPage({super.key});
  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  UiState<List<Item>> _state = const Loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const Loading());
    try {
      final items = await repository.fetchAll();
      if (!mounted) return;
      setState(() => _state = Success(items));
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = Failure(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('列表'), actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
        body: buildBody(_state),
      );
}
```

### 学完自测

- [ ] 能区分局部状态与全局状态。
- [ ] 能说出 `watch`、`select`、`read` 的差别。
- [ ] 知道 `Consumer` 的 `child` 参数为什么能减少重建。
- [ ] 能说出界面应该表达的四种状态。
- [ ] 知道 `dispose` 里必须释放哪些资源。

## 时间/空间复杂度或性能分析

**复杂度证据**：「Flutter 状态管理与性能」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Flutter 状态管理与性能」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Flutter 状态管理与性能」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：重建范围优化速查**

| 手段 | 效果 |
| --- | --- |
| `const` 构造 | 跳过不必要的重建 |
| `Consumer` 包裹最小范围 | 只重建依赖部分 |
| `Selector` / `context.select` | 只在特定字段变化时重建 |
| `ValueListenableBuilder` | 精准监听单值变化 |
| `RepaintBoundary` | 减少重绘区域（与重建不同） |
| `ListView.builder` | 只构建可见项 |
| 拆分组件 | 缩小重建边界 |

```dart
class CartModel extends ChangeNotifier {
  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);

  double get total => _items.length * 9.9;

  void add(String item) {
    _items.add(item);
    notifyListeners();          // 只通知一次，避免多次重建
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }
}

// 只重建总数文本，而不是整页
class CartTotal extends StatelessWidget {
  const CartTotal({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.select<CartModel, double>((model) => model.total);
    return Text('合计：${total.toStringAsFixed(2)}');
  }
}

// 列表项单独订阅，避免父级重建带动整列
class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CartModel>();
    final title = model.items[index];
    return ListTile(
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => model.removeAt(index),
      ),
    );
  }
}
```

## 常见误区与易错点

> 复核《Flutter 状态管理与性能》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Flutter 状态管理与性能」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 `build` 里发请求或改状态 | 无限重建或报错 | 副作用放 `initState` 或事件回调 |
| 忘记 `notifyListeners` | 界面不刷新 | 状态变更后显式通知 |
| 一次变更多次通知 | 重建次数翻倍 | 合并为一次通知 |
| 用全局状态存临时输入 | 状态混乱 | 局部状态用 `setState` |
| 忘记 `dispose` | 内存泄漏、回调仍在跑 | 释放控制器与订阅 |
| `setState` 后使用旧值 | 界面与数据不一致 | 用函数式更新或读取最新状态 |
| 在 `dispose` 后调用 `setState` | 运行时报错 | 异步回调中先判断 `mounted` |
| 把所有状态都提到全局 | 耦合严重、难测试 | 就近管理，按需共享 |
| 依赖派生状态另存一份 | 两份数据不同步 | 直接计算派生值 |
| 大对象频繁 `notifyListeners` | 卡顿 | 拆分模型或精细订阅 |

**教材衔接：故障现场**

### 现场 1：在 build 里发请求或改状态

**症状**：在《Flutter 状态管理与性能》的复现场景中，无限重建或报错。

**根因**：当出现“在 build 里发请求或改状态”时，执行路径已经绕过了《Flutter 状态管理与性能》的关键约束，最终以“无限重建或报错”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Flutter 状态管理与性能》的问题，副作用放 initState 或事件回调。

**验证**：先在《Flutter 状态管理与性能》中记录“在 build 里发请求或改状态”留下的失败证据，再执行“副作用放 initState 或事件回调”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：一次变更多次通知

**症状**：在《Flutter 状态管理与性能》的复现场景中，重建次数翻倍。

**根因**：当出现“一次变更多次通知”时，执行路径已经绕过了《Flutter 状态管理与性能》的关键约束，最终以“重建次数翻倍”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Flutter 状态管理与性能》的问题，合并为一次通知。

**验证**：先在《Flutter 状态管理与性能》中记录“一次变更多次通知”留下的失败证据，再执行“合并为一次通知”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：忘记 dispose

**症状**：在《Flutter 状态管理与性能》的复现场景中，内存泄漏、回调仍在跑。

**根因**：当出现“忘记 dispose”时，执行路径已经绕过了《Flutter 状态管理与性能》的关键约束，最终以“内存泄漏、回调仍在跑”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Flutter 状态管理与性能》的问题，释放控制器与订阅。

**验证**：保留《Flutter 状态管理与性能》里触发“内存泄漏、回调仍在跑”的输入、版本和日志，按“释放控制器与订阅”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Flutter 基础与 Widget 树》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：Flutter 打包发布 Android》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Flutter 基础与 Widget 树》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Flutter 布局入门》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Flutter 状态管理与性能」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Flutter 状态管理与性能》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“Flutter 状态管理与性能”中的 Flutter、状态管理、Provider，下列哪两项是本课强调的实践判断？

A. 学习 Flutter 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 Flutter 的常规示例通过，就可以跳过边界与异常路径
C. 验证 状态管理 时要固定版本并覆盖边界输入，结论才可复现
D. 把 状态管理 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 Flutter 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 状态管理 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把Flutter 状态管理与性能拆成概念、示例与故障现场三部分，因此判断 Flutter 时必须同时交代输入、输出和失败路径，这使“学习 Flutter 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Flutter 状态管理与性能里，判断 状态管理 时要固定版本与边界输入，所以“验证 状态管理 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

阅读「Flutter 状态管理与性能」正文里的这段代码，下面哪一项判断是正确的？

```dart
// 1. 状态：继承 ChangeNotifier，只在数据变化时通知
class CartProvider extends ChangeNotifier {
  final List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void add(Item item) {
    _items.add(item);
    notifyListeners();          // 只在这一处通知
  }
}

// 2. 注入：在应用根部提供
MultiProvider(providers: [
  ChangeNotifierProvider(create: (_) => CartProvider()),
]);

// 3. 消费：只包裹真正依赖的子树
Consumer<CartProvider>(
  builder: (context, cart, child) => Text('合计 ${cart.total}'),
);

// 4. 只读不监听（事件回调里用，避免无谓重建）
context.read<CartProvider>().add(item);
```

A. 这段代码包含条件分支，不同输入会走不同的执行路径。
B. 这段代码包含异常处理分支，失败时会走专门的补救路径。
C. 这段代码会读取外部输入，结果依赖传入的数据。
D. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「Flutter 状态管理与性能」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Flutter 状态管理与性能」的正文示例，围绕Flutter、状态管理、Provider展开；把输入或边界换成空值、极值或失败情况后，结论要以「Flutter 状态管理与性能」的实际运行结果为准。

### 自测 3

忘记在 dispose 中释放控制器会导致？

A. 内存泄漏与后台继续执行
B. 只引起一次性的 UI 卡顿
C. 无法打包
D. 编译错误

**参考答案**：内存泄漏与后台继续执行

**解析**：在「Flutter 状态管理与性能」里，内存泄漏与后台继续执行。AnimationController、TextEditingController、订阅都必须释放。“dispose”与「Flutter 状态管理与性能」的术语表相呼应，只有符合Flutter、状态管理、Provider约束的“内存泄漏与后台继续执行”才是正文支持的结论。

**教材衔接：复习与自测**

- [ ] 能判断状态应放在局部还是全局。
- [ ] 会用 `select` 或 `Consumer` 缩小重建范围。
- [ ] 副作用不写在 `build` 中。
- [ ] 控制器与订阅在 `dispose` 中释放。
- [ ] 派生状态直接计算，不额外存储。

**教材衔接：动手练习**

> 本课练习重点：围绕「Flutter、状态管理、Provider」完成复述、实验和交付，每个结果都要能被别人检查。

先固定 状态管理 的约束，再验证不同屏幕宽度下的表现。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Flutter 状态管理与性能解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「状态管理」是什么关系？

验收标准：用自己的话解释 Flutter，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 ChangeNotifierProvider 当作原例，改动一次状态管理的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

创建一个最小 Widget 展示 Flutter，分别验证正常、空数据和超长文本三种状态。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Flutter」和「状态管理」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Flutter 状态管理与性能安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Flutter 状态管理与性能」的结构，画完再对照骨架：

- 主干：状态分层 → 重建范围控制 → 生命周期要点 → 异步与错误处理
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Flutter与状态管理的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案至少在一个输入上给出不同结果；把差异归因到Flutter，而不是笼统地写「性能更好」。

### 任务 3：迁移到自己的场景

**验收标准**：换一个人按你的记录重跑 ChangeNotifierProvider，能得到相同输出；得不到就补写缺失的前提。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「输入框内容这类局部 UI 状态推荐？」的判断依据。
- [ ] 不看解析，能说出「控制重建范围的有效手段是？」的判断依据。
- [ ] 不看解析，能说出「忘记在 dispose 中释放控制器会导致？」的判断依据。
- [ ] 不看解析，能说出「ChangeNotifier 子类中通知界面刷新的方法是？」的判断依据。
- [ ] 不看解析，能说出「订阅 Provider 时，只希望在某个字段变化时重建，应该用？」的判断依据。
- [ ] 跑通「Flutter 状态管理与性能」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「Flutter 状态管理与性能」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Flutter` | Flutter 状态管理的核心是分层与最小重建：局部用 setState、共享用 Provider/Riverpod、服务端数据走仓库层；再配合 const、Selector 与 RepaintBoundary 控制性能。 |
| `状态管理` | 集中或按作用域组织应用状态，并控制读取、更新与生命周期。 |
| `性能` | 系统在给定负载下表现出的吞吐、延迟、资源占用和稳定性。 |
| `生命周期` | 引用保持有效的区间；在 Rust 中还用于把多个引用的有效期关系写进类型。 |

## 考点精讲

### 考点 1：多选辨析·Flutter

- **题目**：围绕“Flutter 状态管理与性能”中的 Flutter、状态管理、Provider，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Flutter 状态管理与性能拆成概念、示例与故障现场三部分，因此判断 Flutter 时必须同时交代输入、输出和失败路径，这使“学习 Flutter 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Flutter 状态管理与性能里，判断 状态管理 时要固定版本与边界输入，所以“验证 状态管理 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：代码补全·Flutter

- **题目**：阅读「Flutter 状态管理与性能」正文里的这段代码，下面哪一项判断是正确的？
- **判断依据**：在「Flutter 状态管理与性能」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Flutter 状态管理与性能」的正文示例，围绕Flutter、状态管理、Provider展开；把输入或边界换成空值、极值或失败情况后，结论要以「Flutter 状态管理与性能」的实际运行结果为准。

### 考点 3：概念判断·Flutter

- **题目**：忘记在 dispose 中释放控制器会导致？
- **判断依据**：在「Flutter 状态管理与性能」里，内存泄漏与后台继续执行。AnimationController、TextEditingController、订阅都必须释放。“dispose”与「Flutter 状态管理与性能」的术语表相呼应，只有符合Flutter、状态管理、Provider约束的“内存泄漏与后台继续执行”才是正文支持的结论。

### 考点 4：概念判断·Flutter

- **题目**：ChangeNotifier 子类中通知界面刷新的方法是？
- **判断依据**：在「Flutter 状态管理与性能」里，ChangeNotifier 通过 notifyListeners 通知订阅者重建。在「Flutter 状态管理与性能」里，setState 属于 StatefulWidget 自身，与 ChangeNotifier 无关。在「Flutter 状态管理与性能」里，这道题要求区分概念与边界，「notifyListeners」只有在题干给出的前提下才成立，而「只属于 State 的 setState」、「refresh」缺少同一组条件。

### 考点 5：概念判断·Flutter

- **题目**：订阅 Provider 时，只希望在某个字段变化时重建，应该用？
- **判断依据**：在「Flutter 状态管理与性能」里，context.select<Model, T>((m) => m.field)。select 会把重建范围收窄到指定字段，其余字段变化不会触发重建。“Provider”与「Flutter 状态管理与性能」的术语表相呼应，只有符合Flutter、状态管理、Provider约束的“context.select<Model”才是正文支持的结论。

### 考点 6：顺序排列·Flutter

- **题目**：按照「Flutter 状态管理与性能」从概念到实践的讲解顺序排列下列主题。
- **判断依据**：正确的执行顺序是「状态分层」 → 「重建范围控制」 → 「生命周期要点」 → 「异步与错误处理」。在本课中，正确顺序是：1. 状态分层 → 2. 重建范围控制 → 3. 生命周期要点 → 4. 异步与错误处理。在「Flutter 状态管理与性能」里判断这道题，要把Flutter、状态管理、Provider的条件、过程与失败路径逐项对齐，换成“按照Flutter 状态管理与性能从”这个场景，只有满足前提的结论才成立。

## English Overview

**Title:** State Management

**Summary:** State layers, rebuild scope and lifecycle.

**Category:** Mobile Development
**Level:** 进阶
**Key terms:** Flutter, 状态管理, Provider, 性能, 生命周期

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：入门
- 适用环境：Flutter 3.x / Dart 3.x；本课聚焦 Flutter。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Flutter、状态管理、Provider、性能、生命周期
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | 状态分层与重建范围 |
| [Flutter UI 文档](https://docs.flutter.dev/ui) | Widget、布局与渲染 |
| [Dart 异步编程](https://dart.dev/libraries/async/async-await) | Future、Stream 与事件循环 |

> 「Flutter 状态管理与性能」的链接用于离线阅读后的延伸核对；App 不会自动联网。
