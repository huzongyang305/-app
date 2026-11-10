# 状态管理与数据传递

![ArkUI 状态装饰器的数据流向与可观察范围](images/diagram_harmonyos_state_management.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：55 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `状态管理与数据传递`，学习阶段 移动，建议用时 55 分钟。

本课主线：先建立「谁持有数据、谁观察变化、变化后刷新到哪儿」这条判断链，然后把 `@State`、`@Prop`、`@Link`、`@Provide`/`@Consume`、`@Observed`/`@ObjectLink`、`@Watch` 逐个放进这条链里定位；再补上应用级容器 `LocalStorage`、`SessionStorage`、`AppStorage`、`PersistentStorage` 的作用域与生命周期差别；最后专门讲深对象更新的失效场景与两种解法，这是实际项目里最高频的一类疑难。

**学完本课应当能够**

- 给定一段父子组件代码，判断状态归属并选出正确的装饰器组合，说明每种选择的重建范围。
- 解释 `@State` 只能观察第一层的原因，并用 `@Observed` 加 `@ObjectLink` 或值类型替换两种方式修复深层更新不刷新。
- 区分 `LocalStorage`、`SessionStorage`、`AppStorage`、`PersistentStorage` 四类容器的可见范围与落盘行为，为设置项、会话缓存、全局主题各选对载体。

### 复习清单

- [ ] 能不看正文画出父到子的四种传递方向（单向下发、双向同步、跨层共享、全局存取）。
- [ ] 能复述一次「列表项内部字段改了但界面不动」的完整排查步骤。
- [ ] 能完成一次自测，把错题对照易错点表定位是作用域判断还是可观察范围判断出错。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| 组件内状态 | 由 `@State` 持有、只在当前组件可见的可观察数据，赋值即触发重建。 | 易错：普通成员变量改了不会刷新，编译器不报错。 |
| 单向传递 | `@Prop` 从父到子复制一份值，子组件可改但不回流，父组件更新会覆盖。 | 易错：把 @Prop 当双向，改动在父级刷新时丢失。 |
| 双向绑定 | `@Link` 让父子引用同一份状态，任一侧修改另一侧立即可见。 | 易错：用 `$` 语法时父组件传的必须是被装饰的状态。 |
| 跨层共享 | `@Provide` 与 `@Consume` 按键名配对，跳过中间组件直接共享。 | 易错：键名拼错不会报错，表现为数据一直是初始值。 |
| 深层可观察 | `@Observed` 标注类、`@ObjectLink` 在子组件接收实例，使第二层属性变化可见。 | 易错：只用 @ObjectLink 而类没加 @Observed。 |
| 变化副作用 | `@Watch('cb')` 在被观察数据变化时回调，用于联动请求或校验。 | 易错：在回调里再改同一字段造成循环触发。 |
| 应用级容器 | LocalStorage 按 Ability 隔离、AppStorage 全应用共享、SessionStorage 是进程内临时层。 | 易错：把设备相关设置写进 AppStorage 期望自动落盘。 |
| 持久化层 | `PersistentStorage` 把 AppStorage 指定键写盘，重启后自动回填。 | 易错：写入大对象或高频变更项，拖慢退出与启动。 |

## 原理与运行机制

### 机制总览：可观察的本质是拦截赋值

ArkUI 的状态装饰器不是运行时的轮询，而是编译期给声明加上访问拦截：读取时登记依赖，写入时通知框架把该组件标记为待重建。因此「能不能刷新」只取决于两件事——写入是否经过被拦截的入口，以及依赖是否在同一个渲染周期内被登记过。理解了这一点，绝大多数「改了不刷新」的问题都能自己推导出来。

**教材衔接：装饰器职责分工**

| 装饰器 | 数据所有权 | 方向 | 重建范围 | 典型用途 |
| --- | --- | --- | --- | --- |
| @State | 当前组件 | 内部 | 本组件 | 表单输入、开关、计数 |
| @Prop | 父组件持有副本 | 父到子单向 | 子组件 | 只读展示项 |
| @Link | 父子同一份 | 双向 | 父子都可能 | 弹窗编辑、步进器 |
| @Provide/@Consume | 提供方 | 跨层双向 | 订阅方 | 主题、登录态、语言 |
| @Observed/@ObjectLink | 外部实例 | 双向 | 子组件 | 列表项内部字段 |
| @Watch | 依附于上述任一 | 无 | 不改变 | 联动请求、埋点 |

**教材衔接：为什么深层更新会失效**

`@State` 拦截的是「这个变量被换成另一个引用」。当你写 `this.user.name = 'x'`，`user` 的引用没变，框架收不到通知；而 `this.user = { ... }` 或对新数组的赋值会触发。官方给的两条修复路径：其一是把类用 `@Observed` 装饰、在子组件里用 `@ObjectLink` 接收，让第二层属性也进入拦截；其二是保持数据扁平，改完就整体替换引用。前者适合列表项这类天然有层级的场景，后者适合表单与状态机式的更新。

```typescript
@Observed
export class TaskItem {
  id: string = '';
  title: string = '';
  done: boolean = false;

  constructor(id: string, title: string, done: boolean = false) {
    this.id = id;
    this.title = title;
    this.done = done;
  }
}

@Component
struct TaskRow {
  @ObjectLink task: TaskItem;

  build() {
    Row({ space: 10 }) {
      Checkbox()
        .select(this.task.done)
        .onChange((v: boolean) => {
          this.task.done = v;      // 第二层属性变化，@ObjectLink 能感知
        })
      Text(this.task.title)
        .decoration({ type: this.task.done ? TextType.LineThrough : TextType.None })
    }
  }
}
```

**教材衔接：跨层共享与全局状态的边界**

`@Provide`/`@Consume` 解决「中间层不想当搬运工」的问题，但它的可见范围仍是组件子树，一旦越过这棵树就拿不到值。真正的全局状态要交给应用级容器：`LocalStorage` 绑定到某个 Ability 的窗口，页面用它来共享该界面内的数据；`AppStorage` 是全应用内存单例，键值读写用 `@StorageLink`、`@StorageProp` 或 `connect` 均可；`SessionStorage` 挂在窗口上但进程退出即消失，适合放一次性表单草稿。落盘能力只有 `PersistentStorage` 提供，它包装 AppStorage 的部分键，在变化时序列化写文件。

```typescript
PersistentStorage.persistProp('nightMode', false);
PersistentStorage.persistProp('lastTab', 0);

@Entry
@Component
struct SettingsPage {
  @StorageLink('nightMode') night: boolean = false;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('夜间模式').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.night })
          .onChange((isOn: boolean) => {
            this.night = isOn;
          })
      }
      Text(this.night ? '已开启深色' : '当前为浅色')
    }
    .padding(16)
  }
}
```

**教材衔接：@Watch 的正确使用姿势**

`@Watch` 是副作用出口，不是状态同步机制。适合挂在它上面的动作有：把关键词变化转成防抖请求、把选中项变化写进埋点、把表单字段变化触发校验。不适合的动作是修改被观察字段本身——那会形成写入通知写入的闭环，症状是页面卡顿甚至栈溢出。需要防抖时把定时器句柄存在普通成员变量里，别用状态变量承载计时器。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 编辑弹窗回写列表 | 列表项对象、点击某项弹出编辑 | @Link 或 @Observed 加 @ObjectLink，确认后列表即时更新 |
| 全局主题与登录态 | 根组件持有用户与主题对象 | @Provide/@Consume 或 AppStorage，避免层层透传 |
| 设置项重启后保留 | 少量布尔与枚举配置 | PersistentStorage 精确指定键，控制写入频率 |

- 典型现象：子组件里 `@Prop` 改了，父列表不更新。正确做法：需要回流就换 `@Link`，或者由子组件回调让父级改自己的状态。
- 典型现象：从接口拿到数组直接 `push`，界面空着。正确做法：整体替换引用，或对条目类加 `@Observed` 并在条目组件里 `@ObjectLink`。
- 典型现象：应用重启后 AppStorage 全空。正确做法：只有被 `PersistentStorage` 登记过的键才写盘，其余都在内存。

### 最小验证场景

- 准备：一个页面包含父列表与编辑弹窗，数据模型是一个带两层属性的类，列表项内部字段可编辑。
- 观察：先用 `@State` 承载数组并直接改内部字段，记录界面是否变化；再补上 `@Observed` 与 `@ObjectLink`，重复同一次改动。
- 判定：两次对照必须能明确解释「哪一层引用发生了变化」，并能用一句话说出为何第二次会刷新，才算真正掌握可观察范围。

## 代码/协议/SQL 示例

**教材衔接：父子双向绑定的最小完整写法**

`$` 前缀是父组件向 `@Link` 传引用的语法，指向的必须是父侧被装饰的状态变量，传普通常量会编译失败。

```typescript
@Entry
@Component
struct StepperPage {
  @State amount: number = 1;

  build() {
    Column({ space: 16 }) {
      Text(`当前数量 ${this.amount}`).fontSize(18)
      NumberBox({ value: $amount })
      Button('同步加一').onClick(() => {
        this.amount += 1;
      })
    }
    .padding(20)
  }
}

@Component
struct NumberBox {
  @Link value: number;

  build() {
    Row({ space: 12 }) {
      Button('-').onClick(() => {
        if (this.value > 0) {
          this.value -= 1;
        }
      })
      Text(`${this.value}`).fontSize(20).width(48).textAlign(TextAlign.Center)
      Button('+').onClick(() => {
        this.value += 1;
      })
    }
  }
}
```

**教材衔接：用连接对象在逻辑层读写全局状态**

页面之外（服务层、工具类）不能写装饰器，此时通过容器的连接对象读写，再让界面侧用 `@StorageLink` 订阅，形成「逻辑层写、UI 层看」的单向数据流。

```typescript
interface AppState {
  syncing: boolean;
}

export function markSyncing(on: boolean): void {
  AppStorage.setOrCreate('syncing', on);
}

export function readSyncing(): boolean {
  const stored = AppStorage.get<boolean>('syncing');
  return stored === undefined ? false : stored;
}

class SyncService {
  private readonly store: LocalStorage = LocalStorage.getShared();

  start(): void {
    this.store.setOrCreate('syncing', true);
  }
}
```

错误表现：用普通成员变量承载界面要显示的数据，赋值成功但屏幕不动，排查时容易怀疑组件被缓存。

```typescript
@Component
struct Broken {
  count: number = 0;      // 没有可观察能力

  build() {
    Column() {
      Text(`${this.count}`)
      Button('+').onClick(() => { this.count += 1; })
    }
  }
}
```

正确写法：声明为组件内状态，让写入经过拦截入口，重建范围只到本组件。

```typescript
@Component
struct Fixed {
  @State count: number = 0;

  build() {
    Column() {
      Text(`${this.count}`)
      Button('+').onClick(() => { this.count += 1; })
    }
  }
}
```

## 时间/空间复杂度或性能分析

| 维度 | 与什么相关 | 失控表现 | 度量与控制方式 |
| --- | --- | --- | --- |
| 重建成本 | 被标记脏的组件子树规模 | 状态一改整页掉帧 | 状态下放最内层，缩小脏区 |
| 深层观察成本 | @ObjectLink 实例数量 | 长列表内存上升 | 只对需要观察的字段建模 |
| 持久化写入 | 序列化大小与写频率 | 退出变慢、启动回填耗时 | 只登记关键小对象，合并写入 |
| 全局订阅 | 依赖同一键的组件数 | 一改全刷 | 拆分键粒度，避免巨型对象 |
| 副本开销 | @Prop 传递的大对象 | 内存翻倍 | 大数据用引用型装饰器 |

状态管理的性能问题是「刷新粒度」问题。把整页表单塞进一个大对象并用 `@State` 持有，任何一个输入字符都会让整个页面重算，节点数上千时肉眼可见地卡；正确姿势是把每个可独立刷新的块拆成子组件，让状态停在最小作用域。`@Prop` 的复制语义在基本类型上无成本，但传大数组或大对象会立刻产生第二份内存，并且父侧更新会覆盖子侧改动，这类数据应该改用引用型方案。

持久化层同样有隐性成本：`PersistentStorage` 在状态变化时序列化，如果登记了一个高频变化的大列表，退出应用时要等它写完，冷启动时又要反序列化回填。合理边界是「小而关键」——主题、语言、上次浏览页签、少量草稿。会话级临时数据放 `SessionStorage`，跨 Ability 但进程内共享的放 `AppStorage`，真正需要活过重启的才落盘。

状态更新的粒度会把上述指标串成一条因果链。启动阶段，从持久化容器恢复大量状态会阻塞首帧，恢复应分批并且只取首屏需要的键。帧率方面，一次写入引发的重建范围决定构建成本：状态放得越靠近根组件，波及的节点越多，滚动时最容易踩到这条。渲染上，深对象的可观察化通常需要额外代理或整对象替换，代价高于顶层字段变更。包体角度状态层几乎不占体积，真正的负担是随之常驻内存的大集合，需要用有界缓存并显式清理订阅。

## 常见误区与易错点

- **用普通变量存界面数据。** 赋值不会触发任何通知，页面停留在首帧结果，编译期没有警告。
- **以为 `@Prop` 会回写父组件。** 它是值复制，子侧修改只在子侧重建，父级下次下发时直接覆盖。
- **`@Link` 传普通常量。** 语法上要求 `$` 引用父侧状态变量，传字面量在编译期就被拒绝。
- **`@Provide`/`@Consume` 键名拼错。** 不匹配时表现为取不到数据而不是报错，排查成本高。
- **只加 `@ObjectLink` 不给类加 `@Observed`。** 实例属性依然没有拦截，深层改动照样不刷新。
- **`@Watch` 回调里改同一个字段。** 写入触发通知再触发写入，形成循环，最坏情况直接卡死。
- **把巨型对象放进 AppStorage。** 所有订阅者都随一次改动重建，等于放弃粒度控制。
- **指望 AppStorage 自动落盘。** 内存容器重启即失，必须显式用持久化层登记具体键。
- **用数组下标当 ForEach 键。** 与状态复用叠加时会出现条目内容错位，必须用业务主键。
- **在逻辑层写装饰器。** 服务类里不能声明状态，应通过容器连接对象读写，由 UI 层订阅。

## 与其他知识点的关系

**教材衔接：与相邻课程的依赖方向**

状态装饰器的语法合法性来自语言层，容器选型来自页面结构，刷新代价来自布局规模。本课处在三者交汇处：往下要求语言规则清晰，往上要求容器节点数可控，横向要求路由与生命周期时机正确，很多「不刷新」问题最终其实是生命周期或路由层级问题。

- 向上承接 `harmonyos_arkts_basics`：`@State` 只能标注组件成员，属于语言层位置约束。
- 与 `harmonyos_layout_system` 协同：脏区大小由组件树结构决定，长列表必须有稳定键。
- 向下游支撑 `harmonyos_navigation`：页面返回时的数据同步依赖生命周期与状态作用域。
- 与 `harmonyos_network_data` 交界：请求结果落到哪一层状态，决定页面是否需要重新拉取。
- 平行对照 `cross_platform_flutter`：Provider 与 Riverpod 的依赖注入思路可与装饰器体系互为参照。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_arkui_first_page | 首个声明式页面 | 该课的组件粒度决定了本课的刷新粒度 |
| harmonyos_layout_system | 布局系统 | 列表键与复用策略是状态正确显示的前提 |
| harmonyos_navigation | 路由与页面导航 | 页面栈返回时的状态恢复依赖本课的作用域设计 |
| harmonyos_network_data | 网络、数据与文件 | 远端数据入库后如何映射成可观察模型 |
| harmonyos_distributed | 分布式软总线 | 跨端迁移要求状态可序列化，装饰器对象需转换 |

## 自测题与参考答案

**教材衔接：题号 1** — 子组件修改后要立刻回写到父组件，应当选择的传递方式是？

**参考答案**：@Link 与父组件双向同步。

本题正确项是「@Link 与父组件双向同步」。它让父子引用同一份状态，任一侧写入都会让另一侧重建，正是编辑弹窗这类场景需要的语义。单向副本在父级下次下发时会覆盖子侧改动；组件内部状态各自持有，两边看到的是不同数据；变化回调只是副作用出口，本身不建立数据通道，也不能替代传递方式。

**教材衔接：题号 2** — 关于 `@Provide` 与 `@Consume` 的作用范围，下列说法正确的是？

**参考答案**：按同名键跨层级传递数据。

本题正确项是「按同名键跨层级传递数据」。这对装饰器以键名配对，祖先声明提供方后，子孙在自己的子树里声明消费即可直接读写，中间层不必逐层透传。它并不需要根页面显式传参，也不碰任何磁盘存储；一旦跳出提供方所在的组件子树，配对关系就不复存在，跨页面共享要改用应用级状态容器。

**教材衔接：题号 3** — 列表项内部字段被修改后希望该行刷新，子组件应如何接收数据？

**参考答案**：用 @ObjectLink 接收该实例。

本题正确项是「用 @ObjectLink 接收该实例」。配合类上的可观察装饰器，它把实例属性也纳入拦截范围，因此第二层字段变化能定位到具体条目重建。单向副本只拿到值且不会观察深层属性；整个数组放在组件内部状态上会让所有条目一起重建；绑定一个字符串字段与列表项对象无关，三者都解决不了深层不刷新。

**教材衔接：题号 4** — `PersistentStorage` 在这套容器体系里承担的职责是？

**参考答案**：把指定键的状态写入磁盘。

本题正确项是「把指定键的状态写入磁盘」。它包装全局容器中被显式登记过的键，在变化时序列化落盘、启动时回填，因此只应放小而关键的配置。未被登记的键依旧只存在于内存，重启后回到默认值；它不承担跨应用共享，也不负责网络缓存或数据库日志，那些分别属于各自的能力域。

**教材衔接：题号 5** — 首次渲染显示什么？点击一次按钮后 Text 的内容是？
@Component
struct Counter {
  @State count: number = 3;
  build() {
    Column() {
      Text(`count=${this.count}`).fontSize(20)
      Button('+').onClick(() => { this.count++; })
    }
  }
}

**参考答案**：先显示 count=3，点击后变 4。

本题正确项是「先显示 count=3，点击后变 4」。可观察状态的写入会触发所属组件重建，重建时重新求值模板字符串，于是数字随之更新，初值来自声明处的 3。若把变量声明成普通成员而没有装饰器，才会出现点击后画面不动的现象；ArkTS 完整支持模板字符串与反引号插值，不会因为写法报编译错误。

## 考点精讲

**教材衔接：高频考点**

1. 四种传递方向的选型：单向下发用 `@Prop`、双向同步用 `@Link`、跨层用 `@Provide`/`@Consume`、全局用容器。
2. 可观察范围与深层更新失效的两种修复路径。
3. 四类容器的作用域与生命周期，特别是只有持久化层会落盘。
4. `@Watch` 作为副作用出口的边界，禁止回写被观察字段。

**教材衔接：命题规律**

- 场景题给一句「改了不刷新」，正确项几乎都是补齐观察链而不是重写组件。
- 作用域题会问「重启后还在不在」，考内存容器与磁盘层的分界。
- 代码题给最小计数器或列表项，问初值与点击后的显示，答案落在重建机制。

**教材衔接：常见考点**

问：子组件修改后要立刻回写到父组件，应当选择的传递方式是？
答：@Link 与父组件双向同步。

问：关于 `@Provide` 与 `@Consume` 的作用范围，下列说法正确的是？
答：按同名键跨层级传递数据。

问：列表项内部字段被修改后希望该行刷新，子组件应如何接收数据？
答：用 @ObjectLink 接收该实例。

问：`PersistentStorage` 在这套容器体系里承担的职责是？
答：把指定键的状态写入磁盘。

问：首次渲染显示什么？点击一次按钮后 Text 的内容是？
@Component
struct Counter {
  @State count: number = 3;
  build() {
    Column() {
      Text(`count=${this.count}`).fontSize(20)
      Button('+').onClick(() => { this.count++; })
    }
  }
}
答：先显示 count=3，点击后变 4。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| @State | 组件内部可观察状态，赋值即触发本组件重建。 |
| @Prop | 父到子的单向值副本，子侧修改不回流。 |
| @Link | 父子共享同一份状态的双向绑定引用。 |
| @Provide/@Consume | 按键名配对、跳过中间层的跨层共享机制。 |
| @Observed | 标注类，使实例的第二层属性变化可被观察。 |
| @ObjectLink | 子组件接收可观察实例，用于深层更新场景。 |
| @Watch | 状态变化时的副作用回调，不可回写同一字段。 |
| PersistentStorage | 把 AppStorage 指定键序列化落盘并在启动回填。 |

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
- [ArkUI 状态管理概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-state-management)
- [自定义组件间数据传递](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-user-defined-observe-data-send)
- [应用状态存储 LocalStorage 与 AppStorage](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-appstorage)
- [PersistentStorage 持久化指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-persistencestorage)
