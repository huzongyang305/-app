import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 渐进式揭示组件：分步展示复杂内容，降低认知负荷
///
/// 使用示例：
/// ```dart
/// ProgressiveReveal(
///   steps: [
///     RevealStep(
///       title: '为什么需要 AVL 树？',
///       content: Text('普通 BST 在有序输入时会退化...'),
///       interactiveHint: '点击查看失衡案例',
///     ),
///     RevealStep(
///       title: 'LL 旋转原理',
///       content: Text('当左子树过高时...'),
///       interactiveHint: '🖼️ 交互动画',
///     ),
///   ],
/// )
/// ```
class ProgressiveReveal extends StatefulWidget {
  final List<RevealStep> steps;
  final bool autoExpandFirst;
  final Function(int completedSteps)? onProgressUpdate;

  const ProgressiveReveal({
    super.key,
    required this.steps,
    this.autoExpandFirst = true,
    this.onProgressUpdate,
  });

  @override
  State<ProgressiveReveal> createState() => _ProgressiveRevealState();
}

class _ProgressiveRevealState extends State<ProgressiveReveal> {
  late List<bool> _expandedStates;
  int get _completedCount => _expandedStates.where((e) => e).length;

  @override
  void initState() {
    super.initState();
    _expandedStates = List.filled(
      widget.steps.length,
      false,
      growable: false,
    );
    if (widget.autoExpandFirst && widget.steps.isNotEmpty) {
      _expandedStates[0] = true;
    }
  }

  void _toggleStep(int index) {
    setState(() {
      _expandedStates[index] = !_expandedStates[index];
    });
    widget.onProgressUpdate?.call(_completedCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // 进度指示器
        _buildProgressIndicator(theme),
        
        const SizedBox(height: AppSpacing.lg),
        
        // 步骤列表
        ...List.generate(widget.steps.length, (index) {
          final step = widget.steps[index];
          final isExpanded = _expandedStates[index];
          final isUnlocked = index == 0 || _expandedStates[index - 1];
          
          return AnimatedPadding(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            padding: EdgeInsets.only(bottom: index < widget.steps.length - 1 ? AppSpacing.md : 0),
            child: _RevealStepCard(
              step: step,
              index: index,
              isExpanded: isExpanded,
              isUnlocked: isUnlocked,
              onTap: () => _toggleStep(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppPalette.neutralFill,
        borderRadius: AppRadii.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '已展开 $_completedCount / ${widget.steps.length} 个部分',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个揭示步骤
class RevealStep {
  final String title;
  final Widget content;
  final String? interactiveHint;
  final IconData? icon;

  const RevealStep({
    required this.title,
    required this.content,
    this.interactiveHint,
    this.icon,
  });
}

/// 步骤卡片组件
class _RevealStepCard extends StatelessWidget {
  final RevealStep step;
  final int index;
  final bool isExpanded;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _RevealStepCard({
    required this.step,
    required this.index,
    required this.isExpanded,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isExpanded ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(
          color: isExpanded 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : AppPalette.rule,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: AppRadii.card,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 序号或图标
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isExpanded
                          ? theme.colorScheme.primary
                          : (isUnlocked 
                              ? AppPalette.neutralFill 
                              : AppPalette.neutralFill.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: isExpanded
                          ? Icon(Icons.check, size: 18, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isUnlocked 
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // 标题
                  Expanded(
                    child: Text(
                      step.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  
                  // 展开/收起图标
                  if (isUnlocked)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: AppMotion.normal,
                      child: Icon(
                        Icons.expand_more,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  
                  // 锁定图标
                  if (!isUnlocked)
                    Icon(
                      Icons.lock,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
              
              // 交互提示
              if (step.interactiveHint != null && !isExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  step.interactiveHint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              // 展开的内容
              if (isExpanded) ...[
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppPalette.rule),
                const SizedBox(height: AppSpacing.lg),
                step.content,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 先行组织者组件：在学习新内容前展示知识地图
class AdvanceOrganizer extends StatelessWidget {
  final String youAlreadyKnow;
  final String willLearn;
  final String finalGoal;
  final List<String> knowledgeBridge;

  const AdvanceOrganizer({
    super.key,
    required this.youAlreadyKnow,
    required this.willLearn,
    required this.finalGoal,
    required this.knowledgeBridge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.cardPrimary,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.map_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '🗺️ 本章地图',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 三栏信息
          _OrganizerItem(
            icon: Icons.check_circle,
            label: '你已经知道',
            content: youAlreadyKnow,
            color: AppPalette.success,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _OrganizerItem(
            icon: Icons.trending_up,
            label: '即将学习',
            content: willLearn,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _OrganizerItem(
            icon: Icons.flag,
            label: '最终目标',
            content: finalGoal,
            color: AppPalette.warning,
          ),
          
          // 知识桥梁
          if (knowledgeBridge.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(color: AppPalette.rule),
            const SizedBox(height: AppSpacing.md),
            Text(
              '🔗 知识桥梁',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: knowledgeBridge.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadii.chip,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        entry.value,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrganizerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;
  final Color color;

  const _OrganizerItem({
    required this.icon,
    required this.label,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
