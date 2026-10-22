// P1-7：把不足 6 条的「术语速查」补厚。
//
// 用法：
//   dart tool/thicken_glossaries.dart            # dry-run
//   dart tool/thicken_glossaries.dart --write    # 写回 assets/content/*.md
//
// 口径刻意保守，宁可少补也不写坏术语表：
//   · 术语只取本课 `###` 小标题（去掉编号），要求 2-16 字并且不是通用词；
//   · 说明取该小节正文的首句，去掉 Markdown 标记后压到 72 字以内；
//   · 该小节正文为空、首句是问句，或含代码/日志片段时跳过；
//   · 小标题不够时，退回到「加粗词 / 反复出现的行内代码词」，
//     但必须能在正文里找到「词 + 是/指/表示…」的定义句。
// 每门课最多补到 6 条，且不重复本表已有的说明。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int targetRows = 6;

/// 通用词过滤：这些词即使出现在小标题里也不进术语表。
const Set<String> stopTerms = <String>{
  '学习目标',
  '前置知识',
  '动手练习',
  '考点精讲',
  '故障现场',
  '本课小结',
  '参考资料与复核',
  'English Overview',
  '内容元数据',
  '本课复习清单',
  '术语速查',
  '常见错误',
  '常见错误与排查',
  '复习与自测',
  '可运行练习',
  '练习题',
  '示例',
  '代码',
  '注意',
  '总结',
  '为什么',
  '怎么',
  '如何',
  '什么',
  '本课',
  '正文',
  '课程',
  '步骤',
  '练习',
  '任务',
  '任务 1',
  '任务 2',
  '任务 3',
  '任务 4',
  '输出',
  '输入',
  '结论',
  '要点',
  '目标',
  '前提',
  '流程',
  '场景',
  '正确判断',
  '判断依据',
  '关键结论',
  '关键点',
  '验证',
  '验证方式',
  '检查',
  '检查清单',
  '排查顺序',
  '排查步骤',
  '最小示例',
  '完整示例',
  '示例代码',
  '运行结果',
  '常见问题',
  '常见误区',
  '推荐做法',
  '错误做法',
  '正确做法',
  '一句话说明',
  '术语',
  '说明',
  '问题',
  '方法',
  '使用',
  '实现',
  '作用',
  '区别',
  '对比',
  '机制',
  '性能',
  '数据',
  '系统',
  '程序',
  '环境',
  '工具',
  '平台',
  '架构',
  '接口',
  '参数',
  '状态',
  '资源',
  '模型',
  '框架',
  '标准',
  '版本',
  '基础',
  '进阶',
  '实战',
  '小结',
  '自查',
  '自测',
  '复盘',
  '导入',
  '导出',
  '分离',
  '校正',
  '变换',
  '转换',
  '格式化',
  '处理',
  '消息',
  '定位',
  '变量',
  '校验',
  '测试',
  '扩展',
  '判断',
  '依赖',
  '风险',
  '正确姿势',
  '错误姿势',
  '实用组合',
};

const List<String> templateMarkers = <String>[
  'Related terms:',
  'focuses on',
  '它在「',
  '复习时回到正文',
  '课程摘要',
  '本课中的相关概念',
  '本课要点',
];

/// 这些词是真实概念，但太泛，不能靠“同一小节里出现过”自动编说明。
/// 它们仍可由全库里有明确定义的词条复用，避免把「运行时」写成一句套话。
const Set<String> weakHeadingTerms = <String>{
  '小项目',
  '模块',
  '核心',
  '根因',
  '自动化',
  '离线',
  '协调',
  '编译',
  '链接',
  '剔除',
  '运行时',
  '测试策略',
  '约束',
  '命令行',
  '环境',
  '工具',
  '平台',
  '接口',
  '参数',
  '状态',
  '资源',
  '框架',
  '版本',
  '配置',
  '部署',
  '测试',
  '调试',
  '优化',
  '监控',
  '日志',
  '代码',
  '示例',
  '案例',
  '场景',
  '项目',
  '工程',
  '实践',
  '步骤',
  '流程',
  '机制',
  '原理',
  '设计',
  '实现',
  '结构',
  '组件',
  '服务',
  '请求',
  '响应',
  '输入',
  '输出',
  '文件',
  '目录',
  '命令',
  '脚本',
  '程序',
};

/// 允许作为术语来源的正文小节。
///
/// `核心知识` / `深度拓展与实战` / `零基础详解` 的小标题通常是本课真正的
/// 概念名，说明也来自同一个小节，比全库词典复用安全得多。
const Set<String> allowedSections = <String>{
  '考点精讲',
  '动手练习',
  '故障现场',
  '核心知识',
  '深度拓展与实战',
  '零基础详解',
  '实践路径',
  '工程化精练：决策、失败与验证',
};

/// 以这些词开头的 `##` 小节也允许参与取词，避免小节标题带前缀后漏掉。
bool _isAllowedSection(String name) {
  if (allowedSections.contains(name)) return true;
  for (final prefix in const <String>[
    '核心知识',
    '深度拓展',
    '零基础详解',
    '实践路径',
    '工程化精练',
  ]) {
    if (name.startsWith(prefix)) return true;
  }
  // 其余正文小节也可以贡献术语，但要排除测验、复盘、检查清单和元数据。
  for (final prefix in const <String>[
    '学习目标',
    '前置知识',
    '动手练习',
    '可运行练习',
    '故障现场',
    '常见错误',
    '本课复习清单',
    '复习与自测',
    '复习与迁移',
    '术语速查',
    '考点精讲',
    'English Overview',
    'Full English Study Guide',
    'Bilingual Section Outline',
    '内容元数据',
    '参考资料与复核',
    '版本与时效',
    '交付评审',
    '质量门禁',
    '测试与验收',
    '安全、成本与可观测性',
    '性能、容量与故障演练',
    '验证命令与预期输出',
    '预期输出',
    '验证步骤',
    '实施记录与复盘',
  ]) {
    if (name.startsWith(prefix)) return false;
  }
  return true;
}

void main(List<String> args) {
  final write = args.contains('--write');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  final files = <String>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final path = ((rawLesson as Map)['file'] ?? '').toString();
      if (path.isNotEmpty && File(path).existsSync()) files.add(path);
    }
  }

  var updated = 0;
  var added = 0;
  var thinBefore = 0;
  var stillThin = 0;
  var headingHits = 0;
  var bankHits = 0;
  final samples = <String>[];
  final stuck = <String>[];
  final bank = _buildGlossaryBank(files);

  for (final path in files) {
    final text = File(path).readAsStringSync();
    final rows = _glossaryRows(text);
    if (rows.length >= targetRows) continue;
    thinBefore++;
    final existing = rows.map((row) => row.term).toSet();
    final usedDescriptions = rows.map((row) => row.description).toSet();

    // 1) 小标题优先：用该小节首句作说明。
    final additions = <({String term, String description})>[];
    for (final section in _subSectionsOf(text)) {
      if (rows.length + additions.length >= targetRows) break;
      for (final term in _termsFromHeading(section.heading)) {
        if (rows.length + additions.length >= targetRows) break;
        if (existing.contains(term)) continue;
        if (additions.any((row) => row.term == term)) continue;
        final description =
            _descriptionForTerm(term, section.body, section.heading);
        if (description == null) continue;
        if (usedDescriptions.contains(description)) continue;
        if (additions.any((row) => row.description == description)) continue;
        additions.add((term: term, description: description));
        headingHits++;
      }
    }

    // 2) 小标题不够时，退回到定义句里能找到的词。
    if (rows.length + additions.length < targetRows) {
      final prose = _proseOf(text);
      for (final term in _fallbackTerms(prose)) {
        if (rows.length + additions.length >= targetRows) break;
        if (existing.contains(term)) continue;
        if (additions.any((row) => row.term == term)) continue;
        final description = _defineFromMarker(term, prose);
        if (description == null) continue;
        if (usedDescriptions.contains(description)) continue;
        if (additions.any((row) => row.description == description)) continue;
        additions.add((term: term, description: description));
      }
    }

    // 3) 同课程词干找不到时，从全库高质量术语表里复用「同领域」条目。
    //    复用必须同时满足：术语出现在本课教学中、说明里的领域词也出现在本课，
    //    因此不会把 Flutter 的「溢出」配成整数回绕，或把数据库索引塞进前端课。
    if (rows.length + additions.length < targetRows) {
      final bankAdditions = _bankAdditions(
        text: text,
        path: path,
        existing: existing,
        usedDescriptions: usedDescriptions,
        additions: additions,
        bank: bank,
        targetRows: targetRows,
      );
      additions.addAll(bankAdditions);
      bankHits += bankAdditions.length;
    }

    if (additions.isEmpty) {
      stillThin++;
      stuck.add('$path（${rows.length} 条）');
      continue;
    }
    final next = _replaceTable(text, <({String term, String description})>[
      for (final row in rows)
        (term: row.term, description: row.description),
      ...additions,
    ]);
    if (next == text) {
      stillThin++;
      stuck.add('$path（写回失败）');
      continue;
    }
    updated++;
    added += additions.length;
    if (rows.length + additions.length < targetRows) {
      stillThin++;
      stuck.add('$path（仅补到 ${rows.length + additions.length} 条）');
    }
    if (samples.length < 400) {
      for (final row in additions) {
        samples.add('$path｜${row.term}｜${row.description}');
      }
    }
    if (write) File(path).writeAsStringSync(next);
  }

  stdout.writeln('补写前不足 $targetRows 条的课程 $thinBefore');
  stdout.writeln('本次补写课程          $updated');
  stdout.writeln(
    '新增术语行            $added（小标题来源 $headingHits，术语库复用 $bankHits）',
  );
  stdout.writeln('仍未达标              $stillThin');
  for (final sample in samples) {
    stdout.writeln('  + $sample');
  }
  if (stuck.isNotEmpty) {
    stdout.writeln('未达标明细（前 20）：');
    for (final item in stuck.take(20)) {
      stdout.writeln('  - $item');
    }
  }
  if (!write) {
    stdout.writeln('');
    stdout.writeln('（dry-run，未写入文件；加 --write 生效）');
    return;
  }
  stdout.writeln('');
  stdout.writeln('已写回 $updated 个课程文件');
}

class _Row {
  const _Row(this.term, this.description);

  final String term;
  final String description;
}

class _SubSection {
  const _SubSection(this.heading, this.body);

  final String heading;
  final String body;
}

class _BankTerm {
  const _BankTerm(this.term, this.variants);

  final String term;
  final List<_BankVariant> variants;
}

class _BankVariant {
  const _BankVariant({
    required this.description,
    required this.frequency,
    required this.domainTokens,
    required this.languages,
  });

  final String description;
  final int frequency;
  final Set<String> domainTokens;
  final Set<String> languages;
}

class _MutableVariant {
  _MutableVariant(this.description);

  String description;
  int frequency = 1;
  final Set<String> languages = <String>{};
}

/// 不允许参与全库复用的泛化术语或过程词。
const Set<String> _genericBankTerms = <String>{
  '一个',
  '一种',
  '一些',
  '这些',
  '那些',
  '这个',
  '那个',
  '其中',
  '可以',
  '可能',
  '能够',
  '不能',
  '不会',
  '需要',
  '必须',
  '应该',
  '通过',
  '使用',
  '用于',
  '用来',
  '表示',
  '属于',
  '负责',
  '包括',
  '以及',
  '或者',
  '并且',
  '同时',
  '然后',
  '因此',
  '所以',
  '但是',
  '如果',
  '那么',
  '为了',
  '由于',
  '基于',
  '针对',
  '对于',
  '关于',
  '在于',
  '中的',
  '的是',
  '是指',
  '一组',
  '一次',
  '主要',
  '常见',
  '通常',
  '一般',
  '直接',
  '间接',
  '真正',
  '实际',
  '具体',
  '相关',
  '不同',
  '相同',
  '多个',
  '每个',
  '所有',
  '某些',
  '其他',
  '进行',
  '完成',
  '产生',
  '出现',
  '存在',
  '成为',
  '作为',
  '具有',
  '提供',
  '支持',
  '实现',
  '处理',
  '保证',
  '避免',
  '导致',
  '使得',
  '调用',
  '运行',
  '执行',
  '工作',
  '操作',
  '结果',
  '过程',
  '方式',
  '方法',
  '问题',
  '情况',
  '场景',
  '内容',
  '部分',
  '地方',
  '时候',
  '时间',
  '大小',
  '数量',
  '速度',
  '性能',
  '安全',
  '系统',
  '程序',
  '环境',
  '工具',
  '平台',
  '架构',
  '接口',
  '参数',
  '状态',
  '资源',
  '模型',
  '框架',
  '标准',
  '版本',
  '配置',
  '部署',
  '测试',
  '自动化',
  '离线',
  '协调',
  '根因',
  '核心',
  '调试',
  '优化',
  '监控',
  '日志',
  '代码',
  '示例',
  '数据',
  '信息',
  '文件',
  '对象',
  '类型',
  '变量',
  '函数',
  '结构',
  '元素',
  '节点',
  '路径',
};

/// 领域词白名单：当术语表已有说明里出现这些词时，允许参与同领域复用。
/// 其余的 2-3 字碎片不做匹配，避免「使用」「数据」这类泛化词造成误配。
const Set<String> _curatedDomainKeywords = <String>{
  '内存', '地址', '指针', '引用', '线程', '进程', '协程', '异步', '同步',
  '并发', '并行', '死锁', '调度', '时间片', '上下文切换', '缓存', '命中',
  '淘汰', '分页', '页表', '虚拟内存', '中断', '异常', '栈', '队列', '链表',
  '二叉树', '哈希', '复杂度', '递归', '迭代', '动态规划', '贪心', '回溯',
  '二分', '索引', '事务', '隔离级别', '原子性', '提交', '回滚', '主键',
  '外键', '范式', '查询', '连接', '聚合', '分区', '分片', '复制', '一致性',
  '共识', '选举', '快照', '备份', '恢复', '消息队列', '发布订阅', '重试',
  '幂等', '限流', '熔断', '延迟', '吞吐', '带宽', '丢包', '握手', '报文',
  '数据包', '端口', '协议', '路由', '子网', '域名', '解析', '加密', '解密',
  '签名', '认证', '授权', '令牌', '会话', '漏洞', '注入', '权限', '沙箱',
  '编译', '解释', '词法', '语法', '语义', '抽象语法树', '字节码', '机器码',
  '寄存器', '指令', '汇编', '内联', '垃圾回收', '引用计数', '可达性',
  '分代', '泛型', '接口', '继承', '多态', '封装', '闭包', '装饰器',
  '生成器', '迭代器', '上下文管理器', '模块', '依赖', '虚拟环境', '容器',
  '镜像', '编排', '集群', '负载均衡', '网关', '部署', '监控', '指标',
  '日志', '链路', '告警', '单元测试', '集成测试', '契约测试', '基准',
  '压测', '像素', '布局', '约束', '组件', '渲染', '生命周期', '响应式',
  '数据绑定', '副作用', '状态机', '帧', '动画', '物理', '碰撞', '渲染管线',
  '着色器', '纹理', '批处理', '相机', '坐标', '向量', '矩阵', '四元数',
  '插值', '积分', '神经网络', '训练', '推理', '损失', '梯度', '反向传播',
  '过拟合', '正则化', '嵌入', '注意力', 'Transformer', 'Token', '提示词',
  '上下文窗口', '工具调用', '智能体', '检索', '知识库', '向量数据库',
  '多模态', '微调', '蒸馏', '量化', '评估', '幻觉', '规划', '记忆', '工作流',
};

/// 全库复用时不参与领域匹配的英文泛化词。
const Set<String> _genericAsciiTerms = <String>{
  'the', 'and', 'for', 'with', 'from', 'this', 'that', 'true', 'false',
  'null', 'none', 'void', 'main', 'test', 'file', 'data', 'code', 'type',
  'name', 'value', 'item', 'list', 'map', 'set', 'get', 'new', 'use',
};

/// 从全库已有术语表建立「术语 -> 多个同领域候选说明」的复用库。
Map<String, _BankTerm> _buildGlossaryBank(List<String> files) {
  final allTerms = <String>{};
  final rawRows = <({String term, String description, String path})>[];
  for (final path in files) {
    final text = File(path).readAsStringSync();
    for (final row in _glossaryRows(text)) {
      final term = _normalize(row.term);
      if (_looksLikeTerm(term)) allTerms.add(term);
      rawRows.add((
        term: term,
        description: row.description,
        path: path,
      ));
    }
  }
  final sortedTerms = allTerms.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  final grouped = <String, Map<String, _MutableVariant>>{};
  for (final row in rawRows) {
    final term = _normalize(row.term);
    if (!_isBankTerm(term)) continue;
    final description = _normalizeBankDescription(row.description);
    if (description.length < 8 || description.length > 180) continue;
    if (_looksCodeish(description)) continue;
    if (!_looksLikeBankDefinition(term, description)) continue;
    final fingerprint = _descriptionFingerprint(description);
    if (fingerprint.isEmpty) continue;
    final variants = grouped.putIfAbsent(term, () => <String, _MutableVariant>{});
    final languages = <String>{
      ..._languageTagsOfPath(row.path),
      ..._languageTagsOfText(description),
    };
    final existing = variants[fingerprint];
    if (existing == null) {
      variants[fingerprint] = _MutableVariant(description)
        ..languages.addAll(languages);
    } else {
      existing.frequency++;
      existing.languages.addAll(languages);
      if (description.length > existing.description.length) {
        existing.description = description;
      }
    }
  }

  final bank = <String, _BankTerm>{};
  grouped.forEach((term, variants) {
    final list = <_BankVariant>[
      for (final variant in variants.values)
        _BankVariant(
          description: variant.description,
          frequency: variant.frequency,
          domainTokens: _domainTokens(
            variant.description,
            sortedTerms,
            term,
          ),
          languages: variant.languages,
        ),
    ];
    if (list.isNotEmpty) bank[term] = _BankTerm(term, list);
  });
  return bank;
}

bool _isBankTerm(String term) {
  if (!_looksLikeTerm(term)) return false;
  if (stopTerms.contains(term) ||
      _genericBankTerms.contains(term) ||
      _isGenericHeadingTerm(term)) {
    return false;
  }
  final cjk = RegExp(r'[\u4e00-\u9fff]').allMatches(term).length;
  if (cjk > 12) return false;
  if (RegExp(
    r'(方法|技巧|姿势|实践|建议|原则|规则|流程|步骤|场景|案例|问题|原因|'
    r'作用|特点|优缺点|清单|要点|指南|入门|基础|进阶|实战|对比|区别|'
    r'注意事项|常见错误|常见误区|排查|总结|复盘|检查|验证|优化|设计|'
    r'实现|方案|策略|思路|本质|优势|劣势|影响|效果|方式|过程|内容|'
    r'部分|示例|代码)$',
  ).hasMatch(term)) {
    return false;
  }
  if (RegExp(
    r'(要正确|要保留|要处理|要使用|要用|应该|必须|不要|不能|如何|为什么|'
    r'是否|哪些|什么|怎么|先把|然后再)',
  ).hasMatch(term)) {
    return false;
  }
  if (RegExp(r'^(使用|通过|实现|进行|完成|保证|避免|导致|使得|把|将)')
      .hasMatch(term)) {
    return false;
  }
  return true;
}

/// 判断一条旧术语说明是不是“在解释这个术语”，而不是顺带提到它。
///
/// 复用旧说明最大的风险是拿到「Flutter 状态管理的核心是…」这类句子：
/// 词出现了，但真正讲的是另一件事。这里要求术语后 5 个字符内出现定义标志，
/// 或者说明本身不含术语但以名词性短语开头。
bool _looksLikeBankDefinition(String term, String description) {
  final escaped = RegExp.escape(term);
  final marker = RegExp(
    '$escaped[\\s`「」（）()]{0,5}'
    r'(是|指|是一种|指的是|用于|用来|表示|属于|负责|代表|即|称为|包括|运行于|工作在|提供|支持)',
  );
  if (marker.hasMatch(description)) return true;
  if (description.contains(term)) return false;
  if (RegExp(
    r'^(编译|运行|安装|配置|创建|编写|使用|执行|输入|启动|打开|调用|修改|删除|添加|设置|'
    r'记录|保存|检查|验证|测试|优化|部署|提交|拉取|推送|发布|构建|打包|下载|'
    r'用|在|本课|回到|二、|先|再|然后|例如|比如|把「|根据|从|围绕|一份)',
  ).hasMatch(description)) {
    return false;
  }
  if (RegExp(r'^[a-z][a-z0-9._-]*\s+').hasMatch(description)) return false;
  return description.length >= 12;
}

/// 编程语言标记：只用于阻止 Java 的 `super` 说明被复用到 Python 课，
/// 或 JavaScript 的 `await` 说明被复用到 Flutter 课。
const Map<String, List<String>> _languageMarkers = <String, List<String>>{
  'javascript': <String>['javascript'],
  r'(?<![a-z])java(?![a-z])': <String>['java'],
  'python': <String>['python'],
  r'c\+\+': <String>['cpp'],
  r'(?<![a-z])cpp(?![a-z])': <String>['cpp'],
  r'c#': <String>['csharp'],
  r'(?<![a-z])csharp(?![a-z])': <String>['csharp'],
  r'(?<![a-z])rust(?![a-z])': <String>['rust'],
  r'(?<![a-z])kotlin(?![a-z])': <String>['kotlin'],
  r'(?<![a-z])swift(?![a-z])': <String>['swift'],
  r'(?<![a-z])typescript(?![a-z])': <String>['typescript'],
  r'(?<![a-z])ts(?![a-z])': <String>['typescript'],
  r'(?<![a-z])js(?![a-z])': <String>['javascript'],
  r'(?<![a-z])dart(?![a-z])': <String>['dart'],
  r'(?<![a-z])flutter(?![a-z])': <String>['flutter', 'dart'],
  r'(?<![a-z])go(?:lang)?(?![a-z])': <String>['go'],
  r'(?<![a-z])bash(?![a-z])': <String>['shell'],
  r'(?<![a-z])shell(?![a-z])': <String>['shell'],
  r'(?<![a-z])c(?![a-z])': <String>['c'],
};

Set<String> _languageTagsOfPath(String path) {
  final lower = path.toLowerCase();
  final tags = _languageTagsOf(lower);
  // 移动端课程路径不一定含语言名，这里补上明确框架归属。
  if (lower.contains('compose')) tags.add('kotlin');
  if (lower.contains('react_native')) tags.add('javascript');
  if (lower.contains('miniprogram')) tags.add('miniprogram');
  if (lower.contains('harmony')) tags.add('harmony');
  return tags;
}

Set<String> _languageTagsOfText(String text) =>
    _languageTagsOf(text.toLowerCase());

Set<String> _languageTagsOf(String lower) {
  final tags = <String>{};
  for (final entry in _languageMarkers.entries) {
    if (RegExp(entry.key).hasMatch(lower)) tags.addAll(entry.value);
  }
  return tags;
}

String _normalizeBankDescription(String raw) {
  return raw
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'^\s*[-*>#0-9.、]+\s*'), '')
      .replaceFirst(RegExp(r'[。；;]+$'), '')
      .trim();
}

String _descriptionFingerprint(String description) {
  final normalized = description
      .replaceAll(
        RegExp(r'[\s`*_「」“”，。；：、（）()\[\]【】]'),
        '',
      )
      .replaceFirst(RegExp(r'^(是一种|是指|指的是|表示|用于|用来)'), '');
  if (normalized.length <= 24) return normalized;
  return normalized.substring(0, 24);
}

Set<String> _domainTokens(
  String description,
  List<String> sortedTerms,
  String selfTerm,
) {
  final tokens = <String>{};
  const maxTokens = 24;
  for (final term in sortedTerms) {
    if (tokens.length >= maxTokens) break;
    if (term == selfTerm || term.length < 2 || term.length > 12) continue;
    if (_genericBankTerms.contains(term) ||
        stopTerms.contains(term) ||
        _isGenericHeadingTerm(term)) {
      continue;
    }
    if (description.contains(term)) tokens.add(term);
  }
  for (final keyword in _curatedDomainKeywords) {
    if (tokens.length >= maxTokens) break;
    if (description.contains(keyword)) tokens.add(keyword);
  }
  for (final match
      in RegExp(r'[A-Za-z][A-Za-z0-9+#._\-/]{2,}').allMatches(description)) {
    if (tokens.length >= maxTokens) break;
    final token = match.group(0)!;
    if (_genericAsciiTerms.contains(token.toLowerCase())) continue;
    tokens.add(token);
  }
  return tokens;
}

/// 只取讲解型小节作为全库复用的上下文，避免把测验选项里的词当正文术语。
const Set<String> _bankSkippedSections = <String>{
  '术语速查',
  '考点精讲',
  'English Overview',
  'Full English Study Guide',
  'Bilingual Section Outline',
  '内容元数据',
  '参考资料与复核',
  '本课复习清单',
  '复习与自测',
  '版本与时效',
};

bool _skipBankSection(String name) {
  if (_bankSkippedSections.contains(name)) return true;
  for (final prefix in const <String>[
    '考点精讲',
    'English Overview',
    '内容元数据',
    '参考资料与复核',
    '本课复习清单',
    '复习与自测',
  ]) {
    if (name.startsWith(prefix)) return true;
  }
  return false;
}

String _bankProseOf(String text) {
  final buffer = StringBuffer();
  var skip = false;
  var inFence = false;
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      final name = trimmed.substring(3).trim();
      skip = _skipBankSection(name);
      if (!skip) buffer.writeln(name);
      continue;
    }
    if (skip) continue;
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (trimmed.startsWith('|')) continue;
    if (trimmed.startsWith('- [ ]') || trimmed.startsWith('- [x]')) continue;
    buffer.writeln(line);
  }
  return buffer.toString();
}

String _bankHeadingsOf(String text) {
  final buffer = StringBuffer();
  var skip = false;
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      final name = trimmed.substring(3).trim();
      skip = _skipBankSection(name);
      if (!skip) buffer.writeln(name);
      continue;
    }
    if (skip) continue;
    if (trimmed.startsWith('### ')) buffer.writeln(trimmed);
  }
  return buffer.toString();
}

List<({String term, String description})> _bankAdditions({
  required String text,
  required String path,
  required Set<String> existing,
  required Set<String> usedDescriptions,
  required List<({String term, String description})> additions,
  required Map<String, _BankTerm> bank,
  required int targetRows,
}) {
  final need = targetRows - existing.length - additions.length;
  if (need <= 0) return const <({String term, String description})>[];
  final prose = _bankProseOf(text);
  final headings = _bankHeadingsOf(text);
  final focusLine =
      RegExp(r'本课涉及：([^\n]*)').firstMatch(text)?.group(1) ?? '';
  final titleLine = text
      .split('\n')
      .firstWhere((line) => line.startsWith('# '), orElse: () => '');
  final targetLanguages = _languageTagsOfPath(path);
  final strongTargetLanguages = <String>{
    ...targetLanguages,
    ..._languageTagsOfText(focusLine),
    ..._languageTagsOfText(titleLine),
  };
  if (prose.length < 60 || prose.contains('focuses on')) {
    return const <({String term, String description})>[];
  }
  final candidates = <({String term, String description, int score})>[];
  for (final entry in bank.values) {
    if (existing.contains(entry.term) ||
        additions.any((row) => row.term == entry.term)) {
      continue;
    }
    if (!prose.contains(entry.term)) continue;
    final inHeading = headings.contains(entry.term);
    final inFocus = focusLine.contains(entry.term);
    final inTitle = titleLine.contains(entry.term);
    // 术语必须在本课教学小标题或「本课涉及」里出现，不能只是测验文字擦边。
    if (!inHeading && !inFocus && !inTitle) continue;
    final termLength = entry.term.runes.length;
    for (final variant in entry.variants) {
      if (usedDescriptions.contains(variant.description) ||
          additions.any((row) => row.description == variant.description)) {
        continue;
      }
      if (templateMarkers.any(variant.description.contains)) continue;
      if (variant.languages.isNotEmpty &&
          (strongTargetLanguages.isEmpty ||
              variant.languages.intersection(strongTargetLanguages).isEmpty)) {
        continue;
      }
      final descriptionLanguages =
          _languageTagsOfText(variant.description);
      if (descriptionLanguages.isNotEmpty &&
          (strongTargetLanguages.isEmpty ||
              descriptionLanguages
                  .intersection(strongTargetLanguages)
                  .isEmpty)) {
        continue;
      }
      final description = _trimDefinition(variant.description);
      if (description == null) continue;
      final matches = variant.domainTokens
          .where((token) => prose.contains(token) || headings.contains(token))
          .length;
      final required = termLength <= 2 ? 3 : 2;
      if (matches < required) continue;
      // 只出现一次的全库定义默认不复用，除非它在标题里且有 3 个领域词强匹配。
      if (variant.frequency < 2 &&
          !(inHeading && matches >= 3 && _isSpecificBankTerm(entry.term))) {
        continue;
      }
      var score = matches * 15 + variant.frequency * 2 + termLength * 2;
      if (inHeading) score += 25;
      if (inFocus) score += 15;
      if (inTitle) score += 20;
      if (termLength >= 5) score += 10;
      candidates.add((
        term: entry.term,
        description: description,
        score: score,
      ));
    }
  }
  candidates.sort((a, b) => b.score.compareTo(a.score));
  final chosen = <({String term, String description})>[];
  final chosenTerms = <String>{};
  for (final candidate in candidates) {
    if (chosen.length >= need) break;
    if (!chosenTerms.add(candidate.term)) continue;
    chosen.add((term: candidate.term, description: candidate.description));
  }
  return chosen;
}

bool _isSpecificBankTerm(String term) {
  if (RegExp(r'[A-Z0-9]').hasMatch(term)) return true;
  return RegExp(r'[\u4e00-\u9fff]').allMatches(term).length >= 3;
}

/// 解析「术语速查」小节里的表格行（跳过表头与分隔行）。
List<_Row> _glossaryRows(String text) {
  final rows = <_Row>[];
  var inSection = false;
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      inSection = trimmed == '## 术语速查';
      continue;
    }
    if (!inSection) continue;
    if (!trimmed.startsWith('|')) continue;
    if (RegExp(r'^\|[\s:|-]+\|$').hasMatch(trimmed)) continue;
    final cells = trimmed
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
    if (cells.length < 2) continue;
    if (cells[0] == '术语') continue;
    rows.add(_Row(_normalize(cells[0]), cells[1]));
  }
  return rows;
}

/// 取允许小节下的 `###` 子小节及其正文（去掉代码块与表格）。
List<_SubSection> _subSectionsOf(String text) {
  final sections = <_SubSection>[];
  var inAllowedSection = false;
  String? heading;
  final body = StringBuffer();
  var inFence = false;
  void flush() {
    if (heading != null) {
      sections.add(_SubSection(heading!, body.toString().trim()));
    }
    heading = null;
    body.clear();
  }

  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      flush();
      inAllowedSection = _isAllowedSection(trimmed.substring(3).trim());
      continue;
    }
    if (!inAllowedSection) continue;
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (trimmed.startsWith('### ')) {
      flush();
      heading = trimmed.substring(4).trim();
      continue;
    }
    if (heading == null) continue;
    if (trimmed.startsWith('|') ||
        trimmed.startsWith('- [ ]') ||
        trimmed.startsWith('- [x]')) {
      continue;
    }
    body.writeln(line);
  }
  flush();
  return sections;
}

/// 从小标题里拆出术语：过滤题干和过程标题，去掉编号与冒号后的修饰语，
/// 再按「与/、/和」拆开。
List<String> _termsFromHeading(String heading) {
  var text = _normalize(heading).trim();
  if (text.isEmpty) return const <String>[];
  // 题干、练习、复盘、检查项都不是术语来源。
  if (RegExp(r'[？?]').hasMatch(text)) return const <String>[];
  const procedural = <String>[
    '考点',
    '题型',
    '实验',
    '任务',
    '练习',
    '现场',
    '步骤',
    '模块',
    '案例',
    '示例',
    '常见错误',
    '为什么',
    '如何',
    '怎么',
    '什么',
    '本课',
    '一句话',
    '学习目标',
    '前置知识',
    '落地检查',
    '正文依据',
    '记忆方法',
    '判断依据',
    '判断要点',
    '完成标准',
    '验收标准',
    '交付标准',
    '正确做法',
    '错误做法',
    '使用场景',
    '适用场景',
    '不适用场景',
    '规则',
    '提示',
    '注意',
    '观察',
    '测量',
    '操作',
    '排错',
    '自检',
    '验收',
    '交付',
    '反例',
    '现象',
    '风险',
    '难点',
    '重点',
    '易错点',
    '常见坑',
    '有哪些',
    '哪些',
    '什么时候',
    '能不能',
    '是否',
    '正确判断',
    '关键结论',
    '验证方式',
    '工程视角',
    '边界',
    '结论',
    '答案',
    '解析',
    '迁移',
    '复盘',
    '自测',
    '检查',
    '复习',
    '导读',
    '总览',
    '概览',
    '导语',
    '小结',
    '附录',
    '参考资料',
    '延伸阅读',
    '下一步',
    '用生活比喻',
    '手把手',
    '新手最容易',
    '适用边界',
    '完成检查',
    '复习顺序',
    '常见误区',
    '对照表',
    '核心模型',
    '关键机制',
    '工作示例',
    '场景推演',
  ];
  if (procedural.any(text.startsWith)) return const <String>[];
  // 「机制拆解 1：帧预算与刷新率」这类标题，先去掉分析前缀。
  text = text
      .replaceFirst(
        RegExp(
          r'^(机制拆解|专题|主题|模块|案例|原理|原理拆解|机制|要点|概念)\s*'
          r'[\d一二三四五六七八九十]+\s*[：:、.．]\s*',
        ),
        '',
      )
      .replaceFirst(RegExp(r'^[\d一二三四五六七八九十]+[、.．:：]\s*'), '')
      .trim();
  if (text.isEmpty) return const <String>[];
  // 「装饰器本质是接收函数并返回新函数的高阶函数」这类小标题是整句结论，
  // 不是术语；先整句排除，避免从逗号/顿号里拆出「异常」「声明」等碎片。
  if (_looksSentenceHeading(text)) return const <String>[];
  // 「空安全：Kotlin 最值钱的设计」这类标题，只取冒号前的主题词。
  final colon = text.split(RegExp(r'[：:]')).first.trim();
  final parts = _splitHeadingParts(colon)
      .map(_stripHeadingSuffix)
      .where((part) => part.isNotEmpty)
      .toList();
  return <String>[
    for (final part in parts)
      if (!stopTerms.contains(part) &&
          !weakHeadingTerms.contains(part) &&
          !_isGenericHeadingTerm(part) &&
          _looksLikeTerm(part))
        part,
  ];
}

/// 判断一个小标题是否其实是完整句子或操作建议，而不是概念名。
bool _looksSentenceHeading(String text) {
  if (text.length > 30) return true;
  if (RegExp(r'[，。；！？]').hasMatch(text)) return true;
  if (RegExp(
    r'(要正确|要保留|要处理|要使用|要用|应该|必须|不要|不能|可以|'
    r'用于|负责|告诉|发现|导致|使得|变得越来越|先把|然后再|先从|再把|再从)',
  ).hasMatch(text)) {
    return true;
  }
  return false;
}

/// 只把「和」当连词拆，避免把「饱和」「调和」这类词拆坏。
List<String> _splitHeadingParts(String text) {
  const ambiguous = <String>[
    '饱和',
    '调和',
    '求和',
    '总和',
    '和平',
    '温和',
    '和谐',
    '共和国',
    '和声',
  ];
  final rough = text.split(RegExp(r'[、与及]'));
  final parts = <String>[];
  for (final chunk in rough) {
    if (!chunk.contains('和') ||
        ambiguous.any((word) => chunk.contains(word))) {
      parts.add(chunk.trim());
      continue;
    }
    final index = chunk.indexOf('和');
    final left = chunk.substring(0, index).trim();
    final right = chunk.substring(index + 1).trim();
    if (left.length >= 2 && right.length >= 2) {
      parts.addAll(<String>[left, right]);
    } else {
      parts.add(chunk.trim());
    }
  }
  return parts;
}

/// 去掉标题末尾的泛化后缀，让「固定时间步方案」回到「固定时间步」。
String _stripHeadingSuffix(String raw) {
  var text = raw.replaceAll(RegExp(r'[（(].*?[）)]'), '').trim();
  const suffixes = <String>[
    '完整方案',
    '实现方案',
    '落地方案',
    '方案',
    '机制',
    '流程',
    '原理',
    '模型',
    '设计',
    '实现',
    '基础',
    '入门',
    '概览',
    '详解',
    '类型',
    '场景',
    '边界',
    '对比',
    '区别',
    '原因',
    '作用',
    '特点',
    '优缺点',
    '要点',
    '清单',
    '步骤',
    '方法',
    '方式',
    '规则',
    '原则',
  ];
  for (final suffix in suffixes) {
    if (text.endsWith(suffix) && text.length - suffix.length >= 2) {
      final stem = text.substring(0, text.length - suffix.length).trim();
      if (stopTerms.contains(stem) ||
          _genericBankTerms.contains(stem) ||
          _isGenericHeadingTerm(stem)) {
        break;
      }
      text = stem;
      break;
    }
  }
  return text;
}

/// 过滤「安全机制」「性能优化」这类由泛化概念拼出来的标题词。
bool _isGenericHeadingTerm(String term) {
  const generic = <String>[
    '安全',
    '性能',
    '数据',
    '系统',
    '程序',
    '环境',
    '工具',
    '平台',
    '架构',
    '接口',
    '参数',
    '状态',
    '资源',
    '模型',
    '框架',
    '标准',
    '版本',
    '配置',
    '部署',
    '测试',
    '调试',
    '优化',
    '监控',
    '日志',
    '代码',
    '示例',
    '问题',
    '方法',
    '机制',
    '流程',
    '设计',
    '实现',
    '原理',
    '概念',
    '基础',
    '核心',
    '常见',
    '典型',
    '关键',
  ];
  const suffix = <String>['机制', '流程', '设计', '实现', '原理', '方案', '模型'];
  for (final tail in suffix) {
    if (term.endsWith(tail) && term.length - tail.length >= 2) {
      final stem = term.substring(0, term.length - tail.length);
      if (generic.contains(stem)) return true;
    }
  }
  return false;
}

/// 在小节正文里找包含术语的定义句；找不到时再退回术语词干。
String? _descriptionForTerm(String term, String body, String heading) {
  final direct = _bestSentence(body, term);
  if (direct != null && _acceptDirectDescription(term, direct)) return direct;
  final fromHeading = _definitionFromHeading(term, heading);
  if (fromHeading != null) return fromHeading;
  final stem = _stemOf(term);
  if (stem == null || stem.length < 2) return null;
  final related = _bestSentence(body, stem);
  if (related == null) return null;
  return _trimDefinition('${_conceptPrefix(term)}$related');
}

/// 同小节直取说明时，要求术语位于句首，或后面紧跟定义标志；
/// 这样「CD | CI/CD 把流程自动化」不会因为句子里出现 CD 就被当成定义。
bool _acceptDirectDescription(String term, String sentence) {
  final index = sentence.indexOf(term);
  if (index < 0) return false;
  final before = sentence.substring(0, index).trim();
  var after = sentence.substring(index + term.length).trim();
  final startsAtSentence = before.isEmpty ||
      RegExp(r'^[-*>#0-9.、]+$').hasMatch(before);
  if (RegExp(r'^(的)?(关键|核心|作用|优势|劣势|特点|方法|步骤|实现|设计|流程|机制|原理|目标|场景|示例|案例|问题|原因|注意事项)')
      .hasMatch(after)) {
    return false;
  }
  if (RegExp(r'^(编译|安装|配置|创建|编写|使用|执行|输入|启动|打开|调用|修改|删除|添加|设置|记录|保存|检查|验证|测试|优化|部署|提交|拉取|推送|发布|构建|打包|下载)')
      .hasMatch(after)) {
    return false;
  }
  // Widget 这类命名类型如果在讲“很轻量/很常用”，那不是定义。
  if (RegExp(r'^[A-Z][A-Za-z0-9._-]*$').hasMatch(term) &&
      !RegExp(r'^(是|指|是一种|指的是|表示|用于|用来|属于|负责|代表|即|称为|可以|把|让|使)')
          .hasMatch(after)) {
    return false;
  }
  if (startsAtSentence) return true;
  return RegExp(r'^(是|指|是一种|指的是|表示|用于|用来|属于|负责|代表|即|称为)')
      .hasMatch(after);
}

/// 「协程：把耗时工作挪出主线程」这类标题的冒号后半句可以直接作为说明。
String? _definitionFromHeading(String term, String heading) {
  final text = _normalize(heading);
  final index = text.indexOf(RegExp(r'[：:]'));
  if (index <= 0) return null;
  final tail = text.substring(index + 1).trim();
  if (tail.contains(term)) return null;
  if (!RegExp(
    r'^(是|指|把|用于|用来|负责|让|使|通过|可以|由|会|将|按|从|面向|针对)',
  ).hasMatch(tail)) {
    return null;
  }
  if (RegExp(r'^(再|又|还|也|就|才)').hasMatch(tail)) return null;
  if (tail.length < 6 || tail.length > 60) return null;
  if (_looksCodeish(tail)) return null;
  return _trimDefinition('$term$tail');
}

/// 找包含 `needle` 且“最像定义”的陈述句，优先定义句式而不是操作建议。
String? _bestSentence(String body, String needle) {
  ({String text, int score})? best;
  for (final raw in body.split(RegExp(r'(?<=[。！？\n])'))) {
    final sentence = _cleanSentence(raw);
    if (sentence == null || !sentence.contains(needle)) continue;
    final score = _sentenceScore(sentence, needle);
    if (best == null || score > best.score) {
      best = (text: sentence, score: score);
    }
  }
  if (best == null || best.score < 0) return null;
  return _trimDefinition(best.text);
}

int _sentenceScore(String sentence, String term) {
  var score = 0;
  final escaped = RegExp.escape(term);
  if (RegExp('^$escaped').hasMatch(sentence)) score += 30;
  final index = sentence.indexOf(term);
  if (index >= 0 && index <= 10) score += 12;
  if (RegExp(
    '$escaped(是指|指的是|是|指|表示|用于|用来|是一种|属于|负责|'
    r'会把|可以让|让|使|允许|通过|由|包括)',
  ).hasMatch(sentence)) {
    score += 55;
  }
  if (RegExp(r'是|指|表示|用于|用来|包括|由|通过|负责|让|使')
      .hasMatch(sentence)) {
    score += 8;
  }
  if (sentence.length >= 16 && sentence.length <= 64) score += 12;
  if (RegExp(r'^(不要|请|应该|必须|需要|避免|把|使用)').hasMatch(sentence)) {
    score -= 30;
  }
  if (RegExp(r'^(看|记住|口诀|先从|把它写成|一句话)').hasMatch(sentence)) {
    score -= 50;
  }
  if (sentence.contains('左边还是右边') ||
      sentence.contains('哪一步最容易出错')) {
    score -= 50;
  }
  if (sentence.startsWith('在') && sentence.contains('可以这样')) score -= 40;
  if (sentence.contains('记得') || sentence.contains('别忘了')) score -= 20;
  return score;
}

/// 清洗一句 Markdown 文本；不合格时返回 null。
String? _cleanSentence(String raw) {
  var sentence = raw.trim();
  if (sentence.isEmpty) return null;
  sentence = sentence
      .replaceFirst(RegExp(r'^\s*[-*>#0-9.、]+\s*'), '')
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (sentence.isEmpty) return null;
  // 批量工具留下的「边界：」「落地检查：」等标签不进入术语说明。
  const metaLabels = <String>[
    '边界',
    '规则',
    '落地检查',
    '正文依据',
    '工程视角',
    '验证方式',
    '注意',
    '提示',
    '反例',
    '正确做法',
    '错误做法',
    '原因',
    '现象',
    '风险',
    '结论',
    '判断依据',
    '判断要点',
    '记忆方法',
    '完成标准',
    '验收标准',
    '交付标准',
    '要点',
    '好处',
    '口诀',
    '提醒',
    '建议',
    '小结',
    '注意点',
    '关键点',
    '经验',
    '实践建议',
    '正确姿势',
    '错误姿势',
  ];
  sentence = sentence.replaceFirst(
    RegExp('^(${metaLabels.join('|')})[：:]\\s*'),
    '',
  );
  if (sentence.isEmpty) return null;
  if (sentence.endsWith('？') || sentence.endsWith('?')) return null;
  if (sentence.length < 10) return null;
  if (sentence.startsWith('把「') ||
      sentence.contains('改写成一条可执行的核对项') ||
      sentence.contains('能用自己的话解释') ||
      sentence.contains('这条结论放回') ||
      sentence.contains('可以这样验证') ||
      sentence.contains('小样本成立') ||
      sentence.contains('正文对应小节')) {
    return null;
  }
  if (sentence.contains('「') != sentence.contains('」')) return null;
  if (_looksCodeish(sentence)) return null;
  return sentence;
}

/// 复合术语的后半截往往在正文里只出现词干，例如「刷新率」→「刷新」。
String? _stemOf(String term) {
  const suffixes = <String>[
    '上限',
    '下限',
    '机制',
    '模型',
    '方案',
    '流程',
    '率',
    '定位',
    '解耦',
    '协议',
    '算法',
    '索引',
    '缓存',
    '模式',
    '策略',
    '原则',
    '规则',
  ];
  for (final suffix in suffixes) {
    if (term.endsWith(suffix) && term.length - suffix.length >= 2) {
      return term.substring(0, term.length - suffix.length);
    }
  }
  return null;
}

/// 给「词干命中、整词未命中」的术语补一个中性主语，避免说明没有落点。
String _conceptPrefix(String term) {
  if (term == '刷新率') return '画面每秒刷新的次数：';
  if (term == '目标帧率') return '希望画面每秒更新的次数：';
  if (term == '填充率') return 'GPU 每秒能写入的像素数量：';
  if (term.endsWith('帧率')) return '画面每秒更新的次数：';
  if (term.endsWith('命中率')) return '命中次数占总访问次数的比例：';
  if (term.endsWith('采样率')) return '每秒采样的次数：';
  if (term.endsWith('率')) {
    return '比例或频率：';
  }
  if (term.endsWith('上限')) return '允许的最大值或次数：';
  if (term.endsWith('下限')) return '允许的最小值或次数：';
  if (term.endsWith('解耦')) return '把两部分的职责分开：';
  if (term.endsWith('机制')) return '一组固定的协作方式：';
  if (term.endsWith('模型')) return '对问题的结构化表示：';
  if (term.endsWith('协议')) return '通信双方遵守的约定：';
  if (term.endsWith('算法')) return '解决问题的明确步骤：';
  if (term.endsWith('索引')) return '加速查找的数据结构：';
  if (term.endsWith('缓存')) return '把结果暂存起来以便复用的机制：';
  if (term.endsWith('定位')) return '定位问题所在环节的过程：';
  return '本课中的相关概念：';
}

/// 回退来源：加粗词，以及正文里出现 3 次以上的行内代码词。
List<String> _fallbackTerms(String prose) {
  final counts = <String, int>{};
  for (final match in RegExp(r'\*\*([^*\n]{2,16})\*\*').allMatches(prose)) {
    final term = _normalize(match.group(1)!);
    if (term.isEmpty || stopTerms.contains(term)) continue;
    if (!_looksLikeTerm(term)) continue;
    counts[term] = (counts[term] ?? 0) + 100;
  }
  for (final match in RegExp(r'`([^`\n]{2,16})`').allMatches(prose)) {
    final term = _normalize(match.group(1)!);
    if (term.isEmpty || stopTerms.contains(term)) continue;
    if (!_looksLikeTerm(term)) continue;
    counts[term] = (counts[term] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return <String>[
    for (final entry in entries)
      if (entry.value >= 3) entry.key,
  ];
}

/// 从「词 + 是/指/表示…」的定义句里提炼说明。
String? _defineFromMarker(String term, String prose) {
  final marker = RegExp(
    '${RegExp.escape(term)}[`\\s"\'』」）)\\]（(]*'
    r'(是|指|表示|用于|用来|是一种|一种|属于|负责|把|让|使|通过|可以|称为|叫做|即|是指)',
  );
  final sentences = prose.split(RegExp(r'(?<=[。！？\n])'));
  String? best;
  var bestScore = -1;
  for (var i = 0; i < sentences.length; i++) {
    final sentence = sentences[i].trim();
    if (sentence.length < 10 || !sentence.contains(term)) continue;
    if (sentence.endsWith('？') || sentence.endsWith('?')) continue;
    final match = marker.firstMatch(sentence);
    if (match == null) continue;
    var candidate = sentence
        .substring(match.start)
        .replaceFirst(RegExp(r'^\s*[-*>#0-9.、]+\s*'), '')
        .replaceAll('**', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    candidate = candidate
        .replaceFirst(RegExp(r'^`+'), '')
        .replaceFirst(RegExp(r'`+$'), '')
        .trim();
    if (candidate.length > 100) continue;
    if (_looksCodeish(candidate)) continue;
    var score = 100 - candidate.length;
    if (candidate.startsWith(term)) score += 15;
    if (i < 12) score += 20;
    if (score > bestScore) {
      bestScore = score;
      best = candidate;
    }
  }
  if (best == null) return null;
  return _trimDefinition(best);
}

/// 只替换「术语速查」表格，其它正文原样保留。
String _replaceTable(
  String text,
  List<({String term, String description})> rows,
) {
  final lines = text.split('\n');
  final start = lines.indexWhere((line) => line.trimRight() == '## 术语速查');
  if (start < 0) return text;
  // 表前可能有一句导语，定位到本节里第一行表格即可。
  var tableStart = -1;
  for (var i = start + 1; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('## ')) break;
    if (trimmed.startsWith('|')) {
      tableStart = i;
      break;
    }
  }
  if (tableStart < 0) return text;
  final header = <String>['| 术语 | 一句话说明 |', '| --- | --- |'];
  final inserted = <String>[
    for (final row in rows) '| `${row.term}` | ${row.description} |',
  ];
  var end = tableStart;
  while (end < lines.length && lines[end].trim().startsWith('|')) {
    end++;
  }
  final next = <String>[
    ...lines.sublist(0, tableStart),
    ...header,
    ...inserted,
    ...lines.sublist(end),
  ];
  return next.join('\n');
}

String _normalize(String term) =>
    term.replaceAll('`', '').replaceAll('**', '').trim();

/// 术语形态过滤：2-16 字符，不含大部分标点与空白。
bool _looksLikeTerm(String term) {
  if (term.length < 2 || term.length > 16) return false;
  if (RegExp(r'[\s_\(\)\[\]\{\}<>;=,\|，。；：、—→]').hasMatch(term)) {
    return false;
  }
  final cjk = RegExp(r'[\u4e00-\u9fff]').allMatches(term).length;
  if (cjk == 0) return _looksLikeAsciiTerm(term);
  return true;
}

/// 纯英文术语只接受常见缩写、混合大小写或足够长的技术名词，
/// 避免把 `if`、`for`、`get` 这类语法关键字塞进术语表。
bool _looksLikeAsciiTerm(String term) {
  if (term.length < 2 || term.length > 24) return false;
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._+\-/#]*$').hasMatch(term)) {
    return false;
  }
  const acronyms = <String>{
    'sql', 'css', 'xml', 'http', 'https', 'tcp', 'udp', 'dns', 'cpu', 'ram',
    'gpu', 'api', 'ui', 'ux', 'os', 'db', 'io', 'json', 'yaml', 'html', 'url',
    'uri', 'jwt', 'orm', 'crud', 'mvc', 'mvvm', 'sso', 'tls', 'ssl', 'ssh',
    'ftp', 'smtp', 'imap', 'pop3', 'nat', 'dhcp', 'icmp', 'arp', 'vpn', 'cdn',
    'ide', 'sdk', 'cli', 'gui', 'ci', 'cd', 'vm', 'vps', 'k8s', 'aws', 'gcp',
    'azure', 'rest', 'grpc', 'graphql', 'redis', 'kafka', 'docker', 'linux',
    'nginx', 'mysql', 'git', 'npm', 'pip', 'maven', 'gradle', 'dart', 'java',
  };
  final lower = term.toLowerCase();
  if (acronyms.contains(lower)) return true;
  if (RegExp(r'[A-Z]').hasMatch(term)) return true;
  // 小写技术名词至少 4 个字符，像 build、state、widget、commit 可以保留。
  return term.length >= 4;
}

/// 定义句里混进代码、日志或命令时直接放弃。
bool _looksCodeish(String text) {
  if (RegExp(r'[`=]').hasMatch(text)) return true;
  if (text.contains('://')) return true;
  if (RegExp(r'\b(Cookie|session_id|TODO|FIXME)\b').hasMatch(text)) return true;
  if (RegExp(r'[A-Za-z0-9_]{3,}\s*[:=]').hasMatch(text)) return true;
  if (RegExp(r'[{}\[\]]').hasMatch(text)) return true;
  if (text.contains(' ／ ')) return true;
  return false;
}

/// 说明压到 72 字以内，尽量在子句边界收尾。
String? _trimDefinition(String raw) {
  var text = raw
      .replaceAll('\n', ' ')
      .replaceAll('|', '／')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) return null;
  if (templateMarkers.any(text.contains)) return null;
  if (text.length > 72) {
    final cut = text.substring(0, 72);
    final boundary = cut.lastIndexOf(RegExp(r'[，；：]'));
    text = (boundary >= 24 ? cut.substring(0, boundary) : cut).trim();
  }
  text = text.replaceFirst(RegExp(r'[，。；：]+$'), '').trim();
  if (text.length < 8) return null;
  return text;
}

/// 只保留三个讲解小节里的正文，供回退策略使用。
String _proseOf(String body) {
  final buffer = StringBuffer();
  var inFence = false;
  var inSection = false;
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      inSection = allowedSections.contains(trimmed.substring(3).trim());
      continue;
    }
    if (!inSection) continue;
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (trimmed.startsWith('|')) continue;
    buffer.writeln(line);
  }
  return buffer.toString();
}
