import 'package:flutter/material.dart';
import '../models/code_share.dart';
import '../services/social_service.dart';

/// 代码分享页面
class CodeShareScreen extends StatefulWidget {
  const CodeShareScreen({super.key});

  @override
  State<CodeShareScreen> createState() => _CodeShareScreenState();
}

class _CodeShareScreenState extends State<CodeShareScreen> {
  final SocialService _socialService = SocialService();
  List<CodeShare> _shares = [];
  String? _selectedLanguage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    setState(() => _isLoading = true);
    try {
      final shares = await _socialService.getCodeShares(language: _selectedLanguage);
      setState(() {
        _shares = shares;
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
        title: const Text('代码分享'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showShareCodeDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 语言筛选
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _LanguageChip(
                    label: '全部',
                    selected: _selectedLanguage == null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = null;
                        _loadShares();
                      });
                    },
                  ),
                  _LanguageChip(
                    label: 'Dart',
                    selected: _selectedLanguage == 'dart',
                    onTap: () {
                      setState(() {
                        _selectedLanguage = 'dart';
                        _loadShares();
                      });
                    },
                  ),
                  _LanguageChip(
                    label: 'Python',
                    selected: _selectedLanguage == 'python',
                    onTap: () {
                      setState(() {
                        _selectedLanguage = 'python';
                        _loadShares();
                      });
                    },
                  ),
                  _LanguageChip(
                    label: 'Java',
                    selected: _selectedLanguage == 'java',
                    onTap: () {
                      setState(() {
                        _selectedLanguage = 'java';
                        _loadShares();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 代码列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shares.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadShares,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shares.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final share = _shares[index];
                            return _CodeShareCard(
                              share: share,
                              onLike: () => _toggleLike(share.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无代码分享',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showShareCodeDialog,
            icon: const Icon(Icons.add),
            label: const Text('分享代码'),
          ),
        ],
      ),
    );
  }

  void _showShareCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享代码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '标题'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '语言'),
                items: const [
                  DropdownMenuItem(value: 'dart', child: Text('Dart')),
                  DropdownMenuItem(value: 'python', child: Text('Python')),
                  DropdownMenuItem(value: 'java', child: Text('Java')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: '代码',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现分享逻辑
              Navigator.pop(context);
            },
            child: const Text('分享'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(String shareId) async {
    await _socialService.toggleLike(shareId);
    await _loadShares();
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CodeShareCard extends StatelessWidget {
  const _CodeShareCard({
    required this.share,
    required this.onLike,
  });

  final CodeShare share;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    share.username.isNotEmpty ? share.username[0] : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatTime(share.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    share.language.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 标题和描述
            Text(
              share.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (share.description != null) ...[
              const SizedBox(height: 4),
              Text(
                share.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // 代码块
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                share.code.length > 200 
                    ? '${share.code.substring(0, 200)}...'
                    : share.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 操作按钮
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    share.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: share.isLiked ? Colors.red : null,
                  ),
                  onPressed: onLike,
                ),
                Text('${share.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // TODO: 查看评论
                  },
                ),
                Text('${share.comments}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: 分享
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }
}
