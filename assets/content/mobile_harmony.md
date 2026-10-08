# 鸿蒙 ArkTS 应用开发

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：45 分钟

![鸿蒙 ArkTS 与 Stage 模型](images/diagram_mobile_harmony.webp)

![鸿蒙 ArkTS 应用开发](images/category_mobile_harmony.webp)

## 本节知识框架

**课程定位**：所属分类为「移动开发」，课程主题为「鸿蒙 ArkTS 应用开发」，学习阶段为「进阶」，建议用时 45 分钟。

**本课要解决的主问题**：ArkTS 语言约束、ArkUI 声明式写法与 Stage 模型。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「鸿蒙 ArkTS 应用开发」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「鸿蒙 ArkTS 应用开发」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「鸿蒙」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Jetpack Compose 声明式 UI》

**学习位置**：本课位于《Jetpack Compose 声明式 UI》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《移动端性能优化实战》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释鸿蒙 ArkTS 应用开发解决了什么问题，而不是只背术语。
- 能说清 「鸿蒙」、「HarmonyOS」、「ArkTS」、「ArkUI」 之间的关系，并分别举出一个例子。
- 能把 鸿蒙 放回「鸿蒙 ArkTS 应用开发」的知识体系，说明它和 HarmonyOS 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：ArkTS 语言约束、ArkUI 声明式写法与 Stage 模型。

**教材衔接：前置知识**

- 先完成上一课《Jetpack Compose 声明式 UI》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Jetpack Compose 声明式 UI」，或确认自己能独立跑通正文里的 LessonRepository 示例。
- 开始前先复习：鸿蒙、HarmonyOS、ArkTS。
- 看不懂就直接缩小例子：只保留 鸿蒙 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

- 核心问题：鸿蒙 ArkTS 应用开发不是孤立术语，而是在「移动开发」中解决一类具体问题。
- 关键关系：先分清「鸿蒙」与「HarmonyOS」的职责，再理解「ArkTS」的适用边界。
- 判断标准：能解释 鸿蒙 的正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后写下 鸿蒙 的 3 条要点，再去做本课测验。

## 核心概念定义

> 阅读约定：本课先给「鸿蒙 ArkTS 应用开发」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Stage 模型 | HarmonyOS 的应用模型：每个 UIAbility 是可独立启动的入口，页面在它的窗口里组织。 | 仅在「鸿蒙 ArkTS 应用开发」明确给出的输入、版本与资源条件下成立。 |
| 状态装饰器 | 用 @State、@Prop、@Link 标注数据的流向，决定状态变化如何触发界面刷新。 | 仅在「鸿蒙 ArkTS 应用开发」明确给出的输入、版本与资源条件下成立。 |
| ArkTS | HarmonyOS 的 TypeScript 系开发语言，在 TS 基础上加了声明式界面与静态约束。 | 仅在「鸿蒙 ArkTS 应用开发」明确给出的输入、版本与资源条件下成立。 |
| UIAbility | 应用的能力单元，负责一个可启动的界面以及它的生命周期回调。 | 仅在「鸿蒙 ArkTS 应用开发」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「鸿蒙 ArkTS 应用开发」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Stage 模型」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「状态装饰器」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「ArkTS」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「鸿蒙 ArkTS 应用开发」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Stage 模型 | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 状态装饰器 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | ArkTS | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「鸿蒙 ArkTS 应用开发」自己的示例验证。「鸿蒙 ArkTS 应用开发」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：技术栈速查**

| 组成 | 说明 |
| --- | --- |
| ArkTS | 基于 TypeScript 扩展的语言，禁用部分动态特性以提升性能 |
| ArkUI | 声明式 UI 框架，写法与 Compose/SwiftUI 类似 |
| Stage 模型 | 当前主推的应用模型，UIAbility 承载界面 |
| UIAbility | 应用组件，对应一个可启动的界面能力 |
| HAP / HSP | 模块包，HAP 为部署单元，HSP 为共享包 |
| AppGallery Connect | 上架、分发与测试服务 |

| 与 Android 对照 | Android | HarmonyOS |
| --- | --- | --- |
| 语言 | Kotlin / Java | ArkTS |
| UI | Compose / XML | ArkUI 声明式 |
| 入口组件 | Activity | UIAbility |
| 部署包 | APK / AAB | HAP / App Pack |
| 权限声明 | AndroidManifest | module.json5 |

**教材衔接：与 Flutter / Compose 的差异**

| 维度 | 说明 |
| --- | --- |
| 语言限制 | ArkTS 禁用 `any`、运行时动态属性等，编译期检查更严 |
| 状态装饰器 | 通过 `@State`/`@Prop` 等装饰器声明与传递状态 |
| 并发模型 | 提供 TaskPool 与 Worker 处理耗时任务，UI 线程不阻塞 |
| 分布式能力 | 支持跨设备流转、分布式数据对象（需用户授权） |
| 包体结构 | 以模块（Module）组织，HAP 按需分发 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 鸿蒙、HarmonyOS | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「鸿蒙 ArkTS 应用开发」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「鸿蒙 ArkTS 应用开发」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《鸿蒙 ArkTS 应用开发》原文中的最小示例。先预测《鸿蒙 ArkTS 应用开发》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```typescript
@Component
struct LessonList {
  @State lessons: Lesson[] = [];
  @State loading: boolean = false;

  aboutToAppear(): void {
    this.load();                       // 生命周期里做初始化，不在 build 中触发
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.lessons = await LessonRepository.fetch();
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column({ space: 8 }) {
      if (this.loading) {
        LoadingProgress().width(48).height(48);
      } else {
        List({ space: 8 }) {
          ForEach(this.lessons, (lesson: Lesson) => {
            ListItem() {
              Text(lesson.title)
                .fontSize(16)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding(16)
            }
          }, (lesson: Lesson) => lesson.id)      // 稳定 key，避免列表错位
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
```

**教材衔接：ArkUI 速查**

| 需求 | 写法 |
| --- | --- |
| 布局容器 | `Column`、`Row`、`Stack`、`Flex` |
| 列表 | `List` + `ListItem`，配合 `ForEach` |
| 状态 | `@State`、`@Prop`、`@Link`、`@Provide`/`@Consume` |
| 持久状态 | `PersistentStorage`、`AppStorage` |
| 复用组件 | `@Component` + `@Builder` |
| 副作用 | `aboutToAppear()`、`aboutToDisappear()` |
| 路由 | `router.pushUrl` / `Navigation` |

```typescript
@Component
struct LessonList {
  @State lessons: Lesson[] = [];
  @State loading: boolean = false;

  aboutToAppear(): void {
    this.load();                       // 生命周期里做初始化，不在 build 中触发
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.lessons = await LessonRepository.fetch();
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column({ space: 8 }) {
      if (this.loading) {
        LoadingProgress().width(48).height(48);
      } else {
        List({ space: 8 }) {
          ForEach(this.lessons, (lesson: Lesson) => {
            ListItem() {
              Text(lesson.title)
                .fontSize(16)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding(16)
            }
          }, (lesson: Lesson) => lesson.id)      // 稳定 key，避免列表错位
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
```

**教材衔接：零基础详解：鸿蒙 ArkTS 与 ArkUI**

### 一句话说清它是什么

鸿蒙应用用 **ArkTS**（TypeScript 的超集）编写，界面用 **ArkUI 声明式语法**描述。
心智与 Compose、SwiftUI 一致：**状态驱动界面**，改状态就自动刷新。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| ArkTS | 带类型的安全版 TS | 语法近似 TypeScript |
| ArkUI | 声明式画布 | 用代码描述界面 |
| 装饰器 | 贴标签 | `@State`、`@Prop` 标明数据角色 |
| Ability | 应用的一个能力入口 | UIAbility 对应一个界面容器 |
| 页面路由 | 导航员 | 页面之间跳转与传参 |

### 一个页面的基本结构

```typescript
@Entry
@Component
struct CounterPage {
  @State count: number = 0;

  build() {
    Column({ space: 12 }) {
      Text(`计数：${this.count}`)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)

      Button('加一')
        .onClick(() => { this.count += 1; })
        .width('60%')
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

| 关键点 | 说明 |
| --- | --- |
| `@Entry` | 标记为页面入口 |
| `@Component` | 标记为可复用组件 |
| `build()` | 描述界面结构 |
| `@State` | 组件内部状态，变化触发刷新 |

### 五个常用状态装饰器

| 装饰器 | 作用 | 数据流向 |
| --- | --- | --- |
| `@State` | 组件自己的状态 | 组件内部 |
| `@Prop` | 父传子的单向数据 | 父 → 子 |
| `@Link` | 与父组件双向同步 | 双向 |
| `@Provide` / `@Consume` | 跨层共享 | 祖先 → 后代 |
| `@Observed` / `@ObjectLink` | 观察对象内部变化 | 对象属性级 |

```typescript
@Component
struct Child {
  @Prop title: string;              // 只读，父组件传入
  @Link count: number;              // 双向，可直接改

  build() {
    Row({ space: 8 }) {
      Text(this.title)
      Button('+1').onClick(() => { this.count += 1; })
    }
  }
}
```

**要点**：`@State` 只能观察第一层变化；对象内部属性变化要用 `@Observed` 与 `@ObjectLink`。

### 页面跳转与传参

```typescript
import { router } from '@kit.ArkUI';

// 跳转并传参
router.pushUrl({
  url: 'pages/DetailPage',
  params: { id: 42, title: '订单详情' },
});

// 目标页面接收
const params = router.getParams() as Record<string, Object>;
const id = params?.id as number;

// 返回
router.back();
```

更推荐用 **Navigation 组件**管理多级页面与返回栈，能力比 `router` 更完整。

### 应用模型：Stage 模型

```text
entry/                      应用入口模块（HAP）
  src/main/ets/
    entryability/           UIAbility：界面入口与生命周期
    pages/                  页面
    components/             可复用组件
    model/                  数据模型
    viewmodel/              状态与业务编排
  resources/                字符串、图片、颜色
```

| 目录 | 职责 |
| --- | --- |
| `entryability` | 应用启动、前台后台切换 |
| `pages` | 页面级组件 |
| `components` | 通用组件 |
| `viewmodel` | 状态与数据编排 |

**资源统一放 `resources`**：多语言与深色模式都靠它切换，不要在代码里写死文案。

### 生命周期要处理的四件事

```typescript
export default class EntryAbility extends UIAbility {
  onCreate() { /* 初始化资源 */ }
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index');    // 加载首页
  }
  onForeground() { /* 恢复刷新 */ }
  onBackground() { /* 暂停轮询、保存草稿 */ }
}
```

| 时机 | 该做什么 |
| --- | --- |
| `onCreate` | 初始化全局资源 |
| `onWindowStageCreate` | 加载首页 |
| `onForeground` | 恢复定时器与刷新 |
| `onBackground` | 暂停任务、保存状态 |
| `onDestroy` | 释放资源 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用普通变量存状态 | 界面不刷新 | 用 `@State` |
| 修改对象内部属性 | 界面不更新 | 用 `@Observed` 与 `@ObjectLink` |
| 文案写死在代码里 | 无法多语言 | 放 `resources` |
| 忽略 `onBackground` | 后台仍在轮询耗电 | 暂停任务 |
| 列表项缺 key | 刷新后状态错位 | 提供稳定 key |
| 把业务写在 `build()` 里 | 重复执行 | 放生命周期或 ViewModel |
| 不处理权限申请 | 功能静默失败 | 运行时申请并处理拒绝 |
| 忘记适配深色模式 | 界面刺眼 | 用资源颜色变量 |

### 学完自测

- [ ] 能说出 `@State`、`@Prop`、`@Link` 的差别。
- [ ] 知道对象内部属性变化要用什么装饰器。
- [ ] 能说出 Stage 模型里 `entryability` 的职责。
- [ ] 知道为什么文案要放 `resources`。
- [ ] 能说出 `onBackground` 里应该做什么。

## 时间/空间复杂度或性能分析

**复杂度证据**：「鸿蒙 ArkTS 应用开发」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「鸿蒙 ArkTS 应用开发」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「鸿蒙 ArkTS 应用开发」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《鸿蒙 ArkTS 应用开发》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「鸿蒙 ArkTS 应用开发」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 `build()` 里发起请求 | 每次刷新都重复请求 | 放到 `aboutToAppear` 或事件回调 |
| 用普通变量存 UI 状态 | 界面不刷新 | 加 `@State` 等装饰器 |
| 列表 `ForEach` 不给 key | 增删后界面错乱 | 用唯一业务 ID 作为 key |
| UI 线程做耗时计算 | 界面卡顿 | 用 TaskPool / Worker |
| 权限只在代码里判断 | 未声明导致调用失败 | 同时在 `module.json5` 声明权限 |
| 直接用动态类型写法 | 编译报错 | 显式类型，遵循 ArkTS 约束 |
| 忽略多设备适配 | 大屏或折叠屏布局异常 | 用响应式断点与栅格布局 |

**教材衔接：故障现场**

### 现场 1：在 build() 里发起请求

**症状**：在《鸿蒙 ArkTS 应用开发》的复现场景中，每次刷新都重复请求。

**根因**：“每次刷新都重复请求”只是表层结果。向上追溯会落到“在 build() 里发起请求”这一步，因为它省略了《鸿蒙 ArkTS 应用开发》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《鸿蒙 ArkTS 应用开发》的问题，放到 aboutToAppear 或事件回调。

**验证**：在《鸿蒙 ArkTS 应用开发》中按“放到 aboutToAppear 或事件回调”调整后，从“在 build() 里发起请求”的触发条件重放同一条路径，确认“每次刷新都重复请求”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：列表 ForEach 不给 key

**症状**：在《鸿蒙 ArkTS 应用开发》的复现场景中，增删后界面错乱。

**根因**：当出现“列表 ForEach 不给 key”时，执行路径已经绕过了《鸿蒙 ArkTS 应用开发》的关键约束，最终以“增删后界面错乱”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《鸿蒙 ArkTS 应用开发》的问题，用唯一业务 ID 作为 key。

**验证**：先在《鸿蒙 ArkTS 应用开发》中记录“列表 ForEach 不给 key”留下的失败证据，再执行“用唯一业务 ID 作为 key”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：权限只在代码里判断

**症状**：在《鸿蒙 ArkTS 应用开发》的复现场景中，未声明导致调用失败。

**根因**：“未声明导致调用失败”只是表层结果。向上追溯会落到“权限只在代码里判断”这一步，因为它省略了《鸿蒙 ArkTS 应用开发》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《鸿蒙 ArkTS 应用开发》的问题，同时在 module.json5 声明权限。

**验证**：先在《鸿蒙 ArkTS 应用开发》中记录“权限只在代码里判断”留下的失败证据，再执行“同时在 module.json5 声明权限”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Jetpack Compose 声明式 UI》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《小程序开发要点》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Jetpack Compose 声明式 UI》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《移动端性能优化实战》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「鸿蒙 ArkTS 应用开发」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《鸿蒙 ArkTS 应用开发》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“鸿蒙 ArkTS 应用开发”中的 鸿蒙、HarmonyOS、ArkTS，下列哪两项是本课强调的实践判断？

A. 把 HarmonyOS 的单次运行结果当成所有版本和规模都成立
B. 学习 鸿蒙 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 鸿蒙 的常规示例通过，就可以跳过边界与异常路径
D. 验证 HarmonyOS 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 鸿蒙 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 HarmonyOS 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把鸿蒙 ArkTS 应用开发拆成概念、示例与故障现场三部分，因此判断 鸿蒙 时必须同时交代输入、输出和失败路径，这使“学习 鸿蒙 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在鸿蒙 ArkTS 应用开发里，判断 HarmonyOS 时要固定版本与边界输入，所以“验证 HarmonyOS 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

阅读「鸿蒙 ArkTS 应用开发」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？

```typescript
import { router } from '@kit.ArkUI';

// 跳转并传参
router.pushUrl({
  url: 'pages/DetailPage',
  params: { id: 42, title: '订单详情' },
});

// 目标页面接收
const params = router.getParams() as Record<string, Object>;
const id = params?.id as number;

// 返回
router.back();
```

A. 这段代码包含异常处理分支，失败时会走专门的补救路径。
B. 这段代码只做静态声明，没有循环、分支或可观察输出。
C. 这段代码包含条件分支，不同输入会走不同的执行路径。
D. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**参考答案**：这段代码只做静态声明，没有循环、分支或可观察输出。

**解析**：在「鸿蒙 ArkTS 应用开发」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「鸿蒙 ArkTS 应用开发」的正文示例，围绕鸿蒙、HarmonyOS、ArkTS展开；把输入或边界换成空值、极值或失败情况后，结论要以「鸿蒙 ArkTS 应用开发」的实际运行结果为准。

### 自测 3

在 ArkUI 中让界面随数据变化刷新，应该怎么做？

A. 用 @State 等状态装饰器声明数据
B. 手动调用重绘 API
C. 把数据放在全局常量里
D. 用普通成员变量保存数据，但它只覆盖了部分情况

**参考答案**：用 @State 等状态装饰器声明数据

**解析**：在「鸿蒙 ArkTS 应用开发」里，用 @State 等状态装饰器声明数据。ArkUI 通过装饰器建立数据与 UI 的绑定，状态变化自动触发刷新。「鸿蒙 ArkTS 应用开发」要求先交代鸿蒙、HarmonyOS、ArkTS的前提再下结论，所以“用 @State 等状态装饰器声明数据”只在题干“在 ArkUI 中让界面随数据变化刷新”给定的条件下成立。

**教材衔接：复习与自测**

- [ ] 能说清 ArkTS、ArkUI、UIAbility 与 Stage 模型的关系。
- [ ] 状态用装饰器声明，初始化放在生命周期而非 `build`。
- [ ] 列表使用稳定 key，耗时任务放 TaskPool。
- [ ] 权限在配置文件与代码中同时处理。
- [ ] 能对照 Android 的 Activity/Compose 理解差异。

**教材衔接：动手练习**

> 本课练习重点：围绕「鸿蒙、HarmonyOS、ArkTS」完成复述、实验和交付，每个结果都要能被别人检查。

先固定 HarmonyOS 的约束，再验证不同屏幕宽度下的表现。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 鸿蒙 ArkTS 应用开发解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「HarmonyOS」是什么关系？

验收标准：说明 鸿蒙 与 HarmonyOS 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：五步记录要写进笔记——原例是 LessonRepository，改动落在鸿蒙上，结论必须能被他人在同一环境里复现。

### 练习 3：交付一个小结果（30 分钟）

用最小 Widget 验证 HarmonyOS 在空数据与超长文本下的表现。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「鸿蒙」和「HarmonyOS」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```typescript
@Entry
@Component
struct CounterPage {
  @State count: number = 0;

  build() {
    Column({ space: 12 }) {
      Text(`计数：${this.count}`)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)

      Button('加一')
        .onClick(() => { this.count += 1; })
        .width('60%')
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

### 任务 2：只改一个条件

把「鸿蒙 ArkTS 应用开发」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 HarmonyOS 换成边界值，其他输入保持原样。
- 预测：先写下「鸿蒙 ArkTS 应用开发」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响鸿蒙。

### 任务 3：迁移到自己的数据

换一个 HarmonyOS 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「HarmonyOS 中承载界面的应用组件是？」的判断依据。
- [ ] 不看解析，能说出「ArkTS 相比 TypeScript 的主要差异是？」的判断依据。
- [ ] 不看解析，能说出「在 ArkUI 中让界面随数据变化刷新，应该怎么做？」的判断依据。
- [ ] 不看解析，能说出「ForEach 渲染列表时必须注意什么？」的判断依据。
- [ ] 不看解析，能说出「耗时计算放在 UI 线程会怎样？如何解决？」的判断依据。
- [ ] 跑通「鸿蒙 ArkTS 应用开发」的最小示例，并记录一次失败输入的处理方式。
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
| `Stage 模型` | HarmonyOS 的应用模型：每个 UIAbility 是可独立启动的入口，页面在它的窗口里组织。 |
| `状态装饰器` | 用 @State、@Prop、@Link 标注数据的流向，决定状态变化如何触发界面刷新。 |
| `ArkTS` | HarmonyOS 的 TypeScript 系开发语言，在 TS 基础上加了声明式界面与静态约束。 |
| `UIAbility` | 应用的能力单元，负责一个可启动的界面以及它的生命周期回调。 |

## 考点精讲

### 考点 1：多选辨析·鸿蒙

- **题目**：围绕“鸿蒙 ArkTS 应用开发”中的 鸿蒙、HarmonyOS、ArkTS，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把鸿蒙 ArkTS 应用开发拆成概念、示例与故障现场三部分，因此判断 鸿蒙 时必须同时交代输入、输出和失败路径，这使“学习 鸿蒙 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在鸿蒙 ArkTS 应用开发里，判断 HarmonyOS 时要固定版本与边界输入，所以“验证 HarmonyOS 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：代码补全·鸿蒙

- **题目**：阅读「鸿蒙 ArkTS 应用开发」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「鸿蒙 ArkTS 应用开发」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「鸿蒙 ArkTS 应用开发」的正文示例，围绕鸿蒙、HarmonyOS、ArkTS展开；把输入或边界换成空值、极值或失败情况后，结论要以「鸿蒙 ArkTS 应用开发」的实际运行结果为准。

### 考点 3：概念判断·鸿蒙

- **题目**：在 ArkUI 中让界面随数据变化刷新，应该怎么做？
- **判断依据**：在「鸿蒙 ArkTS 应用开发」里，用 @State 等状态装饰器声明数据。ArkUI 通过装饰器建立数据与 UI 的绑定，状态变化自动触发刷新。「鸿蒙 ArkTS 应用开发」要求先交代鸿蒙、HarmonyOS、ArkTS的前提再下结论，所以“用 @State 等状态装饰器声明数据”只在题干“在 ArkUI 中让界面随数据变化刷新”给定的条件下成立。

### 考点 4：概念判断·鸿蒙

- **题目**：ForEach 渲染列表时必须注意什么？
- **判断依据**：在「鸿蒙 ArkTS 应用开发」里，结论应落在「必须提供稳定唯一的 key」。稳定 key 让框架识别条目身份，增删时才能正确复用节点与状态。在「鸿蒙 ArkTS 应用开发」里，这道题要求区分概念与边界，「必须提供稳定唯一的 key」只有在题干给出的前提下才成立，而「必须每次重建全部节点」、「必须禁用虚拟化」缺少同一组条件。

### 考点 5：概念判断·鸿蒙

- **题目**：耗时计算放在 UI 线程会怎样？如何解决？
- **判断依据**：在「鸿蒙 ArkTS 应用开发」里，导致界面卡顿。UI 线程被占用会直接表现为掉帧甚至无响应，鸿蒙提供 TaskPool 与 Worker 处理并发任务。回到「鸿蒙 ArkTS 应用开发」的正文示例，用“耗时计算放在 UI 线程会怎样”走一遍鸿蒙、HarmonyOS、ArkTS的完整流程，能复现的结论才可以保留。

### 考点 6：填空·鸿蒙

- **题目**：补全代码：「鸿蒙 ArkTS 应用开发」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____(windowStage: window.WindowStage) {`
- **判断依据**：空格应填写「onWindowStageCreate」、「onwindowstagecreate」。在「鸿蒙 ArkTS 应用开发」里判断这道题，要把鸿蒙、HarmonyOS、ArkTS的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“ArkTS”与「鸿蒙 ArkTS 应用开发」的术语表相呼应，只有符合鸿蒙、HarmonyOS、ArkTS约束的“onWindowStageCreate”才是正文支持的结论。

## English Overview

**Title:** HarmonyOS ArkTS

**Summary:** ArkTS constraints, ArkUI declarative UI and Stage model.

**Category:** Mobile Development
**Level:** 进阶
**Key terms:** 鸿蒙, HarmonyOS, ArkTS, ArkUI, UIAbility

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Flutter 3.x / Dart 3.x
；本课聚焦 鸿蒙。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：鸿蒙、HarmonyOS、ArkTS、ArkUI、UIAbility
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Dart 语言文档](https://dart.dev/language) | 语言语法、类型与空安全 |
| [Dart 异步编程](https://dart.dev/libraries/async/async-await) | Future、Stream 与事件循环 |
| [Flutter 包与插件](https://docs.flutter.dev/packages-and-plugins) | 包管理、插件与平台通道 |

> 「鸿蒙 ArkTS 应用开发」的链接用于离线阅读后的延伸核对；App 不会自动联网。
