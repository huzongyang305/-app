## Kotlin 语法速查

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

## 协程速查

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

## Android 组件速查

| 组件 | 职责 | 注意 |
| --- | --- | --- |
| Activity | 承载界面 | 避免放业务逻辑 |
| Fragment | 可复用界面块 | 生命周期复杂，注意视图销毁 |
| ViewModel | 保存界面状态 | 不持有 View 引用 |
| Repository | 数据来源统一入口 | 负责缓存策略 |
| WorkManager | 可靠后台任务 | 适合可延迟任务 |
| Foreground Service | 前台服务 | 需通知与权限说明 |
| Room | 本地数据库 | 用 DAO 与 Flow 观察数据 |

## 常见错误对照表

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

## 自测清单

- [ ] 空安全用 `?.`、`?:` 处理，`!!` 只出现在确定非空处。
- [ ] 协程绑定合适作用域，禁止 `GlobalScope`。
- [ ] 状态用 `StateFlow` 暴露，UI 只读订阅。
- [ ] ViewModel 不持有 View 或 Activity 引用。
- [ ] 后台任务与权限按系统版本做兼容处理。
