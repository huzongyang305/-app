import 'note_anchor.dart';

/// 本地笔记：一个知识点对应一条笔记，可附加多个章节锚点。
class Note {
  const Note({
    required this.lessonId,
    required this.content,
    required this.updatedAt,
    this.tags = const <String>[],
    this.anchors = const <NoteAnchor>[],
    this.flashcardEnabled = true,
  });

  final String lessonId;
  final String content;
  final DateTime updatedAt;

  /// 用户自定义标签，用于跨课程检索；去重后按写入顺序保存。
  final List<String> tags;

  /// 关联的章节锚点，支持从笔记直接回到教程中的位置。
  final List<NoteAnchor> anchors;

  /// 是否把这条笔记加入闪卡队列。
  final bool flashcardEnabled;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
    'anchors': anchors.map((item) => item.toJson()).toList(),
    'flashcardEnabled': flashcardEnabled,
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
      anchors: ((json['anchors'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((item) => NoteAnchor.fromJson(item.cast<String, dynamic>()))
          .where((item) => item.title.trim().isNotEmpty)
          .toList(growable: false),
      flashcardEnabled: json['flashcardEnabled'] != false,
    );
  }
}
