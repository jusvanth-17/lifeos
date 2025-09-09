import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task.dart';

class TasksSecondarySidebar extends ConsumerWidget {
  const TasksSecondarySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Filters and Organization
        Expanded(
          child: _buildFilters(context, theme),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.task_alt,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'Tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Add new task
            },
            icon: Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Add Task',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final filters = ref.watch(taskFiltersProvider);
        final taskStats =
            ref.watch(taskProvider.select((state) => state.tasks.length));

        return ListView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          children: [
            // Quick Stats
            _buildQuickStats(context, ref, theme),
            const SizedBox(height: AppConstants.spacingL),

            // Lens Filters
            _buildLensSection(context, ref, theme, filters),
            const SizedBox(height: AppConstants.spacingL),

            // Priority Filter
            _buildPriorityFilters(context, ref, theme, filters),
            const SizedBox(height: AppConstants.spacingL),

            // Status Filter
            _buildStatusFilters(context, ref, theme, filters),
            const SizedBox(height: AppConstants.spacingL),

            // Project Filter
            _buildProjectFilters(context, ref, theme, filters),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    final tasksByStatus = ref.watch(tasksByStatusProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quest Overview',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                  context,
                  theme,
                  'Active',
                  (tasksByStatus[TaskStatus.inProgress]?.length ?? 0)
                      .toString(),
                  Colors.orange),
              _buildStatItem(
                  context,
                  theme,
                  'To Do',
                  (tasksByStatus[TaskStatus.todo]?.length ?? 0).toString(),
                  Colors.blue),
              _buildStatItem(
                  context,
                  theme,
                  'Done',
                  (tasksByStatus[TaskStatus.done]?.length ?? 0).toString(),
                  Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, ThemeData theme, String label,
      String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLensSection(BuildContext context, WidgetRef ref, ThemeData theme,
      TaskFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_alt,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Smart Lenses',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final lens in TaskLens.values)
          ListTile(
            dense: true,
            leading: Icon(
              _getLensIcon(lens),
              size: 16,
              color: filters.lens == lens
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              lens.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: filters.lens == lens ? theme.colorScheme.primary : null,
                fontWeight: filters.lens == lens ? FontWeight.w600 : null,
              ),
            ),
            selected: filters.lens == lens,
            onTap: () => ref.read(taskProvider.notifier).setLens(lens),
          ),
      ],
    );
  }

  Widget _buildPriorityFilters(BuildContext context, WidgetRef ref,
      ThemeData theme, TaskFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.priority_high,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Priority',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final priority in [
          TaskPriority.urgent,
          TaskPriority.high,
          TaskPriority.medium,
          TaskPriority.low
        ])
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: AppConstants.spacingL),
            title: Text(
              priority.displayName,
              style: theme.textTheme.bodySmall,
            ),
            value: filters.priorityFilters.contains(priority),
            onChanged: (value) =>
                ref.read(taskProvider.notifier).togglePriorityFilter(priority),
          ),
      ],
    );
  }

  Widget _buildStatusFilters(BuildContext context, WidgetRef ref,
      ThemeData theme, TaskFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Status',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final status in [
          TaskStatus.backlog,
          TaskStatus.todo,
          TaskStatus.inProgress,
          TaskStatus.done
        ])
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: AppConstants.spacingL),
            title: Text(
              status.displayName,
              style: theme.textTheme.bodySmall,
            ),
            value: filters.statusFilters.contains(status),
            onChanged: (value) =>
                ref.read(taskProvider.notifier).toggleStatusFilter(status),
          ),
      ],
    );
  }

  Widget _buildProjectFilters(BuildContext context, WidgetRef ref,
      ThemeData theme, TaskFilters filters) {
    final tasksByProject = ref.watch(tasksByProjectProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Projects',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final projectEntry in tasksByProject.entries)
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: AppConstants.spacingL),
            title: Text(
              projectEntry.value.isNotEmpty
                  ? projectEntry.value.first.projectName
                  : 'Unknown Project',
              style: theme.textTheme.bodySmall,
            ),
            subtitle: Text(
              '${projectEntry.value.length} quests',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            value: filters.projectFilters.contains(projectEntry.key),
            onChanged: (value) => ref
                .read(taskProvider.notifier)
                .toggleProjectFilter(projectEntry.key),
          ),
      ],
    );
  }

  IconData _getLensIcon(TaskLens lens) {
    switch (lens) {
      case TaskLens.all:
        return Icons.all_inclusive;
      case TaskLens.atRisk:
        return Icons.warning;
      case TaskLens.recentWins:
        return Icons.celebration;
      case TaskLens.drifting:
        return Icons.trending_down;
      case TaskLens.assignedToMe:
        return Icons.person;
      case TaskLens.overdue:
        return Icons.schedule;
      case TaskLens.blocked:
        return Icons.block;
    }
  }

  Widget _buildFilterSection(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final option in options)
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: AppConstants.spacingL),
            title: Text(
              option,
              style: theme.textTheme.bodySmall,
            ),
            value: false, // TODO: Connect to state
            onChanged: (value) {
              // TODO: Handle filter change
            },
          ),
      ],
    );
  }
}
