import '../models/code_snippet.dart';
import '../models/global_search.dart';
import '../models/lesson.dart';
import '../models/lesson_category.dart';
import '../models/note.dart';
import '../models/sandbox_language.dart';
import 'content_provider.dart';
import 'practice_question_factory.dart';
import 'progress_provider.dart';
import 'snippet_service.dart';

/// 统一搜索：课程全文（倒排索引）+ 本地学习数据（笔记、错题、术语、
/// 片段、挑战）。除课程索引外都只读本地存储，不联网。
class GlobalSearchService {
  const GlobalSearchService({
    required this.content,
    required this.progress,
    required this.snippets,
  });

  final ContentProvider content;
  final ProgressProvider progress;
  final SnippetService snippets;

  Future<GlobalSearchResults> search(
    String rawQuery, {
    String? categoryId,
    Set<String>? lessonIds,
  }) async {
    final query = _normalize(rawQuery);
    if (query.isEmpty) return GlobalSearchResults.empty;

    final lessons = await content.search(
      rawQuery,
      categoryId: categoryId,
      lessonIds: lessonIds,
    );
    // 术语索引与课程索引在同一轮构建中生成，这里只是读取。
    final terms = await content.searchTerms(rawQuery, categoryId: categoryId);
    final lessonsById = <String, Lesson>{
      for (final category in content.categories)
        for (final lesson in category.lessons) lesson.id: lesson,
    };
    final categoriesById = <String, LessonCategory>{
      for (final category in content.categories) category.id: category,
    };

    return GlobalSearchResults(
      lessons: lessons,
      notes: matchNotes(
        notes: progress.notes.values,
        lessonsById: lessonsById,
        categoriesById: categoriesById,
        query: query,
        categoryId: categoryId,
      ),
      wrongQuestions: matchWrongQuestions(
        keys: progress.wrongQuestionKeys,
        lessonsById: lessonsById,
        categoriesById: categoriesById,
        query: query,
        wrongCountOf: progress.wrongCountOf,
        categoryId: categoryId,
      ),
      terms: terms,
      snippets: matchSnippets(items: snippets.snippets, query: query),
      challenges: matchChallenges(
        languages: SandboxLanguage.values,
        query: query,
      ),
    );
  }

  static List<NoteHit> matchNotes({
    required Iterable<Note> notes,
    required Map<String, Lesson> lessonsById,
    required Map<String, LessonCategory> categoriesById,
    required String query,
    String? categoryId,
  }) {
    final hits = <NoteHit>[];
    for (final note in notes) {
      final haystack = _normalize(
        '${note.content} ${note.tags.join(' ')}',
      );
      if (!haystack.contains(query)) continue;
      final lesson = lessonsById[note.lessonId];
      final category = lesson == null
          ? null
          : categoriesById[lesson.categoryId];
      if (lesson == null || category == null) continue;
      if (categoryId != null && category.id != categoryId) continue;
      hits.add(
        NoteHit(
          note: note,
          lesson: lesson,
          category: category,
          snippet: _excerpt(note.content, query),
          matchedTerms: <String>[query],
        ),
      );
    }
    hits.sort((a, b) => b.note.updatedAt.compareTo(a.note.updatedAt));
    return List<NoteHit>.unmodifiable(hits.take(12));
  }

  static List<WrongQuestionHit> matchWrongQuestions({
    required List<String> keys,
    required Map<String, Lesson> lessonsById,
    required Map<String, LessonCategory> categoriesById,
    required String query,
    required int Function(String lessonId, int questionIndex) wrongCountOf,
    String? categoryId,
  }) {
    final hits = <WrongQuestionHit>[];
    for (final key in keys) {
      final parts = key.split('#');
      if (parts.length != 2) continue;
      final lesson = lessonsById[parts[0]];
      final index = int.tryParse(parts[1]);
      if (lesson == null || index == null) continue;
      if (index < 0 || index >= lesson.allQuiz.length) continue;
      final question = lesson.allQuiz[index];
      final haystack = _normalize(
        '${question.question} ${question.options.join(' ')} '
        '${question.explanation} ${question.code ?? ''}',
      );
      if (!haystack.contains(query)) continue;
      final category = categoriesById[lesson.categoryId];
      if (category == null) continue;
      if (categoryId != null && category.id != categoryId) continue;
      hits.add(
        WrongQuestionHit(
          lesson: lesson,
          category: category,
          questionIndex: index,
          question: question,
          snippet: _excerpt(
            question.explanation.isNotEmpty
                ? question.explanation
                : question.question,
            query,
          ),
          wrongCount: wrongCountOf(lesson.id, index),
          matchedTerms: <String>[query],
        ),
      );
    }
    hits.sort((a, b) {
      final byCount = b.wrongCount.compareTo(a.wrongCount);
      if (byCount != 0) return byCount;
      return a.lesson.id.compareTo(b.lesson.id);
    });
    return List<WrongQuestionHit>.unmodifiable(hits.take(12));
  }

  static List<SnippetHit> matchSnippets({
    required Iterable<CodeSnippet> items,
    required String query,
  }) {
    final hits = <SnippetHit>[];
    for (final item in items) {
      final haystack = _normalize(
        '${item.title} ${item.code} ${item.stdin}',
      );
      if (!haystack.contains(query)) continue;
      hits.add(
        SnippetHit(
          snippet: item,
          excerpt: _excerpt(item.code, query),
          matchedTerms: <String>[query],
        ),
      );
      if (hits.length >= 12) break;
    }
    return List<SnippetHit>.unmodifiable(hits);
  }

  static List<ChallengeHit> matchChallenges({
    required Iterable<SandboxLanguage> languages,
    required String query,
  }) {
    final hits = <ChallengeHit>[];
    for (final language in languages) {
      for (final challenge in language.challenges) {
        final haystack = _normalize(
          '${challenge.title.zh} ${challenge.title.en} '
          '${challenge.prompt.zh} ${challenge.prompt.en} '
          '${challenge.starterCode}',
        );
        if (!haystack.contains(query)) continue;
        hits.add(
          ChallengeHit(
            language: language,
            challenge: challenge,
            matchedTerms: <String>[query],
          ),
        );
        if (hits.length >= 12) return List<ChallengeHit>.unmodifiable(hits);
      }
    }
    return List<ChallengeHit>.unmodifiable(hits);
  }

  static String _normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _excerpt(String text, String query, {int max = 160}) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.isEmpty) return '';
    final index = flat.toLowerCase().indexOf(query);
    if (index < 0) {
      return flat.length <= max ? flat : '${flat.substring(0, max)}…';
    }
    final start = (index - 40).clamp(0, flat.length);
    final end = (index + query.length + 100).clamp(0, flat.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < flat.length ? '…' : '';
    return '$prefix${flat.substring(start, end)}$suffix';
  }
}
