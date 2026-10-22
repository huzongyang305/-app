import 'lesson.dart';
import 'localized_text.dart';

/// 课程分类：编程语言、计算机基础、算法等。
class LessonCategory {
  const LessonCategory({
    required this.id,
    required this.title,
    required this.iconName,
    required this.colorValue,
    required this.lessons,
  });

  final String id;
  final LocalizedText title;

  /// 图标名称，由 icon_mapper 映射为 Material 图标，便于在 JSON 中声明。
  final String iconName;

  /// 分类主题色，存储为 0xRRGGBB 整数。
  final int colorValue;
  final List<Lesson> lessons;

  factory LessonCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final colorHex = (json['color'] as String? ?? '2563EB').replaceAll('#', '');
    return LessonCategory(
      id: id,
      title: LocalizedText.fromJson(
        (json['title'] as Map).cast<String, dynamic>(),
      ),
      iconName: json['icon'] as String? ?? 'code',
      colorValue: int.parse(colorHex, radix: 16),
      lessons: (json['lessons'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                Lesson.fromJson((item as Map).cast<String, dynamic>(), id),
          )
          .toList(),
    );
  }
}
