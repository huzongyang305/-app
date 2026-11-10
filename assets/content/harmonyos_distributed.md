# 分布式软总线与跨端流转

![HarmonyOS 分布式软总线、设备发现信任、跨端迁移、分布式数据对象与服务卡片的协同关系](images/diagram_harmonyos_distributed.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：60 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `分布式软总线与跨端流转`，学习阶段 移动，建议用时 60 分钟。

本课主线：先讲清楚「多设备为什么能被当成一台」——软总线在物理链路之上虚拟出一条统一总线，设备管理与信任关系决定谁能进来；再讲跨端流转的两条路径，应用级迁移靠 `onContinue` 与状态握手，数据级协同靠分布式数据对象与分布式文件；最后落到服务卡片这一最日常的跨端入口，因为它是唯一不需要用户打开应用就能触达的场景，也是分布式能力最容易做出体感的落点。

**学完本课应当能够**

- 描述软总线的三层职责（发现、组网、传输），并说明 `distributedDeviceManager` 与 `@ohos.bundle.bundleManager` 在设备清单上的分工。
- 区分应用级迁移与数据级协同，写出 `onContinue` 侧必须完成的序列化清单与目标侧的恢复时机。
- 为一份协作数据选对载体：小结构用 `distributedDataObject`，大文件用分布式文件，高频单值用状态同步，并说明各自的容量与延迟代价。
- 说明服务卡片的生命周期、进程归属与刷新机制，解释为什么卡片内不能直接写应用状态。

### 复习清单

- [ ] 能不看正文画出一次跨端迁移从发现设备、握手、状态序列化到目标端恢复的完整时序，并标出三个可能失败的环节。
- [ ] 能说出三种跨端数据载体在容量、延迟、冲突处理与离线能力上的差异，并各配一个适用场景。
- [ ] 能完成一次自测，把错题对照易错点表定位是设备信任关系还是状态序列化理解错了。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| 分布式软总线 | 在异构近场设备间虚拟出统一通信总线的底层能力，屏蔽 Wi-Fi、蓝牙与有线差异。 | 易错：把它当成公网远程通道，超出近场范围就完全不可用。 |
| 可信设备 | 经过用户确认或同账号同认证后建立信任关系的设备，是组网的前提。 | 易错：假设列表里出现即等于可连接，未做握手直接发送必然失败。 |
| distributedDeviceManager | 设备管理入口，提供设备列表、名称、网络 ID 与上下线订阅。 | 易错：只在启动时取一次列表，设备离线后仍向旧 ID 发送。 |
| 应用级迁移 | 把运行中的 UIAbility 状态搬到另一台设备继续执行的能力。 | 易错：把不可序列化的对象塞进迁移参数，对端恢复时才崩。 |
| onContinue | 迁移发起时的回调，业务在此把自定义状态写入待携带的参数对象。 | 易错：返回成功却什么都没写，对端只能从零冷启动。 |
| distributedDataObject | 跨设备同步的共享对象，字段级变更自动广播给同 ID 的对端对象。 | 易错：成员含函数或循环引用，或把大二进制塞进去当文件用。 |
| Service Ability | 不以界面为中心、面向后台服务与跨端调用的能力形态。 | 易错：把它当作可以常驻的后台进程，同样受冻结策略约束。 |
| 服务卡片 | 由提供方渲染、由桌面等宿主托管展示的轻量 UI 单元，可周期或事件刷新。 | 易错：在卡片里访问应用进程内状态，或期望它响应复杂手势。 |

## 原理与运行机制

### 机制总览：从「附近有哪些设备」到「同一件事换个地方继续」

分布式不是网络编程的翻版。它的难点在于把设备抽象成可信节点、把状态抽象成可搬运快照、把 UI 抽象成可换宿主渲染三件事同时成立。任何一件不成立，用户体验都会退化成「手动传文件」。

**教材衔接：软总线的三层职责**

发现层负责感知附近设备并产出候选列表；组网层负责身份认证、密钥协商与逻辑链路建立；传输层负责按数据特征选路，小报文走低延迟通道，大块数据走高带宽通道，并在链路抖动时无感切换。应用层看到的只是一句发送调用，路径选择与重传都在总线内部完成。

| 层次 | 输入 | 输出 | 应用可见的失败 |
| --- | --- | --- | --- |
| 发现 | 附近广播 | 候选设备列表 | 列表为空，多为开关或权限未满足 |
| 组网 | 候选设备加信任凭据 | 可用逻辑链路 | 握手超时或对端拒绝，需引导确认 |
| 传输 | 逻辑链路加负载 | 送达或对端回调 | 大负载被限流，表现为延迟升高 |

**教材衔接：设备管理的正确用法**

`createDeviceManager` 之后要订阅上下线事件，而不是每次发送前重新拉列表。设备标识要用网络级 ID 而不是显示名称，名称可重复且用户可改。跨端调用前必须先确认对方仍在列表中且信任状态有效，否则请求会石沉大海。资源释放同样重要，管理器对象持有系统通道，忘记 `release` 会累积占用。

```typescript
import { distributedDeviceManager } from '@kit.DistributedServiceKit';

const dm = distributedDeviceManager.createDeviceManager('com.example.app');
const devices = dm.getAvailableDeviceListSync();

function onOnline(callback: (info: distributedDeviceManager.DeviceBasicInfo) => void): void {
  dm.on('deviceStateChange', (data) => {
    if (data.action === distributedDeviceManager.DeviceAction.ONLINE) {
      data.detail?.forEach(callback);
    }
  });
}
```

**教材衔接：应用级迁移的握手协议**

迁移是一次两端协商。源端先询问「能不能来」，目标端根据版本、屏幕与登录态决定接受与否；接受后源端进入 `onContinue`，业务在此把无法自动携带的状态写进参数对象；系统把能力实例与参数投递到目标端，目标端在 `onCreate` 与 `onWindowStageRestore` 中读取参数并重建界面。整个链条里业务只需要负责两件事：把状态写成可序列化的键值，以及在恢复时按同样的键读回来。

```typescript
import { abilityContinuation, common, wantAgent } from '@kit.AbilityKit';

class ReaderAbility extends UIAbility {
  onContinue(wantParam: Record<string, Object>): abilityContinuation.OnContinueResult {
    wantParam.bookId = this.state.bookId;
    wantParam.chapterIndex = this.state.chapterIndex;
    wantParam.offset = this.state.offset;
    return abilityContinuation.OnContinueResult.SUCCESS;
  }

  onNewWant(want: Want): void {
    this.restore(want.parameters as Record<string, Object>);
  }
}
```

**教材衔接：三种跨端数据载体的取舍**

| 载体 | 适合内容 | 典型规模 | 一致性 | 离线可用 |
| --- | --- | --- | --- | --- |
| 分布式数据对象 | 结构化小字段集合 | 单字段千字节内 | 字段级最终一致，可加会话ID做冲突仲裁 | 需组网 |
| 分布式文件 | 图片、文档、录音 | 兆级到百兆级 | 按版本合并或整份覆盖 | 本地副本先写后同步 |
| 跨端 RPC 调用 | 一次性请求应答 | 报文级 | 强一致同步语义 | 需组网 |

数据对象的关键约束是「可序列化」：成员只能是基础类型与普通对象，不能带函数、不能循环引用，嵌套层级与整体体积都有上限，超过就丢同步。冲突处理要显式写入会话标识，让业务自己判断谁覆盖谁，而不是指望底层给出不存在的仲裁。

**教材衔接：服务卡片是独立进程的小型 UI**

卡片由提供方应用描述、由框架在宿主进程中实例化并展示，它运行在一个受限的 UI 环境里：只能用被允许的组件子集，不能访问原应用内存，不能执行任意脚本，交互只能通过 `postCardAction` 之类的事件回传给提供方。刷新有两条路：提供方主动 `updateForm` 推送新数据，或按配置的时间与条件由系统触发；两者都会走一遍卡片的 ArkTS 渲染。想让用户点卡片直达应用内的某个页面，正确做法是在动作里带上路由参数，由被拉起的能力再跳转。

```json
{
  "name": "EntryFormAbility",
  "srcEntry": "./ets/entryformability/EntryFormAbility.ts",
  "type": "form",
  "metadata": [{ "name": "ohos.extension.form", "resource": "$profile:form_config" }]
}
```

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 手机看一半平板接着看 | 同账号双设备在线，播放进度可序列化 | 一键迁移后在平板续播，位置误差不超过一个片段 |
| 手机拍照平板立刻可选 | 图片先落本地沙箱再进分布式目录 | 平板侧列出并读取同一文件，无需手动传输 |
| 桌面卡片显示今日待办 | 用户已添加卡片，数据可本地计算 | 卡片按周期刷新，点击直达对应详情页 |

- 典型现象：设备列表里有对方但请求无响应。正确做法：先完成信任确认与握手，再发送，并把失败分类为「未组网」与「对端拒绝」分别提示。
- 典型现象：迁移后应用回到首页而不是原位置。正确做法：检查 `onContinue` 是否真的写了状态、目标端是否在正确的生命周期里读取。
- 典型现象：卡片长时间不更新。正确做法：区分周期刷新与事件刷新，数据变化时由提供方主动推送，别把实时性寄托在最小刷新间隔上。

### 最小验证场景

- 准备：两台同版本设备登录同一账号，应用提供「写入随机数并广播」「触发迁移」「添加卡片」三个入口。
- 观察：设备发现是否及时刷新、对端字段变更是否在可感知延迟内到达、迁移后目标端读取到的状态是否与源端一致、卡片刷新是否与数据变更对应。
- 判定：四项全部成立说明发现、同步、迁移、卡片四条链路各自通畅；任一失败都要能明确指认是链路问题还是业务序列化问题。

## 代码/协议/SQL 示例

**教材衔接：分布式数据对象的定义与监听**

创建时给一个跨端一致的标识，之后所有设备用同一标识获取本地代理对象。写入要整对象提交，监听回调里区分来源设备以避免自激循环。

```typescript
import { distributedDataObject } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

class TaskState {
  public title: string = '';
  public done: boolean = false;
  public revision: number = 0;
}

function openShared(ctx: common.BaseContext, sessionId: string) {
  const obj = distributedDataObject.create(ctx, new TaskState(), sessionId);
  obj.on('change', (id: string) => {
    console.info(`state changed by ${id} rev=${obj.revision}`);
  });
  obj.title = '复习软总线';
  obj.revision += 1;
  return obj;
}
```

**教材衔接：迁移时的状态清单纪律**

把要携带的字段集中成一个结构体，比散落赋值可靠得多：新增字段时只需改一处，目标端也能按同一份清单校验缺字段。

```typescript
type CarryState = { bookId: string; chapterIndex: number; offset: number };

function pack(state: CarryState): Record<string, Object> {
  const params: Record<string, Object> = {};
  params.bookId = state.bookId;
  params.chapterIndex = state.chapterIndex;
  params.offset = state.offset;
  return params;
}
```

错误表现：把带方法与循环引用的对象直接交给迁移参数，源端看不出问题，目标端恢复阶段反序列化失败。

```typescript
onContinue(wantParam: Record<string, Object>): abilityContinuation.OnContinueResult {
  wantParam.viewModel = this.viewModel;   // 含函数与父级引用
  return abilityContinuation.OnContinueResult.SUCCESS;
}
```

正确写法：只携带纯数据快照，恢复后在目标端重建行为对象。

```typescript
onContinue(wantParam: Record<string, Object>): abilityContinuation.OnContinueResult {
  wantParam.snapshot = pack(this.viewModel.toState());
  return abilityContinuation.OnContinueResult.SUCCESS;
}
```

## 时间/空间复杂度或性能分析

| 指标 | 成本来源 | 参考量级 | 优化方向 |
| --- | --- | --- | --- |
| 设备发现 | 广播窗口与认证往返 | 秒级 | 订阅状态变化，避免轮询拉列表 |
| 组网握手 | 用户确认加密钥协商 | 数秒，含人工等待 | 失败分类提示，不要静默重试 |
| 数据对象同步 | 序列化加链路往返 | 数十到数百毫秒 | 减小对象体积，合并高频写入 |
| 应用迁移 | 状态打包加目标冷启动 | 一到三秒 | 精简携带清单，恢复期先渲染骨架 |
| 卡片刷新 | 提供方推送加宿主重绘 | 与刷新周期相关 | 只在数据真变化时推送 |

跨端链路的延迟由人工确认主导，不是网络。工程上必须把「需要用户在对方设备上点同意」这一步显式建模：发起后立即给出等待态，超时后给出可操作的解释，而不是把接口失败笼统提示为网络异常。设备列表的刷新成本很低但很容易忘，未订阅状态变化的实现在设备息屏后仍能拿到旧列表，于是所有请求都发向一个不存在的节点。

数据对象同步的复杂度接近于「改动字段数乘对象大小」。字段级最终一致意味着高频写入会被合并或延迟送达，因此把每次输入都写进共享对象是典型误用，应当加防抖并在会话结束或页面隐藏时提交一次。体积上界不是软限制，超限的表现为静默不同步而不是抛错，这会让问题在联调阶段极难定位。

迁移的性能瓶颈通常在目标端而不是传输端。源端只需要打包一份轻量快照，但目标端要重建能力实例、恢复窗口、再拉取必要数据。把「先恢复界面骨架、后补齐内容」写成固定流程，可以把用户感知的等待压到一次骨架渲染的时间。服务卡片则相反，它的成本在宿主侧的周期性重绘，卡片内不要做数据计算，提供方算好再推，把 ArkTS 卡片的渲染留给纯展示。内存上，跨端对象的本地副本会常驻，多设备多房间场景要显式销毁不再使用的对象，否则副本数量按会话线性增长。

## 常见误区与易错点

- **把软总线当公网通道。** 它服务近场组网，跨城场景必须回到服务端转发。
- **列表里出现就直接发送。** 未建立信任链路时请求没有回执，表现像丢包其实是没组网。
- **用显示名称做设备标识。** 名称可重复可修改，必须用网络级标识。
- **忘记 release 设备管理器。** 系统通道被长期占用，多实例后表现为发现变慢。
- **onContinue 里什么都没写。** 系统只搬能力实例，业务状态不写就等于对端冷启动。
- **把行为对象整体塞进迁移参数。** 含函数或循环引用会在目标端反序列化失败。
- **以为数据对象能同步大文件。** 它有体积上限且超限静默失败，文件要走分布式文件。
- **每个输入事件都写一次共享对象。** 高频小写会被合并或延迟，必须防抖后提交。
- **以为卡片能读应用进程状态。** 卡片由宿主独立渲染，只能通过事件与提供方通信。
- **把周期刷新当实时推送。** 最小刷新间隔由系统控制，实时性靠提供方主动更新；两端版本不一致时还要能协商降级，否则恢复阶段字段缺失直接崩溃。

## 与其他知识点的关系

**教材衔接：分布式是把「一个应用」放大成「一组设备上的同一个会话」**

前面所有课建立的假设——状态在一处、界面在一处、生命周期在一处——在这里同时被打破。迁移要求状态可序列化，同步要求数据结构化，卡片要求 UI 能脱离应用进程渲染。因此本课最好的学习方式是拿一个已有的单端页面逐条改造成跨端版本，而不是孤立记接口。

- 向上承接 `harmonyos_state_management`：能不能迁移，取决于状态是否收敛成可序列化快照。
- 与 `harmonyos_navigation` 协同：卡片与迁移拉起的是路由入口，路由参数是恢复位置的通道。
- 与 `harmonyos_network_data` 交界：分布式文件与本地沙箱目录的划分决定同步范围。
- 与 `harmonyos_system_capabilities` 呼应：设备发现与组网受权限与后台约束直接限制。
- 与 `harmonyos_multimedia` 呼应：投屏与续播要求把播放进度与会话一并搬运。
- 与 `cross_platform_flutter` 对照：跨端在 Flutter 里靠自研通道拼装，鸿蒙把它下沉为系统能力。
- 与 `android_development_*` 对照：Android 的跨设备协同依赖应用层协议，鸿蒙提供统一总线与信任模型。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_state_management | 状态管理与数据传递 | 可序列化状态是应用级迁移成立的前提 |
| harmonyos_navigation | 路由与页面导航 | 迁移与卡片拉起都通过路由参数回到原位置 |
| harmonyos_network_data | 网络、数据与文件 | 分布式文件与沙箱目录共同界定同步范围 |
| harmonyos_system_capabilities | 系统能力与权限 | 组网与后台执行受同一套权限与冻结策略约束 |
| cross_platform_flutter | Flutter 跨平台开发 | 跨端协同在通用框架里需自建通道而鸿蒙内置 |
| harmonyos_release_optimization | 性能调优与上架 AppGallery | 跨端体验指标与兼容性声明都纳入上架检查 |

## 自测题与参考答案

**教材衔接：题号 1** — 分布式软总线在 HarmonyOS 体系中的角色是？

**参考答案**：把异构设备虚拟成同一总线的近场通信底座。

本题正确项是「把异构设备虚拟成同一总线的近场通信底座」。它在物理链路之上统一了发现、组网与传输，应用只面对逻辑设备与逻辑通道，不必关心走的是哪种无线制式。数据库、打包工具与构建插件分别属于存储、制品与编译阶段，跟这层通信底座没有关系，把它们混进来是课程内不同层次概念的常见串台。

**教材衔接：题号 2** — 应用间跨设备迁移页面时，`onContinue` 回调的职责是？

**参考答案**：把不能自动携带的状态序列化进 wantParam。

本题正确项是「把不能自动携带的状态序列化进 wantParam」。框架负责搬运能力实例与窗口信息，业务自定义的进度、选中项、草稿等内容必须在这个回调里显式写入参数对象，目标端才能按同样的键恢复。它不负责在远端重建进程，也不是释放资源的信号，更不是系统全自动完成内存快照；返回成功却没写任何状态，恰恰是迁移后回到首页这类问题的直接来源。

**教材衔接：题号 3** — 关于分布式数据对象，下列说法正确的是？

**参考答案**：它要求成员可序列化并限制嵌套深度。

本题正确项是「它要求成员可序列化并限制嵌套深度」。共享对象在设备间以快照形式同步，函数、循环引用与超大二进制都无法成为合法成员，整体体积也有上限。它并非与普通赋值毫无差别，静默丢弃超限字段就是最常见的失败形态；大文件应由分布式文件承担，视频段落更不该塞进对象；普通三方应用同样可以使用该能力，把它说成系统专属不成立。

**教材衔接：题号 4** — 关于服务卡片的运行模型，下列说法正确的是？

**参考答案**：卡片由提供方渲染并由框架托管周期刷新。

本题正确项是「卡片由提供方渲染并由框架托管周期刷新」。提供方定义内容并推送数据变化，宿主负责展示与刷新调度，两者通过事件与参数通信。卡片不与宿主共享进程内状态，运行环境只开放受限组件与动作集合，不能执行任意脚本，也不能自由访问网络；内容更新恰恰是它的基本能力，「发布后无法更新」与实际机制完全相反。

**教材衔接：题号 5** — 这段迁移代码要解决的问题是？
onContinue(wantParam: Record<string, Object>): abilityContinuation.OnContinueResult {
  wantParam.progress = this.playback.progress;
  this.session.save(wantParam);
  return abilityContinuation.OnContinueResult.SUCCESS;
}

**参考答案**：把播放进度写进迁移参数供对端恢复。

本题正确项是「把播放进度写进迁移参数供对端恢复」。回调在迁移发起时被调用，业务在此把无法自动搬运的自定义状态写入参数对象，返回成功表示同意迁移。参数会随能力实例投递到目标设备，因此既不等于源端立即释放，也不会让对端从头播放；代码里没有任何拒绝语义，也与登录流程无关。

## 考点精讲

**教材衔接：高频考点**

1. 软总线三层职责与每层可观察到的失败形态。
2. 应用级迁移中源端与目标端各自的必做动作，尤其是状态清单。
3. 三种跨端数据载体的选型判据：体积、一致性、离线能力。
4. 服务卡片的进程归属、组件受限集合与两条刷新路径。

**教材衔接：命题规律**

- 概念定位题爱把不同层次的能力并列成选项，考你能否区分通信底座、存储载体与构建工具。
- 迁移题围绕「谁写状态、谁读状态」设陷阱，凡是声称系统全自动搬运业务状态的表述都不成立。
- 代码题给一段迁移回调，考它解决的问题而不是返回值枚举的拼写细节。

**教材衔接：常见考点**

问：分布式软总线在 HarmonyOS 体系中的角色是？
答：把异构设备虚拟成同一总线的近场通信底座。

问：应用间跨设备迁移页面时，`onContinue` 回调的职责是？
答：把不能自动携带的状态序列化进 wantParam。

问：关于分布式数据对象，下列说法正确的是？
答：它要求成员可序列化并限制嵌套深度。

问：关于服务卡片的运行模型，下列说法正确的是？
答：卡片由提供方渲染并由框架托管周期刷新。

问：这段迁移代码要解决的问题是？
onContinue(wantParam: Record<string, Object>): abilityContinuation.OnContinueResult {
  wantParam.progress = this.playback.progress;
  this.session.save(wantParam);
  return abilityContinuation.OnContinueResult.SUCCESS;
}
答：把播放进度写进迁移参数供对端恢复。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 分布式软总线 | 近场多设备的统一通信底座，屏蔽物理链路差异。 |
| 可信设备 | 完成身份确认后建立信任关系的设备，组网的前置条件。 |
| distributedDeviceManager | 设备管理入口，提供列表、标识与上下线订阅。 |
| onContinue | 迁移发起回调，业务在此写入需要携带的自定义状态。 |
| distributedDataObject | 字段级跨端同步的共享对象，成员必须可序列化。 |
| Service Ability | 面向后台服务与跨端调用的非界面能力形态。 |
| postCardAction | 卡片向提供方回传用户动作的标准事件通道。 |
| updateForm | 提供方主动推送卡片新数据、实现即时更新的接口。 |

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
- [分布式能力总览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/soft-bus-overview)
- [应用接续开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/in-app-continuation-overview)
- [分布式数据对象 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-distributed-dataobject)
- [服务卡片开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/form-overview)
