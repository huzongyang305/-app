## 零基础详解：Swift 与 iOS 开发

### 一句话说清它是什么

Swift 的核心特性是**可选类型、值语义、协议**；iOS 侧的工程要点是
**状态驱动界面、异步用 async/await、闭包注意循环引用**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 可选类型 `?` | 可能是空盒子 | 用前必须打开检查 |
| `let` / `var` | 只读 / 可改 | 默认用 `let` |
| struct | 复印件 | 赋值即复制 |
| class | 共享原件 | 赋值是同一实例 |
| 协议 | 岗位要求 | 谁实现谁上岗 |
| 闭包 | 带走的行李 | 捕获外部变量，可能成环 |

### 可选类型：Swift 最核心的安全设计

```swift
var nickname: String? = nil

// 方式一：if let（作用域内使用）
if let nickname {
    print("昵称长度 \(nickname.count)")
}

// 方式二：guard let（提前返回，后续一直可用）
func greet(_ nickname: String?) -> String {
    guard let nickname, !nickname.isEmpty else {
        return "你好，朋友"
    }
    return "你好，\(nickname)"
}

// 方式三：空合并与可选链
let shown = nickname ?? "未填写"
let count = nickname?.count ?? 0
```

**避免 `!` 强制解包**：`nickname!` 在 nil 时会直接崩溃。

### 值类型与引用类型

```swift
struct Point { var x: Int; var y: Int }
class Counter { var value = 0 }

var p1 = Point(x: 1, y: 1)
var p2 = p1
p2.x = 99
print(p1.x)        // 1，结构体是复制语义

let c1 = Counter()
let c2 = c1
c2.value = 5
print(c1.value)    // 5，类共享同一实例
```

| 类型 | 语义 | 适用 |
| --- | --- | --- |
| `struct` | 值类型 | 数据模型、状态、UI 状态 |
| `class` | 引用类型 | 需要共享与身份、继承 |
| `enum` | 值类型 | 有限状态（配合关联值更强） |

**SwiftUI 推荐用 struct 与 enum 表达状态**，配合不可变更新更安全。

### 闭包与循环引用

```swift
final class Loader {
    var onFinish: (() -> Void)?
    private var cache: [String] = []

    func load() {
        // [weak self] 打破强引用环
        fetch { [weak self] result in
            guard let self else { return }
            self.cache.append(result)
            self.onFinish?()
        }
    }
}
```

**规则**：闭包被 self 持有，且闭包又捕获 self 时，必须用 `[weak self]` 或 `[unowned self]`。

### async/await 与并发

```swift
struct UserService {
    func fetchUser(id: Int) async throws -> User {
        let (data, response) = try await URLSession.shared.data(
            from: URL(string: "https://example.com/users/\(id)")!
        )
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badStatus
        }
        return try JSONDecoder().decode(User.self, from: data)
    }
}

// 并发拉取多个任务
async let a = service.fetchUser(id: 1)
async let b = service.fetchUser(id: 2)
let users = try await [a, b]

// 结构化并发 + 限制并发数
try await withThrowingTaskGroup(of: User.self) { group in
    for id in ids { group.addTask { try await service.fetchUser(id: id) } }
    for try await user in group { print(user.name) }
}
```

### SwiftUI 的状态包装器

| 包装器 | 用途 |
| --- | --- |
| `@State` | 视图内部的简单状态 |
| `@Binding` | 把状态传给子视图修改 |
| `@Observable` | 可观察模型（推荐） |
| `@Environment` | 从环境读取共享值 |

```swift
@Observable
final class CartModel {
    private(set) var items: [Item] = []
    var total: Decimal { items.reduce(0) { $0 + $1.price } }

    func add(_ item: Item) { items.append(item) }
}

struct CartView: View {
    @State private var model = CartModel()

    var body: some View {
        List(model.items) { item in
            Text(item.name)
        }
        .safeAreaInset(edge: .bottom) {
            Text("合计 \(model.total, format: .currency(code: "CNY"))")
        }
    }
}
```

**要点**：`@Observable` 会自动追踪被读取的属性，只有用到它的视图才重建。

### iOS 分层

```text
App/
  Features/        按功能划分的界面与 ViewModel
  Domain/          模型、协议、用例
  Data/            网络、数据库、第三方 SDK 实现
  Resources/       资源与本地化
```

**原则**：界面依赖协议而不是具体实现，方便替换与测试。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `!` 强制解包 | 线上崩溃 | 用 `if let` 或 `guard let` |
| 闭包捕获 self 成环 | 内存泄漏 | `[weak self]` |
| 在后台线程更新 UI | 界面异常或崩溃 | 回到 `@MainActor` |
| 用 class 表达简单状态 | 状态共享混乱 | 用 struct 与 enum |
| 忘记 `@MainActor` | 编译器警告、偶发崩溃 | 标注在需要主线程的类型上 |
| 网络请求没有超时 | 一直转圈 | 设置 `timeoutInterval` |
| 强制 try | 崩溃 | `do/catch` 或向上 `throws` |
| 把大对象放进 `@State` | 频繁复制影响性能 | 用引用类型或拆分视图 |

### 手把手练习：带四态的列表视图

```swift
enum LoadState<T> {
    case loading
    case empty
    case loaded(T)
    case failed(String)
}

@MainActor
@Observable
final class ItemListModel {
    private(set) var state: LoadState<[Item]> = .loading
    private let service: ItemService

    init(service: ItemService) { self.service = service }

    func load() async {
        state = .loading
        do {
            let items = try await service.fetchAll()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .failed("加载失败，请稍后重试")
        }
    }
}

struct ItemListView: View {
    @State private var model: ItemListModel

    init(service: ItemService) {
        _model = State(initialValue: ItemListModel(service: service))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading: ProgressView()
            case .empty: Text("暂无数据")
            case .failed(let message): Text(message)
            case .loaded(let items): List(items) { Text($0.name) }
            }
        }
        .task { await model.load() }
    }
}
```

### 学完自测

- [ ] 能说出 `if let` 与 `guard let` 的差别。
- [ ] 知道 struct 与 class 在赋值时的不同。
- [ ] 能说出闭包什么时候需要 `[weak self]`。
- [ ] 知道为什么 UI 更新要在 `@MainActor`。
- [ ] 能说出四种界面状态该怎么表达。
