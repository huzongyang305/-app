import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill_node.dart';

class SkillTreeService {
  static const String _skillsKey = 'user_skills';

  Future<List<SkillNode>> getAllSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final skillsJson = prefs.getString(_skillsKey);
    
    if (skillsJson != null) {
      final List<dynamic> skillsList = jsonDecode(skillsJson);
      return skillsList.map((json) => SkillNode.fromJson(json)).toList();
    }

    // 如果没有数据，返回默认技能树
    return _getDefaultSkills();
  }

  Future<void> updateSkillProgress(String skillId, int progress) async {
    final prefs = await SharedPreferences.getInstance();
    final skills = await getAllSkills();
    
    final updatedSkills = skills.map((skill) {
      if (skill.id == skillId) {
        return SkillNode(
          id: skill.id,
          title: skill.title,
          description: skill.description,
          category: skill.category,
          icon: skill.icon,
          progress: progress,
          prerequisites: skill.prerequisites,
          relatedLessons: skill.relatedLessons,
          difficulty: skill.difficulty,
          unlockedAt: skill.unlockedAt ?? DateTime.now(),
        );
      }
      return skill;
    }).toList();

    await prefs.setString(_skillsKey, jsonEncode(updatedSkills.map((s) => s.toJson()).toList()));
  }

  List<SkillNode> _getDefaultSkills() {
    return [
      // 前端开发
      SkillNode(
        id: 'html_css',
        title: 'HTML/CSS',
        description: '网页结构和样式的基础',
        category: 'frontend',
        icon: Icons.web,
        progress: 0,
        prerequisites: [],
        relatedLessons: ['web_basics', 'css_advanced'],
        difficulty: DifficultyLevel.easy,
      ),
      SkillNode(
        id: 'javascript',
        title: 'JavaScript',
        description: '交互式网页编程',
        category: 'frontend',
        icon: Icons.javascript,
        progress: 0,
        prerequisites: ['html_css'],
        relatedLessons: ['js_fundamentals', 'es6_features'],
        difficulty: DifficultyLevel.medium,
      ),
      SkillNode(
        id: 'react',
        title: 'React',
        description: '现代化的UI库',
        category: 'frontend',
        icon: Icons.code,
        progress: 0,
        prerequisites: ['javascript'],
        relatedLessons: ['react_hooks', 'react_router'],
        difficulty: DifficultyLevel.medium,
      ),
      
      // 后端开发
      SkillNode(
        id: 'java_basics',
        title: 'Java 基础',
        description: '面向对象编程语言',
        category: 'backend',
        icon: Icons.coffee,
        progress: 0,
        prerequisites: [],
        relatedLessons: ['java_syntax', 'oop_concepts'],
        difficulty: DifficultyLevel.easy,
      ),
      SkillNode(
        id: 'spring_boot',
        title: 'Spring Boot',
        description: 'Java Web应用框架',
        category: 'backend',
        icon: Icons.cloud,
        progress: 0,
        prerequisites: ['java_basics'],
        relatedLessons: ['spring_core', 'rest_api'],
        difficulty: DifficultyLevel.hard,
      ),
      
      // 移动开发
      SkillNode(
        id: 'dart',
        title: 'Dart',
        description: 'Flutter的编程语言',
        category: 'mobile',
        icon: Icons.phone_android,
        progress: 0,
        prerequisites: [],
        relatedLessons: ['dart_basics', 'async_programming'],
        difficulty: DifficultyLevel.easy,
      ),
      SkillNode(
        id: 'flutter',
        title: 'Flutter',
        description: '跨平台移动应用开发',
        category: 'mobile',
        icon: Icons.flutter_dash,
        progress: 0,
        prerequisites: ['dart'],
        relatedLessons: ['flutter_widgets', 'state_management'],
        difficulty: DifficultyLevel.medium,
      ),
      
      // DevOps
      SkillNode(
        id: 'git',
        title: 'Git',
        description: '版本控制系统',
        category: 'devops',
        icon: Icons.source,
        progress: 0,
        prerequisites: [],
        relatedLessons: ['git_basics', 'branching_strategy'],
        difficulty: DifficultyLevel.easy,
      ),
      SkillNode(
        id: 'docker',
        title: 'Docker',
        description: '容器化技术',
        category: 'devops',
        icon: Icons.cloud,
        progress: 0,
        prerequisites: ['git'],
        relatedLessons: ['docker_basics', 'docker_compose'],
        difficulty: DifficultyLevel.medium,
      ),
    ];
  }
}
