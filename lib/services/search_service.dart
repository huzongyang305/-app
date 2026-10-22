import '../data/pinyin_map.dart';
import '../models/lesson.dart';
import '../models/lesson_category.dart';
import '../models/search_hit.dart';

/// 课程搜索索引：倒排索引 + 中文二元组 + 拼音/首字母 + 同义词扩展。
///
/// 索引在第一次搜索时懒加载，之后重复查询只做内存打分，不再逐个读取
/// Markdown。索引随内容重新加载而重建，全部数据都在本地。
class LessonSearchIndex {
  /// 命中分低于该值视为噪声（例如中文子串巧合）。
  static const int _minScore = 2;

  final Map<String, _SearchDocument> _documents = <String, _SearchDocument>{};
  final Map<String, Set<String>> _postings = <String, Set<String>>{};
  String _fingerprint = '';

  /// 当前索引对应的内容指纹，用于判断持久缓存是否过期。
  String get fingerprint => _fingerprint;

  bool get isBuilt => _documents.isNotEmpty;

  /// 内容指纹：课程数量 + 每课 id 与标题的稳定哈希，避免缓存串版本。
  static String fingerprintOf(List<LessonCategory> categories) {
    final buffer = StringBuffer();
    for (final category in categories) {
      buffer
        ..write(category.id)
        ..write('#');
      for (final lesson in category.lessons) {
        buffer
          ..write(lesson.id)
          ..write(':')
          ..write(lesson.title.zh)
          ..write('|');
      }
    }
    return _stableHash(buffer.toString()).toRadixString(16);
  }

  /// 把索引压缩成可写入 Hive 的基础类型结构。
  ///
  /// 正文只保留前 3000 个字符：足够覆盖关键词正文检索，又能显著缩小缓存。
  Map<String, dynamic> toCacheJson() => <String, dynamic>{
    'fingerprint': _fingerprint,
    'documents': _documents.values
        .map(
          (doc) => <String>[
            doc.lesson.id,
            doc.category.id,
            doc.title,
            doc.summary,
            doc.keywords,
            doc.body.length > 3000 ? doc.body.substring(0, 3000) : doc.body,
            doc.categoryText,
            doc.pinyin,
            doc.initials,
          ],
        )
        .toList(growable: false),
    'postings': _postings.map(
      (token, ids) => MapEntry(token, ids.toList(growable: false)),
    ),
  };

  /// 从缓存恢复索引；指纹不匹配或数据损坏时返回 false，由调用方重新构建。
  bool restoreFromCache(
    List<LessonCategory> categories,
    Map<String, dynamic> cache,
  ) {
    final fingerprint = fingerprintOf(categories);
    if (cache['fingerprint']?.toString() != fingerprint) return false;
    final rawDocuments = cache['documents'];
    if (rawDocuments is! List || rawDocuments.isEmpty) return false;

    final lessons = <String, Lesson>{
      for (final category in categories)
        for (final lesson in category.lessons) lesson.id: lesson,
    };
    final byCategory = <String, LessonCategory>{
      for (final category in categories) category.id: category,
    };
    final documents = <String, _SearchDocument>{};
    for (final raw in rawDocuments) {
      if (raw is! List || raw.length < 9) return false;
      final lesson = lessons[raw[0].toString()];
      final category = byCategory[raw[1].toString()];
      if (lesson == null || category == null) return false;
      documents[lesson.id] = _SearchDocument(
        lesson: lesson,
        category: category,
        title: raw[2].toString(),
        summary: raw[3].toString(),
        keywords: raw[4].toString(),
        body: raw[5].toString(),
        categoryText: raw[6].toString(),
        pinyin: raw[7].toString(),
        initials: raw[8].toString(),
      );
    }

    final postings = <String, Set<String>>{};
    final rawPostings = cache['postings'];
    if (rawPostings is Map) {
      for (final entry in rawPostings.entries) {
        final ids = entry.value;
        if (ids is! List) return false;
        postings[entry.key.toString()] = ids
            .map((item) => item.toString())
            .where(documents.containsKey)
            .toSet();
      }
    }
    if (postings.isEmpty) {
      // 缓存里没有倒排表时用文档重建，保证功能完整。
      for (final document in documents.values) {
        for (final token in _tokensFor(
          '${document.title} ${document.summary} ${document.keywords} '
          '${document.categoryText} ${document.body}',
        )) {
          postings.putIfAbsent(token, () => <String>{}).add(document.lesson.id);
        }
      }
    }

    _documents
      ..clear()
      ..addAll(documents);
    _postings
      ..clear()
      ..addAll(postings);
    _fingerprint = fingerprint;
    return true;
  }

  Future<void> build(
    List<LessonCategory> categories,
    Future<String> Function(Lesson lesson) plainTextOf,
  ) async {
    _documents.clear();
    _postings.clear();

    for (final category in categories) {
      final categoryText = _normalize(
        '${category.title.zh} ${category.title.en}',
      );
      for (final lesson in category.lessons) {
        final body = _normalize(await plainTextOf(lesson));
        final title = _normalize('${lesson.title.zh} ${lesson.title.en}');
        final summary = _normalize('${lesson.summary.zh} ${lesson.summary.en}');
        final keywords = _normalize(lesson.keywords.join(' '));
        final document = _SearchDocument(
          lesson: lesson,
          category: category,
          title: title,
          summary: summary,
          keywords: keywords,
          body: body,
          categoryText: categoryText,
          // 索引侧同样使用紧凑拼音（去掉分词空格），否则用户输入
          // “pythonjichu”这类连续拼音时无法与带空格的索引匹配。
          pinyin: _pinyinFor('${lesson.title.zh} ${lesson.keywords.join('')}')
              .replaceAll(' ', ''),
          initials: _initialsFor(
            '${lesson.title.zh} ${lesson.keywords.join('')}',
          ),
        );
        _documents[lesson.id] = document;
        for (final token in _tokensFor(
          '$title $summary $keywords $categoryText $body',
        )) {
          _postings.putIfAbsent(token, () => <String>{}).add(lesson.id);
        }
      }
    }
    _fingerprint = fingerprintOf(categories);
  }

  List<SearchHit> search(
    String rawQuery, {
    String? categoryId,
    Set<String>? lessonIds,
  }) {
    final query = rawQuery.trim();
    if (query.isEmpty || _documents.isEmpty) return const <SearchHit>[];

    final normalized = _normalize(query);
    final tokens = _expandTokens(_tokensFor(normalized));
    final queryPinyin = _pinyinFor(query).replaceAll(' ', '');
    final queryInitials = _initialsFor(query).replaceAll(' ', '');
    final candidateIds = <String>{};

    for (final token in tokens) {
      candidateIds.addAll(_postings[token] ?? const <String>{});
    }

    // 文本没有命中时保留一个轻量兜底，覆盖单字、标点和少量错字场景。
    if (candidateIds.isEmpty || normalized.length <= 2) {
      candidateIds.addAll(_documents.keys);
    }

    final scored = <_ScoredSearchHit>[];
    for (final document in _documents.values) {
      if (categoryId != null && document.category.id != categoryId) continue;
      if (lessonIds != null && !lessonIds.contains(document.lesson.id)) {
        continue;
      }
      final score = _score(
        document,
        normalized: normalized,
        tokens: tokens,
        queryPinyin: queryPinyin,
        queryInitials: queryInitials,
        candidate: candidateIds.contains(document.lesson.id),
      );
      if (score <= 0) continue;
      scored.add(
        _ScoredSearchHit(
          hit: SearchHit(
            lesson: document.lesson,
            category: document.category,
            snippet: _snippet(document, normalized, tokens),
            matchedTerms: _matchedTerms(document, normalized, tokens),
          ),
          score: score,
        ),
      );
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.hit.lesson.id.compareTo(b.hit.lesson.id);
    });
    return scored.take(40).map((item) => item.hit).toList();
  }

  int _score(
    _SearchDocument document, {
    required String normalized,
    required List<String> tokens,
    required String queryPinyin,
    required String queryInitials,
    required bool candidate,
  }) {
    var score = 0;
    if (document.title.contains(normalized)) score += 24;
    if (document.keywords.contains(normalized)) score += 18;
    if (document.summary.contains(normalized)) score += 12;
    if (document.categoryText.contains(normalized)) score += 8;
    if (candidate && document.body.contains(normalized)) score += 5;

    for (final token in tokens) {
      if (document.title.contains(token)) score += 7;
      if (document.keywords.contains(token)) score += 6;
      if (document.summary.contains(token)) score += 4;
      if (candidate && document.body.contains(token)) score += 1;
    }

    // 与首字母同理：两字母拼音（sy）在长串里几乎必然撞车，
    // 要求至少 3 个字母，短查询走正文子串匹配。
    if (queryPinyin.length >= 3 && document.pinyin.contains(queryPinyin)) {
      score += 16;
    }
    // 首字母缩写歧义很大：两字母缩写（如 sy）几乎能命中任意课程，
    // 因此至少要 3 个字母才参与打分，宁可漏一点也不要制造假结果。
    if (queryInitials.length >= 3 &&
        document.initials.contains(queryInitials)) {
      score += 12;
    }
    // 中文没有天然分词，「索引用」这类连续文本会让「引用」等词命中
    // 单个正文 token（+1 分）。低于该阈值的命中噪声过大，直接丢弃。
    return score >= _minScore ? score : 0;
  }

  String _snippet(
    _SearchDocument document,
    String normalized,
    List<String> tokens,
  ) {
    final source = document.body.isNotEmpty
        ? document.body
        : document.summary.isNotEmpty
        ? document.summary
        : document.title;
    final candidates = <String>[normalized, ...tokens]
      ..sort((a, b) => b.length.compareTo(a.length));
    var index = -1;
    var matchLength = 0;
    for (final term in candidates) {
      if (term.length < 2) continue;
      final found = source.indexOf(term);
      if (found >= 0) {
        index = found;
        matchLength = term.length;
        break;
      }
    }
    if (index < 0) {
      final fallback = document.summary.isNotEmpty
          ? document.summary
          : document.title;
      return _clip(fallback, 160);
    }
    final start = (index - 42).clamp(0, source.length);
    final end = (index + matchLength + 92).clamp(0, source.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < source.length ? '…' : '';
    return '$prefix${source.substring(start, end).trim()}$suffix';
  }

  List<String> _matchedTerms(
    _SearchDocument document,
    String normalized,
    List<String> tokens,
  ) {
    final result = <String>{};
    if (_containsAnyMetadata(document, normalized)) result.add(normalized);
    for (final token in tokens) {
      if (token.length >= 2 && _containsAnyMetadata(document, token)) {
        result.add(token);
      }
    }
    return result.take(8).toList();
  }

  bool _containsAnyMetadata(_SearchDocument document, String value) =>
      document.title.contains(value) ||
      document.keywords.contains(value) ||
      document.summary.contains(value);
}

class _SearchDocument {
  const _SearchDocument({
    required this.lesson,
    required this.category,
    required this.title,
    required this.summary,
    required this.keywords,
    required this.body,
    required this.categoryText,
    required this.pinyin,
    required this.initials,
  });

  final Lesson lesson;
  final LessonCategory category;
  final String title;
  final String summary;
  final String keywords;
  final String body;
  final String categoryText;
  final String pinyin;
  final String initials;
}

class _ScoredSearchHit {
  const _ScoredSearchHit({required this.hit, required this.score});

  final SearchHit hit;
  final int score;
}

const Map<String, List<String>> _synonyms = <String, List<String>>{
  'http': <String>['超文本传输协议', 'https', '请求', '响应'],
  'https': <String>['tls', '证书', '加密', 'http'],
  'tcp': <String>['传输控制协议', '三次握手', '连接'],
  'dns': <String>['域名解析', '域名', '解析'],
  '并发': <String>['concurrency', '并行', '线程'],
  '并行': <String>['parallel', '并发', '多线程'],
  '数组': <String>['array', '列表', '顺序表'],
  '链表': <String>['linked list', '指针', '节点'],
  '指针': <String>['pointer', '地址', '引用'],
  '函数': <String>['function', '方法', '参数'],
  '索引': <String>['index', 'b树', '查询优化'],
  '事务': <String>['transaction', 'acid', '隔离级别'],
  '缓存': <String>['cache', '命中率', '局部性'],
  '进程': <String>['process', '线程', '调度'],
  '线程': <String>['thread', '并发', '进程'],
  '大模型': <String>['llm', '语言模型', 'transformer'],
  '智能体': <String>['agent', '工具调用', '规划'],
  '提示词': <String>['prompt', '上下文', '指令'],
  '向量': <String>['vector', 'embedding', '相似度'],
  '排序': <String>['sort', '快排', '归并'],
  '查找': <String>['search', '二分', '遍历'],
};

const Set<String> _stopWords = <String>{
  'a',
  'an',
  'and',
  'for',
  'of',
  'or',
  'the',
  'to',
  '的',
  '和',
  '与',
  '在',
  '是',
  '了',
};

List<String> _expandTokens(List<String> tokens) {
  final result = <String>{...tokens};
  for (final token in tokens) {
    result.addAll(_synonyms[token] ?? const <String>[]);
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(token)) result.add(entry.key);
    }
  }
  return result.where((token) => !_stopWords.contains(token)).toList();
}

List<String> _tokensFor(String text) {
  final result = <String>{};
  for (final match in RegExp(r'[a-z0-9][a-z0-9_+#.-]*').allMatches(text)) {
    final token = match.group(0)!;
    if (token.length >= 2) {
      result.add(token);
      if (token.endsWith('s') && token.length > 3) {
        result.add(token.substring(0, token.length - 1));
      }
    }
  }
  for (final match in RegExp(r'[\u4e00-\u9fff]+').allMatches(text)) {
    final sequence = match.group(0)!;
    result.add(sequence);
    if (sequence.length == 1) {
      result.add(sequence);
      continue;
    }
    for (var index = 0; index < sequence.length; index++) {
      if (index + 2 <= sequence.length) {
        result.add(sequence.substring(index, index + 2));
      }
    }
  }
  return result.toList();
}

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(
      RegExp(r'[\u0000-\u002f\u003a-\u0040\u005b-\u0060\u007b-\u007f]'),
      ' ',
    )
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _pinyinFor(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final pinyin = pinyinByCharacter[char];
    if (pinyin != null) {
      buffer.write(pinyin);
    } else if (RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(' ');
    }
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _initialsFor(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final pinyin = pinyinByCharacter[char];
    if (pinyin != null && pinyin.isNotEmpty) {
      buffer.write(pinyin[0]);
    } else if (RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
      buffer.write(char.toLowerCase());
    }
  }
  return buffer.toString();
}

String _clip(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max)}…';

/// FNV-1a 32 位稳定哈希：跨进程、跨平台结果一致，适合做缓存指纹。
int _stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
