/// 复习自评档位：用户做完一轮复习后，对自己的掌握程度打分。
///
/// 三档对应三种调度策略（见 ProgressProvider.scheduleReviewWithGrade）：
///   · forgot     忘记了   → 回到第 1 档，1 天后再复习
///   · fuzzy      有点模糊 → 保持当前档位，间隔不前进
///   · remembered 记得     → 进入下一档，间隔逐级拉长（1 → 3 → 7 → 30 天）
enum ReviewGrade {
  forgot('forgot'),
  fuzzy('fuzzy'),
  remembered('remembered');

  const ReviewGrade(this.storageKey);

  /// 持久化用的稳定字符串（不要随意改动，否则老数据会读不回来）。
  final String storageKey;

  /// 从存储值还原，无法识别时返回 null。
  static ReviewGrade? fromStorage(String? value) {
    if (value == null) return null;
    for (final grade in ReviewGrade.values) {
      if (grade.storageKey == value) return grade;
    }
    return null;
  }
}
