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
