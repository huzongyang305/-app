/// 极简双语词典：key -> {zh, en}。
///
/// 内容正文以中文为主，界面文案支持中英文切换。
class AppStrings {
  const AppStrings(this.localeCode);

  final String localeCode;

  static const Map<String, Map<String, String>> _values = {
    'appTitle': {'zh': '计算机与编程学习', 'en': 'CS & Coding'},
    'navHome': {'zh': '首页', 'en': 'Home'},
    'navLearn': {'zh': '学习', 'en': 'Learn'},
    'navQuiz': {'zh': '测验', 'en': 'Quiz'},
    'navProfile': {'zh': '我的', 'en': 'Profile'},
    'navTools': {'zh': '工具', 'en': 'Tools'},
    'search': {'zh': '搜索知识点', 'en': 'Search lessons'},
    'searchHint': {'zh': '输入关键词，如「二分」「HTTP」', 'en': 'Try "binary" or "HTTP"'},
    'searchEmpty': {'zh': '没有找到相关知识点', 'en': 'No matching lessons'},
    'searchTip': {
      'zh': '支持搜索标题、关键词与教程正文',
      'en': 'Searches titles, keywords and content',
    },
    'searchIndexing': {'zh': '正在建立本地搜索索引…', 'en': 'Building local index…'},
    'searchPinyinHint': {
      'zh': '支持中文、英文、拼音和首字母，例如「erfen」或「efcz」',
      'en': 'Try Chinese, English, pinyin or initials, such as “erfen”.',
    },
    'searchHistory': {'zh': '最近搜索', 'en': 'Recent searches'},
    'clearHistory': {'zh': '清空', 'en': 'Clear'},
    'clear': {'zh': '清空', 'en': 'Clear'},
    'searchFilterAll': {'zh': '全部', 'en': 'All'},
    'searchFilterUnlearned': {'zh': '未学', 'en': 'Unlearned'},
    'searchFilterFavorites': {'zh': '收藏', 'en': 'Favorites'},
    'searchFilterWrong': {'zh': '错题', 'en': 'Wrong'},
    'searchCategoryFilter': {'zh': '按分类筛选', 'en': 'Filter by category'},
    'searchAllCategories': {'zh': '全部分类', 'en': 'All categories'},
    'categories': {'zh': '课程分类', 'en': 'Categories'},
    'continueLearning': {'zh': '继续学习', 'en': 'Continue learning'},
    'overallProgress': {'zh': '总体学习进度', 'en': 'Overall progress'},
    'learnedLessons': {'zh': '已学知识点', 'en': 'Lessons learned'},
    'favorites': {'zh': '我的收藏', 'en': 'Favorites'},
    'notes': {'zh': '我的笔记', 'en': 'Notes'},
    'quizAverage': {'zh': '测验平均正确率', 'en': 'Average quiz score'},
    'quizHistory': {'zh': '测验记录', 'en': 'Quiz history'},
    'settings': {'zh': '设置', 'en': 'Settings'},
    'darkMode': {'zh': '深色模式', 'en': 'Dark mode'},
    'language': {'zh': '语言', 'en': 'Language'},
    'switchToEnglish': {'zh': '切换到英文', 'en': 'Switch to Chinese'},
    'themeSystem': {'zh': '跟随系统', 'en': 'System'},
    'themeLight': {'zh': '浅色', 'en': 'Light'},
    'themeDark': {'zh': '深色', 'en': 'Dark'},
    'lessons': {'zh': '个知识点', 'en': 'lessons'},
    'minutes': {'zh': '分钟', 'en': 'min'},
    'startQuiz': {'zh': '开始测验', 'en': 'Start quiz'},
    'openLab': {'zh': '打开互动实验', 'en': 'Open interactive lab'},
    'prerequisites': {'zh': '前置知识', 'en': 'Prerequisites'},
    'relatedLessons': {'zh': '相关拓展', 'en': 'Related lessons'},
    'retakeQuiz': {'zh': '重新测验', 'en': 'Retake'},
    'viewLesson': {'zh': '查看教程', 'en': 'View lesson'},
    'markLearned': {'zh': '标记为已学', 'en': 'Mark as learned'},
    'learned': {'zh': '已学习', 'en': 'Learned'},
    'copyCode': {'zh': '代码已复制', 'en': 'Code copied'},
    'copy': {'zh': '复制', 'en': 'Copy'},
    'question': {'zh': '第', 'en': 'Question'},
    'nextQuestion': {'zh': '下一题', 'en': 'Next'},
    'seeResult': {'zh': '查看结果', 'en': 'See result'},
    'correct': {'zh': '回答正确', 'en': 'Correct'},
    'wrong': {'zh': '回答错误', 'en': 'Incorrect'},
    'quizTypeCode': {'zh': '代码输出', 'en': 'Code output'},
    'quizTypeDebug': {'zh': '排错', 'en': 'Debugging'},
    'quizTypeOrder': {'zh': '排序', 'en': 'Ordering'},
    'quizTypeFill': {'zh': '填空', 'en': 'Fill in'},
    'quizTypeMulti': {'zh': '多选', 'en': 'Multiple select'},
    'quizSubmitAnswer': {'zh': '提交答案', 'en': 'Submit answer'},
    'quizFillHint': {
      'zh': '在输入框中填写答案，大小写和空格不影响判定。',
      'en': 'Type the answer; case and spaces do not affect grading.',
    },
    'quizFillPlaceholder': {'zh': '输入答案', 'en': 'Your answer'},
    'quizAcceptedAnswers': {'zh': '参考答案', 'en': 'Accepted answers'},
    'quizOrderHint': {
      'zh': '拖动右侧手柄，把步骤调整为正确顺序。',
      'en': 'Drag the handle to put the steps in the correct order.',
    },
    'quizRunInSandbox': {'zh': '运行', 'en': 'Run'},
    'quizCodeRunUnsupported': {
      'zh': '该语言暂不支持离线运行，可先阅读代码并选择输出。',
      'en': 'This language cannot run offline here; read the code and choose the output.',
    },
    'quizExpectedOutput': {'zh': '参考输出', 'en': 'Expected output'},
    'explanation': {'zh': '解析', 'en': 'Explanation'},
    'quizDone': {'zh': '测验完成', 'en': 'Quiz complete'},
    'yourScore': {'zh': '本次得分', 'en': 'Your score'},
    'bestScore': {'zh': '最好成绩', 'en': 'Best score'},
    'restart': {'zh': '再来一次', 'en': 'Try again'},
    'backToLesson': {'zh': '返回教程', 'en': 'Back to lesson'},
    'noteTitle': {'zh': '写笔记', 'en': 'Note'},
    'noteHint': {'zh': '记录你的理解与疑问…', 'en': 'Write down your thoughts…'},
    'save': {'zh': '保存', 'en': 'Save'},
    'cancel': {'zh': '取消', 'en': 'Cancel'},
    'noteSaved': {'zh': '笔记已保存', 'en': 'Note saved'},
    'noFavorites': {'zh': '还没有收藏，去教程页点星标吧', 'en': 'No favorites yet'},
    'noNotes': {'zh': '还没有笔记', 'en': 'No notes yet'},
    'noQuizRecord': {'zh': '还没有测验记录', 'en': 'No quiz records yet'},
    'allLessons': {'zh': '全部知识点', 'en': 'All lessons'},
    'loading': {'zh': '加载中…', 'en': 'Loading…'},
    'loadFailed': {'zh': '内容加载失败', 'en': 'Failed to load content'},
    'retry': {'zh': '重试', 'en': 'Retry'},
    'questions': {'zh': '道题', 'en': 'questions'},
    'attempts': {'zh': '次作答', 'en': 'attempts'},
    'progress': {'zh': '进度', 'en': 'Progress'},
    'emptyLearning': {
      'zh': '从首页选一个分类开始学习吧',
      'en': 'Pick a category on Home to start',
    },
    'about': {'zh': '本应用内容全部离线内置，无需联网', 'en': 'All content is bundled offline'},
    'references': {'zh': '参考资料与许可', 'en': 'References & licenses'},
    'referencesBody': {
      'zh':
          '知识点结构参考以下开源项目：\n\n'
          '· developer-roadmap（Kamran Ahmed，CC BY-NC-SA 4.0）\n'
          '  用于 Python / C++ / Java / JavaScript 路线图\n'
          '· TheAlgorithms（MIT）\n'
          '  用于算法与数据结构主题\n'
          '· Microsoft .NET 官方文档（CC BY 4.0）\n'
          '  用于 C# 与 ASP.NET Core 主题\n\n'
          '· developer-roadmap：AI Engineer / AI Agents 路线图（CC BY-NC-SA 4.0）\n'
          '  用于 AI 与大模型主题\n'
          '全部教程正文为面向本 App 重新撰写的中文内容，代码示例均为自写示例。',
      'en':
          'Topic outlines are based on these open-source projects:\n\n'
          '· developer-roadmap (Kamran Ahmed, CC BY-NC-SA 4.0)\n'
          '· TheAlgorithms (MIT)\n'
          '· Microsoft .NET docs (CC BY 4.0)\n\n'
          'All lesson text is originally written for this app.',
    },
    'close': {'zh': '关闭', 'en': 'Close'},
    'wrongBook': {'zh': '错题本', 'en': 'Wrong answers'},
    'wrongCount': {'zh': '答错', 'en': 'Wrong'},
    'noWrongQuestions': {'zh': '还没有错题，继续保持', 'en': 'No wrong answers yet'},
    'learningPaths': {'zh': '学习路径', 'en': 'Learning paths'},
    'learningPathsEntry': {'zh': '按目标规划的学习路线', 'en': 'Curated routes by goal'},
    'learningPathsHint': {
      'zh': '每条路线把知识点排好顺序，跟着走即可',
      'en': 'Each route orders the lessons for you',
    },
    'todayReview': {'zh': '今日复习', 'en': 'Review today'},
    'todayReviewHint': {
      'zh': '按间隔重复安排，点一下开始复习',
      'en': 'Spaced repetition queue, tap to start',
    },
    'reviewPlanTitle': {'zh': '今日复习计划', 'en': 'Today\'s review plan'},
    'reviewPlanSummary': {
      'zh': '{count} 个知识点 · 预计 {minutes} 分钟',
      'en': '{count} lessons · about {minutes} min',
    },
    'reviewPlanDeferred': {
      'zh': '另有 {n} 个知识点超出今日时间预算，将顺延到明天',
      'en': '{n} more lessons are deferred to tomorrow',
    },
    'reviewPlanOverdue': {'zh': '逾期 {n} 天', 'en': '{n} day(s) overdue'},
    'reviewPlanToday': {'zh': '今天到期', 'en': 'Due today'},
    'reviewPlanEstimate': {'zh': '预计 {n} 分钟', 'en': 'About {n} min'},
    'reviewPlanEmpty': {
      'zh': '今天没有待复习的知识点',
      'en': 'Nothing due for review today',
    },
    'reviewPlanEmptyHint': {
      'zh': '学完课程或完成测验后，这里会自动安排复习',
      'en': 'Finish a lesson or quiz to schedule the next review',
    },
    'mockExam': {'zh': '模拟考试', 'en': 'Mock exam'},
    'mockExamHint': {
      'zh': '自选题量与范围 · 按难度配比随机组卷',
      'en': 'Pick size and scope, difficulty-weighted',
    },
    'wrongDrill': {'zh': '错题重练', 'en': 'Wrong-answer drill'},
    'wrongDrillHint': {
      'zh': '只考错题本里的题目，答对即移出错题本',
      'en': 'Only your wrong answers — correct ones leave the book',
    },
    'wrongDrillEmpty': {'zh': '错题本是空的', 'en': 'Wrong-answer book is empty'},
    'reviewGradeTitle': {
      'zh': '这次复习感觉如何？',
      'en': 'How well did you recall it?',
    },
    'gradeForgot': {'zh': '忘记了', 'en': 'Forgot'},
    'gradeFuzzy': {'zh': '有点模糊', 'en': 'Fuzzy'},
    'gradeRemembered': {'zh': '记得', 'en': 'Remembered'},
    'reviewScheduled': {
      'zh': '已安排 {days} 天后再复习',
      'en': 'Next review in {days} day(s)',
    },
    // ── 成就与里程碑 ──
    'achievements': {'zh': '成就与里程碑', 'en': 'Achievements'},
    'achievementsHint': {
      'zh': '坚持学习即可逐枚解锁',
      'en': 'Keep learning to unlock them all',
    },
    'achievementEarnedCount': {
      'zh': '已解锁 {n} / {m}',
      'en': '{n} of {m} unlocked',
    },
    'achievementProgress': {'zh': '{n}/{m}', 'en': '{n}/{m}'},
    'achievementLocked': {'zh': '未解锁', 'en': 'Locked'},
    'achFirstLesson': {'zh': '起步', 'en': 'First step'},
    'achFirstLessonDesc': {'zh': '学完第一个知识点', 'en': 'Finish 1 lesson'},
    'achLessons10': {'zh': '十篇达成', 'en': 'Ten lessons'},
    'achLessons10Desc': {'zh': '累计学完 10 个知识点', 'en': 'Finish 10 lessons'},
    'achLessons50': {'zh': '五十篇', 'en': 'Fifty lessons'},
    'achLessons50Desc': {'zh': '累计学完 50 个知识点', 'en': 'Finish 50 lessons'},
    'achLessons100': {'zh': '百篇里程碑', 'en': 'Hundred lessons'},
    'achLessons100Desc': {'zh': '累计学完 100 个知识点', 'en': 'Finish 100 lessons'},
    'achStreak3': {'zh': '三日不断', 'en': 'Three-day streak'},
    'achStreak3Desc': {'zh': '连续学习 3 天', 'en': 'Study 3 days in a row'},
    'achStreak7': {'zh': '一周坚持', 'en': 'Week-long streak'},
    'achStreak7Desc': {'zh': '连续学习 7 天', 'en': 'Study 7 days in a row'},
    'achStreak30': {'zh': '月度坚持', 'en': 'Monthly streak'},
    'achStreak30Desc': {'zh': '连续学习 30 天', 'en': 'Study 30 days in a row'},
    'achQuiz80': {'zh': '稳定发挥', 'en': 'Sharp shooter'},
    'achQuiz80Desc': {
      'zh': '测验平均正确率达到 80%（至少 5 个知识点）',
      'en': 'Average quiz score ≥ 80% over 5+ lessons',
    },
    'achNotes10': {'zh': '笔记达人', 'en': 'Note taker'},
    'achNotes10Desc': {'zh': '写下 10 条笔记', 'en': 'Write 10 notes'},
    'achFavorites10': {'zh': '收藏家', 'en': 'Collector'},
    'achFavorites10Desc': {'zh': '收藏 10 个知识点', 'en': 'Favorite 10 lessons'},
    'submitExam': {'zh': '交卷', 'en': 'Submit'},
    'weakPoints': {'zh': '薄弱知识点', 'en': 'Weak areas'},
    'examAllCorrect': {
      'zh': '全部答对，可以挑战更高难度了',
      'en': 'All correct, try harder questions',
    },
    'streak': {'zh': '连续学习', 'en': 'Streak'},
    'days': {'zh': '天', 'en': 'days'},
    'todayNew': {'zh': '今日新学', 'en': 'New today'},
    'recommendTitle': {'zh': '今日推荐', 'en': 'Recommended today'},
    'recommendReview': {'zh': '到期复习', 'en': 'Review due'},
    'recommendWeak': {'zh': '薄弱知识点', 'en': 'Needs practice'},
    'recommendNext': {'zh': '下一课', 'en': 'Next lesson'},
    'continueCourse': {'zh': '继续本课程', 'en': 'Continue this course'},
    'readingFont': {'zh': '正文字号', 'en': 'Reading font size'},
    'fontSmall': {'zh': '小', 'en': 'Small'},
    'fontNormal': {'zh': '标准', 'en': 'Normal'},
    'fontLarge': {'zh': '大', 'en': 'Large'},
    'backup': {'zh': '备份与恢复', 'en': 'Backup & restore'},
    'copyLesson': {'zh': '复制全文', 'en': 'Copy lesson'},
    'lessonCopied': {
      'zh': '已复制标题、摘要与正文',
      'en': 'Title, summary and body copied',
    },
    'copyFailed': {'zh': '复制失败：{error}', 'en': 'Copy failed: {error}'},
    'linkSheetTitle': {'zh': '教程里的链接', 'en': 'Link in this lesson'},
    'copyLink': {'zh': '复制链接', 'en': 'Copy link'},
    'linkCopied': {'zh': '链接已复制', 'en': 'Link copied'},
    'linkHint': {
      'zh': '为避免联网，本 App 不直接打开浏览器；可复制链接后在浏览器访问。',
      'en': 'This app stays offline, so copy the link and open it in your browser.',
    },
    'imageViewer': {'zh': '查看大图', 'en': 'View image'},
    'imageCaption': {'zh': '图注', 'en': 'Caption'},
    'zoomIn': {'zh': '放大', 'en': 'Zoom in'},
    'zoomOut': {'zh': '缩小', 'en': 'Zoom out'},
    'resetZoom': {'zh': '复位', 'en': 'Reset'},
    'imageZoomHint': {
      'zh': '双指缩放、拖动查看细节，双击图片可放大或复位。',
      'en': 'Pinch to zoom, drag to inspect, double-tap to zoom or reset.',
    },
    'exportData': {'zh': '导出学习数据', 'en': 'Export data'},
    'importData': {'zh': '从备份恢复', 'en': 'Restore from backup'},
    'reviewReminder': {'zh': '复习提醒', 'en': 'Review reminder'},
    'reviewReminderOff': {
      'zh': '关闭中，开启后每天提醒一次复习',
      'en': 'Off — get one daily nudge to review',
    },
    'reviewReminderOn': {'zh': '每天提醒时间', 'en': 'Daily reminder time'},
    'reminderTime': {'zh': '提醒时间', 'en': 'Reminder time'},
    'notificationDenied': {
      'zh': '系统通知权限未开启，可到系统设置里手动允许',
      'en': 'Notification permission is off; enable it in system settings',
    },
    'examScope': {'zh': '考试范围', 'en': 'Exam scope'},
    'examAllCourses': {'zh': '全部课程', 'en': 'All courses'},
    'examQuestionsCount': {'zh': '题量', 'en': 'Questions'},
    'examStart': {'zh': '开始考试', 'en': 'Start exam'},
    'examPoolHint': {'zh': '该范围可选知识点', 'en': 'Lessons in scope'},
    'examTimeHint': {'zh': '考试时长', 'en': 'Duration'},
    'examNoQuestion': {
      'zh': '该范围暂无可用于组卷的知识点',
      'en': 'No questions available in this scope',
    },
    'examRuleHint': {
      'zh':
          '按基础 40% / 进阶 40% / 高级 20% 随机组卷，每个知识点只出一题，'
          '答错会自动记入错题本。',
      'en':
          'Difficulty-weighted random paper, one question per lesson. '
          'Wrong answers go to your wrong-answer book.',
    },
    // ── 难度标签（数据里存中文，展示时按语言映射） ──
    'difficultyBeginner': {'zh': '入门', 'en': 'Beginner'},
    'difficultyBasic': {'zh': '基础', 'en': 'Basic'},
    'difficultyIntermediate': {'zh': '进阶', 'en': 'Intermediate'},
    'difficultyAdvanced': {'zh': '高级', 'en': 'Advanced'},
    // ── 学习路径 ──
    'pathPython': {'zh': 'Python 从入门到实战', 'en': 'Python: Zero to Production'},
    'pathPythonSub': {
      'zh': '语法 → 数据结构 → OOP → 工程化 → 并发 → 数据实战',
      'en': 'Syntax → data structures → OOP → tooling → concurrency → practice',
    },
    'pathJavaBackend': {'zh': 'Java 后端工程师', 'en': 'Java Backend Engineer'},
    'pathJavaBackendSub': {
      'zh': 'Java 语言 → 数据库 → 网络 → Git/Docker/CI → 网关 → 实战项目',
      'en':
          'Java → databases → networking → Git/Docker/CI → gateway → projects',
    },
    'pathJsFrontend': {
      'zh': 'JavaScript 前端工程师',
      'en': 'JavaScript Frontend Engineer',
    },
    'pathJsFrontendSub': {
      'zh': 'JS 核心 → DOM/异步 → 模块化 → TypeScript → React 实战',
      'en': 'JS core → DOM/async → modules → TypeScript → React practice',
    },
    'pathLanguageTour': {'zh': '语言通览与项目交付', 'en': 'Language Tour & Delivery'},
    'pathLanguageTourSub': {
      'zh': '九种语言横向对照 → 图解底层原理 → 从需求到复盘的完整交付',
      'en': 'Compare 9 languages → visual deep dives → full delivery workflow',
    },
    'pathAiEngineer': {'zh': 'AI 应用工程师', 'en': 'AI Application Engineer'},
    'pathAiEngineerSub': {
      'zh': 'ML 基础 → 大模型 → 提示工程 → RAG → Agent → 评测与部署',
      'en': 'ML basics → LLMs → prompting → RAG → agents → evals & deployment',
    },
    'pathInterviewAlgo': {'zh': '算法面试冲刺', 'en': 'Algorithm Interview Sprint'},
    'pathInterviewAlgoSub': {
      'zh': '复杂度 → 线性结构 → 树/图 → 排序查找 → DP → 高频技巧',
      'en': 'Complexity → linear structures → trees/graphs → sorting → DP → tricks',
    },
    'pathCLanguage': {'zh': 'C 语言与系统编程', 'en': 'C and Systems Programming'},
    'pathCLanguageSub': {
      'zh': '语法与编译 → 指针内存 → 结构体/宏 → 文件与调试 → 命令行项目',
      'en':
          'Syntax → pointers → structs/macros → files/debugging → CLI project',
    },
    'pathCppEngineer': {'zh': 'C++ 工程师', 'en': 'C++ Engineer'},
    'pathCppEngineerSub': {
      'zh': '语法基础 → 指针与内存 → 模板/STL → 现代 C++ → CMake 项目',
      'en': 'Basics → pointers/memory → templates/STL → modern C++ → CMake project',
    },
    'pathCsharpDotnet': {'zh': 'C# / .NET 工程师', 'en': 'C# / .NET Engineer'},
    'pathCsharpDotnetSub': {
      'zh': '语言基础 → 面向对象 → LINQ/异步 → Web API → Blazor 与部署',
      'en': 'Basics → OOP → LINQ/async → Web API → Blazor and deployment',
    },
    'pathGoBackend': {'zh': 'Go 后端工程师', 'en': 'Go Backend Engineer'},
    'pathGoBackendSub': {
      'zh': '基础语法 → 并发/接口 → 测试/性能 → gRPC/微服务 → 数据访问',
      'en': 'Basics → concurrency/interfaces → tests/performance → gRPC → data access',
    },
    'pathRustSystems': {'zh': 'Rust 系统开发', 'en': 'Rust Systems Development'},
    'pathRustSystemsSub': {
      'zh': '所有权 → 类型系统 → 并发/异步 → 智能指针/宏 → CLI 与 WASM',
      'en': 'Ownership → types → concurrency/async → smart pointers/macros → CLI/WASM',
    },
    'pathMobileEngineer': {'zh': '移动端工程师', 'en': 'Mobile Engineer'},
    'pathMobileEngineerSub': {
      'zh': 'Flutter → Kotlin/Android → Swift/iOS → 状态、网络与发布',
      'en': 'Flutter → Kotlin/Android → Swift/iOS → state, network and release',
    },
    'pathSecurityEngineer': {'zh': '安全工程师', 'en': 'Security Engineer'},
    'pathSecurityEngineerSub': {
      'zh': '威胁建模 → OWASP → 认证/密钥 → 云/K8s → 供应链与事件响应',
      'en': 'Threat modeling → OWASP → auth/secrets → cloud/K8s → supply chain/IR',
    },
    'pathDataEngineer': {'zh': '数据工程师', 'en': 'Data Engineer'},
    'pathDataEngineerSub': {
      'zh': 'SQL/索引/事务 → 数仓/湖仓 → 批流处理 → 分布式与数据质量',
      'en': 'SQL/indexes → warehouse/lakehouse → batch/stream → distributed data quality',
    },
    'pathCsFundamentals': {
      'zh': '计算机基础全程',
      'en': 'Computer Science Fundamentals',
    },
    'pathCsFundamentalsSub': {
      'zh': '体系结构 → 操作系统 → 网络 → 算法与数据结构',
      'en': 'Architecture → operating systems → networks → algorithms and data structures',
    },
    'pathDevopsPlatform': {
      'zh': 'DevOps 与平台工程',
      'en': 'DevOps and Platform Engineering',
    },
    'pathDevopsPlatformSub': {
      'zh': 'Git/Docker → CI/CD → K8s/IaC → 可观测性 → 分布式可靠性',
      'en': 'Git/Docker → CI/CD → K8s/IaC → observability → distributed reliability',
    },
    'pathHtmlCss': {'zh': 'HTML 与 CSS 前端基础', 'en': 'HTML & CSS Foundations'},
    'pathHtmlCssSub': {
      'zh': '语义化 HTML → 选择器与盒模型 → Flex/Grid → 响应式实战',
      'en': 'Semantic HTML → selectors/box model → Flex/Grid → responsive practice',
    },
    'pathMathFoundation': {
      'zh': 'AI 与算法数学基础',
      'en': 'Math for AI & Algorithms',
    },
    'pathMathFoundationSub': {
      'zh': '集合函数 → 线代/微积分 → 概率统计 → 信息论 → 凸优化',
      'en': 'Sets → linear algebra/calculus → probability → information theory → optimization',
    },
    'pathShellAutomation': {
      'zh': 'Shell 自动化工程师',
      'en': 'Shell Automation Engineer',
    },
    'pathShellAutomationSub': {
      'zh': '语法与管道 → 条件/循环/函数 → 健壮性与安全 → 运维脚本 → 部署实战',
      'en': 'Syntax/pipes → control flow/functions → robustness/security → ops scripts → deployment',
    },
    'pathSoftwareEngineering': {
      'zh': '软件工程与质量',
      'en': 'Software Engineering & Quality',
    },
    'pathSoftwareEngineeringSub': {
      'zh': '需求与设计 → 测试策略 → TDD/重构 → 代码评审 → 故障复盘与质量门禁',
      'en': 'Requirements/design → testing → TDD/refactoring → review → postmortem/quality gates',
    },
    'pathAiProduct': {
      'zh': 'AI 产品与 Agent 落地',
      'en': 'AI Product & Agent Delivery',
    },
    'pathAiProductSub': {
      'zh': '提示与上下文 → RAG/向量库 → Agent 工具调用 → 评测/护栏 → 服务化落地',
      'en': 'Prompting/context → RAG/vector DB → tool-calling agents → evals/guardrails → serving',
    },
    'pathDuration': {
      'zh': '约 {hours} 小时 · {lessons} 课',
      'en': 'About {hours}h · {lessons} lessons',
    },
    'pathStageExam': {'zh': '阶段自测', 'en': 'Stage self-test'},
    'pathCheckpoint': {'zh': '检查点', 'en': 'Checkpoint'},
    'pathCapstone': {'zh': '结业项目', 'en': 'Capstone project'},
    'pathPassed': {'zh': '阶段已通过', 'en': 'Stage passed'},
    'pathPassRule': {
      'zh': '通过标准：检查点测验正确率达到 80%',
      'en': 'Pass rule: 80% on checkpoint quizzes',
    },
    'pathPractice': {'zh': '需要补课', 'en': 'Needs review'},
    // ── 首页卡片 ──
    'homeQuizExamTitle': {'zh': '测验与模拟考试', 'en': 'Quiz & mock exam'},
    'homeToolsTitle': {'zh': '开发者工具', 'en': 'Developer tools'},
    'homeToolsSub': {
      'zh': '编码转换 · JSON · 哈希 · 正则 · UUID',
      'en': 'Encoding · JSON · hashing · regex · UUID',
    },
    'homeStartFirst': {'zh': '开始你的第一次学习', 'en': 'Start your first lesson'},
    'homeRecent': {'zh': '最近学习', 'en': 'Recently studied'},
    'homeRecentCount': {'zh': '近 7 天 {n} 次', 'en': '{n} in the last 7 days'},
    'homeToday': {'zh': '今天', 'en': 'Today'},
    'homeDaysAgo': {'zh': '{n}天前', 'en': '{n}d ago'},
    // ── 学习页 ──
    'learnQuizExamSub': {
      'zh': '按知识点练习 · 自选模拟卷 · 错题本',
      'en': 'Practice by lesson · custom papers · wrong-answer book',
    },
    // ── 我的页 ──
    'profileExported': {'zh': '已导出到：{path}', 'en': 'Exported to: {path}'},
    'profileExportFailed': {
      'zh': '导出失败：{error}',
      'en': 'Export failed: {error}',
    },
    'profileNoBackup': {
      'zh': '未找到备份文件，请先导出',
      'en': 'No backup file found — export first',
    },
    'profileRestored': {
      'zh': '已从备份恢复学习数据',
      'en': 'Learning data restored from backup',
    },
    'profileRestoreFailed': {
      'zh': '恢复失败：{error}',
      'en': 'Restore failed: {error}',
    },
    'profileExportFileName': {
      'zh': '导出为 code_learn_backup.json',
      'en': 'Exports code_learn_backup.json',
    },
    'profileImportHint': {
      'zh': '从同一目录的备份文件恢复',
      'en': 'Restore from the backup file in the same folder',
    },
    'profileLegacyImport': {
      'zh': '从旧版应用目录导入',
      'en': 'Import from legacy app folder',
    },
    'profileLegacyImportHint': {
      'zh': '读取升级前保存在应用文档目录的 code_learn_backup.json',
      'en': 'Reads code_learn_backup.json kept in the app folder before the upgrade',
    },
    'profileLegacyMissing': {
      'zh': '旧版应用目录中没有找到备份文件',
      'en': 'No backup file found in the legacy app folder',
    },
    // ── 测验记录 / 课程卡片 ──
    'lessonIndex': {'zh': '第{n}课 · {title}', 'en': 'Lesson {n} · {title}'},
    // ── 签到卡 ──
    'checkInStreak': {'zh': '连续学习 {n} 天', 'en': '{n}-day streak'},
    'checkInDone': {'zh': '已签到', 'en': 'Checked in'},
    'checkInAction': {'zh': '签到', 'en': 'Check in'},
    // ── 代码块 ──
    'copyTooltip': {'zh': '复制', 'en': 'Copy'},
    'codeCopied': {'zh': '代码已复制', 'en': 'Code copied'},
    'fullscreenCode': {'zh': '全屏查看代码', 'en': 'View code fullscreen'},
    'exitFullscreen': {'zh': '退出全屏', 'en': 'Exit fullscreen'},
    'codeLineCount': {'zh': '共 {n} 行', 'en': '{n} lines'},
    // ── 内容加载错误 ──
    'contentLoadFailed': {
      'zh': '课程内容加载失败：{error}',
      'en': 'Failed to load content: {error}',
    },
    // ── 开发者工具页 ──
    'toolsTitle': {'zh': '开发者工具', 'en': 'Developer tools'},
    'sandboxTitle': {'zh': '代码沙箱', 'en': 'Code sandbox'},
    'sandboxHint': {
      'zh': '离线运行 JavaScript / TypeScript / Python / Lua / SQL，无需联网。',
      'en': 'Run JavaScript, TypeScript, Python, Lua and SQL fully offline.',
    },
    'sandboxRun': {'zh': '运行代码', 'en': 'Run code'},
    'sandboxRunning': {'zh': '运行中…', 'en': 'Running…'},
    'sandboxClear': {'zh': '清空代码', 'en': 'Clear code'},
    'sandboxReset': {'zh': '恢复示例代码', 'en': 'Reset sample'},
    'sandboxCopyCode': {'zh': '复制代码', 'en': 'Copy code'},
    'sandboxCopyOutput': {'zh': '复制输出', 'en': 'Copy output'},
    'sandboxOutput': {'zh': '输出', 'en': 'Output'},
    'sandboxOutputCopied': {'zh': '输出已复制', 'en': 'Output copied'},
    'sandboxNoOutput': {'zh': '（还没有输出）', 'en': '(no output yet)'},
    'sandboxEmptyCode': {'zh': '请先输入代码', 'en': 'Enter some code first'},
    'sandboxLangJavascript': {'zh': 'JavaScript', 'en': 'JavaScript'},
    'sandboxLangTypescript': {'zh': 'TypeScript', 'en': 'TypeScript'},
    'sandboxLangPython': {'zh': 'Python', 'en': 'Python'},
    'sandboxLangLua': {'zh': 'Lua', 'en': 'Lua'},
    'sandboxLangSql': {'zh': 'SQL', 'en': 'SQL'},
    'sandboxLangJson': {'zh': 'JSON', 'en': 'JSON'},
    'sandboxHintJavascript': {
      'zh': '支持 console.log 与表达式结果，适合练习语法、数组与算法。',
      'en': 'console.log and expression results; handy for syntax, arrays and algorithms.',
    },
    'sandboxHintTypescript': {
      'zh': '支持类型标注、接口与枚举；只做语法转译，不做类型检查。',
      'en': 'Types, interfaces and enums; transpiles only, no type checking.',
    },
    'sandboxHintPython': {
      'zh': '内置 Brython 与标准库（math、json、random、datetime 等），print 输出显示在下方。',
      'en': 'Brython plus the standard library (math, json, random, datetime...). print output shows below.',
    },
    'sandboxHintLua': {
      'zh': '支持 Lua 5.3 语法与常用标准库，print 输出显示在下方。',
      'en': 'Lua 5.3 syntax with the common standard library; print output shows below.',
    },
    'sandboxHintSql': {
      'zh': '内置 SQLite（sql.js），可建表、插入数据并查询结果。',
      'en': 'SQLite via sql.js: create tables, insert rows and query results.',
    },
    'sandboxHintJson': {
      'zh': '校验 JSON 语法并格式化输出，方便检查接口数据。',
      'en': 'Validate and pretty-print JSON to inspect data payloads.',
    },
    'toolsLocalOnly': {
      'zh': '全部在本地完成，不联网 · 共 {n} 个工具',
      'en': 'Everything runs offline · {n} tools',
    },
    'toolsGroupEncode': {'zh': '编码转换', 'en': 'Encoding'},
    'toolsGroupJsonText': {'zh': 'JSON 与文本', 'en': 'JSON & text'},
    'toolsGroupTimeHash': {'zh': '时间与哈希', 'en': 'Time & hashing'},
    'toolsGroupOther': {'zh': '其他', 'en': 'Others'},
    'toolsConvert': {'zh': '转换', 'en': 'Convert'},
    'toolsResult': {'zh': '结果', 'en': 'Result'},
    'toolsCopied': {'zh': '已复制', 'en': 'Copied'},
    'toolsCopy': {'zh': '复制', 'en': 'Copy'},
    'toolsClear': {'zh': '清空', 'en': 'Clear'},
    'toolsFailed': {'zh': '处理失败：{error}', 'en': 'Failed: {error}'},
    'toolBase64Encode': {'zh': 'Base64 编码', 'en': 'Base64 encode'},
    'toolBase64Decode': {'zh': 'Base64 解码', 'en': 'Base64 decode'},
    'toolUrlEncode': {'zh': 'URL 编码', 'en': 'URL encode'},
    'toolUrlDecode': {'zh': 'URL 解码', 'en': 'URL decode'},
    'toolRadix': {'zh': '进制转换', 'en': 'Number base'},
    'toolJsonPretty': {'zh': 'JSON 格式化', 'en': 'JSON format'},
    'toolJsonMin': {'zh': 'JSON 压缩', 'en': 'JSON minify'},
    'toolTextStats': {'zh': '文本统计', 'en': 'Text stats'},
    'toolTsToDate': {'zh': '时间戳 → 日期', 'en': 'Timestamp → date'},
    'toolDateToTs': {'zh': '日期 → 时间戳', 'en': 'Date → timestamp'},
    'toolMd5': {'zh': 'MD5 摘要', 'en': 'MD5 digest'},
    'toolSha256': {'zh': 'SHA-256 摘要', 'en': 'SHA-256 digest'},
    'toolUuid': {'zh': '随机 UUID', 'en': 'Random UUID'},
    'toolColor': {'zh': '颜色值解析', 'en': 'Color parser'},
    'toolRegex': {'zh': '正则测试', 'en': 'Regex tester'},
    'toolHintBase64Encode': {'zh': '输入要编码的文本', 'en': 'Text to encode'},
    'toolHintBase64Decode': {'zh': '输入 Base64 字符串', 'en': 'Base64 string'},
    'toolHintUrlEncode': {'zh': '输入要编码的文本', 'en': 'Text to encode'},
    'toolHintUrlDecode': {'zh': '输入 URL 编码文本', 'en': 'URL-encoded text'},
    'toolHintRadix': {'zh': '输入十进制整数', 'en': 'A decimal integer'},
    'toolHintJson': {'zh': '粘贴 JSON', 'en': 'Paste JSON'},
    'toolHintText': {'zh': '粘贴文本', 'en': 'Paste text'},
    'toolHintTs': {'zh': '输入秒或毫秒时间戳', 'en': 'Seconds or milliseconds'},
    'toolHintDate': {
      'zh': '输入 2026-10-02 18:30',
      'en': 'e.g. 2026-10-02 18:30',
    },
    'toolHintColor': {
      'zh': '输入 #6C8FF8 或 FF6C8FF8',
      'en': 'e.g. #6C8FF8 or FF6C8FF8',
    },
    'toolHintRegex': {
      'zh': '第一行写正则，其余为待匹配文本',
      'en': 'First line is the pattern, the rest is the text',
    },
    // ── 开发者工具的输出文案 ──
    'toolsInvalidBase64': {'zh': '不是合法的 Base64 内容', 'en': 'Not valid Base64'},
    'toolsRadixDecimal': {'zh': '十进制', 'en': 'Decimal'},
    'toolsRadixBinary': {'zh': '二进制', 'en': 'Binary'},
    'toolsRadixOctal': {'zh': '八进制', 'en': 'Octal'},
    'toolsRadixHex': {'zh': '十六进制', 'en': 'Hexadecimal'},
    'toolsRadixByte': {'zh': '字节', 'en': 'Byte'},
    'toolsStatsChars': {'zh': '总字符数', 'en': 'Characters'},
    'toolsStatsLines': {'zh': '行数', 'en': 'Lines'},
    'toolsStatsWords': {'zh': '单词数（按空白分词）', 'en': 'Words (whitespace)'},
    'toolsStatsHan': {'zh': '汉字数', 'en': 'CJK characters'},
    'toolsStatsLetters': {'zh': '字母数', 'en': 'Letters'},
    'toolsStatsDigits': {'zh': '数字个数', 'en': 'Digits'},
    'toolsStatsBytes': {'zh': 'UTF-8 字节数', 'en': 'UTF-8 bytes'},
    'toolsTimeLocal': {'zh': '本地时间', 'en': 'Local time'},
    'toolsTimeUtc': {'zh': 'UTC', 'en': 'UTC'},
    'toolsTimeIso': {'zh': 'ISO 8601', 'en': 'ISO 8601'},
    'toolsTsSeconds': {'zh': '秒级', 'en': 'Seconds'},
    'toolsTsMillis': {'zh': '毫秒级', 'en': 'Milliseconds'},
    'toolsColorFormat': {
      'zh': '需要 6 位（RRGGBB）或 8 位（AARRGGBB）',
      'en': 'Expected 6 (RRGGBB) or 8 (AARRGGBB) hex digits',
    },
    'toolsRegexNone': {'zh': '没有匹配项', 'en': 'No matches'},
    'toolsRegexCount': {'zh': '匹配到 {n} 处：', 'en': '{n} match(es):'},
    'toolsRegexItem': {
      'zh': '{i}. "{text}"  位置 {start}-{end}',
      'en': '{i}. "{text}"  at {start}-{end}',
    },
    'toolsRegexGroup': {'zh': '  分组: {groups}', 'en': '  groups: {groups}'},
    // ── 学习分析 ──
    'learningAnalytics': {'zh': '学习分析', 'en': 'Learning analytics'},
    'learningAnalyticsHint': {
      'zh': '查看周期活动、分类掌握度与薄弱点',
      'en': 'Review activity, mastery and weak points',
    },
    'analyticsOverview': {'zh': '学习概览', 'en': 'Learning overview'},
    'analyticsStreak': {'zh': '连续学习天数', 'en': 'Current streak'},
    'analyticsEstimatedMinutes': {'zh': '预计学习时长', 'en': 'Estimated minutes'},
    'analyticsRecentActivity': {
      'zh': '最近 {period} 天活动',
      'en': 'Activity in the last {period} days',
    },
    'analyticsActivityTotal': {'zh': '学习活动', 'en': 'Activities'},
    'analyticsActiveDays': {'zh': '活跃天数', 'en': 'Active days'},
    'analyticsTrend': {'zh': '环比', 'en': 'Trend'},
    'analyticsTrendUp': {'zh': '多 {n} 次', 'en': '+{n}'},
    'analyticsTrendDown': {'zh': '少 {n} 次', 'en': '-{n}'},
    'analyticsTrendFlat': {'zh': '持平', 'en': 'No change'},
    'analyticsCategoryMastery': {'zh': '分类掌握度', 'en': 'Category mastery'},
    'analyticsCategoryMasteryHint': {
      'zh': '综合学习进度、测验正确率和错题数量估算',
      'en': 'Estimated from progress, quiz accuracy and wrong answers',
    },
    'analyticsWeakPoints': {'zh': '薄弱点', 'en': 'Weak points'},
    'analyticsWeakPointsHint': {
      'zh': '优先复习正确率低或答错过的知识点',
      'en': 'Review lessons with low accuracy or wrong answers first',
    },
    'analyticsNoWeakPoints': {
      'zh': '暂时没有明显薄弱点，继续保持！',
      'en': 'No clear weak points right now. Keep going!',
    },
    'analyticsAccuracy': {'zh': '正确率', 'en': 'Accuracy'},
    'analyticsWrongTimes': {'zh': '错 {n} 次', 'en': '{n} wrong'},
    'analyticsRecommendation': {'zh': '推荐下一步', 'en': 'Recommended next'},
    // ── 英文正文覆盖与离线朗读 ──
    'lessonEnglishFallback': {
      'zh': '本文暂未提供完整英文正文，当前显示中文版本。课程仍包含英文概览与英文学习指南。完整英文正文覆盖：{available}/{total}。',
      'en': 'A full English translation is not available for this lesson, so the Chinese tutorial is shown. Every lesson still includes an English overview and study guide. Full English coverage: {available}/{total}.',
    },
    'englishCoverage': {
      'zh': '完整英文正文：{available}/{total}',
      'en': 'Full English lessons: {available}/{total}',
    },
    'ttsReadAloud': {'zh': '朗读正文', 'en': 'Read aloud'},
    'ttsStopReading': {'zh': '停止朗读', 'en': 'Stop reading'},
    'ttsUnavailable': {
      'zh': '当前设备没有可用的离线朗读引擎，请先在系统设置中安装 TTS 语音数据。',
      'en': 'No offline speech engine is available. Install TTS voice data in system settings first.',
    },
    'ttsFailed': {
      'zh': '朗读启动失败，请重试。',
      'en': 'Could not start reading. Try again.',
    },
    'ttsNoReadableText': {
      'zh': '正文没有可朗读的文字。',
      'en': 'There is no readable text in this lesson.',
    },
    // ── 交互式学习实验室 ──
    'interactiveLab': {'zh': '交互式学习实验室', 'en': 'Interactive lab'},
    'interactiveLabHint': {
      'zh': '用步骤演示理解算法与数据结构，不联网运行',
      'en': 'Step through algorithms and data structures offline',
    },
    'labBinarySearch': {'zh': '二分查找', 'en': 'Binary search'},
    'labBubbleSort': {'zh': '冒泡排序', 'en': 'Bubble sort'},
    'labInsertionSort': {'zh': '插入排序', 'en': 'Insertion sort'},
    'labSelectionSort': {'zh': '选择排序', 'en': 'Selection sort'},
    'labStackQueue': {'zh': '栈与队列', 'en': 'Stack & queue'},
    'labSystemFlow': {'zh': '系统机制演示', 'en': 'System flow lab'},
    'labSelectAlgorithm': {'zh': '选择演示', 'en': 'Choose a demo'},
    'labStepProgress': {
      'zh': '第 {current}/{total} 步',
      'en': 'Step {current}/{total}',
    },
    'labPrevious': {'zh': '上一步', 'en': 'Previous step'},
    'labNext': {'zh': '下一步', 'en': 'Next step'},
    'labPlay': {'zh': '播放', 'en': 'Play'},
    'labPause': {'zh': '暂停', 'en': 'Pause'},
    'labReset': {'zh': '重置', 'en': 'Reset'},
    'labSearchStart': {
      'zh': '在有序数组中查找 {target}，先看中间元素。',
      'en': 'Search for {target}; start with the middle value.',
    },
    'labSearchCompare': {
      'zh': '中间值 {value}，与目标 {target} 比较。',
      'en': 'Middle value {value}; compare it with {target}.',
    },
    'labSearchFound': {
      'zh': '找到 {value}，位置下标是 {mid}。',
      'en': 'Found {value} at index {mid}.',
    },
    'labSearchNotFound': {
      'zh': '搜索区间为空，没有找到 {target}。',
      'en': 'The search range is empty; {target} was not found.',
    },
    'labBubbleStart': {
      'zh': '从左到右比较相邻元素，把较大的值逐步冒泡到末尾。',
      'en':
          'Compare adjacent values left to right and bubble larger ones right.',
    },
    'labBubbleCompare': {
      'zh': '比较第 {index} 对：{left} 与 {right}，顺序正确。',
      'en': 'Compare pair {index}: {left} and {right}; order is correct.',
    },
    'labBubbleSwap': {
      'zh': '比较第 {index} 对：{left} > {right}，交换位置。',
      'en': 'Compare pair {index}: {left} > {right}; swap them.',
    },
    'labBubbleDone': {'zh': '排序完成，数组已经有序。', 'en': 'Done. The array is sorted.'},
    'labInsertionStart': {
      'zh': '把数组左边看作已排序区，每次取出一个值并插入正确位置。',
      'en': 'Treat the left side as sorted and insert each new value into its correct position.',
    },
    'labInsertionCompare': {
      'zh': '用当前值 {value} 与左侧元素 {compare} 比较，继续向左寻找位置。',
      'en': 'Compare the current value {value} with {compare} on the left and keep moving left.',
    },
    'labInsertionShift': {
      'zh': '当前值 {value} 小于 {compare}，把 {compare} 向右移动。',
      'en': 'Current value {value} is less than {compare}; shift {compare} to the right.',
    },
    'labInsertionPlace': {
      'zh': '当前值 {value} 找到位置，放到下标 {index}。',
      'en': 'Place the current value {value} at index {index}.',
    },
    'labInsertionDone': {
      'zh': '插入排序完成，数组已经有序。',
      'en': 'Insertion sort is complete and the array is sorted.',
    },
    'labSelectionStart': {
      'zh': '每一轮从未排序区选择最小值，再与未排序区首位交换。',
      'en': 'Each pass selects the smallest value in the unsorted range and swaps it to the front.',
    },
    'labSelectionCompare': {
      'zh': '当前最小值是 {minimum}，把它与 {candidate} 比较。',
      'en': 'The current minimum is {minimum}; compare it with {candidate}.',
    },
    'labSelectionSwap': {
      'zh': '本轮最小值 {minimum} 与位置 {index} 的值交换。',
      'en': 'Swap the minimum value {minimum} into position {index}.',
    },
    'labSelectionDone': {
      'zh': '选择排序完成，数组已经有序。',
      'en': 'Selection sort is complete and the array is sorted.',
    },
    'labStructureHint': {
      'zh': '栈遵循后进先出，队列遵循先进先出，点击下面的按钮观察变化。',
      'en': 'A stack is LIFO; a queue is FIFO. Use the buttons to observe changes.',
    },
    'labOperations': {'zh': '操作', 'en': 'Operations'},
    'labStack': {'zh': '栈（后进先出）', 'en': 'Stack (LIFO)'},
    'labQueue': {'zh': '队列（先进先出）', 'en': 'Queue (FIFO)'},
    'labEmptyStructure': {'zh': '当前为空', 'en': 'Currently empty'},
    'labPush': {'zh': '入栈', 'en': 'Push'},
    'labPop': {'zh': '出栈', 'en': 'Pop'},
    'labEnqueue': {'zh': '入队', 'en': 'Enqueue'},
    'labDequeue': {'zh': '出队', 'en': 'Dequeue'},
    // ── 网络与数据库机制演示 ──
    'systemLab': {'zh': '系统机制演示', 'en': 'System flow lab'},
    'systemLabHint': {
      'zh': '像看时序图一样逐步查看 HTTP 请求与数据库事务，理解每一步的状态变化。',
      'en': 'Step through an HTTP request and a database transaction like a sequence diagram.',
    },
    'systemLabHttp': {'zh': 'HTTP 请求链路', 'en': 'HTTP request flow'},
    'systemLabTransaction': {'zh': '数据库事务与隔离', 'en': 'Database transaction'},
    'systemLabCurrent': {'zh': '当前步骤', 'en': 'Current step'},
    'systemLabTimeline': {'zh': '流程时间线', 'en': 'Flow timeline'},
    'systemLabComplete': {'zh': '流程演示完成', 'en': 'Flow complete'},
    'systemLabNext': {'zh': '下一步', 'en': 'Next step'},
    'systemLabPrevious': {'zh': '上一步', 'en': 'Previous step'},
    'systemLabReset': {'zh': '重新播放', 'en': 'Restart'},
    'systemHttpDnsTitle': {'zh': '1. DNS 解析', 'en': '1. DNS lookup'},
    'systemHttpDnsDetail': {
      'zh': '浏览器把 example.com 解析成服务器 IP；命中本地或系统 DNS 缓存时可以直接复用。',
      'en': 'The browser resolves example.com to a server IP and may reuse a local or system DNS cache.',
    },
    'systemHttpTcpTitle': {'zh': '2. TCP 连接', 'en': '2. TCP connection'},
    'systemHttpTcpDetail': {
      'zh': '客户端与服务器完成三次握手，建立可靠传输通道；失败时按超时和重试策略处理。',
      'en': 'Client and server complete the TCP handshake to create a reliable channel, with timeout and retry boundaries.',
    },
    'systemHttpTlsTitle': {'zh': '3. TLS 握手', 'en': '3. TLS handshake'},
    'systemHttpTlsDetail': {
      'zh': 'HTTPS 校验证书、协商密钥并建立加密通道，之后才发送 HTTP 内容。',
      'en': 'HTTPS validates certificates, negotiates keys and creates an encrypted channel before HTTP data is sent.',
    },
    'systemHttpRequestTitle': {'zh': '4. 发送请求', 'en': '4. Send request'},
    'systemHttpRequestDetail': {
      'zh': '请求包含方法、路径、请求头、Cookie 和可选的请求体，经过代理或网关时还会增加转发信息。',
      'en': 'The request carries method, path, headers, cookies and an optional body; proxies or gateways may add forwarding metadata.',
    },
    'systemHttpServerTitle': {'zh': '5. 服务端处理', 'en': '5. Server processing'},
    'systemHttpServerDetail': {
      'zh': '服务器完成路由、鉴权、业务逻辑与数据库访问，并把结果转换成状态码、响应头和响应体。',
      'en': 'The server performs routing, authorization, business logic and data access, then builds status, headers and body.',
    },
    'systemHttpResponseTitle': {
      'zh': '6. 响应与渲染',
      'en': '6. Response and render',
    },
    'systemHttpResponseDetail': {
      'zh': '浏览器根据状态码、缓存策略和内容类型处理响应，更新缓存并渲染页面；失败时进入重试或错误页。',
      'en': 'The browser handles status, cache policy and content type, updates its cache, renders the page and handles failures.',
    },
    'systemTxBeginTitle': {
      'zh': '1. 事务 T1 开始',
      'en': '1. Transaction T1 begins',
    },
    'systemTxBeginDetail': {
      'zh': '事务获得一致性快照或必要的锁，后续读写都归属于同一个原子操作。',
      'en': 'The transaction obtains a consistent snapshot or required locks; all later reads and writes belong to one atomic operation.',
    },
    'systemTxUpdateTitle': {'zh': '2. T1 修改余额', 'en': '2. T1 updates balance'},
    'systemTxUpdateDetail': {
      'zh': '修改先写入事务日志和缓冲区；在提交前，其他事务看到的值取决于隔离级别和可见性规则。',
      'en': 'The change is written to the transaction log and buffers; visibility to others depends on isolation and snapshot rules.',
    },
    'systemTxOtherBeginTitle': {
      'zh': '3. 事务 T2 开始',
      'en': '3. Transaction T2 begins',
    },
    'systemTxOtherBeginDetail': {
      'zh': 'T2 开始自己的快照。若使用可重复读，它在提交前不会看到 T1 尚未提交的修改。',
      'en': 'T2 starts its own snapshot. Under repeatable read it will not see T1 changes until T1 commits.',
    },
    'systemTxReadOldTitle': {
      'zh': '4. T2 读取旧值',
      'en': '4. T2 reads the old value',
    },
    'systemTxReadOldDetail': {
      'zh': '在多数 MVCC 数据库中，T2 读到事务开始时的旧版本，避免读到未提交的脏数据。',
      'en': 'With MVCC, T2 reads the version visible at its snapshot, avoiding dirty reads of uncommitted data.',
    },
    'systemTxCommitTitle': {'zh': '5. T1 提交', 'en': '5. T1 commits'},
    'systemTxCommitDetail': {
      'zh': '数据库把事务日志持久化并发布新版本。提交成功后，新事务可以看到新值。',
      'en': 'The database flushes its log and publishes the new version. After commit, new transactions can see the new value.',
    },
    'systemTxReadNewTitle': {'zh': '6. 后续读取', 'en': '6. Later reads'},
    'systemTxReadNewDetail': {
      'zh': '根据隔离级别，T2 重新查询或开启新事务时会看到新值；旧快照仍可能读到旧版本。',
      'en': 'Depending on isolation, T2 sees the new value on a later query or new transaction, while an old snapshot may still read the previous version.',
    },
    'systemTxRollbackTitle': {'zh': '失败路径：回滚', 'en': 'Failure path: rollback'},
    'systemTxRollbackDetail': {
      'zh': '任何一步失败时事务回滚，未提交修改不可见，锁被释放，调用方需要重试或返回明确错误。',
      'en': 'If any step fails, the transaction rolls back, uncommitted changes stay invisible, locks are released and the caller retries or returns a clear error.',
    },
    // ── 加密备份 ──
    'profileExportEncrypted': {'zh': '导出备份', 'en': 'Export backup'},
    'profileBackupSaved': {
      'zh': '备份已保存到所选位置',
      'en': 'Backup saved to the selected location',
    },
    'profileBackupCancelled': {'zh': '已取消保存备份', 'en': 'Backup save cancelled'},
    'profileShare': {'zh': '分享备份', 'en': 'Share backup'},
    'profileShareHint': {
      'zh': '通过系统分享面板发送到文件管理器、云盘或聊天工具',
      'en': 'Send through the system share sheet to files, cloud storage or chat apps',
    },
    'profileShareStarted': {
      'zh': '已打开系统分享面板',
      'en': 'System share sheet opened',
    },
    'profileShareCancelled': {'zh': '未分享备份', 'en': 'Backup was not shared'},
    'profileOpenCancelled': {
      'zh': '已取消选择备份文件',
      'en': 'Backup selection cancelled',
    },
    'profileImportEncrypted': {'zh': '导入加密备份', 'en': 'Import encrypted backup'},
    'profileExportEncryptedHint': {
      'zh': '留空导出明文；输入密码后使用 AES-GCM 加密',
      'en': 'Leave blank for plain JSON; enter a password for AES-GCM',
    },
    'profilePassword': {'zh': '备份密码', 'en': 'Backup password'},
    'profilePasswordHint': {
      'zh': '输入至少 6 位密码，密码不会被保存',
      'en': 'Use at least 6 characters; the password is never stored',
    },
    'profilePasswordRequired': {
      'zh': '请输入备份密码',
      'en': 'Enter the backup password',
    },
    'profilePasswordWeak': {
      'zh': '密码至少需要 6 位',
      'en': 'Use at least 6 characters',
    },
    'profilePasswordOptional': {
      'zh': '不加密时留空，继续使用旧版明文格式。',
      'en': 'Leave blank to keep the legacy plain JSON format.',
    },
    'backupCryptoUnavailable': {
      'zh': '当前设备不支持加密备份，请改用明文导出。',
      'en': 'Encrypted backup is unavailable on this device; export plain JSON instead.',
    },
    'backupEncryptFailed': {
      'zh': '加密失败，请重试或改用明文导出。',
      'en': 'Encryption failed; retry or export plain JSON.',
    },
    'backupDecryptFailed': {
      'zh': '密码错误或备份内容已损坏。',
      'en': 'The password is wrong or the backup is damaged.',
    },
    'backupInvalidFormat': {
      'zh': '备份格式无法识别。',
      'en': 'The backup format is not recognized.',
    },
    'backupVersionUnsupported': {
      'zh': '备份来自更新版本的 App，请先升级后再导入。',
      'en': 'This backup comes from a newer app version. Update before importing.',
    },
    'backupFileUnavailable': {
      'zh': '当前设备不支持系统文件操作。',
      'en': 'System file operations are unavailable on this device.',
    },
    'backupFileFailed': {
      'zh': '文件操作失败，请重试。',
      'en': 'The file operation failed. Try again.',
    },
    'backupTooLarge': {
      'zh': '备份文件超过 16 MB，无法处理。',
      'en': 'The backup exceeds the 16 MB limit.',
    },
    // ── P2 无障碍、响应式与离线内容包 ──
    'mainNavigation': {'zh': '主导航', 'en': 'Main navigation'},
    'reduceMotion': {'zh': '减少动画', 'en': 'Reduce motion'},
    'reduceMotionHint': {
      'zh': '关闭答题对错与页面切换动画，适合对动态效果敏感的用户',
      'en': 'Disable answer and page transition animations',
    },
    'quizOptionSemantic': {
      'zh': '选项 {letter}：{text}',
      'en': 'Option {letter}: {text}',
    },
    'quizOptionCorrect': {'zh': '回答正确', 'en': 'Correct answer'},
    'quizOptionWrong': {'zh': '回答错误', 'en': 'Incorrect answer'},
    'progressSemantic': {
      'zh': '学习进度 {value}',
      'en': 'Learning progress {value}',
    },
    'offlinePack': {'zh': '离线内容包', 'en': 'Offline content pack'},
    'offlinePackNone': {'zh': '尚未安装内容包', 'en': 'No content pack installed'},
    'offlinePackCurrent': {
      'zh': '当前内容包：{name} · {version} · {count} 课',
      'en': 'Installed: {name} · {version} · {count} lessons',
    },
    'offlinePackHint': {
      'zh': '从设备选择 JSON 内容包；导入后可更新或追加课程，全程不联网',
      'en':
          'Pick a JSON pack from this device to update or add lessons offline',
    },
    'offlinePackImport': {'zh': '选择内容包', 'en': 'Choose pack'},
    'offlinePackRemove': {'zh': '移除内容包', 'en': 'Remove pack'},
    'offlinePackImported': {
      'zh': '内容包已导入并重新加载',
      'en': 'Content pack imported and reloaded',
    },
    'offlinePackRemoved': {'zh': '内容包已移除', 'en': 'Content pack removed'},
    'offlinePackCancelled': {'zh': '已取消选择', 'en': 'Selection cancelled'},
    'offlinePackInvalid': {
      'zh': '内容包无效：{error}',
      'en': 'Invalid content pack: {error}',
    },
  };

  String get(String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[localeCode] ?? entry['zh'] ?? key;
  }

  /// 全部词条 key（供测试与工具校验完整性）。
  static Iterable<String> get allKeys => _values.keys;

  /// 某个词条的原始内容（供测试校验中英文是否齐全）。
  static Map<String, String>? raw(String key) => _values[key];
}
