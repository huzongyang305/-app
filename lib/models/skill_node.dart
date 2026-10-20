import 'package:flutter/material.dart';

class SkillNode {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final int progress; // 0-100
  final List<String> prerequisites;
  final List<String> relatedLessons;
  final DifficultyLevel difficulty;
  final DateTime? unlockedAt;
  
  SkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.progress,
    required this.prerequisites,
    required this.relatedLessons,
    required this.difficulty,
    this.unlockedAt,
  });

  bool get isMastered => progress >= 100;
  bool get isLocked => prerequisites.isNotEmpty && !prerequisites.every(_isPrerequisiteMet);
  
  bool _isPrerequisiteMet(String prereqId) {
    // TODO: 从用户进度中检查前置技能是否完成
    return false;
  }

  Offset get position {
    // 根据类别和难度计算在技能树中的位置
    final categoryIndex = ['frontend', 'backend', 'mobile', 'devops'].indexOf(category);
    final difficultyValue = difficulty.index;
    
    return Offset(
      200 + categoryIndex * 400,
      200 + difficultyValue * 150,
    );
  }

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      progress: json['progress'] as int,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      relatedLessons: List<String>.from(json['relatedLessons'] ?? []),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon.codePoint,
      'progress': progress,
      'prerequisites': prerequisites,
      'relatedLessons': relatedLessons,
      'difficulty': difficulty.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
}
