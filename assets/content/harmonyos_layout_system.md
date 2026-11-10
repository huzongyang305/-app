# 布局系统：Flex/Grid/Stack

![ArkUI 布局容器体系与一次开发多端部署的断点映射](images/diagram_harmonyos_layout_system.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `布局系统：Flex/Grid/Stack`，学习阶段 移动，建议用时 50 分钟。

本课主线：先把线性布局的三兄弟 Row / Column / Flex 的差别讲到可背出来，再补齐层叠与相对定位两类非常规布局，然后进入列表与网格两大内容型容器，最后用媒体查询、断点系统与栅格组件把上面所有内容串成「一次开发，多端部署」的落地方案，并单独说明折叠屏展开态的处理方式。

**学完本课应当能够**

- 针对给定视觉稿判断该用 `Flex`、`Stack` 还是 `RelativeContainer`，并说明各自的空间分配模型。
- 用 `layoutWeight`、`justifyContent`、`alignItems`、`flexWrap` 四个关键属性组合出稳定的弹性布局，不再靠硬编码尺寸对齐。
- 用 `List` 的懒加载与复用能力承载长内容，并通过 `Grid` 的模板字符串实现不等宽网格。
- 使用媒体查询与栅格断点让同一页面在手机、平板与折叠屏展开态都能正常显示。

### 复习清单

- [ ] 能不看正文说出 Row 与 Flex 在换行与主轴方向上的差别，并各写一个例子。
- [ ] 能画出 List 懒加载时「视口 + 缓存区」的示意图，并说明为什么需要稳定键。
- [ ] 能完成一次自测，把错题对照易错点表定位是空间分配还是容器选型判断错了。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| 主轴与交叉轴 | 线性布局中排列方向称主轴，垂直方向称交叉轴，对齐属性分别作用于两者。 | 易错：Flex 改变 direction 后仍按原来的对齐属性名理解效果。 |
| layoutWeight | 按权重瓜分父容器在主轴方向上的剩余空间，参与分配的子项不再用固定尺寸。 | 易错：给权重同时又给固定宽，实际表现取决于剩余空间是否够。 |
| Flex | 弹性容器，支持换行、方向切换与多行对齐，是 Row/Column 的超集。 | 易错：以为 Flex 一定比 Row 慢，差别在层级而不是单次测量。 |
| Stack | 层叠容器，子节点按声明顺序自下而上叠放，可用对齐与偏移定位。 | 易错：只靠声明顺序控制遮挡关系，动态场景应显式设置层级。 |
| RelativeContainer | 相对布局容器，通过锚点、参考线、屏障建立子节点之间的约束。 | 易错：不写锚点规则，子节点会退回默认位置，看起来像失效。 |
| Grid 模板 | 用类似 `1fr 2fr` 的字符串描述列宽比例与固定列，配合 GridItem 使用。 | 易错：在滚动容器里放不可滚动 Grid，导致高度测量异常。 |
| List 懒加载 | 只为视口与缓存区内的条目创建组件，滑出后回收复用。 | 易错：条目缺少稳定唯一键，复用后出现状态错位。 |
| 断点系统 | 按窗口宽度划分 xs/sm/md/lg/xl，配合栅格列数切换布局密度。 | 易错：只按设备型号判断，横竖屏与自由窗口会立刻打脸。 |

## 原理与运行机制

### 机制总览：ArkUI 的三套空间分配模型

布局的本质是把父容器给定的空间分给子节点。ArkUI 里存在三种模型：线性容器按「固定尺寸 + 权重瓜分剩余」分配；层叠容器给所有子节点同样的画布，靠对齐与偏移解决重叠；相对容器把一次求解拆成约束图，由锚点决定先后。选型的第一步不是问「哪个更灵活」，而是问「这份视觉稿的空间由谁决定」——由内容决定就用自适应，由比例决定就用权重，由彼此关系决定才考虑相对布局。

**教材衔接：容器选型对照**

| 需求特征 | 首选容器 | 关键属性 | 不该用的方案 |
| --- | --- | --- | --- |
| 一行几个等宽按钮 | Row 加权重 | layoutWeight | 逐个写死宽度 |
| 标签流式换行 | Flex | wrap、space | Column 手动分行 |
| 角标覆盖头像 | Stack | alignment、offset | 多层相对定位 |
| A 跟随 B 底部 | RelativeContainer | anchor、alignRule | 嵌套三层 Row |
| 不定长记录列表 | List | space、cachedCount | Column 全量渲染 |
| 不等宽图片墙 | Grid / WaterFlow | columnsTemplate | 手写二维数组 |

**教材衔接：Row、Column 与 Flex 的真实边界**

三者共享同一套测量逻辑，差别集中在能力开关上：`Flex` 暴露 `direction`、`wrap`、`space`、`alignItems` 的完整组合，能一行变多行；`Row` 与 `Column` 是它的两个特化写法，语义更明确，代码更短，但不支持自动换行。因此「什么时候必须换成 Flex」只有一个硬条件：需要换行。其余场景按可读性选择即可，性能差异可以忽略。

**教材衔接：层叠与相对定位的分工**

`Stack` 解决「同一个位置放多层内容」，典型如背景图加文案、头像加在线状态点、卡片加右上角徽标。层级默认由声明顺序决定，需要动态置顶时用 `zIndex` 显式声明；`clip` 控制是否裁掉超出画布的部分，不设置时子节点越界仍会绘制但不会参与父容器尺寸。`RelativeContainer` 面向「A 的位置依赖 B」的场景，通过 `Rules` 描述 anchor、中心线、屏障三类约束，好处是层级只有一层，测量链路短；代价是约束表达不如嵌套直观，复杂规则要写注释。

```typescript
@Entry
@Component
struct TagFlow {
  tags: string[] = ['鸿蒙', 'ArkTS', 'ArkUI', '声明式', '软总线', '元服务', '分布式'];

  build() {
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(this.tags, (item: string) => {
        Text(item)
          .fontSize(14)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .margin({ right: 8, bottom: 8 })
          .backgroundColor('#EAF1FF')
          .borderRadius(14)
      }, (item: string) => item)
    }
    .padding(12)
    .width('100%')
  }
}
```

**教材衔接：长列表的回收与稳定键**

`List` 的每个 `ListItem` 只有进入「视口 + 预加载区」才会被创建，滑出后进入回收池。要复用组件而不是重建，可给子组件加 `@Reusable`，此时框架会跳过构造与析构，改为回调复用钩子，你必须自己把内部状态重置，否则会把上一条的数据带到下一条。键值必须稳定唯一：用数组下标当键会让「删除中间一项」变成整片错位，正确做法是用业务主键。滚动控制交给 `Scroller`，下拉刷新与加载更多分别接刷新组件与触底事件，不要把这三件事写在同一个状态里。

**教材衔接：一次开发多端部署**

鸿蒙把多端适配做成框架能力：`GridRow` / `GridCol` 提供 12 列栅格与断点配置，`mediaquery` 提供窗口尺寸监听，断点从 xs 到 xl 覆盖手表到车机。真正可维护的做法是「布局随窗口宽度变，而不是随设备型号变」，因为折叠屏半折态、平行视界、自由窗口都会让型号判断失效。

```json
{
  "breakpoints": {
    "xs": "0vp",
    "sm": "600vp",
    "md": "840vp",
    "lg": "1440vp"
  },
  "gridColumns": { "xs": 4, "sm": 8, "md": 12, "lg": 12 }
}
```

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 首页九宫格入口 | 图标数量不固定，需要按屏宽自动决定列数 | Grid 加断点列数，条目等宽且可滚动 |
| 消息流页面 | 条目高度不一，数量上千 | List 加复用与稳定键，滑动帧率稳定 |
| 折叠屏适配 | 同一页面在手机竖屏与内屏展开态都要可用 | 断点驱动的栅格与主从布局切换 |

- 典型现象：手机上排版正常，平板上左右留白巨大。正确做法：根容器改成栅格列并设置最大宽度，而不是给每个子项加百分比。
- 典型现象：列表滑动时出现「图片串位」。正确做法：给条目设置稳定键并在复用回调里清空占位图。
- 典型现象：给某项加了权重后其它项被挤没。正确做法：权重只在剩余空间内分配，先确认固定项尺寸之和小于父容器。

### 最小验证场景

- 准备：一个页面，内含一行三等宽卡片、一个标签流、一个 500 条数据的列表，全部用同一套组件写成。
- 观察：把窗口宽度从 360vp 逐步拉到 1200vp，记录每一档下列数、卡片宽度与列表首屏条目数变化。
- 判定：布局变化只在预设断点发生、中间过程不出现跳变或截断，且 500 条列表滑动时不出现空白条目，即视为布局体系掌握到位。

## 代码/协议/SQL 示例

**教材衔接：List 与 Grid 的写法差异**

两者都支持滚动与分组，但空间模型不同：`List` 沿一个方向排布，`lanes` 可以把它变成多列瀑布式；`Grid` 由模板字符串同时决定行列，条目必须包在 `GridItem` 里。

```typescript
@Component
struct FeedList {
  items: string[] = Array.from({ length: 200 }, (_: void, i: number) => `item-${i}`);
  private scroller: Scroller = new Scroller();

  build() {
    List({ space: 8, scroller: this.scroller }) {
      ForEach(this.items, (name: string) => {
        ListItem() {
          Text(name)
            .width('100%')
            .height(56)
            .padding({ left: 16 })
            .backgroundColor(Color.White)
            .borderRadius(10)
        }
      }, (name: string) => name)
    }
    .width('100%')
    .height('100%')
    .cachedCount(6)
    .divider({ strokeWidth: 0 })
  }
}
```

**教材衔接：RelativeContainer 的锚点表达**

「标题在图片右侧、副标题贴底」这类描述在嵌套布局里要三层，在相对容器里是一次求解。`id` 是被引用方的名字，`anchor` 指定参照物，`align` 决定贴哪条边。

```typescript
@Entry
@Component
struct MediaCell {
  build() {
    RelativeContainer() {
      Image($r('app.media.cover'))
        .id('cover')
        .width(72)
        .height(72)
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          left: { anchor: '__container__', align: HorizontalAlign.Start }
        })
      Text('标题文字')
        .id('title')
        .alignRules({
          top: { anchor: 'cover', align: VerticalAlign.Top },
          left: { anchor: 'cover', align: HorizontalAlign.End }
        })
        .margin({ left: 12 })
    }
    .width('100%')
    .height(84)
  }
}
```

错误表现：把整份数据一次性交给 `Column` 渲染，几百个条目同时构建，首帧明显卡顿且滑动掉帧。

```typescript
Column() {
  ForEach(this.rows, (r: Row) => { Text(r.name) })   // 全量创建，无回收
}
```

正确写法：换成带回收能力的 `List`，并给出稳定键，让框架只维护视口附近的节点。

```typescript
List({ space: 8 }) {
  ForEach(this.rows, (r: Row) => { ListItem() { Text(r.name) } }, (r: Row) => r.id)
}
```

## 时间/空间复杂度或性能分析

| 容器 | 单次测量复杂度 | 内存特征 | 适合规模 | 主要风险 |
| --- | --- | --- | --- | --- |
| Row / Column | 与子节点数线性 | 全量驻留 | 数十节点 | 深层嵌套放大测量链路 |
| Flex | 线性，换行时多一趟 | 全量驻留 | 数十节点 | 换行加权重时易出现空行 |
| Stack | 与子节点数线性 | 全量驻留 | 少量覆盖层 | 层级混乱导致遮挡误判 |
| RelativeContainer | 接近线性，取决于约束图 | 全量驻留 | 一层内多约束 | 约束缺失表现为静默失效 |
| List / Grid | 视口内常数级 | 与缓存条目数相关 | 上千条目 | 键不稳定导致复用错位 |
| 栅格 GridRow | 与列配置相关 | 视口内驻留 | 页面骨架 | 断点跳变处理不好会抖动 |

布局性能的第一原则是「让不滚动的内容尽量少、让滚动的内容可回收」。全量渲染的页面，构建耗时与节点总数近似线性，节点到三四千时首帧会进入数百毫秒区间；同样数据换成 `List` 后常驻节点数只与视口和缓存区有关，首帧与滑动都稳定。第二个原则是「减少测量往返」：嵌套的加权布局会在父子之间来回求解，父容器给约束、子容器反推理想尺寸，深度每加一层成本乘以常数，因此能把三层 Row 压成一层 RelativeContainer 或一个栅格就更压。

折叠屏与自由窗口带来额外的重排成本：窗口尺寸变化会触发整棵树的重新测量，如果页面里有依赖宽度的计算逻辑并且写在构建路径上，就会在拖拽窗口时每帧执行一次。合理做法是把尺寸计算结果缓存成状态，只在断点跨越时更新，而不是每个像素都重算。

布局是这几项指标里最容易被写坏的一环。启动耗时上，首屏的容器嵌套深度直接决定第一帧的求解轮数，权重与弹性布局还会引入额外的分配回合。帧率上，列表项的布局复杂度会被条目数量放大，滚动时每一帧都要重算变化项，因此条目内应尽量用固定尺寸加一次测量。渲染方面，相对定位与栅格断点会带来额外的约束求解，折叠屏切换时的重排代价也应纳入评估。包体上布局本身几乎不占空间，但为多形态准备的限定资源会成倍增加，需要与设备清单一起权衡。

## 常见误区与易错点

- **把 Flex 当 Row 的替代品。** 只有需要换行或动态方向时才值得，普通一行一列用 Row/Column 语义更清楚。
- **权重与固定尺寸混写还不算总账。** 剩余空间不足时固定项会先挤掉权重项，表现像布局失效。
- **改了 direction 却没改对齐语义。** 主轴变了，`justifyContent` 与 `alignItems` 作用方向随之变化。
- **用声明顺序控制遮挡。** 动态插入或删除节点会改变叠放次序，跨层覆盖要显式设置层级。
- **RelativeContainer 漏写约束。** 没有锚点的子节点回到默认位置，看起来像组件不生效。
- **Grid 放在固定高度的滚动容器里。** 测量冲突会导致只渲染首屏，需要让 Grid 自身可滚动。
- **列表用下标当键。** 数据增删后复用池错位，必须使用业务主键并保持唯一。
- **按设备型号做适配。** 折叠态、平行视界、自由窗口让型号判断不可靠，应按窗口宽度设断点。
- **窗口变化时重算所有派生尺寸。** 把计算结果收敛到断点状态，跨越断点才刷新。
- **嵌套过深追求视觉细节。** 每加一层都增加测量成本，能用一层解决就不要套三层。

## 与其他知识点的关系

**教材衔接：与相邻两门课的接口**

布局决定「有多少节点、节点长什么样」，状态决定「什么时候重建这些节点」。本课的容器选型与重建成本直接相关：一个把状态提到页面级的长列表，会因为布局规模大而把刷新代价放大，所以学完本课应当回头再读状态管理课的刷新粒度一节。

- 向上承接 `harmonyos_arkui_first_page`：本课把单页 Column/Row 扩展到完整容器体系。
- 与 `harmonyos_state_management` 协同：键稳定性与状态归属共同决定长列表表现。
- 与 `harmonyos_multimedia` 衔接：图片墙与视频卡片是布局性能最敏感的场景。
- 与 `harmonyos_distributed` 呼应：跨端流转时窗口尺寸会突变，布局必须按断点响应。
- 平行对照 `cross_platform_flutter`：Flutter 的 Row/Column/Stack 与_constraints_模型可逐条类比。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_arkui_first_page | 首个声明式页面 | 该课的线性容器在本课扩展为容器选型体系 |
| harmonyos_state_management | 状态管理 | 列表键与状态作用域是本科布局表现的前提条件 |
| harmonyos_multimedia | 多媒体与图形渲染 | 图片与视频条目是布局测量成本最高的内容类型 |
| harmonyos_navigation | 路由与页面导航 | 分栏式导航本身依赖断点与主从布局来实现 |
| cross_platform_flutter | Flutter 跨平台 | 两种约束传递模型对照，有助于理解鸿蒙的单向测量 |

## 自测题与参考答案

**教材衔接：题号 1** — 下列关于 Row 与 Flex 差别的说法正确的是？

**参考答案**：Flex 支持换行而 Row 不换行。

本题正确项是「Flex 支持换行而 Row 不换行」。Row 是单行线性容器的特化写法，内容超出主轴时只会挤压或溢出；弹性容器暴露方向与换行开关，能在空间不足时折到下一行。两者共享同一套测量逻辑，方向都不是唯一固定值，也不存在数量级上的性能代差，真正的选择依据是「是否需要换行」以及可读性。

**教材衔接：题号 2** — 子组件上设置 `layoutWeight(1)` 的含义是？

**参考答案**：按比例分配父容器的剩余空间。

本题正确项是「按比例分配父容器的剩余空间」。父容器先给不带权重的兄弟节点分配固定尺寸，再把主轴剩余空间按权重比值分给带权重节点，因此既不是取一半也不是按内容自适应。剩余空间不足时权重项会被压到很小，这正是「加了权重反而被挤没」的成因，与最小宽度概念无关。

**教材衔接：题号 3** — 在 Stack 里让某个子层相对默认位置做小幅偏移，应使用哪个属性？

**参考答案**：用 offset 做相对偏移。

本题正确项是「用 offset 做相对偏移」。它在不改变布局尺寸的前提下做相对位移，适合角标、气泡这类微调场景。对齐属性决定的是整个容器内子节点的对齐基准而不是单个偏移量，层级属性只控制谁盖住谁，裁剪属性负责是否显示越界部分，三者都实现不了「按坐标挪一点」这个需求。

**教材衔接：题号 4** — 承载上千条记录且要求滑动流畅，最合适的方案是？

**参考答案**：用 List 配合懒加载与复用。

本题正确项是「用 List 配合懒加载与复用」。列表容器只维护视口与缓存区内的条目，滑出后进入回收池，配合稳定键与组件复用可把常驻节点数压到常数级。用普通线性容器全量渲染会让首帧耗时随条目数线性增长；把网格列数设成一并不会改变它的测量模型，反而绕远；滚动容器套层叠容器同样没有回收能力，只是把问题藏得更深。

**教材衔接：题号 5** — 父 Row 宽度为 300，中间 Text('B') 的实际宽度是？
@Component
struct Weights {
  build() {
    Row() {
      Text('A').width(60)
      Text('B').layoutWeight(1)
      Text('C').width(40)
    }.width(300)
  }
}

**参考答案**：宽度为 200。

本题正确项是「宽度为 200」。父容器先在主轴上给 A 与 C 分别留出 60 与 40，剩余 300 减 100 等于 200，再由唯一的带权重节点全部获得。选 60 是把固定宽度当成了权重语义，选 300 忽略了兄弟节点已经占用的空间，选 120 则没有任何分配规则能够推出该数值。

## 考点精讲

**教材衔接：高频考点**

1. 容器选型：换行才用 Flex，覆盖用 Stack，相互约束用 RelativeContainer，长内容用 List 或 Grid。
2. `layoutWeight` 的剩余空间分配模型，以及权重与固定尺寸混写时的挤没现象。
3. 长列表三要素：懒加载、稳定唯一键、复用时的状态重置。
4. 断点驱动的响应式布局，反对按设备型号做适配。

**教材衔接：命题规律**

- 选型题给一段视觉描述，正确项通常是「唯一能满足硬需求」的那个容器，干扰项往往也能显示但缺关键能力。
- 计算题喜欢给固定宽度加权重，考剩余空间口径，答案是一个具体数值。
- 排错题常描述「平板上留白过大」或「滑动串位」，指向断点与稳定键而不是组件性能。

**教材衔接：常见考点**

问：下列关于 Row 与 Flex 差别的说法正确的是？
答：Flex 支持换行而 Row 不换行。

问：子组件上设置 `layoutWeight(1)` 的含义是？
答：按比例分配父容器的剩余空间。

问：在 Stack 里让某个子层相对默认位置做小幅偏移，应使用哪个属性？
答：用 offset 做相对偏移。

问：承载上千条记录且要求滑动流畅，最合适的方案是？
答：用 List 配合懒加载与复用。

问：父 Row 宽度为 300，中间 Text('B') 的实际宽度是？
@Component
struct Weights {
  build() {
    Row() {
      Text('A').width(60)
      Text('B').layoutWeight(1)
      Text('C').width(40)
    }.width(300)
  }
}
答：宽度为 200。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 主轴 | 线性容器的排列方向，justifyContent 作用于该方向。 |
| 交叉轴 | 与主轴垂直的方向，alignItems 作用于该方向。 |
| layoutWeight | 按比值瓜分父容器主轴剩余空间的分配属性。 |
| FlexWrap | 控制弹性容器在空间不足时是否折行。 |
| zIndex | Stack 中显式指定子层叠放次序的属性。 |
| alignRules | RelativeContainer 中描述锚点与对齐约束的规则集合。 |
| cachedCount | 列表在视口之外预先保留的条目数量。 |
| 断点系统 | 按窗口宽度切换栅格列数与布局密度的响应式约定。 |

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
- [ArkUI 布局容器开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-layout-development-overview)
- [弹性布局与 Flex 属性说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-layout-development-flex-layout)
- [相对容器 RelativeContainer 用法](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-layout-development-relative-layout)
- [一次开发多端部署与栅格断点](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multiuipatterns)
