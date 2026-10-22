/// 学习小组模型
class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.members,
    required this.maxMembers,
    required this.createdAt,
    this.category,
    this.isPublic = true,
    this.activeChallengeId,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<GroupMember> members;
  final int maxMembers;
  final DateTime createdAt;
  final String? category;
  final bool isPublic;
  final String? activeChallengeId;

  int get memberCount => members.length;
  bool get isFull => members.length >= maxMembers;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'members': members.map((m) => m.toJson()).toList(),
    'maxMembers': maxMembers,
    'createdAt': createdAt.toIso8601String(),
    'category': category,
    'isPublic': isPublic,
    'activeChallengeId': activeChallengeId,
  };

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ownerId: json['ownerId'] as String,
      members: (json['members'] as List?)
              ?.map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      maxMembers: json['maxMembers'] as int? ?? 10,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      activeChallengeId: json['activeChallengeId'] as String?,
    );
  }
}

/// 小组成员
class GroupMember {
  const GroupMember({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.joinedAt,
    this.role = GroupMemberRole.member,
    this.totalPoints = 0,
  });

  final String userId;
  final String username;
  final String avatar;
  final DateTime joinedAt;
  final GroupMemberRole role;
  final int totalPoints;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'avatar': avatar,
    'joinedAt': joinedAt.toIso8601String(),
    'role': role.name,
    'totalPoints': totalPoints,
  };

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      role: GroupMemberRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => GroupMemberRole.member,
      ),
      totalPoints: json['totalPoints'] as int? ?? 0,
    );
  }
}

enum GroupMemberRole {
  owner,
  admin,
  member,
}

/// 小组挑战
class GroupChallenge {
  const GroupChallenge({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.targetLessons,
    this.completedLessons = 0,
    this.participants = const [],
  });

  final String id;
  final String groupId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int targetLessons;
  final int completedLessons;
  final List<String> participants;

  double get progress => targetLessons == 0 ? 0 : completedLessons / targetLessons;
  bool get isActive => DateTime.now().isBefore(endDate);

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'targetLessons': targetLessons,
    'completedLessons': completedLessons,
    'participants': participants,
  };

  factory GroupChallenge.fromJson(Map<String, dynamic> json) {
    return GroupChallenge(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      targetLessons: json['targetLessons'] as int,
      completedLessons: json['completedLessons'] as int? ?? 0,
      participants: List<String>.from(json['participants'] ?? []),
    );
  }
}
