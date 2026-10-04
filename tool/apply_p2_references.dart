// P2 逐课参考资料与复核日期工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_p2_references.dart [--dry-run]
//
// 每篇课程追加“参考资料与复核”块，标明官方文档来源、适用范围和下次复核时间。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- p2-references:v1 -->';
const String reviewedAt = '2026-10-04';
const String nextReviewAt = '2027-04-04';

class Source {
  const Source(this.name, this.url, this.scope);

  final String name;
  final String url;
  final String scope;
}

const Map<String, List<Source>> sourcesByCategory = <String, List<Source>>{
  'flutter': [
    Source('Flutter 官方文档', 'https://docs.flutter.dev/', '框架、组件与发布流程'),
    Source('Dart 官方文档', 'https://dart.dev/guides', '语言、异步与工具链'),
  ],
  'html_css': [
    Source(
      'MDN Web Docs',
      'https://developer.mozilla.org/docs/Web',
      'HTML、CSS 与浏览器行为',
    ),
    Source('W3C Standards', 'https://www.w3.org/TR/', 'Web 标准与可访问性规范'),
  ],
  'python': [
    Source('Python 官方文档', 'https://docs.python.org/3/', '语言、标准库与版本行为'),
    Source('Python Packaging', 'https://packaging.python.org/', '包管理与发布'),
  ],
  'cpp': [
    Source('C++ 标准库参考', 'https://en.cppreference.com/w/cpp', '语言、标准库与并发'),
    Source('ISO C++', 'https://isocpp.org/', '标准动态、指南与最佳实践'),
  ],
  'c': [
    Source('C 标准库参考', 'https://en.cppreference.com/w/c', 'C 语言与标准库'),
    Source(
      'GNU C Manual',
      'https://www.gnu.org/software/libc/manual/',
      'POSIX 与系统接口',
    ),
  ],
  'java': [
    Source(
      'Java SE API',
      'https://docs.oracle.com/en/java/javase/',
      '语言、标准库与 JVM',
    ),
    Source('dev.java', 'https://dev.java/learn/', '现代 Java 官方教程'),
  ],
  'kotlin': [
    Source('Kotlin 官方文档', 'https://kotlinlang.org/docs/home.html', '语言、协程与互操作'),
    Source(
      'Android Kotlin',
      'https://developer.android.com/kotlin',
      'Android 工程实践',
    ),
  ],
  'swift': [
    Source('Swift 官方文档', 'https://www.swift.org/documentation/', '语言、并发与包管理'),
    Source(
      'Apple Developer',
      'https://developer.apple.com/documentation/swift',
      '平台 API 与工具链',
    ),
  ],
  'javascript': [
    Source(
      'MDN JavaScript',
      'https://developer.mozilla.org/docs/Web/JavaScript',
      '语言、DOM 与运行时',
    ),
    Source(
      'ECMAScript',
      'https://ecma-international.org/publications-and-standards/standards/ecma-262/',
      '语言标准',
    ),
  ],
  'csharp': [
    Source(
      'C# 官方指南',
      'https://learn.microsoft.com/dotnet/csharp/',
      '语言、异步与模式匹配',
    ),
    Source('.NET 文档', 'https://learn.microsoft.com/dotnet/', '运行时、GC 与发布'),
  ],
  'go': [
    Source('Go 官方文档', 'https://go.dev/doc/', '语言、并发与工具链'),
    Source('Go 标准库', 'https://pkg.go.dev/std', '标准库 API'),
  ],
  'rust': [
    Source('The Rust Book', 'https://doc.rust-lang.org/book/', '所有权、类型与工程实践'),
    Source('Rust 标准库', 'https://doc.rust-lang.org/std/', '标准库与并发 API'),
  ],
  'typescript': [
    Source(
      'TypeScript Handbook',
      'https://www.typescriptlang.org/docs/handbook/intro.html',
      '类型系统与编译配置',
    ),
    Source(
      'Decorators 与模块',
      'https://www.typescriptlang.org/docs/',
      '语言特性与生态集成',
    ),
  ],
  'shell': [
    Source(
      'GNU Bash Manual',
      'https://www.gnu.org/software/bash/manual/',
      'Bash 语法与行为',
    ),
    Source(
      'POSIX Shell',
      'https://pubs.opengroup.org/onlinepubs/9799919799/',
      '可移植 Shell 标准',
    ),
  ],
  'fundamentals': [
    Source('Linux Kernel Docs', 'https://docs.kernel.org/', '操作系统与硬件接口'),
    Source(
      'Arm Architecture',
      'https://developer.arm.com/documentation',
      '处理器与内存体系结构',
    ),
  ],
  'algorithms': [
    Source('CP-Algorithms', 'https://cp-algorithms.com/', '算法实现与复杂度'),
    Source(
      'MIT OpenCourseWare 6.006',
      'https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/',
      '算法设计与分析',
    ),
  ],
  'network': [
    Source('RFC Editor', 'https://www.rfc-editor.org/', '互联网协议标准'),
    Source(
      'MDN HTTP',
      'https://developer.mozilla.org/docs/Web/HTTP',
      'HTTP 语义与浏览器行为',
    ),
  ],
  'security': [
    Source(
      'OWASP Cheat Sheets',
      'https://cheatsheetseries.owasp.org/',
      '应用安全实践',
    ),
    Source(
      'NIST Cybersecurity',
      'https://www.nist.gov/cyberframework',
      '风险治理框架',
    ),
  ],
  'database': [
    Source('PostgreSQL 文档', 'https://www.postgresql.org/docs/', 'SQL、索引与事务'),
    Source('SQLite 文档', 'https://sqlite.org/docs.html', '嵌入式数据库与 SQL 行为'),
  ],
  'os': [
    Source('Linux Kernel Docs', 'https://docs.kernel.org/', '进程、内存、I/O 与调度'),
    Source(
      'Linux man-pages',
      'https://man7.org/linux/man-pages/',
      '系统调用与用户态接口',
    ),
  ],
  'toolchain': [
    Source('Git 文档', 'https://git-scm.com/doc', '版本控制与协作'),
    Source('Docker 文档', 'https://docs.docker.com/', '容器与镜像'),
    Source('Kubernetes 文档', 'https://kubernetes.io/docs/', '编排与运维'),
  ],
  'ai': [
    Source('OpenAI Docs', 'https://platform.openai.com/docs/', '模型 API、工具与评估'),
    Source('Hugging Face Docs', 'https://huggingface.co/docs', '模型、数据集与推理'),
    Source(
      'Model Context Protocol',
      'https://modelcontextprotocol.io/',
      'Agent 工具与上下文协议',
    ),
  ],
  'distributed': [
    Source('CNCF Landscape', 'https://landscape.cncf.io/', '云原生技术地图'),
    Source('Google SRE Books', 'https://sre.google/books/', '可靠性、容量与事故响应'),
  ],
  'software_engineering': [
    Source('Martin Fowler', 'https://martinfowler.com/', '架构、重构与持续交付'),
    Source(
      'Google SWE Book Resources',
      'https://abseil.io/resources/swe-book',
      '代码评审与工程规范',
    ),
  ],
  'math': [
    Source(
      'MIT Linear Algebra',
      'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/',
      '线性代数基础',
    ),
    Source('NIST DLMF', 'https://dlmf.nist.gov/', '数学函数与公式参考'),
  ],
  'cross_language': [
    Source('DevDocs', 'https://devdocs.io/', '多语言 API 快速检索'),
    Source('官方语言文档', 'https://developer.mozilla.org/docs/Web', '跨语言语义对照'),
  ],
  'visual_guide': [
    Source('RFC Editor', 'https://www.rfc-editor.org/', '协议与状态机'),
    Source('MDN Web Docs', 'https://developer.mozilla.org/', '浏览器与网络流程'),
  ],
  'project_practice': [
    Source('The Twelve-Factor App', 'https://12factor.net/', '可部署应用原则'),
    Source('Google SRE Books', 'https://sre.google/books/', '可观测性与发布工程'),
  ],
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  var changed = 0;
  var skipped = 0;

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    final sources =
        sourcesByCategory[categoryId] ?? sourcesByCategory['fundamentals']!;
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      var content = await file.readAsString();
      if (content.contains(marker)) {
        skipped++;
        continue;
      }
      final summary = (lesson['summary'] as Map)['zh']?.toString() ?? '';
      final buffer = StringBuffer()
        ..writeln(marker)
        ..writeln()
        ..writeln('## 参考资料与复核')
        ..writeln()
        ..writeln('- 最后复核：$reviewedAt')
        ..writeln('- 下次复核：$nextReviewAt')
        ..writeln('- 复核范围：版本兼容、API 行为、安全建议与工程实践')
        ..writeln('- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文')
        ..writeln()
        ..writeln('| 参考资料 | 本课用途 |')
        ..writeln('| --- | --- |');
      for (final source in sources) {
        buffer.writeln('| [${source.name}](${source.url}) | ${source.scope} |');
      }
      buffer
        ..writeln()
        ..writeln('> 本课主题：$summary')
        ..writeln()
        ..writeln('> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。');

      if (!dryRun) {
        content = '${content.trimRight()}\n\n$buffer\n';
        await file.writeAsString(content, flush: true);
      }
      changed++;
    }
  }

  if (!dryRun) {
    manifest['content_last_reviewed_at'] = reviewedAt;
    manifest['content_next_review_at'] = nextReviewAt;
    manifest['p2_references_version'] = 1;
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
  }
  stdout.writeln('${dryRun ? '待补充' : '已补充'}：$changed 篇，已存在跳过：$skipped 篇');
}
