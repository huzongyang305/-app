import 'lesson.dart';

/// 一次作答的中间状态。
///
/// 用同一个对象承载单选、多选、填空和排序，页面层无需为不同题型维护多套
/// 分散变量，模拟考试也能直接序列化每道题的作答状态。
class QuizAnswer {
  const QuizAnswer({
    this.selectedIndexes = const <int>{},
    this.text = '',
    this.orderedIndexes = const <int>[],
  });

  final Set<int> selectedIndexes;
  final String text;
  final List<int> orderedIndexes;

  factory QuizAnswer.initial(QuizQuestion question) {
    return QuizAnswer(
      orderedIndexes: List<int>.generate(question.options.length, (i) => i),
    );
  }

  bool get hasResponse =>
      selectedIndexes.isNotEmpty ||
      text.trim().isNotEmpty ||
      orderedIndexes.isNotEmpty;

  QuizAnswer copyWith({
    Set<int>? selectedIndexes,
    String? text,
    List<int>? orderedIndexes,
  }) {
    return QuizAnswer(
      selectedIndexes: selectedIndexes ?? this.selectedIndexes,
      text: text ?? this.text,
      orderedIndexes: orderedIndexes ?? this.orderedIndexes,
    );
  }

  QuizAnswer toggleOption(int index) {
    final next = <int>{...selectedIndexes};
    if (!next.add(index)) next.remove(index);
    return copyWith(selectedIndexes: next);
  }

  QuizAnswer selectOnly(int index) => copyWith(selectedIndexes: <int>{index});

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
