## 零基础详解：Jetpack Compose 声明式 UI

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
