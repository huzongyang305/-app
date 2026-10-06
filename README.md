# 计算机与编程学习

一个完全离线的 Flutter 学习类 App：内置教程、代码示例与测验，学习进度、收藏和笔记都保存在手机本地，不需要任何后端服务。

## 功能

- **28 个分类、542 篇教程、3086 道测验题**，全部内置在安装包里，断网也能用
- **P0/P1/P2 内容扩容**：新增网络抓包、数据库调优、操作系统并发、安全攻防、算法工程、DevOps、移动离线 App、数据 ETL 8 门项目实战；全部课程补齐可运行练习、故障现场、特殊题型、版本复核与参考资料
- 首页分类导航 + 关键词搜索：倒排索引 + 中文二元组 + 拼音 / 首字母 + 同义词，支持未学 / 收藏 / 错题与分类筛选、搜索历史与命中高亮
- 每篇教程都是 Markdown 图文正文：学习支架、示意图、可复制的高亮代码块、常见坑与练习
- 每个知识点配 3~5 道测验题，支持单选、多选、填空、排序、代码输出与排错；答完立即判分并给出解析，另有模拟考试与错题本
- **代码阅读题（P0）**：20 种语言的读代码判断题，按课程自动生成，覆盖 485 门课程；与静态题库合并成动态试卷
- 学习进度、测验正确率、连续签到、成就徽章
- **学习时长统计（P1）**：进入教程自动计时，按天累计学习分钟数，在统计页展示近 7 天柱状图与日均时长
- **学习路径（P1）**：选定「我的学习目标」，目标路线置顶高亮；提供入学测评、推荐起点、80% 检查点自测与动态补课清单
- **复习队列（1.3）**：SM-2 风格间隔重复，支持按分类筛选、单次场次时长（15/30/45/60 分钟）、未来 7 天复习日历与主动提前复习；答错的题会自动提前排入队列
- **每日学习目标（1.3）**：首页展示今日已学分钟 / 目标进度环，达成后本地通知祝贺；「我的」里可选 10 / 20 / 30 / 60 分钟目标
- **考试增强（1.3）**：模拟考试支持难度与题型筛选、自定义题量、限时 / 练习双模式、断点续考与交卷后逐题回顾
- **学习可视化（1.3）**：12 周学习热力图、按语言 / 课程的掌握度排行、薄弱点与下一步建议，学习报告可一键导出或分享
- **每日一题（1.3）**：按日期从本地题库确定性抽题，通知带「去作答」操作按钮，点击直接进入当日题目；答错自动写入错题本
- **闪卡模式（1.3）**：题库与笔记自动生成卡片，点击翻面、左右滑动自评（忘记 / 模糊 / 记得），结果直接进入间隔复习
- **错题专项（1.3）**：错题本展示消灭率（已消灭 / 曾答错）、支持一键错题专项重练，答对即移出错题本
- **自动备份（1.3）**：授权一个 SAF 文件夹后可每天 / 每周自动写入备份，自动保留最近 3 / 5 / 10 份并清理旧文件，全程离线
- 收藏知识点、写本地笔记；笔记支持标签、跨课程搜索、Markdown 预览、编辑删除与一键导出到剪贴板
- **代码块增强（P1）**：全屏阅读、一键复制、系统分享（不可用时自动回退复制）、字号调节与自动换行开关，设置会持久化
- **多语言代码沙箱（1.3.2）**：JavaScript / TypeScript / Python / Lua / SQL / JSON / Scheme / Markdown / 正则 / XML / CSV / C / C++ / Bash 共 13 种语言，运行时全部内置、完全离线；支持标准输入、示例库、片段收藏、全屏编辑、运行中停止、代码自动缩进与括号补全；教程代码块可一键「在沙箱打开」
- **离线朗读（P2）**：教程页可用系统内置 TTS 朗读正文，代码块自动折叠成简短提示；没有可用语音引擎时给出明确提示，全程不联网
- **交互式演示（P2）**：二分查找、冒泡 / 插入 / 选择排序、栈与队列的分步动画，以及 HTTP 请求链路、数据库事务隔离的时间线演示，自动尊重系统「减少动画」设置
- **英文正文（P2）**：55 篇课程提供完整英文正文，其余课程提供英文概览与英文学习指南；语言开关会显示当前完整英文覆盖数量
- **响应式与无障碍**：手机底部导航、平板 NavigationRail、教程分栏和横屏答题布局；关键卡片与选项带 TalkBack 语义，答题结果用图标 + 文字双重标注（不依赖红绿颜色），支持 2 倍系统字号，可开启“减少动画”
- **逐课内容治理**：542 篇课程均带官方参考来源、最后复核和下次复核日期；全部课程图片统一为 WebP
- **逐课考点精讲**：542 篇教程都有一节与当前题库同步的「考点精讲」，把每道测验题还原成判断过程，并附迁移检查与复习清单
- **离线内容包（P1）**：可从系统文件选择器导入 JSON 内容包，覆盖、追加或 delta 增量更新课程并立即生效；支持 SHA-256 校验和、HMAC 签名验证、语义化版本比较与更新记录管理，全程不联网
- **系统备份文件（P5A）**：导出走系统“另存为”，可一键分享到文件管理器/云盘，也能从文件选择器恢复；旧版本写在应用目录的 `code_learn_backup.json` 仍可在「我的」里单独导入
- **备份与存储加固**：备份格式带 `schema` 版本，未来版本的备份会被拒绝而不是覆盖数据；启动时执行幂等存储迁移，数据版本高于当前客户端时进入只读错误页，不清空任何内容；文件读写有 16 MB 上限与占用互斥保护
- **设备矩阵**：Android CI 在 API 30 / 33 / 35 三档模拟器上跑真机启动冒烟
- 开发者工具：Base64、URL、进制转换、JSON、时间戳、MD5 / SHA-256 等
- **现代极简界面（2026 风格）**：全局只用主色蓝 / 表面白 / 画布浅灰三种颜色，16px 统一圆角、单层柔和阴影、20px 页面边距与统一字体层级，动效克制在 280ms 以内，支持深色模式与中英文切换

### 分类与规模

| 分类 | 课程 | 选择题 | 分类 | 课程 | 选择题 |
| --- | ---: | ---: | --- | ---: | ---: |
| Python | 21 | 97 | C++ | 21 | 97 |
| Java | 21 | 97 | JavaScript | 21 | 97 |
| Go | 22 | 102 | Shell | 22 | 102 |
| TypeScript | 22 | 102 | C# | 19 | 87 |
| Rust | 18 | 82 | C 语言 | 15 | 60 |
| Kotlin | 13 | 52 | Swift | 13 | 52 |
| 计算机基础 | 30 | 142 | 算法与数据结构 | 35 | 167 |
| 网络 | 24 | 112 | 操作系统 | 17 | 78 |
| 数据库 | 27 | 127 | 安全与合规 | 15 | 60 |
| 工具链 | 14 | 68 | AI 与智能体 | 38 | 173 |
| 分布式与架构 | 10 | 50 | 软件工程 | 12 | 60 |
| 数学基础 | 9 | 44 | 跨语言对照 | 18 | 72 |
| 图解专题 | 21 | 84 | 项目实战 | 5 | 20 |
| 移动开发 | 12 | 58 | HTML 与 CSS | 14 | 68 |

### 界面设计

全站共用一套现代极简（Modern Minimal）设计令牌，定义在 `lib/theme/app_theme.dart`：

| 维度 | 规则 |
| --- | --- |
| 颜色 | 只用主色蓝 `#2F6BFF`、表面白 `#FFFFFF`、画布浅灰 `#F5F6FA`；绿 / 红 / 橙仅用于答题对错等必要反馈 |
| 圆角 | 卡片 16、控件 12、标签 10、底部弹层 24 |
| 间距 | 4 的倍数，页面水平边距固定 20 |
| 阴影 | 卡片只保留单层柔和阴影（`blur 20 / offset y 6`），不再叠加第二层 |
| 字体 | 全站无衬线；标题 700、正文 400、标签 500~600，数字用表格数字对齐 |
| 动效 | 140 / 200 / 280ms，统一 `easeOutCubic`，并遵循系统「减少动画」设置 |

## 题库质量

- P0 已支持单选、多选、填空、排序、代码输出和排错等题型交互。
- P1 已将旧版模板题全部替换为从课程 Markdown 的“定义、练习、最小示例、常见错误”章节提炼的复习题。
- 当前 3086 道题均有 120 字以上解析，题干不重复，元问题、重复 5 次以上的模板句与旧版自动扩写句均为 0。
- 单选答案 A/B/C/D 占比均衡在 22%–28%，正确项「明显最长」的题目为 0，避免长度暗示答案。
- 542 篇教程正文平均 16,240 字符、最短 11,690 字符；每课均有可运行练习或实践任务、故障现场和内容复核信息。
- 质量巡检与内容重建可执行：`dart tool/analyze_quiz_quality.dart`、`dart tool/rebuild_lesson_study_sections.dart`，脚本幂等，可重复运行。

## 代码沙箱

「工具 → 代码沙箱」可以离线运行 13 种语言，运行时全部随 APK 打包（约 15 MB，按 APK 压缩后实际增量见下方体积门禁）：

| 语言 | 运行时 | 说明 |
| --- | --- | --- |
| JavaScript | WebView 内置引擎 | console.log 与表达式结果 |
| TypeScript | sucrase（本地打包，约 530 KB） | 类型标注 / 接口 / 枚举，只转译不类型检查 |
| Python | Brython 3.14 + 标准库 | math、json、random、datetime 等都可导入 |
| Lua | Fengari（Lua 5.3） | 语法与常用标准库，print 输出 |
| SQL | sql.js（SQLite，wasm 内联 base64） | 建表、插入、查询，结果渲染成真正的数据表格 |
| JSON | 浏览器内置 JSON | 校验并格式化 |
| Scheme | BiwaScheme（约 370 KB） | R7RS 子集，display / map / 递归等，支持 read-line |
| Markdown | 自写迷你渲染器 | 标题、列表、粗体、行内代码、围栏代码、引用与链接；支持「预览 / HTML 源码」切换 |
| 正则表达式 | 浏览器内置 RegExp | 第一行写表达式、第二行写 flags，其余为待匹配文本；匹配结果在原文中高亮显示 |
| XML | 浏览器内置 DOMParser | 语法校验并缩进打印元素树，解析失败给出错误位置 |
| CSV | 自写解析器 | 支持引号包裹、引号内换行与 `""` 转义，渲染成表格并附 JSON 预览 |
| C / C++ | JSCPP 2.0.9（本地打包，约 393 KB） | 教学子集：变量、数组、函数、递归、指针、结构体以及 printf / cout / scanf / cin；不支持 STL 容器、类、模板与 Lambda |
| Bash | bashkit-wasm 0.18.2（WebAssembly，约 6.8 MB） | 变量、循环、条件、函数、管道、重定向与 grep / sed / awk / sort / wc / jq 等常用命令；文件只存在于沙箱虚拟文件系统 |

编辑器与输入：

- **标准输入**：除 Markdown / 正则 / XML / CSV 这类「正文即输入」的语言外，其余语言都有 stdin 输入框；JavaScript 用 `readLine()`、Python 用 `input()`、Scheme 用 `read-line`、C / C++ 用 `scanf` / `cin`，各行按顺序消费，用尽时给出明确提示；
- **示例库**：每种语言内置多个可直接运行的示例，一键载入代码与配套 stdin；
- **片段库**：可把当前代码存成片段（本地保存，上限 200 条，可收藏、可删除、按语言过滤）；
- **编辑器增强**：Tab / Shift+Tab 对当前行或选中行缩进、反缩进，回车自动继承缩进并在成对括号中间展开，`()`、`[]`、`{}` 与引号自动补全；
- **运行控制与结构化输出**：运行中可随时「停止」并立即销毁 WebView；输出超过 2000 行 / 20 万字符自动截断并提示；SQL / CSV 渲染表格，Markdown 支持预览，正则支持匹配高亮；
- **全屏编辑与教程联动**：编辑器可全屏展开，字号在 0.8×–1.8× 之间调节并持久化；教程代码块可一键「在沙箱打开」，暂不支持离线执行的语言会明确提示当前支持范围。

实现要点：

- 页面模板放在 `assets/sandbox/harness/*.html`，原生层把对应运行时内联进模板，再把用户代码转义成 JS 字符串注入，避免内联脚本被 `</script>` 截断；
- 组装好的页面写入应用缓存目录，用 `file://` 打开（避免超大内联页面走 `data:` 通道，也便于 Brython 在 `file://` 下正常导入内置标准库）；执行结束立即销毁 WebView 并删除临时页面；
- WebView 开启 `blockNetworkLoads`，关闭 `allowFileAccessFromFileURLs`、`allowUniversalAccessFromFileURLs` 与 DOM 存储，沙箱不联网，也不会读取 App 的其它本地文件；
- 单次执行由原生层兜底超时 30 秒，超时自动销毁 WebView；
- 校验脚本：`dart tool/verify_sandbox_harness.dart`（用无头 Edge 跑 28 个用例、共 39 次执行，覆盖正常输出、错误分支、标准输入、输出截断与 file:// 打开方式，并对 11 个用例额外用 http:// 跑一遍确认没有额外网络请求）。

## 内容来源与复核

知识点结构参考以下开源项目（正文为面向本 App 重新撰写的中文内容，代码示例为自写示例）：

- [developer-roadmap](https://github.com/kamranahmedse/developer-roadmap)（CC BY-NC-SA 4.0）：Python / C++ / Java / JavaScript 路线图
- [developer-roadmap](https://github.com/kamranahmedse/developer-roadmap)（CC BY-NC-SA 4.0）：AI Engineer / AI Agents 路线图
- [TheAlgorithms](https://github.com/TheAlgorithms)（MIT）：算法与数据结构主题
- [Microsoft .NET 文档](https://learn.microsoft.com/dotnet/)（CC BY 4.0）：C# 与 ASP.NET Core 主题

App 内「我的 → 参考资料与许可」中也有同样的署名说明。

每篇 Markdown 末尾都有「参考资料与复核」块，列出至少 2 个官方文档或标准来源，并记录：

| 字段 | 当前值 |
| --- | --- |
| 最后复核 | 2026-10-04 |
| 下次复核 | 2027-04-04 |
| 复核范围 | 版本兼容、API 行为、安全建议与工程实践 |

复核元数据由 `dart tool/apply_p2_references.dart` 幂等生成。课程图片统一使用 WebP，可用 `tool/optimize_content_images.ps1` 重新压缩。

## 离线内容包

「我的 → 离线内容包」可通过 Android 系统文件选择器导入 JSON 文件，全程不联网。内容包 schema：

```json
{
  "schema": "code-learn-content-pack",
  "schema_version": 1,
  "pack_id": "example-pack",
  "name": "Example Pack",
  "version": "2026.10",
  "lessons": [
    {
      "id": "python_first_script",
      "category_id": "python",
      "title": { "zh": "更新后的课程", "en": "Updated lesson" },
      "summary": { "zh": "课程摘要", "en": "Lesson summary" },
      "markdown": "# 课程正文"
    }
  ]
}
```

- 同 ID 课程覆盖标题、摘要、正文和可选题目；新 ID 追加到指定分类。
- 单包上限 8 MB，单课 Markdown 上限 1 MB；错误 schema、重复 ID 和空课程会被拒绝。
- 移除内容包后立即恢复 APK 内置课程；原课程文件不会被删除。
- 完整性：`checksum` 为整包的 SHA-256（排除 checksum / signature / imported_at），`signature` 为内置密钥的 HMAC-SHA256；校验失败或签名不符会拒绝导入，未签名的旧包仍按兼容模式放行。
- 版本关系：导入时自动比较语义化版本，提示「新版本 / 已是最新 / 较旧覆盖」，并在「内容包管理」面板展示校验和与最近 20 条更新记录。
- 增量更新：包内可带 `delta.base_version` 与 `delta.removed_lesson_ids`，App 会在已安装内容包上合并增量，只覆盖变化的课程。
- 签名工具：`dart run tool/sign_content_pack.dart pack.json [out.json]` 可为内容包写入 checksum 与 signature。


## 技术选型

| 需求 | 方案 |
| --- | --- |
| 状态管理 | `provider`（ChangeNotifier） |
| 本地存储 | `hive` + `hive_flutter` |
| Markdown 渲染 | `flutter_markdown` |
| 语法高亮 | `flutter_highlight` + `highlight` |
| 内容来源 | `assets/content/`，启动时加载，离线可用 |
| 代码沙箱 | 原生 `WebView` + 内置 JS 运行时（Brython / Fengari / sql.js / sucrase / BiwaScheme） |
| 本地通知 | `flutter_local_notifications` + `timezone` |

## 目录结构

```text
code_learn_app/
├── assets/content/            # 教程 Markdown + manifest.json 内容索引
├── assets/sandbox/            # 代码沙箱：harness 页面模板 + 各语言运行时
│   ├── harness/               # 每种语言一个 HTML 模板（含 __USER_CODE__ 占位符）
│   ├── brython/ fengari/ sqljs/ sucrase/   # 内置运行时
├── lib/
│   ├── main.dart              # 入口：初始化 Hive 后启动
│   ├── app.dart               # Provider 注入 + MaterialApp 主题/语言
│   ├── models/                # 分类、知识点、测验题、成绩、笔记、沙箱语言
│   ├── data/                  # 预留：需要扩展本地数据源时使用
│   ├── services/              # 内容仓库、进度、设置、推荐、沙箱、Hive 存储封装
│   ├── screens/               # 首页、分类、教程、测验、学习、搜索、我的、工具、沙箱
│   ├── widgets/               # 卡片、代码块、选项、空状态等复用组件
│   ├── theme/                 # Material 3 浅色 / 深色主题
│   └── l10n/                  # 中英文界面文案
├── android/keystore/          # 发布密钥库（不提交版本库）
├── integration_test/          # Android 真机/模拟器冒烟测试
├── tool/                      # 内容生成、代码校验、品牌资源与沙箱脚本
└── test/                      # 内容完整性测试 + 端到端流程测试 + 金图视觉回归
```

## 运行

```bash
flutter pub get
flutter run                 # 连接 Android 模拟器或真机后执行
```

如果本机还没配置 Flutter，请先安装 Flutter SDK 并把 `flutter/bin` 加入 PATH；Android 侧需要 Android SDK 与 JDK 17 及以上。

## 品牌资源

| 资源 | 位置 | 说明 |
| --- | --- | --- |
| 自适应图标（Android 8+） | `res/mipmap-anydpi-v26/ic_launcher.xml` | 矢量前景 + 品牌渐变背景，并声明 `monochrome` 以支持 Android 13+ 主题图标 |
| 传统启动图标 | `res/mipmap-*/ic_launcher.png`、`ic_launcher_round.png` | 48 / 72 / 96 / 144 / 192 px 五档密度 |
| 启动画面 | `res/drawable/launch_background.xml`、`values-v31/styles.xml` | 品牌渐变 + 居中白色标记；Android 12+ 走系统 SplashScreen |
| 应用名 | `res/values/strings.xml`、`values-en/strings.xml` | 中文「计算机与编程学习」/ 英文「CS & Coding」 |

改图标只需运行（需要 Pillow + numpy）：

```bash
python tool/make_brand_assets.py     # 重新生成所有 PNG
dart tool/check_brand_assets.dart    # 自检尺寸、安全区与资源引用
```

矢量前景与脚本保持同一套几何参数（mark_scale=0.76、dy=0.028），自检会确认前景落在自适应图标 66×66dp 安全区内。

## 打包

包名：`com.codelearn.study`（`android/app/build.gradle.kts` 的 `namespace` 与 `applicationId`）。
如需换成自有域名，同时修改这两处并把 `MainActivity.kt` 移到对应包目录。

### 直接分发 APK

```bash
# 推荐：ARM 双 ABI 通用包，覆盖绝大多数 Android 真机
flutter build apk --release --target-platform android-arm,android-arm64
# 按 ABI 拆分（含 x86_64 模拟器包，单包更小）
flutter build apk --release --split-per-abi
# 完整三 ABI 通用包（含 x86_64，仅本机验证用；体积会超过 CI 门禁）
flutter build apk --release
```

> ⚠️ 打包时**不要加 `--no-pub`**：`--no-pub` 会跳过插件注册文件重生成，
> 导致 release 编译仍引用 debug 专用的 `integration_test` 插件而失败。
> 先 `flutter pub get`，再执行不带 `--no-pub` 的构建命令即可。

产物与实测体积（v1.3.3+13，本机 Flutter 3.13+ / AGP 9 环境）：

| 命令 | 产物 | 体积 |
| --- | --- | ---: |
| `--target-platform android-arm,android-arm64` | `app-release.apk`（ARM 双 ABI） | 86.48 MiB / 门禁 90 MiB |
| `--split-per-abi` | `app-arm64-v8a-release.apk` | 67.68 MiB / 门禁 90 MiB |
| | `app-armeabi-v7a-release.apk` | 65.62 MiB / 门禁 90 MiB |
| | `app-x86_64-release.apk` | 69.16 MiB / 门禁 90 MiB |
| `flutter build apk --release` | `app-release.apk`（3 ABI） | 超过 90 MiB 门禁，仅用于本机安装验证 |

体积主要来自两部分：内置课程资产约 55.5 MiB（542 篇 Markdown 18.0 MiB + 1059 张配图 33.4 MiB）
与沙箱运行时等资源约 15 MiB；ARM 双 ABI 原生库约 37 MiB。
CI 里有体积门禁，会对 ARM 通用包和三个 ABI 分包逐一执行
`dart tool/check_apk_size.dart <apk> 90`。

发布签名（`android/key.properties` 存在时走发布证书）：

```text
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
→ Verified using v2 scheme: true
→ Verified using v3 scheme: true
→ V3.0 Signer certificate DN: CN=Code Learn, OU=Mobile, O=Code Learn, L=Beijing, ST=Beijing, C=CN
```

APK 权限仅 `POST_NOTIFICATIONS` / `RECEIVE_BOOT_COMPLETED` / `VIBRATE`，
**没有** `INTERNET`，不依赖任何网络服务。

### 签名配置

- 密钥库：`android/keystore/code_learn_release.jks`（别名 `codelearn`，RSA 2048，有效期 30 年）
- 口令文件：`android/key.properties`（`storeFile` 相对 `android/app` 目录）
- 两者都已加入 `.gitignore`，**不会**进入版本库，也没有被打包进 APK。

务必单独备份这两个文件：密钥库一旦丢失，就无法再发布同一应用的升级包。协作者没有 `key.properties` 时，`release` 会自动回退到 debug 签名，保证仍可构建与安装。

### 版本策略

`pubspec.yaml` 的 `version: 主.次.修订+构建号` 是唯一版本来源：

- `versionName` = `主.次.修订`（当前 `1.3.3`），对用户可见；
- `versionCode` = `+` 后的构建号，每次分发新版本必须**严格递增**；
- 使用 `--split-per-abi` 时 Flutter 会按 ABI 自动叠加偏移，无需手工维护。

### 构建环境说明

- `android/settings.gradle.kts` 已配置阿里云镜像（官方源兜底），国内网络下解析 AGP / Kotlin / Maven 依赖更快。
- Gradle 9 + AGP 9 不再允许用全局 init 脚本里的 `gradle.allprojects { repositories { ... } }` 注入仓库，否则会报 `Build was configured to prefer settings repositories over project repositories`。本机 `~/.gradle/init.d/mirrors.init.gradle` 已改为在 `beforeSettings` 中写入 `settings.dependencyResolutionManagement.repositories`，镜像加速保留，构建可正常进行。其他机器如果装了同类旧脚本，可按同样方式调整。

## 校验

```bash
flutter analyze     # 静态检查（当前 0 issue）
flutter test        # 199 项：内容完整性 + 端到端流程 + 金图视觉回归 + 备份/迁移/沙箱测试
dart tool/verify_sandbox_harness.dart   # 多语言沙箱离线校验（需本机有 Edge/Chrome）
dart tool/check_brand_assets.dart       # 图标/启动页资源自检
dart tool/check_apk_size.dart build/app/outputs/flutter-apk/app-release.apk 90   # APK 体积门禁
```

`.github/workflows/flutter-ci.yml` 会在 push / PR 时自动执行依赖安装、静态检查、全量测试、品牌资源检查、沙箱校验、金图视觉回归、release APK 构建与体积门禁；金图覆盖首页（手机 / 平板 / 深色）、学习、工具、我的、教程与测验页，位于 `test/goldens/`。
`.github/workflows/android-device.yml` 另外在 API 30 / 33 / 35 三档模拟器上跑 `integration_test/app_smoke_test.dart` 启动冒烟。

## 如何新增知识点

1. 在 `assets/content/` 下新增一个 Markdown 文件，代码块用带语言标记的围栏：

   ````text
   ```python
   print("hello")
   ```
   ````

2. 在 `assets/content/manifest.json` 对应的分类里追加一条 lesson，填写 `id`、`title`、`summary`、`file`、`minutes`、`keywords` 和 `quiz` 题目（3-5 道基础题，另可加 1 道排序/填空/多选扩展题）。

3. 题目字段按题型配置：

   - `single` / `code` / `debug`：`answer` 为正确选项下标，从 0 开始；
   - `multi`：`answers` 填全部正确下标；
   - `fill`：`accepted_answers` 填可接受答案；
   - `order`：`options` 是打乱后的步骤，`correct_order` 填正确下标顺序；
   - `code` 题还可填写 `language` 与 `expected_output`，并可从题目跳转离线沙箱运行。

4. 运行 `flutter test`，内容自检会校验题量、答案字段与 Markdown 是否可加载。批量整理模板题可执行 `python tool/curate_p0_quiz.py`。

## 数据存储说明

学习进度、收藏、笔记和测验成绩保存在 Hive 盒子 `app_data` 中，键名前缀分别是 `learned_ids`、`favorite_ids`、`note_*`、`quiz_result_*`。卸载应用即清除；不需要联网，也不会上传任何数据。
