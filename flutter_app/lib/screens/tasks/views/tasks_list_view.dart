import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task.dart';
import '../widgets/task_card.dart';

class TasksListView extends ConsumerWidget {
  const TasksListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasks = ref.watch(filteredTasksProvider);
    final filters = ref.watch(taskFiltersProvider);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState(context, filters);
    }

    return Column(
      children: [
        // Search and Filter Bar
        _buildSearchBar(context, ref, filters),

        // Task List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return Padding(
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, TaskFilters filters) {
    final hasActiveFilters = filters.hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters ? Icons.filter_list_off : Icons.task_alt,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              hasActiveFilters
                  ? 'No quests match your filters'
                  : 'No quests yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              hasActiveFilters
                  ? 'Try adjusting your filters or search terms to find more quests.'
                  : 'Create your first quest to get started on your journey.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXL),
            if (hasActiveFilters)
              OutlinedButton.icon(
                onPressed: () => _clearFilters(context),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _createNewTask(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Quest'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, WidgetRef ref, TaskFilters filters) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search quests...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: filters.searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () =>
                            ref.read(taskProvider.notifier).setSearchQuery(''),
                        icon: const Icon(Icons.clear, size: 20),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                isDense: true,
              ),
              onChanged: (query) =>
                  ref.read(taskProvider.notifier).setSearchQuery(query),
            ),
          ),

          const SizedBox(width: AppConstants.spacingM),

          // Lens Selector
          _buildLensSelector(context, ref, filters.lens),

          const SizedBox(width: AppConstants.spacingS),

          // Filter Indicator
          if (filters.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                _getActiveFilterCount(filters).toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLensSelector(
      BuildContext context, WidgetRef ref, TaskLens currentLens) {
    return PopupMenuButton<TaskLens>(
      initialValue: currentLens,
      onSelected: (lens) => ref.read(taskProvider.notifier).setLens(lens),
      itemBuilder: (context) => TaskLens.values.map((lens) {
        return PopupMenuItem<TaskLens>(
          value: lens,
          child: Row(
            children: [
              Icon(
                _getLensIcon(lens),
                size: 16,
                color: lens == currentLens
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                lens.displayName,
                style: TextStyle(
                  color: lens == currentLens
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight:
                      lens == currentLens ? FontWeight.w600 : FontWeight.normal,
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getLensIcon(currentLens),
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              currentLens.displayName,
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

  int _getActiveFilterCount(TaskFilters filters) {
    int count = 0;
    if (filters.perspective != TaskPerspective.all) count++;
    if (filters.lens != TaskLens.all) count++;
    if (filters.statusFilters.isNotEmpty) count++;
    if (filters.priorityFilters.isNotEmpty) count++;
    if (filters.projectFilters.isNotEmpty) count++;
    if (filters.assigneeFilters.isNotEmpty) count++;
    if (filters.searchQuery.isNotEmpty) count++;
    return count;
  }

  void _navigateToTaskDetail(BuildContext context, Task task) {
    context.go('/tasks/${task.id}');
  }

  void _navigateToTaskChat(BuildContext context, Task task) {
    if (task.chatRoomId != null) {
      context.go('/chats/${task.chatRoomId}');
    }
  }

  void _navigateToTaskDocument(BuildContext context, Task task) {
    context.go('/documents/task-${task.id}');
  }

  void _updateTaskStatus(WidgetRef ref, String taskId, TaskStatus status) {
    ref.read(taskProvider.notifier).updateTaskStatus(taskId, status);
  }

  void _updateTaskPriority(
      WidgetRef ref, String taskId, TaskPriority priority) {
    ref.read(taskProvider.notifier).updateTaskPriority(taskId, priority);
  }

  void _clearFilters(BuildContext context) {
    // This will be handled by the provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters cleared')),
    );
  }

  void _createNewTask(BuildContext context) {
    context.go('/tasks/create');
  }
}
