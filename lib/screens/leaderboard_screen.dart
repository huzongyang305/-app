import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/social_service.dart';

/// 排行榜页面
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SocialService _socialService = SocialService();
  List<Friend> _friends = [];
  LeaderboardType _currentType = LeaderboardType.points;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _socialService.getLeaderboard(type: _currentType);
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
      ),
      body: Column(
        children: [
          // 排行榜类型切换
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<LeaderboardType>(
              segments: const [
                ButtonSegment(
                  value: LeaderboardType.points,
                  label: Text('积分'),
                  icon: Icon(Icons.star, size: 18),
                ),
                ButtonSegment(
                  value: LeaderboardType.streak,
                  label: Text('连续'),
                  icon: Icon(Icons.local_fire_department, size: 18),
                ),
                ButtonSegment(
                  value: LeaderboardType.lessons,
                  label: Text('课程'),
                  icon: Icon(Icons.menu_book, size: 18),
                ),
                ButtonSegment(
                  value: LeaderboardType.challenges,
                  label: Text('挑战'),
                  icon: Icon(Icons.emoji_events, size: 18),
                ),
              ],
              selected: {_currentType},
              onSelectionChanged: (selected) {
                setState(() {
                  _currentType = selected.first;
                  _loadLeaderboard();
                });
              },
            ),
          ),
          
          // 排行榜列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadLeaderboard,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _friends.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final friend = _friends[index];
                        return _LeaderboardItem(
                          friend: friend,
                          rank: index + 1,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  const _LeaderboardItem({
    required this.friend,
    required this.rank,
  });

  final Friend friend;
  final int rank;

  Color _getRankColor() {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.orange.shade700;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRankColor(),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          friend.username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '已学 ${friend.learnedLessons} 课 · 完成 ${friend.completedChallenges} 挑战',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank <= 3)
              Icon(
                Icons.emoji_events,
                color: _getRankColor(),
                size: 24,
              ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${friend.totalPoints}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '积分',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
