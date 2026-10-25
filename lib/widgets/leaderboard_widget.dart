import 'package:flutter/material.dart';

class LeaderboardWidget extends StatelessWidget {
  final ScrollController scrollController;

  const LeaderboardWidget({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '挑战排行榜',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTimeFilter(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: 50,
              itemBuilder: (context, index) {
                return _buildLeaderboardItem(index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('今日'),
            selected: true,
            onSelected: (selected) {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('本周'),
            selected: false,
            onSelected: (selected) {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('本月'),
            selected: false,
            onSelected: (selected) {},
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(int rank) {
    final isTopThree = rank <= 3;
    final colors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: isTopThree ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isTopThree
              ? BorderSide(color: colors[rank - 1], width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree ? colors[rank - 1] : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: isTopThree ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            '用户${rank + 100}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('完成 ${50 - rank} 个挑战'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(50 - rank) * 100} 分',
                style: TextStyle(
                  color: isTopThree ? colors[rank - 1] : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isTopThree)
                Icon(
                  Icons.emoji_events,
                  color: colors[rank - 1],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
