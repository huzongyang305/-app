# Swift 与 iOS 开发

![Swift 与 iOS 开发的关键能力](images/diagram_mobile_swift.webp)

![Swift 与 iOS 开发](images/category_mobile_swift.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「移动开发」，课程主题为「Swift 与 iOS 开发」，学习阶段为「基础」，建议用时 50 分钟。

**本课要解决的主问题**：可选类型、值类型、ARC 与 SwiftUI 状态。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Swift 与 iOS 开发」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Swift 与 iOS 开发」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Swift」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Kotlin 与 Android 开发》

**学习位置**：本课位于《Kotlin 与 Android 开发》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《小程序开发要点》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Swift 与 iOS 开发解决了什么问题，而不是只背术语。
- 能说清 「Swift」、「iOS」、「SwiftUI」、「ARC」 之间的关系，并分别举出一个例子。
- 能把 Swift 放回「Swift 与 iOS 开发」的知识体系，说明它和 iOS 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：可选类型、值类型、ARC 与 SwiftUI 状态。

**教材衔接：前置知识**

- 先完成上一课《Kotlin 与 Android 开发》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议先完成「Kotlin 与 Android 开发」，或确认自己能独立跑通正文里的 LessonViewModel 示例。
- 开始前先复习：Swift、iOS、SwiftUI。
- 看不懂就直接缩小例子：只保留 Swift 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

iOS 开发的关键是**值类型 + 可选类型 + ARC 内存管理**：用 struct 与协议组织代码、用可选类型显式处理缺失、用 weak 打破循环引用。

## 核心概念定义

> 阅读约定：本课先给「Swift 与 iOS 开发」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Swift | Apple 推出的静态类型编程语言，用于 iOS、macOS 等平台开发。 | 仅在「Swift 与 iOS 开发」明确给出的输入、版本与资源条件下成立。 |
| SwiftUI | Apple 的声明式 UI 框架，用状态驱动视图并跨 Apple 平台复用。 | 仅在「Swift 与 iOS 开发」明确给出的输入、版本与资源条件下成立。 |
| 可选类型 | Optional 表示值可能为 nil，必须显式解包（if let、guard let）才能使用，从类型层面消除空指针。 | 仅在「Swift 与 iOS 开发」明确给出的输入、版本与资源条件下成立。 |
| ARC | Swift 的自动引用计数，在编译期插入引用计数的增减，循环引用要用 weak 或 unowned 打破。 | 仅在「Swift 与 iOS 开发」明确给出的输入、版本与资源条件下成立。 |
| Task | Swift 并发中的异步任务单元，可等待结果、取消或组合并发工作 | 仅在「Swift 与 iOS 开发」明确给出的输入、版本与资源条件下成立。 |
| async | 标记异步函数或异步块，使内部可以使用 await 而不阻塞调用线程 | 仅在「Swift 与 iOS 开发」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Swift 与 iOS 开发」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Swift」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「SwiftUI」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「可选类型」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Swift 与 iOS 开发」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Swift | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | SwiftUI | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 可选类型 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Swift 与 iOS 开发」自己的示例验证。「Swift 与 iOS 开发」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：语言特性速览**

| 特性 | 说明 |
| --- | --- |
| 可选类型 | `String?` 表示可能为 nil，用 `if let`/`guard let` 解包 |
| 值类型优先 | struct 默认值语义，class 才引用语义；SwiftUI 中 struct 是主流 |
| 协议与扩展 | 协议定义契约，extension 提供默认实现，面向协议编程 |
| 闭包 | 尾随闭包语法简洁，注意用 `[weak self]` 避免循环引用 |
| 错误处理 | `throws` + `try/catch`，或用 Result 类型 |
| 并发 | `async/await` + `actor` 保证数据隔离 |

**教材衔接：打包发布**

用 Xcode Archive 产出 ipa；签名依赖证书与描述文件（开发/分发/企业三类）；TestFlight 做灰度与内测；App Store 审核要点包括隐私清单（Privacy Manifest）、权限用途说明与 ATT 跟踪授权。CI 上常用 fastlane 自动化构建与上传。

**教材衔接：生命周期与线程速查**

| 概念 | 说明 |
| --- | --- |
| `viewDidLoad` | 视图加载完成，做一次性配置 |
| `viewWillAppear` | 即将显示，刷新数据 |
| `deinit` | 释放资源，验证无循环引用 |
| MainActor | 主线程更新 UI |
| Task | 结构化并发任务 |
| async let | 并发启动多个异步调用 |
| actor | 保护可变状态的隔离单元 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Swift、iOS | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Swift 与 iOS 开发」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Swift 与 iOS 开发」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**教材衔接：iOS 应用结构**

| 模式 | 说明 |
| --- | --- |
| MVC | 传统模式，容易把逻辑堆进 ViewController |
| MVVM | ViewModel 持有状态，SwiftUI 下最常用 |
| 单向数据流 | 状态集中管理，配合 @State/@Observable 驱动 UI |

SwiftUI 要点：视图是 struct（轻量重建）；`@State` 管局部状态、`@Binding` 传递、`@Observable` 管共享模型；用 `List`/`LazyVStack` 做长列表懒加载。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Swift 与 iOS 开发》原文中的最小示例。先预测《Swift 与 iOS 开发》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```swift
// 值类型 + 不可变：默认优先的选择
struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    var completed: Bool = false
}

// 异步加载：用弱引用避免闭包持有视图控制器
final class LessonViewModel {
    private(set) var lessons: [Lesson] = []
    var onChange: (() -> Void)?

    func load(completion: @escaping () -> Void) {
        Task { [weak self] in
            guard let self else { return }
            let fetched = await Self.fetch()
            self.lessons = fetched
            self.onChange?()
            completion()
        }
    }

    private static func fetch() async -> [Lesson] {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return [Lesson(id: "1", title: "Swift 基础")]
    }
}

// SwiftUI 状态：@State 管局部，@Observable 管共享
import SwiftUI

@Observable
final class LessonStore {
    var lessons: [Lesson] = []
    var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        lessons = await LessonViewModel.fetch()
    }
}

struct LessonListView: View {
    @State private var store = LessonStore()

    var body: some View {
        List(store.lessons) { lesson in
            Text(lesson.title)
        }
        .task { await store.load() }
        .overlay { if store.isLoading { ProgressView() } }
    }
}
```

**教材衔接：Swift 语法速查**

| 特性 | 写法 | 说明 |
| --- | --- | --- |
| 常量与变量 | `let` / `var` | 优先用 `let` |
| 可选类型 | `String?` | 必须解包后才能使用 |
| 可选绑定 | `if let name = user.name { }` | 安全解包 |
| 提前返回 | `guard let name else { return }` | 解包失败即退出 |
| 空值兜底 | `user.name ?? "匿名"` | 提供默认值 |
| 强制解包 | `user.name!` | 为空即崩溃，避免使用 |
| 值类型 | `struct` | 复制语义，优先使用 |
| 引用类型 | `class` | 需要共享身份时才用 |
| 枚举关联值 | `enum Result { case ok(String) }` | 表达状态与数据 |
| 协议扩展 | `extension` | 提供默认实现 |

**教材衔接：零基础详解：Swift 与 iOS 开发**

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

## 时间/空间复杂度或性能分析

**复杂度证据**：「Swift 与 iOS 开发」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Swift 与 iOS 开发」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Swift 与 iOS 开发」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：生命周期与内存管理**

1. ARC 自动引用计数：强引用成环就泄漏，闭包捕获 self 时用 `[weak self]`。
2. App 生命周期从 App/Scene 委托演进到 SwiftUI 的 scenePhase。
3. 图片与大数据对象要及时释放，避免内存峰值被杀。
4. 后台任务受系统调度限制，用 BackgroundTasks 框架申请。

**教材衔接：内存管理速查**

| 概念 | 说明 |
| --- | --- |
| ARC | 编译期插入引用计数管理 |
| 强引用 | 默认，持有对象 |
| weak | 不增加计数、自动置 nil，用于避免循环引用 |
| unowned | 假定对象一直存在，用错会崩溃 |
| 循环引用 | 闭包捕获 self 或两个对象互相强引用 |
| 捕获列表 | `[weak self]` 打破闭包循环引用 |

```swift
// 值类型 + 不可变：默认优先的选择
struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    var completed: Bool = false
}

// 异步加载：用弱引用避免闭包持有视图控制器
final class LessonViewModel {
    private(set) var lessons: [Lesson] = []
    var onChange: (() -> Void)?

    func load(completion: @escaping () -> Void) {
        Task { [weak self] in
            guard let self else { return }
            let fetched = await Self.fetch()
            self.lessons = fetched
            self.onChange?()
            completion()
        }
    }

    private static func fetch() async -> [Lesson] {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return [Lesson(id: "1", title: "Swift 基础")]
    }
}

// SwiftUI 状态：@State 管局部，@Observable 管共享
import SwiftUI

@Observable
final class LessonStore {
    var lessons: [Lesson] = []
    var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        lessons = await LessonViewModel.fetch()
    }
}

struct LessonListView: View {
    @State private var store = LessonStore()

    var body: some View {
        List(store.lessons) { lesson in
            Text(lesson.title)
        }
        .task { await store.load() }
        .overlay { if store.isLoading { ProgressView() } }
    }
}
```

## 常见误区与易错点

> 复核《Swift 与 iOS 开发》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Swift 与 iOS 开发」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 滥用 `!` 强制解包 | 偶发崩溃 | 用 `guard let` 或 `??` |
| 闭包里强引用 self | 内存泄漏 | 用 `[weak self]` |
| 用 class 表达纯数据 | 意外共享与修改 | 优先 `struct` |
| 在后台线程更新 UI | 崩溃或异常 | 用 `@MainActor` 或切回主线程 |
| 忘记取消 Task | 页面销毁后仍在请求 | 用 `.task` 或在 `deinit` 取消 |
| 用 unowned 却可能为 nil | 崩溃 | 不确定时用 weak |
| 过度使用单例 | 难测试、状态共享 | 依赖注入替代 |
| 忽略 `Sendable` 约束 | 并发警告与隐患 | 明确类型跨线程安全性 |
| 视图里堆业务逻辑 | 难测试 | 抽到 ViewModel 或 Store |
| 不处理错误分支 | 静默失败 | 用 `Result` 或抛出并显式处理 |

**教材衔接：故障现场**

### 现场 1：用 class 表达纯数据

**症状**：在《Swift 与 iOS 开发》的复现场景中，意外共享与修改。

**根因**：“意外共享与修改”只是表层结果。向上追溯会落到“用 class 表达纯数据”这一步，因为它省略了《Swift 与 iOS 开发》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Swift 与 iOS 开发》的问题，优先 struct。

**验证**：在《Swift 与 iOS 开发》中按“优先 struct”调整后，从“用 class 表达纯数据”的触发条件重放同一条路径，确认“意外共享与修改”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：忘记取消 Task

**症状**：在《Swift 与 iOS 开发》的复现场景中，页面销毁后仍在请求。

**根因**：当出现“忘记取消 Task”时，执行路径已经绕过了《Swift 与 iOS 开发》的关键约束，最终以“页面销毁后仍在请求”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Swift 与 iOS 开发》的问题，用 .task 或在 deinit 取消。

**验证**：在《Swift 与 iOS 开发》中按“用 .task 或在 deinit 取消”调整后，从“忘记取消 Task”的触发条件重放同一条路径，确认“页面销毁后仍在请求”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：过度使用单例

**症状**：在《Swift 与 iOS 开发》的复现场景中，难测试、状态共享。

**根因**：当出现“过度使用单例”时，执行路径已经绕过了《Swift 与 iOS 开发》的关键约束，最终以“难测试、状态共享”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Swift 与 iOS 开发》的问题，依赖注入替代。

**验证**：先在《Swift 与 iOS 开发》中记录“过度使用单例”留下的失败证据，再执行“依赖注入替代”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Kotlin 与 Android 开发》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《React Native 跨平台开发》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Kotlin 与 Android 开发》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《小程序开发要点》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Swift 与 iOS 开发」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Swift 与 iOS 开发》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“Swift 与 iOS 开发”中的 Swift、iOS、SwiftUI，下列哪两项是本课强调的实践判断？

A. 学习 Swift 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 Swift 的常规示例通过，就可以跳过边界与异常路径
C. 验证 iOS 时要固定版本并覆盖边界输入，结论才可复现
D. 把 iOS 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 Swift 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 iOS 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把Swift 与 iOS 开发拆成概念、示例与故障现场三部分，因此判断 Swift 时必须同时交代输入、输出和失败路径，这使“学习 Swift 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Swift 与 iOS 开发里，判断 iOS 时要固定版本与边界输入，所以“验证 iOS 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

按“Swift 与 iOS 开发”中 Swift、iOS、SwiftUI 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。

A. 固定版本与证据，把“Swift 与 iOS 开发”的结论写成可复现记录
B. 先明确 Swift 的输入、输出与约束
C. 写出最小示例并核对 iOS 的基线结果
D. 只改一个变量，记录边界与失败路径的变化

**参考答案**：先明确 Swift 的输入、输出与约束 → 写出最小示例并核对 iOS 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把“Swift 与 iOS 开发”的结论写成可复现记录

**解析**：题干的正确项是固定版本与证据，把“Swift 与 iOS 开发”的结论写成可复现记录。在「Swift 与 iOS 开发」里，在本课的练习里，顺序应当是：先明确 Swift 的输入、输出与约束 → 写出最小示例并核对 iOS 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 Swift 的输入、输出和约束放在最前面，在Swift 与 iOS 开发里避免概念没对齐就开始调参。第二步用 iOS 建立可核对的基线，在Swift 与 iOS 开发里第三步才允许改变一个变量并观察失败路径。

### 自测 3

SwiftUI 中管理共享模型状态的常用方式是？

A. @Observable 等状态包装器
B. 把模型存进 UserDefaults
C. 单例
D. 全局变量

**参考答案**：@Observable 等状态包装器

**解析**：在「Swift 与 iOS 开发」里，@Observable 等状态包装器。用状态包装器驱动视图重建，配合单向数据流。“SwiftUI”与「Swift 与 iOS 开发」的术语表相呼应，只有符合Swift、iOS、SwiftUI约束的“@Observable 等状态包装器”才是正文支持的结论。

**教材衔接：复习与自测**

- [ ] 优先使用 `let`、`struct` 与可选绑定。
- [ ] 闭包捕获遵循 `[weak self]`，核对无循环引用。
- [ ] UI 更新确保在主线程或标注 `@MainActor`。
- [ ] 异步任务有取消路径。
- [ ] 业务逻辑与视图分离，便于测试。

**教材衔接：动手练习**

> 本课练习重点：围绕「Swift、iOS、SwiftUI」完成复述、实验和交付，每个结果都要能被别人检查。

先做 Swift 的最小 Widget，再切换状态，最后在窄屏与深色模式下验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Swift 与 iOS 开发解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「iOS」是什么关系？

验收标准：回答里必须出现 Swift，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先原样跑通正文里的 `LessonViewModel`，再只改Swift相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：交付一个小结果（30 分钟）

用最小 Widget 验证 iOS 在空数据与超长文本下的表现。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Swift」和「iOS」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Swift 与 iOS 开发安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Swift 与 iOS 开发」的结构，画完再对照骨架：

- 主干：语言特性速览 → iOS 应用结构 → 生命周期与内存管理 → 打包发布
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Swift与iOS的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案至少在一个输入上给出不同结果；把差异归因到Swift，而不是笼统地写「性能更好」。

### 任务 3：迁移到自己的场景

**验收标准**：换一个人按你的记录重跑 LessonViewModel，能得到相同输出；得不到就补写缺失的前提。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Swift 中解包可选类型的安全写法是？」的判断依据。
- [ ] 不看解析，能说出「闭包捕获 self 时为避免循环引用应使用？」的判断依据。
- [ ] 不看解析，能说出「SwiftUI 中管理共享模型状态的常用方式是？」的判断依据。
- [ ] 不看解析，能说出「Swift 中 struct 与 class 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「guard let 与 if let 相比，最明显的特点是？」的判断依据。
- [ ] 用 Swift 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
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
| `Swift` | Apple 推出的静态类型编程语言，用于 iOS、macOS 等平台开发。 |
| `SwiftUI` | Apple 的声明式 UI 框架，用状态驱动视图并跨 Apple 平台复用。 |
| `可选类型` | Optional 表示值可能为 nil，必须显式解包（if let、guard let）才能使用，从类型层面消除空指针。 |
| `ARC` | Swift 的自动引用计数，在编译期插入引用计数的增减，循环引用要用 weak 或 unowned 打破。 |
| `Task` | Swift 并发中的异步任务单元，可等待结果、取消或组合并发工作 |
| `async` | 标记异步函数或异步块，使内部可以使用 await 而不阻塞调用线程 |

## 考点精讲

### 考点 1：多选辨析·Swift

- **题目**：围绕“Swift 与 iOS 开发”中的 Swift、iOS、SwiftUI，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Swift 与 iOS 开发拆成概念、示例与故障现场三部分，因此判断 Swift 时必须同时交代输入、输出和失败路径，这使“学习 Swift 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Swift 与 iOS 开发里，判断 iOS 时要固定版本与边界输入，所以“验证 iOS 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：顺序排列·Swift

- **题目**：按“Swift 与 iOS 开发”中 Swift、iOS、SwiftUI 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **判断依据**：题干的正确项是固定版本与证据，把“Swift 与 iOS 开发”的结论写成可复现记录。在「Swift 与 iOS 开发」里，在本课的练习里，顺序应当是：先明确 Swift 的输入、输出与约束 → 写出最小示例并核对 iOS 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 Swift 的输入、输出和约束放在最前面，在Swift 与 iOS 开发里避免概念没对齐就开始调参。第二步用 iOS 建立可核对的基线，在Swift 与 iOS 开发里第三步才允许改变一个变量并观察失败路径。

### 考点 3：概念判断·Swift

- **题目**：SwiftUI 中管理共享模型状态的常用方式是？
- **判断依据**：在「Swift 与 iOS 开发」里，@Observable 等状态包装器。用状态包装器驱动视图重建，配合单向数据流。“SwiftUI”与「Swift 与 iOS 开发」的术语表相呼应，只有符合Swift、iOS、SwiftUI约束的“@Observable 等状态包装器”才是正文支持的结论。

### 考点 4：概念判断·Swift

- **题目**：Swift 中 struct 与 class 的关键区别是？
- **判断依据**：在「Swift 与 iOS 开发」里，结论应落在「struct 是值类型（复制语义）」。赋值或传参时 struct 会复制，class 传递的是同一个对象引用。在「Swift 与 iOS 开发」里，这道题要求区分概念与边界，「struct 是值类型（复制语义）」只有在题干给出的前提下才成立，而「struct 不能有方法」、「class 不能实现协议」缺少同一组条件。

### 考点 5：概念判断·Swift

- **题目**：guard let 与 if let 相比，最明显的特点是？
- **判断依据**：在「Swift 与 iOS 开发」里，guard 的条件不满足时必须在当前作用域退出（return/throw 等）。guard 用于「提前返回」，解包后的变量在后续作用域继续可用，能减少嵌套层级。回到「Swift 与 iOS 开发」的正文示例，用“guard let 与 if let”走一遍Swift、iOS、SwiftUI的完整流程，能复现的结论才可以保留。

### 考点 6：排错·Swift

- **题目**：阅读「Swift 与 iOS 开发」的代码片段，下面哪项判断是正确的？
- **判断依据**：在「Swift 与 iOS 开发」里，if let 或 guard let。转换（仅部分场景成立）」、「强制解包。回到「Swift 与 iOS 开发」的正文示例，用“阅读Swift 与 iOS 开发的代”走一遍Swift、iOS、SwiftUI的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Swift & iOS

**Summary:** Optionals, value types, ARC and SwiftUI state.

**Category:** Mobile Development
**Level:** 基础
**Key terms:** Swift, iOS, SwiftUI, ARC, TestFlight

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Flutter 3.x / Dart 3.x
；本课聚焦 Swift。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Swift、iOS、SwiftUI、ARC、TestFlight
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Dart 语言文档](https://dart.dev/language) | 语言语法、类型与空安全 |
| [Flutter 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | 状态分层与重建范围 |
| [Flutter 性能最佳实践](https://docs.flutter.dev/perf/best-practices) | 帧率、构建与内存优化 |

> 「Swift 与 iOS 开发」的链接用于离线阅读后的延伸核对；App 不会自动联网。
