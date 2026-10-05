/// 本地笔记：一个知识点对应一条笔记。
class Note {
  const Note({
    required this.lessonId,
    required this.content,
    required this.updatedAt,
    this.tags = const <String>[],
  });

  final String lessonId;
  final String content;
  final DateTime updatedAt;

  /// 用户自定义标签，用于跨课程检索；去重后按写入顺序保存。
  final List<String> tags;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      lessonId: json['lessonId'] as String,
      content: json['content'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      tags: ((json['tags'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }
}
