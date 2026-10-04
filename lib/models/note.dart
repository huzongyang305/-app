/// 本地笔记：一个知识点对应一条笔记。
class Note {
  const Note({
    required this.lessonId,
    required this.content,
    required this.updatedAt,
  });

  final String lessonId;
  final String content;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      lessonId: json['lessonId'] as String,
      content: json['content'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
