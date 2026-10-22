import 'package:flutter/material.dart';
import '../models/daily_challenge.dart';

class ChallengeCard extends StatefulWidget {
  final DailyChallenge challenge;
  final Function(bool success, int score) onComplete;

  const ChallengeCard({
    Key? key,
    required this.challenge,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  bool _isSubmitting = false;

  Color _getDifficultyColor() {
    switch (widget.challenge.difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.challenge.type) {
      case ChallengeType.coding:
        return Icons.code;
      case ChallengeType.quiz:
        return Icons.quiz;
      case ChallengeType.debugging:
        return Icons.bug_report;
      case ChallengeType.optimization:
        return Icons.speed;
      case ChallengeType.design:
        return Icons.design_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getDifficultyColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.challenge.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              _getDifficultyText(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getDifficultyColor().withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              widget.challenge.maxScore.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: widget.challenge.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey.shade200,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (!widget.challenge.isCompleted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _startChallenge,
                      child: const Text('开始挑战'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSolution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getDifficultyColor(),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('提交答案'),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '已完成 - 得分: ${widget.challenge.userScore}/${widget.challenge.maxScore}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
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

  String _getDifficultyText() {
    switch (widget.challenge.difficulty) {
      case DifficultyLevel.easy:
        return '简单';
      case DifficultyLevel.medium:
        return '中等';
      case DifficultyLevel.hard:
        return '困难';
      case DifficultyLevel.expert:
        return '专家';
    }
  }

  void _startChallenge() {
    // TODO: 打开挑战详情页面
  }

  Future<void> _submitSolution() async {
    setState(() => _isSubmitting = true);
    
    try {
      // TODO: 实现答案验证逻辑
      await Future.delayed(const Duration(seconds: 2));
      
      // 模拟提交成功
      widget.onComplete(true, widget.challenge.maxScore);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
