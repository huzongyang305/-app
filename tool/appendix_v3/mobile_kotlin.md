## 零基础详解：Kotlin 与 Android 开发

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
