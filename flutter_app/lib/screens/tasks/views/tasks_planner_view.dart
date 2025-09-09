import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task.dart';
import '../../../models/extensions/task_extensions.dart';
import '../widgets/task_card.dart';

class TasksPlannerView extends ConsumerWidget {
  const TasksPlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasks = ref.watch(filteredTasksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Planner Header
          _buildPlannerHeader(context),

          const SizedBox(height: AppConstants.spacingL),

          // Time Sections
          _buildTimeSection(
            context,
            ref,
            'Today',
            Icons.today,
            Colors.red,
            _getTasksForToday(filteredTasks),
          ),

          const SizedBox(height: AppConstants.spacingL),

          _buildTimeSection(
            context,
            ref,
            'Tomorrow',
            Icons.event,
            Colors.orange,
            _getTasksForTomorrow(filteredTasks),
          ),

          const SizedBox(height: AppConstants.spacingL),

          _buildTimeSection(
            context,
            ref,
            'This Week',
            Icons.view_week,
            Colors.blue,
            _getTasksForThisWeek(filteredTasks),
          ),

          const SizedBox(height: AppConstants.spacingL),

          _buildTimeSection(
            context,
            ref,
            'Unplanned',
            Icons.schedule,
            Colors.grey,
            _getUnplannedTasks(filteredTasks),
          ),

          const SizedBox(height: AppConstants.spacingL),

          // Overdue Section
          if (_getOverdueTasks(filteredTasks).isNotEmpty)
            _buildTimeSection(
              context,
              ref,
              'Overdue',
              Icons.warning,
              Theme.of(context).colorScheme.error,
              _getOverdueTasks(filteredTasks),
            ),
        ],
      ),
    );
  }

  Widget _buildPlannerHeader(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quest Planner',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  _formatDate(now),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  'Plan your quests across time',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: const Icon(
              Icons.calendar_view_day,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    Color color,
    List<Task> tasks,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: color,
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
              const Spacer(),
              if (tasks.isNotEmpty) _buildSectionStats(context, tasks, color),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spacingM),

        // Tasks
        if (tasks.isEmpty)
          _buildEmptySection(context, title, icon, color)
        else
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                child: TaskCard(
                  task: task,
                  onTap: () => _navigateToTaskDetail(context, task),
                  onStatusChanged: (status) =>
                      _updateTaskStatus(ref, task.id, status),
                  onPriorityChanged: (priority) =>
                      _updateTaskPriority(ref, task.id, priority),
                  onChatTap: () => _navigateToTaskChat(context, task),
                  onDocumentTap: () => _navigateToTaskDocument(context, task),
                ),
              )),
      ],
    );
  }

  Widget _buildSectionStats(
      BuildContext context, List<Task> tasks, Color color) {
    final theme = Theme.of(context);
    final completedCount =
        tasks.where((task) => task.status == TaskStatus.done).length;
    final totalEstimatedHours = tasks
        .where((task) => task.estimatedHours != null)
        .fold<double>(0, (sum, task) => sum + task.estimatedHours!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (completedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: AppConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 12),
                const SizedBox(width: AppConstants.spacingXS),
                Text(
                  '$completedCount done',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        if (completedCount > 0 && totalEstimatedHours > 0)
          const SizedBox(width: AppConstants.spacingS),
        if (totalEstimatedHours > 0)
          Container(
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
                Icon(Icons.schedule, color: color, size: 12),
                const SizedBox(width: AppConstants.spacingXS),
                Text(
                  '${totalEstimatedHours.toInt()}h',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySection(
      BuildContext context, String title, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'No quests ${title.toLowerCase()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Task filtering methods
  List<Task> _getTasksForToday(List<Task> tasks) {
    final today = DateTime.now();
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;
    }).toList();
  }

  List<Task> _getTasksForTomorrow(List<Task> tasks) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == tomorrow.year &&
          task.dueDate!.month == tomorrow.month &&
          task.dueDate!.day == tomorrow.day;
    }).toList();
  }

  List<Task> _getTasksForThisWeek(List<Task> tasks) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate = task.dueDate!;

      // Exclude today and tomorrow
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      if ((dueDate.year == today.year &&
              dueDate.month == today.month &&
              dueDate.day == today.day) ||
          (dueDate.year == tomorrow.year &&
              dueDate.month == tomorrow.month &&
              dueDate.day == tomorrow.day)) {
        return false;
      }

      return dueDate.isAfter(startOfWeek) &&
          dueDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  List<Task> _getUnplannedTasks(List<Task> tasks) {
    return tasks.where((task) => task.dueDate == null).toList();
  }

  List<Task> _getOverdueTasks(List<Task> tasks) {
    return tasks.where((task) => task.isOverdue).toList();
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}, ${date.year}';
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
