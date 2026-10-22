import 'package:flutter/foundation.dart';

import '../models/achievement.dart';
import '../services/progress_provider.dart';

/// 成就解锁事件：当用户获得新徽章时触发。
class AchievementUnlockedEvent {
  const AchievementUnlockedEvent({
    required this.achievement,
    required this.previousValue,
    required this.newValue,
  });

  final Achievement achievement;
  final double previousValue;
  final double newValue;
}

/// 成就解锁监听器类型。
typedef AchievementUnlockCallback = void Function(
  AchievementUnlockedEvent event,
);

/// 成就解锁服务：监听进度变化并检测新解锁的徽章。
class AchievementUnlockService extends ChangeNotifier {
  AchievementUnlockService(this._progress) {
    _previousStatuses = evaluateAchievements(_progress);
    _progress.addListener(_onProgressChanged);
  }

  final ProgressProvider _progress;
  late List<AchievementStatus> _previousStatuses;
  final List<AchievementUnlockCallback> _callbacks = [];

  /// 注册解锁回调：当有新成就解锁时会调用所有已注册的回调。
  void onUnlocked(AchievementUnlockCallback callback) {
    _callbacks.add(callback);
  }

  /// 移除回调。
  void offUnlocked(AchievementUnlockCallback callback) {
    _callbacks.remove(callback);
  }

  void _onProgressChanged() {
    final currentStatuses = evaluateAchievements(_progress);

    for (int i = 0; i < currentStatuses.length; i++) {
      final current = currentStatuses[i];
      final previous = _previousStatuses[i];

      // 检测从未解锁到已解锁的转变
      if (!previous.earned && current.earned) {
        final event = AchievementUnlockedEvent(
          achievement: current.achievement,
          previousValue: previous.value,
          newValue: current.value,
        );

        // 通知所有回调
        for (final callback in _callbacks) {
          callback(event);
        }

        // 同时通知监听器（用于UI更新）
        notifyListeners();
      }
    }

    _previousStatuses = currentStatuses;
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    super.dispose();
  }
}
