class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final int maxScore;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCompleted;
  final int? userScore;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.tags,
    required this.maxScore,
    required this.createdAt,
    required this.expiresAt,
    this.isCompleted = false,
    this.userScore,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.coding,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      maxScore: json['maxScore'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      userScore: json['userScore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'tags': tags,
      'maxScore': maxScore,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isCompleted': isCompleted,
      'userScore': userScore,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get timeRemaining => expiresAt.difference(DateTime.now()).inHours;
}

enum ChallengeType {
  coding,
  quiz,
  debugging,
  optimization,
  design,
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
}
