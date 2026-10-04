# 第三方组件与许可清单

适用范围：`com.codelearn.study` 1.1.0+2。版本号取自 `pubspec.lock`；
更新依赖后请重新核对本表（见文末“如何重新生成清单”）。

## 一、Flutter 依赖（Dart / 原生插件）

| 组件 | 版本 | 许可 | 用途 |
| --- | --- | --- | --- |
| Flutter SDK / Dart SDK | 随构建环境 | BSD-3-Clause | 应用框架与渲染引擎 |
| provider | 6.1.5+1 | MIT | 状态管理（ChangeNotifier 封装） |
| hive | 2.2.3 | Apache-2.0 | 本地键值数据库 |
| hive_flutter | 1.1.0 | Apache-2.0 | Hive 的 Flutter 初始化支持 |
| path_provider | 2.1.6 | BSD-3-Clause | 获取应用私有目录 |
| flutter_markdown | 0.7.7+1 | BSD-3-Clause | 教程 Markdown 渲染 |
| markdown | 7.3.1 | BSD-3-Clause | Markdown 解析 |
| flutter_highlight | 0.7.0 | MIT | 代码块语法高亮组件 |
| highlight | 0.7.0 | MIT | 语法高亮引擎 |
| crypto | 3.0.7 | BSD-3-Clause | MD5 / SHA-1 / SHA-256 工具箱 |
| flutter_local_notifications | 19.5.0 | BSD-3-Clause | 本地复习提醒通知 |
| timezone | 0.10.1 | BSD-3-Clause | 通知使用的时区数据库 |
| flutter_timezone | 5.1.1 | Apache-2.0 | 读取设备本地时区 |
| cupertino_icons | 1.0.9 | MIT | 图标字体 |
| Roboto（Flutter 内置字体） | 随 Flutter SDK | Apache-2.0 | 界面默认字体 |

## 二、安装包内置的代码沙箱运行时

| 组件 | 版本 | 许可 | 说明 |
| --- | --- | --- | --- |
| Brython | 3.14.0 | BSD-3-Clause | 浏览器内 Python 运行时（`assets/sandbox/brython/`） |
| Fengari | 随 bundle | MIT | 浏览器内 Lua 5.3 运行时，含 Lua 官方版权声明 |
| sql.js（SQLite WASM） | 随 bundle | MIT（SQLite 为 Public Domain） | 浏览器内 SQL 执行引擎 |
| Sucrase | 随 bundle | MIT | TypeScript → JavaScript 转译 |

以上运行时全部打包进 APK，不联网加载；其版权与许可声明保留在各自的 bundle 头部注释中。

## 三、课程内容参考来源与署名

课程正文为面向本应用重新撰写的内容，代码示例为自写示例；知识点结构与部分主题参考：

| 来源 | 许可 | 参考范围 |
| --- | --- | --- |
| [developer-roadmap](https://github.com/kamranahmedse/developer-roadmap) | CC BY-NC-SA 4.0 | Python / C++ / Java / JavaScript / AI / AI Agent 学习路线结构 |
| [TheAlgorithms](https://github.com/TheAlgorithms) | MIT | 算法与数据结构主题组织方式 |
| [Microsoft Learn .NET 文档](https://learn.microsoft.com/dotnet/) | CC BY 4.0 | C#、ASP.NET Core 主题 |

> 上架前请确认目标商店与分发方式符合上述来源的许可条款（其中 CC BY-NC-SA 4.0
> 含“非商业”限制）。应用内「我的 → 参考资料与许可」保留了同样的署名说明。

## 四、应用内查看完整许可

Flutter 构建时会自动收集所有 package 的 `LICENSE` 文件并写入 `NOTICES`，
运行时可调用 `showLicensePage()` / `LicenseRegistry` 查看完整原文。
如果商店审核要求“应用内可查看开源许可”，在“关于/我的”页接入 `showLicensePage` 即可，
无需手工维护长文本。

## 五、如何重新生成清单

```bash
# 1. 查看直接与间接依赖
flutter pub deps --style=compact

# 2. 读取锁定版本（本表版本列来源）
flutter pub deps --json

# 3. 每个依赖的许可原文位于 pub 缓存：
#    %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<package>-<version>\LICENSE
#    ~/.pub-cache/hosted/pub.dev/<package>-<version>/LICENSE
```

新增依赖时：把组件名、锁定版本、许可、用途补进上表，并确认许可允许商店分发
（本应用当前依赖均为 MIT / BSD-3-Clause / Apache-2.0）。

## 六、提交前检查

- [ ] 本表版本与 `pubspec.lock` 一致；
- [ ] 新增依赖没有 GPL / AGPL 等与当前分发方式冲突的许可；
- [ ] 沙箱运行时 bundle 头部的版权注释未被裁剪；
- [ ] 应用内可查看完整开源许可（`showLicensePage`）；
- [ ] 内容参考来源的署名与许可说明仍与实际内容一致。
