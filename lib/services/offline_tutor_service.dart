import '../models/lesson.dart';
import '../models/tutor_reply.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

/// 离线学习助手：用本地课程索引和当前进度回答常见问题。
///
/// 它不会调用云端模型，也不会发送任何数据；回答方式以“下一步建议 +
/// 相关课程 + 可执行动作”为主，适合完全离线的学习场景。
class OfflineTutorService {
  const OfflineTutorService._();

  static TutorReply answer({
    required String query,
    required List<Lesson> lessons,
    required ProgressProvider progress,
    required SettingsProvider settings,
  }) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) {
      return const TutorReply(
        title: '可以问我什么',
        body: '例如：今天学什么、帮我找二分查找、我有多少错题、下一步怎么复习。',
        followUps: <String>['今天学什么', '我的错题', '复习计划'],
      );
    }
    if (_containsAny(text, const <String>['今天学什么', '下一步', '接下来', '推荐'])) {
      final next = _nextLesson(lessons, progress, settings);
      if (next == null) {
        return const TutorReply(
          title: '课程已全部完成',
          body: '现在最值得做的是复习到期内容和项目实战。建议打开“学习中心”查看今日任务。',
          followUps: <String>['复习计划', '项目实战'],
        );
      }
      return TutorReply(
        title: '建议先学：${next.title.zh}',
        body: '${next.summary.zh}\n\n预计 ${next.minutes} 分钟。学完后做一次测验，再安排间隔复习。',
        lessonIds: <String>[next.id],
        followUps: <String>['帮我找相关课程', '复习计划'],
      );
    }
    if (_containsAny(text, const <String>['错题', '错误', '薄弱'])) {
      final causes = progress.errorCauseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final causeText = causes.isEmpty
          ? '暂时没有记录错因。'
          : causes
                .take(3)
                .map((item) => '${item.key} ${item.value} 次')
                .join('、');
      return TutorReply(
        title: '错题概览',
        body:
            '当前错题本有 ${progress.totalWrongQuestions} 道题，曾经答错 ${progress.everWrongQuestions} 道，已消灭 ${progress.resolvedWrongQuestions} 道。\n\n主要错因：$causeText',
        followUps: const <String>['开始错题重练', '查看概念掌握度'],
      );
    }
    if (_containsAny(text, const <String>['复习', '到期', '遗忘'])) {
      final due = progress.dueReviewLessonIds;
      return TutorReply(
        title: '今日复习',
        body: due.isEmpty
            ? '今天没有到期复习。可以提前复习未来 7 天的内容，或学习一节新知识。'
            : '今天有 ${due.length} 门课程到期，优先复习逾期最久的内容。复习完成后用三档自评调整下次间隔。',
        lessonIds: due.take(5).toList(growable: false),
        followUps: const <String>['打开复习计划', '今天学什么'],
      );
    }

    final matches = _search(text, lessons);
    if (matches.isEmpty) {
      return TutorReply(
        title: '没有找到完全匹配的课程',
        body: '可以换一个更短的关键词，或直接使用搜索页。离线助手只会引用本机课程，不会编造外部答案。',
        followUps: const <String>['今天学什么', '复习计划'],
      );
    }
    final first = matches.first;
    return TutorReply(
      title: '找到相关课程：${first.title.zh}',
      body: '${first.summary.zh}\n\n相关课程还有 ${matches.length - 1} 门，可以在下方直接打开。',
      lessonIds: matches.take(6).map((item) => item.id).toList(growable: false),
      followUps: const <String>['今天学什么', '我有多少错题'],
    );
  }

  static List<Lesson> _search(String query, List<Lesson> lessons) {
    final terms = query
        .split(RegExp(r'\s+'))
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
    final scored = <MapEntry<Lesson, int>>[];
    for (final lesson in lessons) {
      final haystack =
          '${lesson.title.zh} ${lesson.title.en} '
                  '${lesson.summary.zh} ${lesson.keywords.join(' ')}'
              .toLowerCase();
      var score = 0;
      for (final term in terms) {
        if (haystack.contains(term)) score += 3;
        if (lesson.title.zh.toLowerCase().contains(term)) score += 5;
        if (lesson.keywords.any((item) => item.toLowerCase().contains(term))) {
          score += 2;
        }
      }
      if (score > 0) scored.add(MapEntry(lesson, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((item) => item.key).toList(growable: false);
  }

  static Lesson? _nextLesson(
    List<Lesson> lessons,
    ProgressProvider progress,
    SettingsProvider settings,
  ) {
    final ordered = [...lessons]
      ..sort((a, b) {
        final aPath = a.categoryId == settings.selectedPathId ? 0 : 1;
        final bPath = b.categoryId == settings.selectedPathId ? 0 : 1;
        if (aPath != bPath) return aPath.compareTo(bPath);
        final category = a.categoryId.compareTo(b.categoryId);
        return category != 0 ? category : a.order.compareTo(b.order);
      });
    for (final lesson in ordered) {
      if (!progress.isLearned(lesson.id)) return lesson;
    }
    return null;
  }

  static bool _containsAny(String text, List<String> values) =>
      values.any(text.contains);
}
