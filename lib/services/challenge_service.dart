import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge.dart';

class ChallengeService {
  static const String _challengesKey = 'daily_challenges';
  static const String _streakKey = 'challenge_streak';
  static const String _lastCompletedKey = 'last_completed_challenge';

  Future<DailyChallenge> getTodayChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    
    // 检查是否有今天的挑战
    final storedDate = prefs.getString('last_challenge_date');
    if (storedDate != null && storedDate == _formatDate(today)) {
      final challengeJson = prefs.getString(_challengesKey);
      if (challengeJson != null) {
        return DailyChallenge.fromJson(jsonDecode(challengeJson));
      }
    }

    // 生成新挑战
    final challenge = _generateDailyChallenge(today);
    await prefs.setString(_challengesKey, jsonEncode(challenge.toJson()));
    await prefs.setString('last_challenge_date', _formatDate(today));
    
    return challenge;
  }

  Future<int> getStreakDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  Future<void> completeChallenge(String challengeId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompleted = prefs.getString(_lastCompletedKey);
    
    // 更新连续天数
    if (lastCompleted != null) {
      final lastDate = DateTime.parse(lastCompleted);
      final now = DateTime.now();
      final daysDiff = now.difference(lastDate).inDays;
      
      if (daysDiff == 1) {
        // 连续完成
        final currentStreak = await getStreakDays();
        await prefs.setInt(_streakKey, currentStreak + 1);
      } else if (daysDiff > 1) {
        // 中断，重置
        await prefs.setInt(_streakKey, 1);
      }
    } else {
      // 第一次完成
      await prefs.setInt(_streakKey, 1);
    }
    
    await prefs.setString(_lastCompletedKey, DateTime.now().toIso8601String());
  }

  DailyChallenge _generateDailyChallenge(DateTime date) {
    // 基于日期生成确定性挑战（同一天所有人看到相同的挑战）
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final challenges = _getChallengePool();
    final index = seed % challenges.length;
    
    return challenges[index].copyWith(
      createdAt: date,
      expiresAt: date.add(const Duration(days: 1)),
    );
  }

  List<DailyChallenge> _getChallengePool() {
    return [
      DailyChallenge(
        id: 'challenge_001',
        title: 'Flutter Widget 优化',
        description: '重构以下代码，使用更高效的Widget结构...',
        type: ChallengeType.optimization,
        difficulty: DifficultyLevel.medium,
        tags: ['Flutter', 'Performance', 'Widget'],
        maxScore: 100,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      DailyChallenge(
        id: 'challenge_002',
        title: '算法挑战：快速排序',
        description: '实现一个优化的快速排序算法...',
        type: ChallengeType.coding,
        difficulty: DifficultyLevel.hard,
        tags: ['Algorithm', 'Sorting'],
        maxScore: 150,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      // 更多挑战...
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

extension DailyChallengeExtension on DailyChallenge {
  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    DifficultyLevel? difficulty,
    List<String>? tags,
    int? maxScore,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
    int? userScore,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      maxScore: maxScore ?? this.maxScore,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      userScore: userScore ?? this.userScore,
    );
  }
}
