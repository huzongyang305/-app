import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../models/study_group.dart';
import '../models/code_share.dart';

/// 社交功能服务
class SocialService {
  static const String _friendsKey = 'friends_list';
  static const String _friendRequestsKey = 'friend_requests';
  static const String _groupsKey = 'study_groups';
  static const String _codeSharesKey = 'code_shares';
  static const String _currentUserIdKey = 'current_user_id';

  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_currentUserIdKey);
    if (userId == null) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_currentUserIdKey, userId);
    }
    return userId;
  }

  // ========== 好友管理 ==========

  Future<List<Friend>> getFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_friendsKey) ?? [];
    return data
        .map((json) => Friend.fromJson(_decodeJson(json)))
        .toList();
  }

  Future<void> addFriend(Friend friend) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await getFriends();
    friends.add(friend);
    await prefs.setStringList(
      _friendsKey,
      friends.map((f) => _encodeJson(f.toJson())).toList(),
    );
  }

  Future<void> removeFriend(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await getFriends();
    friends.removeWhere((f) => f.id == friendId);
    await prefs.setStringList(
      _friendsKey,
      friends.map((f) => _encodeJson(f.toJson())).toList(),
    );
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_friendRequestsKey) ?? [];
    return data
        .map((json) => FriendRequest.fromJson(_decodeJson(json)))
        .toList();
  }

  Future<void> addFriendRequest(FriendRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getFriendRequests();
    requests.add(request);
    await prefs.setStringList(
      _friendRequestsKey,
      requests.map((r) => _encodeJson(r.toJson())).toList(),
    );
  }

  // ========== 学习小组 ==========

  Future<List<StudyGroup>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_groupsKey) ?? [];
    return data
        .map((json) => StudyGroup.fromJson(_decodeJson(json)))
        .toList();
  }

  Future<void> createGroup(StudyGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    final groups = await getGroups();
    groups.add(group);
    await prefs.setStringList(
      _groupsKey,
      groups.map((g) => _encodeJson(g.toJson())).toList(),
    );
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final groups = await getGroups();
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = groups[index];
      // TODO: 添加成员逻辑
      await prefs.setStringList(
        _groupsKey,
        groups.map((g) => _encodeJson(g.toJson())).toList(),
      );
    }
  }

  // ========== 代码分享 ==========

  Future<List<CodeShare>> getCodeShares({String? language}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_codeSharesKey) ?? [];
    var shares = data
        .map((json) => CodeShare.fromJson(_decodeJson(json)))
        .toList();
    
    if (language != null) {
      shares = shares.where((s) => s.language == language).toList();
    }
    
    shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return shares;
  }

  Future<void> shareCode(CodeShare share) async {
    final prefs = await SharedPreferences.getInstance();
    final shares = await getCodeShares();
    shares.insert(0, share);
    await prefs.setStringList(
      _codeSharesKey,
      shares.map((s) => _encodeJson(s.toJson())).toList(),
    );
  }

  Future<void> toggleLike(String shareId) async {
    final prefs = await SharedPreferences.getInstance();
    final shares = await getCodeShares();
    final index = shares.indexWhere((s) => s.id == shareId);
    if (index != -1) {
      final share = shares[index];
      final updated = share.copyWith(
        isLiked: !share.isLiked,
        likes: share.isLiked ? share.likes - 1 : share.likes + 1,
      );
      shares[index] = updated;
      await prefs.setStringList(
        _codeSharesKey,
        shares.map((s) => _encodeJson(s.toJson())).toList(),
      );
    }
  }

  // ========== 排行榜 ==========

  Future<List<Friend>> getLeaderboard({
    LeaderboardType type = LeaderboardType.points,
    int limit = 50,
  }) async {
    final friends = await getFriends();
    
    switch (type) {
      case LeaderboardType.points:
        friends.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      case LeaderboardType.streak:
        friends.sort((a, b) => b.streakDays.compareTo(a.streakDays));
      case LeaderboardType.lessons:
        friends.sort((a, b) => b.learnedLessons.compareTo(a.learnedLessons));
      case LeaderboardType.challenges:
        friends.sort((a, b) => b.completedChallenges.compareTo(a.completedChallenges));
    }
    
    return friends.take(limit).toList();
  }

  // ========== 工具方法 ==========

  String _encodeJson(Map<String, dynamic> json) {
    return jsonEncode(json);
  }

  Map<String, dynamic> _decodeJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }
}

enum LeaderboardType {
  points,
  streak,
  lessons,
  challenges,
}
