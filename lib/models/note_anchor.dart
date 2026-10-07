/// 笔记锚点：记录笔记关联的章节与阅读位置。
///
/// 阅读页允许用户从当前章节创建锚点；重新打开教程时可以按阅读进度快速回到
/// 对应位置，不依赖 Markdown 内部的绝对字符偏移，因此内容包更新后仍然可用。
class NoteAnchor {
  const NoteAnchor({
    required this.title,
    required this.progress,
    this.createdAt,
  });

  /// 章节标题，例如「常见错误与排查」。
  final String title;

  /// 归一化阅读位置（0..1），用于重新打开时恢复滚动位置。
  final double progress;

  /// 创建时间；旧数据可能没有该字段。
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'progress': progress,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory NoteAnchor.fromJson(Map<String, dynamic> json) {
    return NoteAnchor(
      title: json['title']?.toString() ?? '',
      progress: ((json['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
