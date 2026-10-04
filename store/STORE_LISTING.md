# 商店文案与素材清单

当前版本：1.1.0+2 · 内容规模：28 个分类 / 534 篇教程 / 2430 道测验 / 534 张配图
（规模数据来自 `assets/content/manifest.json`，每次大批量加课后请重新执行“复核命令”）

## 一、应用标题

| 语言 | 文案 | 字符数 |
| --- | --- | ---: |
| 中文 | 计算机与编程学习 | 8 |
| English | CS & Coding: Learn to Code | 27 |

> Google Play 标题上限 30 字符；若同时上架多语言，可把英文标题改为
> `CS & Coding: Offline Courses`（28 字符）。

## 二、简短说明（上限 80 字符）

- 中文：`534 篇离线教程 · 2430 道测验 · 编程、算法、AI 与计算机基础`
- English: `534 offline lessons, 2430 quizzes: Python, Java, C++, AI and CS basics.`

## 三、完整说明

### 中文

```
完全离线的计算机与编程学习应用：不需要账号，不需要联网，装上就能学。

【内容规模】
· 28 个分类、534 篇图文教程、2430 道带解析的测验题
· 覆盖 Python、Java、C++、C#、JavaScript、算法与数据结构、计算机网络、
  操作系统、数据库、工具链、AI 与 AI Agent 等主题
· 每篇教程都有代码示例、知识点拆解与参考资料，代码块可一键复制

【学习方式】
· 按推荐顺序的课程路线学习，也可以按分类自由跳转
· 每课配 3-5 道选择题，答完立即判分并显示解析
· 学习进度、测验正确率、错题本、收藏与笔记全部自动记录
· 复习队列按遗忘曲线提醒该复习的课程

【离线工具】
· 代码沙箱：离线运行 JavaScript / TypeScript / Python / Lua / SQL / JSON
· 开发者工具箱：Base64、URL 编码、进制转换、JSON 格式化、哈希计算等

【隐私】
· 不收集任何个人信息，不联网，无广告，无账号
· 学习数据只保存在本机，可随时清除或导出备份

适合准备面试、复习计算机基础、或者从零开始学编程的自学者。
```

### English

```
A fully offline computer-science and programming tutor. No account, no internet
needed — install and start learning.

HIGHLIGHTS
· 28 categories, 534 illustrated lessons, 2430 quiz questions with explanations
· Python, Java, C++, C#, JavaScript, algorithms, networking, operating systems,
  databases, tooling, AI and AI agents
· Every lesson includes runnable code samples, key takeaways and references
· 3-5 multiple-choice questions per lesson with instant scoring and explanations
· Progress, accuracy, wrong-answer book, favorites and notes stored on device
· Spaced-repetition review queue for what you are about to forget

OFFLINE TOOLS
· Code sandbox: run JavaScript / TypeScript / Python / Lua / SQL / JSON offline
· Developer toolbox: Base64, URL encoding, radix conversion, JSON, hashing

PRIVACY
· No personal data collection, no network permission, no ads, no accounts
· All learning data stays on your device and can be exported or deleted anytime
```

## 四、分类与标签

- 应用类别：教育（Education）
- 标签建议：编程、计算机科学、学习、离线、算法、Python、Java、C++、AI
- 目标受众：13 岁以上的中学生、大学生、转行自学者与面试备考者

## 五、素材清单

| 素材 | 规格 | 文件 | 状态 |
| --- | --- | --- | --- |
| 应用图标 | 512 × 512 PNG | `store/icon_512.png` | 已生成，`dart tool/check_brand_assets.dart` 校验 |
| 功能图 | 1024 × 500 PNG | `store/feature_graphic_1024x500.png` | 由 `flutter test tool/store_screenshot_test.dart` 直接导出 |
| 手机截图 | 390 × 844 PNG | `store/screenshots/01_home_en.png` 等 3 张 | 同上，脚本直接写盘 |
| 隐私政策网址 | 公开可访问 | `store/privacy_policy.html` | 需部署后把网址填入商店后台 |

> 截图脚本使用 Flutter SDK 自带 Roboto 字体，不会出现方块字；
> 若 UI 改版，重新执行一次脚本即可覆盖旧素材。

## 六、复核命令

```bash
# 内容规模与分类统计
python -c "import json;m=json.load(open('assets/content/manifest.json',encoding='utf-8'));ls=[l for c in m['categories'] for l in c['lessons']];print(len(m['categories']),len(ls),sum(len(l.get('quiz',[])) for l in ls))"

# 品牌素材自检
dart tool/check_brand_assets.dart

# 重新生成商店截图与功能图
flutter test tool/store_screenshot_test.dart
```
