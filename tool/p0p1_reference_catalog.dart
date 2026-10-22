// P0/P1 逐课参考资料目录。
//
// 每个分类提供一批可追踪的官方文档、标准或权威教材。治理脚本按课程标题、
// 摘要和关键词给来源打分，再为每门课选择唯一的组合，避免整个分类复用同一组链接。
import 'dart:math' as math;

class ReferenceSource {
  const ReferenceSource({
    required this.name,
    required this.url,
    required this.scope,
    required this.tags,
  });

  final String name;
  final String url;
  final String scope;
  final String tags;
}

class LessonReferenceRequest {
  const LessonReferenceRequest({
    required this.lessonId,
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.keywords,
  });

  final String lessonId;
  final String categoryId;
  final String title;
  final String summary;
  final List<String> keywords;
}

class ReferenceSelection {
  const ReferenceSelection(this.lessonId, this.references);

  final String lessonId;
  final List<ReferenceSource> references;
}

/// 为整批课程选择参考资料。同一分类内不会出现两组完全相同的链接。
List<ReferenceSelection> selectLessonReferences(
  List<LessonReferenceRequest> lessons,
) {
  final byCategory = <String, List<LessonReferenceRequest>>{};
  for (final lesson in lessons) {
    byCategory
        .putIfAbsent(lesson.categoryId, () => <LessonReferenceRequest>[])
        .add(lesson);
  }

  final selected = <ReferenceSelection>[];
  for (final entry in byCategory.entries) {
    final sources = sourcesByCategory[entry.key] ?? _fallbackSources;
    final used = <String>{};
    for (var index = 0; index < entry.value.length; index++) {
      final lesson = entry.value[index];
      final picks = _pickForLesson(lesson, sources, used, index);
      if (picks.isEmpty) continue;
      used.add(_referenceSignature(picks));
      selected.add(ReferenceSelection(lesson.lessonId, picks));
    }
  }
  return selected;
}

List<ReferenceSource> _pickForLesson(
  LessonReferenceRequest lesson,
  List<ReferenceSource> sources,
  Set<String> used,
  int offset,
) {
  final ranked =
      sources.map((source) => (source, _score(source, lesson))).toList()
        ..sort((a, b) {
          final byScore = b.$2.compareTo(a.$2);
          return byScore != 0 ? byScore : a.$1.name.compareTo(b.$1.name);
        });

  final triples = <(double, List<ReferenceSource>)>[];
  for (var a = 0; a < ranked.length; a++) {
    for (var b = a + 1; b < ranked.length; b++) {
      for (var c = b + 1; c < ranked.length; c++) {
        triples.add((
          ranked[a].$2 + ranked[b].$2 + ranked[c].$2,
          <ReferenceSource>[ranked[a].$1, ranked[b].$1, ranked[c].$1],
        ));
      }
    }
  }
  triples.sort((a, b) {
    final byScore = b.$1.compareTo(a.$1);
    if (byScore != 0) return byScore;
    return a.$2
        .map((source) => source.url)
        .join('\n')
        .compareTo(b.$2.map((source) => source.url).join('\n'));
  });
  if (triples.isEmpty) {
    return sources.take(math.min(2, sources.length)).toList();
  }
  for (var shift = 0; shift < triples.length; shift++) {
    final candidate = triples[(offset + shift) % triples.length].$2;
    final key = _referenceSignature(candidate);
    if (!used.contains(key)) return candidate;
  }
  return triples[offset % triples.length].$2;
}

double _score(ReferenceSource source, LessonReferenceRequest lesson) {
  final haystack = <String>[
    lesson.title,
    lesson.summary,
    ...lesson.keywords,
    lesson.lessonId,
  ].join(' ').toLowerCase();
  var score = 0.0;
  for (final raw in source.tags.split(',')) {
    final tag = raw.trim().toLowerCase();
    if (tag.isNotEmpty && haystack.contains(tag)) {
      score += tag.length >= 4 ? 4.0 : 2.0;
    }
  }
  score += (lesson.lessonId.hashCode.abs() % 7) / 100.0;
  return score;
}

String _referenceSignature(List<ReferenceSource> references) {
  final urls = references.map((source) => source.url).toList()..sort();
  return urls.join('\n');
}

ReferenceSource _s(String name, String url, String scope, String tags) =>
    ReferenceSource(name: name, url: url, scope: scope, tags: tags);

const List<ReferenceSource> _fallbackSources = <ReferenceSource>[
  ReferenceSource(
    name: 'MDN Web Docs',
    url: 'https://developer.mozilla.org/',
    scope: 'Web 平台与通用计算概念',
    tags: 'web,计算机,基础',
  ),
  ReferenceSource(
    name: 'MIT OpenCourseWare',
    url: 'https://ocw.mit.edu/',
    scope: '计算机科学与工程基础课程',
    tags: '计算机,算法,系统,基础',
  ),
  ReferenceSource(
    name: 'RFC Editor',
    url: 'https://www.rfc-editor.org/',
    scope: '互联网协议标准原文',
    tags: '网络,协议,标准',
  ),
];

final Map<String, List<ReferenceSource>>
sourcesByCategory = <String, List<ReferenceSource>>{
  'flutter': <ReferenceSource>[
    _s(
      'Flutter UI 文档',
      'https://docs.flutter.dev/ui',
      'Widget、布局与渲染',
      'flutter,widget,布局,渲染,ui',
    ),
    _s(
      'Flutter 状态管理',
      'https://docs.flutter.dev/data-and-backend/state-mgmt/intro',
      '状态分层与重建范围',
      '状态,provider,riverpod,重建,生命周期',
    ),
    _s(
      'Flutter 性能最佳实践',
      'https://docs.flutter.dev/perf/best-practices',
      '帧率、构建与内存优化',
      '性能,优化,帧,内存,懒加载',
    ),
    _s(
      'Flutter 测试文档',
      'https://docs.flutter.dev/testing',
      '单元、组件与集成测试',
      '测试,回归,单元,集成',
    ),
    _s(
      'Android 发布指南',
      'https://docs.flutter.dev/deployment/android',
      '签名、构建与发布',
      '发布,android,apk,签名,构建',
    ),
    _s(
      'Dart 语言文档',
      'https://dart.dev/language',
      '语言语法、类型与空安全',
      'dart,语言,类型,空安全',
    ),
    _s(
      'Dart 异步编程',
      'https://dart.dev/libraries/async/async-await',
      'Future、Stream 与事件循环',
      '异步,future,stream,isolate,事件循环',
    ),
    _s(
      'Flutter 包与插件',
      'https://docs.flutter.dev/packages-and-plugins',
      '包管理、插件与平台通道',
      '包,插件,平台通道,依赖',
    ),
  ],
  'html_css': <ReferenceSource>[
    _s(
      'MDN HTML',
      'https://developer.mozilla.org/docs/Web/HTML',
      'HTML 语义与文档结构',
      'html,语义,表单,可访问性',
    ),
    _s(
      'MDN CSS',
      'https://developer.mozilla.org/docs/Web/CSS',
      'CSS 布局、选择器与动画',
      'css,样式,布局,动画,选择器',
    ),
    _s(
      'MDN JavaScript',
      'https://developer.mozilla.org/docs/Web/JavaScript',
      '浏览器脚本语言',
      'javascript,js,dom,事件',
    ),
    _s(
      'MDN DOM',
      'https://developer.mozilla.org/docs/Web/API/Document_Object_Model',
      'DOM 树与浏览器 API',
      'dom,元素,事件,浏览器',
    ),
    _s(
      'MDN 无障碍',
      'https://developer.mozilla.org/docs/Web/Accessibility',
      '可访问性与语义',
      '无障碍,可访问性,aria,语义',
    ),
    _s(
      'MDN HTTP',
      'https://developer.mozilla.org/docs/Web/HTTP',
      'HTTP 语义与缓存',
      'http,缓存,请求,响应,网络',
    ),
    _s(
      'W3C Web 标准',
      'https://www.w3.org/TR/',
      'HTML、CSS 与 Web 标准',
      '标准,w3c,web',
    ),
    _s(
      'web.dev 学习平台',
      'https://web.dev/learn/',
      '现代 Web 性能与最佳实践',
      'web,性能,响应式,最佳实践',
    ),
  ],
  'python': <ReferenceSource>[
    _s(
      'Python 教程',
      'https://docs.python.org/3/tutorial/',
      '语法、数据类型与控制流',
      'python,基础,语法,变量,类型,循环,函数',
    ),
    _s(
      'Python 语言参考',
      'https://docs.python.org/3/reference/',
      '语言语义与数据模型',
      'python,语义,对象,作用域,类',
    ),
    _s(
      'Python 标准库',
      'https://docs.python.org/3/library/',
      '标准库 API 与模块',
      'python,标准库,模块,json,re,pathlib',
    ),
    _s(
      'asyncio 文档',
      'https://docs.python.org/3/library/asyncio.html',
      '异步 I/O 与并发任务',
      'python,异步,asyncio,并发,协程',
    ),
    _s(
      'typing 文档',
      'https://docs.python.org/3/library/typing.html',
      '类型标注与泛型',
      'python,类型,typing,泛型,协议',
    ),
    _s(
      'unittest 文档',
      'https://docs.python.org/3/library/unittest.html',
      '测试组织与断言',
      'python,测试,unittest,断言',
    ),
    _s(
      'Python 打包指南',
      'https://packaging.python.org/',
      '依赖、构建与发布',
      'python,包,依赖,发布,venv,pip',
    ),
    _s(
      'Python 性能分析',
      'https://docs.python.org/3/library/profile.html',
      'cProfile 与性能分析',
      'python,性能,profile,基准',
    ),
    _s(
      'sqlite3 文档',
      'https://docs.python.org/3/library/sqlite3.html',
      'SQLite 持久化与事务',
      'python,sqlite,数据库,事务',
    ),
    _s('PEP 索引', 'https://peps.python.org/', '语言提案与版本演进', 'python,pep,版本,提案'),
  ],
  'cpp': <ReferenceSource>[
    _s(
      'cppreference C++ 语言',
      'https://en.cppreference.com/w/cpp/language',
      'C++ 语言规则与语义',
      'cpp,c++,语言,类型,作用域,模板',
    ),
    _s(
      'cppreference 标准库',
      'https://en.cppreference.com/w/cpp/standard_library',
      '标准库组件索引',
      'cpp,stl,标准库,容器,算法',
    ),
    _s(
      'C++ 内存管理',
      'https://en.cppreference.com/w/cpp/memory',
      'RAII、智能指针与所有权',
      'cpp,内存,指针,raii,智能指针,泄漏',
    ),
    _s(
      'C++ 并发支持库',
      'https://en.cppreference.com/w/cpp/thread',
      '线程、互斥与原子操作',
      'cpp,并发,线程,互斥,原子,锁',
    ),
    _s(
      'C++ 模板',
      'https://en.cppreference.com/w/cpp/language/templates',
      '模板、推导与泛型编程',
      'cpp,模板,泛型,推导',
    ),
    _s(
      'C++ Core Guidelines',
      'https://isocpp.github.io/CppCoreGuidelines/',
      '现代 C++ 工程规范',
      'cpp,规范,最佳实践,安全,现代',
    ),
    _s(
      'CMake 文档',
      'https://cmake.org/documentation/',
      '跨平台构建与依赖管理',
      'cpp,cmake,构建,项目',
    ),
    _s(
      'GDB 文档',
      'https://sourceware.org/gdb/documentation/',
      '断点、调用栈与内存调试',
      'cpp,调试,gdb,断点,崩溃',
    ),
    _s(
      'Google C++ 风格指南',
      'https://google.github.io/styleguide/cppguide.html',
      '命名、接口与工程约束',
      'cpp,风格,规范,工程',
    ),
    _s('C++ 标准委员会', 'https://isocpp.org/', '标准演进与提案动态', 'cpp,标准,版本,提案'),
  ],
  'c': <ReferenceSource>[
    _s(
      'cppreference C 语言',
      'https://en.cppreference.com/w/c/language',
      'C 语言规则与语义',
      'c,语言,类型,指针,数组,结构体',
    ),
    _s(
      'cppreference C 标准库',
      'https://en.cppreference.com/w/c',
      'C 标准库 API',
      'c,标准库,stdio,string,stdlib',
    ),
    _s(
      'GNU C Library',
      'https://www.gnu.org/software/libc/manual/',
      'POSIX 与 GNU C 接口',
      'c,glibc,posix,系统接口',
    ),
    _s(
      'GCC 文档',
      'https://gcc.gnu.org/onlinedocs/',
      '编译、链接与警告选项',
      'c,gcc,编译,链接,警告',
    ),
    _s(
      'GNU Make',
      'https://www.gnu.org/software/make/manual/',
      'Makefile 与构建依赖',
      'c,make,makefile,构建',
    ),
    _s(
      'GDB 文档',
      'https://sourceware.org/gdb/documentation/',
      'C 程序调试与崩溃定位',
      'c,调试,gdb,段错误,内存',
    ),
    _s(
      'POSIX 标准',
      'https://pubs.opengroup.org/onlinepubs/9799919799/',
      '可移植系统接口标准',
      'c,posix,标准,可移植',
    ),
    _s(
      'Valgrind 文档',
      'https://valgrind.org/docs/manual/manual.html',
      '内存错误与泄漏检测',
      'c,valgrind,内存,泄漏,未初始化',
    ),
  ],
  'java': <ReferenceSource>[
    _s(
      'dev.java 学习',
      'https://dev.java/learn/',
      '现代 Java 官方教程',
      'java,基础,语法,类,接口',
    ),
    _s(
      'Java 语言规范',
      'https://docs.oracle.com/javase/specs/jls/se21/html/index.html',
      '语言语义与类型规则',
      'java,语言,规范,类型',
    ),
    _s(
      'Java SE API',
      'https://docs.oracle.com/en/java/javase/21/docs/api/',
      '标准库 API',
      'java,api,标准库,集合,字符串',
    ),
    _s(
      'Java 并发教程',
      'https://docs.oracle.com/javase/tutorial/essential/concurrency/',
      '线程、同步与并发工具',
      'java,并发,线程,锁,同步',
    ),
    _s(
      'JVM 规范',
      'https://docs.oracle.com/javase/specs/jvms/se21/html/index.html',
      '字节码与运行时行为',
      'java,jvm,字节码,运行时',
    ),
    _s(
      'JDBC 教程',
      'https://docs.oracle.com/javase/tutorial/jdbc/',
      '数据库连接与事务',
      'java,jdbc,数据库,事务',
    ),
    _s(
      'Maven 指南',
      'https://maven.apache.org/guides/',
      '依赖、生命周期与构建',
      'java,maven,依赖,构建',
    ),
    _s(
      'Gradle 文档',
      'https://docs.gradle.org/current/userguide/userguide.html',
      '构建脚本与依赖管理',
      'java,gradle,构建,依赖',
    ),
    _s(
      'JUnit 用户指南',
      'https://junit.org/junit5/docs/current/user-guide/',
      '自动化测试与断言',
      'java,测试,junit,断言',
    ),
    _s(
      'Java GC 调优',
      'https://docs.oracle.com/en/java/javase/21/gctuning/',
      '垃圾回收与性能调优',
      'java,gc,垃圾回收,性能,内存',
    ),
  ],
  'kotlin': <ReferenceSource>[
    _s(
      'Kotlin 基础语法',
      'https://kotlinlang.org/docs/basic-syntax.html',
      '语法、类型与函数',
      'kotlin,基础,语法,类型,函数',
    ),
    _s(
      'Kotlin 协程',
      'https://kotlinlang.org/docs/coroutines-guide.html',
      '结构化并发与异步流',
      'kotlin,协程,并发,flow',
    ),
    _s(
      'Kotlin 多平台',
      'https://kotlinlang.org/docs/multiplatform.html',
      '跨平台共享与平台适配',
      'kotlin,多平台,kmp,跨平台',
    ),
    _s(
      'Android Kotlin',
      'https://developer.android.com/kotlin',
      'Android 官方 Kotlin 实践',
      'kotlin,android,activity,compose',
    ),
    _s(
      'Kotlin Serialization',
      'https://kotlinlang.org/docs/serialization.html',
      '序列化与数据模型',
      'kotlin,序列化,json',
    ),
    _s(
      'Kotlin 测试',
      'https://kotlinlang.org/docs/testing.html',
      '单元测试与断言',
      'kotlin,测试,junit',
    ),
    _s(
      'Kotlin Java 互操作',
      'https://kotlinlang.org/docs/java-interop.html',
      'Java 调用与类型映射',
      'kotlin,java,互操作',
    ),
    _s(
      'Android 架构指南',
      'https://developer.android.com/topic/architecture',
      '分层、状态与生命周期',
      'kotlin,android,架构,生命周期,状态',
    ),
  ],
  'swift': <ReferenceSource>[
    _s(
      'Swift 语言指南',
      'https://docs.swift.org/swift-book/documentation/the-swift-programming-language/',
      '语法、类型与内存模型',
      'swift,语言,类型,可选,值类型',
    ),
    _s(
      'Swift 官方文档',
      'https://www.swift.org/documentation/',
      '工具链、包管理与语言演进',
      'swift,工具链,包,文档',
    ),
    _s(
      'SwiftUI 文档',
      'https://developer.apple.com/documentation/swiftui',
      '声明式界面与状态',
      'swift,swiftui,界面,状态',
    ),
    _s(
      'Swift 并发',
      'https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/',
      'async/await 与 actor',
      'swift,并发,async,actor',
    ),
    _s(
      'Swift Package Manager',
      'https://www.swift.org/documentation/package-manager/',
      '依赖与模块化',
      'swift,spm,包,依赖',
    ),
    _s(
      'XCTest 文档',
      'https://developer.apple.com/documentation/xctest',
      '单元测试与 UI 测试',
      'swift,测试,xctest',
    ),
    _s(
      'Apple 内存管理',
      'https://developer.apple.com/documentation/swift/automatic-reference-counting',
      'ARC 与循环引用',
      'swift,arc,内存,循环引用,weak',
    ),
    _s(
      'Apple 人机界面指南',
      'https://developer.apple.com/design/human-interface-guidelines/',
      'iOS 设计规范与可访问性',
      'swift,ios,设计,界面,可访问性',
    ),
  ],
  'javascript': <ReferenceSource>[
    _s(
      'MDN JavaScript 指南',
      'https://developer.mozilla.org/docs/Web/JavaScript/Guide',
      '语言基础与浏览器 API',
      'javascript,js,语法,类型,函数',
    ),
    _s(
      'ECMAScript 标准',
      'https://tc39.es/ecma262/',
      'JavaScript 语言标准',
      'javascript,标准,ecmascript,语义',
    ),
    _s(
      'Node.js 文档',
      'https://nodejs.org/docs/latest/api/',
      '服务端运行时与模块',
      'javascript,node,后端,模块,fs',
    ),
    _s(
      'Node 事件循环',
      'https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick',
      '事件循环与异步顺序',
      'javascript,事件循环,异步,promise',
    ),
    _s(
      'MDN Promise',
      'https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Promise',
      'Promise 与异步链',
      'javascript,promise,async,await,异步',
    ),
    _s(
      'MDN Fetch API',
      'https://developer.mozilla.org/docs/Web/API/Fetch_API',
      '网络请求与响应处理',
      'javascript,fetch,http,请求',
    ),
    _s(
      'MDN 模块',
      'https://developer.mozilla.org/docs/Web/JavaScript/Guide/Modules',
      'ES Module 与依赖组织',
      'javascript,模块,import,export',
    ),
    _s('npm 文档', 'https://docs.npmjs.com/', '包管理与发布', 'javascript,npm,包,依赖'),
    _s(
      'Jest 文档',
      'https://jestjs.io/docs/getting-started',
      'JavaScript 测试与断言',
      'javascript,测试,jest,断言',
    ),
  ],
  'csharp': <ReferenceSource>[
    _s(
      'C# 指南',
      'https://learn.microsoft.com/dotnet/csharp/',
      '语言语法与类型系统',
      'csharp,c#,语言,类型,类',
    ),
    _s(
      '.NET 文档',
      'https://learn.microsoft.com/dotnet/',
      '运行时、库与工具链',
      'csharp,.net,运行时,库',
    ),
    _s(
      'C# 异步编程',
      'https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/',
      'async/await 与取消',
      'csharp,异步,async,await,取消',
    ),
    _s(
      'LINQ 文档',
      'https://learn.microsoft.com/dotnet/csharp/linq/',
      '查询、延迟执行与投影',
      'csharp,linq,查询,集合',
    ),
    _s(
      'EF Core 文档',
      'https://learn.microsoft.com/ef/core/',
      'ORM、迁移与并发',
      'csharp,efcore,数据库,orm,事务',
    ),
    _s(
      'ASP.NET Core 文档',
      'https://learn.microsoft.com/aspnet/core/',
      'Web API 与中间件',
      'csharp,aspnet,web,api',
    ),
    _s(
      'Blazor 文档',
      'https://learn.microsoft.com/aspnet/core/blazor/',
      '组件、状态与交互',
      'csharp,blazor,组件,ui',
    ),
    _s(
      '.NET 测试文档',
      'https://learn.microsoft.com/dotnet/core/testing/',
      '单元测试与集成测试',
      'csharp,测试,单元,集成',
    ),
    _s(
      '.NET GC 文档',
      'https://learn.microsoft.com/dotnet/standard/garbage-collection/',
      '垃圾回收与内存',
      'csharp,gc,内存,垃圾回收,性能',
    ),
    _s(
      'dotnet CLI',
      'https://learn.microsoft.com/dotnet/core/tools/',
      '构建、运行与发布命令',
      'csharp,cli,构建,发布,dotnet',
    ),
  ],
  'go': <ReferenceSource>[
    _s('Go 官方教程', 'https://go.dev/tour/', '语言基础与并发入门', 'go,golang,基础,语法,并发'),
    _s(
      'Effective Go',
      'https://go.dev/doc/effective_go',
      '惯用写法与接口设计',
      'go,规范,接口,错误,工程',
    ),
    _s('Go 标准库', 'https://pkg.go.dev/std', '标准库 API', 'go,标准库,api,json,http'),
    _s(
      'Go 并发',
      'https://go.dev/talks/2012/concurrency.slide',
      'goroutine 与 channel',
      'go,并发,goroutine,channel,锁',
    ),
    _s(
      'Go Modules',
      'https://go.dev/doc/modules/',
      '模块、版本与依赖',
      'go,module,依赖,版本',
    ),
    _s(
      'Go 测试',
      'https://go.dev/doc/tutorial/add-a-test',
      '测试、基准与覆盖率',
      'go,测试,benchmark,覆盖率',
    ),
    _s(
      'Go pprof',
      'https://pkg.go.dev/net/http/pprof',
      '性能剖析与火焰图',
      'go,性能,pprof,剖析,内存',
    ),
    _s(
      'database/sql',
      'https://pkg.go.dev/database/sql',
      '数据库连接、事务与预编译',
      'go,数据库,sql,事务',
    ),
    _s(
      'net/http',
      'https://pkg.go.dev/net/http',
      'HTTP 客户端与服务端',
      'go,http,服务,路由,客户端',
    ),
    _s('Go 内存模型', 'https://go.dev/ref/mem', '并发读写与同步语义', 'go,内存模型,同步,竞态'),
  ],
  'rust': <ReferenceSource>[
    _s(
      'The Rust Book',
      'https://doc.rust-lang.org/book/',
      '所有权、类型与工程实践',
      'rust,所有权,借用,类型,基础',
    ),
    _s(
      'Rust 标准库',
      'https://doc.rust-lang.org/std/',
      '标准库 API 与容器',
      'rust,标准库,集合,字符串,迭代器',
    ),
    _s(
      'Rustonomicon',
      'https://doc.rust-lang.org/nomicon/',
      'unsafe 与内存布局',
      'rust,unsafe,内存,指针,布局',
    ),
    _s(
      'Rust Async Book',
      'https://rust-lang.github.io/async-book/',
      '异步运行时与 Future',
      'rust,异步,async,future,tokio',
    ),
    _s(
      'Cargo Book',
      'https://doc.rust-lang.org/cargo/',
      '依赖、工作区与发布',
      'rust,cargo,依赖,工作区,发布',
    ),
    _s(
      'Clippy 文档',
      'https://doc.rust-lang.org/clippy/',
      'Lint 与惯用写法',
      'rust,clippy,lint,规范',
    ),
    _s(
      'Tokio 文档',
      'https://tokio.rs/tokio/tutorial',
      '异步运行时与任务',
      'rust,tokio,异步,任务',
    ),
    _s(
      'Axum 文档',
      'https://docs.rs/axum/latest/axum/',
      'Web 路由与提取器',
      'rust,axum,web,api,路由',
    ),
    _s(
      'Rust 测试',
      'https://doc.rust-lang.org/book/ch11-00-testing.html',
      '单元测试与集成测试',
      'rust,测试,断言,集成',
    ),
  ],
  'typescript': <ReferenceSource>[
    _s(
      'TypeScript Handbook',
      'https://www.typescriptlang.org/docs/handbook/intro.html',
      '类型系统与语言指南',
      'typescript,ts,类型,接口,泛型',
    ),
    _s(
      'Everyday Types',
      'https://www.typescriptlang.org/docs/handbook/2/everyday-types.html',
      '常用类型与收窄',
      'typescript,类型,联合,收窄',
    ),
    _s(
      '泛型文档',
      'https://www.typescriptlang.org/docs/handbook/2/generics.html',
      '泛型约束与复用',
      'typescript,泛型,约束',
    ),
    _s(
      'Utility Types',
      'https://www.typescriptlang.org/docs/handbook/utility-types.html',
      '内置类型变换',
      'typescript,工具类型,映射,条件类型',
    ),
    _s(
      '装饰器文档',
      'https://www.typescriptlang.org/docs/handbook/decorators.html',
      '装饰器与元数据',
      'typescript,装饰器,元数据',
    ),
    _s(
      'tsconfig 参考',
      'https://www.typescriptlang.org/tsconfig/',
      '编译选项与严格模式',
      'typescript,tsconfig,编译,配置',
    ),
    _s(
      'TypeScript Node 指南',
      'https://nodejs.org/en/learn/typescript',
      'Node 中的 TypeScript',
      'typescript,node,后端,运行时',
    ),
    _s(
      '声明文件',
      'https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html',
      '类型声明与发布',
      'typescript,声明,d.ts,类型',
    ),
    _s(
      '项目引用',
      'https://www.typescriptlang.org/docs/handbook/project-references.html',
      '大型项目拆分与增量构建',
      'typescript,项目引用,monorepo,构建',
    ),
    _s(
      'TypeScript 发布说明',
      'https://www.typescriptlang.org/docs/release-notes/',
      '版本变化与兼容性',
      'typescript,版本,发布,兼容',
    ),
  ],
  'shell': <ReferenceSource>[
    _s(
      'GNU Bash 手册',
      'https://www.gnu.org/software/bash/manual/',
      'Bash 语法、展开与作业控制',
      'shell,bash,变量,循环,函数,脚本',
    ),
    _s(
      'POSIX Shell 标准',
      'https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html',
      '可移植 Shell 语法',
      'shell,posix,可移植,标准',
    ),
    _s(
      'GNU Coreutils',
      'https://www.gnu.org/software/coreutils/manual/',
      '文件、文本与进程工具',
      'shell,coreutils,ls,cp,文本,进程',
    ),
    _s(
      'GNU Findutils',
      'https://www.gnu.org/software/findutils/manual/',
      'find、xargs 与文件检索',
      'shell,find,xargs,文件',
    ),
    _s(
      'GNU sed',
      'https://www.gnu.org/software/sed/manual/sed.html',
      '流式文本替换',
      'shell,sed,文本,正则,替换',
    ),
    _s(
      'GNU awk',
      'https://www.gnu.org/software/gawk/manual/',
      '字段处理与报表',
      'shell,awk,文本,字段,日志',
    ),
    _s(
      'GNU grep',
      'https://www.gnu.org/software/grep/manual/',
      '模式匹配与过滤',
      'shell,grep,正则,过滤',
    ),
    _s(
      'ShellCheck 文档',
      'https://www.shellcheck.net/wiki/',
      '脚本缺陷与安全写法',
      'shell,shellcheck,安全,规范,缺陷',
    ),
    _s('jq 手册', 'https://jqlang.org/manual/', 'JSON 查询与转换', 'shell,jq,json,过滤'),
    _s(
      'cron 手册',
      'https://man7.org/linux/man-pages/man5/crontab.5.html',
      '定时任务与调度',
      'shell,cron,定时,调度',
    ),
  ],
  'fundamentals': <ReferenceSource>[
    _s(
      'NIST 二进制与数据表示',
      'https://www.nist.gov/pml/owm/binary-information',
      '二进制、位与数据单位',
      '二进制,位,字节,编码,数字',
    ),
    _s(
      'Linux 内核文档',
      'https://docs.kernel.org/',
      '操作系统与硬件接口',
      '操作系统,内核,进程,内存,驱动',
    ),
    _s(
      'Arm 架构文档',
      'https://developer.arm.com/documentation',
      '处理器与内存体系结构',
      'cpu,arm,指令,缓存,架构',
    ),
    _s(
      'Intel 开发者文档',
      'https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html',
      'x86 指令集与体系结构',
      'cpu,x86,指令,流水线,缓存',
    ),
    _s(
      'MIT 6.004 计算结构',
      'https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/',
      '数字逻辑、ISA 与计算机组织',
      '数字电路,逻辑,isa,计算机组成',
    ),
    _s(
      'MIT 6.006 算法导论',
      'https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/',
      '算法与数据结构基础',
      '算法,数据结构,复杂度',
    ),
    _s(
      'MIT 6.033 计算机系统工程',
      'https://ocw.mit.edu/courses/6-033-computer-system-engineering-spring-2018/',
      '系统设计与并发',
      '操作系统,系统,并发,分布式',
    ),
    _s(
      'CS50 计算机科学导论',
      'https://cs50.harvard.edu/x/',
      '计算机科学综合入门',
      '计算机,编程,算法,内存',
    ),
    _s(
      'Nand2Tetris',
      'https://www.nand2tetris.org/',
      '从逻辑门到计算机系统',
      '数字逻辑,cpu,汇编,编译',
    ),
    _s(
      'MDN 计算机基础',
      'https://developer.mozilla.org/docs/Learn_web_development/Core',
      'Web 相关计算机基础',
      '计算机,web,基础,网络',
    ),
  ],
  'algorithms': <ReferenceSource>[
    _s(
      'CP-Algorithms',
      'https://cp-algorithms.com/',
      '算法实现与复杂度',
      '算法,数据结构,图,动态规划,排序',
    ),
    _s(
      'MIT 6.006',
      'https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/',
      '算法设计与分析',
      '算法,复杂度,排序,图,动态规划',
    ),
    _s(
      'Princeton Algorithms',
      'https://algs4.cs.princeton.edu/home/',
      '经典算法与数据结构教材',
      '算法,数据结构,排序,查找,图',
    ),
    _s('VisuAlgo', 'https://visualgo.net/en', '算法可视化与交互', '算法,可视化,排序,图,树'),
    _s(
      'OpenDSA',
      'https://opendsa-server.cs.vt.edu/',
      '数据结构互动教材',
      '数据结构,树,图,排序',
    ),
    _s(
      'Big-O Cheat Sheet',
      'https://www.bigocheatsheet.com/',
      '复杂度速查',
      '复杂度,大o,时间,空间',
    ),
    _s('RFC 算法与协议', 'https://www.rfc-editor.org/', '协议中的算法约束', '算法,协议,网络'),
    _s(
      'LeetCode 学习',
      'https://leetcode.com/explore/',
      '算法题训练与模式',
      '算法,练习,面试,题目',
    ),
    _s(
      'GeeksforGeeks 算法',
      'https://www.geeksforgeeks.org/fundamentals-of-algorithms/',
      '算法专题与实现',
      '算法,排序,查找,图,动态规划',
    ),
    _s('OI Wiki', 'https://oi-wiki.org/', '竞赛算法与数据结构', '算法,竞赛,数据结构,图'),
  ],
  'network': <ReferenceSource>[
    _s(
      'RFC 9110 HTTP 语义',
      'https://www.rfc-editor.org/rfc/rfc9110',
      'HTTP 方法、状态与缓存',
      'http,请求,响应,缓存,rest',
    ),
    _s(
      'RFC 9112 HTTP/1.1',
      'https://www.rfc-editor.org/rfc/rfc9112',
      'HTTP/1.1 报文与连接',
      'http,http1.1,连接,报文',
    ),
    _s(
      'RFC 9113 HTTP/2',
      'https://www.rfc-editor.org/rfc/rfc9113',
      'HTTP/2 多路复用与流',
      'http2,多路复用,流,帧',
    ),
    _s(
      'RFC 9000 QUIC',
      'https://www.rfc-editor.org/rfc/rfc9000',
      'QUIC 传输与连接迁移',
      'quic,udp,传输,加密',
    ),
    _s(
      'RFC 9293 TCP',
      'https://www.rfc-editor.org/rfc/rfc9293',
      'TCP 连接、重传与拥塞',
      'tcp,连接,重传,拥塞,三次握手',
    ),
    _s(
      'RFC 1035 DNS',
      'https://www.rfc-editor.org/rfc/rfc1035',
      'DNS 报文与解析',
      'dns,域名,解析,报文',
    ),
    _s(
      'RFC 8446 TLS 1.3',
      'https://www.rfc-editor.org/rfc/rfc8446',
      'TLS 握手与加密',
      'tls,加密,证书,握手,https',
    ),
    _s(
      'MDN HTTP',
      'https://developer.mozilla.org/docs/Web/HTTP',
      '浏览器视角的 HTTP',
      'http,浏览器,缓存,cors',
    ),
    _s(
      'IANA 协议注册表',
      'https://www.iana.org/protocols',
      '端口、协议号与参数',
      '协议,端口,iana,标准',
    ),
    _s(
      'Cloudflare Learning',
      'https://www.cloudflare.com/learning/',
      '网络概念与安全解释',
      '网络,dns,cdn,ddos,http',
    ),
  ],
  'security': <ReferenceSource>[
    _s(
      'OWASP Top 10',
      'https://owasp.org/www-project-top-ten/',
      '常见 Web 安全风险',
      '安全,owasp,注入,xss,风险',
    ),
    _s(
      'OWASP Cheat Sheets',
      'https://cheatsheetseries.owasp.org/',
      '认证、授权与安全编码',
      '安全,认证,授权,会话,加密',
    ),
    _s(
      'OWASP ASVS',
      'https://owasp.org/www-project-application-security-verification-standard/',
      '应用安全验证要求',
      '安全,审计,验证,标准',
    ),
    _s(
      'PortSwigger Web Security Academy',
      'https://portswigger.net/web-security',
      '漏洞原理与实验',
      '安全,漏洞,xss,sql注入,csrf',
    ),
    _s(
      'NIST 网络安全框架',
      'https://www.nist.gov/cyberframework',
      '风险管理与治理',
      '安全,风险,治理,nist',
    ),
    _s('CWE 弱点列表', 'https://cwe.mitre.org/', '软件弱点分类', '安全,弱点,cwe,漏洞'),
    _s(
      'MITRE ATT&CK',
      'https://attack.mitre.org/',
      '攻击技术与防御映射',
      '安全,攻击,防御,mitre',
    ),
    _s(
      'CIS Benchmarks',
      'https://www.cisecurity.org/cis-benchmarks',
      '系统安全基线',
      '安全,基线,加固,配置',
    ),
    _s(
      'NIST 密码标准',
      'https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines',
      '密码算法与协议',
      '安全,密码,加密,哈希',
    ),
  ],
  'database': <ReferenceSource>[
    _s(
      'PostgreSQL 文档',
      'https://www.postgresql.org/docs/',
      'SQL、索引、事务与并发',
      '数据库,sql,postgresql,索引,事务',
    ),
    _s(
      'SQLite 文档',
      'https://sqlite.org/docs.html',
      '嵌入式 SQL 与事务',
      '数据库,sqlite,sql,事务',
    ),
    _s(
      'MySQL 文档',
      'https://dev.mysql.com/doc/',
      '关系数据库与 InnoDB',
      '数据库,mysql,innodb,索引,事务',
    ),
    _s(
      'MongoDB 文档',
      'https://www.mongodb.com/docs/',
      '文档数据库与聚合',
      '数据库,mongodb,文档,nosql',
    ),
    _s(
      'Redis 文档',
      'https://redis.io/docs/latest/',
      '缓存、数据结构与持久化',
      '数据库,redis,缓存,键值',
    ),
    _s(
      'Use The Index, Luke',
      'https://use-the-index-luke.com/',
      'SQL 索引与查询优化',
      '数据库,索引,优化,sql,执行计划',
    ),
    _s(
      'SQL 标准概览',
      'https://www.iso.org/standard/76583.html',
      'SQL 标准范围',
      '数据库,sql,标准,iso',
    ),
    _s(
      'PostgreSQL 事务教程',
      'https://www.postgresql.org/docs/current/tutorial-transactions.html',
      'ACID 与隔离级别',
      '数据库,事务,acid,隔离',
    ),
    _s(
      'JDBC 事务',
      'https://docs.oracle.com/javase/tutorial/jdbc/basics/transactions.html',
      '连接事务与回滚',
      '数据库,事务,jdbc,回滚',
    ),
    _s(
      '数据库规范化',
      'https://learn.microsoft.com/office/troubleshoot/access/database-normalization-description',
      '范式与表设计',
      '数据库,设计,范式,表',
    ),
  ],
  'os': <ReferenceSource>[
    _s(
      'Linux 内核文档',
      'https://docs.kernel.org/',
      '调度、内存、文件系统与 I/O',
      '操作系统,linux,内核,进程,内存,调度',
    ),
    _s(
      'Linux man-pages',
      'https://man7.org/linux/man-pages/',
      '系统调用与用户态接口',
      '操作系统,系统调用,进程,文件,信号',
    ),
    _s(
      'POSIX 标准',
      'https://pubs.opengroup.org/onlinepubs/9799919799/',
      '可移植操作系统接口',
      '操作系统,posix,标准,进程,线程',
    ),
    _s(
      'OSTEP',
      'https://pages.cs.wisc.edu/~remzi/OSTEP/',
      '操作系统导论教材',
      '操作系统,进程,内存,文件,并发',
    ),
    _s(
      'MIT xv6',
      'https://pdos.csail.mit.edu/6.828/2023/xv6.html',
      '教学内核与系统调用',
      '操作系统,内核,进程,虚拟内存',
    ),
    _s(
      'LWN 内核文章',
      'https://lwn.net/Kernel/Index/',
      '内核机制与演进',
      '操作系统,linux,内核,调度,内存',
    ),
    _s(
      'systemd 文档',
      'https://www.freedesktop.org/software/systemd/man/latest/',
      '服务、日志与资源控制',
      '操作系统,systemd,服务,日志,cgroup',
    ),
    _s(
      'GNU C Library',
      'https://www.gnu.org/software/libc/manual/',
      '进程、线程与系统接口',
      '操作系统,glibc,线程,进程,文件',
    ),
    _s(
      'QEMU 文档',
      'https://www.qemu.org/docs/master/',
      '虚拟化与系统模拟',
      '操作系统,虚拟化,qemu,模拟',
    ),
    _s(
      'Linux 性能事件',
      'https://perf.wiki.kernel.org/',
      '性能分析与内核事件',
      '操作系统,性能,perf,追踪',
    ),
  ],
  'toolchain': <ReferenceSource>[
    _s('Git 文档', 'https://git-scm.com/doc', '版本控制与分支模型', 'git,版本控制,分支,合并'),
    _s(
      'Pro Git',
      'https://git-scm.com/book/zh/v2',
      'Git 原理与协作流程',
      'git,提交,rebase,远程',
    ),
    _s(
      'Docker 文档',
      'https://docs.docker.com/',
      '镜像、容器与网络',
      'docker,容器,镜像,compose',
    ),
    _s(
      'Kubernetes 文档',
      'https://kubernetes.io/docs/',
      '编排、服务与配置',
      'kubernetes,k8s,容器,部署',
    ),
    _s(
      'GitHub Actions',
      'https://docs.github.com/actions',
      'CI/CD 工作流',
      'ci,cd,github actions,流水线',
    ),
    _s(
      'CMake 文档',
      'https://cmake.org/documentation/',
      '跨平台构建与依赖',
      'cmake,构建,依赖,编译',
    ),
    _s(
      'GNU Make',
      'https://www.gnu.org/software/make/manual/',
      '构建规则与增量编译',
      'make,makefile,构建',
    ),
    _s(
      'Maven 指南',
      'https://maven.apache.org/guides/',
      'Java 构建与依赖',
      'maven,构建,依赖,java',
    ),
    _s(
      'npm 文档',
      'https://docs.npmjs.com/',
      'JavaScript 包管理',
      'npm,包管理,依赖,javascript',
    ),
    _s(
      'Gradle 文档',
      'https://docs.gradle.org/current/userguide/userguide.html',
      '构建脚本与插件',
      'gradle,构建,插件,java',
    ),
  ],
  'ai': <ReferenceSource>[
    _s(
      'OpenAI 开发者文档',
      'https://platform.openai.com/docs/',
      '模型 API、工具与评估',
      'ai,大模型,openai,api,工具,agents',
    ),
    _s(
      'OpenAI Cookbook',
      'https://cookbook.openai.com/',
      'RAG、Agent 与工程示例',
      'ai,rag,agent,示例,评估',
    ),
    _s(
      'Hugging Face 文档',
      'https://huggingface.co/docs',
      '模型、数据集与推理',
      'ai,模型,数据集,transformer,推理',
    ),
    _s(
      'Model Context Protocol',
      'https://modelcontextprotocol.io/',
      'Agent 工具与上下文协议',
      'ai,agent,mcp,工具,协议',
    ),
    _s(
      'LangChain 文档',
      'https://python.langchain.com/docs/',
      'Agent、RAG 与工作流编排',
      'ai,langchain,agent,rag,工作流',
    ),
    _s(
      'LlamaIndex 文档',
      'https://docs.llamaindex.ai/',
      '索引、检索与数据框架',
      'ai,rag,索引,检索,llamaindex',
    ),
    _s(
      'PyTorch 文档',
      'https://pytorch.org/docs/stable/index.html',
      '张量、训练与推理',
      'ai,深度学习,pytorch,训练,张量',
    ),
    _s(
      'TensorFlow 文档',
      'https://www.tensorflow.org/api_docs',
      '模型构建与部署',
      'ai,深度学习,tensorflow,训练,部署',
    ),
    _s(
      'scikit-learn 文档',
      'https://scikit-learn.org/stable/documentation.html',
      '经典机器学习算法',
      'ai,机器学习,sklearn,分类,回归',
    ),
    _s(
      'Anthropic 文档',
      'https://docs.anthropic.com/',
      'Claude API 与 Agent 安全',
      'ai,agent,claude,安全,提示词',
    ),
    _s('Ollama 文档', 'https://ollama.com/', '本地模型运行与部署', 'ai,本地模型,推理,ollama'),
    _s(
      'Google AI 文档',
      'https://ai.google.dev/gemini-api/docs',
      'Gemini API 与多模态',
      'ai,多模态,gemini,api',
    ),
  ],
  'distributed': <ReferenceSource>[
    _s('CNCF 技术地图', 'https://landscape.cncf.io/', '云原生技术生态', '分布式,云原生,cncf,容器'),
    _s(
      'Google SRE 书',
      'https://sre.google/books/',
      '可靠性、容量与事故响应',
      '分布式,可靠性,sre,容量,故障',
    ),
    _s(
      'AWS 架构中心',
      'https://aws.amazon.com/architecture/',
      '高可用与云架构模式',
      '分布式,高可用,云,架构',
    ),
    _s(
      'Microsoft 云设计模式',
      'https://learn.microsoft.com/azure/architecture/patterns/',
      '重试、熔断与队列模式',
      '分布式,设计模式,重试,熔断,队列',
    ),
    _s(
      'Martin Fowler 微服务',
      'https://martinfowler.com/articles/microservices.html',
      '服务边界与演进',
      '分布式,微服务,架构,服务',
    ),
    _s(
      'Martin Fowler 事件驱动',
      'https://martinfowler.com/articles/201701-event-driven.html',
      '事件、消息与一致性',
      '分布式,事件,消息,一致性',
    ),
    _s(
      'Apache Kafka 文档',
      'https://kafka.apache.org/documentation/',
      '日志、分区与消费组',
      '分布式,kafka,消息,分区',
    ),
    _s(
      'CAP 定理资料',
      'https://www.cs.princeton.edu/courses/archive/fall20/cos418/papers/brew.pdf',
      '一致性、可用性与分区',
      '分布式,cap,一致性,可用性',
    ),
    _s(
      'Google 分布式系统论文',
      'https://research.google/pubs/',
      '共识、存储与调度论文',
      '分布式,共识,存储,调度,论文',
    ),
  ],
  'software_engineering': <ReferenceSource>[
    _s(
      'Google SWE Book',
      'https://abseil.io/resources/swe-book',
      '工程规范、评审与维护',
      '软件工程,规范,代码评审,维护',
    ),
    _s(
      'Martin Fowler 架构',
      'https://martinfowler.com/architecture/',
      '架构、重构与演进',
      '软件工程,架构,重构,设计',
    ),
    _s(
      'Refactoring Catalog',
      'https://refactoring.com/catalog/',
      '重构手法与代码坏味道',
      '软件工程,重构,坏味道,设计',
    ),
    _s('DORA 能力模型', 'https://dora.dev/', '交付性能与工程效能', '软件工程,devops,交付,ci,cd'),
    _s(
      'The Twelve-Factor App',
      'https://12factor.net/',
      '可部署应用设计原则',
      '软件工程,部署,配置,日志',
    ),
    _s('C4 Model', 'https://c4model.com/', '架构图与系统上下文', '软件工程,架构,图,系统设计'),
    _s('ADR 文档', 'https://adr.github.io/', '架构决策记录', '软件工程,架构决策,文档,adr'),
    _s('OWASP SAMM', 'https://owaspsamm.org/', '软件安全成熟度', '软件工程,安全,成熟度,开发'),
    _s(
      'Semantic Versioning',
      'https://semver.org/',
      '版本兼容与发布约定',
      '软件工程,版本,发布,兼容',
    ),
  ],
  'math': <ReferenceSource>[
    _s(
      'MIT 线性代数',
      'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/',
      '向量、矩阵与线性变换',
      '数学,线代,矩阵,向量,变换',
    ),
    _s('NIST DLMF', 'https://dlmf.nist.gov/', '数学函数与公式参考', '数学,公式,函数,参考'),
    _s(
      'OpenStax 微积分',
      'https://openstax.org/details/books/calculus-volume-1',
      '极限、导数与积分',
      '数学,微积分,导数,积分',
    ),
    _s(
      'OpenStax 概率统计',
      'https://openstax.org/details/books/introductory-statistics',
      '概率、分布与统计推断',
      '数学,概率,统计,分布',
    ),
    _s(
      'Khan Academy 数学',
      'https://www.khanacademy.org/math',
      '从基础算术到高等数学',
      '数学,基础,代数,概率,微积分',
    ),
    _s(
      'Wolfram MathWorld',
      'https://mathworld.wolfram.com/',
      '数学概念与公式查询',
      '数学,公式,概念,离散',
    ),
    _s(
      'MIT 离散数学',
      'https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/',
      '逻辑、证明与离散结构',
      '数学,离散,逻辑,证明,图',
    ),
    _s('NIST 数字图书馆', 'https://www.nist.gov/pml', '计量、数值与科学数据', '数学,数值,计量,科学'),
    _s('OEIS 数列百科', 'https://oeis.org/', '整数序列与组合关系', '数学,数列,组合,整数'),
  ],
  'cross_language': <ReferenceSource>[
    _s(
      'MDN Web Docs',
      'https://developer.mozilla.org/',
      'Web 技术跨语言参考',
      '跨语言,web,javascript,css,http',
    ),
    _s('DevDocs', 'https://devdocs.io/', '多语言 API 快速检索', '跨语言,api,文档,语言'),
    _s(
      'Rosetta Code',
      'https://rosettacode.org/wiki/Rosetta_Code',
      '同一任务的跨语言实现',
      '跨语言,实现,对照,算法',
    ),
    _s('Exercism', 'https://exercism.org/docs', '多语言练习与反馈', '跨语言,练习,语言,测试'),
    _s(
      'Learn X in Y minutes',
      'https://learnxinyminutes.com/',
      '语言语法速览',
      '跨语言,语法,速览',
    ),
    _s(
      'Programming Languages DB',
      'https://pldb.io/',
      '语言特性与生态对照',
      '跨语言,语言,特性,生态',
    ),
    _s(
      'Compiler Explorer',
      'https://godbolt.org/',
      '不同编译器与汇编对照',
      '跨语言,编译,汇编,优化',
    ),
    _s(
      'Open Source Guides',
      'https://opensource.guide/',
      '跨语言协作与项目规范',
      '跨语言,开源,协作,规范',
    ),
  ],
  'visual_guide': <ReferenceSource>[
    _s(
      'RFC Editor',
      'https://www.rfc-editor.org/',
      '协议状态机与报文流程',
      '可视化,协议,流程,标准',
    ),
    _s(
      'MDN 浏览器工作原理',
      'https://developer.mozilla.org/docs/Web/Performance/How_browsers_work',
      '从请求到渲染的流程',
      '可视化,浏览器,渲染,网络',
    ),
    _s(
      'Mermaid 文档',
      'https://mermaid.js.org/intro/',
      '流程图、时序图与状态图',
      '可视化,图表,流程,时序图',
    ),
    _s('PlantUML 文档', 'https://plantuml.com/', 'UML 与架构图表达', '可视化,uml,架构图,类图'),
    _s('Diagrams.net 文档', 'https://www.drawio.com/doc/', '通用图表绘制', '可视化,图表,绘图'),
    _s(
      'Kubernetes 架构',
      'https://kubernetes.io/docs/concepts/architecture/',
      '控制平面与节点流程',
      '可视化,kubernetes,架构,流程',
    ),
    _s(
      'Cloudflare Learning',
      'https://www.cloudflare.com/learning/',
      '网络流程与概念图解',
      '可视化,网络,dns,http',
    ),
    _s(
      'Pro Git 内部原理',
      'https://git-scm.com/book/zh/v2/Git-内部原理-Git-对象',
      'Git 对象与引用关系',
      '可视化,git,对象,引用',
    ),
    _s('W3C 规范', 'https://www.w3.org/TR/', 'Web 标准结构图', '可视化,web,标准,结构'),
  ],
  'project_practice': <ReferenceSource>[
    _s(
      'The Twelve-Factor App',
      'https://12factor.net/',
      '配置、日志与可部署性',
      '项目,部署,配置,日志,工程',
    ),
    _s(
      'Google SRE 书',
      'https://sre.google/books/',
      '可靠性、监控与事故响应',
      '项目,可靠性,监控,故障,sre',
    ),
    _s(
      'OpenAI Cookbook',
      'https://cookbook.openai.com/',
      'AI 应用与评估实践',
      '项目,ai,rag,agent,评估',
    ),
    _s(
      'Docker 入门',
      'https://docs.docker.com/get-started/',
      '容器化与 Compose',
      '项目,docker,容器,部署',
    ),
    _s(
      'Kubernetes 教程',
      'https://kubernetes.io/docs/tutorials/',
      '部署、服务与配置',
      '项目,kubernetes,部署,服务',
    ),
    _s(
      'GitHub Actions 文档',
      'https://docs.github.com/actions',
      '自动构建、测试与发布',
      '项目,ci,cd,测试,发布',
    ),
    _s(
      'OWASP ASVS',
      'https://owasp.org/www-project-application-security-verification-standard/',
      '项目安全验收',
      '项目,安全,验收,审计',
    ),
    _s(
      'OpenTelemetry 文档',
      'https://opentelemetry.io/docs/',
      '日志、指标与链路追踪',
      '项目,可观测性,日志,指标,追踪',
    ),
    _s(
      'PostgreSQL 教程',
      'https://www.postgresql.org/docs/current/tutorial.html',
      '数据建模与事务实践',
      '项目,数据库,事务,sql',
    ),
  ],
};
