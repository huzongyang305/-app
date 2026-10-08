// P1-6 共享工具：选项长度线索的公共判定与「自然限定子句」语料。
//
// 背景：题库里正确项经常写得比干扰项更完整，形成「最长项就是答案」的暗示。
// 修复手段是给干扰项补一个语气自然的限定子句（而不是教科书式的
// 「（混淆了相邻概念，不能回答本题）」这类明显的元评论），
// 既拉平长度，又保持选项读起来像正常的答案。
import 'dart:math' as math;

/// 与题目无关的通用限定子句。
const List<String> genericCaveats = <String>[
  '，但这会带来额外的维护成本',
  '，实际效果取决于具体实现',
  '，但这会引入新的复杂度',
  '，需要额外的验证与维护',
  '，但它只覆盖了部分情况',
  '，不过这需要额外的前提条件',
  '，但它并不是通用的做法',
  '，往往无法达到预期效果',
];

/// 按主题挑选的限定子句，让补出来的话读起来更像该领域的正常选项。
const Map<String, List<String>> domainCaveats = <String, List<String>>{
  'performance': <String>[
    '，但这会拖慢关键路径的响应',
    '，但这会增加每帧的开销',
    '，但这会让抖动更明显',
    '，实际收益取决于具体负载',
    '，但在高并发下会明显劣化',
    '，但这只是把开销挪到了别处',
  ],
  'memory': <String>[
    '，但这会占用更多内存',
    '，但这会加重回收压力',
    '，但生命周期结束后仍可能被引用',
    '，实际占用取决于运行环境',
    '，但这并不能根治泄漏',
  ],
  'security': <String>[
    '，但这会留下攻击面',
    '，但这无法抵御主动攻击',
    '，但这需要额外的密钥管理',
    '，但在边界输入下并不安全',
    '，但这只是隐藏了风险',
  ],
  'maintainability': <String>[
    '，但这会降低可维护性',
    '，但这会让后续改动更难',
    '，但这会增加理解成本',
    '，但很快就会出现重复代码',
    '，但耦合会越来越重',
  ],
  'build': <String>[
    '，但这会让包体更大',
    '，但这会拖慢构建速度',
    '，但这会引入额外的依赖',
    '，但需要额外的缓存与清理',
    '，但这会牺牲可复现性',
  ],
  'data': <String>[
    '，但这会带来一致性问题',
    '，但这在数据量大时不可行',
    '，但这会破坏事务边界',
    '，但这会加重锁竞争',
    '，但这无法保证正确性',
  ],
  'network': <String>[
    '，但这会增加往返次数',
    '，但这会在弱网下失败',
    '，但这会放大延迟',
    '，但这需要额外的重试机制',
    '，但这会带来一致性问题',
  ],
  'testing': <String>[
    '，但这会掩盖真实的缺陷',
    '，但这会让用例变得脆弱',
    '，但这只覆盖了理想路径',
    '，但这无法复现线上问题',
    '，但这会拖慢反馈速度',
  ],
};

/// 主题关键词 → 语料分类。
const List<List<String>> _topicRules = <List<String>>[
  <String>[
    'performance',
    '性能|耗时|延迟|卡顿|帧率|渲染|吞吐|CPU|GPU|带宽|QPS|优化',
  ],
  <String>['memory', '内存|泄漏|缓存|对象|回收|GC|占用'],
  <String>['security', '安全|注入|密钥|权限|认证|授权|加密|攻击|漏洞|隐私'],
  <String>['maintainability', '可维护|命名|注释|重构|风格|耦合|抽象|设计模式'],
  <String>['build', '构建|编译|依赖|打包|体积|镜像|包体|发布'],
  <String>['data', '数据库|索引|事务|一致性|SQL|表|查询|存储'],
  <String>['network', '网络|请求|HTTP|连接|超时|DNS|TCP|重试'],
  <String>['testing', '测试|用例|断言|覆盖|CI|回归|验证'],
];

/// 稳定哈希：保证同一道题每次运行时补的句子一致。
int stableHash(String text) {
  var hash = 7;
  for (final rune in text.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash;
}

/// 按子句边界切分，括号内不切。
List<String> splitClauses(String text) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '(' || ch == '（') depth++;
    if (ch == ')' || ch == '）') depth = depth > 0 ? depth - 1 : 0;
    if (depth == 0 && (ch == '，' || ch == '；' || ch == '、')) {
      parts.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString());
  return parts;
}

/// 干扰项是否「像一句完整的话」，可以安全续写限定子句。
bool canAppendClause(String text) {
  final trimmed = text.trim();
  if (trimmed.length < 6) return false;
  if (trimmed.startsWith('.') || trimmed.startsWith('/')) return false;
  // 纯代码/标识符（如 notifyListeners、df.to_csv）不能直接接中文从句。
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_./{}\s]*$').hasMatch(trimmed)) {
    return false;
  }
  final cjk = RegExp(r'[\u4e00-\u9fff]').allMatches(trimmed).length;
  if (cjk < 4) return false;
  if (trimmed.endsWith('。') ||
      trimmed.endsWith('；') ||
      trimmed.endsWith('，')) {
    return false;
  }
  return true;
}

/// 该选项是否已经补过限定子句（避免重复叠加）。
bool alreadyCaveated(String text) {
  final trimmed = text.trim();
  for (final clause in <String>[
    ...genericCaveats,
    ...domainCaveats.values.expand((pool) => pool),
  ]) {
    if (trimmed.endsWith(clause.replaceFirst('，', ''))) return true;
  }
  return RegExp(
    r'[（(](仅部分场景成立|与课程定义不一致|忽略了题干限定的前提|'
    r'只在个别条件下成立|只在边界情况下成立|没有覆盖题干给出的条件|'
    r'混淆了相邻概念|不能回答本题|不能作为答案)',
  ).hasMatch(trimmed);
}

/// 该选项可用的限定子句候选（主题语料在前，通用语料在后）。
List<String> caveatCandidates(String question, String option) {
  final context = '$question $option';
  final pools = <List<String>>[];
  for (final rule in _topicRules) {
    if (RegExp(rule[1]).hasMatch(context)) {
      pools.add(domainCaveats[rule[0]]!);
    }
  }
  pools.add(genericCaveats);
  return pools.expand((pool) => pool).toList();
}

/// 为选项挑一个自然的限定子句；无法安全续写时返回 null。
String? naturalCaveatFor(String question, String option, {int salt = 0}) {
  if (!canAppendClause(option) || alreadyCaveated(option)) return null;
  final candidates = caveatCandidates(question, option)
      .where((clause) => !option.endsWith(clause.replaceFirst('，', '')))
      .toList();
  if (candidates.isEmpty) return null;
  return candidates[(stableHash(option) + salt) % candidates.length];
}

/// 把干扰项补到「不短于正确项」所需的最短限定子句。
///
/// [maxOvershoot] 限制补完之后比正确项长出的字符数，避免制造反向线索。
String? caveatToReach(
  String question,
  String option,
  int targetLength, {
  int maxOvershoot = 8,
}) {
  if (!canAppendClause(option) || alreadyCaveated(option)) return null;
  final candidates = caveatCandidates(question, option);
  final window = <String>[];
  for (final clause in candidates) {
    final length = option.length + clause.length;
    if (length >= targetLength && length <= targetLength + maxOvershoot) {
      window.add(clause);
    }
  }
  if (window.isNotEmpty) {
    window.sort((a, b) => a.length.compareTo(b.length));
    // 在最短的若干候选里按稳定哈希挑一个，避免所有题补同一句。
    final take = math.min(3, window.length);
    return window[(stableHash(option) + targetLength) % take];
  }
  final longer = candidates
      .where((clause) => option.length + clause.length >= targetLength)
      .toList()
    ..sort((a, b) => a.length.compareTo(b.length));
  return longer.isEmpty ? null : longer.first;
}

/// 与 [caveatToReach] 相同，但必要时叠加两个限定子句。
///
/// 有些干扰项只有十来个字，而正确项是一整句，靠单个子句补不到目标长度；
/// 这时允许再叠加一句，仍然保持口语化的读感。
String? caveatsToReach(
  String question,
  String option,
  int targetLength, {
  int maxOvershoot = 14,
}) {
  final single = caveatToReach(
    question,
    option,
    targetLength,
    maxOvershoot: maxOvershoot,
  );
  if (single != null) return single;
  if (!canAppendClause(option) || alreadyCaveated(option)) return null;
  final candidates = caveatCandidates(question, option);
  String? best;
  var bestOvershoot = 1 << 30;
  for (final first in candidates) {
    for (final second in candidates) {
      if (first == second) continue;
      final length = option.length + first.length + second.length;
      if (length < targetLength) continue;
      final overshoot = length - targetLength;
      if (overshoot > maxOvershoot) continue;
      if (overshoot < bestOvershoot) {
        bestOvershoot = overshoot;
        // 两个子句都以「但」开头时读起来打结，第二句换成「同时」。
        final secondText = first.startsWith('，但') && second.startsWith('，但')
            ? '，同时${second.replaceFirst('，但', '')}'
            : second;
        best = '$first$secondText';
      }
    }
  }
  return best;
}
