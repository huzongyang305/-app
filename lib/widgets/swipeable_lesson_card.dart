import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import 'lesson_card.dart';

/// 支持滑动手势的课程卡片
/// - 左滑：标记为已学
/// - 右滑：收藏/取消收藏
/// - 长按：显示快捷菜单
class SwipeableLessonCard extends StatefulWidget {
  const SwipeableLessonCard({
    super.key,
    required this.lesson,
    required this.isLearned,
    required this.isFavorite,
    required this.quizResult,
    this.onFavoriteTap,
    this.onTap,
    this.onMarkLearned,
  });

  final Lesson lesson;
  final bool isLearned;
  final bool isFavorite;
  final dynamic quizResult;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onMarkLearned;

  @override
  State<SwipeableLessonCard> createState() => _SwipeableLessonCardState();
}

class _SwipeableLessonCardState extends State<SwipeableLessonCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  static const _swipeThreshold = 100.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      // 限制拖动范围
      _dragOffset = _dragOffset.clamp(-150.0, 150.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > _swipeThreshold) {
      if (_dragOffset > 0) {
        // 右滑 - 收藏
        widget.onFavoriteTap?.call();
        _showFeedback(context.tr('addedToFavorites'), Icons.favorite, Colors.red);
      } else {
        // 左滑 - 标记已学
        widget.onMarkLearned?.call();
        _showFeedback(context.tr('markedAsLearned'), Icons.check_circle, Colors.green);
      }
    }
    // 重置位置
    setState(() {
      _dragOffset = 0;
    });
  }

  void _showFeedback(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _showQuickMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : null,
                ),
                title: Text(widget.isFavorite
                    ? sheetContext.tr('removeFromFavorites')
                    : sheetContext.tr('addToFavorites')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onFavoriteTap?.call();
                },
              ),
              ListTile(
                leading: Icon(
                  widget.isLearned ? Icons.check_circle : Icons.check_circle_outline,
                  color: widget.isLearned ? Colors.green : null,
                ),
                title: Text(widget.isLearned
                    ? sheetContext.tr('markAsUnlearned')
                    : sheetContext.tr('markAsLearned')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onMarkLearned?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: Text(sheetContext.tr('addNote')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  // TODO: Navigate to notes screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(sheetContext.tr('shareLesson')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  // TODO: Implement share
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: _showQuickMenu,
      child: Stack(
        children: [
          // 背景反馈层
          Positioned.fill(
            child: Row(
              children: [
                // 右侧背景（右滑时显示）
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _dragOffset > 0
                          ? Colors.red.withValues(alpha: _dragOffset / 150 * 0.3)
                          : Colors.transparent,
                      borderRadius: AppRadii.card,
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: _dragOffset > 50
                        ? Icon(
                            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 32,
                          )
                        : null,
                  ),
                ),
                // 左侧背景（左滑时显示）
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _dragOffset < 0
                          ? Colors.green.withValues(alpha: (-_dragOffset) / 150 * 0.3)
                          : Colors.transparent,
                      borderRadius: AppRadii.card,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: _dragOffset < -50
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // 前景卡片
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: LessonCard(
              lesson: widget.lesson,
              isLearned: widget.isLearned,
              isFavorite: widget.isFavorite,
              quizResult: widget.quizResult,
              onFavoriteTap: widget.onFavoriteTap ?? () {},
              onTap: widget.onTap ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

extension on BuildContext {
  String tr(String key) {
    // Simple translation helper - use actual l10n in production
    return key;
  }
}
