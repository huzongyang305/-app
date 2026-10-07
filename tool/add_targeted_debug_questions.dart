// P2 题型均衡收尾：为自动生成器无法覆盖的 3 个分类各补 1 道排错题。
//
// 用法：
//   dart tool/add_targeted_debug_questions.dart [--dry-run]
//
// 题目来自对应课程的既有正文与代码，不引入课外事实；新题会同步追加到
// Markdown 的「考点精讲」。project_practice / visual_guide 以项目和图示
// 为主，没有可执行的错误代码，因此不强行补排错题。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

class DebugTarget {
  const DebugTarget({
    required this.lessonId,
    required this.question,
    required this.options,
    required this.answer,
    required this.code,
    required this.language,
    required this.explanation,
    this.replaceFill = false,
  });

  final String lessonId;
  final String question;
  final List<String> options;
  final int answer;
  final String code;
  final String language;
  final String explanation;
  // 课程已达 6 题上限时，是否用这道排错题替换一道填空题。
  final bool replaceFill;
}

const List<DebugTarget> targets = [
  DebugTarget(
    lessonId: 'cross_build_release',
    question: '阅读构建与发布脚本，下面哪项判断是正确的？',
    options: [
      'latest 标签能自动追溯对应的 commit，回滚最方便',
      '每个环境各构建一次，才能保证环境差异被覆盖',
      '固定基础镜像版本，并用版本号加 commit SHA 标记制品，各环境复用同一份',
      '只要构建成功，制品名是否可追溯不影响发布',
    ],
    answer: 2,
    code: 'docker build -t myapp:latest .\ndocker push myapp:latest\n# 生产环境直接部署 myapp:latest',
    language: 'bash',
    explanation:
        '正确答案是「固定基础镜像版本，并用版本号加 commit SHA 标记制品，各环境复用同一份」。'
        '本课在「可复现构建的三个条件」和「新手最容易踩的八个坑」中说明：latest 无法追溯与回滚，'
        '每个环境各构建一次会导致测试的不是发布的制品；正确做法是固定依赖与环境，构建一次并在各环境复用。',
  ),
  DebugTarget(
    lessonId: 'security_auth_session',
    question: '阅读 JWT 校验伪代码，下面哪项判断是正确的？',
    options: [
      '允许 none 算法并关闭过期校验可以兼容更多客户端，应当保留',
      '必须固定允许的签名算法，并校验 issuer、audience、过期时间和令牌用途',
      '只要签名能解出 payload，就说明令牌一定可信',
      'JWT 是无状态的，所以注销后无需考虑令牌失效',
    ],
    answer: 1,
    code:
        'payload = jwt.decode(token, SECRET, algorithms=["none", "HS256"], '
        'options={"verify_exp": False})\nuser = payload["sub"]\nreturn create_session(user)',
    language: 'python',
    explanation:
        '正确答案是「必须固定允许的签名算法，并校验 issuer、audience、过期时间和令牌用途」。'
        '本课在「核心知识」中说明：JWT 必须校验签名算法、issuer、audience、过期时间和令牌用途；'
        '允许 none、关闭过期校验或只解出 payload 都会绕过认证边界，注销与权限变更还必须能失效会话。',
  ),
  DebugTarget(
    lessonId: 'se_code_review',
    replaceFill: true,
    question: '阅读下面的评审场景，哪项判断是正确的？',
    options: [
      '这是合理的测试优化，评审可以直接通过',
      '放宽断言会掩盖真实缺陷，应重点审查测试改动并要求作者说明原因',
      '评审只关注业务代码，测试改动由作者自己负责',
      '只要 CI 变绿，测试改动就不需要评审',
    ],
    answer: 1,
    code:
        'PR 改动：- assert result == expected\n+ assert result is not None\n'
        '# 说明：为了让 CI 通过',
    language: 'text',
    explanation:
        '正确答案是「放宽断言会掩盖真实缺陷，应重点审查测试改动并要求作者说明原因」。'
        '本课在「评审清单速查」和「常见错误对照表」中说明：审查测试改动时要重点看去掉了哪些断言、'
        '是否删除了用例；为了让 CI 通过而放宽断言属于高风险操作，必须先确认产品行为而不是直接放行。',
  ),
];

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessons[lesson['id'] as String] = lesson;
    }
  }

  var added = 0;
  var skipped = 0;
  for (final target in targets) {
    final lesson = lessons[target.lessonId];
    if (lesson == null) {
      stderr.writeln('找不到课程：${target.lessonId}');
      exitCode = 1;
      continue;
    }
    final quiz = (lesson['quiz'] as List).cast<Map<dynamic, dynamic>>();
    final normalized = _normalize(target.question);
    final exists = quiz.any(
      (item) => _normalize((item['question'] as String?) ?? '') == normalized,
    );
    if (exists) {
      skipped++;
      continue;
    }
    if (quiz.length >= 6) {
      final fillIndex = target.replaceFill
          ? quiz.indexWhere((item) => item['type'] == 'fill')
          : -1;
      if (fillIndex < 0) {
        stderr.writeln('${target.lessonId} 已达到 6 题上限且没有可替换的填空题，跳过');
        exitCode = 1;
        continue;
      }
      quiz[fillIndex] = <String, dynamic>{
        'type': 'debug',
        'question': target.question,
        'options': target.options,
        'answer': target.answer,
        'code': target.code,
        'language': target.language,
        'explanation': target.explanation,
      };
      if (!dryRun) {
        _replaceFillExamPoint(lesson['file'] as String, target);
      }
      added++;
      stdout.writeln(
        '${dryRun ? '[dry-run] ' : ''}${target.lessonId} 用排错题替换填空题',
      );
      continue;
    }

    quiz.add({
      'type': 'debug',
      'question': target.question,
      'options': target.options,
      'answer': target.answer,
      'code': target.code,
      'language': target.language,
      'explanation': target.explanation,
    });
    if (!dryRun) {
      _appendExamPoint(lesson['file'] as String, target);
    }
    added++;
    stdout.writeln('${dryRun ? '[dry-run] ' : ''}${target.lessonId} 追加排错题');
  }

  if (added > 0 && !dryRun) {
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }
  stdout.writeln('${dryRun ? '[dry-run] ' : ''}新增题目：$added，已存在跳过：$skipped');
}

String _normalize(String value) => value.replaceAll(RegExp(r'\s+'), '');

String _shorten(String value, [int limit = 40]) {
  final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return singleLine.length <= limit
      ? singleLine
      : '${singleLine.substring(0, limit)}…';
}

void _appendExamPoint(String path, DebugTarget target) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('找不到教程文件：$path');
    exitCode = 1;
    return;
  }
  var markdown = file.readAsStringSync();
  final start = markdown.indexOf('## 考点精讲');
  if (start < 0) {
    stderr.writeln('$path 缺少「考点精讲」章节');
    exitCode = 1;
    return;
  }
  var next = markdown.indexOf('\n## ', start + '## 考点精讲'.length);
  if (next < 0) next = markdown.length;
  final section = markdown.substring(start, next);
  final count = RegExp(
    r'^### 考点 \d+：',
    multiLine: true,
  ).allMatches(section).length;
  final correct = target.options[target.answer];
  final block =
      '### 考点 ${count + 1}：${_shorten(target.question)}\n\n'
      '- **正确判断**：$correct\n'
      '- **判断依据**：${target.explanation}';
  final before = markdown.substring(0, next).trimRight();
  final after = markdown.substring(next).trimLeft();
  markdown = '$before\n\n$block\n\n$after';
  file.writeAsStringSync(markdown, flush: true);
}

void _replaceFillExamPoint(String path, DebugTarget target) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('找不到教程文件：$path');
    exitCode = 1;
    return;
  }
  var markdown = file.readAsStringSync();
  final sectionStart = markdown.indexOf('## 考点精讲');
  if (sectionStart < 0) {
    stderr.writeln('$path 缺少「考点精讲」章节');
    exitCode = 1;
    return;
  }
  var sectionEnd = markdown.indexOf('\n## ', sectionStart + '## 考点精讲'.length);
  if (sectionEnd < 0) sectionEnd = markdown.length;
  final section = markdown.substring(sectionStart, sectionEnd);
  final lines = section.split('\n');

  var startLine = -1;
  var endLine = lines.length;
  for (var index = 0; index < lines.length; index++) {
    if (lines[index].startsWith('### 考点 ') && lines[index].contains('补全代码')) {
      startLine = index;
      for (var next = index + 1; next < lines.length; next++) {
        if (lines[next].startsWith('### 考点 ') ||
            lines[next].startsWith('## ')) {
          endLine = next;
          break;
        }
      }
      break;
    }
  }
  if (startLine < 0) {
    stderr.writeln('$path 没有可替换的「补全代码」考点');
    exitCode = 1;
    return;
  }

  final number =
      RegExp(r'考点 (\d+)').firstMatch(lines[startLine])?.group(1) ?? '?';
  final correct = target.options[target.answer];
  final replacement = <String>[
    '### 考点 $number：${_shorten(target.question)}',
    '',
    '- **正确判断**：$correct',
    '- **判断依据**：${target.explanation}',
    '- **迁移检查**：把错误代码中的关键条件换一个，结论是否还成立？写出判断过程。',
    '',
  ];
  final newLines = <String>[
    ...lines.take(startLine),
    ...replacement,
    ...lines.skip(endLine),
  ];
  markdown =
      markdown.substring(0, sectionStart) +
      newLines.join('\n') +
      markdown.substring(sectionEnd);
  file.writeAsStringSync(markdown, flush: true);
}
