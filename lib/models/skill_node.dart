import 'package:flutter/material.dart';

/// 技能树节点。
///
/// 进度不再单独持久化，而是由 [SkillTreeService] 根据已学课程实时计算，
/// 避免技能树、课程列表和复习计划出现三套互相矛盾的进度。
class SkillNode {
  const SkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.prerequisites,
    required this.relatedLessons,
    required this.difficulty,
    required this.order,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final List<String> prerequisites;
  final List<String> relatedLessons;
  final DifficultyLevel difficulty;

  /// 同分类内的纵向序号，保证同难度节点不会叠在一起。
  final int order;

  /// 0–100，由关联课程的已学比例计算。
  final int progress;

  /// 节点尺寸与列顺序：绘制和点击命中共用同一份常量。
  static const Size nodeSize = Size(168, 100);
  static const List<String> categoryOrder = <String>[
    'frontend',
    'backend',
    'mobile',
    'devops',
  ];

  bool get isMastered => progress >= 100;

  /// 前置技能全部掌握后解锁；没有前置技能时直接解锁。
  bool isUnlocked(Map<String, SkillNode> byId) =>
      prerequisites.every((id) => byId[id]?.isMastered ?? false);

  SkillNode copyWith({int? progress}) => SkillNode(
    id: id,
    title: title,
    description: description,
    category: category,
    icon: icon,
    prerequisites: prerequisites,
    relatedLessons: relatedLessons,
    difficulty: difficulty,
    order: order,
    progress: progress ?? this.progress,
  );

  Offset get position {
    final index = categoryOrder.indexOf(category);
    return Offset(180 + (index < 0 ? 0 : index) * 430, 160 + order * 180);
  }

  Rect get bounds => Rect.fromCenter(
    center: position,
    width: nodeSize.width,
    height: nodeSize.height,
  );
}

enum DifficultyLevel { easy, medium, hard, expert }
