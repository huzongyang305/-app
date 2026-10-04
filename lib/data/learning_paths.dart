import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/content_provider.dart';

/// 学习路径：把分散的知识点按目标串成有序路线。
///
/// 路径由「分组名」和「指定知识点 ID」两部分组成：
/// 分组名用于成组引入（如整组 Python），ID 用于跨分类补充工程实践内容。
class LearningPath {
  const LearningPath({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    this.groups = const <String>[],
    this.categoryIds = const <String>[],
    this.lessonIds = const <String>[],
  });

  final String id;

  /// 标题与副标题只存 l10n key，渲染时按当前语言取词。
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final List<String> groups;

  /// 按整门课程引入（编程语言已拆成独立课程，用课程 ID 更直接）。
  final List<String> categoryIds;
  final List<String> lessonIds;
}

const List<LearningPath> learningPaths = <LearningPath>[
  LearningPath(
    id: 'python',
    titleKey: 'pathPython',
    subtitleKey: 'pathPythonSub',
    icon: Icons.terminal,
    categoryIds: <String>['python'],
  ),
  LearningPath(
    id: 'java-backend',
    titleKey: 'pathJavaBackend',
    subtitleKey: 'pathJavaBackendSub',
    icon: Icons.dns,
    categoryIds: <String>['java'],
    lessonIds: <String>[
      'sql_basics',
      'index',
      'transaction',
      'db_query_optimization',
      'redis',
      'http_basics',
      'tcp_ip',
      'git_basics',
      'docker',
      'ci_cd',
      'gateway',
      'observability',
      'project_requirements_design',
      'project_testing_quality',
      'project_deploy_ops',
      'java_project',
    ],
  ),
  LearningPath(
    id: 'javascript-frontend',
    titleKey: 'pathJsFrontend',
    subtitleKey: 'pathJsFrontendSub',
    icon: Icons.web,
    categoryIds: <String>['javascript', 'typescript'],
    lessonIds: <String>[
      'http_basics',
      'http2_http3',
      'git_basics',
      'ci_cd',
      'project_requirements_design',
      'project_testing_quality',
      'project_deploy_ops',
    ],
  ),
  LearningPath(
    id: 'language-tour',
    titleKey: 'pathLanguageTour',
    subtitleKey: 'pathLanguageTourSub',
    icon: Icons.translate,
    categoryIds: <String>['cross_language', 'visual_guide', 'project_practice'],
  ),
  LearningPath(
    id: 'ai-engineer',
    titleKey: 'pathAiEngineer',
    subtitleKey: 'pathAiEngineerSub',
    icon: Icons.psychology,
    lessonIds: <String>[
      'ai_basics',
      'ml_fundamentals',
      'ai_deep_learning_llm',
      'ai_prompt_engineering',
      'ai_embeddings_rag',
      'ai_agent_basics',
      'ai_multi_agent',
      'ai_engineering',
      'ai_fine_tuning_deployment',
      'ai_multimodal',
      'ai_coding_assistant',
      'ai_agent_evaluation',
      'ai_realtime_voice',
      'multimodal_rag',
      'agent_cost_performance',
      'model_evaluation',
      'agent_memory',
      'ai_training',
      'ai_data_engineering',
    ],
  ),
  LearningPath(
    id: 'interview-algorithms',
    titleKey: 'pathInterviewAlgo',
    subtitleKey: 'pathInterviewAlgoSub',
    icon: Icons.account_tree,
    lessonIds: <String>[
      'time_complexity',
      'binary_search',
      'sorting',
      'bubble_sort',
      'hash_table',
      'stack_queue',
      'linked_list',
      'tree_bst',
      'graph',
      'dynamic_programming',
      'two_pointers',
      'backtracking',
      'greedy',
      'bit_manipulation',
      'prefix_sum',
      'union_find',
      'trie',
      'segment_tree',
      'monotonic_stack',
      'binary_answer',
      'string_matching',
      'algorithm_intro',
      'algorithms_project',
    ],
  ),
  LearningPath(
    id: 'c-language',
    titleKey: 'pathCLanguage',
    subtitleKey: 'pathCLanguageSub',
    icon: Icons.memory,
    categoryIds: <String>['c'],
  ),
  LearningPath(
    id: 'cpp-engineer',
    titleKey: 'pathCppEngineer',
    subtitleKey: 'pathCppEngineerSub',
    icon: Icons.developer_board,
    categoryIds: <String>['cpp'],
  ),
  LearningPath(
    id: 'csharp-dotnet',
    titleKey: 'pathCsharpDotnet',
    subtitleKey: 'pathCsharpDotnetSub',
    icon: Icons.window,
    categoryIds: <String>['csharp'],
  ),
  LearningPath(
    id: 'go-backend',
    titleKey: 'pathGoBackend',
    subtitleKey: 'pathGoBackendSub',
    icon: Icons.dns,
    categoryIds: <String>['go'],
  ),
  LearningPath(
    id: 'rust-systems',
    titleKey: 'pathRustSystems',
    subtitleKey: 'pathRustSystemsSub',
    icon: Icons.settings_suggest,
    categoryIds: <String>['rust'],
  ),
  LearningPath(
    id: 'mobile-engineer',
    titleKey: 'pathMobileEngineer',
    subtitleKey: 'pathMobileEngineerSub',
    icon: Icons.phone_android,
    categoryIds: <String>['flutter', 'kotlin', 'swift'],
  ),
  LearningPath(
    id: 'security-engineer',
    titleKey: 'pathSecurityEngineer',
    subtitleKey: 'pathSecurityEngineerSub',
    icon: Icons.security,
    categoryIds: <String>['security'],
  ),
  LearningPath(
    id: 'data-engineer',
    titleKey: 'pathDataEngineer',
    subtitleKey: 'pathDataEngineerSub',
    icon: Icons.storage,
    categoryIds: <String>['database', 'distributed'],
    lessonIds: <String>[
      'realtime_warehouse',
      'bigdata_batch_stream',
      'data_lakehouse',
      'olap_columnar',
      'database_project',
    ],
  ),
  LearningPath(
    id: 'cs-fundamentals',
    titleKey: 'pathCsFundamentals',
    subtitleKey: 'pathCsFundamentalsSub',
    icon: Icons.account_tree,
    categoryIds: <String>['fundamentals', 'os', 'network', 'algorithms'],
  ),
  LearningPath(
    id: 'devops-platform',
    titleKey: 'pathDevopsPlatform',
    subtitleKey: 'pathDevopsPlatformSub',
    icon: Icons.cloud,
    categoryIds: <String>['toolchain', 'distributed'],
  ),
];

/// 解析路径包含的知识点：先按分组（保持内容顺序），再按显式 ID 顺序补充。
List<Lesson> resolvePathLessons(ContentProvider content, LearningPath path) {
  final byId = <String, Lesson>{
    for (final lesson in content.allLessons) lesson.id: lesson,
  };
  final result = <Lesson>[];
  final seen = <String>{};

  if (path.categoryIds.isNotEmpty) {
    for (final category in content.categories) {
      if (!path.categoryIds.contains(category.id)) continue;
      final ordered = <Lesson>[...category.lessons]
        ..sort((a, b) => a.order.compareTo(b.order));
      for (final lesson in ordered) {
        if (seen.add(lesson.id)) result.add(lesson);
      }
    }
  }
  if (path.groups.isNotEmpty) {
    for (final lesson in content.allLessons) {
      final group = lesson.group;
      if (group != null && path.groups.contains(group) && seen.add(lesson.id)) {
        result.add(lesson);
      }
    }
  }
  for (final id in path.lessonIds) {
    final lesson = byId[id];
    if (lesson != null && seen.add(id)) result.add(lesson);
  }
  return result;
}
