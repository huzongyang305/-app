/// 好友信息模型
class Friend {
  const Friend({
    required this.id,
    required this.username,
    required this.avatar,
    required this.totalPoints,
    required this.streakDays,
    required this.learnedLessons,
    required this.completedChallenges,
    this.isOnline = false,
    this.lastActiveAt,
  });

  final String id;
  final String username;
  final String avatar;
  final int totalPoints;
  final int streakDays;
  final int learnedLessons;
  final int completedChallenges;
  final bool isOnline;
  final DateTime? lastActiveAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar': avatar,
    'totalPoints': totalPoints,
    'streakDays': streakDays,
    'learnedLessons': learnedLessons,
    'completedChallenges': completedChallenges,
    'isOnline': isOnline,
    'lastActiveAt': lastActiveAt?.toIso8601String(),
  };

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      totalPoints: json['totalPoints'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      learnedLessons: json['learnedLessons'] as int? ?? 0,
      completedChallenges: json['completedChallenges'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }

  Friend copyWith({
    String? id,
    String? username,
    String? avatar,
    int? totalPoints,
    int? streakDays,
    int? learnedLessons,
    int? completedChallenges,
    bool? isOnline,
    DateTime? lastActiveAt,
  }) {
    return Friend(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      totalPoints: totalPoints ?? this.totalPoints,
      streakDays: streakDays ?? this.streakDays,
      learnedLessons: learnedLessons ?? this.learnedLessons,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

/// 好友请求
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.fromAvatar,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String fromUserId;
  final String fromUsername;
  final String fromAvatar;
  final DateTime createdAt;
  final String? message;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUserId': fromUserId,
    'fromUsername': fromUsername,
    'fromAvatar': fromAvatar,
    'createdAt': createdAt.toIso8601String(),
    'message': message,
  };

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUsername: json['fromUsername'] as String,
      fromAvatar: json['fromAvatar'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      message: json['message'] as String?,
    );
  }
}
