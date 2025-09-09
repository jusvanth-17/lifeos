import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/extensions/task_extensions.dart';
import '../services/task_service.dart';

enum TaskViewType {
  list('list', 'List'),
  kanban('kanban', 'Kanban'),
  graph('graph', 'Graph'),
  planner('planner', 'Planner');

  const TaskViewType(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum TaskPerspective {
  today('today', 'Today'),
  week('week', 'This Week'),
  month('month', 'This Month'),
  quarter('quarter', 'This Quarter'),
  all('all', 'All Time');

  const TaskPerspective(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum TaskLens {
  all('all', 'All Tasks'),
  atRisk('at_risk', 'At Risk'),
  recentWins('recent_wins', 'Recent Wins'),
  drifting('drifting', 'Drifting'),
  assignedToMe('assigned_to_me', 'Assigned to Me'),
  overdue('overdue', 'Overdue'),
  blocked('blocked', 'Blocked');

  const TaskLens(this.value, this.displayName);
  final String value;
  final String displayName;
}

class TaskFilters {
  final TaskPerspective perspective;
  final TaskLens lens;
  final List<TaskStatus> statusFilters;
  final List<TaskPriority> priorityFilters;
  final List<String> projectFilters;
  final List<String> assigneeFilters;
  final String searchQuery;

  const TaskFilters({
    this.perspective = TaskPerspective.all,
    this.lens = TaskLens.all,
    this.statusFilters = const [],
    this.priorityFilters = const [],
    this.projectFilters = const [],
    this.assigneeFilters = const [],
    this.searchQuery = '',
  });

  TaskFilters copyWith({
    TaskPerspective? perspective,
    TaskLens? lens,
    List<TaskStatus>? statusFilters,
    List<TaskPriority>? priorityFilters,
    List<String>? projectFilters,
    List<String>? assigneeFilters,
    String? searchQuery,
  }) {
    return TaskFilters(
      perspective: perspective ?? this.perspective,
      lens: lens ?? this.lens,
      statusFilters: statusFilters ?? this.statusFilters,
      priorityFilters: priorityFilters ?? this.priorityFilters,
      projectFilters: projectFilters ?? this.projectFilters,
      assigneeFilters: assigneeFilters ?? this.assigneeFilters,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters {
    return perspective != TaskPerspective.all ||
        lens != TaskLens.all ||
        statusFilters.isNotEmpty ||
        priorityFilters.isNotEmpty ||
        projectFilters.isNotEmpty ||
        assigneeFilters.isNotEmpty ||
        searchQuery.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskFilters &&
        other.perspective == perspective &&
        other.lens == lens &&
        other.statusFilters == statusFilters &&
        other.priorityFilters == priorityFilters &&
        other.projectFilters == projectFilters &&
        other.assigneeFilters == assigneeFilters &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return Object.hash(
      perspective,
      lens,
      statusFilters,
      priorityFilters,
      projectFilters,
      assigneeFilters,
      searchQuery,
    );
  }
}

class TaskState {
  final List<Task> tasks;
  final Task? selectedTask;
  final TaskViewType viewType;
  final TaskFilters filters;
  final bool isLoading;
  final String? error;

  const TaskState({
    this.tasks = const [],
    this.selectedTask,
    this.viewType = TaskViewType.list,
    this.filters = const TaskFilters(),
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<Task>? tasks,
    Task? selectedTask,
    TaskViewType? viewType,
    TaskFilters? filters,
    bool? isLoading,
    String? error,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      selectedTask: selectedTask ?? this.selectedTask,
      viewType: viewType ?? this.viewType,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Task> get filteredTasks {
    var filtered = List<Task>.from(tasks);

    // Apply search filter
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.projectName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filters
    if (filters.statusFilters.isNotEmpty) {
      filtered = filtered.where((task) {
        return filters.statusFilters.contains(task.status);
      }).toList();
    }

    // Apply priority filters
    if (filters.priorityFilters.isNotEmpty) {
      filtered = filtered.where((task) {
        return filters.priorityFilters.contains(task.priority);
      }).toList();
    }

    // Apply project filters
    if (filters.projectFilters.isNotEmpty) {
      filtered = filtered.where((task) {
        return filters.projectFilters.contains(task.projectId);
      }).toList();
    }

    // Apply assignee filters
    if (filters.assigneeFilters.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.questTeam.any((assignment) {
          return filters.assigneeFilters.contains(assignment.userId);
        });
      }).toList();
    }

    // Apply lens filters
    switch (filters.lens) {
      case TaskLens.all:
        break;
      case TaskLens.atRisk:
        filtered = filtered.where((task) {
          return task.isBlocked || task.isOverdue || task.isDrifting;
        }).toList();
        break;
      case TaskLens.recentWins:
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = filtered.where((task) {
          return task.status == TaskStatus.done &&
              task.completedDate != null &&
              task.completedDate!.isAfter(oneWeekAgo);
        }).toList();
        break;
      case TaskLens.drifting:
        filtered = filtered.where((task) => task.isDrifting).toList();
        break;
      case TaskLens.assignedToMe:
        // TODO: Get current user ID from auth provider
        const currentUserId = 'current_user';
        filtered = filtered.where((task) {
          return task.questTeam.any((assignment) {
            return assignment.userId == currentUserId;
          });
        }).toList();
        break;
      case TaskLens.overdue:
        filtered = filtered.where((task) => task.isOverdue).toList();
        break;
      case TaskLens.blocked:
        filtered = filtered.where((task) => task.isBlocked).toList();
        break;
    }

    // Apply perspective filters
    switch (filters.perspective) {
      case TaskPerspective.all:
        break;
      case TaskPerspective.today:
        final today = DateTime.now();
        filtered = filtered.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.year == today.year &&
              task.dueDate!.month == today.month &&
              task.dueDate!.day == today.day;
        }).toList();
        break;
      case TaskPerspective.week:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filtered = filtered.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(startOfWeek) &&
              task.dueDate!.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        break;
      case TaskPerspective.month:
        final now = DateTime.now();
        filtered = filtered.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.year == now.year &&
              task.dueDate!.month == now.month;
        }).toList();
        break;
      case TaskPerspective.quarter:
        final now = DateTime.now();
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStart = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        final quarterEnd = DateTime(now.year, quarter * 3 + 1, 1)
            .subtract(const Duration(days: 1));
        filtered = filtered.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(quarterStart) &&
              task.dueDate!.isBefore(quarterEnd.add(const Duration(days: 1)));
        }).toList();
        break;
    }

    return filtered;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskState &&
        other.tasks == tasks &&
        other.selectedTask == selectedTask &&
        other.viewType == viewType &&
        other.filters == filters &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      tasks,
      selectedTask,
      viewType,
      filters,
      isLoading,
      error,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  final TaskService _taskService;

  TaskNotifier(this._taskService) : super(const TaskState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _taskService.getAllTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createTask({
    required String title,
    required String description,
    required String projectId,
    required String createdBy,
    String? questDocument,
    TaskStatus status = TaskStatus.backlog,
    TaskPriority priority = TaskPriority.medium,
    double? estimatedHours,
    DateTime? dueDate,
    DateTime? startDate,
    String? goalId,
    String? parentTaskId,
    List<String>? subtaskIds,
    List<String>? dependsOn,
    List<String>? blocks,
    List<String>? attachedDocumentIds,
    int knowledgeReward = 10,
  }) async {
    try {
      final newTask = await _taskService.createTask(
        title: title,
        description: description,
        projectId: projectId,
        createdBy: createdBy,
        questDocument: questDocument,
        status: status,
        priority: priority,
        estimatedHours: estimatedHours,
        dueDate: dueDate,
        startDate: startDate,
        goalId: goalId,
        parentTaskId: parentTaskId,
        subtaskIds: subtaskIds,
        dependsOn: dependsOn,
        blocks: blocks,
        attachedDocumentIds: attachedDocumentIds,
        knowledgeReward: knowledgeReward,
      );

      if (newTask != null) {
        state = state.copyWith(
          tasks: [...state.tasks, newTask],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final updatedTask = await _taskService.updateTask(taskId, updates);
      if (updatedTask != null) {
        final updatedTasks = state.tasks.map((t) {
          return t.id == updatedTask.id ? updatedTask : t;
        }).toList();

        state = state.copyWith(
          tasks: updatedTasks,
          selectedTask: state.selectedTask?.id == updatedTask.id
              ? updatedTask
              : state.selectedTask,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
      state = state.copyWith(
        tasks: updatedTasks,
        selectedTask:
            state.selectedTask?.id == taskId ? null : state.selectedTask,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void selectTask(Task? task) {
    state = state.copyWith(selectedTask: task);
  }

  void setViewType(TaskViewType viewType) {
    state = state.copyWith(viewType: viewType);
  }

  void updateFilters(TaskFilters filters) {
    state = state.copyWith(filters: filters);
  }

  void setPerspective(TaskPerspective perspective) {
    final updatedFilters = state.filters.copyWith(perspective: perspective);
    state = state.copyWith(filters: updatedFilters);
  }

  void setLens(TaskLens lens) {
    final updatedFilters = state.filters.copyWith(lens: lens);
    state = state.copyWith(filters: updatedFilters);
  }

  void setSearchQuery(String query) {
    final updatedFilters = state.filters.copyWith(searchQuery: query);
    state = state.copyWith(filters: updatedFilters);
  }

  void toggleStatusFilter(TaskStatus status) {
    final currentFilters = List<TaskStatus>.from(state.filters.statusFilters);
    if (currentFilters.contains(status)) {
      currentFilters.remove(status);
    } else {
      currentFilters.add(status);
    }
    final updatedFilters =
        state.filters.copyWith(statusFilters: currentFilters);
    state = state.copyWith(filters: updatedFilters);
  }

  void togglePriorityFilter(TaskPriority priority) {
    final currentFilters =
        List<TaskPriority>.from(state.filters.priorityFilters);
    if (currentFilters.contains(priority)) {
      currentFilters.remove(priority);
    } else {
      currentFilters.add(priority);
    }
    final updatedFilters =
        state.filters.copyWith(priorityFilters: currentFilters);
    state = state.copyWith(filters: updatedFilters);
  }

  void toggleProjectFilter(String projectId) {
    final currentFilters = List<String>.from(state.filters.projectFilters);
    if (currentFilters.contains(projectId)) {
      currentFilters.remove(projectId);
    } else {
      currentFilters.add(projectId);
    }
    final updatedFilters =
        state.filters.copyWith(projectFilters: currentFilters);
    state = state.copyWith(filters: updatedFilters);
  }

  void clearFilters() {
    state = state.copyWith(filters: const TaskFilters());
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Quick actions
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await updateTask(taskId, {
      'status': status,
      'completedDate': status == TaskStatus.done ? DateTime.now() : null,
    });
  }

  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    await updateTask(taskId, {
      'priority': priority,
    });
  }

  Future<void> assignUserToTask(
      String taskId, TaskAssignment assignment) async {
    try {
      await _taskService.assignUserToTask(
        taskId: taskId,
        userId: assignment.userId,
        userName: assignment.userName ?? '',
        userAvatar: assignment.userAvatar ?? '',
        role: assignment.role,
        assignedBy: assignment.assignedBy,
      );

      // Reload tasks to get updated assignments
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeUserFromTask(String taskId, String userId) async {
    try {
      await _taskService.removeUserFromTask(taskId, userId);

      // Reload tasks to get updated assignments
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService.instance;
});

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TaskNotifier(taskService);
});

// Helper providers
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.filteredTasks;
});

final selectedTaskProvider = Provider<Task?>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.selectedTask;
});

final taskViewTypeProvider = Provider<TaskViewType>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.viewType;
});

final taskFiltersProvider = Provider<TaskFilters>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.filters;
});

final tasksByStatusProvider = Provider<Map<TaskStatus, List<Task>>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  final Map<TaskStatus, List<Task>> tasksByStatus = {};

  for (final status in TaskStatus.values) {
    tasksByStatus[status] =
        tasks.where((task) => task.status == status).toList();
  }

  return tasksByStatus;
});

final tasksByProjectProvider = Provider<Map<String, List<Task>>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  final Map<String, List<Task>> tasksByProject = {};

  for (final task in tasks) {
    if (!tasksByProject.containsKey(task.projectId)) {
      tasksByProject[task.projectId] = [];
    }
    tasksByProject[task.projectId]!.add(task);
  }

  return tasksByProject;
});
