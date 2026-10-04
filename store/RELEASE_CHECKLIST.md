# 发布检查清单

当前目标版本：`1.1.0+2`（`pubspec.yaml` 是唯一版本来源）。
每一项都通过后才上传商店；未完成项必须写明原因与负责人。

## 一、版本与签名

- [ ] `pubspec.yaml` 的 `version:` 已递增，`+` 后的构建号严格大于上一版（当前 `1.1.0+2`）；
- [ ] `android/key.properties` 与 `android/keystore/code_learn_release.jks` 存在且已单独备份；
- [ ] 确认本机构建使用 release 签名（未回退到 debug 签名，见下方 `apksigner` 输出）；
- [ ] 发布说明（Release notes）已写清：新增功能、内容扩充、修复的问题。

## 二、质量门禁（必须全部通过）

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze --no-pub
flutter test --no-pub
dart tool/check_brand_assets.dart
dart tool/verify_sandbox_harness.dart
```

- [ ] 静态检查 0 issue；
- [ ] 全量测试全部通过（含内容完整性、端到端流程、金图视觉回归、P5A 发布测试）；
- [ ] 金图若更新，已人工目视确认不是裁剪/溢出/错位；
- [ ] 品牌资源自检通过（图标、启动页、功能图尺寸与不透明区域）；
- [ ] 沙箱离线校验通过（6 种语言用例，且未产生额外网络请求）。

## 三、功能验收（真机 / 模拟器）

- [ ] 冷启动进入首页无崩溃，断网状态下可正常浏览；
- [ ] 选分类 → 看教程 → 做测验 → 看进度 全流程可完成；
- [ ] 代码块可复制，语法高亮正常；
- [ ] 测验答对/答错即时反馈与解析正确；
- [ ] 收藏、笔记、错题本、复习队列数据在重启后仍保留；
- [ ] 深色模式、中英文切换、字号放大后无文字溢出；
- [ ] 复习提醒：开启后能收到本地通知，重启手机后提醒计划仍在；
- [ ] 备份：导出到系统“另存为”→ 清除数据 → 从备份恢复，数据完整；
- [ ] 旧版备份：`code_learn_backup.json` 仍可导入（“从旧版应用目录导入”入口）；
- [ ] 加密备份：设置密码导出后，用错误密码导入会失败且不会破坏现有数据；
- [ ] 离线内容包：导入/移除正常，移除后恢复内置课程；
- [ ] 存储迁移：从旧版本升级（覆盖安装）后进度、错题、索引完整，无数据清空。

## 四、商店合规材料

- [ ] 隐私政策已部署到公开网址并填入商店后台（内容取自 `store/privacy_policy.html`）；
- [ ] `store/PRIVACY_POLICY.md` 中的 `【待填写】` 占位符已全部替换为真实主体与邮箱；
- [ ] 数据安全表单已按 `store/DATA_SAFETY.md` 逐项提交；
- [ ] 内容分级问卷已按 `store/CONTENT_RATING.md` 提交并取得分级；
- [ ] 第三方许可清单已按 `store/THIRD_PARTY_LICENSES.md` 复核，应用内可查看开源许可；
- [ ] 商店文案与素材已按 `store/STORE_LISTING.md` 准备（图标、功能图、截图）；
- [ ] 目标 API 级别符合商店当年要求（Flutter 稳定版默认 `targetSdk`，构建日志中确认）。

## 五、构建与产物校验

```bash
# 不要用 --no-pub：release 构建需要重新生成插件注册文件，
# 否则会残留 debug 模式的 integration_test 插件引用而编译失败。
flutter clean
flutter pub get
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --split-per-abi

# APK 体积门禁（第二个参数为上限 MB）
dart tool/check_apk_size.dart build/app/outputs/flutter-apk/app-release.apk 90

# 签名与证书校验
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk

# 产物校验和（写入发布记录与 README）
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256
Get-FileHash build/app/outputs/bundle/release/app-release.aab -Algorithm SHA256
```

- [ ] APK 与 AAB 均构建成功，无 KGP / 资源警告；
- [ ] APK 体积未增长到门禁值以上（当前约 80 MB，门禁 90 MB）；
- [ ] `apksigner` 输出 v2 与 v3 均为 `true`，且证书为发布证书（非 Android Debug）；
- [ ] APK 中确认无 `android.permission.INTERNET`（`aapt dump permissions`）；
- [ ] APK 中 `versionName` / `versionCode` 与 `pubspec.yaml` 一致；
- [ ] SHA-256 已记录到 `README.md` 的发布章节。

## 六、设备矩阵

| 设备 | 系统 | 重点验证 |
| --- | --- | --- |
| Android 模拟器 API 30 | Android 11 | 旧系统文件选择器、通知权限兼容 |
| Android 模拟器 API 33 | Android 13 | 通知运行时权限、主题模式 |
| Android 模拟器 API 35 | Android 15 | 最新系统行为、边到边布局、预测性返回 |
| 真机（手机竖屏） | 主流品牌 | 完整学习流程、备份导入导出、离线可用 |
| 平板 / 横屏 | 任一 | 双栏导航、横屏答题布局、无文字溢出 |

CI 已在 `.github/workflows/android-device.yml` 中配置 API 30 / 33 / 35 三档模拟器冒烟；
`.github/workflows/flutter-ci.yml` 负责静态检查、全量测试、品牌检查、沙箱校验与 APK 体积门禁。

## 七、上传与发布

- [ ] Play Console 创建新版本（内部测试轨道先行）；
- [ ] 上传 AAB，确认 Play 预发布报告无崩溃、无兼容性阻断；
- [ ] 内部测试通过后进入封闭测试 / 分阶段发布（建议 10% → 50% → 100%）；
- [ ] 发布说明与商店文案同步更新；

## 八、发布后

- [ ] 查看 Play Console「Android Vitals」崩溃率与 ANR 率（应用无自定义上报 SDK，以商店数据为准）；
- [ ] 收集用户反馈中的内容错误，记录到内容复核清单；
- [ ] 出现严重问题时在 Play Console 暂停分阶段发布，修复后提升构建号重新提交；
- [ ] 下一版前重新执行「二、质量门禁」与「五、构建与产物校验」。

## 九、回滚预案

- 分阶段发布期间：在 Play Console 暂停发布（Halt rollout），已安装用户不受影响；
- 已全量发布：只能提交更高 `versionCode` 的修复版本，不能回退版本号；
- 数据层：`StorageMigrationService` 遇到高于当前客户端的数据版本会进入只读错误页，
  不会清空用户数据；回滚前请勿手工修改 Hive 数据格式。
- 备份层：新版本导出的备份可被旧版本导入（无加密时）；加密备份需要旧版本同样支持
  `CLB1:` 信封格式。
