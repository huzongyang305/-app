import 'package:flutter/material.dart';

import 'daily_challenge_screen.dart';
import 'skill_tree_screen.dart';
import 'mentor_selection_screen.dart';
import 'achievements_screen.dart';

/// 游戏化功能中心页面 - 统一入口
class GamificationHubScreen extends StatelessWidget {
  const GamificationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏化中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
            tooltip: '帮助',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '让学习更有趣！',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '通过挑战、成就和技能追踪，让学习之旅充满乐趣',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // 图标圈 + 标题/副标题行高 + 内边距，随系统字号增长。
                  mainAxisExtent:
                      64 +
                      12 +
                      MediaQuery.textScalerOf(context).scale(24) +
                      4 +
                      MediaQuery.textScalerOf(context).scale(18) +
                      32 +
                      8,
                ),
                children: [
                  _buildCard(
                    context,
                    title: '每日挑战',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    subtitle: '每日编程挑战',
                    badge: 'NEW',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyChallengeScreen(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    title: '技能树',
                    icon: Icons.auto_graph,
                    color: Colors.blue,
                    subtitle: '学习进度追踪',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkillTreeScreen(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    title: '虚拟导师',
                    icon: Icons.psychology,
                    color: Colors.purple,
                    subtitle: '个性化指导',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MentorSelectionScreen(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    title: '成就徽章',
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                    subtitle: '查看已解锁成就',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AchievementsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('游戏化功能说明'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                Icons.local_fire_department,
                Colors.orange,
                '每日挑战',
                '每天一个编程挑战，连续完成可获得额外奖励',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.auto_graph,
                Colors.blue,
                '技能树',
                '可视化展示你的学习进度和技能依赖关系',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.psychology,
                Colors.purple,
                '虚拟导师',
                '选择专属导师，获得个性化学习建议和鼓励',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.emoji_events,
                Colors.amber,
                '成就徽章',
                '完成特定目标解锁徽章，展示你的学习成果',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
