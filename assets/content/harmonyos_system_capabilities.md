# 系统能力与权限

![HarmonyOS 系统能力调用链路：清单声明、运行时授权、能力接口与后台约束四道关卡](images/diagram_harmonyos_system_capabilities.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `系统能力与权限`，学习阶段 移动，建议用时 50 分钟。

本课主线：把「应用要用设备能力」这件事拆成四道必须依次通过的关卡——清单声明、授权方式、能力接口、运行约束。前三关决定代码能不能跑通，第四关决定用户把应用切到后台之后还能不能跑通。在此基础上分别展开位置、传感器、通知、剪贴板、蓝牙五类高频能力，最后交代元服务这一种受限运行形态，因为它会把前三关的规则整体收紧一档。

**学完本课应当能够**

- 说出 `system_grant`、`user_grant`、`manual_settings` 三档授权方式的差别，并判断一个具体权限落在哪一档、需要哪些配套动作。
- 写出一段完整的运行时授权流程：先 `requestPermissionsFromUser`，再按 `authResults` 分支处理拒绝、永久拒绝与设置页引导。
- 为「连续回调型」能力（位置、传感器、蓝牙扫描）设计成对的注册与注销，并解释遗漏注销为什么在页面上看不出来却会持续耗电。
- 区分短时任务、延迟任务、周期任务与长时任务的适用边界，说明长时任务为什么必须绑定业务场景。

### 复习清单

- [ ] 能不看正文画出一次敏感权限调用从清单声明到用户授权的完整流程，并标出每一步失败时的表现。
- [ ] 能说出五类高频能力各自需要的权限名、是否属于 `user_grant`、以及离开页面时必须做的清理动作。
- [ ] 能完成一次自测，把错题对照易错点表定位是授权档位判断错了还是后台约束记错了。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| requestPermissions | `module.json5` 中声明应用需要使用哪些系统权限的清单节点。 | 易错：只在代码里调用申请接口而漏了清单声明，运行时直接抛权限错误。 |
| system_grant | 安装即授予的系统权限，用户无法逐项拒绝。 | 易错：以为这类权限也要弹窗，白白加了一次无意义的请求调用。 |
| user_grant | 必须运行时弹窗由用户明确授予的敏感权限，可事后撤回。 | 易错：连续被拒后系统不再弹框，代码若不分支就永远拿不到数据。 |
| authResults | `requestPermissionsFromUser` 返回的逐项授权结果数组，与请求顺序一一对应。 | 易错：只判断数组长度而不按下标比较 `GrantStatus`，把拒绝当成就绪。 |
| geoLocationManager | 定位能力入口，提供单次定位、连续订阅与开关状态查询。 | 易错：没有先确认系统定位总开关就发起请求，回调永远不来。 |
| notificationManager | 通知发布与管理入口，负责渠道、授权与发布撤销。 | 易错：不做 `isNotificationEnabled` 检查，通知被系统静默丢弃而无异常。 |
| 长时任务 | 让应用在后台持续执行特定场景任务的机制，需声明匹配模式与权限。 | 易错：申请的运行模式与实际业务不符，审核与运行时都会被回收。 |
| 元服务 | 免安装、以卡片与搜索为主要入口的轻量应用形态，能力集合受限。 | 易错：把应用级权限假设直接搬进元服务，功能在真机上整块不可用。 |

## 原理与运行机制

### 机制总览：一次能力调用的四道关卡

第一关是清单声明。所有权限必须在 `module.json5` 的 `requestPermissions` 里列出，可同时声明 `reason` 与 `usedScene`，前者用于应用市场审核与弹窗文案，后者说明在哪些模块、什么阶段使用。清单缺失时，无论代码怎么写都会拿到权限校验失败。

第二关是授权方式。鸿蒙按风险等级把权限分成三档，处理方式完全不同：

**教材衔接：三档授权方式对照**

| 授权方式 | 授予时机 | 用户可否拒绝 | 典型权限 | 代码里要做什么 |
| --- | --- | --- | --- | --- |
| system_grant | 安装时自动授予 | 不可逐项拒绝 | 网络访问、振动 | 只声明，不申请 |
| user_grant | 运行时弹窗 | 可拒绝可撤回 | 位置、相机、麦克风 | 声明加运行时申请 |
| manual_settings | 安装时不授予 | 需用户去设置里手动打开 | 读取剪贴板后台访问 | 检测状态并引导跳转设置页 |

**教材衔接：运行时授权的标准流程**

`abilityAccessCtrl.createAtManager()` 得到管理器，先用 `checkAccessToken` 判断当前状态，未授予时再调 `requestPermissionsFromUser`。返回值里有两个关键数组：`authResults` 是逐项结果，`dialogShownResults` 标明本次是否真的弹了框。工程上必须区分三种失败：用户点了拒绝、用户之前已拒绝导致这次没弹框、系统策略直接禁止。只有第一种可以立即重试，第二种必须引导用户去设置页。

```typescript
import { abilityAccessCtrl, common, Permissions, Want } from '@kit.AbilityKit';

async function ensureLocation(ctx: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const perms: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION'];
  const result = await atManager.requestPermissionsFromUser(ctx, perms);
  if (result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
    return true;
  }
  const settings: Want = {
    bundleName: 'com.huawei.hmos.settings',
    abilityName: 'com.huawei.hmos.settings.MainAbility',
    uri: 'application_info_entry'
  };
  await ctx.startAbility(settings);
  return false;
}
```

**教材衔接：位置与传感器——连续回调必须成对取消**

定位与传感器都是订阅式能力：`on` 注册回调，`off` 注销。它们在页面上没有任何可见痕迹，忘记注销的后果不是崩溃而是持续耗电与回调堆积。正确写法是把注册放在页面可见之后、注销放在页面不可见或销毁时，并把回调函数保存为成员，因为匿名函数无法作为参数传给 `off` 精确匹配。

```typescript
import { geoLocationManager } from '@kit.LocationKit';

function startTracking(): void {
  const request: geoLocationManager.RequestConfig = {
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    scenario: geoLocationManager.LocationRequestScenario.UNSET,
    timeInterval: 2,
    distanceInterval: 0
  };
  geoLocationManager.on('locationChange', request, onLocationChanged);
}

function stopTracking(): void {
  geoLocationManager.off('locationChange', onLocationChanged);
}
```

**教材衔接：通知的三级结构**

通知不是「发一条文本」这么简单。它的结构是渠道、请求、发布三层：先用 `addSlot` 建立通知渠道并确定重要级，渠道一旦建立其属性由用户在设置里掌控；再组装 `NotificationRequest`，包含 `id`、`content`、`slotType`、`wantAgent`；最后 `publish`。同 `id` 再发布会覆盖旧通知，这正是做进度通知的手段，也是把两条消息错误合并成一条的常见事故来源。发布之前必须确认 `isNotificationEnabled`，否则系统静默丢弃。

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "requestPermissions": [
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:loc_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
      },
      { "name": "ohos.permission.KEEP_BACKGROUND_RUNNING" }
    ]
  }
}
```

**教材衔接：后台任务的四种形态**

应用退到后台，进程会被冻结，这是设计而非缺陷。想继续干活必须走后台任务接口，四种形态的成本与约束差别很大：

| 形态 | 触发时机 | 时限 | 关键约束 | 典型用途 |
| --- | --- | --- | --- | --- |
| 短时任务 | 已进入后台的即刻收尾 | 分钟级 | 需在退后台前申请 | 保存数据、补发请求 |
| 延迟任务 | 满足条件时由系统择机执行 | 一次性 | 受充电与灭屏条件影响 | 批量上传日志 |
| 周期任务 | 按固定间隔重复 | 间隔有下限 | 间隔不可自行设得过短 | 定时同步 |
| 长时任务 | 全程前台化运行 | 与场景绑定 | 必须声明匹配运行模式与权限 | 导航、播歌、录制 |

**教材衔接：剪贴板、蓝牙与元服务的边界**

剪贴板是跨应用共享区，读取他应用内容在系统层面有可见性提示，敏感数据不要放进来；写入用 `pasteboard` 的系统剪贴板与记录对象，读取要按 `getPrimaryText` 之类的类型化接口而不是假设格式。蓝牙的开关与扫描都是共享资源，扫描必须先确认适配器状态并且注册与注销同样成对。元服务则把所有规则整体收紧：它的包体上限远低于应用、入口只有卡片与搜索、部分 `user_grant` 权限根本不可申请，写代码前要按形态核对能力清单，不能假设「同一套代码换个打包参数就能上」。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 打卡页面自动带出位置 | 用户首次进入，清单已声明定位权限 | 弹出授权框，允许后回填地址，拒绝后给出可手动输入的兜底 |
| 后台听课时锁屏控制 | 播放中，用户切到桌面或锁屏 | 申请音频类长时任务，通知栏与锁屏出现可控播放条目 |
| 商品链接跨应用分享 | 用户点击复制，目标应用随后读取 | 写入文本记录，读取方按类型解析，异常时提示内容已失效 |

- 典型现象：定位回调一次也没有触发，也没有异常。正确做法：先查系统定位总开关与 `isLocationEnabled`，再确认是否只申请了模糊位置而业务要求精确坐标。
- 典型现象：通知在开发机上正常、上架后被用户投诉收不到。正确做法：检查是否把业务全塞进同一个默认渠道，以及渠道重要级是否被用户调低。
- 典型现象：应用退到后台十分钟后导航中断。正确做法：以导航场景申请长时任务，并在任务结束时立即调用停止接口释放。

### 最小验证场景

- 准备：一个只含两个按钮的页面，分别触发「申请定位并订阅一次」与「取消订阅并读回传感器列表」。
- 观察：首次点击的弹窗文案与 `reason` 是否一致；拒绝后再次点击是否直接进入设置引导；页面销毁后位置回调是否彻底停止。
- 判定：三项分别对应有授权可用、无授权可解释且可恢复、注销后无残留回调，才算系统能力接入完成，任一环节静默失败都要补齐日志。

## 代码/协议/SQL 示例

**教材衔接：把权限判定收敛成一个可复用函数**

页面里散落多处 `if (granted)` 是后续维护的坑。把「查状态、请求、解释」三步封成一个函数，页面只消费布尔结果与失败原因，才能保证不同能力的授权体验一致。

```typescript
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';

type PermissionOutcome = { granted: boolean; permanent: boolean };

async function acquire(
  ctx: common.UIAbilityContext,
  perms: Array<Permissions>
): Promise<PermissionOutcome> {
  const atManager = abilityAccessCtrl.createAtManager();
  const tokenID: number = bundleManager.getBundleInfoForSelfSync(
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
  ).appInfo.accessTokenId;
  const precheck: abilityAccessCtrl.GrantStatus =
    atManager.checkAccessTokenSync(tokenID, perms[0]);
  if (precheck === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
    return { granted: true, permanent: false };
  }
  const result = await atManager.requestPermissionsFromUser(ctx, perms);
  const granted: boolean = result.authResults[0] === 0;
  return { granted: granted, permanent: !result.dialogShownResults![0] };
}
```

**教材衔接：通知的渠道建立与发布**

渠道要早于发布建立，且只在首次建立时生效；后续重要级由用户在设置里控制。`id` 是更新与撤销的唯一句柄，业务侧应把它持久化而不是随手生成。

```typescript
import { notificationManager } from '@kit.NotificationKit';

async function publishProgress(done: number): Promise<void> {
  await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
  const request: notificationManager.NotificationRequest = {
    id: 1001,
    content: {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: { title: '下载中', text: `已完成 ${done}%`, additionalText: '点按查看' }
    },
    slotType: notificationManager.SlotType.SERVICE_INFORMATION
  };
  await notificationManager.publish(request);
}
```

错误表现：把注销写成另一个匿名函数，系统匹配不到原回调，订阅一直存活，表现为离开页面后仍在耗电。

```typescript
aboutToAppear(): void {
  sensor.on('accelerometer', (d: sensor.SensorEvent): void => { this.push(d); });
}
aboutToDisappear(): void {
  sensor.off('accelerometer', (d: sensor.SensorEvent): void => { this.push(d); });
}
```

正确写法：回调保存为稳定引用，注册与注销指向同一个对象。

```typescript
private readonly onAcc: Callback<sensor.SensorEvent> = (d: sensor.SensorEvent): void => {
  this.push(d);
};

aboutToAppear(): void { sensor.on('accelerometer', this.onAcc); }
aboutToDisappear(): void { sensor.off('accelerometer', this.onAcc); }
```

## 时间/空间复杂度或性能分析

| 指标 | 成本来源 | 参考量级 | 优化方向 |
| --- | --- | --- | --- |
| 首次授权流程 | 弹窗交互加用户决策 | 数百毫秒到数十秒 | 延迟到真正需要时再触发，不要启动即弹 |
| 单次定位 | 卫星与网络混合测距 | 数百毫秒到数秒 | 用缓存位置兜底，设置合理超时 |
| 连续定位功耗 | 每帧回调加测距组件常驻 | 每小时百分点级电量 | 拉长 timeInterval，页面不可见即注销 |
| 通知发布 | 跨进程投递与渲染 | 数十毫秒 | 合并同类通知，复用同一 id 更新 |
| 后台任务配额 | 系统按应用画像分配 | 分钟级窗口 | 只在退后台瞬间申请，结束立即释放 |

启动阶段的权限策略直接影响留存。把所有 `user_grant` 权限集中在首屏申请，会让用户在还不了解产品时就面对一长串弹窗，拒绝率显著升高，而且被拒两次的权限此后系统不再弹框，等于永久关上了这扇门。正确做法是「用到才申请」，并且为每个权限准备拒绝后的解释与手动开启路径。

连续型能力是耗电排查的头号对象。位置、传感器、蓝牙扫描的共同特征是回调频率由系统决定、代价按时间累积、界面上毫无痕迹。工程约束有两条：注册与注销必须成对且共享同一回调引用；订阅参数里的时间间隔要显式给出，不能依赖默认值，因为默认值往往为了通用性而偏保守。

后台任务的性能讨论要换成配额视角。短时任务给的是一个有限的分钟级窗口，超窗口后进程被冻结，未完成的异步调用不会报错，只是永远不返回，这类问题在日志里表现为「莫名丢单」。长时任务的运行模式必须与真实业务一致，模式与场景不匹配时不仅审核不通过，系统也会在检测到行为与声明不符时提前回收，表现为功能随机中断。内存维度上，订阅型能力持有的回调会间接持有组件实例，忘记注销还会带来对象无法回收的连带泄漏。

## 常见误区与易错点

- **清单没写就去弹窗。** 权限声明是前置条件，缺失时申请接口直接失败，不会给用户任何提示。
- **把 system_grant 也拿去申请。** 多一次无意义调用，还可能让代码走进永远不返回的分支。
- **只判长度不判下标。** `authResults` 是按请求顺序的结果数组，必须逐项与 `GrantStatus` 比较。
- **拒绝后反复重试同一个接口。** 系统对连续拒绝有静默策略，第二次之后不再弹框，必须转去引导设置页。
- **忘记确认系统定位总开关。** 应用有权限但设备关闭了定位服务，回调同样一次都不来。
- **注销时传了新的匿名函数。** 引用不匹配等于没注销，表现为离开页面后仍在耗电。
- **同一条通知每次换新 id。** 通知栏被堆满；反之把不同业务共用一个 id 又会互相覆盖。
- **不做通知授权检查。** 未授权时发布静默失败，日志干净，用户只觉得「应用不提醒」。
- **长时任务随意挑一个模式。** 声明与行为不符会被系统提前回收，功能表现为随机中断。
- **把应用的能力假设照搬进元服务。** 包体、入口与可申请权限集合都不同，必须逐项核对清单。

## 与其他知识点的关系

**教材衔接：能力接入是把前面所有课接起来的粘合层**

权限流程要 UI（申请与引导）、状态（授权结果放进哪一层）、网络（拿到数据后上报）、后台（任务窗口内完成补发）四方配合。任何一环没打通，问题都会以「功能有时能用」这种最难查的形态出现，所以本课的定位不是新增一个能力，而是把已有能力纳入可验证的调用纪律。

- 向上承接 `harmonyos_navigation`：引导用户去设置页本质是一次跨应用跳转，要按路由的失败分支处理返回。
- 与 `harmonyos_state_management` 协同：授权状态是可观察状态，写进组件级状态会导致多页面各自重复弹窗。
- 与 `harmonyos_network_data` 交界：短时任务窗口内要完成的通常是补发请求与落盘，两者时序耦合。
- 与 `harmonyos_multimedia` 呼应：后台播放依赖音频类长时任务与媒体会话同时生效。
- 与 `harmonyos_distributed` 呼应：跨端能力同样受权限约束，设备发现与连接各有独立权限项。
- 与 `android_development_*` 系列对照：Android 的运行时权限模型与三档授权思路相近，但分组方式与静默策略不同。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_state_management | 状态管理与数据传递 | 授权结果作为可观察状态的归属决定会否重复弹窗 |
| harmonyos_network_data | 网络、数据与文件 | 短时任务窗口内的补发与落盘共用同一套时序约束 |
| harmonyos_multimedia | 多媒体与图形渲染 | 后台播放与锁屏控制需长时任务和会话同时生效 |
| harmonyos_distributed | 分布式软总线与跨端流转 | 设备发现与跨端连接各自带独立权限项 |
| harmonyos_release_optimization | 性能调优与上架 AppGallery | 权限用途说明与后台场景声明都是审核关注点 |
| kotlin_coroutines_scope | 协程与作用域 | 取消订阅与作用域治理解决同一类残留回调问题 |

## 自测题与参考答案

**教材衔接：题号 1** — 关于应用使用敏感权限，下列说法正确的是？

**参考答案**：运行时需弹窗请求且用户可拒绝或撤回。

本题正确项是「运行时需弹窗请求且用户可拒绝或撤回」。敏感权限在安装时并不生效，必须由应用在使用时机主动请求，用户既能当场拒绝也能事后可设置里关闭。清单声明只是让接口有资格被调用，它本身不产生授权；安装时一次性授予的说法把低风险的普通权限与敏感权限混为一谈；被拒一次后系统在连续拒绝情形下会转为静默策略而不是自动放行，指望重启获得授权没有依据。

**教材衔接：题号 2** — 调用定位能力获取连续位置前，除代码外必须先完成的是？

**参考答案**：在模块配置中声明定位相关权限。

本题正确项是「在模块配置中声明定位相关权限」。定位属于敏感能力，清单里缺少对应声明时，运行时请求会在权限校验阶段就失败，业务永远等不到回调。注册桌面入口、打开编译开关、添加地图容器都与权限链路无关，它们既不影响系统对能力的授权判定，也不能替代声明这一步。

**教材衔接：题号 3** — 发布一条前台通知前必须满足的前提是？

**参考答案**：已获得通知授权且渠道未被用户关闭。

本题正确项是「已获得通知授权且渠道未被用户关闭」。未授权或被用户关闭时发布调用不会抛异常，系统只是静默丢弃，这正是排查困难的原因。正式包名与提示音文件都不是必要条件，通知可用系统默认声；标识编号只需在同一应用内保持稳定以便更新，并不要求全局唯一。

**教材衔接：题号 4** — 关于后台任务的运行约束，下列说法正确的是？

**参考答案**：长时任务需匹配指定场景并在结束后释放。

本题正确项是「长时任务需匹配指定场景并在结束后释放」。这类任务的配额与系统对业务场景的判断绑定，声明与行为不符时会被提前回收，用完不释放则长期占用配额。后台无限运行在任何受限移动系统上都不成立；短时的收尾窗口只有分钟级，撑不起一次完整的大文件下载；延迟与周期任务由系统择机执行，不能靠它们保证实时性。

**教材衔接：题号 5** — 关于这段权限申请代码，说法正确的是？
const atManager = abilityAccessCtrl.createAtManager();
const perms: Array<Permissions> = ['ohos.permission.LOCATION'];
const result = await atManager.requestPermissionsFromUser(ctx, perms);
const granted: boolean = result.authResults[0] === 0;

**参考答案**：granted 为假时业务应降级并说明用途再请求。

本题正确项是「granted 为假时业务应降级并说明用途再请求」。结果为假说明用户没有授权，正确姿势是给出可理解的用途解释并提供手动开启入口，而不是立刻重发同一次请求。返回值是数值型授权结果而不是权限名称字符串，需要与授权枚举比较；未弹框与当场拒绝是两种不同情形，要借助弹框标记区分；清单声明是接口能工作的前提，缺了它这条调用只会失败。

## 考点精讲

**教材衔接：高频考点**

1. 三档授权方式的判定，以及每一档在代码侧对应的动作。
2. 运行时申请返回值的正确消费方式：逐项比较授权结果并区分是否弹框。
3. 订阅型能力的成对注销要求与引用一致性。
4. 四种后台任务的时限、触发条件与场景约束。

**教材衔接：命题规律**

- 授权题常给一个具体权限名，考它属于哪一档、需要哪些配套动作，正确项必须同时覆盖弹窗与可撤回两点。
- 后台题把时限与场景混在一起设置陷阱，凡出现无限期、无需说明理由这类绝对表述基本都是错的。
- 代码题给一段申请调用，考返回值语义与失败分支处理，而不是接口名拼写。

**教材衔接：常见考点**

问：关于应用使用敏感权限，下列说法正确的是？
答：运行时需弹窗请求且用户可拒绝或撤回。

问：调用定位能力获取连续位置前，除代码外必须先完成的是？
答：在模块配置中声明定位相关权限。

问：发布一条前台通知前必须满足的前提是？
答：已获得通知授权且渠道未被用户关闭。

问：关于后台任务的运行约束，下列说法正确的是？
答：长时任务需匹配指定场景并在结束后释放。

问：关于这段权限申请代码，说法正确的是？
const atManager = abilityAccessCtrl.createAtManager();
const perms: Array<Permissions> = ['ohos.permission.LOCATION'];
const result = await atManager.requestPermissionsFromUser(ctx, perms);
const granted: boolean = result.authResults[0] === 0;
答：granted 为假时业务应降级并说明用途再请求。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| requestPermissions | 模块清单里的权限声明节点，是所有能力调用的前置条件。 |
| user_grant | 必须运行时弹窗、用户可拒绝可撤回的敏感权限档位。 |
| authResults | 逐项授权结果数组，顺序与请求一致，需与枚举值比较。 |
| geoLocationManager | 定位入口，提供单次定位、连续订阅与开关状态查询。 |
| notificationManager | 通知入口，负责渠道建立、授权检查与发布撤销。 |
| SlotType | 通知渠道类型，决定默认重要级与用户的可控制粒度。 |
| 长时任务 | 与业务场景绑定的后台持续运行机制，用完必须立即释放。 |
| 元服务 | 免安装的轻量应用形态，包体与权限集合都强于应用受限。 |

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
- [声明应用权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [应用内请求授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-privilege-in-app)
- [定位服务开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/geo-add-location)
- [通知管理服务开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-manager-publish)
- [长时任务开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/continuous-task)
