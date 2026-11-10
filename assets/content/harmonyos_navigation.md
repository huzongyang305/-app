# 路由与页面导航

![HarmonyOS 页面栈与 Navigation 导航容器的工作模型](images/diagram_harmonyos_navigation.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：45 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `路由与页面导航`，学习阶段 移动，建议用时 45 分钟。

本课主线：先说明鸿蒙同时存在两套导航方案——`@ohos.router` 的页面级路由与 `Navigation` 的组件级导航，给出选型判据；再展开 `NavPathStack` 这棵导航栈的每一种操作与对应的生命周期回调；然后补齐对话框、侧边栏、自定义转场三类非常规导航；最后把页面显示隐藏、返回拦截与状态恢复这些「导航引起的生命周期问题」一次讲透。

**学完本课应当能够**

- 在新工程里正确选型，说明为什么官方把 `Navigation` 作为多端与分栏场景的首选，以及什么情况仍适合 `router`。
- 熟练使用 `pushPath`、`pushDestination`、`popToName`、`clear`、`replacePath` 等导航栈 API 完成入栈、出栈、替换与清栈，并解释每一步触发的回调。
- 设计页面间结果回传与返回拦截，避免用全局变量或轮询兜住跨页通信。
- 说清 `onPageShow`、`onPageHide`、`onBackPress`、`aboutToDisappear` 在两套方案中的触发时机差异。

### 复习清单

- [ ] 能不看正文画出一次 push 与 pop 之间的生命周期顺序。
- [ ] 能说出 Navigation 的三种容器模式与对应的界面表现。
- [ ] 能完成一次自测，把错题对照易错点表定位是导航栈语义还是生命周期时机理解错了。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| router 路由表 | `main_pages.json` 登记的页面清单，按文件路径寻址，页面必须带 `@Entry`。 | 易错：页面忘了登记，pushUrl 直接失败但错误只打在日志里。 |
| NavPathStack | Navigation 的栈句柄，提供入栈、出栈、替换、查询与拦截的编程式接口。 | 易错：多处各自 new 一个栈，导致真正的栈句柄被架空。 |
| NavDestination | 导航内容的单元，相当于栈上的一个节点，自身带生命周期回调。 | 易错：把 NavDestination 当普通组件写在页面里，不接导航栈就没意义。 |
| navBar / navDestination | 分别定义导航的起始栏与内容构建工厂，按名字路由到具体页面构建器。 | 易错：工厂里不做名字判断，所有名字渲染成同一个界面。 |
| mode | 容器模式，`Stack` 全屏压栈、`Split` 左右分栏、`Auto` 按宽度自适应。 | 易错：只测手机竖屏，平板上分栏后返回逻辑失效。 |
| 结果回传 | pop 时携带数据，由 `onPopReady` 或 pushPath 的回调在上一页接收。 | 易错：在子页面里直接改父页面状态，破坏状态归属。 |
| onBackPress | 页面返回拦截回调，返回 true 表示已消费，系统不再继续返回。 | 易错：忘记返回 false 分支，导致侧滑与实体返回全部失效。 |
| 命名路由 | 通过名字而非文件路径寻址的页面注册方式，与按需加载配合使用。 | 易错：名字大小写不一致，运行期拿不到构造函数。 |

## 原理与运行机制

### 机制总览：两套导航的分工

router 是页面级方案：一次跳转替换整个窗口内容，栈由系统维护，页面之间通过参数对象传值，路由表在编译期固定。Navigation 是组件级方案：导航容器只是视图树里的一个节点，容器内可以有工具栏、内容区与侧栏，栈由 `NavPathStack` 显式管理，页面是 `NavDestination` 而不是独立窗口。正因为 Navigation 把导航做成组件，它才可能同时支持单栏、分栏与侧拉三种形态，也能在一多设备上用同一套栈代码工作。

**教材衔接：选型判据**

| 需求 | 推荐方案 | 关键原因 |
| --- | --- | --- |
| 只有三五页的简单工具 | router | 心智负担小，页面即文件 |
| 需要平板左右分栏 | Navigation | 分栏是容器模式而不是两套代码 |
| 半模态详情与弹层 | Navigation 加 Dialog/Custom 类型 | 转场与系统层级统一管理 |
| 深层嵌套的详情页 | Navigation | 栈句柄可编程，能精确回退 |
| 老工程只做路径迁移 | router | 增量替换成本更低 |

**教材衔接：一次压栈走过的四个阶段**

调用 `pushPath` 之后，框架依次做：向栈写入节点、调用目标构建工厂生成 `NavDestination`、播放进场转场动画、在内容挂载完成后回调目标页的 `onReady` 与 `onShown`。对应的出栈也分四步：触发 `onBackPressed` 判断是否拦截、执行退场动画、销毁节点并回调 `onHidden` 与 `aboutToDisappear`、把结果数据交给上一页的 pop 回调。把这条链记住，绝大多数「返回后不刷新」的问题都能定位到是回调时机不对而不是数据没传。

```typescript
import { router } from '@kit.ArkUI';

@Entry
@Component
struct LessonList {
  lessons: string[] = ['软总线', '状态管理', '卡片开发'];

  build() {
    List({ space: 8 }) {
      ForEach(this.lessons, (name: string) => {
        ListItem() {
          Text(name)
            .width('100%')
            .height(48)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/LessonDetail',
                params: { title: name }
              }).catch((e: Error) => {
                console.error(`push failed: ${e.message}`);
              });
            })
        }
      }, (name: string) => name)
    }
    .padding(12)
  }
}
```

**教材衔接：NavPathStack 的操作语义**

| 方法 | 对栈的影响 | 常见用途 |
| --- | --- | --- |
| pushPath | 追加一个节点，上一页保留 | 进入详情 |
| pushDestination | 追加并等待内容就绪回调 | 需要拿到子页句柄时 |
| replacePath | 用新节点替换栈顶 | 引导页结束后不让返回 |
| popToName | 回退到指定命名节点 | 多级表单一步回到首页 |
| popWithInfo | 出栈并携带结果 | 选择器页面回传 |
| clear | 清空除起始栏外的节点 | 退出登录 |

**教材衔接：生命周期与页面可见性**

router 页面用 `@Entry` 组件上的 `onPageShow`、`onPageHide`、`onBackPress`；Navigation 的 `NavDestination` 用 `onShown`、`onHidden`、`onBackPressed` 与 `onReady`。两套都遵循「隐藏不等于销毁」：被上层页面盖住的页面只触发隐藏回调，节点与状态仍在；真正销毁发生在出栈时，因此不要指望 `aboutToDisappear` 承担「页面切走」的职责，做暂停播放、停止定位这类动作应当挂在隐藏回调上。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 商品列表到详情 | 列表项带主键，详情页需要按 id 拉数据 | 命名路由加参数校验，返回时列表保留滚动位置 |
| 多级表单分步填写 | 四步表单，最后一步要一次回到首页 | 栈内命名节点加 `popToName`，中途数据落在共享状态 |
| 平板主从布局 | 同套代码在手机压栈、平板分栏 | `mode` 设为 Auto，配合断点与侧栏构建器 |

- 典型现象：返回后页面数据是旧的。正确做法：把刷新逻辑放在 `onShown`/`onPageShow`，而不是构造或首次挂载回调。
- 典型现象：连续点击列表触发多次入栈，返回要点好几次。正确做法：入栈前用节流或判断栈顶是否已是同一名字。
- 典型现象：侧滑关闭时脏数据没保存。正确做法：拦截返回回调，在两个分支里都走同一个收尾函数。

### 最小验证场景

- 准备：一个导航容器，三个命名页面，其中一页负责选择并通过结果回传写入上一页。
- 观察：依次执行入栈、返回、`popToName` 到指定页、`clear` 后重新入栈，记录每一步的栈深与触发到的生命周期回调顺序。
- 判定：能画出完整回调序列，且返回后上一页数据即时正确、拦截分支不影响系统侧滑，即视为导航链路掌握。

## 代码/协议/SQL 示例

**教材衔接：一个可运行的 Navigation 骨架**

下面这段把导航栈、起始栏与内容工厂三件事写全。工厂函数按名字把请求分派到具体的 `NavDestination` 构建器，这是命名路由的核心；名字匹配不到时应给出兜底界面，否则内容区会一片空白。

```typescript
@Component
export struct RootPage {
  paths: NavPathStack = new NavPathStack();

  @Builder
  factory(name: string) {
    if (name === 'detail') {
      DetailDestination()
    } else if (name === 'settings') {
      SettingsDestination()
    } else {
      NavDestination() {
        Text(`未注册的路由：${name}`)
      }
    }
  }

  build() {
    Navigation(this.paths) {
      Column({ space: 12 }) {
        Button('进入详情').onClick(() => {
          this.paths.pushPath({ name: 'detail', param: { id: 42 } });
        })
        Button('打开设置').onClick(() => {
          this.paths.pushPath({ name: 'settings' });
        })
      }
      .padding(16)
    }
    .mode(NavigationMode.Auto)
    .navBarWidth(320)
    .navDestination(this.factory)
  }
}
```

**教材衔接：结果回传与返回拦截**

选择器页面最干净的写法是把结果通过出栈动作带回，上一页在入栈时注册的回调里接收。返回拦截返回 true 表示已消费，框架不再继续默认行为，所以任何不需要拦截的分支必须显式返回 false。

```typescript
@Entry
@Component
struct CityPicker {
  paths: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.paths) {
      Button('选杭州').onClick(() => {
        this.paths.pop({ name: '杭州' }, true);
      })
    }
    .navDestination((name: string) => {
      this.factory(name)
    })
  }

  @Builder
  factory(name: string) {
    NavDestination() {
      Text('城市列表')
    }
    .onBackPressed(() => {
      this.paths.pop(undefined, true);
      return true;
    })
  }
}
```

错误表现：在子页面里直接改父页面持有的状态对象，父子耦合后父页面销毁时引用失效，表现为随机崩溃或数据丢失。

```typescript
parentState.selected = city;     // 跨页面直接写对方状态
this.paths.pop();
```

正确写法：把结果放进出栈动作携带的数据里，由上一页在回调中自行落地，数据所有权保持清晰。

```typescript
this.paths.pop({ name: city }, true);   // 结果随出栈返回
```

## 时间/空间复杂度或性能分析

| 维度 | 与什么相关 | 失控表现 | 控制手段 |
| --- | --- | --- | --- |
| 入栈耗时 | 目标页节点数与数据请求 | 点击后明显白屏 | 先展示骨架再拉数据 |
| 栈深 | 未回收的历史节点数 | 返回要点很多次、内存上涨 | 用替换或回退到指定节点收敛栈 |
| 单节点内存 | 页面持有的图片与列表缓存 | 深层跳转后被 OOM 回收 | 隐藏时释放重资源 |
| 转场开销 | 动效层级与截图成本 | 低端机掉帧 | 简化自定义转场 |
| 构建工厂分派 | if 分支数量 | 首帧分支判断成本可忽略 | 用注册表替代长链 if |

导航的性能问题绝大多数是「栈没有管理好」。深链跳转（列表到详情到评论到用户到列表）会让栈不断变深，每一层都保留自己的组件树与图片缓存，内存随栈深线性增长；合理做法是在语义上不允许返回的节点用替换而不是追加，并在页面隐藏时主动释放大资源。自定义转场会额外触发一次内容截图，节点复杂时应降低动画层级。

Navigation 相比 router 的一个隐性优势是按需加载：命名路由的目标构建器可以配合动态导入，只有真正进入时才把对应模块载入，这会把首屏包体的解析成本摊到使用时；代价是首次进入稍慢，因此对进入概率高的页面要预热。

导航结构对指标的影响常被低估。启动耗时上，路由表解析与首个页面构建串在首帧之前，页面数量增加会让这一步变慢，因此入口页应保持轻量，把重资源留到真正进入时再取。帧率方面，转场期间新旧页面同时存在于渲染树中，层级越深、节点越多，动画期间的掉帧越明显。渲染上多一层导航容器就多一次测量与布局求解。包体角度，页面文件都编译进同一份字节码，把低频的深层页面拆到按需加载的模块里，能同时改善首包体积与冷启动路径。

## 常见误区与易错点

- **两套方案混着当同一套用。** router 用路径寻址，Navigation 用名字与栈句柄，混用时会话与生命周期语义不同。
- **页面没登记进路由表。** router 的 pushUrl 会失败，而且失败常只在日志里体现，表现为「点了没反应」。
- **到处 new 导航栈。** 每个组件持有各自的句柄，真实栈与代码里的栈不同步，pop 自然无效。
- **把刷新写在构造回调。** 返回时组件并不会重新构造，刷新应挂在显示回调上。
- **返回拦截漏写默认分支。** 只写了 true 的分支会让系统返回和侧滑一起失效。
- **用全局变量做跨页回传。** 短期能跑，但破坏了状态归属，多入口复用同一页时立刻出问题。
- **只测手机竖屏。** 分栏模式下返回语义不同，必须验证平板与折叠屏展开态。
- **无限压同名节点。** 快速点击会叠加多层，需要做节流或栈顶判断。
- **工厂函数不做兜底。** 未注册的名字直接落到空实现上，页面一片白。
- **以为出栈即销毁。** 被上层盖住只触发隐藏，真正销毁发生在出栈动画结束。

## 与其他知识点的关系

**教材衔接：导航与状态、生命周期的交界处**

导航决定「谁在什么时候显示」，状态决定「显示时数据从哪里来」。跨页数据回传如果走全局状态，等于把状态所有权交给路由结构，页面复用与并发入口都会变得脆弱；正确顺序是先定状态归属，再选导航方式。同时，页面显示隐藏回调是资源管理的入口，需要与网络、多媒体、传感器课程里的启停逻辑对齐。

- 向上承接 `harmonyos_arkui_first_page`：页面必须先成为可登记的路由目标才能被跳转。
- 与 `harmonyos_state_management` 协同：跨页数据流依赖状态容器而不是全局变量。
- 向下游支撑 `harmonyos_distributed`：跨端续播要求导航栈可序列化并在对端重建。
- 与 `harmonyos_system_capabilities` 交界：deeplink 与隐式 Want 会把用户直接送到栈中间。
- 平行对照 `android_development_navigation`：Jetpack Navigation 的返回栈与 NavPathStack 概念高度对应。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_arkui_first_page | 首个声明式页面 | 页面登记与 @Entry 语义是路由跳转的前提 |
| harmonyos_state_management | 状态管理与数据传递 | 跨页回传的正确形态取决于状态归属设计 |
| harmonyos_multimedia | 多媒体与图形渲染 | 自定义转场与页面动效共用同一套动画能力 |
| harmonyos_system_capabilities | 系统能力与权限 | 由通知或深链进入应用时的落栈方式在该课展开 |
| harmonyos_distributed | 分布式软总线 | 迁移与续播要求导航栈与页面状态可序列化 |

## 自测题与参考答案

**教材衔接：题号 1** — 下列关于 `@ohos.router` 与 `Navigation` 的说法正确的是？

**参考答案**：router 适合简单的页面级跳转。

本题正确项是「router 适合简单的页面级跳转」。它以文件路径寻址、整窗替换内容，栈由系统维护，页面数少时心智负担最小；`Navigation` 把导航做成组件，因此能承担分栏、弹层与可编程栈这些复杂形态，说它只能整页跳转并不准确。两套方案在同一工程里可以共存，只是不建议对同一条链路同时使用，避免两套生命周期互相干扰。

**教材衔接：题号 2** — `NavPathStack.pushPath` 被调用后的效果是？

**参考答案**：向导航栈压入一个新页面。

本题正确项是「向导航栈压入一个新页面」。它追加节点并保留上一页，随后调用内容构建工厂生成对应的导航节点并播放转场。替换栈顶是 `replacePath` 的语义，回退到指定命名节点要用 `popToName`，清空整栈另有 `clear` 方法，四者动作完全不同，混用会造成返回逻辑与预期不符。

**教材衔接：题号 3** — 关于页面可见性回调，下列说法正确的是？

**参考答案**：onPageShow 在页面切前台时触发。

本题正确项是「onPageShow 在页面切前台时触发」。页面被上层盖住时触发隐藏回调，重新回到前台时触发显示回调，做数据刷新与播放恢复应挂在这里。组件销毁对应的是 `aboutToDisappear`，它只在节点真正出栈销毁时执行；返回拦截回调想阻止默认返回必须显式返回 true，而不是「拦不住」；该回调也不会在每次构建时重复触发。

**教材衔接：题号 4** — 子页面完成后要把选择结果带回上一页，最合适的做法是？

**参考答案**：出栈时携带结果并由回调接收。

本题正确项是「出栈时携带结果并由回调接收」。结果随出栈动作返回，上一页在入栈时注册的回调里接收并写入自己的状态，数据所有权清晰、页面可复用。直接改父页面状态会让两页强耦合，写磁盘再读延迟高且引入一致性问题，定时轮询既耗资源也拿不到准确的完成时机，都不适合作为跨页通信手段。

**教材衔接：题号 5** — 下面代码最后一行打印的是？
const stack: NavPathStack = new NavPathStack();
stack.pushPath({ name: 'detail' });
stack.pushPath({ name: 'settings' });
stack.pushPath({ name: 'detail' });
console.info(`${stack.size()}-${stack.getAllPathName().length}`);

**参考答案**：打印 3-3。

本题正确项是「打印 3-3」。三次入栈都会追加节点，重复的名字不会被合并，因此栈深是 3；`getAllPathName()` 返回的是按栈序排列的全部名字数组，同样包含重复项，长度也是 3。要按名字数量去重得自己转成集合，指望命名路由自动去重是常见误解。

## 考点精讲

**教材衔接：高频考点**

1. 两套导航的选型判据：是否需要分栏、弹层与可编程栈。
2. `NavPathStack` 六个核心方法的语义差异，尤其 push 与 replace、popToName 与 clear。
3. 显示隐藏与销毁的分界，决定刷新与资源释放写在哪一个回调。
4. 跨页结果回传的正确形态：随出栈携带，由上一页接收。

**教材衔接：命题规律**

- 语义辨析题把四个栈方法并列，正确项描述的动作要与方法名严格对应。
- 生命周期题喜欢给一段跳转序列，问哪几个回调按什么顺序触发。
- 排错题常描述「返回后数据不刷新」或「返回点了没反应」，答案指向回调时机或路由登记。

**教材衔接：常见考点**

问：下列关于 `@ohos.router` 与 `Navigation` 的说法正确的是？
答：router 适合简单的页面级跳转。

问：`NavPathStack.pushPath` 被调用后的效果是？
答：向导航栈压入一个新页面。

问：关于页面可见性回调，下列说法正确的是？
答：onPageShow 在页面切前台时触发。

问：子页面完成后要把选择结果带回上一页，最合适的做法是？
答：出栈时携带结果并由回调接收。

问：下面代码最后一行打印的是？
const stack: NavPathStack = new NavPathStack();
stack.pushPath({ name: 'detail' });
stack.pushPath({ name: 'settings' });
stack.pushPath({ name: 'detail' });
console.info(`${stack.size()}-${stack.getAllPathName().length}`);
答：打印 3-3。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| router 路由表 | main_pages.json 登记的页面清单，按文件路径寻址。 |
| NavPathStack | 导航栈句柄，提供入栈、出栈、替换与查询的编程接口。 |
| NavDestination | 导航栈上的一个内容节点，自带显示隐藏与返回回调。 |
| NavigationMode | 容器形态，可选全屏压栈、左右分栏或按宽度自适应。 |
| navDestination | 内容构建工厂，把路由名字分派到具体的目标页面。 |
| popWithInfo | 出栈同时携带结果数据，由上一页回调接收。 |
| onBackPressed | 返回拦截回调，返回 true 表示已消费不再默认返回。 |
| onShown | 导航节点回到可见状态时的回调，用于刷新与恢复。 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-11-10
- 学习阶段：移动
- 适用环境：DevEco Studio NEXT / HarmonyOS API 12+；真机需 HarmonyOS 4/5 NEXT；构建产物为 HAP/HSP/AppPack
- 内容来源：华为官方文档与工程实践整理
- 相关主题：ArkTS、ArkUI、分布式软总线、上架 AppGallery

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-11-10
- [HarmonyOS NEXT 开发者官网](https://developer.huawei.com/consumer/cn/harmonyos-next/)
- [Navigation 组件导航开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-navigation)
- [页面路由 Router 接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-router)
- [UIAbility 生命周期与窗口管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-lifecycle)
- [命名路由与按需加载](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-named-routing)
