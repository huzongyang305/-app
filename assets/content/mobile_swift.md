# Swift 与 iOS 开发

![Swift 与 iOS 开发的关键能力](images/diagram_mobile_swift.webp)

![Swift 与 iOS 开发](images/category_mobile_swift.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「Swift 与 iOS 开发」解决了什么问题，而不是只背术语。
- 能说清 「Swift」、「iOS」、「SwiftUI」、「ARC」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「移动开发」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：可选类型、值类型、ARC 与 SwiftUI 状态。

## 前置知识

- 先完成上一课《Kotlin 与 Android 开发》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：Swift、iOS、SwiftUI。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 语言特性速览

| 特性 | 说明 |
| --- | --- |
| 可选类型 | `String?` 表示可能为 nil，用 `if let`/`guard let` 解包 |
| 值类型优先 | struct 默认值语义，class 才引用语义；SwiftUI 中 struct 是主流 |
| 协议与扩展 | 协议定义契约，extension 提供默认实现，面向协议编程 |
| 闭包 | 尾随闭包语法简洁，注意用 `[weak self]` 避免循环引用 |
| 错误处理 | `throws` + `try/catch`，或用 Result 类型 |
| 并发 | `async/await` + `actor` 保证数据隔离 |

## iOS 应用结构

| 模式 | 说明 |
| --- | --- |
| MVC | 传统模式，容易把逻辑堆进 ViewController |
| MVVM | ViewModel 持有状态，SwiftUI 下最常用 |
| 单向数据流 | 状态集中管理，配合 @State/@Observable 驱动 UI |

SwiftUI 要点：视图是 struct（轻量重建）；`@State` 管局部状态、`@Binding` 传递、`@Observable` 管共享模型；用 `List`/`LazyVStack` 做长列表懒加载。

## 生命周期与内存管理

1. ARC 自动引用计数：强引用成环就泄漏，闭包捕获 self 时用 `[weak self]`。
2. App 生命周期从 App/Scene 委托演进到 SwiftUI 的 scenePhase。
3. 图片与大数据对象要及时释放，避免内存峰值被杀。
4. 后台任务受系统调度限制，用 BackgroundTasks 框架申请。

## 打包发布

用 Xcode Archive 产出 ipa；签名依赖证书与描述文件（开发/分发/企业三类）；TestFlight 做灰度与内测；App Store 审核要点包括隐私清单（Privacy Manifest）、权限用途说明与 ATT 跟踪授权。CI 上常用 fastlane 自动化构建与上传。

## 本课小结
iOS 开发的关键是**值类型 + 可选类型 + ARC 内存管理**：用 struct 与协议组织代码、用可选类型显式处理缺失、用 weak 打破循环引用。


## Swift 语法速查

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

## 内存管理速查

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

## 生命周期与线程速查

| 概念 | 说明 |
| --- | --- |
| `viewDidLoad` | 视图加载完成，做一次性配置 |
| `viewWillAppear` | 即将显示，刷新数据 |
| `deinit` | 释放资源，验证无循环引用 |
| MainActor | 主线程更新 UI |
| Task | 结构化并发任务 |
| async let | 并发启动多个异步调用 |
| actor | 保护可变状态的隔离单元 |

## 常见错误对照表

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

## 自测清单

- [ ] 优先使用 `let`、`struct` 与可选绑定。
- [ ] 闭包捕获遵循 `[weak self]`，核对无循环引用。
- [ ] UI 更新确保在主线程或标注 `@MainActor`。
- [ ] 异步任务有取消路径。
- [ ] 业务逻辑与视图分离，便于测试。


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

## 动手练习


> 本课练习重点：围绕「Swift、iOS、SwiftUI」完成复述、实验和交付，每个结果都要能被别人检查。

先做一个最小 Widget，再切换状态与约束，最后在窄屏和深色模式下验证布局。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Swift 与 iOS 开发」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「iOS」是什么关系？

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
- 至少覆盖「Swift」和「iOS」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 实践任务

本节围绕“Swift 与 iOS 开发”安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

合上教程，用 5 句话说明“Swift 与 iOS 开发”解决什么问题、输入是什么、输出是什么、失败时会怎样、与相邻概念的边界在哪里。画一张流程图或状态图，把每个节点标注成“输入 / 处理 / 输出 / 失败路径”之一。

**验收标准**：图里至少有 5 个节点和 1 条失败路径；每个节点都能在正文中找到依据。

### 任务 2：做一次对比实验

从正文里选两个差异最小的方案，列成 4 列表格：方案、前提、代价、适用边界。然后只改变一个条件（数据规模、并发度、精度或资源上限），记录结果变化。

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

把“Swift 与 iOS 开发”的核心方法用到你熟悉的一个真实场景，写出一份 300 字以内的实施记录：目标、步骤、验证方式、仍然不确定的问题。

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。


## 故障现场

这一节把“Swift 与 iOS 开发”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“Swift 与 iOS 开发”的 Swift 常规用例通过，但边界用例失败

**症状**：在“Swift 与 iOS 开发”的练习或生产场景里出现““Swift 与 iOS 开发”的 Swift 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““Swift 与 iOS 开发”的 Swift 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“Swift 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“Swift 与 iOS 开发”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““Swift 与 iOS 开发”的 Swift 常规用例通过，但边界用例失败”写成一条自动化用例，并在“Swift 与 iOS 开发”的验收清单里保留对应检查项。


### 现场 2：“Swift 与 iOS 开发”的 iOS 结果在两次运行之间不一致

**症状**：在“Swift 与 iOS 开发”的练习或生产场景里出现““Swift 与 iOS 开发”的 iOS 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““Swift 与 iOS 开发”的 iOS 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“iOS 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“Swift 与 iOS 开发”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““Swift 与 iOS 开发”的 iOS 结果在两次运行之间不一致”写成一条自动化用例，并在“Swift 与 iOS 开发”的验收清单里保留对应检查项。


### 现场 3：“Swift 与 iOS 开发”的验证只在开发机通过

**症状**：在“Swift 与 iOS 开发”的练习或生产场景里出现““Swift 与 iOS 开发”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““Swift 与 iOS 开发”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，Swift 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“Swift 与 iOS 开发”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““Swift 与 iOS 开发”的验证只在开发机通过”写成一条自动化用例，并在“Swift 与 iOS 开发”的验收清单里保留对应检查项。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Swift 中解包可选类型的安全写法是？

- **正确判断**：if let 或 guard let
- **判断依据**：正确答案是「if let 或 guard let」，本课在「本课小结」中说明：iOS 开发的关键是值类型 + 可选类型 + ARC 内存管理：用 struct 与协议组织代码、用可选类型显式处理缺失、用 weak 打破循环引用。强制解包遇到 nil 会崩溃，应使用可选绑定。本课还在「零基础详解：Swift 与 iOS 开发」中说明：Swift 的核心特性是可选类型、值语义、协议。本课还在「零基础详解：Swift 与 iOS 开发」中说明：避免 ! 强制解包：nickname! 在 nil 时会直接崩溃。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：闭包捕获 self 时为避免循环引用应使用？

- **正确判断**：[weak self]
- **判断依据**：正确答案是「[weak self]」，本课在「生命周期与内存管理」中说明：ARC 自动引用计数：强引用成环就泄漏，闭包捕获 self 时用 [weak self]。ARC 下强引用成环会内存泄漏，用 weak 打破环。本课还在「零基础详解：Swift 与 iOS 开发」中说明：规则：闭包被 self 持有，且闭包又捕获 self 时，必须用 [weak self] 或 [unowned self]。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：SwiftUI 中管理共享模型状态的常用方式是？

- **正确判断**：@Observable 等状态包装器
- **判断依据**：正确答案是「@Observable 等状态包装器」，本课在「iOS 应用结构」中说明：@State 管局部状态、@Binding 传递、@Observable 管共享模型。用状态包装器驱动视图重建，配合单向数据流。本课还在「打包发布」中说明：签名依赖证书与描述文件（开发/分发/企业三类）。本课还在「打包发布」中说明：CI 上常用 fastlane 自动化构建与上传。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：Swift 中 struct 与 class 的关键区别是？

- **正确判断**：struct 是值类型（复制语义）
- **判断依据**：正确答案是「struct 是值类型（复制语义）」，本课在「本课小结」中说明：iOS 开发的关键是值类型 + 可选类型 + ARC 内存管理：用 struct 与协议组织代码、用可选类型显式处理缺失、用 weak 打破循环引用。赋值或传参时 struct 会复制，class 传递的是同一个对象引用。本课还在「零基础详解：Swift 与 iOS 开发」中说明：知道 struct 与 class 在赋值时的不同。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：guard let 与 if let 相比，最明显的特点是？

- **正确判断**：guard 的条件不满足时必须在当前作用域退出（return/throw 等）
- **判断依据**：正确答案是「guard 的条件不满足时必须在当前作用域退出（return/throw 等）」，本课在「零基础详解：Swift 与 iOS 开发」中说明：能说出 if let 与 guard let 的差别。guard 用于「提前返回」，解包后的变量在后续作用域继续可用，能减少嵌套层级。本课还在「iOS 应用结构」中说明：SwiftUI 要点：视图是 struct（轻量重建）。本课还在「生命周期与内存管理」中说明：App 生命周期从 App/Scene 委托演进到 SwiftUI 的 scenePhase。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 6：补全代码：「Swift 与 iOS 开发」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `print("昵称长度 \(____.count)")`

- **正确判断**：nickname
- **判断依据**：正确答案是「nickname」，本课在「零基础详解：Swift 与 iOS 开发」中说明：避免 ! 强制解包：nickname! 在 nil 时会直接崩溃。本课示例中还能看到 `if let nickname {` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

### 补充考点 1：阅读「Swift 与 iOS 开发」的代码片段，下面哪项判断是正确的？

- **正确判断**：if let 或 guard let
- **判断依据**：正确答案是「if let 或 guard let」。这段代码来自「Swift 与 iOS 开发」的示例，判断时先看输入与输出，再检查条件、循环和边界。正确答案是「if let 或 guard let」，本课在「本课小结」中说明：iOS 开发的关键是值类型 + 可选类型 + ARC 内存管理：用 struct 与协议组织代码、用可选类型显式处理缺失、…在「Swift 与 iOS 开发」中，如果只改一个条件，输出通常会随之改变，因此不能脱离代码前提作答。

### 补充自测（2 题）

1. 围绕“Swift 与 iOS 开发”中的 Swift、iOS、SwiftUI，下列哪两项是本课强调的实践判断？
2. 按“Swift 与 iOS 开发”中 Swift、iOS、SwiftUI 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Swift 中解包可选类型的安全写法是？」的判断依据。
- [ ] 不看解析，能说出「闭包捕获 self 时为避免循环引用应使用？」的判断依据。
- [ ] 不看解析，能说出「SwiftUI 中管理共享模型状态的常用方式是？」的判断依据。
- [ ] 不看解析，能说出「Swift 中 struct 与 class 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「guard let 与 if let 相比，最明显的特点是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「Swift 与 iOS 开发」示例中，下面这行代码缺少哪个关键字或函…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `String?` | \| 可选类型 \| `String?` 表示可能为 nil，用 `if let`/`guard let` 解包 \| |
| `if let` | \| 可选类型 \| `String?` 表示可能为 nil，用 `if let`/`guard let` 解包 \| |
| `guard let` | \| 可选类型 \| `String?` 表示可能为 nil，用 `if let`/`guard let` 解包 \| |
| `[weak self]` | \| 闭包 \| 尾随闭包语法简洁，注意用 `[weak self]` 避免循环引用 \| |
| `throws` | \| 错误处理 \| `throws` + `try/catch`，或用 Result 类型 \| |
| `try/catch` | \| 错误处理 \| `throws` + `try/catch`，或用 Result 类型 \| |
| `async/await` | \| 并发 \| `async/await` + `actor` 保证数据隔离 \| |
| `actor` | \| 并发 \| `async/await` + `actor` 保证数据隔离 \| |
| `@State` | SwiftUI 要点：视图是 struct（轻量重建）；`@State` 管局部状态、`@Binding` 传递、`@Observable` 管共享模型；用 `List`/`LazyVStack` 做长列表懒加载。 |
| `@Binding` | SwiftUI 要点：视图是 struct（轻量重建）；`@State` 管局部状态、`@Binding` 传递、`@Observable` 管共享模型；用 `List`/`LazyVStack` 做长列表懒加载。 |
| `@Observable` | SwiftUI 要点：视图是 struct（轻量重建）；`@State` 管局部状态、`@Binding` 传递、`@Observable` 管共享模型；用 `List`/`LazyVStack` 做长列表懒加载。 |
| `List` | SwiftUI 要点：视图是 struct（轻量重建）；`@State` 管局部状态、`@Binding` 传递、`@Observable` 管共享模型；用 `List`/`LazyVStack` 做长列表懒加载。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：Swift 中解包可选类型的安全写法是？

**参考回答**：正确答案是「if let 或 guard let」，本课在「本课小结」中说明：iOS 开发的关键是值类型 + 可选类型 + ARC 内存管理：用 struct 与协议组织代码、用可选类型显式处理缺失、用 weak 打破循环引用。强制解包遇到 nil 会崩溃，应使用可选绑定。本课还在「零基础详解·Swift 与 iOS 开发」中说明：Swift 的核心特性是可选类型、值语义、协议。本课还在「零基础详解·Swift 与 iOS 开发」中说明：避免 ! 强制解包：nickname! 在 nil 时会直接崩溃。

### 追问 2：闭包捕获 self 时为避免循环引用应使用？

**参考回答**：正确答案是「[weak self]」，本课在「生命周期与内存管理」中说明：ARC 自动引用计数：强引用成环就泄漏，闭包捕获 self 时用 [weak self]。ARC 下强引用成环会内存泄漏，用 weak 打破环。本课还在「零基础详解·Swift 与 iOS 开发」中说明：规则：闭包被 self 持有，且闭包又捕获 self 时，必须用 [weak self] 或 [unowned self]。

### 追问 3：SwiftUI 中管理共享模型状态的常用方式是？

**参考回答**：正确答案是「@Observable 等状态包装器」，本课在「iOS 应用结构」中说明：@State 管局部状态、@Binding 传递、@Observable 管共享模型。用状态包装器驱动视图重建，配合单向数据流。本课还在「打包发布」中说明：签名依赖证书与描述文件（开发/分发/企业三类）。本课还在「打包发布」中说明：CI 上常用 fastlane 自动化构建与上传。

### 追问 4：Swift 中 struct 与 class 的关键区别是？

**参考回答**：正确答案是「struct 是值类型（复制语义）」，本课在「本课小结」中说明：iOS 开发的关键是值类型 + 可选类型 + ARC 内存管理：用 struct 与协议组织代码、用可选类型显式处理缺失、用 weak 打破循环引用。赋值或传参时 struct 会复制，class 传递的是同一个对象引用。本课还在「零基础详解·Swift 与 iOS 开发」中说明：知道 struct 与 class 在赋值时的不同。

### 追问 5：guard let 与 if let 相比，最明显的特点是？

**参考回答**：正确答案是「guard 的条件不满足时必须在当前作用域退出（return/throw 等）」，本课在「零基础详解·Swift 与 iOS 开发」中说明：能说出 if let 与 guard let 的差别。guard 用于「提前返回」，解包后的变量在后续作用域继续可用，能减少嵌套层级。本课还在「iOS 应用结构」中说明：SwiftUI 要点：视图是 struct（轻量重建）。本课还在「生命周期与内存管理」中说明：App 生命周期从 App/Scene 委托演进到 SwiftUI 的 scenePhase。

## English Overview

**Title:** Swift & iOS

**Summary:** Optionals, value types, ARC and SwiftUI state.

**Category:** Mobile Development  
**Level:** 基础  
**Key terms:** Swift, iOS, SwiftUI, ARC, TestFlight

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Flutter 3.x / Dart 3.x
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Swift、iOS、SwiftUI、ARC、TestFlight
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter 官方文档](https://docs.flutter.dev/) | 框架、组件与发布流程 |
| [Dart 官方文档](https://dart.dev/guides) | 语言、异步与工具链 |

> 本课主题：可选类型、值类型、ARC 与 SwiftUI 状态。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
