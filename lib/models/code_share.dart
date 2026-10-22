/// 代码分享模型
class CodeShare {
  const CodeShare({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.title,
    required this.code,
    required this.language,
    required this.createdAt,
    this.description,
    this.lessonId,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.tags = const [],
  });

  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String title;
  final String code;
  final String language;
  final DateTime createdAt;
  final String? description;
  final String? lessonId;
  final int likes;
  final int comments;
  final bool isLiked;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'userAvatar': userAvatar,
    'title': title,
    'code': code,
    'language': language,
    'createdAt': createdAt.toIso8601String(),
    'description': description,
    'lessonId': lessonId,
    'likes': likes,
    'comments': comments,
    'isLiked': isLiked,
    'tags': tags,
  };

  factory CodeShare.fromJson(Map<String, dynamic> json) {
    return CodeShare(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userAvatar: json['userAvatar'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      language: json['language'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      lessonId: json['lessonId'] as String?,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  CodeShare copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? title,
    String? code,
    String? language,
    DateTime? createdAt,
    String? description,
    String? lessonId,
    int? likes,
    int? comments,
    bool? isLiked,
    List<String>? tags,
  }) {
    return CodeShare(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      code: code ?? this.code,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      lessonId: lessonId ?? this.lessonId,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
    );
  }
}

/// 代码评论
class CodeComment {
  const CodeComment({
    required this.id,
    required this.shareId,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.parentId,
  });

  final String id;
  final String shareId;
  final String userId;
  final String username;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final String? parentId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'shareId': shareId,
    'userId': userId,
    'username': username,
    'userAvatar': userAvatar,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'parentId': parentId,
  };

  factory CodeComment.fromJson(Map<String, dynamic> json) {
    return CodeComment(
      id: json['id'] as String,
      shareId: json['shareId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userAvatar: json['userAvatar'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentId: json['parentId'] as String?,
    );
  }
}
