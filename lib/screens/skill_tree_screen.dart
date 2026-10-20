import 'package:flutter/material.dart';
import '../models/skill_node.dart';
import '../services/skill_tree_service.dart';
import '../widgets/skill_node_widget.dart';

class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({Key? key}) : super(key: key);

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  final SkillTreeService _skillTreeService = SkillTreeService();
  List<SkillNode> _skills = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() => _isLoading = true);
    try {
      _skills = await _skillTreeService.getAllSkills();
    } catch (e) {
      debugPrint('加载技能树失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('技能树'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              setState(() => _selectedCategory = category);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(value: 'frontend', child: Text('前端开发')),
              const PopupMenuItem(value: 'backend', child: Text('后端开发')),
              const PopupMenuItem(value: 'mobile', child: Text('移动开发')),
              const PopupMenuItem(value: 'devops', child: Text('DevOps')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressOverview(),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: CustomPaint(
                      painter: SkillTreePainter(
                        skills: _filteredSkills,
                        onNodeTap: _showSkillDetail,
                      ),
                      size: const Size(2000, 3000),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<SkillNode> get _filteredSkills {
    if (_selectedCategory == null) return _skills;
    return _skills.where((s) => s.category == _selectedCategory).toList();
  }

  Widget _buildProgressOverview() {
    final totalSkills = _skills.length;
    final masteredSkills = _skills.where((s) => s.isMastered).length;
    final inProgressSkills = _skills.where((s) => s.progress > 0 && !s.isMastered).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalSkills > 0 ? masteredSkills / totalSkills : 0,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$masteredSkills / $totalSkills 已掌握',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildStatCard('进行中', '$inProgressSkills', Icons.play_circle),
          const SizedBox(width: 8),
          _buildStatCard('未开始', '${totalSkills - masteredSkills - inProgressSkills}', Icons.circle_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showSkillDetail(SkillNode skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SkillDetailSheet(
          skill: skill,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class SkillTreePainter extends CustomPainter {
  final List<SkillNode> skills;
  final Function(SkillNode) onNodeTap;

  SkillTreePainter({
    required this.skills,
    required this.onNodeTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 绘制连接线
    for (final skill in skills) {
      if (skill.prerequisites.isNotEmpty) {
        for (final prereqId in skill.prerequisites) {
          final prereq = skills.firstWhere(
            (s) => s.id == prereqId,
            orElse: () => skill,
          );
          _drawConnection(canvas, paint, prereq, skill);
        }
      }
    }

    // 绘制节点
    for (final skill in skills) {
      _drawSkillNode(canvas, skill);
    }
  }

  void _drawConnection(Canvas canvas, Paint paint, SkillNode from, SkillNode to) {
    final path = Path()
      ..moveTo(from.position.dx, from.position.dy)
      ..lineTo(to.position.dx, to.position.dy);
    
    canvas.drawPath(path, paint);
  }

  void _drawSkillNode(Canvas canvas, SkillNode skill) {
    final rect = Rect.fromCenter(
      center: skill.position,
      width: 120,
      height: 80,
    );

    final paint = Paint()
      ..color = skill.isMastered
          ? Colors.green
          : skill.progress > 0
              ? Colors.orange
              : Colors.grey
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );

    // TODO: 添加文字和图标
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SkillDetailSheet extends StatelessWidget {
  final SkillNode skill;
  final ScrollController scrollController;

  const SkillDetailSheet({
    Key? key,
    required this.skill,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            children: [
              Icon(
                skill.icon,
                size: 48,
                color: skill.isMastered ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      skill.category,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            skill.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            '学习进度',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: skill.progress / 100),
          const SizedBox(height: 4),
          Text('${skill.progress}%'),
          const SizedBox(height: 20),
          if (skill.prerequisites.isNotEmpty) ...[
            Text(
              '前置技能',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: skill.prerequisites.map((id) {
                return Chip(label: Text(id));
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: skill.isLocked ? null : () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(skill.isLocked ? '请先完成前置技能' : '开始学习'),
          ),
        ],
      ),
    );
  }
}
