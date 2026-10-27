import 'code_snippet.dart';
import 'lesson.dart';
import 'lesson_category.dart';
import 'note.dart';
import 'sandbox_challenge.dart';
import 'sandbox_language.dart';
import 'search_hit.dart';

/// 笔记命中：标题取所属课程，正文展示命中的笔记片段。
class NoteHit {
  const NoteHit({
    required this.note,
    required this.lesson,
    required this.category,
    required this.snippet,
    this.matchedTerms = const <String>[],
  });

  final Note note;
  final Lesson lesson;
  final LessonCategory category;
  final String snippet;
  final List<String> matchedTerms;
}

/// 错题命中：定位到具体题目，便于查看答案与解析。
class WrongQuestionHit {
  const WrongQuestionHit({
    required this.lesson,
    required this.category,
    required this.questionIndex,
    required this.question,
    required this.snippet,
    this.wrongCount = 1,
    this.matchedTerms = const <String>[],
  });

  final Lesson lesson;
  final LessonCategory category;
  final int questionIndex;
  final QuizQuestion question;
  final String snippet;
  final int wrongCount;
  final List<String> matchedTerms;
}

/// 术语命中：来自课文「术语速查」表。
class TermHit {
  const TermHit({
    required this.lesson,
    required this.category,
    required this.term,
    required this.explanation,
    this.matchedTerms = const <String>[],
  });

  final Lesson lesson;
  final LessonCategory category;
  final String term;
  final String explanation;
  final List<String> matchedTerms;
}

/// 代码片段命中：可直接在沙箱里继续编辑运行。
class SnippetHit {
  const SnippetHit({
    required this.snippet,
    required this.excerpt,
    this.matchedTerms = const <String>[],
  });

  final CodeSnippet snippet;
  final String excerpt;
  final List<String> matchedTerms;
}

/// 沙箱挑战命中。
class ChallengeHit {
  const ChallengeHit({
    required this.language,
    required this.challenge,
    this.matchedTerms = const <String>[],
  });

  final SandboxLanguage language;
  final SandboxChallenge challenge;
  final List<String> matchedTerms;
}

/// 统一搜索结果：课程全文 + 本地学习数据，按来源分组。
class GlobalSearchResults {
  const GlobalSearchResults({
    this.lessons = const <SearchHit>[],
    this.notes = const <NoteHit>[],
    this.wrongQuestions = const <WrongQuestionHit>[],
    this.terms = const <TermHit>[],
    this.snippets = const <SnippetHit>[],
    this.challenges = const <ChallengeHit>[],
  });

  static const GlobalSearchResults empty = GlobalSearchResults();

  final List<SearchHit> lessons;
  final List<NoteHit> notes;
  final List<WrongQuestionHit> wrongQuestions;
  final List<TermHit> terms;
  final List<SnippetHit> snippets;
  final List<ChallengeHit> challenges;

  int get total =>
      lessons.length +
      notes.length +
      wrongQuestions.length +
      terms.length +
      snippets.length +
      challenges.length;

  bool get isEmpty => total == 0;
}
