/// 某一天到期的复习量：知识点、题目与闪卡三类来源的合计。
class ReviewForecastDay {
  const ReviewForecastDay({
    required this.date,
    required this.lessons,
    required this.questions,
    required this.flashcards,
  });

  /// 当天 0 点。
  final DateTime date;

  /// 当天到期的知识点数量。
  final int lessons;

  /// 当天到期的题目数量。
  final int questions;

  /// 当天到期的术语 / 笔记闪卡数量。
  final int flashcards;

  /// 三类来源的合计。
  int get total => lessons + questions + flashcards;

  bool get isEmpty => total == 0;
}
