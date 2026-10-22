import 'lesson.dart';

/// 作答时的信心程度，用于校准掌握度与错因分析。
enum AnswerConfidence {
  guessed('guessed'),
  unsure('unsure'),
  confident('confident');

  const AnswerConfidence(this.storageKey);

  final String storageKey;

  static AnswerConfidence fromStorage(String? value) {
    for (final item in AnswerConfidence.values) {
      if (item.storageKey == value) return item;
    }
    return AnswerConfidence.unsure;
  }
}

/// 一次作答的中间状态。
///
/// 用同一个对象承载单选、多选、填空和排序，页面层无需为不同题型维护多套
/// 分散变量，模拟考试也能直接序列化每道题的作答状态。
class QuizAnswer {
  const QuizAnswer({
    this.selectedIndexes = const <int>{},
    this.text = '',
    this.orderedIndexes = const <int>[],
    this.confidence = AnswerConfidence.unsure,
    this.responded = false,
  });

  final Set<int> selectedIndexes;
  final String text;
  final List<int> orderedIndexes;

  /// 自评信心：用于区分真正掌握和猜对。
  final AnswerConfidence confidence;

  /// 是否已经产生过有效作答。
  ///
  /// [responded] 表示用户是否真正操作过（拖动、输入、选择），用于答题卡与
  /// 交卷检查；排序题的初始顺序本身就是一个可提交的答案，因此即使没有拖动，
  /// 也允许直接提交当前顺序，避免用户被卡在「必须动一下才能继续」。
  final bool responded;

  factory QuizAnswer.initial(QuizQuestion question) {
    return QuizAnswer(
      orderedIndexes: question.type == 'order'
          ? List<int>.generate(question.options.length, (i) => i)
          : const <int>[],
    );
  }

  bool get hasResponse =>
      responded ||
      selectedIndexes.isNotEmpty ||
      text.trim().isNotEmpty ||
      orderedIndexes.isNotEmpty;

  QuizAnswer copyWith({
    Set<int>? selectedIndexes,
    String? text,
    List<int>? orderedIndexes,
    AnswerConfidence? confidence,
    bool? responded,
  }) {
    return QuizAnswer(
      selectedIndexes: selectedIndexes ?? this.selectedIndexes,
      text: text ?? this.text,
      orderedIndexes: orderedIndexes ?? this.orderedIndexes,
      confidence: confidence ?? this.confidence,
      responded: responded ?? this.responded,
    );
  }

  /// 序列化为可持久化的 JSON，用于模拟考试断点续考。
  Map<String, dynamic> toJson() => <String, dynamic>{
    'selected': selectedIndexes.toList()..sort(),
    'text': text,
    'ordered': orderedIndexes,
    'confidence': confidence.storageKey,
    'responded': responded,
  };

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    final selected = (json['selected'] as List<dynamic>? ?? const [])
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .toSet();
    final ordered = (json['ordered'] as List<dynamic>? ?? const [])
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
    return QuizAnswer(
      selectedIndexes: selected,
      text: json['text']?.toString() ?? '',
      orderedIndexes: ordered,
      confidence: AnswerConfidence.fromStorage(json['confidence']?.toString()),
      responded: json['responded'] == true,
    );
  }

  QuizAnswer toggleOption(int index) {
    final next = <int>{...selectedIndexes};
    if (!next.add(index)) next.remove(index);
    return copyWith(selectedIndexes: next, responded: true);
  }

  QuizAnswer selectOnly(int index) =>
      copyWith(selectedIndexes: <int>{index}, responded: true);

  bool matches(QuizQuestion question) {
    switch (question.type) {
      case 'fill':
        return _matchesFill(question);
      case 'order':
        return _matchesOrder(question);
      case 'multi':
        return _sameSet(selectedIndexes, question.correctIndexes.toSet());
      default:
        return selectedIndexes.length == 1 &&
            question.correctIndexes.contains(selectedIndexes.first);
    }
  }

  /// 部分得分：多选按正确选项覆盖率扣掉误选，排序按正确位置比例，
  /// 单选 / 填空仍为 0 或 1。用于展示更细的测验反馈。
  double scoreFor(QuizQuestion question) {
    if (matches(question)) return 1;
    switch (question.type) {
      case 'multi':
        final expected = question.correctIndexes.toSet();
        if (expected.isEmpty) return 0;
        final selected = selectedIndexes;
        final hit = selected.where(expected.contains).length;
        final wrong = selected.where((item) => !expected.contains(item)).length;
        return ((hit - wrong) / expected.length).clamp(0.0, 1.0);
      case 'order':
        final expected = question.correctOrder;
        if (expected.isEmpty || orderedIndexes.length != expected.length) {
          return 0;
        }
        var hit = 0;
        for (var i = 0; i < expected.length; i++) {
          if (orderedIndexes[i] == expected[i]) hit++;
        }
        return hit / expected.length;
      default:
        return 0;
    }
  }

  bool _matchesFill(QuizQuestion question) {
    final expected = question.acceptedAnswers;
    if (expected.isEmpty) return false;
    final actual = _normalize(text);
    return expected.any((answer) => _normalize(answer) == actual);
  }

  bool _matchesOrder(QuizQuestion question) {
    final expected = question.correctOrder;
    if (expected.isEmpty || orderedIndexes.length != expected.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i++) {
      if (orderedIndexes[i] != expected[i]) return false;
    }
    return true;
  }

  static bool _sameSet(Set<int> left, Set<int> right) {
    if (left.length != right.length) return false;
    for (final value in left) {
      if (!right.contains(value)) return false;
    }
    return true;
  }

  /// 填空判定忽略大小写、空白和常见中英文标点差异，减少“知道答案却因格式算错”。
  static String _normalize(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('（', '(')
      .replaceAll('）', ')')
      .replaceAll('，', ',')
      .replaceAll('。', '.');
}
