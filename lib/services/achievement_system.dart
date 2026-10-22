import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final RarityLevel rarity;
  final IconData icon;
  final int points;
  final DateTime? unlockedAt;
  final Map<String, dynamic> criteria;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    required this.points,
    this.unlockedAt,
    required this.criteria,
  });

  bool get isUnlocked => unlockedAt != null;

  Color get rarityColor {
    switch (rarity) {
      case RarityLevel.common:
        return Colors.grey;
      case RarityLevel.uncommon:
        return Colors.green;
      case RarityLevel.rare:
        return Colors.blue;
      case RarityLevel.epic:
        return Colors.purple;
      case RarityLevel.legendary:
        return Colors.orange;
    }
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.learning,
      ),
      rarity: RarityLevel.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => RarityLevel.common,
      ),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      points: json['points'] as int,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String) 
          : null,
      criteria: json['criteria'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'rarity': rarity.name,
      'icon': icon.codePoint,
      'points': points,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'criteria': criteria,
    };
  }
}

enum AchievementCategory {
  learning,       // 学习相关
  practice,       // 练习相关
  social,         // 社交相关
  streak,         // 连续学习
  mastery,        // 精通掌握
  contribution,   // 贡献相关
  speed,          // 速度挑战
  exploration,    // 探索发现
}

enum RarityLevel {
  common,     // 普通 - 灰色
  uncommon,   // 少见 - 绿色
  rare,       // 稀有 - 蓝色
  epic,       // 史诗 - 紫色
  legendary,  // 传说 - 橙色
}

class AchievementService {
  static List<Achievement> getAllAchievements() {
    return [
      // 学习类徽章
      Achievement(
        id: 'first_lesson',
        title: '初学者',
        description: '完成第一门课程',
        category: AchievementCategory.learning,
        rarity: RarityLevel.common,
        icon: Icons.school,
        points: 10,
        criteria: {'type': 'lesson_completed', 'count': 1},
      ),
      Achievement(
        id: 'lesson_master',
        title: '学习达人',
        description: '完成50门课程',
        category: AchievementCategory.learning,
        rarity: RarityLevel.epic,
        icon: Icons.school,
        points: 500,
        criteria: {'type': 'lesson_completed', 'count': 50},
      ),
      
      // 连续学习类徽章
      Achievement(
        id: 'streak_7',
        title: '坚持不懈',
        description: '连续学习7天',
        category: AchievementCategory.streak,
        rarity: RarityLevel.uncommon,
        icon: Icons.local_fire_department,
        points: 70,
        criteria: {'type': 'daily_streak', 'days': 7},
      ),
      Achievement(
        id: 'streak_30',
        title: '月度战士',
        description: '连续学习30天',
        category: AchievementCategory.streak,
        rarity: RarityLevel.rare,
        icon: Icons.whatshot,
        points: 300,
        criteria: {'type': 'daily_streak', 'days': 30},
      ),
      Achievement(
        id: 'streak_100',
        title: '百日传奇',
        description: '连续学习100天',
        category: AchievementCategory.streak,
        rarity: RarityLevel.legendary,
        icon: Icons.emoji_events,
        points: 1000,
        criteria: {'type': 'daily_streak', 'days': 100},
      ),
      
      // 练习类徽章
      Achievement(
        id: 'quiz_expert',
        title: '测验专家',
        description: '完成100次测验',
        category: AchievementCategory.practice,
        rarity: RarityLevel.rare,
        icon: Icons.quiz,
        points: 200,
        criteria: {'type': 'quiz_completed', 'count': 100},
      ),
      Achievement(
        id: 'perfect_score',
        title: '完美主义者',
        description: '获得10次满分',
        category: AchievementCategory.practice,
        rarity: RarityLevel.epic,
        icon: Icons.star,
        points: 400,
        criteria: {'type': 'perfect_scores', 'count': 10},
      ),
      
      // 代码练习类徽章
      Achievement(
        id: 'code_warrior',
        title: '代码战士',
        description: '编写1000行代码',
        category: AchievementCategory.practice,
        rarity: RarityLevel.rare,
        icon: Icons.code,
        points: 250,
        criteria: {'type': 'code_lines', 'count': 1000},
      ),
      Achievement(
        id: 'debug_master',
        title: '调试大师',
        description: '修复50个bug',
        category: AchievementCategory.practice,
        rarity: RarityLevel.uncommon,
        icon: Icons.bug_report,
        points: 150,
        criteria: {'type': 'bugs_fixed', 'count': 50},
      ),
      
      // 社交类徽章
      Achievement(
        id: 'helper',
        title: '热心助人',
        description: '帮助10位学习者',
        category: AchievementCategory.social,
        rarity: RarityLevel.uncommon,
        icon: Icons.help,
        points: 100,
        criteria: {'type': 'helped_users', 'count': 10},
      ),
      Achievement(
        id: 'community_leader',
        title: '社区领袖',
        description: '获得100个赞',
        category: AchievementCategory.social,
        rarity: RarityLevel.epic,
        icon: Icons.thumb_up,
        points: 500,
        criteria: {'type': 'likes_received', 'count': 100},
      ),
      
      // 精通类徽章
      Achievement(
        id: 'flutter_master',
        title: 'Flutter大师',
        description: '完成所有Flutter课程',
        category: AchievementCategory.mastery,
        rarity: RarityLevel.legendary,
        icon: Icons.flutter_dash,
        points: 1000,
        criteria: {'type': 'category_completed', 'category': 'flutter'},
      ),
      Achievement(
        id: 'java_expert',
        title: 'Java专家',
        description: '完成所有Java课程',
        category: AchievementCategory.mastery,
        rarity: RarityLevel.legendary,
        icon: Icons.coffee,
        points: 1000,
        criteria: {'type': 'category_completed', 'category': 'java'},
      ),
      
      // 速度挑战类徽章
      Achievement(
        id: 'speed_learner',
        title: '速学者',
        description: '一天内完成5门课程',
        category: AchievementCategory.speed,
        rarity: RarityLevel.rare,
        icon: Icons.flash_on,
        points: 300,
        criteria: {'type': 'lessons_in_day', 'count': 5},
      ),
      
      // 探索类徽章
      Achievement(
        id: 'explorer',
        title: '探索者',
        description: '访问所有分类的课程',
        category: AchievementCategory.exploration,
        rarity: RarityLevel.uncommon,
        icon: Icons.explore,
        points: 150,
        criteria: {'type': 'categories_visited', 'count': 10},
      ),
      Achievement(
        id: 'polymath',
        title: '博学家',
        description: '学习超过5个不同领域的知识',
        category: AchievementCategory.exploration,
        rarity: RarityLevel.epic,
        icon: Icons.auto_stories,
        points: 600,
        criteria: {'type': 'categories_learned', 'count': 5},
      ),
    ];
  }

  static List<Achievement> checkAndUnlockAchievements(
    List<Achievement> achievements,
    Map<String, dynamic> userStats,
  ) {
    return achievements.map((achievement) {
      if (achievement.isUnlocked) return achievement;
      
      if (_checkCriteria(achievement.criteria, userStats)) {
        return Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          category: achievement.category,
          rarity: achievement.rarity,
          icon: achievement.icon,
          points: achievement.points,
          unlockedAt: DateTime.now(),
          criteria: achievement.criteria,
        );
      }
      
      return achievement;
    }).toList();
  }

  static bool _checkCriteria(
    Map<String, dynamic> criteria,
    Map<String, dynamic> userStats,
  ) {
    final type = criteria['type'] as String;
    
    switch (type) {
      case 'lesson_completed':
        final required = criteria['count'] as int;
        final completed = userStats['lessonsCompleted'] as int? ?? 0;
        return completed >= required;
        
      case 'daily_streak':
        final requiredDays = criteria['days'] as int;
        final currentStreak = userStats['currentStreak'] as int? ?? 0;
        return currentStreak >= requiredDays;
        
      case 'quiz_completed':
        final required = criteria['count'] as int;
        final completed = userStats['quizzesCompleted'] as int? ?? 0;
        return completed >= required;
        
      case 'perfect_scores':
        final required = criteria['count'] as int;
        final perfectCount = userStats['perfectScores'] as int? ?? 0;
        return perfectCount >= required;
        
      case 'code_lines':
        final required = criteria['count'] as int;
        final lines = userStats['codeLinesWritten'] as int? ?? 0;
        return lines >= required;
        
      default:
        return false;
    }
  }
}
