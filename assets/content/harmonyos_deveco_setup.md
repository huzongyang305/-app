# DevEco Studio 与工程结构

![DevEco Studio 工程结构与构建签名链路](images/diagram_harmonyos_deveco_setup.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：35 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `DevEco Studio 与工程结构`，学习阶段 移动，建议用时 35 分钟。

本课主线：从安装 DevEco Studio 与 SDK 组件开始，走一遍「新建工程 → 读懂目录 → 改配置 → 跑模拟器 → 配签名 → 打真机」的完整闭环，重点讲清项目级 / 模块级 / 应用级三份配置各自管什么，以及 `HAP`、`HSP`、`HAR` 三种产物在目录里如何落地。

**学完本课应当能够**

- 独立完成 DevEco Studio 与 SDK 的安装选型，说明 `Local Emulator` 与真机调试各自能覆盖与不能覆盖的能力。
- 逐目录解释一个 Stage 模型工程，指出 `build-profile.json5`、`oh-package.json5`、`module.json5`、`AppScope` 四处配置的责任边界。
- 配置调试签名与发布签名，并用 `hvigor` 命令行产出可安装的 HAP 与可上架的 App Pack。

### 复习清单

- [ ] 能不看正文画出一个 entry 模块从 `src/main/ets` 到 `build/default/outputs` 的目录树，并说明中间产物。
- [ ] 能说清 `products`、`signingConfigs`、`buildOption` 三个字段分别在哪一层生效。
- [ ] 能完成一次自测，把错题对照本课易错点表定位是配置层级搞混还是签名材料搞混。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| DevEco Studio | 华为官方 IDE，集成 ArkTS 语法检查、预览器、模拟器管理、构建与签名向导。 | 易错：只装 IDE 不装对应 SDK 组件，编译期才报缺 platform 包。 |
| SDK 组件 | 由 SDK Manager 分装的 Platform、Previewer、Toolchains、Native 等可独立升级的部件。 | 易错：升级 IDE 不等于升级 API 版本，二者要分别确认。 |
| Local Emulator | 本机运行的设备镜像，可模拟屏幕、传感器、相册与系统 UI。 | 易错：不能模拟真实设备的分布式组网与部分硬件编解码。 |
| hvigor | 声明式构建任务引擎，负责把源码、资源与依赖编排成 HAP/HSP 产物。 | 易错：把 hvigor 当 Gradle 直接改任务脚本，多数场景应改配置而非写插件。 |
| ohpm | OpenHarmony 包管理器，管理 HAR 包与三方依赖，锁文件为 oh-package-lock.json5。 | 易错：只在模块里加依赖不改项目级配置，出现同库多版本。 |
| module.json5 | 模块级清单，声明模块类型、能力、权限、页面路由与设备类型。 | 易错：改完 abilities 不重新签名，安装时报签名与信息不一致。 |
| build-profile.json5 | 构建配置，项目级管 products 与 signingConfigs，模块级管 targets 与 buildOption。 | 易错：把 release 混淆开关写在项目级，模块不继承导致未生效。 |
| AppScope | 应用级作用域目录，存放应用图标、名称资源与应用级配置。 | 易错：把应用级资源重复拷进模块，打包后出现两份同名资源。 |

## 原理与运行机制

### 机制总览：一个 Stage 工程的三层配置

工程根目录看起来文件不多，但配置实际上分成三层：应用级（`AppScope/app.json5` 与各资源目录）、模块级（每个模块的 `src/main/module.json5`）、构建级（根 `build-profile.json5` 与模块 `build-profile.json5`）。三层各有各的责任边界，越界配置不会报错但会静默失效，这是新手最难自查的一类问题。

**教材衔接：目录结构逐层拆解**

| 目录或文件 | 所属层 | 承担职责 |
| --- | --- | --- |
| AppScope/app.json5 | 应用级 | bundleName、版本、应用图标与标签 |
| entry/src/main/module.json5 | 模块级 | 模块类型、UIAbility、权限、pages 路由 |
| entry/src/main/ets | 源码 | 页面、组件、能力、工具类与入口 |
| entry/src/main/resources | 资源 | 限定词目录下的字符串、图片、媒体 |
| oh_modules | 依赖 | ohpm 安装的包实际落盘位置 |
| build-profile.json5 | 构建级 | products、signingConfigs、modules 注册 |
| hvigorfile.ts | 构建级 | 任务钩子与插件注册，一般不改 |

**教材衔接：SDK 与模拟器的安装选型**

安装时先确认 IDE 版本与目标 API 的对应关系：一个 DevEco Studio 大版本通常绑定一个 SDK 主版本，装错会导致工程模板里没有 NEXT 分支。SDK Manager 里 Platform 提供编译期接口，Previewer 提供免设备预览，Toolchains 提供 hvigor 与 hdc。Local Emulator 走 x86 镜像，启动快、能截图与模拟部分传感器，适合日常开发；它跑不出真实的分布式组网、部分相机与硬件解码链路，也拿不到真实指纹与 NFC，涉及这些能力必须回到真机。远程模拟器由云端设备池提供，适合没有设备时的冒烟验证，但网络延迟会明显影响交互体验。

**教材衔接：hvigor 的构建任务链**

一次 `assembleHap` 会经历配置解析、依赖安装、ArkTS 编译、资源编译、打包与签名六个阶段。理解这条链能解释三类现象：只改资源不触发重编通常是资源限定词目录命名非法；编译时报 `Cannot find module` 多半是 oh_modules 未安装或模块未在根 build-profile 的 modules 中注册；签名阶段失败通常与代码无关，而是证书、Profile 与 bundleName 三者不一致。

```bash
cd entry
hvigorw --mode module -p product=default assembleHap --no-daemon
# 产物：entry/build/default/outputs/default/entry-default-signed.hap
```

**教材衔接：签名材料与两套签名流程**

调试签名可以走 IDE 的自动签名：登录开发者账号后由 IDE 生成调试证书、Profile 与密钥库，并把材料写进用户目录下的 `.ohos/config`。发布签名必须手工准备四件套：`.p12` 密钥库、`.csr` 证书请求、`.cer` 发布证书、`.p7b` Profile，四者的包名与设备范围必须一致。命令行签名时把密码通过环境变量注入，切勿把 material 目录提交到仓库。

```json
{
  "app": {
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "debug.cer",
          "storeFile": "debug.p12",
          "keyAlias": "debugKey",
          "profile": "debug.p7b"
        }
      }
    ],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "runtimeOS": "HarmonyOS",
        "compileSdkVersion": "5.0.0(12)"
      }
    ]
  }
}
```

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 新成员环境搭建 | 一台 Windows 开发机与一个企业开发者账号 | 可运行的空工程、已连接真机、能一键出包的签名配置 |
| 多模块工程拆分 | 已有单体 entry，需复用公共组件与网络层 | entry + feature + shared(HSP) 结构，公共库以 HAR 发布 |
| CI 出包 | 代码仓库与签名材料以密文注入 | 每次提交产出已签名 HAP 与 App Pack 两个制品 |

- 典型现象：本地能跑，同事拉下来报 `SDK component missing`。正确做法：把 `compileSdkVersion` 与 `compatibleSdkVersion` 写进工程而不是依赖 IDE 默认，并在 README 标注需要装的 SDK 组件。
- 典型现象：预览器里布局正常，模拟器里字体位置偏移。正确做法：预览器不做完整系统度量，关键页必须以模拟器和真机各验一次。
- 典型现象：安装时报 `error: install failed due to invoke signature verify`。正确做法：先确认卸载旧包再装，签名材料变更后旧包不会被覆盖安装。

### 最小验证场景

- 准备：一个刚生成的 Empty Ability 工程，SDK 版本与 IDE 版本匹配，已配置自动签名。
- 观察：执行 `hvigorw clean assembleHap`，记录构建耗时、产物目录里 `*-signed.hap` 的体积，以及 `install` 后首次启动的日志时间戳。
- 判定：构建成功、产物已签名、真机能拉起首屏并打印出自定义日志三项全绿，说明工具链闭环打通，可以进入业务开发。

## 代码/协议/SQL 示例

**教材衔接：模块注册与依赖声明的最小写法**

模块要参与构建，必须同时满足两件事：物理目录存在，且在根 `build-profile.json5` 的 `modules` 数组里登记；跨模块引用则写在调用方的 `oh-package.json5` 里，用 `file:` 指向本地路径或直接用包名指向 HAR。

```json
{
  "modelVersion": "5.0.0",
  "modules": [
    { "name": "entry", "srcPath": "./entry", "targets": [{ "name": "default", "applyToProducts": ["default"] }] },
    { "name": "shared", "srcPath": "./shared" }
  ]
}
```

**教材衔接：入口能力的完整声明**

`module.json5` 里的 abilities 决定应用能不能被桌面图标拉起，`skills` 中的 `entities` 与 `actions` 是系统匹配入口的依据，缺失时应用装得上但没有启动入口。

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "mainElement": "EntryAbility",
    "deviceTypes": ["phone", "tablet"],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:white",
        "exported": true,
        "skills": [{ "entities": ["entity.system.home"], "actions": ["action.system.home"] }]
      }
    ]
  }
}
```

错误表现：把共享包声明成 `entry` 类型，构建能过，但安装阶段出现两个都想当主模块的能力包，桌面图标重复或启动落到错误模块。

```json
{ "module": { "name": "shared_utils", "type": "entry" } }
```

正确写法：共享代码用 `shared`（应用内 HSP）或独立发布为 HAR，主入口只保留一个 `entry` 模块。

```json
{ "module": { "name": "shared_utils", "type": "shared" } }
```

## 时间/空间复杂度或性能分析

| 维度 | 测量点 | 典型量级 | 可执行的优化动作 |
| --- | --- | --- | --- |
| 全量构建 | clean 后 assembleHap | 空工程 20~60s，十模块工程 3~8min | 拆模块并开启增量，避免每次都 clean |
| 增量构建 | 改一个 ets 文件 | 1~8s | 不要把日志与截图资源放进源码目录 |
| 模拟器冷启 | 双击图标到桌面就绪 | 15~60s，取决于磁盘与 CPU | 用已启动实例，避免反复新建 |
| HAP 体积 | 产物文件大小 | 空包 1~3MB | 大图走 CDN 或换 WebP，按设备拆包 |
| 安装耗时 | hdc install | 数百 ms 到数秒 | 减少 HSP 数量，避免安装期解析长依赖 |

构建时间的主要成本分布在 ArkTS 类型检查与资源编译两段。ArkTS 的类型检查是跨文件全量语义分析，单文件改动也会触发依赖链上的重新检查，因此把巨型工具文件拆成多个窄接口模块，比堆在一个 `Utils.ets` 里增量友好。资源编译的成本与文件数量而不是体积近似线性，工程里塞进上百张未压缩截图会明显拖慢每次打包。

包体方面要注意三层叠加：ArkTS 字节码、`resources.index` 与媒体资源、以及可能存在的 native `.so`。多设备形态下一次构建可能产出多个 HAP，每个都带一份资源索引，如果公共资源没有下沉到 HSP，体积会按模块数放大。调试期的做法是先用 `--mode module` 只构建变更模块，发布前再跑一次全量，避免把日常等待时间花在无关模块上。

工程结构还会显著影响增量构建与首屏表现。把大量低频页面留在入口模块里，会让每次改动的类型检查范围整体变大，增量构建时间随模块内文件数近似线性增长；按特性拆分后，改动通常只触发所在模块的重编译。运行时侧同样受影响：入口 HAP 的体积决定安装与解压时间，也影响首次启动时的字节码加载范围，把不进入首屏的页面与资源移出主包，是配置层就能拿到的收益。帧率与渲染不由工程结构直接决定，但资源限定目录放错会导致加载到超出显示尺寸的位图，间接抬高每帧的合成开销。

## 常见误区与易错点

- **只升级 IDE 不确认 SDK。** 工程模板与编译接口由 SDK 决定，IDE 版本对不上时报的错常被误读成语法问题。
- **把 `build-profile.json5` 当成唯一配置中心。** 应用信息在 `AppScope/app.json5`，能力与权限在 `module.json5`，三处混改会互相覆盖认知。
- **JSON5 用错注释风格。** JSON5 支持注释与尾逗号，但部分脚本按严格 JSON 解析这些文件，CI 里要保持一致工具链。
- **共享包写成 entry。** 会出现多主模块现象，正确类型是 `shared`，跨应用复用应发 HAR。
- **调试与发布签名混用一套材料。** 上架包必须用发布证书与发布 Profile，用调试材料打出的包无法通过审核。
- **把签名 material 提交进仓库。** 密钥库与 Profile 属于机密，应通过 CI 密文变量注入。
- **依赖只加在模块不登记项目。** 未在根 `modules` 注册的目录不参与构建，报模块找不到。
- **用预览器验收所有页面。** 预览器不做完整系统能力与字体度量，动画、权限弹窗、分布式能力都必须真机验。
- **clean 当万能药。** 反复 clean 会把增量优势全部丢掉，先查 oh_modules 与 SDK 组件是否完整更划算。
- **忽略 deviceTypes。** 模块声明的设备类型与实际产物不符，会在上架阶段被判定缺少对应设备包。

## 与其他知识点的关系

**教材衔接：与安卓与 iOS 工具链的对照**

把新工具映射到已经熟悉的对象可以显著降低学习成本，但要注意责任边界并不完全一致：hvigor 的任务图接近 Gradle，可配置写法更声明式；DevEco Studio 基于 IntelliJ 平台，快捷键与重构体验可以平移，但预览器与 Layout Inspector 的能力覆盖比安卓的对应工具更窄。

- 向上承接 `harmonyos_overview` 的包形态结论，本课把 HAP/HSP 落成具体目录与配置字段。
- 向下为 `harmonyos_arkts_basics` 准备好可编译环境，避免语法练习被工具问题打断。
- 与 `android_development_gradle` 平行：两者都在解决多模块与签名问题，但鸿蒙的模块类型是安装期语义。
- 与 `cross_platform_flutter` 平行：Flutter 的 pubspec 与鸿蒙的 oh-package 都是包声明，但鸿蒙还有应用级 AppScope。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_overview | 全景与生态定位 | 该课给出的包形态与版本口径是本课配置字段的来源 |
| harmonyos_arkui_first_page | 首个声明式页面 | 工程跑通后第一个验收目标就是该课的页面能否渲染 |
| harmonyos_state_management | 状态管理与数据传递 | AppStorage 与持久化配置依赖本课的模块与产物结构 |
| harmonyos_release_optimization | 性能调优与上架 | 签名四件套与产物形态在该课进入发布流程与审核 |
| android_development_gradle | 安卓 Gradle 构建 | 同类构建问题在两个生态中的配置粒度与生命周期不同 |

## 自测题与参考答案

**教材衔接：题号 1** — DevEco Studio 的 Local Emulator 无法覆盖下列哪项验证？

**参考答案**：真实设备的分布式组网。

本题正确项是「真实设备的分布式组网」。本机模拟器用 x86 镜像模拟屏幕尺寸、传感器、相册与系统界面，日常布局与交互验证足够用，但软总线组网、真实指纹、NFC 与部分硬件编解码链路依赖实体设备与真实网络环境，必须回到真机验证。多分辨率与折叠态可以通过新建不同设备实例覆盖，通知面板属于系统 UI 的一部分，模拟器能够呈现。

**教材衔接：题号 2** — 想让一个模块只在本应用内被其他模块共享，`module.json5` 中 type 应设为？

**参考答案**：shared。

本题正确项是「shared」。声明为 shared 的模块构建为 HSP，随宿主应用一起安装并只在应用内共享，可以避免同一份逻辑被重复打包进多个能力包。entry 是承载主入口的能力包，feature 是可按需分发的特性能力包，两者都不是共享库语义；atomicService 对应免安装的元服务形态，用来承载轻交互入口，与代码共享没有对应关系。

**教材衔接：题号 3** — 项目级 `build-profile.json5` 中 products 数组的主要作用是？

**参考答案**：定义产物与目标 SDK 配置。

本题正确项是「定义产物与目标 SDK 配置」。每个 product 描述一套可交付形态，包含名称、引用的签名配置、运行时系统标识与编译兼容的 SDK 版本，构建时按 product 选择产物。三方依赖登记在包描述文件里，页面路由写在模块清单的 pages 字段，证书与密钥材料属于 signingConfigs 的 material 部分，这三处都不归 products 管。

**教材衔接：题号 4** — 调试签名与发布签名必须使用不同材料，根本原因是？

**参考答案**：两套证书的用途与信任链不同。

本题正确项是「两套证书的用途与信任链不同」。调试证书由开发工具代申请、Profile 限定可调试的设备列表，用于真机联调；发布证书需在开发者后台按主体申请，Profile 覆盖上架分发场景，两者不可互换。调试证书恰恰可以安装到已登记的调试真机，签名与包名必须一致否则安装被拒，上架时市场会严格校验发布签名而不只是包名。

**教材衔接：题号 5** — 关于下面这段工程配置片段，哪一项说法正确？
// build-profile.json5 片段
{
  "products": [{
    "name": "default",
    "signingConfig": "default",
    "runtimeOS": "HarmonyOS",
    "compileSdkVersion": "5.0.0(12)"
  }]
}

**参考答案**：JSON5 允许注释与尾逗号。

本题正确项是「JSON5 允许注释与尾逗号」。鸿蒙的这几个配置文件都是 JSON5 方言，首行注释与数组尾逗号都属合法写法，这也是它们以 json5 结尾的原因。`runtimeOS` 用于区分产物运行的系统分支，去掉会改变默认口径，不应随意省略；一个工程可以声明多个 product 覆盖不同设备与渠道；signingConfig 只是引用名，与 product 名相同是团队习惯而非语法约束。

## 考点精讲

**教材衔接：高频考点**

1. 三层配置的责任边界：AppScope 管应用、module.json5 管能力与权限、build-profile 管产物与签名。
2. 模块类型四分法 entry / feature / shared / atomicService 与对应产物语义。
3. 调试与发布签名材料的组成与不可互换性。
4. Local Emulator 的能力边界，以及哪些验证必须回到真机。

**教材衔接：命题规律**

- 喜欢拿「配置写在哪一层」出题，正确项常带「主要作用」「根本原因」这类限定，排除只描述现象的选项。
- 排错题给一段看似合法的目录或字段组合，考的是模块类型与共享语义是否匹配。
- 代码题贴一小段配置文件，答案往往落在语法方言或字段语义上，而不是取值大小。

**教材衔接：常见考点**

问：DevEco Studio 的 Local Emulator 无法覆盖下列哪项验证？
答：真实设备的分布式组网。

问：想让一个模块只在本应用内被其他模块共享，`module.json5` 中 type 应设为？
答：shared。

问：项目级 `build-profile.json5` 中 products 数组的主要作用是？
答：定义产物与目标 SDK 配置。

问：调试签名与发布签名必须使用不同材料，根本原因是？
答：两套证书的用途与信任链不同。

问：关于下面这段工程配置片段，哪一项说法正确？
// build-profile.json5 片段
{
  "products": [{
    "name": "default",
    "signingConfig": "default",
    "runtimeOS": "HarmonyOS",
    "compileSdkVersion": "5.0.0(12)"
  }]
}
答：JSON5 允许注释与尾逗号。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| DevEco Studio | 鸿蒙官方 IDE，集成语法检查、预览器、模拟器与构建签名向导。 |
| hvigor | 声明式构建引擎，把源码、资源与依赖编排成 HAP 与 HSP。 |
| ohpm | 包管理器，管理 HAR 与三方依赖，锁文件为 oh-package-lock.json5。 |
| AppScope | 应用级作用域，存放 bundleName、版本与应用图标名称资源。 |
| module.json5 | 模块清单，声明模块类型、能力、权限、路由与目标设备类型。 |
| signingConfigs | 签名材料配置，引用密钥库、证书、Profile 与密钥别名。 |
| Local Emulator | 本机设备镜像，能验布局与交互，不能验真实组网与部分硬件链路。 |
| HAP / HSP / HAR | 能力包、应用内共享包与编译期静态库三种产物形态。 |

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
- [DevEco Studio 下载与安装](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-software-install)
- [DevEco Studio 模拟器使用指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-tools-emulator)
- [应用配置资源与 AppScope 说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-configuration-file)
- [签署应用包与证书管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)
