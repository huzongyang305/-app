# Jetpack Compose 声明式 UI

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![Jetpack Compose 重组与状态](images/diagram_mobile_compose.webp)

![Jetpack Compose 声明式 UI](images/category_mobile_compose.webp)

## 本节知识框架

**课程定位**：所属分类 `flutter`（移动开发），课程主题 `Jetpack Compose 声明式 UI`，学习阶段 进阶，建议用时 45 分钟。

本课主线：重组机制、状态提升、副作用与重组范围优化。

**学完本课应当能够**
- 说清 `状态提升` 与 `可组合函数` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `重组` 的行为，记录输入、输出与失败条件。
- 遇到「在 Composable 里发请求」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `状态提升`：先掌握 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试，再用它解释 `可组合函数` 为什么会出现。
2. `可组合函数`：先掌握 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」，再用它解释 `重组` 为什么会出现。
3. `重组`：先掌握 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树，再用它解释 `单向数据流` 为什么会出现。
4. `单向数据流`：先掌握 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理，再用它解释 `修饰符` 为什么会出现。
5. `修饰符`：先掌握 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「移动开发」分类的第 10 课。先修内容：《React Native 跨平台开发》。《React Native 跨平台开发》里的 `Hooks`、`原生模块` 是本课的前提。相关或后续课程：《鸿蒙 ArkTS 应用开发》。

### 完成判据

- **定义关**：不看正文也能说明 `状态提升` 是 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `Jetpack Compose 声明式 UI`，而不是只背结论。
- **示例关**：能运行或推演 `Jetpack Compose 声明式 UI` 的 `kotlin` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `Jetpack Compose 声明式 UI` 示例里的 调用了 `LessonScreen()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 在 Composable 里发请求，记录现象并按 用 `LaunchedEffect` 修复。
- **迁移关**：能把 `Compose`、`声明式UI`、`重组`、`状态提升` 放进一个与 `Jetpack Compose 声明式 UI` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `Jetpack Compose 声明式 UI` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| 状态提升 | 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。 | 易错：无法共享与测试；正确做法是状态提升到 ViewModel。 |
| 可组合函数 | 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。 | 缓存与状态残留会让结果过期，先明确失效策略再判断正确性。 |
| 重组 | 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。 | 易错：重组时重复请求；正确做法是用 `LaunchedEffect`。 |
| 单向数据流 | 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。 | 缓存与状态残留会让结果过期，先明确失效策略再判断正确性。 |
| 修饰符 | 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同 | 易错：样式与预期不符；正确做法是记住顺序有意义。 |

## 原理与运行机制

### 机制总览

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

**失败路径（来自本课错误表）**
- 在 Composable 里发请求 → 重组时重复请求 → 用 `LaunchedEffect`。
- 用普通变量存状态 → 界面不更新 → 用 `mutableStateOf`。
- 列表不给 key → 元素状态错位 → `key = { it.id }`。
- 修饰符顺序随意 → 样式与预期不符 → 记住顺序有意义。
### 机制拆解：每一步的输入、动作与输出

#### 1. `状态提升`
- 输入：`Compose`；本步把 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试 当作判断规则。
- 动作：围绕 `状态提升` 保留中间状态，并记录它与 `可组合函数` 的对应关系。
- 输出：`可组合函数`，它可以被下一段代码、测试或记录继续使用。
- `状态提升` 的失败条件：当状态放太深时，会出现无法共享与测试。

#### 2. `可组合函数`
- 输入：`状态提升`；本步把 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」 当作判断规则。
- 动作：围绕 `可组合函数` 保留中间状态，并记录它与 `重组` 的对应关系。
- 输出：`重组`，它可以被下一段代码、测试或记录继续使用。
- `可组合函数` 的失败条件：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。

#### 3. `重组`
- 输入：`可组合函数`；本步把 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树 当作判断规则。
- 动作：围绕 `重组` 保留中间状态，并记录它与 `单向数据流` 的对应关系。
- 输出：`单向数据流`，它可以被下一段代码、测试或记录继续使用。
- `重组` 的失败条件：当在 Composable 里发请求时，会出现重组时重复请求。

#### 4. `单向数据流`
- 输入：`重组`；本步把 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理 当作判断规则。
- 动作：围绕 `单向数据流` 保留中间状态，并记录它与 `修饰符` 的对应关系。
- 输出：`修饰符`，它可以被下一段代码、测试或记录继续使用。
- `单向数据流` 的失败条件：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。

#### 5. `修饰符`
- 输入：`单向数据流`；本步把 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同 当作判断规则。
- 动作：围绕 `修饰符` 保留中间状态，并记录它与 `LessonScreen` 的对应关系。
- 输出：`LessonScreen`，它可以被下一段代码、测试或记录继续使用。
- `修饰符` 的失败条件：当修饰符顺序随意时，会出现样式与预期不符。

### 示例中的可观察事实

1. 调用了 `LessonScreen()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
2. 调用了 `collectAsStateWithLifecycle()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
3. 调用了 `LaunchedEffect()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
4. 调用了 `load()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
5. 调用了 `Column()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
6. 调用了 `fillMaxSize()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
7. 调用了 `padding()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。
8. 调用了 `CircularProgressIndicator()`；它对应的课程主题是 `Jetpack Compose 声明式 UI`。

### 复现实验记录

- 环境：`Jetpack Compose 声明式 UI` 使用 `kotlin` 示例，固定 `Compose`、`声明式UI`、`重组`、`状态提升` 作为第一组条件。
- 首轮输入：先确认 调用了 `LessonScreen()`，预测 `状态提升` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `Compose`，观察 `修饰符` 是否仍满足定义。
- 失败注入：复现 在 Composable 里发请求，确认现象是 重组时重复请求。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `Jetpack Compose 声明式 UI` 时才能区分概念错误与实现错误。

## 典型应用场景

- **在 Composable 里发请求**：典型现象是重组时重复请求；正确做法是用 `LaunchedEffect`。
- **用普通变量存状态**：典型现象是界面不更新；正确做法是用 `mutableStateOf`。
- **列表不给 key**：典型现象是元素状态错位；正确做法是`key = { it.id }`。
- **修饰符顺序随意**：典型现象是样式与预期不符；正确做法是记住顺序有意义。

### 最小验证场景

- 准备：保留 `kotlin` 示例的原始输入，先记录 `Jetpack Compose 声明式 UI` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `LessonScreen()`，再改变一个与 `状态提升` 相关的条件。
- 判定：新结果与 `Jetpack Compose 声明式 UI` 的基线不同不等于错误；只有当差异破坏了 `状态提升` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `状态提升` 时，先满足它的定义：把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试；易错：无法共享与测试；正确做法是状态提升到 ViewModel。
- 使用 `可组合函数` 时，先满足它的定义：用 @Composable 标注的界面函数，描述「给定状态界面长什么样」；缓存与状态残留会让结果过期，先明确失效策略再判断正确性。
- 使用 `重组` 时，先满足它的定义：状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树；易错：重组时重复请求；正确做法是用 `LaunchedEffect`。
- 使用 `单向数据流` 时，先满足它的定义：状态向下传、事件向上抛，界面不直接改数据，便于测试与推理；缓存与状态残留会让结果过期，先明确失效策略再判断正确性。
- 使用 `修饰符` 时，先满足它的定义：修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同；易错：样式与预期不符；正确做法是记住顺序有意义。

## 代码/协议/SQL 示例

### 最小可验证示例

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

**运行方式**：运行 `Jetpack Compose 声明式 UI` 的示例时，用 `kotlinc` 编译或用 Gradle 任务运行；注意 JVM 目标版本。

### 示例精读：先找证据，再改一个条件

1. 调用了 `LessonScreen()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `collectAsStateWithLifecycle()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `LaunchedEffect()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `load()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `Column()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `fillMaxSize()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `padding()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `CircularProgressIndicator()`；它出现在 `Jetpack Compose 声明式 UI` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `Jetpack Compose 声明式 UI` 中与 `状态提升` 对照：示例必须能支持 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试，否则说明这一段还缺少实现或验证步骤。
- 在 `Jetpack Compose 声明式 UI` 中与 `可组合函数` 对照：示例必须能支持 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」，否则说明这一段还缺少实现或验证步骤。
- 在 `Jetpack Compose 声明式 UI` 中与 `重组` 对照：示例必须能支持 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树，否则说明这一段还缺少实现或验证步骤。
- 在 `Jetpack Compose 声明式 UI` 中与 `单向数据流` 对照：示例必须能支持 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（Jetpack Compose 声明式 UI）**：渲染与重建是主要开销：关注帧时间、重建次数与首屏耗时，热重载与 release 构建要分开记录。

**测量方法**：以 `Jetpack Compose 声明式 UI` 的 `Compose` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `Jetpack Compose 声明式 UI` 的 `Compose`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Jetpack Compose 声明式 UI` 的 `声明式UI`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Jetpack Compose 声明式 UI` 的 `重组`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Jetpack Compose 声明式 UI` 的 `状态提升`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Jetpack Compose 声明式 UI` 的 `LazyColumn`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Jetpack Compose 声明式 UI` 中 `状态提升` 的边界：易错：无法共享与测试；正确做法是状态提升到 ViewModel。达到边界时不要外推，必须重新测量。
- `Jetpack Compose 声明式 UI` 中 `可组合函数` 的边界：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。达到边界时不要外推，必须重新测量。
- `Jetpack Compose 声明式 UI` 中 `重组` 的边界：易错：重组时重复请求；正确做法是用 `LaunchedEffect`。达到边界时不要外推，必须重新测量。
- `Jetpack Compose 声明式 UI` 中 `单向数据流` 的边界：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。达到边界时不要外推，必须重新测量。
- `Jetpack Compose 声明式 UI` 中 `修饰符` 的边界：易错：样式与预期不符；正确做法是记住顺序有意义。达到边界时不要外推，必须重新测量。
- `Jetpack Compose 声明式 UI` 的代码证据：先验证 调用了 `LessonScreen()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 Composable 里发请求 | 重组时重复请求 | 用 `LaunchedEffect` |
| 用普通变量存状态 | 界面不更新 | 用 `mutableStateOf` |
| 列表不给 key | 元素状态错位 | `key = { it.id }` |
| 修饰符顺序随意 | 样式与预期不符 | 记住顺序有意义 |
| 列表项里做重计算 | 滚动卡顿 | 用 `remember` 缓存 |
| 忘记 `onDispose` | 监听器泄漏 | 用 `DisposableEffect` |
| 状态放太深 | 无法共享与测试 | 状态提升到 ViewModel |
| 过度使用 `derivedStateOf` | 逻辑绕 | 只在真正需要时用 |
| 列表滚动卡顿 | 每次重组都创建新对象 | 用 `key`、`remember`、稳定数据类 |
| 状态丢失 | 状态放在会被移除的组合中 | 状态提升或 `rememberSaveable` |
| 无限重组 | 在组合体里改状态 | 副作用移到 `LaunchedEffect` |
| 参数不稳定导致全量重组 | 传入可变集合或 lambda | 使用不可变集合、`@Stable` 标注 |
| 频繁布局读取 | 在组合阶段读 `Modifier` 布局信息 | 用 `Modifier.layout` 或 `derivedStateOf` |
| 在 composable 里直接发请求 | 每次重组都触发 | 放到 `LaunchedEffect` |
| 用普通变量存状态 | 界面不更新 | 用 `mutableStateOf` 或 `StateFlow` |
| 列表不写 `key` | 增删后状态错位 | `items(list, key = { it.id })` |
| 在组合体里读取 `LazyListState` 的滚动值 | 滚动时全量重组 | 用 `derivedStateOf` 包一层 |
| 传可变集合给子组件 | 无法跳过重组 | 用 `ImmutableList` 或不可变结构 |
| 把 `remember` 当全局缓存 | 状态意外保留或丢失 | 明确生命周期，必要时提升状态 |
| 忽略 `Modifier` 顺序 | 内边距与裁剪效果不符合预期 | 顺序即执行顺序，按需调整 |
| 列表不写 key | 增删后状态错位。 | items(list, key = { it.id })。 |
| 在组合体里读取 LazyListState 的滚动值 | 滚动时全量重组。 | 用 derivedStateOf 包一层。 |

### 现场 1：在 Composable 里发请求

**症状**：重组时重复请求。

**根因与修复**：用 `LaunchedEffect`。

**自检**：在本课示例里复现「在 Composable 里发请求」，改成用 `LaunchedEffect`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：用普通变量存状态

**症状**：界面不更新。

**根因与修复**：用 `mutableStateOf`。

**自检**：在本课示例里复现「用普通变量存状态」，改成用 `mutableStateOf`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：列表不给 key

**症状**：元素状态错位。

**根因与修复**：`key = { it.id }`。

**自检**：在本课示例里复现「列表不给 key」，改成`key = { it.id }`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：修饰符顺序随意

**症状**：样式与预期不符。

**根因与修复**：记住顺序有意义。

**自检**：在本课示例里复现「修饰符顺序随意」，改成记住顺序有意义后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：列表项里做重计算

**症状**：滚动卡顿。

**根因与修复**：用 `remember` 缓存。

**自检**：在本课示例里复现「列表项里做重计算」，改成用 `remember` 缓存后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：忘记 `onDispose`

**症状**：监听器泄漏。

**根因与修复**：用 `DisposableEffect`。

**自检**：在本课示例里复现「忘记 `onDispose`」，改成用 `DisposableEffect`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：状态放太深

**症状**：无法共享与测试。

**根因与修复**：状态提升到 ViewModel。

**自检**：在本课示例里复现「状态放太深」，改成状态提升到 ViewModel后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：过度使用 `derivedStateOf`

**症状**：逻辑绕。

**根因与修复**：只在真正需要时用。

**自检**：在本课示例里复现「过度使用 `derivedStateOf`」，改成只在真正需要时用后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：列表滚动卡顿

**症状**：每次重组都创建新对象。

**根因与修复**：用 `key`、`remember`、稳定数据类。

**自检**：在本课示例里复现「列表滚动卡顿」，改成用 `key`、`remember`、稳定数据类后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

**教材衔接：与 View 体系对照**

| 维度 | View / XML | Compose |
| --- | --- | --- |
| 描述方式 | 命令式、可变树 | 声明式、状态驱动 |
| 更新 | 手动查找并修改视图 | 状态变化自动重组 |
| 可测试性 | 依赖 Espresso 查找视图 | 用测试规则直接断言节点 |
| 动画 | 属性动画 | `animate*AsState`、`Transition` |
| 复用 | `<include>`、自定义 View | 可组合函数天然复用 |

- **先修**：`React Native 跨平台开发`。本课默认这些内容已经掌握。
- **相关或后续**：`鸿蒙 ArkTS 应用开发`。本课术语会在这些课程里继续使用。
- **术语归属**：`状态提升`、`可组合函数`、`重组` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。

### 先修与后续术语接口

- `React Native 跨平台开发`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `鸿蒙 ArkTS 应用开发`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `状态提升` 与 `可组合函数`：前者强调 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试；后者强调 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `可组合函数` 与 `重组`：前者强调 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」；后者强调 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `重组` 与 `单向数据流`：前者强调 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树；后者强调 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `单向数据流` 与 `修饰符`：前者强调 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理；后者强调 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `状态提升` 的操作性定义，并说明它与 `可组合函数` 的区别。

**参考答案**：把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。

`可组合函数` 的定位是：用 @Composable 标注的界面函数，描述「给定状态界面长什么样」；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「在 Composable 里发请求」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是重组时重复请求；正确做法是用 `LaunchedEffect`。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `kotlin` 示例，把其中的 `16` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `kotlin` 示例应当复现正文给出的结果；把 `16` 换成边界值后，如果结果改变或报错，先核对它是否满足 `Jetpack Compose 声明式 UI` 中`状态提升` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `kotlin` 示例，说明它体现了`状态提升` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`状态提升` 的定义是 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试，示例正是在实现这条定义。改动与 `状态提升` 有关的一个输入后，如果结果不再符合 `Jetpack Compose 声明式 UI` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `Jetpack Compose 声明式 UI` 的方法迁移到自己的项目：围绕 `状态提升` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「在组合体里读取 LazyListState 的滚动值」，它会导致滚动时全量重组；检验方式是按用 derivedStateOf 包一层改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `状态提升` 与 `可组合函数`：各写一行适用场景、一行失败表现。

**参考答案**：`状态提升` 的定义是把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试；`可组合函数` 的定义是用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「在 Composable 里发请求」引发的问题，请把“复现 重组时重复请求 → 保留证据 → 用 `LaunchedEffect` → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按重组时重复请求复现；第二步记录输入、版本与完整报错；第三步按用 `LaunchedEffect`只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `修饰符`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：样式与预期不符；正确做法是记住顺序有意义。 同时要把 `修饰符` 的定义 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `状态提升` → `可组合函数` → `重组` → `单向数据流` 的作用链。

**参考答案**：起点是 `状态提升` 的定义 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试；中间每一步都保留可观察状态；终点由 `修饰符` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `Jetpack Compose 声明式 UI` 中，现象是 滚动时全量重组。请围绕 在组合体里读取 LazyListState 的滚动值 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 在组合体里读取 LazyListState 的滚动值，记录输入与完整错误；再按 用 derivedStateOf 包一层 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `Jetpack Compose 声明式 UI`：先给主问题，再按顺序说出 `状态提升`、`可组合函数`、`重组`、`单向数据流`，最后给一个失败案例。

**自评标准**：主问题必须对应 重组机制、状态提升、副作用与重组范围优化；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `状态提升` | 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。 |
| `可组合函数` | 用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。 |
| `重组` | 状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。 |
| `单向数据流` | 状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。 |
| `修饰符` | 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同。 |

**术语关系**：`状态提升`（把状态从子组件提到共同父级） → `可组合函数`（用 @Composable 标注的界面函数） → `重组`（状态变化后 Compose 只重新执行受影响的可组合函数） → `单向数据流`（状态向下传、事件向上抛）。

## 考点精讲

`Jetpack Compose 声明式 UI` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：按“Jetpack Compose 声明式 UI”中 Compose、声明式UI、重组 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **正确项**：先明确 Compose 的输入、输出与约束 → 写出最小示例并核对 声明式UI 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把“Jetpack Compose 声明式 UI”的结论写成可复现记录
- **判断依据**：这道题落在术语 `重组` 上：状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。复习时把 `重组` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：围绕“Jetpack Compose 声明式 UI”中的 Compose、声明式UI、重组，下列哪两项是本课强调的实践判断？
- **正确项**：学习 Compose 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 声明式UI 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `重组` 上：状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。复习时把 `重组` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：关于派生状态 derivedStateOf，说法正确的是？
- **正确项**：它能减少因状态频繁变化导致的重组
- **判断依据**：这道题落在术语 `重组` 上：状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。复习时把 `重组` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：状态提升（state hoisting）的主要目的是？
- **正确项**：让组件无状态、易于复用与测试
- **判断依据**：这道题落在术语 `状态提升` 上：把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。复习时把 `状态提升` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：下面哪种写法最容易造成无限重组？
- **正确项**：在 composable 函数体里直接修改状态
- **判断依据**：这道题落在术语 `重组` 上：状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。若写成 无限重组 就会在组合体里改状态，应按 副作用移到 `LaunchedEffect` 处理。

### 考点 6：第 6 题

- **题目**：结合 `Jetpack Compose 声明式 UI` 中围绕 `状态提升` 的代码，哪一项说法与“重组机制、状态提升、副作用与重组范围优化。”一致？
- **正确项**：放在 LaunchedEffect 中
- **判断依据**：这道题落在术语 `状态提升` 上：把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。复习时把 `状态提升` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`状态提升`

- **要点**：把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。
- **状态提升 的边界**：易错：无法共享与测试；正确做法是状态提升到 ViewModel。

### 考点 8：`可组合函数`

- **要点**：用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。
- **可组合函数 的边界**：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。

### 考点 9：`重组`

- **要点**：状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。
- **重组 的边界**：易错：重组时重复请求；正确做法是用 `LaunchedEffect`。

### 考点 10：`单向数据流`

- **要点**：状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。
- **单向数据流 的边界**：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。

### 考点 11：`修饰符`

- **要点**：修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同
- **修饰符 的边界**：易错：样式与预期不符；正确做法是记住顺序有意义。

### 考点 12：排错——在 Composable 里发请求

- **现象**：重组时重复请求。
- **处理**：用 `LaunchedEffect`。

### 考点 13：排错——用普通变量存状态

- **现象**：界面不更新。
- **处理**：用 `mutableStateOf`。

### 考点 14：综合辨析——`状态提升` 与 `修饰符`

- **辨析点**：`状态提升` 的定义是 把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试；`修饰符` 的定义是 修饰符顺序有影响：padding 在 background 之前与之后，效果完全不同。
- **答题要求**：面对 `Jetpack Compose 声明式 UI` 的题目，先判断描述的是 `状态提升` 还是 `修饰符`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 15：排错评分点

- **现象分**：能写出 重组时重复请求，而不是只写“程序有错”。
- **证据分**：保留触发 在 Composable 里发请求 的输入、版本和错误原文。
- **修复分**：按 用 `LaunchedEffect` 只改一处，并同时回归正常路径与边界路径。

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
- 来源性质：官方文档、标准或权威教材；本课核对关键词：Compose、声明式UI、重组、状态提升、LazyColumn。

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter UI 文档](https://docs.flutter.dev/ui) | Widget、布局与渲染 |
| [Flutter 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | 状态分层与重建范围 |
| [Android 发布指南](https://docs.flutter.dev/deployment/android) | 签名、构建与发布 |

| [本课术语索引：Jetpack Compose 声明式 UI](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「Jetpack Compose 声明式 UI」的链接用于离线阅读后的延伸核对；App 不会自动联网。