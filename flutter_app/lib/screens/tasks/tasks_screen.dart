import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/layout/four_panel_layout.dart';
import 'views/tasks_list_view.dart';
import 'views/tasks_kanban_view.dart';
import 'views/tasks_graph_view.dart';
import 'views/tasks_planner_view.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure navigation state is set to tasks
    Future.microtask(() {
      ref
          .read(navigationProvider.notifier)
          .setActiveFeature(AppConstants.navTasks);
    });

    final taskState = ref.watch(taskProvider);
    final viewType = ref.watch(taskViewTypeProvider);
    final filters = ref.watch(taskFiltersProvider);

    return FourPanelLayout(
      title: _getScreenTitle(viewType, filters),
      actions: [
        // View Type Selector
        _buildViewTypeSelector(context, ref, viewType),
        const SizedBox(width: AppConstants.spacingM),

        // Perspective Selector
        _buildPerspectiveSelector(context, ref, filters.perspective),
        const SizedBox(width: AppConstants.spacingM),

        // Add Task Button
        IconButton(
          onPressed: () => _showCreateTaskDialog(context, ref),
          icon: const Icon(Icons.add),
          tooltip: 'Create New Quest',
        ),
      ],
      child: _buildTaskView(context, ref, viewType, taskState),
    );
  }

  String _getScreenTitle(TaskViewType viewType, TaskFilters filters) {
    String baseTitle = 'Quests';

    if (filters.lens != TaskLens.all) {
      baseTitle = filters.lens.displayName;
    }

    if (filters.perspective != TaskPerspective.all) {
      baseTitle += ' - ${filters.perspective.displayName}';
    }

    return baseTitle;
  }

  Widget _buildViewTypeSelector(
      BuildContext context, WidgetRef ref, TaskViewType currentView) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TaskViewType.values.map((viewType) {
          final isSelected = viewType == currentView;
          return Padding(
            padding: const EdgeInsets.all(2),
            child: Material(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: InkWell(
                onTap: () =>
                    ref.read(taskProvider.notifier).setViewType(viewType),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getViewTypeIcon(viewType),
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        viewType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerspectiveSelector(
      BuildContext context, WidgetRef ref, TaskPerspective currentPerspective) {
    return PopupMenuButton<TaskPerspective>(
      initialValue: currentPerspective,
      onSelected: (perspective) {
        ref.read(taskProvider.notifier).setPerspective(perspective);
      },
      itemBuilder: (context) => TaskPerspective.values.map((perspective) {
        return PopupMenuItem<TaskPerspective>(
          value: perspective,
          child: Row(
            children: [
              Icon(
                _getPerspectiveIcon(perspective),
                size: 16,
                color: perspective == currentPerspective
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                perspective.displayName,
                style: TextStyle(
                  color: perspective == currentPerspective
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: perspective == currentPerspective
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPerspectiveIcon(currentPerspective),
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              currentPerspective.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: AppConstants.spacingXS),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskView(BuildContext context, WidgetRef ref,
      TaskViewType viewType, TaskState taskState) {
    if (taskState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (taskState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Error loading tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              taskState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: () => ref.read(taskProvider.notifier).loadTasks(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (viewType) {
      case TaskViewType.list:
        return const TasksListView();
      case TaskViewType.kanban:
        return const TasksKanbanView();
      case TaskViewType.graph:
        return const TasksGraphView();
      case TaskViewType.planner:
        return const TasksPlannerView();
    }
  }

  IconData _getViewTypeIcon(TaskViewType viewType) {
    switch (viewType) {
      case TaskViewType.list:
        return Icons.list;
      case TaskViewType.kanban:
        return Icons.view_column;
      case TaskViewType.graph:
        return Icons.account_tree;
      case TaskViewType.planner:
        return Icons.calendar_view_day;
    }
  }

  IconData _getPerspectiveIcon(TaskPerspective perspective) {
    switch (perspective) {
      case TaskPerspective.today:
        return Icons.today;
      case TaskPerspective.week:
        return Icons.view_week;
      case TaskPerspective.month:
        return Icons.calendar_month;
      case TaskPerspective.quarter:
        return Icons.calendar_view_month;
      case TaskPerspective.all:
        return Icons.all_inclusive;
    }
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Quest'),
        content: const Text('Task creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to task creation screen
              context.go('/tasks/create');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
