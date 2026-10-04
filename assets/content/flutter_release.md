# 实战：Flutter 打包发布 Android

![实战：Flutter 打包发布 Android](images/category_flutter_release.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「实战：Flutter 打包发布 Android」解决了什么问题，而不是只背术语。
- 能说清 「Flutter」、「发布」、「签名」、「混淆」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「移动开发」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：正式签名、按 ABI 拆分、混淆与符号保留、发布清单。

## 前置知识

- 先完成上一课《Flutter 状态管理与性能》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：Flutter、发布、签名。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 从调试到发布

| 阶段 | 命令 | 关注点 |
| --- | --- | --- |
| 静态检查 | `flutter analyze` | 零 error，info 尽量清零 |
| 测试 | `flutter test` | 单元 + 组件 + 端到端 |
| 构建 | `flutter build apk --release` 或 `--appbundle` | 签名、混淆、ABI |
| 产物校验 | `flutter build apk --analyze-size` | 各模块体积占比 |

## 签名配置

关键：**不要用调试签名发布**。生成 keystore（`keytool -genkey`），把 `key.properties` 放在仓库外并在 `.gitignore` 中排除，`build.gradle.kts` 里读取它配置 `signingConfigs.release`。keystore 与密码丢失后将无法更新已上架应用。

## 体积优化

1. 用 `--split-per-abi` 或 App Bundle 按 ABI 拆分，避免把三种架构都打进一个包。
2. `--tree-shake-icons` 剔除未用图标字体（默认开启）。
3. 压缩图片资源，优先用 WebP；避免打包未使用的字体。
4. 用 `--analyze-size` 找出体积大头，再针对性处理（通常是大图或冗余依赖）。

## 混淆与符号

```text
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

混淆能提高逆向成本，但崩溃堆栈会变成符号，**必须保存 split-debug-info 产物**，否则线上崩溃无法定位（用 `flutter symbolize` 还原）。

## 发布检查清单

1. 版本号与构建号递增（versionName/versionCode），否则商店拒收。
2. 权限最小化，`AndroidManifest.xml` 中删除不需要的权限。
3. targetSdk 跟上官方的商店要求（过低会被下架或限制）。
4. 应用图标与启动页替换模板资源。
5. 真机验证：冷启动、深色模式、横竖屏、低内存与断网场景。
6. 接入崩溃上报与版本分布统计（可选但强烈建议）。

## 签名配置与体积优化实操

**签名配置四步**：① `keytool -genkey -v -keystore release.jks -keyalg RSA -validity 10000 -alias app` 生成密钥库；② 在项目外创建 `key.properties`（storeFile/storePassword/keyAlias/keyPassword）并写入 .gitignore；③ 在 `android/app/build.gradle.kts` 读取该文件配置 signingConfigs.release；④ 在 buildTypes.release 中引用它。**密钥库与密码必须离线备份**，丢失后无法再更新已上架应用。

**体积优化前后参考**（同一 Flutter 项目）：

| 配置 | 体积变化 |
| --- | --- |
| 默认 release（含 arm64+armeabi+x64） | 约 55 MB |
| `--split-per-abi` 后单包 | 每个约 20~22 MB |
| `--tree-shake-icons`（默认开启） | 图标字体从 1.6 MB 降到约 7 KB |
| 移除未用字体与大图（WebP 化） | 视资源而定，常见可再降 10%~30% |

用 `flutter build apk --analyze-size` 查看各模块占比，优先处理体积最大的资源；App Bundle（`--appbundle`）让商店按设备下发，是发布到 Google Play 的首选形式。

## 本课小结
Flutter 发布的关键是**正式签名 + 按 ABI 拆分 + 混淆并保留符号 + 版本与权限合规**；跑通这四步，产物才算能上架。

<!-- appendix:v1 -->

## 发布清单速查

| 项 | 要求 |
| --- | --- |
| 版本号 | `pubspec.yaml` 的 `version: 1.0.0+1`，加号后为构建号 |
| 签名 | 正式 keystore，密钥与口令不入仓库 |
| 混淆 | `--obfuscate --split-debug-info=build/symbols` |
| 体积 | 按 ABI 拆分或使用 app bundle |
| 图标与启动图 | 各分辨率齐全，避免拉伸 |
| 权限 | 只声明真正需要的权限并写清用途 |
| 隐私 | 提供隐私政策与数据收集说明 |
| 目标 SDK | 符合商店最新要求 |

## 构建命令速查

```bash
# 产物类型
flutter build apk --release                          # 单个 APK
flutter build apk --release --split-per-abi          # 按 ABI 拆分，体积更小
flutter build appbundle --release                    # 上架 Google Play 推荐

# 混淆与符号保留（崩溃堆栈需用符号还原）
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols

# 还原混淆堆栈
flutter symbolize -i stack.txt -d build/symbols

# 指定版本号与构建号
flutter build apk --release --build-name=1.4.0 --build-number=42
```

```yaml
# android/app/build.gradle.kts 关键片段
android {
    defaultConfig {
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

## 发布前自检速查

| 检查项 | 方法 |
| --- | --- |
| 无调试日志泄漏 | 全局搜索 `print`、`debugPrint` 与测试域名 |
| 密钥未入库 | 搜索仓库与产物中的密钥串 |
| 权限最小化 | 对照 `AndroidManifest.xml` 逐条确认 |
| 崩溃堆栈可还原 | 用符号文件试还原一次 |
| 首屏与冷启动 | 真机测冷启动耗时 |
| 弱网与离线 | 断网、弱网、切后台恢复 |
| 机型覆盖 | 至少覆盖低端机与高刷屏 |
| 升级路径 | 从旧版本升级后数据完整 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 debug 签名发布 | 商店拒绝或无法升级 | 用正式 keystore 并妥善备份 |
| keystore 丢失 | 无法更新已发布应用 | 备份密钥与口令到安全位置 |
| 混淆后不保留符号 | 崩溃堆栈无法定位 | `--split-debug-info` 并存档符号 |
| 只出一个大 APK | 用户下载体积大 | `--split-per-abi` 或 app bundle |
| 忘记改构建号 | 商店拒绝上传 | 每次发布递增构建号 |
| 权限声明过多 | 商店审核与用户信任下降 | 最小权限并说明用途 |
| 测试环境地址打进包 | 生产连错后端 | 用编译期变量区分环境 |
| 未测升级路径 | 老用户升级后崩溃 | 保留旧版本做升级测试 |
| 只在大屏机型测试 | 小屏溢出 | 覆盖小屏与折叠屏 |
| 不配置隐私说明 | 审核被拒 | 提供隐私政策与数据清单 |

## 自测清单

- [ ] 正式签名密钥已生成、备份且未入库。
- [ ] 发布开启混淆并归档符号文件。
- [ ] 按 ABI 拆分或使用 app bundle 控制体积。
- [ ] 权限最小化，环境地址由编译期注入。
- [ ] 完成弱网、低端机与升级路径测试。

<!-- appendix:v3 -->

## 零基础详解：Flutter 打包与发布

### 一句话说清它是什么

发布 Flutter 应用要做四件事：**签名、定版本、减体积、留符号**。
前三件决定能不能上架，最后一件决定线上崩溃能不能查。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| keystore | 公章 | 商店靠它确认是你发布的 |
| applicationId | 身份证号 | 上架后不能改 |
| versionName | 对外版本号 | 用户看到的 1.2.0 |
| versionCode | 内部序号 | 每次上架必须递增 |
| debug symbols | 病历存档 | 还原被混淆的崩溃堆栈 |

### 第一步：生成签名

```bash
keytool -genkeypair -v \
  -keystore ~/keys/release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release
```

```properties
# android/key.properties（不要提交到 Git）
storePassword=你的密码
keyPassword=你的密码
keyAlias=release
storeFile=/abs/path/release.jks
```

```kotlin
// android/app/build.gradle.kts
val keystoreProperties = java.util.Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

**keystore 与密码必须备份**：丢失后无法更新已上架的应用。

### 第二步：版本号

```yaml
# pubspec.yaml
version: 1.2.0+12        # versionName+versionCode
```

```bash
flutter build appbundle --release --build-name=1.2.0 --build-number=12
```

`versionCode` 每次上架都要比上一版大，否则商店会拒绝。

### 第三步：减小体积

```bash
# 按 CPU 架构拆分 APK，单包体积显著下降
flutter build apk --release --split-per-abi

# 或发布 AAB，由商店按设备下发
flutter build appbundle --release

# 查看各部分的体积构成
flutter build apk --analyze-size
```

| 手段 | 效果 |
| --- | --- |
| `--split-per-abi` | 每个架构一个包，用户只下需要的 |
| AAB | 商店动态下发，最小化下载体积 |
| tree-shake icons | 默认开启，只保留用到的图标 |
| 图片与字体裁剪 | 去掉未使用资源 |
| 移除调试依赖 | 生产不带 dev 包 |

### 第四步：保留崩溃符号

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols
```

**务必把 `build/symbols` 归档保存**，否则线上崩溃只能看到 `a.b.c` 这类无意义符号。

```bash
# 还原堆栈时使用
flutter symbolize -i crash.txt -d build/symbols/app.android-arm64.symbols
```

### 完整发布流水线

```bash
#!/usr/bin/env bash
set -euo pipefail

flutter clean
flutter pub get
flutter analyze
flutter test

flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --build-name="${VERSION:?需要 VERSION}" \
  --build-number="${BUILD_NUMBER:?需要 BUILD_NUMBER}"

echo "产物：build/app/outputs/bundle/release/app-release.aab"
echo "符号：build/symbols（请归档）"
```

### 上架前检查清单

| 检查项 | 说明 |
| --- | --- |
| applicationId 唯一 | 上架后不可更改 |
| 版本号递增 | versionCode 必须大于上一版 |
| 正式签名 | 不能用调试签名 |
| 权限最小化 | 删掉不需要的权限 |
| 隐私政策 | 收集数据必须有说明 |
| 图标与截图齐全 | 各尺寸都要提供 |
| 目标 SDK 达标 | 商店有最低要求 |
| 混淆后自测 | 反射相关代码可能被裁掉 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| keystore 丢失 | 无法更新应用 | 多处离线备份 |
| key.properties 提交到 Git | 密钥泄露 | 加进 `.gitignore` |
| 忘了递增 versionCode | 上架被拒 | CI 里自动递增 |
| 混淆后崩溃查不了 | 堆栈无意义 | 保留并归档 symbols |
| 用调试签名上架 | 商店拒绝 | 配置 release signingConfig |
| 只测 APK 不测 AAB | 上架后才出问题 | 用 bundletool 本地验证 |
| 权限申请过多 | 审核被拒 | 只申请真正需要的 |
| 混淆裁掉反射用类 | 运行时崩溃 | 配置 keep 规则并自测 |

### 学完自测

- [ ] 能说出 keystore 丢失的后果。
- [ ] 知道 `versionName` 与 `versionCode` 的分工。
- [ ] 能说出三种减小体积的手段。
- [ ] 知道 `--split-debug-info` 产物要做什么。
- [ ] 能列出上架前至少五项检查。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「Flutter、发布、签名」完成复述、实验和交付，每个结果都要能被别人检查。

先做一个最小 Widget，再切换状态与约束，最后在窄屏和深色模式下验证布局。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「实战：Flutter 打包发布 Android」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「发布」是什么关系？

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
- 至少覆盖「Flutter」和「发布」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 静态检查 | `flutter analyze` | 无分析问题 |
| 运行测试 | `flutter test` | 测试全部通过 |
| 构建 | `flutter build apk --release` | 成功生成 APK |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Flutter Release

**Summary:** Signing, ABI splits, obfuscation and release checklist.

**Category:** Mobile Development  
**Level:** 高级  
**Key terms:** Flutter, 发布, 签名, 混淆, 体积优化

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Flutter 3.x / Dart 3.x
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Flutter、发布、签名、混淆、体积优化
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：实战：Flutter 打包发布 Android

### 核心场景

正式签名、按 ABI 拆分、混淆与符号保留、发布清单。 项目目标是把「Flutter、发布、签名、混淆、体积优化」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | Flutter、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。

<!-- project-delivery:v1 -->

## 项目交付物

### 建议仓库结构

```text
lib/
  models/
  screens/
  services/
test/
pubspec.yaml
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "flutter_release",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「Flutter、发布、签名」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter 官方文档](https://docs.flutter.dev/) | 框架、组件与发布流程 |
| [Dart 官方文档](https://dart.dev/guides) | 语言、异步与工具链 |

> 本课主题：正式签名、按 ABI 拆分、混淆与符号保留、发布清单。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

