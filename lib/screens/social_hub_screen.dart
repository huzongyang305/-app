import 'package:flutter/material.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'code_share_screen.dart';
import 'study_groups_screen.dart';

/// 社交中心页面
class SocialHubScreen extends StatelessWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('社交'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: '好友'),
              Tab(icon: Icon(Icons.emoji_events), text: '排行'),
              Tab(icon: Icon(Icons.code), text: '分享'),
              Tab(icon: Icon(Icons.groups), text: '小组'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsScreen(),
            LeaderboardScreen(),
            CodeShareScreen(),
            StudyGroupsScreen(),
          ],
        ),
      ),
    );
  }
}
