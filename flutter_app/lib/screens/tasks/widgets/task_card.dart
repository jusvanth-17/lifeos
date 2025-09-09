import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/task.dart';
import '../../../models/extensions/task_extensions.dart';
import '../../../models/extensions/task_assignment_extensions.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final Function(TaskStatus)? onStatusChanged;
  final Function(TaskPriority)? onPriorityChanged;
  final VoidCallback? onChatTap;
  final VoidCallback? onDocumentTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    this.onPriorityChanged,
    this.onChatTap,
    this.onDocumentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Priority Indicator
                  _buildPriorityIndicator(context, theme),
                  const SizedBox(width: AppConstants.spacingS),

                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.status == TaskStatus.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Status Chip
                  _buildStatusChip(context, theme),
                ],
              ),

              const SizedBox(height: AppConstants.spacingS),

              // Description
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                  child: Text(
                    task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Project and Due Date Row
              Row(
                children: [
                  // Project
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: AppConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Text(
                      task.projectName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppConstants.spacingS),

                  // Due Date
                  if (task.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: task.isOverdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppConstants.spacingXS),
                        Text(
                          _formatDueDate(task.dueDate!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: task.isOverdue
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: task.isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // Progress Indicator
                  if (task.estimatedHours != null)
                    _buildProgressIndicator(context, theme),
                ],
              ),

              const SizedBox(height: AppConstants.spacingM),

              // Bottom Row
              Row(
                children: [
                  // Quest Team Avatars
                  if (task.hasQuestTeam) _buildQuestTeamAvatars(context, theme),

                  const Spacer(),

                  // Action Buttons
                  _buildActionButtons(context, theme),
                ],
              ),

              // Warning Indicators
              if (task.isBlocked || task.isDrifting || task.isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingS),
                  child: _buildWarningIndicators(context, theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(BuildContext context, ThemeData theme) {
    Color priorityColor;
    IconData priorityIcon;

    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case TaskPriority.high:
        priorityColor = Colors.orange;
        priorityIcon = Icons.keyboard_arrow_up;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.blue;
        priorityIcon = Icons.remove;
        break;
      case TaskPriority.low:
        priorityColor = Colors.green;
        priorityIcon = Icons.keyboard_arrow_down;
        break;
      case TaskPriority.none:
        priorityColor = theme.colorScheme.onSurfaceVariant;
        priorityIcon = Icons.radio_button_unchecked;
        break;
    }

    return GestureDetector(
      onTap: () => _showPrioritySelector(context),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(color: priorityColor, width: 1),
        ),
        child: Icon(
          priorityIcon,
          size: 16,
          color: priorityColor,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ThemeData theme) {
    Color statusColor;
    String statusText;

    switch (task.status) {
      case TaskStatus.backlog:
        statusColor = theme.colorScheme.outline;
        statusText = 'Backlog';
        break;
      case TaskStatus.todo:
        statusColor = Colors.blue;
        statusText = 'To Do';
        break;
      case TaskStatus.inProgress:
        statusColor = Colors.orange;
        statusText = 'In Progress';
        break;
      case TaskStatus.done:
        statusColor = Colors.green;
        statusText = 'Done';
        break;
      case TaskStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return GestureDetector(
      onTap: () => _showStatusSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingS,
          vertical: AppConstants.spacingXS,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: statusColor, width: 1),
        ),
        child: Text(
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ThemeData theme) {
    final progress = task.completionPercentage;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 4,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestTeamAvatars(BuildContext context, ThemeData theme) {
    const maxAvatars = 3;
    final teamToShow = task.questTeam.take(maxAvatars).toList();
    final remainingCount = task.questTeam.length - maxAvatars;

    return Row(
      children: [
        ...teamToShow.map((assignment) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: _getRoleColor(assignment.role),
                child: Text(
                  assignment.userInitials,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            )),
        if (remainingCount > 0)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chat Button
        if (task.chatRoomId != null)
          IconButton(
            onPressed: onChatTap,
            icon: const Icon(Icons.chat_bubble_outline),
            iconSize: 18,
            tooltip: 'Quest Chat',
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),

        // Document Button
        IconButton(
          onPressed: onDocumentTap,
          icon: const Icon(Icons.description_outlined),
          iconSize: 18,
          tooltip: 'Quest Document',
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            padding: const EdgeInsets.all(4),
          ),
        ),

        // More Actions
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit Quest'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Icon(
            Icons.more_vert,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningIndicators(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: AppConstants.spacingS,
      children: [
        if (task.isOverdue)
          _buildWarningChip(
            context,
            theme,
            'Overdue',
            Icons.schedule,
            theme.colorScheme.error,
          ),
        if (task.isBlocked)
          _buildWarningChip(
            context,
            theme,
            'Blocked',
            Icons.block,
            Colors.red,
          ),
        if (task.isDrifting)
          _buildWarningChip(
            context,
            theme,
            'Drifting',
            Icons.trending_down,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildWarningChip(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.leader:
        return Colors.purple;
      case TeamRole.designer:
        return Colors.blue;
      case TeamRole.builder:
        return Colors.green;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${difference.abs()} days ago';
    }
  }

  void _showPrioritySelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) {
            return ListTile(
              leading: Icon(
                _getPriorityIcon(priority),
                color: _getPriorityColor(priority),
              ),
              title: Text(priority.displayName),
              selected: priority == task.priority,
              onTap: () {
                Navigator.of(context).pop();
                onPriorityChanged?.call(priority);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStatusSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(status.displayName),
              selected: status == task.status,
              onTap: () {
                Navigator.of(context).pop();
                onStatusChanged?.call(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Icons.priority_high;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.none:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.none:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return Icons.inbox;
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return Colors.grey;
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onTap?.call();
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Duplicate quest functionality coming soon')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text(
            'Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Delete functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
