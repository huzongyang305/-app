# Flutter 状态管理与性能

> 内容更新时间：2026-10-06 · 学习阶段：入门 · 预计用时：40 分钟

![状态分层与重建范围](images/diagram_mobile_flutter_state.webp)

![Flutter 状态管理与性能](images/category_flutter_state.webp)

## 学习目标

- 能用自己的话解释Flutter 状态管理与性能解决了什么问题，而不是只背术语。
- 能说清 「Flutter」、「状态管理」、「Provider」、「性能」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「移动开发」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：状态分层、重建范围控制与生命周期陷阱。

## 前置知识

- 先完成上一课《Flutter 基础与 Widget 树》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Flutter、状态管理、Provider。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 状态分层

| 类型 | 例子 | 推荐方案 |
| --- | --- | --- |
| 局部 UI 状态 | 输入框内容、开关、动画 | StatefulWidget + setState |
| 跨页面共享 | 登录用户、主题、购物车 | Provider / Riverpod / Bloc |
| 服务端数据 | 列表、详情、分页 | 仓库层 + FutureBuilder/AsyncNotifier + 缓存 |

选型原则：**能局部就不全局**。全局状态越少，重建范围越小、越容易测试。Provider 适合中小项目（ChangeNotifier + Consumer），Riverpod 编译期安全、便于测试，Bloc 适合复杂业务与团队规范要求高的场景。

## 重建范围控制

1. 用 `const` 构造器避免无谓重建。
2. `Consumer`/`Selector` 只包裹真正依赖该状态的子树，而不是整页。
3. 长列表用 `ListView.builder` + `itemExtent`（已知行高时）减少布局计算。
4. 复杂动画或频繁重绘区域用 `RepaintBoundary` 隔离。
5. 避免在 build 里做重活（排序、网络、JSON 解析），移到 initState 或状态层。

## 生命周期要点

`initState` 做一次初始化（注意不能在这里用 context 依赖），`didChangeDependencies` 响应依赖变化，`dispose` 释放控制器、订阅与定时器。**忘记 dispose 是内存泄漏的常见来源**（AnimationController、TextEditingController、StreamSubscription）。

## 异步与错误处理

用 FutureBuilder 时务必处理三种状态：等待、错误、空数据；页面卸载后不要再 setState（用 `if (!mounted) return;`）。分页加载要注意去重与并发请求的竞态（后发先至）。

## Provider 代码骨架

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

## 测试策略

状态类不依赖 Widget，可直接单测：构造 Provider → 调用方法 → 断言状态与通知次数（用 `addListener` 计数）。Widget 测试中通过 `ChangeNotifierProvider.value` 注入假数据，避免真实网络与数据库。

## 本课小结

Flutter 状态管理的核心是**分层与最小重建**：局部用 setState、共享用 Provider/Riverpod、服务端数据走仓库层；再配合 const、Selector 与 RepaintBoundary 控制性能。

## 状态分类速查

| 状态类型 | 生命周期 | 推荐方案 |
| --- | --- | --- |
| 局部 UI 状态 | 单页面 | `StatefulWidget` + `setState` |
| 跨组件共享 | 多个页面 | Provider / Riverpod |
| 全局配置 | 应用级 | Provider + 持久化 |
| 派生状态 | 由其他状态计算 | 直接计算，不额外存 |
| 异步数据 | 网络请求 | `FutureBuilder` 或状态管理的异步封装 |

## 重建范围优化速查

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

## 生命周期速查

| 阶段 | 时机 | 典型用途 |
| --- | --- | --- |
| `initState` | 组件插入树后 | 初始化控制器、首次请求 |
| `didChangeDependencies` | 依赖变化 | 读取 `InheritedWidget` 或主题 |
| `build` | 每次需要渲染 | 只做构建，不放副作用 |
| `didUpdateWidget` | 父级传入参数变化 | 对比新旧参数做响应 |
| `dispose` | 组件移除 | 取消订阅、释放控制器 |
| `deactivate` | 从树中暂时移除 | 少见，谨慎使用 |

## 常见错误与排查

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

## 复习与自测

- [ ] 能判断状态应放在局部还是全局。
- [ ] 会用 `select` 或 `Consumer` 缩小重建范围。
- [ ] 副作用不写在 `build` 中。
- [ ] 控制器与订阅在 `dispose` 中释放。
- [ ] 派生状态直接计算，不额外存储。

## 零基础详解：状态管理与重建范围

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

## 动手练习

> 本课练习重点：围绕「Flutter、状态管理、Provider」完成复述、实验和交付，每个结果都要能被别人检查。

先做一个最小 Widget，再切换状态与约束，最后在窄屏和深色模式下验证布局。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Flutter 状态管理与性能解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「状态管理」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

创建一个最小 Widget，分别验证正常输入、空数据和超长文本三种状态。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Flutter」和「状态管理」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

本节围绕Flutter 状态管理与性能安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Flutter 状态管理与性能」的结构，画完再对照骨架：

- 主干：状态分层 → 重建范围控制 → 生命周期要点 → 异步与错误处理
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Flutter与状态管理的关系？

### 任务 2：做一次对比实验

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。

## 故障现场

### 现场 1：本课的 Flutter 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 Flutter 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 Flutter 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“Flutter 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 Flutter 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 状态管理 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 状态管理 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 状态管理 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“状态管理 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 状态管理 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，Flutter 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「输入框内容这类局部 UI 状态推荐？」的判断依据。
- [ ] 不看解析，能说出「控制重建范围的有效手段是？」的判断依据。
- [ ] 不看解析，能说出「忘记在 dispose 中释放控制器会导致？」的判断依据。
- [ ] 不看解析，能说出「ChangeNotifier 子类中通知界面刷新的方法是？」的判断依据。
- [ ] 不看解析，能说出「订阅 Provider 时，只希望在某个字段变化时重建，应该用？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「Flutter 状态管理与性能」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `Flutter` | Flutter 状态管理的核心是分层与最小重建：局部用 setState、共享用 Provider/Riverpod、服务端数据走仓库层；再配合 const、Selector 与 RepaintBoundary 控制性能。 |
| `状态管理` | 围绕“状态管理 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `Provider` | Flutter 状态管理的核心是分层与最小重建：局部用 setState、共享用 Provider/Riverpod、服务端数据走仓库层；再配合 const、Selector 与 RepaintBoundary 控制性能。 |
| `性能` | 它在「Flutter 状态管理与性能」里是理解「性能」的关键术语，用来解释定义、适用条件与失败路径；它与Flutter、状态管理共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |
| `生命周期` | 它在「Flutter 状态管理与性能」里是理解「生命周期」的关键术语，用来解释定义、适用条件与失败路径；它与Flutter、状态管理共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |

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
- **判断依据**：在「Flutter 状态管理与性能」里，ChangeNotifier 通过 notifyListeners 通知订阅者重建。在「Flutter 状态管理与性能」里，setState 属于 StatefulWidget 自身。在「Flutter 状态管理与性能」里，这道题要求区分概念与边界，「notifyListeners」只有在题干给出的前提下才成立，而「setState」、「refresh」缺少同一组条件。

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
- 适用环境：Flutter 3.x / Dart 3.x
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Flutter、状态管理、Provider、性能、生命周期
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | 状态分层与重建范围 |
| [Flutter UI 文档](https://docs.flutter.dev/ui) | Widget、布局与渲染 |
| [Dart 异步编程](https://dart.dev/libraries/async/async-await) | Future、Stream 与事件循环 |

> 「Flutter 状态管理与性能」的链接用于离线阅读后的延伸核对；App 不会自动联网。
