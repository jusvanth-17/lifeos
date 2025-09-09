import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/task.dart';
import '../../models/extensions/task_extensions.dart';
import '../../widgets/layout/four_panel_layout.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure navigation state is set to tasks when viewing task details
    Future.microtask(() {
      ref
          .read(navigationProvider.notifier)
          .setActiveFeature(AppConstants.navTasks);
    });

    final taskState = ref.watch(taskProvider);
    final task = taskState.tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

    return FourPanelLayout(
      title: 'Quest Details',
      actions: [
        // Edit Button
        IconButton(
          onPressed: () => _editTask(context, task),
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Quest',
        ),

        // More Actions
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, ref, task, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: 8),
                  Text('Duplicate Quest'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive, size: 16),
                  SizedBox(width: 8),
                  Text('Archive Quest'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Quest', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),

        // Close Button
        IconButton(
          onPressed: () => context.go('/tasks'),
          icon: const Icon(Icons.close),
          tooltip: 'Back to Tasks',
        ),
      ],
      child: _buildTaskDetail(context, ref, task),
    );
  }

  Widget _buildTaskDetail(BuildContext context, WidgetRef ref, Task task) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Header
          _buildTaskHeader(context, theme, ref, task),
          const SizedBox(height: AppConstants.spacingXL),

          // Task Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskDescription(context, theme, task),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildTaskProgress(context, theme, task),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildTaskActivity(context, theme, task),
                  ],
                ),
              ),

              const SizedBox(width: AppConstants.spacingL),

              // Sidebar
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskMetadata(context, theme, ref, task),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildQuestTeam(context, theme, task),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildQuickActions(context, theme, task),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(
      BuildContext context, ThemeData theme, WidgetRef ref, Task task) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status Row
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: task.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              _buildStatusChip(context, theme, ref, task),
            ],
          ),

          const SizedBox(height: AppConstants.spacingM),

          // Priority and Project Row
          Row(
            children: [
              _buildPriorityChip(context, theme, ref, task),
              const SizedBox(width: AppConstants.spacingM),
              _buildProjectChip(context, theme, task),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDescription(
      BuildContext context, ThemeData theme, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              task.description.isNotEmpty
                  ? task.description
                  : 'No description provided for this quest.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: task.description.isEmpty
                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                    : null,
                fontStyle: task.description.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskProgress(BuildContext context, ThemeData theme, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.completionPercentage,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      task.completionPercentage == 1.0
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  '${(task.completionPercentage * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Time Tracking
            if (task.estimatedHours != null || task.actualHours != null)
              Row(
                children: [
                  if (task.estimatedHours != null)
                    _buildTimeChip(
                      context,
                      theme,
                      'Estimated',
                      '${task.estimatedHours}h',
                      Colors.blue,
                    ),
                  if (task.estimatedHours != null && task.actualHours != null)
                    const SizedBox(width: AppConstants.spacingS),
                  if (task.actualHours != null)
                    _buildTimeChip(
                      context,
                      theme,
                      'Actual',
                      '${task.actualHours}h',
                      task.actualHours! > (task.estimatedHours ?? 0)
                          ? Colors.orange
                          : Colors.green,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskActivity(BuildContext context, ThemeData theme, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Activity Timeline
            _buildActivityTimeline(context, theme, task),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(
      BuildContext context, ThemeData theme, Task task) {
    // Mock activity data - in real app this would come from the task model
    final activities = [
      {'action': 'Quest created', 'time': task.createdAt, 'user': 'You'},
      if (task.status != TaskStatus.backlog)
        {
          'action': 'Status changed to ${task.status.displayName}',
          'time': task.updatedAt,
          'user': 'You'
        },
    ];

    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Text(
            'No activity yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: activities.map((activity) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['action'] as String,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${activity['user']} • ${_formatDateTime(activity['time'] as DateTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskMetadata(
      BuildContext context, ThemeData theme, WidgetRef ref, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quest Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Created Date
            _buildMetadataRow(
              context,
              theme,
              'Created',
              _formatDateTime(task.createdAt),
              Icons.calendar_today,
            ),

            // Updated Date
            _buildMetadataRow(
              context,
              theme,
              'Updated',
              _formatDateTime(task.updatedAt),
              Icons.update,
            ),

            // Due Date
            if (task.dueDate != null)
              _buildMetadataRow(
                context,
                theme,
                'Due Date',
                _formatDateTime(task.dueDate!),
                Icons.schedule,
                isOverdue: task.isOverdue,
              ),

            // Attachments
            if (task.attachedDocumentIds.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Attachments',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                '${task.attachedDocumentIds.length} document(s) attached',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isOverdue
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isOverdue ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTeam(BuildContext context, ThemeData theme, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Quest Team',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),

            if (task.questTeam.isEmpty)
              Text(
                'No team members assigned',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...task.questTeam.map((assignment) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _getRoleColor(assignment.role),
                          child: Text(
                            assignment.userName
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.userName ?? 'Unknown User',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                assignment.role.displayName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

            // Add Team Member Button
            const SizedBox(height: AppConstants.spacingS),
            OutlinedButton.icon(
              onPressed: () => _addTeamMember(context),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add Team Member'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Chat Button
            if (task.chatRoomId != null)
              _buildActionButton(
                context,
                theme,
                'Open Quest Chat',
                Icons.chat_bubble_outline,
                () => context.go('/chats/${task.chatRoomId}'),
              ),

            // Document Button
            _buildActionButton(
              context,
              theme,
              'Quest Document',
              Icons.description_outlined,
              () => context.go('/documents/task-${task.id}'),
            ),

            // Time Tracking Button
            _buildActionButton(
              context,
              theme,
              'Track Time',
              Icons.timer,
              () => _startTimeTracking(context, task),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      BuildContext context, ThemeData theme, WidgetRef ref, Task task) {
    Color statusColor = _getStatusColor(task.status);

    return GestureDetector(
      onTap: () => _showStatusSelector(context, ref, task),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: statusColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(task.status),
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              task.status.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
      BuildContext context, ThemeData theme, WidgetRef ref, Task task) {
    Color priorityColor = _getPriorityColor(task.priority);

    return GestureDetector(
      onTap: () => _showPrioritySelector(context, ref, task),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: priorityColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPriorityIcon(task.priority),
              size: 16,
              color: priorityColor,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              task.priority.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: priorityColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectChip(BuildContext context, ThemeData theme, Task task) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            task.projectName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
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
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper methods
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _editTask(BuildContext context, Task task) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit quest functionality coming soon')),
    );
  }

  void _handleMenuAction(
      BuildContext context, WidgetRef ref, Task task, String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Duplicate quest functionality coming soon')),
        );
        break;
      case 'archive':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Archive quest functionality coming soon')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, task);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality
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

  void _showStatusSelector(BuildContext context, WidgetRef ref, Task task) {
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
                ref
                    .read(taskProvider.notifier)
                    .updateTaskStatus(task.id, status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrioritySelector(BuildContext context, WidgetRef ref, Task task) {
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
                ref
                    .read(taskProvider.notifier)
                    .updateTaskPriority(task.id, priority);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _addTeamMember(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Add team member functionality coming soon')),
    );
  }

  void _startTimeTracking(BuildContext context, Task task) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time tracking functionality coming soon')),
    );
  }
}
