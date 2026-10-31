import 'package:flutter/material.dart';

import '../models/skill_node.dart';

/// 技能树目录与进度计算。
///
/// 每个技能都绑定 manifest 里真实存在的课程：已学完关联课程即视为掌握，
/// 进度直接取「已学课程数 / 关联课程数」，不额外维护一份技能进度。
class SkillTreeService {
  const SkillTreeService();

  /// 用已学课程集合生成带进度的技能树。
  List<SkillNode> buildSkills(Set<String> learnedIds) => _catalog
      .map((skill) => skill.copyWith(progress: _progressOf(skill, learnedIds)))
      .toList(growable: false);

  int _progressOf(SkillNode skill, Set<String> learnedIds) {
    if (skill.relatedLessons.isEmpty) return 0;
    final done = skill.relatedLessons.where(learnedIds.contains).length;
    return (done / skill.relatedLessons.length * 100).round();
  }

  /// 课程 ID 必须与 assets/content/manifest.json 保持一致；
  /// test/skill_tree_test.dart 会校验，改名时不会静默失效。
  static const List<SkillNode> _catalog = <SkillNode>[
    // 前端开发
    SkillNode(
      id: 'html_css',
      title: 'HTML / CSS',
      description: '网页结构与样式基础：先能写出语义化、可响应的页面。',
      category: 'frontend',
      icon: Icons.web,
      order: 0,
      prerequisites: <String>[],
      relatedLessons: <String>['html_basics', 'css_basics', 'css_layout'],
      difficulty: DifficultyLevel.easy,
    ),
    SkillNode(
      id: 'javascript',
      title: 'JavaScript',
      description: '浏览器里的编程语言：类型、函数、异步与 DOM 操作。',
      category: 'frontend',
      icon: Icons.javascript,
      order: 1,
      prerequisites: <String>['html_css'],
      relatedLessons: <String>['js_basics', 'js_functions', 'js_async'],
      difficulty: DifficultyLevel.medium,
    ),
    SkillNode(
      id: 'react',
      title: 'React',
      description: '组件化 UI 与状态管理，能把页面拆成可复用的组件。',
      category: 'frontend',
      icon: Icons.code,
      order: 2,
      prerequisites: <String>['javascript'],
      relatedLessons: <String>[
        'frontend_react_hooks',
        'frontend_state_management',
      ],
      difficulty: DifficultyLevel.medium,
    ),

    // 后端开发
    SkillNode(
      id: 'java_basics',
      title: 'Java 基础',
      description: '面向对象、集合与异常处理，打好后端语言基础。',
      category: 'backend',
      icon: Icons.coffee,
      order: 0,
      prerequisites: <String>[],
      relatedLessons: <String>['java_first_class', 'java_basics', 'java_oop'],
      difficulty: DifficultyLevel.easy,
    ),
    SkillNode(
      id: 'spring_boot',
      title: 'Spring Boot',
      description: '用 Spring 生态搭 REST 服务：核心容器、MVC 与接口设计。',
      category: 'backend',
      icon: Icons.cloud,
      order: 1,
      prerequisites: <String>['java_basics'],
      relatedLessons: <String>[
        'java_spring_boot_intro',
        'java_spring_core',
        'java_restful_api',
      ],
      difficulty: DifficultyLevel.hard,
    ),

    // 移动开发
    SkillNode(
      id: 'flutter',
      title: 'Flutter',
      description: 'Widget、布局与状态管理，做一个能跑的跨平台 App。',
      category: 'mobile',
      icon: Icons.flutter_dash,
      order: 0,
      prerequisites: <String>[],
      relatedLessons: <String>[
        'flutter_widget_intro',
        'flutter_basics',
        'flutter_state',
      ],
      difficulty: DifficultyLevel.easy,
    ),
    SkillNode(
      id: 'android_release',
      title: 'Android 发布',
      description: '签名、包体优化与上架轨道，把作品真正交到用户手里。',
      category: 'mobile',
      icon: Icons.phone_android,
      order: 1,
      prerequisites: <String>['flutter'],
      relatedLessons: <String>['flutter_release', 'android_flutter_release'],
      difficulty: DifficultyLevel.medium,
    ),

    // DevOps
    SkillNode(
      id: 'git',
      title: 'Git',
      description: '版本控制与分支协作，能安全地提交、回退和合并代码。',
      category: 'devops',
      icon: Icons.source,
      order: 0,
      prerequisites: <String>[],
      relatedLessons: <String>['git_intro', 'git_basics'],
      difficulty: DifficultyLevel.easy,
    ),
    SkillNode(
      id: 'docker',
      title: 'Docker',
      description: '把应用和依赖装进镜像，跑通构建、分发与部署。',
      category: 'devops',
      icon: Icons.inventory_2,
      order: 1,
      prerequisites: <String>['git'],
      relatedLessons: <String>['docker', 'devops_docker_registry'],
      difficulty: DifficultyLevel.medium,
    ),
  ];
}
