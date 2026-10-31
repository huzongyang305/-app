import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/skill_node.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/skill_tree_service.dart';
import 'lesson_screen.dart';

const Map<String, String> _categoryLabels = <String, String>{
  'frontend': '前端开发',
  'backend': '后端开发',
  'mobile': '移动开发',
  'devops': 'DevOps',
};

/// 技能树：节点进度来自真实已学课程，前置技能掌握后自动解锁。
class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({super.key});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  static const SkillTreeService _service = SkillTreeService();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final skills = _service.buildSkills(progress.learnedIds);
    final byId = <String, SkillNode>{
      for (final skill in skills) skill.id: skill,
    };
    final filtered = _selectedCategory == null
        ? skills
        : skills.where((skill) => skill.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('技能树'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '按方向筛选',
            onSelected: (category) {
              setState(() => _selectedCategory = category);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String?>(value: null, child: Text('全部')),
              for (final entry in _categoryLabels.entries)
                PopupMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressOverview(skills, byId),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '拖动可平移、双指可缩放，点节点查看详情',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(48),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleNodeTap(details.localPosition, filtered, byId),
                child: CustomPaint(
                  size: const Size(1740, 760),
                  painter: SkillTreePainter(
                    skills: filtered,
                    byId: byId,
                    colorScheme: Theme.of(context).colorScheme,
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(
    List<SkillNode> skills,
    Map<String, SkillNode> byId,
  ) {
    final total = skills.length;
    final mastered = skills.where((skill) => skill.isMastered).length;
    final inProgress = skills
        .where((skill) => skill.progress > 0 && !skill.isMastered)
        .length;
    final locked = skills.where((skill) => !skill.isUnlocked(byId)).length;
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '总体进度',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? mastered / total : 0,
                  backgroundColor: foreground.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mastered / $total 已掌握',
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatCard('进行中', '$inProgress', Icons.play_circle),
          const SizedBox(width: 8),
          _buildStatCard('已锁定', '$locked', Icons.lock_outline),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.85),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNodeTap(
    Offset point,
    List<SkillNode> skills,
    Map<String, SkillNode> byId,
  ) {
    for (final skill in skills.reversed) {
      if (skill.bounds.contains(point)) {
        _showSkillDetail(skill, byId);
        return;
      }
    }
  }

  void _showSkillDetail(SkillNode skill, Map<String, SkillNode> byId) {
    final progress = context.read<ProgressProvider>();
    final content = context.read<ContentProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SkillDetailSheet(
          skill: skill,
          allSkills: byId,
          learnedIds: progress.learnedIds,
          content: content,
          scrollController: scrollController,
          onOpenLesson: (lessonId) {
            Navigator.of(sheetContext).pop();
            _openLesson(lessonId);
          },
        ),
      ),
    );
  }

  Future<void> _openLesson(String lessonId) async {
    final content = context.read<ContentProvider>();
    final lesson = content.lessonById(lessonId);
    if (!mounted) return;
    if (lesson == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('课程 $lessonId 暂不可用，请先更新内容包')));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
    );
  }
}

class SkillTreePainter extends CustomPainter {
  SkillTreePainter({
    required this.skills,
    required this.byId,
    required this.colorScheme,
    required this.textScaler,
  });

  final List<SkillNode> skills;
  final Map<String, SkillNode> byId;
  final ColorScheme colorScheme;
  final TextScaler textScaler;

  static const Color _masteredColor = Color(0xFF2E7D32);
  static const Color _progressColor = Color(0xFFEF6C00);

  @override
  void paint(Canvas canvas, Size size) {
    final visible = <String>{for (final skill in skills) skill.id};
    for (final skill in skills) {
      for (final prereqId in skill.prerequisites) {
        final from = byId[prereqId];
        if (from != null && visible.contains(prereqId)) {
          _drawConnection(canvas, from, skill);
        }
      }
    }
    _drawCategoryHeaders(canvas);
    for (final skill in skills) {
      _drawSkillNode(canvas, skill);
    }
  }

  void _drawCategoryHeaders(Canvas canvas) {
    for (var index = 0; index < SkillNode.categoryOrder.length; index++) {
      final category = SkillNode.categoryOrder[index];
      if (!skills.any((skill) => skill.category == category)) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: _categoryLabels[category] ?? category,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textScaler: textScaler,
      )..layout(maxWidth: 168);
      painter.paint(canvas, Offset(180 + index * 430 - 84, 96));
    }
  }

  void _drawConnection(Canvas canvas, SkillNode from, SkillNode to) {
    final unlocked = from.isMastered;
    final paint = Paint()
      ..color = unlocked
          ? _masteredColor.withValues(alpha: 0.55)
          : colorScheme.outlineVariant.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final start = from.position + Offset(0, SkillNode.nodeSize.height / 2);
    final end = to.position - Offset(0, SkillNode.nodeSize.height / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx,
        (start.dy + end.dy) / 2,
        end.dx,
        (start.dy + end.dy) / 2,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
  }

  void _drawSkillNode(Canvas canvas, SkillNode skill) {
    final unlocked = skill.isUnlocked(byId);
    final mastered = skill.isMastered;
    final Color fill;
    if (!unlocked) {
      fill = colorScheme.surfaceContainerHighest;
    } else if (mastered) {
      fill = _masteredColor;
    } else if (skill.progress > 0) {
      fill = _progressColor;
    } else {
      fill = colorScheme.primary;
    }
    final foreground = unlocked ? Colors.white : colorScheme.onSurfaceVariant;
    final rect = skill.bounds;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: 0.18),
      unlocked ? 6 : 2,
      false,
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    if (!unlocked) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = colorScheme.outlineVariant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    _drawIcon(
      canvas,
      unlocked ? skill.icon : Icons.lock,
      Offset(rect.left + 14, rect.top + 12),
      22,
      foreground,
    );

    final title = TextPainter(
      text: TextSpan(
        text: skill.title,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
      textScaler: textScaler,
    )..layout(maxWidth: rect.width - 28);
    title.paint(
      canvas,
      Offset(rect.center.dx - title.width / 2, rect.top + 32),
    );

    final barRect = Rect.fromLTWH(
      rect.left + 14,
      rect.bottom - 30,
      rect.width - 28,
      5,
    );
    final trackColor = unlocked
        ? Colors.white.withValues(alpha: 0.28)
        : colorScheme.onSurface.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
      Paint()..color = trackColor,
    );
    if (skill.progress > 0) {
      final valueRect = Rect.fromLTWH(
        barRect.left,
        barRect.top,
        barRect.width * skill.progress / 100,
        barRect.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(valueRect, const Radius.circular(3)),
        Paint()..color = unlocked ? Colors.white : colorScheme.primary,
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: unlocked ? '${skill.progress}%' : '待解锁 · ${skill.progress}%',
        style: TextStyle(
          color: foreground.withValues(alpha: 0.92),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      textScaler: textScaler,
    )..layout(maxWidth: rect.width - 28);
    label.paint(
      canvas,
      Offset(rect.center.dx - label.width / 2, rect.bottom - 20),
    );
  }

  void _drawIcon(
    Canvas canvas,
    IconData icon,
    Offset offset,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant SkillTreePainter oldDelegate) =>
      oldDelegate.skills != skills ||
      oldDelegate.byId != byId ||
      oldDelegate.colorScheme != colorScheme;
}

class SkillDetailSheet extends StatelessWidget {
  const SkillDetailSheet({
    super.key,
    required this.skill,
    required this.allSkills,
    required this.learnedIds,
    required this.content,
    required this.scrollController,
    required this.onOpenLesson,
  });

  final SkillNode skill;
  final Map<String, SkillNode> allSkills;
  final Set<String> learnedIds;
  final ContentProvider content;
  final ScrollController scrollController;
  final ValueChanged<String> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = skill.isUnlocked(allSkills);
    final prerequisites = <SkillNode>[
      for (final id in skill.prerequisites)
        if (allSkills[id] != null) allSkills[id]!,
    ];
    final learnedCount = skill.relatedLessons.where(learnedIds.contains).length;
    final nextLessonId = _nextLessonId();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Row(
          children: [
            Icon(
              skill.isMastered ? Icons.verified : skill.icon,
              size: 48,
              color: skill.isMastered
                  ? const Color(0xFF2E7D32)
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _categoryLabels[skill.category] ?? skill.category,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (skill.isMastered)
              Chip(
                label: const Text('已掌握'),
                backgroundColor: const Color(0xFF2E7D32)
                    .withValues(alpha: 0.12),
                labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                side: BorderSide.none,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(skill.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        Text(
          '学习进度',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: skill.progress / 100),
        const SizedBox(height: 4),
        Text(
          '${skill.progress}% · $learnedCount/${skill.relatedLessons.length} 门课已学',
        ),
        if (prerequisites.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '前置技能',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prerequisite in prerequisites)
                Chip(
                  avatar: Icon(
                    prerequisite.isMastered
                        ? Icons.check_circle
                        : Icons.lock_outline,
                    size: 18,
                    color: prerequisite.isMastered
                        ? const Color(0xFF2E7D32)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    '${prerequisite.title} · ${prerequisite.progress}%',
                  ),
                ),
            ],
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            Text(
              '掌握全部前置技能后自动解锁。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        Text(
          '关联课程',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        for (final lessonId in skill.relatedLessons)
          _buildLessonTile(context, lessonId, unlocked),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: unlocked && nextLessonId != null
              ? () => onOpenLesson(nextLessonId)
              : null,
          icon: Icon(
            skill.isMastered ? Icons.replay : Icons.play_arrow_rounded,
          ),
          label: Text(
            !unlocked
                ? '请先完成前置技能'
                : skill.isMastered
                ? '再学一遍'
                : skill.progress > 0
                ? '继续学习'
                : '开始学习',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  String? _nextLessonId() {
    for (final id in skill.relatedLessons) {
      if (!learnedIds.contains(id)) return id;
    }
    return skill.relatedLessons.isEmpty ? null : skill.relatedLessons.first;
  }

  Widget _buildLessonTile(
    BuildContext context,
    String lessonId,
    bool unlocked,
  ) {
    final lesson = content.lessonById(lessonId);
    final learned = learnedIds.contains(lessonId);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: unlocked,
      leading: Icon(
        learned
            ? Icons.check_circle
            : unlocked
            ? Icons.play_circle_outline
            : Icons.lock_outline,
        color: learned
            ? const Color(0xFF2E7D32)
            : unlocked
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(lesson?.title.zh ?? lessonId),
      subtitle: Text(
        learned
            ? '已学'
            : unlocked
            ? '未学'
            : '解锁后可学习',
      ),
      trailing: unlocked ? const Icon(Icons.chevron_right) : null,
      onTap: unlocked && lesson != null ? () => onOpenLesson(lessonId) : null,
    );
  }
}
