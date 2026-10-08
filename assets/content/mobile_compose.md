# Jetpack Compose 声明式 UI

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：45 分钟

![Jetpack Compose 重组与状态](images/diagram_mobile_compose.webp)

![Jetpack Compose 声明式 UI](images/category_mobile_compose.webp)

## 本节知识框架

**课程定位**：所属分类为「移动开发」，课程主题为「Jetpack Compose 声明式 UI」，学习阶段为「进阶」，建议用时 45 分钟。

**本课要解决的主问题**：重组机制、状态提升、副作用与重组范围优化。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Jetpack Compose 声明式 UI」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Jetpack Compose 声明式 UI」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Compose」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《React Native 跨平台开发》

**学习位置**：本课位于《React Native 跨平台开发》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《鸿蒙 ArkTS 应用开发》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Jetpack Compose 声明式 UI解决了什么问题，而不是只背术语。
- 能说清 「Compose」、「声明式UI」、「重组」、「状态提升」 之间的关系，并分别举出一个例子。
- 能把 Compose 放回「Jetpack Compose 声明式 UI」的知识体系，说明它和 声明式UI 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：重组机制、状态提升、副作用与重组范围优化。

**教材衔接：前置知识**

- 先完成上一课《React Native 跨平台开发》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「React Native 跨平台开发」，或确认自己能独立跑通正文里的 collectAsStateWithLifecycle 示例。
- 开始前先复习：Compose、声明式UI、重组。
- 卡在 Compose 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

- 核心问题：Jetpack Compose 声明式 UI不是孤立术语，而是在「移动开发」中解决一类具体问题。
- 关键关系：先分清「Compose」与「声明式UI」的职责，再理解「重组」的适用边界。
- 判断标准：能解释 Compose 的正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：先复述 声明式UI 的边界，再开始本课测验。

## 核心概念定义

> 阅读约定：本课先给「Jetpack Compose 声明式 UI」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| 状态提升 | 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。 | 仅在「Jetpack Compose 声明式 UI」明确给出的输入、版本与资源条件下成立。 |
| 可组合函数 | 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。 | 仅在「Jetpack Compose 声明式 UI」明确给出的输入、版本与资源条件下成立。 |
| 重组 | 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。 | 仅在「Jetpack Compose 声明式 UI」明确给出的输入、版本与资源条件下成立。 |
| 单向数据流 | 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。 | 仅在「Jetpack Compose 声明式 UI」明确给出的输入、版本与资源条件下成立。 |
| 修饰符 | 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同 | 仅在「Jetpack Compose 声明式 UI」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Jetpack Compose 声明式 UI」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「状态提升」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「可组合函数」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「重组」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Jetpack Compose 声明式 UI」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | 状态提升 | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 可组合函数 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 重组 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Jetpack Compose 声明式 UI」自己的示例验证。「Jetpack Compose 声明式 UI」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：核心理念**

Compose 用「函数描述 UI」取代 XML 布局：UI 是状态的函数，状态变了就重组（recompose）受影响的部分。理解重组的作用域与稳定性，是写好 Compose 的关键。

| 概念 | 含义 |
| --- | --- |
| 可组合函数 | 标注 `@Composable` 的函数，描述一段 UI |
| 重组 | 状态变化时重新执行受影响的 composable |
| 状态提升 | 把状态交给调用方，组件只负责展示 |
| 副作用 | 在组合之外执行的动作（`LaunchedEffect`、`DisposableEffect`） |
| 记忆 | `remember` 在重组间保留值 |
| 稳定性 | 参数稳定则可跳过重组，性能更好 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Compose、声明式UI | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Jetpack Compose 声明式 UI」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Jetpack Compose 声明式 UI」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Jetpack Compose 声明式 UI》原文中的最小示例。先预测《Jetpack Compose 声明式 UI》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```kotlin
@Composable
fun LessonScreen(viewModel: LessonViewModel, modifier: Modifier = Modifier) {
    // 用 collectAsStateWithLifecycle 让订阅跟随生命周期，避免后台空跑
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        viewModel.load()          // 副作用写在 LaunchedEffect 里，而不是组合体中
    }

    Column(modifier = modifier.fillMaxSize().padding(16.dp)) {
        when {
            state.loading -> CircularProgressIndicator(Modifier.align(Alignment.CenterHorizontally))
            state.error != null -> ErrorBanner(state.error!!, onRetry = viewModel::load)
            else -> LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(bottom = 24.dp),
            ) {
                items(state.items, key = { it.id }) { lesson ->
                    LessonCard(
                        title = lesson.title,
                        onClick = { viewModel.open(lesson.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun LessonCard(title: String, onClick: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(16.dp),
        )
    }
}
```

**教材衔接：常用 API 速查**

| 需求 | 写法 |
| --- | --- |
| 状态 | `var x by remember { mutableStateOf(0) }` |
| 可观察列表 | `mutableStateListOf()` |
| 副作用 | `LaunchedEffect(key) { }`、`DisposableEffect(key)` |
| 列表 | `LazyColumn` / `LazyRow` / `LazyVerticalGrid` |
| 布局 | `Column`、`Row`、`Box`、`ConstraintLayout` |
| 修饰符 | `Modifier.padding().fillMaxWidth().clip()` |
| 主题 | `MaterialTheme`、`ColorScheme`、`Typography` |
| 派生状态 | `derivedStateOf { }` |

```kotlin
@Composable
fun LessonScreen(viewModel: LessonViewModel, modifier: Modifier = Modifier) {
    // 用 collectAsStateWithLifecycle 让订阅跟随生命周期，避免后台空跑
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        viewModel.load()          // 副作用写在 LaunchedEffect 里，而不是组合体中
    }

    Column(modifier = modifier.fillMaxSize().padding(16.dp)) {
        when {
            state.loading -> CircularProgressIndicator(Modifier.align(Alignment.CenterHorizontally))
            state.error != null -> ErrorBanner(state.error!!, onRetry = viewModel::load)
            else -> LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(bottom = 24.dp),
            ) {
                items(state.items, key = { it.id }) { lesson ->
                    LessonCard(
                        title = lesson.title,
                        onClick = { viewModel.open(lesson.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun LessonCard(title: String, onClick: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(16.dp),
        )
    }
}
```

**教材衔接：零基础详解：Jetpack Compose 声明式 UI**

### 一句话说清它是什么

Compose 用 Kotlin 函数描述界面：**UI = f(状态)**。
状态变了，Compose 自动重组受影响的组件，你不需要手动找控件改内容。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| Composable | 会画画的函数 | 描述「界面长什么样」 |
| 状态 | 输入参数 | 变了就重新画 |
| 重组 | 重画 | 只重画用到该状态的部分 |
| 副作用 | 画画之外的动手 | 发请求、订阅、埋点 |
| 修饰符 | 装修清单 | 尺寸、间距、点击都在这里加 |

### 最小可运行示例

```kotlin
@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "你好，$name！",
        modifier = modifier.padding(16.dp),
        style = MaterialTheme.typography.titleMedium,
    )
}

@Preview(showBackground = true)
@Composable
private fun GreetingPreview() {
    MyAppTheme { Greeting("小明") }
}
```

`@Preview` 可以在 Android Studio 里直接看效果，不用跑模拟器。

### 状态：记住与提升

```kotlin
@Composable
fun Counter() {
    var count by rememberSaveable { mutableIntStateOf(0) }   // 旋转屏幕也能保留

    Column(Modifier.padding(16.dp)) {
        Text("计数：$count")
        Button(onClick = { count++ }) { Text("加一") }
    }
}

// 状态提升：把状态交给调用方，组件变成纯展示
@Composable
fun CounterRow(count: Int, onIncrement: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text("计数：$count", Modifier.weight(1f))
        Button(onClick = onIncrement) { Text("加一") }
    }
}
```

| 写法 | 用途 |
| --- | --- |
| `remember` | 重组之间记住值 |
| `rememberSaveable` | 进程重建也能恢复 |
| `mutableStateOf` | 可观察状态 |
| `derivedStateOf` | 从其他状态推导，减少重组 |

**状态提升的好处**：组件可复用、可测试、状态来源单一。

### 副作用：三个最常用的 API

```kotlin
@Composable
fun UserScreen(userId: Long, viewModel: UserViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    // 1. LaunchedEffect：进入或 key 变化时执行一次挂起逻辑
    LaunchedEffect(userId) { viewModel.load(userId) }

    // 2. DisposableEffect：需要成对注册与注销
    DisposableEffect(Unit) {
        val listener = registerListener()
        onDispose { listener.unregister() }
    }

    // 3. remember 缓存计算结果，避免每次重组都算
    val label = remember(state) { buildLabel(state) }

    Text(label)
}
```

**规则**：Composable 函数体内应当只做「描述界面」的事，取数据与订阅要放进副作用 API。

### 布局与修饰符

```kotlin
Column(
    modifier = Modifier
        .fillMaxWidth()
        .padding(16.dp),
    verticalArrangement = Arrangement.spacedBy(8.dp),
) {
    Text("标题", style = MaterialTheme.typography.titleLarge)

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text("说明", Modifier.weight(1f), maxLines = 2, overflow = TextOverflow.Ellipsis)
        Icon(Icons.Default.ChevronRight, contentDescription = null)
    }
}
```

| 修饰符 | 作用 |
| --- | --- |
| `fillMaxWidth` / `fillMaxSize` | 撑满可用空间 |
| `padding` / `size` | 内边距与尺寸 |
| `weight` | 按比例分配剩余空间 |
| `clickable` | 添加点击 |
| `semantics` | 无障碍描述 |

**修饰符顺序有影响**：`padding` 在 `background` 之前与之后，效果完全不同。

### 列表：一定要给稳定 key

```kotlin
LazyColumn(
    contentPadding = PaddingValues(16.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
) {
    items(items = state.items, key = { it.id }) { item ->
        ItemCard(item)
    }
}
```

`key` 让 Compose 在数据变化时正确复用与移动元素，避免状态错位。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 在 Composable 里发请求 | 重组时重复请求 | 用 `LaunchedEffect` |
| 用普通变量存状态 | 界面不更新 | 用 `mutableStateOf` |
| 列表不给 key | 元素状态错位 | `key = { it.id }` |
| 修饰符顺序随意 | 样式与预期不符 | 记住顺序有意义 |
| 列表项里做重计算 | 滚动卡顿 | 用 `remember` 缓存 |
| 忘记 `onDispose` | 监听器泄漏 | 用 `DisposableEffect` |
| 状态放太深 | 无法共享与测试 | 状态提升到 ViewModel |
| 过度使用 `derivedStateOf` | 逻辑绕 | 只在真正需要时用 |

### 学完自测

- [ ] 能说出 `remember` 与 `rememberSaveable` 的区别。
- [ ] 知道为什么要做状态提升。
- [ ] 能说出 `LaunchedEffect` 与 `DisposableEffect` 的适用场景。
- [ ] 知道 LazyColumn 为什么必须给 key。
- [ ] 能说出两类不能直接写在 Composable 里的操作。

## 时间/空间复杂度或性能分析

**复杂度证据**：「Jetpack Compose 声明式 UI」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Jetpack Compose 声明式 UI」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Jetpack Compose 声明式 UI」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：重组与性能速查**

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 列表滚动卡顿 | 每次重组都创建新对象 | 用 `key`、`remember`、稳定数据类 |
| 状态丢失 | 状态放在会被移除的组合中 | 状态提升或 `rememberSaveable` |
| 无限重组 | 在组合体里改状态 | 副作用移到 `LaunchedEffect` |
| 参数不稳定导致全量重组 | 传入可变集合或 lambda | 使用不可变集合、`@Stable` 标注 |
| 频繁布局读取 | 在组合阶段读 `Modifier` 布局信息 | 用 `Modifier.layout` 或 `derivedStateOf` |

## 常见误区与易错点

> 复核《Jetpack Compose 声明式 UI》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Jetpack Compose 声明式 UI」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 composable 里直接发请求 | 每次重组都触发 | 放到 `LaunchedEffect` |
| 用普通变量存状态 | 界面不更新 | 用 `mutableStateOf` 或 `StateFlow` |
| 列表不写 `key` | 增删后状态错位 | `items(list, key = { it.id })` |
| 在组合体里读取 `LazyListState` 的滚动值 | 滚动时全量重组 | 用 `derivedStateOf` 包一层 |
| 传可变集合给子组件 | 无法跳过重组 | 用 `ImmutableList` 或不可变结构 |
| 把 `remember` 当全局缓存 | 状态意外保留或丢失 | 明确生命周期，必要时提升状态 |
| 忽略 `Modifier` 顺序 | 内边距与裁剪效果不符合预期 | 顺序即执行顺序，按需调整 |

**教材衔接：故障现场**

### 现场 1：在 composable 里直接发请求

**症状**：在《Jetpack Compose 声明式 UI》的复现场景中，每次重组都触发。

**根因**：“每次重组都触发”只是表层结果。向上追溯会落到“在 composable 里直接发请求”这一步，因为它省略了《Jetpack Compose 声明式 UI》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Jetpack Compose 声明式 UI》的问题，放到 LaunchedEffect。

**验证**：先在《Jetpack Compose 声明式 UI》中记录“在 composable 里直接发请求”留下的失败证据，再执行“放到 LaunchedEffect”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：列表不写 key

**症状**：在《Jetpack Compose 声明式 UI》的复现场景中，增删后状态错位。

**根因**：触发点是把“列表不写 key”当成安全做法。它没有满足《Jetpack Compose 声明式 UI》要求的前提，因此先表现为“增删后状态错位”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Jetpack Compose 声明式 UI》的问题，items(list, key = { it.id })。

**验证**：在《Jetpack Compose 声明式 UI》中按“items(list, key = { it.id })”调整后，从“列表不写 key”的触发条件重放同一条路径，确认“增删后状态错位”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：在组合体里读取 LazyListState 的滚动值

**症状**：在《Jetpack Compose 声明式 UI》的复现场景中，滚动时全量重组。

**根因**：触发点是把“在组合体里读取 LazyListState 的滚动值”当成安全做法。它没有满足《Jetpack Compose 声明式 UI》要求的前提，因此先表现为“滚动时全量重组”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Jetpack Compose 声明式 UI》的问题，用 derivedStateOf 包一层。

**验证**：保留《Jetpack Compose 声明式 UI》里触发“滚动时全量重组”的输入、版本和日志，按“用 derivedStateOf 包一层”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《React Native 跨平台开发》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《鸿蒙 ArkTS 应用开发》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《React Native 跨平台开发》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《鸿蒙 ArkTS 应用开发》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Jetpack Compose 声明式 UI」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

**教材衔接：与 View 体系对照**

| 维度 | View / XML | Compose |
| --- | --- | --- |
| 描述方式 | 命令式、可变树 | 声明式、状态驱动 |
| 更新 | 手动查找并修改视图 | 状态变化自动重组 |
| 可测试性 | 依赖 Espresso 查找视图 | 用测试规则直接断言节点 |
| 动画 | 属性动画 | `animate*AsState`、`Transition` |
| 复用 | `<include>`、自定义 View | 可组合函数天然复用 |

## 自测题与参考答案

> 先独立作答《Jetpack Compose 声明式 UI》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

按“Jetpack Compose 声明式 UI”中 Compose、声明式UI、重组 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。

A. 只改一个变量，记录边界与失败路径的变化
B. 固定版本与证据，把“Jetpack Compose 声明式 UI”的结论写成可复现记录
C. 先明确 Compose 的输入、输出与约束
D. 写出最小示例并核对 声明式UI 的基线结果

**参考答案**：先明确 Compose 的输入、输出与约束 → 写出最小示例并核对 声明式UI 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把“Jetpack Compose 声明式 UI”的结论写成可复现记录

**解析**：在「Jetpack Compose 声明式 UI」里，在本课的练习里，顺序应当是：先明确 Compose 的输入、输出与约束 → 写出最小示例并核对 声明式UI 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 Compose 的输入、输出和约束放在最前面，在Jetpack Compose 声明式 UI里避免概念没对齐就开始调参。第二步用 声明式UI 建立可核对的基线，在Jetpack Compose 声明式 UI里第三步才允许改变一个变量并观察失败路径。

### 自测 2

围绕“Jetpack Compose 声明式 UI”中的 Compose、声明式UI、重组，下列哪两项是本课强调的实践判断？

A. 把 声明式UI 的单次运行结果当成所有版本和规模都成立
B. 学习 Compose 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 Compose 的常规示例通过，就可以跳过边界与异常路径
D. 验证 声明式UI 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 Compose 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 声明式UI 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把Jetpack Compose 声明式 UI拆成概念、示例与故障现场三部分，因此判断 Compose 时必须同时交代输入、输出和失败路径，这使“学习 Compose 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Jetpack Compose 声明式 UI里，判断 声明式UI 时要固定版本与边界输入，所以“验证 声明式UI 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

关于派生状态 derivedStateOf，说法正确的是？

A. 它会把状态写入持久存储
B. 它替代了所有 remember 用法
C. 它能减少因状态频繁变化导致的重组
D. 它只能用于列表滚动

**参考答案**：它能减少因状态频繁变化导致的重组

**解析**：在「Jetpack Compose 声明式 UI」里，它能减少因状态频繁变化导致的重组。derivedStateOf 让读取方只在派生结果真正变化时才重组，例如「是否滚动到顶部」这种布尔值，避免每像素滚动都触发重组。「Jetpack Compose 声明式 UI」要求先交代Compose、声明式UI、重组的前提再下结论，所以“它能减少因状态频繁变化导致的重组”只在题干“派生状态 derivedStateOf”给定的条件下成立。

**教材衔接：复习与自测**

- [ ] 能解释声明式 UI 与重组的关系。
- [ ] 状态用 `mutableStateOf`/`StateFlow`，副作用用 `LaunchedEffect`。
- [ ] 列表使用 `key` 并传稳定数据。
- [ ] 会用 `derivedStateOf` 减少重组范围。
- [ ] 知道状态提升与 `rememberSaveable` 的适用场景。

**教材衔接：动手练习**

> 本课练习重点：围绕「Compose、声明式UI、重组」完成复述、实验和交付，每个结果都要能被别人检查。

把 collectAsStateWithLifecycle 的布局放进窄屏与深色模式各检查一次。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Jetpack Compose 声明式 UI解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「声明式UI」是什么关系？

验收标准：用自己的话解释 Compose，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：用 collectAsStateWithLifecycle 复现原例后，把声明式UI改成边界值，五步记录缺一不可，其中「原因」一栏要写明「Jetpack Compose 声明式 UI」里哪条规则被触发。

### 练习 3：交付一个小结果（30 分钟）

用最小 Widget 验证 声明式UI 在空数据与超长文本下的表现。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Compose」和「声明式UI」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Jetpack Compose 声明式 UI安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Jetpack Compose 声明式 UI」的结构，画完再对照骨架：

- 主干：核心理念 → 常用 API 速查 → 重组与性能速查 → 与 View 体系对照
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Compose与声明式UI的关系？

### 任务 2：做一次对比实验

**验收标准**：用 collectAsStateWithLifecycle 做一次真实对照，结论要说明在「Jetpack Compose 声明式 UI」的哪个前提下成立。

### 任务 3：迁移到自己的场景

**验收标准**：用自己的话复述 Compose，并配一个反例；只写定义不算通过。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「在 composable 中发起网络请求，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「让 Compose 列表在增删后不错位，关键是？」的判断依据。
- [ ] 不看解析，能说出「关于派生状态 derivedStateOf，说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「状态提升（state hoisting）的主要目的是？」的判断依据。
- [ ] 不看解析，能说出「下面哪种写法最容易造成无限重组？」的判断依据。
- [ ] 用 Compose 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `状态提升` | 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。 |
| `可组合函数` | 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。 |
| `重组` | 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。 |
| `单向数据流` | 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。 |
| `修饰符` | 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同 |

## 考点精讲

### 考点 1：顺序排列·Compose

- **题目**：按“Jetpack Compose 声明式 UI”中 Compose、声明式UI、重组 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **判断依据**：在「Jetpack Compose 声明式 UI」里，在本课的练习里，顺序应当是：先明确 Compose 的输入、输出与约束 → 写出最小示例并核对 声明式UI 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 Compose 的输入、输出和约束放在最前面，在Jetpack Compose 声明式 UI里避免概念没对齐就开始调参。第二步用 声明式UI 建立可核对的基线，在Jetpack Compose 声明式 UI里第三步才允许改变一个变量并观察失败路径。

### 考点 2：多选辨析·Compose

- **题目**：围绕“Jetpack Compose 声明式 UI”中的 Compose、声明式UI、重组，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Jetpack Compose 声明式 UI拆成概念、示例与故障现场三部分，因此判断 Compose 时必须同时交代输入、输出和失败路径，这使“学习 Compose 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Jetpack Compose 声明式 UI里，判断 声明式UI 时要固定版本与边界输入，所以“验证 声明式UI 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·Compose

- **题目**：关于派生状态 derivedStateOf，说法正确的是？
- **判断依据**：在「Jetpack Compose 声明式 UI」里，它能减少因状态频繁变化导致的重组。derivedStateOf 让读取方只在派生结果真正变化时才重组，例如「是否滚动到顶部」这种布尔值，避免每像素滚动都触发重组。「Jetpack Compose 声明式 UI」要求先交代Compose、声明式UI、重组的前提再下结论，所以“它能减少因状态频繁变化导致的重组”只在题干“派生状态 derivedStateOf”给定的条件下成立。

### 考点 4：概念判断·Compose

- **题目**：状态提升（state hoisting）的主要目的是？
- **判断依据**：在「Jetpack Compose 声明式 UI」里，结论应落在「让组件无状态、易于复用与测试」。把状态交给调用方管理，组件只接收值并回调事件，从而变成纯粹的展示层，复用与测试都更简单。在「Jetpack Compose 声明式 UI」里，这道题要求区分概念与边界，「让组件无状态、易于复用与测试」只有在题干给出的前提下才成立，而「替代 ViewModel」、「减少内存占用」缺少同一组条件。

### 考点 5：概念判断·Compose

- **题目**：下面哪种写法最容易造成无限重组？
- **判断依据**：在「Jetpack Compose 声明式 UI」里，在 composable 函数体里直接修改状态。在组合阶段修改状态会触发新一轮重组，形成循环。这道题的关键在「Jetpack Compose 声明式 UI」的Compose、声明式UI、重组：先确认题干“下面哪种写法最容易造成无限重组”问的是哪一步，再排除偷换前提的选项。

### 考点 6：排错·Compose

- **题目**：阅读「Jetpack Compose 声明式 UI」的代码片段，下面哪项判断是正确的？
- **判断依据**：在「Jetpack Compose 声明式 UI」里，放在 LaunchedEffect 中。在「Jetpack Compose 声明式 UI」里判断这道题，要把Compose、声明式UI、重组的条件、过程与失败路径逐项对齐，换成“阅读Jetpack Compose”这个场景，只有满足前提的结论才成立。

## English Overview

**Title:** Jetpack Compose

**Summary:** Recomposition, state hoisting, side effects and performance.

**Category:** Mobile Development
**Level:** 进阶
**Key terms:** Compose, 声明式UI, 重组, 状态提升, LazyColumn

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Flutter 3.x / Dart 3.x
；本课聚焦 Compose。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Compose、声明式UI、重组、状态提升、LazyColumn
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter UI 文档](https://docs.flutter.dev/ui) | Widget、布局与渲染 |
| [Flutter 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | 状态分层与重建范围 |
| [Android 发布指南](https://docs.flutter.dev/deployment/android) | 签名、构建与发布 |

> 「Jetpack Compose 声明式 UI」的链接用于离线阅读后的延伸核对；App 不会自动联网。
