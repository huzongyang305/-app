import 'package:flutter/material.dart';

import '../models/virtual_mentor.dart';

class MentorSelectionScreen extends StatefulWidget {
  const MentorSelectionScreen({super.key});

  @override
  State<MentorSelectionScreen> createState() => _MentorSelectionScreenState();
}

class _MentorSelectionScreenState extends State<MentorSelectionScreen> {
  List<VirtualMentor> _mentors = [];
  String? _selectedMentorId;

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() {
      _mentors = MentorService.getAllMentors();
      // TODO: 从本地存储加载用户已选择的导师
      _selectedMentorId = _mentors.isNotEmpty ? _mentors[0].id : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择你的导师')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '每位导师都有独特的教学风格和专业领域，选择最适合你的一位吧！',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // 头像 + 姓名/专业行高 + 选中标记，随系统字号增长。
                  mainAxisExtent:
                      80 +
                      12 +
                      MediaQuery.textScalerOf(context).scale(24) +
                      4 +
                      MediaQuery.textScalerOf(context).scale(18) +
                      8 +
                      24 +
                      12,
                ),
                itemCount: _mentors.length,
                itemBuilder: (context, index) {
                  final mentor = _mentors[index];
                  final isSelected = mentor.id == _selectedMentorId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMentorId = mentor.id;
                      });
                      _showMentorPreview(mentor);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mentor.themeColor.withValues(alpha: 0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? mentor.themeColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: mentor.themeColor.withValues(
                              alpha: 0.3,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: mentor.themeColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mentor.name.split(' - ')[0],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: mentor.themeColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mentor.specialty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            Icon(
                              Icons.check_circle,
                              color: mentor.themeColor,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedMentorId != null ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('确认选择'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMentorPreview(VirtualMentor mentor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: mentor.themeColor.withValues(alpha: 0.3),
                  child: Icon(Icons.person, size: 60, color: mentor.themeColor),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                mentor.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: mentor.themeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mentor.specialty,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                '教学风格',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(mentor.personality),
              const SizedBox(height: 16),
              Text(
                '鼓励语录',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...mentor.encouragingMessages.map((msg) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: mentor.themeColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(msg)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSelection() {
    // TODO: 保存用户选择到本地存储
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导师选择成功！'), backgroundColor: Colors.green),
    );
  }
}
