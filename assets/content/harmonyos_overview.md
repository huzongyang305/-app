# HarmonyOS NEXT 全景与生态定位

![HarmonyOS NEXT 全栈自研分层与生态位示意](images/diagram_harmonyos_overview.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：30 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `HarmonyOS NEXT 全景与生态定位`，学习阶段 移动，建议用时 30 分钟。

本课主线：先把「纯血鸿蒙 / OpenHarmony / 兼容安卓的鸿蒙 3 与 4」这三件容易被混为一谈的东西切开，再自上而下走一遍 API 分层（应用 API、OS API、System API）、运行时与编译栈、HMS Core 与鸿蒙开放能力的位置，最后落到开发者身份、应用包形态与生态现状，为后面 11 门课建立统一的坐标系。

**学完本课应当能够**

- 用 `纯血鸿蒙` 的三条判据（去掉 AOSP 与 APK 兼容、自研 `鸿蒙内核`、`ArkTS` 作为一等应用语言）说明 HarmonyOS NEXT 与上一代鸿蒙的断裂点在哪里。
- 在 `OpenHarmony`、`HarmonyOS`、`HMS Core` 三者之间划清边界，并指出同一项能力（如推送、地图）分别由哪一层提供。
- 说明 `HAP` / `HSP` / `App Pack` 三种产物的差别，以及开发者账号、`应用上架` 与 `元服务` 三条发布路径对技术选型的影响。

### 复习清单

- [ ] 能不看正文说出 NEXT 相对安卓兼容版鸿蒙删掉了哪两层，因此哪些存量能力必须重写。
- [ ] 能画出从 `ArkTS` 源码到 `App Pack` 的一条链路，并标注每一环的产出物。
- [ ] 能完成一次自测，把错题对照本课易错点表定位是概念混淆还是版本口径过期。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| 纯血鸿蒙 | 指 HarmonyOS NEXT 这一代自研全栈系统：内核、运行时、框架、系统应用全部替换，不再包含 AOSP 与 Linux 兼容层。 | 易错：把「能装 apk 的鸿蒙」也算纯血，NEXT 上 adb install 安卓包必然失败。 |
| OpenHarmony | 面向开源社区的系统项目，由开放原子基金会托管，提供 Foundation 层 System API 与参考实现。 | 易错：把 OpenHarmony 直接当成商用发货系统，缺少 HMS 生态与商用安全补丁。 |
| HarmonyOS | 华为在 OpenHarmony 之上商用发行的操作系统，叠加 OS API、HMS Core、应用市场与设备协同能力。 | 易错：认为商用版与开源版接口完全一致，商用侧特有 Kit 需要单独申请。 |
| ArkTS | 鸿蒙应用主语言，TypeScript 的静态约束子集加声明式 UI 扩展，编译产物在方舟运行时上执行。 | 易错：当成「就是 TS」，NEXT 禁止任意类型、动态加属性与结构化赋值。 |
| ArkUI | 声明式 UI 框架，提供组件、状态管理、布局与渲染管线，是 ArkTS 侧的界面层。 | 易错：把 ArkUI 等同于 Flutter Widget，鸿蒙没有独立渲染引擎。 |
| HMS Core | 华为移动服务，提供账号、支付、推送、地图、定位、扫描等云端与端侧开放能力集合。 | 易错：以为全部 Kit 都免费且无需申请，多数能力需在 AGC 里开通并签名绑定。 |
| API 分层 | 应用 API（ArkTS 接口）、OS API（系统级能力）、System API（OpenHarmony 基础接口）三层可见性与稳定性约定。 | 易错：在应用侧调用 System API，NEXT 会因权限与签名校验直接拒绝。 |
| HAP / HSP | HAP 是能力包（entry/feature），HSP 是应用内共享包；两者最终打包成 App Pack 上架。 | 易错：用 HSP 做跨应用复用，它只在同一个应用内共享。 |

## 原理与运行机制

### 机制总览：一次「纯血」替换发生在哪几层

HarmonyOS NEXT 的断裂不是「加了新组件」，而是把三层同时换掉：内核层从 Linux 换成面向多设备的自研鸿蒙内核；语言与运行时层从 Java/JS 双栈收敛到 `ArkTS` + 方舟运行时；框架层从 Ability（FA）模型换成 `Stage` 模型，UI 侧统一为 `ArkUI` 声明式。任何一层单独看都能找到安卓或 iOS 的对应物，但它们被绑成一个封闭栈之后，跨层移植成本就变成了一次重写。

**教材衔接：三层替换的对照**

| 层 | 兼容安卓的鸿蒙 | HarmonyOS NEXT | 迁移时的直接后果 |
| --- | --- | --- | --- |
| 内核 | Linux 宏内核 + 鸿蒙微内核特性 | 自研鸿蒙内核，微内核设计 | 依赖 /proc、syscall 的 native 逻辑需重写 |
| 应用层兼容 | 可运行 APK 与 Java 生态 | 移除 AOSP 与 ART | 第三方安卓 SDK 必须找鸿蒙对应 Kit |
| 语言与运行时 | Java/Kotlin、JS 前端、Web | ArkTS（方舟编译 AOT）、C/C++（NAPI） | 类型系统收紧，反射与动态属性受限 |
| UI 框架 | 安卓 View + 鸿蒙 JS2 | ArkUI 声明式（ArkTS 语法） | 老 JS/HTML 页面全部改写 |
| 应用模型 | FA（Feature Ability） | Stage（UIAbility + ExtensionAbility） | 生命周期回调与窗口管理语义变化 |

**教材衔接：API 三层可见性**

应用开发者日常写的是应用 API，例如 `@kit.ArkUI`、`@kit.NetworkKit` 导出的接口；OS API 是华为商用侧扩展，需要对应的 `system_basic` / `system_core` 权限与签名；System API 由 OpenHarmony Foundation 定义，属于系统能力提供者与 OEM 的接口面。三者稳定性承诺不同：应用 API 有版本兼容保证，System API 随 OpenHarmony 版本演进可能破坏性变更，这也是很多教程里的示例在真机上跑不通的根因。

| 层 | 谁可以调 | 典型入口 | 稳定性 |
| --- | --- | --- | --- |
| 应用 API | 三方应用 | `import { http } from '@kit.NetworkKit'` | SDK 主版本内向后兼容 |
| OS API | 申请授权的应用 | 特定 Kit + ACL 权限 | 随商用 ROM 灰度发布 |
| System API | 系统应用 / OEM | OpenHarmony Foundation | 跨大版本可能不兼容 |

**教材衔接：方舟引擎与编译链路**

ArkTS 源码经过 `arkc` 编译器做类型检查与语法降级，产出方舟字节码（`.abc`），再在执行阶段以 AOT 与 JIT 混合方式落到机器码；UI 侧 ArkUI 把声明式描述编译成组件树，配合方舟内存分配器与渲染管线做首帧优化。理解这条链路能解释两件实践现象：一是 NEXT 上没有「运行时解释执行任意字符串」的能力，动态求值被禁止；二是包体里 `.abc` 替代了 dex，反编译工具链与安卓完全不同。

```json
{
  "app": {
    "bundleName": "com.example.hmnextdemo",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "label": "$string:app_name",
    "icon": "$media:app_icon",
    "minAPIVersion": 12,
    "targetAPIVersion": 12
  }
}
```

**教材衔接：HMS Core 与鸿蒙开放能力的分工**

推送、账号、应用内支付、地图、定位这类「需要云端配合」的能力过去统一挂在 HMS Core 名下；NEXT 之后，端侧调用面被重整为一批 `@kit.*` 模块，例如 `@kit.PushKit`、`@kit.AccountKit`、`@kit.MapKit`，但云端配置、证书与配额仍然在 AppGallery Connect 侧。所以「装了 SDK 就能用」的判断是错的：能力开关、签名指纹、包名三者必须同时对齐。

**教材衔接：生态现状与开发者身份**

个人开发者可以发布免费应用与 `元服务`，部分能力（如支付、内容分级）需要企业资质；企业开发者需完成营业执照认证并对公打款。生态上 NEXT 采取「头部应用适配 + 长尾用元服务承接」的策略，元服务免安装、以卡片和 `Service` 形态存在，适合轻交互场景，也是个人开发者最快的上线路径。技术选型前应先确认：目标设备是否已升到 NEXT、需要的是 App 还是元服务、依赖的 Kit 是否已开放给三方。

**教材衔接：从源码到上架的一条链路**

把这条链路记牢，后面所有工程问题都能定位到具体环节：ArkTS 源码与资源经 hvigor 任务图编译，ArkTS 部分由 `arkc` 产出 `.abc`，资源由资源编译器打包成 `.r` 描述并生成 `resources.index`，模块级产物签上 Profile 与证书后成为 HAP；多个 HAP 与 HSP 再合并成 `.app` 格式的 App Pack 提交 AppGallery Connect。调试期用的签名证书与发布期不同，两套 material 目录不要混用；CI 里把签名材料做成环境变量注入，避免把 `.p12`、`.cer`、`.p7b` 提交进仓库。

| 环节 | 输入 | 产出 | 最常见的失败点 |
| --- | --- | --- | --- |
| 语法与类型检查 | `.ets` 源码 | 通过校验的中间产物 | 用了被禁的 TS 动态写法 |
| 字节码编译 | 通过校验的产物 | `.abc` | 版本与 SDK 不匹配 |
| 资源编译 | `resources/` 目录 | 资源索引与限定词目录 | 限定词目录命名错误 |
| 打包签名 | HAP/HSP 集合 | 已签名 HAP | 证书与 bundleName 不一致 |
| 上架产物 | 多个已签名包 | App Pack（`.app`） | 缺少指定设备类型的包 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 存量 App 评估是否适配 NEXT | 一份第三方 SDK 清单与现有安卓工程 | 能力映射表：可直接替换、需自研、需换 Kit 三类，附工作量估算 |
| 新项目选型 | 目标设备为 Mate/Pura 系列 NEXT 机型，需要卡片与免安装入口 | 决定采用 App + 元服务双形态，主包 HAP + 共享 HSP 结构 |
| 技术预研汇报 | 只有开源资料与一台开发机 | 说清 OpenHarmony 与商用 NEXT 的差异，并给出可发货的合规路径 |

- 典型现象：团队按安卓经验引入某个开源库，编译通过但运行时崩溃。正确做法：先确认该库是否依赖 AOSP 私有 API 或 JNI 直接 syscall，NEXT 上必须换成对应 `@kit.*` 能力或纯 ArkTS 实现。
- 典型现象：把 OpenHarmony 每日构建镜像刷到量产机上验证业务。正确做法：开发期用 SDK 版本对齐的模拟器或正式版 ROM，OpenHarmony 只用于阅读源码与理解 System API。
- 典型现象：文档里写「调用某 API 需要 ACL 权限」，签名后仍报权限拒绝。正确做法：ACL 只放开受限权限，云端未开通的 Kit 依旧不可用，需回 AGC 检查能力开关与证书指纹。

### 最小验证场景

- 准备：一台 HarmonyOS NEXT 真机或 DevEco 模拟器，一个新建的空工程，`minAPIVersion` 设为 12。
- 观察：在页面里读 `deviceInfo.osFullName`、`deviceInfo.sdkApiVersion`、`bundleManager` 的包信息三处输出，确认设备处于 NEXT 分支而非兼容安卓的老版本。
- 判定：能拿到 API 12 及以上的版本号、且工程不引入任何 AOSP 依赖仍跑通首帧，才算打通基线；任一环节失败先修环境再谈业务。

## 代码/协议/SQL 示例

**教材衔接：用 deviceInfo 与 bundleManager 判定运行环境**

迁移评估的第一步是「我现在到底跑在什么系统上」。下面这段在页面加载时打印设备与包信息，把 `osFullName`、API 版本与是否调试态三项写进日志，后续排查 Kit 不可用问题时可以先排除环境错配。

```typescript
import { deviceInfo } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

async function dumpEnv(): Promise<void> {
  const info = await bundleManager.getBundleInfoForSelf(
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  hilog.info(0x0001, 'EnvProbe',
    `os=${deviceInfo.osFullName} api=${deviceInfo.sdkApiVersion} ver=${info.versionName}`);
}
```

**教材衔接：一份模块清单的最小 JSON**

模块级 `src/main/module.json5` 描述包内模块类型、入口能力与权限需求。`type` 为 `entry` 表示主模块，`exported` 控制其他应用能否拉起该能力；下面是理解字段用途的示意片段而非完整文件。

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["phone", "tablet", "2in1"],
    "abilities": [
      { "name": "EntryAbility", "exported": true, "startWindowIcon": "$media:startIcon" }
    ],
    "requestPermissions": [{ "name": "ohos.permission.INTERNET" }]
  }
}
```

错误表现：把 NEXT 当成「可以装 apk 的鸿蒙」，沿用安卓 SDK 清单直接开工，写到推送才发现在 NEXT 上找不到对应实现，需要把三处调用点全部重写。

```typescript
// 迁移评估阶段就要确认能力是否存在，而不是等编译报错
let pushReady = false;   // 缺少 AGC 配置与 Kit 校验，运行时才暴露问题
```

正确写法：把每一项外部能力做成显式的能力探测与降级分支，评估阶段就能产出「能直接用 / 需要开通 / 必须自研」三档清单。

```typescript
async function probePush(): Promise<boolean> {
  try {
    return (await tokenService.getRequestEnableStatus()) === 0;
  } catch (err) {
    hilog.warn(0x0001, 'EnvProbe', 'push unavailable: ${err}');
    return false;
  }
}
```

## 时间/空间复杂度或性能分析

| 维度 | 观察口径 | NEXT 上的典型量级 | 主要影响因素 |
| --- | --- | --- | --- |
| 冷启动到首帧 | 点图标到页面可交互 | 中高端机 300~700ms | AOT 产物质量、entry 模块体积、首帧页面复杂度 |
| HAP 体积 | 安装包内 entry.hap | 空工程约 1~3MB，含资源线性增长 | `.abc` 字节码、图片资源、so 库 |
| 运行内存 | PSS 稳态 | 轻应用 80~200MB | 方舟 GC 策略、组件树深度、图片缓存 |
| 帧率 | 滑动列表 FPS | 目标 60fps，可变量 90/120fps | 主线程任务、状态刷新范围、渲染层级 |
| 构建耗时 | 全量 assembleHap | 数十秒到数分钟 | 模块数量、混淆开关、HSP 依赖图 |

生态定位决定了性能基线：NEXT 上没有安卓的 dex2oat 与 ART 分层编译，取而代之的是方舟字节码，安装阶段不需要长时间预热，因此「装完第一次打开很慢」这个安卓经验在鸿蒙上不成立，真正的启动成本落在 `entry` 模块的 ArkTS 初始化与首帧组件树构建上。包体方面，`HSP` 能把多模块共用的代码从各 HAP 中抽出来，避免同一份逻辑在 feature 包里重复出现；但如果滥用 HSP，安装期需要一次性解析所有共享包，低端机首启会被依赖解析拖慢。

多设备形态是 NEXT 性能模型的另一个变量：同一份 ArkUI 代码在折叠屏展开态会构造更大的组件树，布局测量成本随节点数近似线性增长。因此「生态定位」阶段就应当决定是否采用一次开发多端部署（响应式断点 + 栅格），这比后期为平板单独写页面更省渲染开销，也更省包体。

从指标口径看，生态定位还会改写三个数字的读法。启动耗时不能只比自家应用：NEXT 的冷启动路径由方舟运行时与 Stage 模型决定，与安卓的进程预热机制不同，跨端比较必须换成同机同场景的相对值。包体大小要按 HAP 与 HSP 分开统计，共享库只算一次，否则会把复用带来的收益误读成膨胀。帧率与渲染表现则取决于设备形态，同一份声明式代码在折叠屏半开态与平板分栏下会走不同的布局求解路径，因此帧预算评估必须逐形态采样，不能用一种设备的结论覆盖全部。

## 常见误区与易错点

- **把 HarmonyOS NEXT 说成「安卓的换皮」。** NEXT 已移除 AOSP 与 APK 兼容层，应用运行在方舟运行时上，安装、调试、崩溃栈都与安卓不同。
- **把 OpenHarmony 与 HarmonyOS 当同一个东西。** 前者是开源参考实现与 System API 来源，后者是商用发行版，带 HMS Core、安全补丁与上架体系。
- **认为 ArkTS 等于 TypeScript。** ArkTS 是带强静态约束的方言，`any`、动态属性、结构化赋值等写法会被编译器拒绝。
- **只背 API 号不背 Kit 名。** API 12 起接口以 `@kit.*` 聚合导出，同一功能的老 `@ohos.xxx` 路径仍可用但文档口径已迁移。
- **忽视开发者身份差异。** 个人主体与企业主体能开通的 Kit 不同，支付、内容分发类能力通常要求企业资质。
- **把 HAP 与 HSP 混用。** HAP 是可独立安装的能力包，HSP 只在同一应用内共享，跨应用复用要发布为 HAR 静态库。
- **用兼容版鸿蒙的 SDK 建工程。** FA 模型与 JS 页面在 NEXT 上不再受支持，工程模板必须选 Stage 模型。
- **以为装上 Kit 就能调用。** 云端能力需在 AGC 开通、应用签名指纹与包名一致，否则端侧只会拿到权限错误。
- **把元服务当小程序直接改名。** 元服务有独立的卡片规格、包体上限与能力白名单，交互假设与 App 不同。
- **只看装机量选型。** 目标用户机型是否已升到 NEXT、系统 API 分布，比总装机数更能决定可用接口。

## 与其他知识点的关系

**教材衔接：与相邻技术栈的坐标系对齐**

如果你已经学过安卓或 iOS，可以把本课内容映射到熟悉的概念上：`UIAbility` 近似 Activity/Scene 但生命周期语义不同；`ArkUI` 近似 SwiftUI/Compose 的声明式范式；`@kit.*` 近似 AndroidX 的模块聚合；`App Pack` 近似 AAB 的上架包形态。差异点集中在两处：一是鸿蒙把分布式能力做成系统级 API，二是包形态有三种且安装语义不同。

- 向上承接 `cross_platform_flutter` 的跨端视角：自绘引擎与原生渲染两条路线的取舍在 NEXT 上表现为「ArkUI 原生渲染 + 无 AOT 桥」。
- 平行对照 `android_development_arch`：组件化与 HAP/HSP 拆分在解决同一类问题，但鸿蒙的拆分粒度在安装期生效。
- 平行对照 `kotlin_coroutines`：`async/await` 在 ArkTS 的语义接近协程挂起，但运行在单线程事件循环上。
- 向下为 `harmonyos_deveco_setup` 与 `harmonyos_arkts_basics` 提供术语表与版本口径。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_deveco_setup | DevEco Studio 与工程结构 | 本课说的 HAP/HSP/App Pack 在该课落到具体目录与 build-profile.json5 配置 |
| harmonyos_arkts_basics | ArkTS 语言基础 | 本课「ArkTS 不等于 TS」的判断在该课用具体禁用语法验证 |
| harmonyos_state_management | 状态管理与数据传递 | Stage 模型下的组件生命周期与状态作用域在该课展开 |
| harmonyos_release_optimization | 性能调优与上架 | 本课的启动、包体量级在该课给出测量手段与优化动作 |
| android_development_arch | 安卓组件化架构 | 同一类「多模块拆分」问题在两个生态里的产物形态与安装语义不同 |
| cross_platform_flutter | Flutter 跨平台 | 自绘渲染与原生渲染的取舍对照，帮助理解 ArkUI 的性能模型 |

## 自测题与参考答案

**教材衔接：题号 1** — HarmonyOS NEXT 被称为「纯血鸿蒙」的最直接依据是？

**参考答案**：移除 AOSP 与 APK 兼容层。

本题正确项是「移除 AOSP 与 APK 兼容层」。NEXT 把安卓运行时与兼容框架整体撤掉，应用只能以 ArkTS 或 C++ 形态运行在方舟运行时上，这是它与此前可侧载 APK 的鸿蒙版本之间唯一的硬边界，也是所有迁移工作的起点。自研内核与新的界面框架是同步发生的配套替换，API 命名空间重整只是文档口径变化，都不足以单独构成「纯血」的判据。

**教材衔接：题号 2** — 下列关于 OpenHarmony 与 HarmonyOS 关系的说法成立的是？

**参考答案**：后者在前者之上叠加商用能力。

本题正确项是「后者在前者之上叠加商用能力」。OpenHarmony 由开放原子基金会托管，提供 Foundation 层与 System API 参考实现；商用 HarmonyOS 在此之上加入 HMS Core、OS API、安全补丁与上架体系，并有明确的 API 版本认证。两者共享部分接口但发布节奏与可用能力不同，把开源每日构建镜像直接当发货系统会缺少生态与合规支撑。

**教材衔接：题号 3** — API 12 起在 ArkTS 中引用系统能力，官方推荐的导入写法是？

**参考答案**：按 `@kit.*` 模块聚合导入。

本题正确项是「按 `@kit.*` 模块聚合导入」。从这一代 SDK 开始，网络、UI、能力等接口以 Kit 为单位聚合导出，类型提示、文档与能力清单都按 Kit 组织，原先细粒度的 `@ohos.*` 路径仍可用但不再作为主口径。相对路径只用于工程内文件，包别名解决的是模块解析而不是能力可见性，ArkTS 也禁止用字符串动态求值的方式加载模块。

**教材衔接：题号 4** — 需要在同一应用的多个模块间共享一份代码，应选用的包形态是？

**参考答案**：HSP 共享包。

本题正确项是「HSP 共享包」。HSP 在安装期随宿主应用一起被解析，只在本应用范围内共享，能避免同一份逻辑在多个 HAP 里重复打包，符合「应用内共享」这一诉求。HAR 是编译期静态库，适合跨应用分发但会被打进每个使用方；独立 HAP 是可安装的能力包而不是共享库；原子化服务对应免安装的元服务形态，与代码共享无关。

**教材衔接：题号 5** — 下面代码打印出的 os 字段最可能反映什么？
import { deviceInfo } from '@kit.BasicServicesKit';
@Entry
@Component
struct Probe {
  build() {
    Column() {
      Text(deviceInfo.osFullName)
    }
  }
}

**参考答案**：设备的发行系统名称。

本题正确项是「设备的发行系统名称」。`deviceInfo.osFullName` 返回设备发货时写入的完整发行版字符串，在 NEXT 机型上可用于与 `sdkApiVersion` 交叉验证运行环境，是迁移评估阶段最常用的判据之一。应用版本名要从包管理接口读取，编译器版本不会作为运行时字段暴露给应用层，厂商型号另有对应字段而不是这个属性。

## 考点精讲

**教材衔接：高频考点**

1. 纯血鸿蒙的判据：以「是否移除 AOSP 与 APK 兼容」为核心，其余自研组件为配套。
2. OpenHarmony 与 HarmonyOS 的分层关系，以及 System API / OS API / 应用 API 的可见性差异。
3. 包形态三分法：HAP 能力包、HSP 应用内共享包、HAR 静态库，跨应用复用只能选 HAR。
4. `@kit.*` 导入口径与 API 版本、开发者身份对能力可用性的共同约束。

**教材衔接：命题规律**

- 概念辨析题占多数，正确项往往带「之上叠加」「同一应用内」这类限定词，避免绝对表述。
- 排错题喜欢用「换皮」「就是 TS」「装了就能用」这类看似顺口的因果链，考的是断裂点是否清楚。
- 场景题给一个存量工程，要求在三类处置（直接替换、需开通、需自研）中挑最短路径。

**教材衔接：常见考点**

问：HarmonyOS NEXT 被称为「纯血鸿蒙」的最直接依据是？
答：移除 AOSP 与 APK 兼容层。

问：下列关于 OpenHarmony 与 HarmonyOS 关系的说法成立的是？
答：后者在前者之上叠加商用能力。

问：API 12 起在 ArkTS 中引用系统能力，官方推荐的导入写法是？
答：按 `@kit.*` 模块聚合导入。

问：需要在同一应用的多个模块间共享一份代码，应选用的包形态是？
答：HSP 共享包。

问：下面代码打印出的 os 字段最可能反映什么？
import { deviceInfo } from '@kit.BasicServicesKit';
@Entry
@Component
struct Probe {
  build() {
    Column() {
      Text(deviceInfo.osFullName)
    }
  }
}
答：设备的发行系统名称。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 纯血鸿蒙 | HarmonyOS NEXT 的通俗叫法，指全栈自研且不再兼容安卓包。 |
| OpenHarmony | 开源社区系统项目，提供 Foundation 层与 System API 参考实现。 |
| Stage 模型 | NEXT 唯一应用模型，以 UIAbility 与 ExtensionAbility 组织入口与窗口。 |
| ArkTS | 带强静态约束的 TypeScript 方言，是应用层主语言。 |
| ArkUI | 声明式 UI 框架，负责组件、布局、状态与渲染管线。 |
| HMS Core | 华为移动服务，提供账号、支付、推送、地图等开放能力集合。 |
| HAP / HSP | 能力包与应用内共享包，最终合并为 App Pack 提交上架。 |
| 元服务 | 免安装的应用形态，以卡片与服务入口承载轻交互场景。 |

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
- [HarmonyOS 与 OpenHarmony 的关系说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/harmonyos-and-openharmony)
- [Stage 模型应用架构说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-models)
- [应用包结构与 HAP/HSP 说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hap-package)
- [设备类型与多端部署建议](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-device-adaptation)
