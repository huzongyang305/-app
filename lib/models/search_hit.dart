import 'lesson.dart';
import 'lesson_category.dart';

/// 搜索结果：知识点 + 所属分类 + 命中片段。
class SearchHit {
  const SearchHit({
    required this.lesson,
    required this.category,
    required this.snippet,
    this.matchedTerms = const <String>[],
  });

  final Lesson lesson;
  final LessonCategory category;

  /// 关键词附近的文本片段，便于用户判断是否命中。
  final String snippet;

  /// 命中标题、关键词或摘要的词，供界面高亮使用。
  final List<String> matchedTerms;
}
