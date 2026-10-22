import 'dart:math';

import '../models/flashcard.dart';
import '../models/lesson.dart';
import '../models/note.dart';
import 'practice_question_factory.dart';

/// 闪卡服务：把本地题库与笔记转成可自评的卡片队列。
///
/// 闪卡完全离线生成，不新增资产文件；同一课程每天生成的卡片
/// 顺序稳定，便于「接着上次继续」。
class FlashcardService {
  const FlashcardService._();

  /// 每门课最多抽取的题目卡数量，避免一门课淹没整场复习。
  static const int maxQuestionsPerLesson = 4;

  /// 生成卡片队列。
  ///
  /// [categoryId] / [lessonId] 为空表示不过滤；[seed] 用于稳定洗牌，
  /// 传 null 时按当前时间随机。
  static List<Flashcard> buildQueue(
    List<Lesson> lessons, {
    List<Note> notes = const <Note>[],
    String? categoryId,
    String? lessonId,
    bool includeNotes = true,
    int maxCards = 40,
    int? seed,
  }) {
    final selected = lessons.where((lesson) {
      if (categoryId != null && lesson.categoryId != categoryId) return false;
      if (lessonId != null && lesson.id != lessonId) return false;
      return true;
    }).toList();

    final cards = <Flashcard>[];
    for (final lesson in selected) {
      final quiz = lesson.allQuiz;
      if (quiz.isEmpty) continue;
      final indexes = List<int>.generate(quiz.length, (index) => index)
        ..shuffle(Random(seed == null ? null : seed + lesson.id.hashCode));
      for (final index in indexes.take(maxQuestionsPerLesson)) {
        cards.add(
          Flashcard.fromQuestion(
            lesson: lesson,
            question: quiz[index],
            questionIndex: index,
          ),
        );
      }
    }

    if (includeNotes && notes.isNotEmpty) {
      final byId = <String, Lesson>{
        for (final lesson in selected) lesson.id: lesson,
      };
      for (final note in notes) {
        final lesson = byId[note.lessonId];
        if (lesson == null) continue;
        // 笔记可在笔记页一键开关是否参与闪卡。
        if (!note.flashcardEnabled) continue;
        final content = note.content.trim();
        if (content.isEmpty) continue;
        cards.add(Flashcard.fromNote(lesson: lesson, content: content));
      }
    }

    cards.shuffle(Random(seed));
    if (cards.length <= maxCards) return cards;
    return cards.take(maxCards).toList(growable: false);
  }

  /// 可出卡的课程数量，用于入口页展示与空态判断。
  static int availableLessonCount(List<Lesson> lessons, {String? categoryId}) =>
      lessons
          .where(
            (lesson) =>
                (categoryId == null || lesson.categoryId == categoryId) &&
                lesson.allQuiz.isNotEmpty,
          )
          .length;
}
