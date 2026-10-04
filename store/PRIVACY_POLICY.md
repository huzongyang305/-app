# 隐私政策 / Privacy Policy

| 项目 | 内容 |
| --- | --- |
| 应用名称 | 计算机与编程学习（CS & Coding） |
| 包名 | `com.codelearn.study` |
| 开发者 | 【待填写：开发者或公司全称】 |
| 隐私联系邮箱 | 【待填写：隐私事务联系邮箱】 |
| 最后更新 | 2026-10-04 |
| 生效日期 | 2026-10-04 |

> **发布前必读**：本文件是上架用模板，所有 `【待填写：…】` 占位符必须在正式提交商店前替换为
> 真实信息，不得原样提交。Google Play 要求隐私政策通过可公开访问的网址提供，可直接部署
> `store/privacy_policy.html` 到任意静态托管（GitHub Pages、对象存储等），并把该网址填入
> 商店后台的“隐私政策”字段。

## 一、摘要

- 本应用是**纯离线**的学习应用：不注册账号、不联网、不收集、不上传、不共享任何个人信息。
- Release 版 APK / AAB **未声明** `android.permission.INTERNET`，应用本身不具备联网能力。
- 不包含广告、统计分析、崩溃上报、用户画像或任何第三方追踪 SDK。
- 学习进度、收藏、笔记、测验成绩、设置项只保存在设备本地的 Hive 数据库中。
- 备份导出、备份分享、内容包导入都只在用户主动操作时，通过 Android 系统文件选择器完成；
  取消操作不会读取或写出任何文件。

## 二、我们收集哪些信息

**不收集任何个人信息。** 具体而言：

1. 不收集姓名、邮箱、电话、地址、账号、密码等身份信息；
2. 不收集设备标识符（IMEI、Android ID、广告 ID 等）；
3. 不收集位置、通讯录、相册、麦克风、摄像头、短信、通话记录等敏感数据；
4. 不收集学习行为用于广告或分析，应用内没有埋点上报代码。

## 三、应用在本地保存哪些数据

以下数据仅写入应用私有目录（Android 的 `/data/data/com.codelearn.study/`），其他应用无法读取：

| 数据 | 说明 | 位置 |
| --- | --- | --- |
| 学习进度 | 已学知识点、学习时长、连续学习天数 | Hive 盒子 `app_data` |
| 测验成绩 | 每课得分、正确率、错题记录 | Hive 盒子 `app_data` |
| 收藏与笔记 | 用户收藏的知识点、手写笔记 | Hive 盒子 `app_data` |
| 设置项 | 深色模式、语言、提醒时间等偏好 | Hive 盒子 `app_data` |
| 离线内容包 | 用户主动导入的 JSON 课程包 | Hive 盒子 `app_data` |
| 备份文件 | 仅在用户主动导出/分享时生成 | 用户选择的位置或应用缓存 |

卸载应用或在系统“应用信息 → 存储”中执行“清除数据”，以上内容会全部删除。

## 四、Android 权限说明

应用只声明以下权限，全部用于本地功能，不涉及数据上传：

| 权限 | 用途 | 触发时机 |
| --- | --- | --- |
| `android.permission.POST_NOTIFICATIONS` | 发送“复习提醒”本地通知 | 用户开启提醒开关时由系统弹窗询问，可随时拒绝 |
| `android.permission.RECEIVE_BOOT_COMPLETED` | 手机重启后恢复已安排的本地提醒 | 系统重启时，仅重新注册本地通知计划 |

文件读取与写入不使用存储权限：导出备份、导入备份、导入内容包全部通过 Android
Storage Access Framework（系统文件选择器）完成，应用只能访问用户当次明确选择的文件。
分享备份时使用 `FileProvider` 生成临时只读 URI，授权在分享结束后自动失效。

## 五、代码沙箱

「工具 → 代码沙箱」在 Android WebView 中离线执行用户输入或内置示例代码：

- 页面与运行时（Brython、Sucrase、Fengari、sql.js 等）全部随安装包打包；
- WebView 已关闭网络加载，并禁止 `file://` 页面读取其他本地文件；
- 代码及其输出只存在于内存和临时缓存，执行结束或超时后立即销毁并删除临时页面；
- 沙箱不会上传代码，也不会把代码写入学习数据。

## 六、儿童隐私

应用内容为面向大众的计算机与编程教育内容，不针对 13 岁以下儿童定向收集任何数据。
由于应用不收集个人信息，也不包含广告或社交功能，家长可以放心让未成年人在离线状态下使用。

## 七、第三方组件

应用使用了开源框架与运行库（Flutter、Provider、Hive、flutter_markdown、Brython、Fengari、
sql.js、Sucrase 等），它们只在设备本地运行，不会把数据发送给其作者。
完整清单与许可协议见 `store/THIRD_PARTY_LICENSES.md`；应用内“关于 → 开源许可”
可查看 Flutter 自动生成的完整许可文本。

## 八、数据保留与删除

- 数据保留多久由用户决定：应用不上传数据，因此开发者不持有任何用户数据副本。
- 删除方式一：Android 系统“设置 → 应用 → 计算机与编程学习 → 存储 → 清除数据”；
- 删除方式二：卸载应用（会同时删除应用私有目录中的全部学习数据）；
- 用户主动导出的备份文件保存在用户自己选择的位置，需要用户自行删除。
- 由于开发者不收集数据，无需向开发者提交数据删除申请；如对本地数据有疑问，可通过
  上面的隐私联系邮箱咨询。

## 九、政策变更

如果未来版本新增联网、账号或统计功能，本政策会同步更新，并在应用内和商店页面提示。
继续使用新版本即表示接受更新后的政策。

## 十、联系方式

隐私相关问题请联系：**【待填写：隐私事务联系邮箱】**。

---

# English Summary

This app (`com.codelearn.study`) is a fully offline computer-science learning app.

- We do **not** collect, transmit, or share any personal data. No accounts, no ads,
  no analytics or tracking SDKs.
- The release build does not declare the `android.permission.INTERNET` permission.
- Progress, favorites, notes, quiz results and settings are stored only in the app's
  private Hive database on your device.
- `POST_NOTIFICATIONS` is used for optional local study reminders.
  `RECEIVE_BOOT_COMPLETED` re-registers those local reminders after a reboot.
- File import/export uses the Android Storage Access Framework and only touches files
  you explicitly select. Backup sharing uses a temporary read-only `FileProvider` URI.
- The in-app code sandbox runs entirely inside an offline WebView with network access
  disabled; code and output are destroyed after execution.
- Delete all local data at any time via Android Settings → Apps → Storage → Clear data,
  or by uninstalling the app.

Developer / contact: **【待填写：开发者或公司全称 / contact email】**

Last updated: 2026-10-04
