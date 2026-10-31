import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/models/skill_node.dart';
import 'package:code_learn_app/services/skill_tree_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SkillTreeService();
  final emptySkills = service.buildSkills(const <String>{});
  final emptyById = <String, SkillNode>{
    for (final skill in emptySkills) skill.id: skill,
  };

  SkillNode byId(List<SkillNode> skills, String id) =>
      skills.firstWhere((skill) => skill.id == id);

  test('技能树关联课程都能在 manifest 里找到', () {
    final raw = File('assets/content/manifest.json').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final lessonIds = <String>{};
    for (final category in data['categories'] as List<dynamic>) {
      final lessons = (category as Map<String, dynamic>)['lessons'];
      if (lessons is! List) continue;
      for (final lesson in lessons) {
        lessonIds.add((lesson as Map<String, dynamic>)['id'] as String);
      }
    }

    for (final skill in emptySkills) {
      expect(skill.relatedLessons, isNotEmpty, reason: '${skill.id} 没有关联课程');
      for (final lessonId in skill.relatedLessons) {
        expect(
          lessonIds.contains(lessonId),
          isTrue,
          reason: '技能 ${skill.id} 关联的课程 $lessonId 不在 manifest 中',
        );
      }
      for (final prerequisiteId in skill.prerequisites) {
        expect(
          emptyById.containsKey(prerequisiteId),
          isTrue,
          reason: '技能 ${skill.id} 的前置 $prerequisiteId 不存在',
        );
      }
    }
  });

  test('进度按关联课程的已学比例计算', () {
    final partial = service.buildSkills(const <String>{'html_basics'});
    expect(byId(partial, 'html_css').progress, 33);

    final complete = service.buildSkills(const <String>{
      'html_basics',
      'css_basics',
      'css_layout',
    });
    expect(byId(complete, 'html_css').progress, 100);
    expect(byId(complete, 'html_css').isMastered, isTrue);
  });

  test('前置技能未掌握时锁定，掌握后自动解锁', () {
    expect(byId(emptySkills, 'html_css').isUnlocked(emptyById), isTrue);
    expect(byId(emptySkills, 'javascript').isUnlocked(emptyById), isFalse);

    final partial = service.buildSkills(const <String>{'html_basics'});
    final partialById = <String, SkillNode>{
      for (final skill in partial) skill.id: skill,
    };
    expect(byId(partial, 'javascript').isUnlocked(partialById), isFalse);

    final htmlDone = service.buildSkills(const <String>{
      'html_basics',
      'css_basics',
      'css_layout',
    });
    final htmlDoneById = <String, SkillNode>{
      for (final skill in htmlDone) skill.id: skill,
    };
    expect(byId(htmlDone, 'javascript').isUnlocked(htmlDoneById), isTrue);
    expect(byId(htmlDone, 'react').isUnlocked(htmlDoneById), isFalse);
  });

  test('同名前置链最多两级，不存在循环依赖', () {
    for (final skill in emptySkills) {
      expect(skill.prerequisites, isNot(contains(skill.id)));
    }
    for (final skill in emptySkills) {
      for (final prerequisiteId in skill.prerequisites) {
        final prerequisite = emptyById[prerequisiteId]!;
        expect(
          prerequisite.prerequisites,
          isNot(contains(skill.id)),
          reason: '${skill.id} 与 $prerequisiteId 互相前置',
        );
      }
    }
  });
}
