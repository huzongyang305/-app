/// 代码沙箱片段：可保存、收藏、分享的代码 + 标准输入。
class CodeSnippet {
  const CodeSnippet({
    required this.id,
    required this.languageId,
    required this.title,
    required this.code,
    this.stdin = '',
    required this.createdAt,
    required this.updatedAt,
    this.favorite = false,
  });

  final String id;
  final String languageId;
  final String title;
  final String code;
  final String stdin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool favorite;

  CodeSnippet copyWith({
    String? languageId,
    String? title,
    String? code,
    String? stdin,
    DateTime? updatedAt,
    bool? favorite,
  }) {
    return CodeSnippet(
      id: id,
      languageId: languageId ?? this.languageId,
      title: title ?? this.title,
      code: code ?? this.code,
      stdin: stdin ?? this.stdin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'languageId': languageId,
    'title': title,
    'code': code,
    'stdin': stdin,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'favorite': favorite,
  };

  factory CodeSnippet.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updated = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    return CodeSnippet(
      id: json['id']?.toString() ?? '',
      languageId: json['languageId']?.toString() ?? 'javascript',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      stdin: json['stdin']?.toString() ?? '',
      createdAt: created ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updated ?? created ?? DateTime.fromMillisecondsSinceEpoch(0),
      favorite: json['favorite'] == true,
    );
  }
}