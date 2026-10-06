import '../models/note.dart';

/// 笔记导出与统计：把本地笔记整理成可分享、可备份的 Markdown / JSON 文本。
///
/// 纯函数实现，不写文件、不联网；调用方决定把结果复制到剪贴板或保存。
class NoteExportService {
  const NoteExportService._();

  /// 导出全部笔记为 Markdown；[titleOf] 把 lessonId 映射为课程标题。
  static String toMarkdown(
    List<Note> notes, {
    required String Function(String lessonId) titleOf,
    String? tag,
  }) {
    final filtered = tag == null
        ? notes.toList()
        : notes.where((note) => note.tags.contains(tag)).toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final buffer = StringBuffer()
      ..writeln('# 学习笔记')
      ..writeln()
      ..writeln('共 ${filtered.length} 条${tag == null ? '' : '（标签：$tag）'}')
      ..writeln();
    for (final note in filtered) {
      buffer
        ..writeln('## ${titleOf(note.lessonId)}')
        ..writeln()
        ..writeln('- 课程 ID：`${note.lessonId}`')
        ..writeln('- 更新时间：${_formatTime(note.updatedAt)}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('- 标签：${note.tags.join('、')}');
      }
      buffer
        ..writeln()
        ..writeln(note.content.trim().isEmpty ? '（空白笔记）' : note.content.trim())
        ..writeln()
        ..writeln('---')
        ..writeln();
    }
    return buffer.toString().trimRight();
  }

  /// 导出为 JSON 字符串，字段与本地存储保持一致，方便备份与迁移。
  static String toJson(List<Note> notes) {
    final buffer = StringBuffer('[\n');
    for (var index = 0; index < notes.length; index++) {
      final note = notes[index];
      buffer
        ..write('  ')
        ..write(_encode(note.toJson()))
        ..write(index == notes.length - 1 ? '\n' : ',\n');
    }
    buffer.write(']');
    return buffer.toString();
  }

  /// 笔记统计：总数、有内容数、标签分布与最近更新时间。
  static NoteStatistics statistics(List<Note> notes) {
    final tagCounts = <String, int>{};
    var nonEmpty = 0;
    DateTime? latest;
    var totalCharacters = 0;
    for (final note in notes) {
      for (final tag in note.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      final content = note.content.trim();
      totalCharacters += content.length;
      if (content.isNotEmpty) nonEmpty++;
      if (latest == null || note.updatedAt.isAfter(latest)) {
        latest = note.updatedAt;
      }
    }
    return NoteStatistics(
      total: notes.length,
      nonEmpty: nonEmpty,
      totalCharacters: totalCharacters,
      tagCounts: tagCounts,
      latestUpdatedAt: latest,
    );
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  static String _encode(Map<String, dynamic> value) {
    final entries = value.entries.map((entry) {
      final raw = entry.value;
      final content = raw is List
          ? '[${raw.map((item) => '"${_escape('$item')}"').join(',')}]'
          : '"${_escape('$raw')}"';
      return '"${entry.key}": $content';
    });
    return '{${entries.join(', ')}}';
  }

  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}

/// 笔记统计结果。
class NoteStatistics {
  const NoteStatistics({
    required this.total,
    required this.nonEmpty,
    required this.totalCharacters,
    required this.tagCounts,
    required this.latestUpdatedAt,
  });

  final int total;
  final int nonEmpty;
  final int totalCharacters;
  final Map<String, int> tagCounts;
  final DateTime? latestUpdatedAt;

  List<MapEntry<String, int>> get topTags {
    final entries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(10).toList(growable: false);
  }
}
