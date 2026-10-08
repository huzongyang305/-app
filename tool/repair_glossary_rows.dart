// 术语速查行修复工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart run tool/repair_glossary_rows.dart            # 预览改动
//   dart run tool/repair_glossary_rows.dart --write    # 写回 Markdown
//
// 修复规则：
//   1. 任务/步骤标题行直接删除（它们不是术语）；
//   2. 说明是代码行/英文摘要/模板句的行，按 tool/glossary_repairs.dart 里
//      人工写好的定义改写（不允许自动编造）；
//   3. 修完不足 4 行的课，从「全库已有定义且本课正文出现过」的术语里补足，
//      保证同一术语在不同课程里说法一致。
import 'dart:io';

import 'audit_glossary_rows.dart';
import 'glossary_repairs.dart';

const String contentDir = 'assets/content';

/// 自动补术语时要跳过的通用词（它们在正文里到处都是，但不是本课术语）。
const Set<String> stopTerms = <String>{
  '目标',
  '日志',
  '定位',
  '实战',
  '练习',
  '小结',
  '总结',
  '示例',
  '代码',
  '过程',
  '结论',
  '方法',
  '原因',
  '结果',
  '问题',
  '场景',
  '说明',
  '步骤',
  '任务',
  '输出',
  '输入',
  '边界',
  '排查',
  '检查',
  '验证',
  '思路',
  '方案',
  '常见',
  '技巧',
  '要点',
  '前提',
  '作用',
  '影响',
  '区别',
  '对比',
  '选择',
  '建议',
  '注意',
  '记录',
  '内容',
  '课程',
  '数据',
  // 通用词：在正文里到处都是，放进术语表只会稀释信息量。
  '回滚',
  '评审',
  '提交',
  '测试',
  '覆盖率',
  '边界值',
  '质量门禁',
  '参数',
  '变量',
  '函数',
  '对象',
  '模块',
  '包',
  '循环',
  '浏览器',
  '缓存',
  '部署',
  '告警',
  '路径',
  '权限',
  '密钥',
  '网络',
  '发布',
  '重试',
  '并发',
  '异步',
  '安全',
  '审计',
  '校验',
  '遍历',
  '类型',
  '渲染',
  '请求',
  '响应',
  '超时',
  '重连',
  '退避',
  '序列化',
  '性能',
  '复杂度',
  '表达式',
  '语句',
  '运算符',
  '引用',
  '数组',
  '列表',
  '字典',
  '集合',
  '索引',
  '事务',
  '队列',
  '协议',
  '端口',
  '地址',
  '线程',
  '进程',
  '内存',
  '文件',
  '目录',
  '脚本',
  '命令',
  '参数解析',
  '错误处理',
  '状态',
  '时间',
  '单位',
  '约束',
  '迁移',
  '分片',
  '依赖',
  '构建',
  '性能剖析',
  '可移植性',
  '实时',
  // 第二轮机检出的通用词（多来自「二、三个容易混淆的边界」这类小节标题）。
  '混淆',
  '复盘',
  '版本',
  '模板',
  '数据流',
  '策略',
  '系统',
  '关系',
  '成本',
  '资源',
  '配置',
  '声明式',
  '兜底',
  '恢复',
  '会话',
  '切片',
  '检索',
  '嵌入',
  '向量',
  '数据库',
  '算法',
  '冒泡',
  '递归',
  '容器',
  '流水线',
  '崩溃',
  '优先级',
  '代码块',
  '位运算',
  '溢出',
  '精度',
  '分区',
  '数仓',
  '复制',
  '死循环',
  '局部性',
  '指令',
  '类',
  '事件',
  '版本控制',
  '协议栈',
  '最小权限',
  '内核',
  '管道',
  '内联',
  '箭头函数',
  '组合',
  '生命周期',
  '组件',
  '协程',
  '装饰器',
  '不可变数据',
  '选主',
  '条件数',
  '假设检验',
  '度量',
  '概率',
  '线性代数',
  '正则',
  '收敛',
  '状态码',
  '接口',
  '压测',
  '写屏障',
  '文件描述符',
  '命令行',
  '值传递',
  '时区',
  '幂等',
  // 第三轮机检出的通用词（语言名、抽象动作、泛化名词）。
  '仓库',
  '矩阵',
  '训练',
  '可复现',
  '属性',
  '编译',
  '打包',
  '分支',
  '注入',
  '浮点数',
  '推理',
  '标注',
  '几何',
  '投影',
  '压缩',
  '旋转',
  '调度',
  '合并',
  '嵌套',
  '分布式',
  '高可用',
  '快照',
  '计划',
  '位点',
  '基准',
  '泄漏',
  '作用域',
  '跨平台',
  '隔离',
  '同步',
  '稳定性',
  '门禁',
  '视图',
  '后端',
  '窗口',
  '关键路径',
  '单元测试',
  '热点',
  '一致性',
  '签名',
  '范围',
  '封装',
  '成功率',
  '调用',
  '返回值',
  '类型转换',
  '控制流',
  '结构体',
  '标签',
  '所有权',
  '通道',
  '迭代器',
  '哈希函数',
  '顺序',
  '训练数据',
  '访问',
  '覆盖',
  '复用',
};

Future<void> main(List<String> args) async {
  final write = args.contains('--write');
  final scan = await scanGlossaryRows(contentDir);
  final dictionary = _buildDictionary(scan.rows);

  final rowsByLesson = <String, List<GlossaryRow>>{};
  for (final row in scan.rows) {
    rowsByLesson.putIfAbsent(row.lessonId, () => <GlossaryRow>[]).add(row);
  }

  var touchedLessons = 0;
  var deletedRows = 0;
  var rewrittenRows = 0;
  var addedRows = 0;
  final missingFixes = <String>[];
  final topUpLog = <String>[];
  final keptLog = <String>[];

  for (final entry in rowsByLesson.entries) {
    final lessonId = entry.key;
    final rows = entry.value;
    if (!rows.any((row) => row.finding != null)) continue;

    final file = File(rows.first.file);
    final body = await file.readAsString();
    final headings = _headingsOf(body);
    final fixes = glossaryFixes[lessonId] ?? const <String, GlossaryFix>{};

    final repaired = <({String term, String description})>[];
    var changed = false;
    for (final row in rows) {
      final fix = fixes[row.term];
      if (row.finding == null && fix == null) {
        repaired.add((term: row.term, description: row.description));
        continue;
      }
      if (fix?.remove ?? false) {
        deletedRows++;
        changed = true;
        continue;
      }
      if (fix == null &&
          (row.finding == 'task_term' || row.finding == 'heading_term')) {
        // 任务/步骤/小节标题行：没有人工修复指令时直接删除。
        deletedRows++;
        changed = true;
        continue;
      }
      final newTerm = fix?.term ?? row.term;
      final newDescription = fix?.description;
      if (newDescription == null || newDescription.isEmpty) {
        missingFixes.add('$lessonId | ${row.term}（${row.finding}）');
        repaired.add((term: row.term, description: row.description));
        continue;
      }
      if (newTerm != row.term) changed = true;
      if (newDescription != row.description) {
        rewrittenRows++;
        changed = true;
      }
      repaired.add((term: newTerm, description: newDescription));
    }

    final existingTerms = repaired.map((row) => row.term).toSet();
    if (!write) {
      keptLog.add('$lessonId :: ${repaired.map((row) => row.term).join(' | ')}');
    }
    if (repaired.length < 4) {
      final need = 4 - repaired.length;
      final explicit = glossaryTopUps[lessonId] ?? const <List<String>>[];
      final picks = <({String term, String description})>[];
      for (final entry in explicit) {
        if (picks.length >= need) break;
        final term = entry[0];
        final description = entry.length > 1 ? entry[1] : '';
        if (existingTerms.contains(term)) continue;
        if (description.isEmpty) continue;
        picks.add((term: term, description: description));
      }
      if (picks.length < need) {
        final proposed = _proposeTopUps(
          body: body,
          headings: headings,
          existingTerms: {
            ...existingTerms,
            ...picks.map((pick) => pick.term),
          },
          dictionary: dictionary,
          count: need - picks.length,
        );
        for (final term in proposed) {
          final description = glossaryDefinitions[term] ?? dictionary[term];
          if (description == null) continue;
          picks.add((term: term, description: description));
        }
      }
      if (picks.length < need) {
        missingFixes.add(
          '$lessonId | 还差 ${need - picks.length} 条（现有 ${repaired.length} 条）',
        );
      }
      for (final pick in picks) {
        repaired.add((term: pick.term, description: pick.description));
        addedRows++;
        changed = true;
      }
      if (picks.isNotEmpty) {
        topUpLog.add('$lessonId: ${picks.map((pick) => pick.term).join(', ')}');
      }
    }

    if (!changed) continue;
    touchedLessons++;
    if (!write) continue;
    final updated = _replaceTable(body, repaired);
    await file.writeAsString(updated);
  }

  stdout.writeln('涉及课程 $touchedLessons 门：删除 $deletedRows 行，改写 $rewrittenRows 行，新增 $addedRows 条术语');
  if (keptLog.isNotEmpty) {
    stdout.writeln('修复后各课保留的术语：');
    for (final line in keptLog) {
      stdout.writeln('  $line');
    }
  }
  if (topUpLog.isNotEmpty) {
    stdout.writeln('自动补足的术语：');
    for (final line in topUpLog) {
      stdout.writeln('  $line');
    }
  }
  if (missingFixes.isNotEmpty) {
    stdout.writeln('缺少人工定义（必须先补 tool/glossary_repairs.dart）：');
    for (final line in missingFixes) {
      stdout.writeln('  $line');
    }
    exitCode = 2;
    return;
  }
  stdout.writeln(write ? '已写回 Markdown' : 'dry-run：未写入（加 --write 生效）');
}

/// 全库「合格行」组成的术语词典：同一术语取最长的一条中文说明。
Map<String, String> _buildDictionary(List<GlossaryRow> rows) {
  final dictionary = <String, String>{};
  for (final row in rows) {
    if (row.finding != null) continue;
    if (!hanPattern.hasMatch(row.description)) continue;
    if (row.description.length < 8 || row.description.length > 140) continue;
    final existing = dictionary[row.term];
    if (existing == null || row.description.length > existing.length) {
      dictionary[row.term] = row.description;
    }
  }
  return dictionary;
}

Set<String> _headingsOf(String body) {
  final headings = <String>{};
  for (final line in body.split('\n')) {
    if (!line.startsWith('### ')) continue;
    headings.add(line.substring(4).trim());
  }
  return headings;
}

List<String> _proposeTopUps({
  required String body,
  required Set<String> headings,
  required Set<String> existingTerms,
  required Map<String, String> dictionary,
  required int count,
}) {
  final prose = _proseOf(body);
  final boldTerms = <String>{
    for (final match in RegExp(r'\*\*([^*\n]{2,16})\*\*').allMatches(prose))
      match.group(1)!.trim(),
  };
  final scored = <({String term, int score})>[];
  for (final term in dictionary.keys) {
    if (existingTerms.contains(term)) continue;
    if (stopTerms.contains(term)) continue;
    if (term.length < 2 || term.length > 16) continue;
    if (_isCodeishTerm(term)) continue;
    final occurrences = term.allMatches(prose).length;
    if (occurrences == 0) continue;
    final headingHit = headings.any((heading) => heading.contains(term));
    if (!headingHit && occurrences < 2) continue;
    var score = occurrences.clamp(0, 12) * 10;
    if (headings.any((heading) => heading.contains(term))) score += 1000;
    if (boldTerms.contains(term)) score += 300;
    scored.add((term: term, score: score));
  }
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return a.term.compareTo(b.term);
  });
  return scored.take(count).map((item) => item.term).toList();
}

/// 去掉围栏代码块，只保留正文，避免把代码里的标识符当成术语。
String _proseOf(String body) {
  final buffer = StringBuffer();
  var inFence = false;
  for (final line in body.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    buffer.writeln(line);
  }
  return buffer.toString();
}

/// 纯 ASCII 且很短的词多半是代码标识符（id、def、if、ref），除非是常见技术缩写。
bool _isCodeishTerm(String term) {
  const allowed = <String>{
    '.NET',
    'Node.js',
    'C#',
    'C++',
    'A*',
    '2PC',
    '3PC',
  };
  if (allowed.contains(term)) return false;
  // 纯 ASCII 术语（语言名、关键字、库名）一律不自动补，避免术语表变成清单。
  if (RegExp(r'^[\x20-\x7E]+$').hasMatch(term)) return true;
  // 空格、下划线、括号、点号等形态基本都是代码片段，不是术语。
  if (RegExp(r'[\s_\(\)\[\]\{\}<>;=,\|]').hasMatch(term)) return true;
  if (term.contains('.') || term.contains('/') || term.contains('\\')) {
    return true;
  }
  if (RegExp(r'^[A-Za-z][A-Za-z0-9\-\+\#]{0,3}$').hasMatch(term)) return true;
  return false;
}

/// 只替换「术语速查」小节的表格行，其它内容原样保留。
String _replaceTable(
  String body,
  List<({String term, String description})> rows,
) {
  final lines = body.split('\n');
  final start = lines.indexWhere((line) => line.trimRight() == '## 术语速查');
  if (start < 0) {
    throw StateError('找不到术语速查小节');
  }
  var cursor = start + 1;
  while (cursor < lines.length && !lines[cursor].startsWith('|')) {
    if (lines[cursor].startsWith('## ')) {
      throw StateError('术语速查小节没有表格');
    }
    cursor++;
  }
  final headerIndex = cursor;
  var end = headerIndex;
  while (end < lines.length && lines[end].startsWith('|')) {
    end++;
  }
  final table = <String>[
    lines[headerIndex],
    lines[headerIndex + 1],
    for (final row in rows) '| `${row.term}` | ${row.description} |',
  ];
  return <String>[
    ...lines.sublist(0, headerIndex),
    ...table,
    ...lines.sublist(end),
  ].join('\n');
}
