import 'package:flutter/material.dart';
import '../models/daily_challenge.dart';
import '../services/challenge_service.dart';
import '../widgets/challenge_card.dart';
import '../widgets/leaderboard_widget.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({Key? key}) : super(key: key);

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final ChallengeService _challengeService = ChallengeService();
  DailyChallenge? _todayChallenge;
  bool _isLoading = true;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayChallenge();
  }

  Future<void> _loadTodayChallenge() async {
    setState(() => _isLoading = true);
    try {
      _todayChallenge = await _challengeService.getTodayChallenge();
      _streakDays = await _challengeService.getStreakDays();
    } catch (e) {
      debugPrint('加载每日挑战失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日挑战'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => _showLeaderboard(),
            tooltip: '排行榜',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayChallenge,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(),
                    const SizedBox(height: 16),
                    if (_todayChallenge != null)
                      ChallengeCard(
                        challenge: _todayChallenge!,
                        onComplete: _handleChallengeComplete,
                      ),
                    const SizedBox(height: 24),
                    _buildUpcomingChallenges(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.white, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '连续挑战',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$_streakDays 天',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getStreakMessage(_streakDays),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
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

  String _getStreakMessage(int days) {
    if (days == 0) return '开始你的第一次挑战吧！';
    if (days < 3) return '不错的开始，继续保持！';
    if (days < 7) return '太棒了！你已经坚持了一周！';
    if (days < 30) return '令人印象深刻！你是真正的学习者！';
    return '传奇级别！无人能及！';
  }

  Widget _buildUpcomingChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '即将开始的挑战',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: 0.6,
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Text('${index + 2}', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text('第${index + 2}天的挑战'),
                    subtitle: const Text('明天解锁'),
                    trailing: const Icon(Icons.lock, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleChallengeComplete(bool success, int score) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('恭喜！获得 $score 积分！'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: '查看排名',
            textColor: Colors.white,
            onPressed: _showLeaderboard,
          ),
        ),
      );
      _loadTodayChallenge();
    }
  }

  void _showLeaderboard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => LeaderboardWidget(
          scrollController: scrollController,
        ),
      ),
    );
  }
}
