import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task.dart';
import '../widgets/task_card.dart';

class TasksKanbanView extends ConsumerWidget {
  const TasksKanbanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksByStatus = ref.watch(tasksByStatusProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: TaskStatus.values.map((status) {
          final tasks = tasksByStatus[status] ?? [];
          return _buildKanbanColumn(context, ref, status, tasks);
        }).toList(),
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    WidgetRef ref,
    TaskStatus status,
    List<Task> tasks,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    status.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Text(
                    tasks.length.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingM),

          // Tasks
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyColumn(context, status)
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingM),
                        child: TaskCard(
                          task: task,
                          onTap: () => _navigateToTaskDetail(context, task),
                          onStatusChanged: (newStatus) =>
                              _updateTaskStatus(ref, task.id, newStatus),
                          onPriorityChanged: (priority) =>
                              _updateTaskPriority(ref, task.id, priority),
                          onChatTap: () => _navigateToTaskChat(context, task),
                          onDocumentTap: () =>
                              _navigateToTaskDocument(context, task),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(BuildContext context, TaskStatus status) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'No ${status.displayName.toLowerCase()} quests',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  void _navigateToTaskDetail(BuildContext context, Task task) {
    // TODO: Navigate to task detail
  }

  void _navigateToTaskChat(BuildContext context, Task task) {
    // TODO: Navigate to task chat
  }

  void _navigateToTaskDocument(BuildContext context, Task task) {
    // TODO: Navigate to task document
  }

  void _updateTaskStatus(WidgetRef ref, String taskId, TaskStatus status) {
    ref.read(taskProvider.notifier).updateTaskStatus(taskId, status);
  }

  void _updateTaskPriority(
      WidgetRef ref, String taskId, TaskPriority priority) {
    ref.read(taskProvider.notifier).updateTaskPriority(taskId, priority);
  }
}
