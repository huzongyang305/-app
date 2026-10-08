# Kotlin 与 Android 开发

![Kotlin Android 开发的关键能力](images/diagram_mobile_kotlin.webp)

![Kotlin 与 Android 开发](images/category_mobile_kotlin.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「移动开发」，课程主题为「Kotlin 与 Android 开发」，学习阶段为「基础」，建议用时 50 分钟。

**本课要解决的主问题**：空安全、协程、分层架构与打包发布。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Kotlin 与 Android 开发」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Kotlin 与 Android 开发」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Kotlin」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《实战：Flutter 打包发布 Android》

**学习位置**：本课位于《实战：Flutter 打包发布 Android》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Swift 与 iOS 开发》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Kotlin 与 Android 开发解决了什么问题，而不是只背术语。
- 能说清 「Kotlin」、「Android」、「协程」、「ViewModel」 之间的关系，并分别举出一个例子。
- 能把 Kotlin 放回「Kotlin 与 Android 开发」的知识体系，说明它和 Android 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：空安全、协程、分层架构与打包发布。

**教材衔接：前置知识**

- 先完成上一课《实战：Flutter 打包发布 Android》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议先完成「实战：Flutter 打包发布 Android」，或确认自己能独立跑通正文里的 LessonRepository 示例。
- 开始前先复习：Kotlin、Android、协程。
- 如果 语言特性速览 这一步看不懂，先记录具体卡点，再用 LessonRepository 复现一遍。

**教材衔接：本课小结**

Android 开发的关键是**分层（UI/状态/数据）+ 空安全 + 协程**：把状态交给 ViewModel、把耗时操作交给协程、把数据来源收敛到 Repository。

## 核心概念定义

> 阅读约定：本课先给「Kotlin 与 Android 开发」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Kotlin | 运行于 JVM 等平台、强调空安全与简洁语法的现代编程语言。 | 仅在「Kotlin 与 Android 开发」明确给出的输入、版本与资源条件下成立。 |
| Android | Android 开发的关键是分层（UI/状态/数据）+ 空安全 + 协程：把状态交给 ViewModel、把耗时操作交给协程、把数据来源收敛到 Repository。 | 仅在「Kotlin 与 Android 开发」明确给出的输入、版本与资源条件下成立。 |
| AAB | Android App Bundle 发布格式，由应用商店按设备配置生成拆分后的 APK。 | 仅在「Kotlin 与 Android 开发」明确给出的输入、版本与资源条件下成立。 |
| 构建变体 | debug、release 等不同配置的产物，用变体维度管理签名、混淆与接口地址。 | 仅在「Kotlin 与 Android 开发」明确给出的输入、版本与资源条件下成立。 |
| 协程 | 协程把耗时工作挪出主线程 | 仅在「Kotlin 与 Android 开发」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Kotlin 与 Android 开发」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Kotlin」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「Android」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「AAB」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Kotlin 与 Android 开发」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Kotlin | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | Android | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | AAB | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Kotlin 与 Android 开发」自己的示例验证。「Kotlin 与 Android 开发」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：语言特性速览**

| 特性 | 说明 |
| --- | --- |
| 空安全 | 类型区分可空与非空，`?.`/`?:`/`!!` 显式处理空值 |
| 数据类 | `data class User(val id: Int, val name: String)` 自动生成 equals/hashCode/copy |
| 扩展函数 | 给已有类加方法而不继承，如 `fun String.toSlug()` |
| 协程 | `suspend` + `launch`/`async`，用同步写法表达异步逻辑 |
| 密封类 | `sealed class Result` 表达有限状态，配合 when 穷尽检查 |
| 属性委托 | `by lazy`、`by viewModels()` 减少样板代码 |

**教材衔接：生命周期与常见崩溃**

1. 配置变更（旋转）会重建 Activity，状态放 ViewModel 而非成员变量。
2. 持有 Activity/Context 的长时间引用会内存泄漏（用 applicationContext 或在 onDestroy 释放）。
3. 后台启动 Service 受限，长任务改用 WorkManager 或前台服务。
4. 主线程做 IO 会 ANR，所有磁盘与网络访问走协程。

**教材衔接：打包发布**

`./gradlew bundleRelease` 产出 AAB；签名用 `keystore.properties` 外置并在 .gitignore 排除；用 `minifyEnabled true` 加混淆规则减小体积；多渠道与不同环境通过 productFlavors 配置；上线前用 `lint` 检查权限与 API 使用问题。

**教材衔接：Android 组件速查**

| 组件 | 职责 | 注意 |
| --- | --- | --- |
| Activity | 承载界面 | 避免放业务逻辑 |
| Fragment | 可复用界面块 | 生命周期复杂，注意视图销毁 |
| ViewModel | 保存界面状态 | 不持有 View 引用 |
| Repository | 数据来源统一入口 | 负责缓存策略 |
| WorkManager | 可靠后台任务 | 适合可延迟任务 |
| Foreground Service | 前台服务 | 需通知与权限说明 |
| Room | 本地数据库 | 用 DAO 与 Flow 观察数据 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Kotlin、Android | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Kotlin 与 Android 开发」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Kotlin 与 Android 开发」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**教材衔接：Android 应用结构**

| 层 | 组件 | 职责 |
| --- | --- | --- |
| UI | Activity / Fragment / Compose | 展示与交互 |
| 状态 | ViewModel + StateFlow | 持有界面状态，配置变更后存活 |
| 数据 | Repository + Room/Retrofit | 统一数据来源（本地缓存 + 网络） |
| 后台 | WorkManager | 可延迟、需保证执行的任务 |

要点：**不要在 Activity 里写业务逻辑**；网络与数据库操作必须离开主线程（协程的 Dispatchers.IO）；用 `viewLifecycleOwner` 收集 Flow 避免泄漏。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Kotlin 与 Android 开发》原文中的最小示例。先预测《Kotlin 与 Android 开发》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```kotlin
// ViewModel：状态用 StateFlow 暴露，UI 只读订阅
data class UiState(
    val loading: Boolean = false,
    val items: List<String> = emptyList(),
    val error: String? = null,
)

class LessonViewModel(private val repo: LessonRepository) : ViewModel() {
    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _state.update { it.copy(loading = true, error = null) }
            runCatching { withContext(Dispatchers.IO) { repo.fetch() } }
                .onSuccess { list -> _state.update { it.copy(loading = false, items = list) } }
                .onFailure { e -> _state.update { it.copy(loading = false, error = e.message) } }
        }
    }
}

// 可空链式处理：任一步为空即短路
fun displayName(user: User?): String =
    user?.profile?.nickname?.takeIf { it.isNotBlank() } ?: "匿名用户"
```

**教材衔接：Kotlin 语法速查**

| 特性 | 写法 | 说明 |
| --- | --- | --- |
| 只读变量 | `val name = "x"` | 引用不可重新赋值 |
| 可空类型 | `String?` | 必须显式处理空值 |
| 安全调用 | `name?.length` | 为空返回 null |
| 埃尔维斯 | `name ?: "默认"` | 空值兜底 |
| 非空断言 | `name!!` | 为空即崩溃，尽量不用 |
| 数据类 | `data class User(val id: Long)` | 自动生成 equals / copy |
| 密封类 | `sealed interface Result` | 穷尽分支的联合类型 |
| 扩展函数 | `fun String.shout() = uppercase()` | 不修改原类即可扩展 |
| 作用域函数 | `apply`、`let`、`run`、`also` | 简化初始化与空值处理 |
| 协程 | `suspend fun load()` | 可挂起的异步函数 |

**教材衔接：协程速查**

| 作用域 | 生命周期 | 适用 |
| --- | --- | --- |
| `viewModelScope` | 与 ViewModel 一致 | 界面数据加载 |
| `lifecycleScope` | 与 Activity/Fragment 一致 | 界面相关任务 |
| `applicationScope` | 与应用一致 | 全局后台任务 |
| `GlobalScope` | 不受限 | **禁止使用** |

| 概念 | 说明 |
| --- | --- |
| `Dispatchers.Main` | 主线程，更新 UI |
| `Dispatchers.IO` | 阻塞 IO |
| `Dispatchers.Default` | CPU 密集计算 |
| `withContext` | 切换线程并返回结果 |
| `Flow` | 冷数据流，支持背压 |
| `StateFlow` | 有状态热流，适合 UI 状态 |

```kotlin
// ViewModel：状态用 StateFlow 暴露，UI 只读订阅
data class UiState(
    val loading: Boolean = false,
    val items: List<String> = emptyList(),
    val error: String? = null,
)

class LessonViewModel(private val repo: LessonRepository) : ViewModel() {
    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _state.update { it.copy(loading = true, error = null) }
            runCatching { withContext(Dispatchers.IO) { repo.fetch() } }
                .onSuccess { list -> _state.update { it.copy(loading = false, items = list) } }
                .onFailure { e -> _state.update { it.copy(loading = false, error = e.message) } }
        }
    }
}

// 可空链式处理：任一步为空即短路
fun displayName(user: User?): String =
    user?.profile?.nickname?.takeIf { it.isNotBlank() } ?: "匿名用户"
```

**教材衔接：零基础详解：Kotlin 与 Android 开发**

### 一句话说清它是什么

Kotlin 是 Android 的官方首选语言，核心优势是**空安全、简洁、协程**。
Android 侧的工程要点是：**UI 层不写业务、状态放 ViewModel、耗时工作交给协程**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 可空类型 `?` | 贴了「可能空的标签」 | 用前必须处理 |
| `val` / `var` | 只读标签 / 可改标签 | 默认用 `val` |
| 数据类 | 自动生成的信息卡 | 自带 `equals`、`copy` |
| 扩展函数 | 给别人的类加方法 | 不改源码就能扩展 |
| 协程 | 可暂停的轻量任务 | 挂起而不阻塞线程 |
| ViewModel | 页面专属的数据管家 | 旋转屏幕后仍存活 |

### 空安全：Kotlin 最值钱的设计

```kotlin
var name: String = "小明"
var nickname: String? = null          // 加了 ? 才能为 null

// 编译期就拦住：println(nickname.length) 无法编译
println(nickname?.length ?: 0)        // 安全调用加默认值
println(nickname?.length ?: "未填写")

nickname?.let { value ->              // 非空时才执行
    println("昵称长度 ${value.length}")
}

// 只在确实不可能为空时使用，且要能说出理由
val forced = nickname!!.length
```

| 写法 | 含义 |
| --- | --- |
| `String` | 一定不为空 |
| `String?` | 可能为空 |
| `?.` | 为空就返回 null |
| `?:` | 为空时取默认值 |
| `!!` | 断言非空，为空就抛异常（慎用） |

### 数据类与扩展函数

```kotlin
data class User(
    val id: Long,
    val name: String,
    val email: String? = null,
)

val a = User(1, "小明")
val b = a.copy(name = "小红")          // 非破坏性修改
println(a == User(1, "小明"))          // true，按值比较

fun String.toInitials(): String =
    split(" ").mapNotNull { it.firstOrNull() }.joinToString("")

println("Xiao Ming".toInitials())      // XM
```

### 协程：把耗时工作挪出主线程

```kotlin
class UserViewModel(
    private val repository: UserRepository,
) : ViewModel() {

    private val _state = MutableStateFlow<UiState>(UiState.Loading)
    val state: StateFlow<UiState> = _state.asStateFlow()

    fun load(userId: Long) {
        viewModelScope.launch {                 // 绑定 ViewModel 生命周期
            _state.value = UiState.Loading
            _state.value = try {
                UiState.Success(repository.find(userId))
            } catch (e: IOException) {
                UiState.Failure("网络异常，请重试")
            }
        }
    }
}

sealed interface UiState {
    data object Loading : UiState
    data class Success(val user: User) : UiState
    data class Failure(val message: String) : UiState
}
```

| 作用域 | 生命周期 | 用途 |
| --- | --- | --- |
| `viewModelScope` | 跟随 ViewModel | 页面数据加载 |
| `lifecycleScope` | 跟随 Activity 或 Fragment | 界面相关任务 |
| `applicationScope` | 跟随进程 | 全局后台任务 |

**不要在 `GlobalScope` 里启动协程**：它不受生命周期约束，容易泄漏。

### Compose 中的状态

```kotlin
@Composable
fun UserScreen(viewModel: UserViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    when (val s = state) {
        UiState.Loading -> CircularProgressIndicator()
        is UiState.Failure -> ErrorMessage(s.message, onRetry = { viewModel.load(1) })
        is UiState.Success -> UserCard(s.user)
    }
}

@Composable
private fun UserCard(user: User) {
    Card {
        Column(Modifier.padding(16.dp)) {
            Text(user.name, style = MaterialTheme.typography.titleMedium)
            user.email?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
        }
    }
}
```

**要点**：`collectAsStateWithLifecycle` 会在界面不可见时自动停止收集，省电。

### Android 分层

```text
app/
  ui/             Compose 界面与 ViewModel
  domain/         业务模型与用例
  data/
    local/        数据库（Room）
    remote/       Retrofit 接口
    repository/   组合本地与远端
```

**原则**：UI 只依赖 ViewModel 暴露的状态；Repository 负责决定数据从缓存还是网络来。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 在 UI 里发网络请求 | 旋转屏幕后重复请求、崩溃 | 放 ViewModel |
| 用 `!!` 图省事 | 线上空指针崩溃 | 用 `?.` 与 `?:` |
| 在主线程做耗时操作 | 界面卡顿或 ANR | 用协程切换 IO 调度器 |
| 用 `GlobalScope` | 协程泄漏 | 用 `viewModelScope` |
| 状态可变且多处修改 | 界面不同步 | 单一数据源加不可变状态 |
| 忘记处理失败态 | 出错白屏 | 四态齐全 |
| 在 Composable 里做副作用 | 重组时重复执行 | 用 `LaunchedEffect` |
| 数据库操作在主线程 | 报错或卡顿 | Room 加挂起函数 |

### 手把手练习：带四态的列表页

```kotlin
class ListViewModel(private val repo: ItemRepository) : ViewModel() {
    private val _state = MutableStateFlow<ListUiState>(ListUiState.Loading)
    val state: StateFlow<ListUiState> = _state.asStateFlow()

    init { refresh() }

    fun refresh() {
        viewModelScope.launch {
            _state.value = ListUiState.Loading
            runCatching { repo.all() }
                .onSuccess { items ->
                    _state.value = if (items.isEmpty()) {
                        ListUiState.Empty
                    } else {
                        ListUiState.Success(items)
                    }
                }
                .onFailure { _state.value = ListUiState.Failure(it.message ?: "加载失败") }
        }
    }
}

sealed interface ListUiState {
    data object Loading : ListUiState
    data object Empty : ListUiState
    data class Success(val items: List<Item>) : ListUiState
    data class Failure(val message: String) : ListUiState
}
```

### 学完自测

- [ ] 能说出 `String` 与 `String?` 的区别。
- [ ] 知道为什么不该用 `!!`。
- [ ] 能说出 `viewModelScope` 与 `GlobalScope` 的差别。
- [ ] 知道为什么状态要放在 ViewModel 里。
- [ ] 能说出 Compose 里副作用的正确位置。

## 时间/空间复杂度或性能分析

**复杂度证据**：「Kotlin 与 Android 开发」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Kotlin 与 Android 开发」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Kotlin 与 Android 开发」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《Kotlin 与 Android 开发》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Kotlin 与 Android 开发」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 滥用 `!!` | 线上崩溃 | 用 `?.`、`?:` 或 `requireNotNull` |
| 在 `ViewModel` 里持有 Activity | 内存泄漏 | 只持有 Application 或数据层 |
| 主线程做 IO | 界面卡顿甚至 ANR | 切到 `Dispatchers.IO` |
| 用 `GlobalScope` | 任务泄漏、难以取消 | 用受生命周期约束的作用域 |
| Fragment 中直接碰已销毁视图 | 崩溃 | 在 `onDestroyView` 后置空绑定 |
| 手写大量 `findViewById` | 易错 | 用 ViewBinding |
| 在协程外抛异常未捕获 | 崩溃 | 用 `runCatching` 或 `CoroutineExceptionHandler` |
| 忘记处理配置变更 | 数据丢失 | 状态放 `ViewModel` 或用 `SavedStateHandle` |
| 用字符串拼 SQL | 注入风险 | Room 或参数化查询 |
| 权限未做兼容处理 | 新系统版本崩溃 | 按版本分支申请权限 |

**教材衔接：故障现场**

### 现场 1：主线程做 IO

**症状**：在《Kotlin 与 Android 开发》的复现场景中，界面卡顿甚至 ANR。

**根因**：当出现“主线程做 IO”时，执行路径已经绕过了《Kotlin 与 Android 开发》的关键约束，最终以“界面卡顿甚至 ANR”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Kotlin 与 Android 开发》的问题，切到 Dispatchers.IO。

**验证**：保留《Kotlin 与 Android 开发》里触发“界面卡顿甚至 ANR”的输入、版本和日志，按“切到 Dispatchers.IO”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：用 GlobalScope

**症状**：在《Kotlin 与 Android 开发》的复现场景中，任务泄漏、难以取消。

**根因**：当出现“用 GlobalScope”时，执行路径已经绕过了《Kotlin 与 Android 开发》的关键约束，最终以“任务泄漏、难以取消”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Kotlin 与 Android 开发》的问题，用受生命周期约束的作用域。

**验证**：在《Kotlin 与 Android 开发》中按“用受生命周期约束的作用域”调整后，从“用 GlobalScope”的触发条件重放同一条路径，确认“任务泄漏、难以取消”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：权限未做兼容处理

**症状**：在《Kotlin 与 Android 开发》的复现场景中，新系统版本崩溃。

**根因**：触发点是把“权限未做兼容处理”当成安全做法。它没有满足《Kotlin 与 Android 开发》要求的前提，因此先表现为“新系统版本崩溃”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Kotlin 与 Android 开发》的问题，按版本分支申请权限。

**验证**：保留《Kotlin 与 Android 开发》里触发“新系统版本崩溃”的输入、版本和日志，按“按版本分支申请权限”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《实战：Flutter 打包发布 Android》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Swift 与 iOS 开发》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《Kotlin Android 架构》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《实战：Flutter 打包发布 Android》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Swift 与 iOS 开发》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Kotlin 与 Android 开发」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Kotlin 与 Android 开发》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“Kotlin 与 Android 开发”中的 Kotlin、Android、协程，下列哪两项是本课强调的实践判断？

A. 学习 Kotlin 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 Kotlin 的常规示例通过，就可以跳过边界与异常路径
C. 验证 Android 时要固定版本并覆盖边界输入，结论才可复现
D. 把 Android 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 Kotlin 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Android 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把Kotlin 与 Android 开发拆成概念、示例与故障现场三部分，因此判断 Kotlin 时必须同时交代输入、输出和失败路径，这使“学习 Kotlin 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Kotlin 与 Android 开发里，判断 Android 时要固定版本与边界输入，所以“验证 Android 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

Android 中承载界面状态、配置变更后仍存活的组件是？

A. Adapter
B. Activity
C. ViewModel
D. Application

**参考答案**：ViewModel

**解析**：在「Kotlin 与 Android 开发」里，Activity 旋转会重建，状态应放在 ViewModel 中。在「Kotlin 与 Android 开发」里，其他选项：Application 是进程级入口，Adapter 负责列表项绑定，Activity 在配置变更时会重建。

### 自测 3

下面这段 Kotlin 代码摘自「Kotlin 与 Android 开发」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

```kotlin
class UserViewModel(
    private val repository: UserRepository,
) : ViewModel() {

    private val _state = MutableStateFlow<UiState>(UiState.Loading)
    val state: StateFlow<UiState> = _state.asStateFlow()

    fun load(userId: Long) {
        viewModelScope.launch {                 // 绑定 ViewModel 生命周期
            _state.value = UiState.Loading
            _state.value = try {
                UiState.Success(repository.find(userId))
            } catch (e: IOException) {
                UiState.Failure("网络异常，请重试")
            }
        }
    }
}

sealed interface UiState {
    data object Loading : UiState
    data class Success(val user: User) : UiState
    data class Failure(val message: String) : UiState
}
```

A. 这段代码包含循环结构，同一段逻辑会被重复执行。
B. 这段代码包含异常处理分支，失败时会走专门的补救路径。
C. 这段代码会产生可观察的输出，运行后能看到结果。
D. 这段代码只做静态声明，没有循环、分支或可观察输出。

**参考答案**：这段代码包含异常处理分支，失败时会走专门的补救路径。

**解析**：在「Kotlin 与 Android 开发」里，这段代码包含异常处理分支，失败时会走专门的补救路径。这段代码出自「Kotlin 与 Android 开发」的正文示例，围绕Kotlin、Android、协程展开；把输入或边界换成空值、极值或失败情况后，结论要以「Kotlin 与 Android 开发」的实际运行结果为准。

**教材衔接：复习与自测**

- [ ] 空安全用 `?.`、`?:` 处理，`!!` 只出现在确定非空处。
- [ ] 协程绑定合适作用域，禁止 `GlobalScope`。
- [ ] 状态用 `StateFlow` 暴露，UI 只读订阅。
- [ ] ViewModel 不持有 View 或 Activity 引用。
- [ ] 后台任务与权限按系统版本做兼容处理。

**教材衔接：动手练习**

> 本课练习重点：围绕「Kotlin、Android、协程」完成复述、实验和交付，每个结果都要能被别人检查。

先固定 Android 的约束，再验证不同屏幕宽度下的表现。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Kotlin 与 Android 开发解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Android」是什么关系？

验收标准：回答里必须出现 Kotlin，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「语言特性速览」里找一个可运行的最小输入，再按五步法记录Kotlin的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

用最小 Widget 验证 Android 在空数据与超长文本下的表现。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Kotlin」和「Android」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Kotlin 与 Android 开发安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Kotlin 与 Android 开发」的结构，画完再对照骨架：

- 主干：语言特性速览 → Android 应用结构 → 生命周期与常见崩溃 → 打包发布
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Kotlin与Android的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案至少在一个输入上给出不同结果；把差异归因到Kotlin，而不是笼统地写「性能更好」。

### 任务 3：迁移到自己的场景

**验收标准**：结论要能追溯到「语言特性速览」的具体段落，并说明它和 Android 的边界。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Kotlin 中表示「可能为空」的类型写法是？」的判断依据。
- [ ] 不看解析，能说出「Android 中承载界面状态、配置变更后仍存活的组件是？」的判断依据。
- [ ] 不看解析，能说出「Android 上架 Google Play 推荐的产物格式是？」的判断依据。
- [ ] 不看解析，能说出「Kotlin 中 val 与 var 的区别是？」的判断依据。
- [ ] 不看解析，能说出「在 Activity 中启动一个随生命周期自动取消的协程，常用写法是？」的判断依据。
- [ ] 用 Kotlin 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「Kotlin 与 Android 开发」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Kotlin` | 运行于 JVM 等平台、强调空安全与简洁语法的现代编程语言。 |
| `Android` | Android 开发的关键是分层（UI/状态/数据）+ 空安全 + 协程：把状态交给 ViewModel、把耗时操作交给协程、把数据来源收敛到 Repository。 |
| `AAB` | Android App Bundle 发布格式，由应用商店按设备配置生成拆分后的 APK。 |
| `构建变体` | debug、release 等不同配置的产物，用变体维度管理签名、混淆与接口地址。 |
| `协程` | 协程把耗时工作挪出主线程 |

## 考点精讲

### 考点 1：多选辨析·Kotlin

- **题目**：围绕“Kotlin 与 Android 开发”中的 Kotlin、Android、协程，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Kotlin 与 Android 开发拆成概念、示例与故障现场三部分，因此判断 Kotlin 时必须同时交代输入、输出和失败路径，这使“学习 Kotlin 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Kotlin 与 Android 开发里，判断 Android 时要固定版本与边界输入，所以“验证 Android 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·Kotlin

- **题目**：Android 中承载界面状态、配置变更后仍存活的组件是？
- **判断依据**：在「Kotlin 与 Android 开发」里，Activity 旋转会重建，状态应放在 ViewModel 中。在「Kotlin 与 Android 开发」里，其他选项：Application 是进程级入口，Adapter 负责列表项绑定，Activity 在配置变更时会重建。

### 考点 3：概念判断·Kotlin

- **题目**：Android 上架 Google Play 推荐的产物格式是？
- **判断依据**：AAB 让商店按设备下发，减小下载体积。其他选项：JAR 不是 Android 产物，DEX 是字节码格式，APK 虽可安装但并非商店推荐。如果只凭关键词作答，很容易把「JAR」、「APK」与「AAB」混在一起；这道题的关键在「Kotlin 与 Android 开发」的Kotlin、Android、协程：先确认题干“Android 上架 Google”问的是哪一步，再排除偷换前提的选项。

### 考点 4：代码补全·Kotlin

- **题目**：下面这段 Kotlin 代码摘自「Kotlin 与 Android 开发」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「Kotlin 与 Android 开发」里，这段代码包含异常处理分支，失败时会走专门的补救路径。这段代码出自「Kotlin 与 Android 开发」的正文示例，围绕Kotlin、Android、协程展开；把输入或边界换成空值、极值或失败情况后，结论要以「Kotlin 与 Android 开发」的实际运行结果为准。

### 考点 5：概念判断·Kotlin

- **题目**：在 Activity 中启动一个随生命周期自动取消的协程，常用写法是？
- **判断依据**：在「Kotlin 与 Android 开发」里，lifecycleScope.launch { }。lifecycleScope 绑定组件生命周期，销毁时自动取消，避免泄漏。「Kotlin 与 Android 开发」要求先交代Kotlin、Android、协程的前提再下结论，所以“lifecycleScope.launc”只在题干“在 Activity 中启动一个随生命周期自动取消的协程”给定的条件下成立。

### 考点 6：顺序排列·Kotlin

- **题目**：按照「Kotlin 与 Android 开发」从概念到实践的讲解顺序排列下列主题。
- **判断依据**：在「Kotlin 与 Android 开发」里，正确的执行顺序是「语言特性速览」 → 「Android 应用结构」 → 「生命周期与常见崩溃」 → 「打包发布」。在「Kotlin 与 Android 开发」里，在本课中，正确顺序是：1. 语言特性速览 → 2. Android 应用结构 → 3. 生命周期与常见崩溃 → 4. 打包发布。

## English Overview

**Title:** Kotlin & Android

**Summary:** Null safety, coroutines, layering and release.

**Category:** Mobile Development
**Level:** 基础
**Key terms:** Kotlin, Android, 协程, ViewModel, AAB

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Flutter 3.x / Dart 3.x；本课聚焦 Kotlin。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Kotlin、Android、协程、ViewModel、AAB
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Android 发布指南](https://docs.flutter.dev/deployment/android) | 签名、构建与发布 |
| [Dart 语言文档](https://dart.dev/language) | 语言语法、类型与空安全 |
| [Flutter 性能最佳实践](https://docs.flutter.dev/perf/best-practices) | 帧率、构建与内存优化 |

> 「Kotlin 与 Android 开发」的链接用于离线阅读后的延伸核对；App 不会自动联网。
