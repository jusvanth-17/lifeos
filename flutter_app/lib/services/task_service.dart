import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_core.dart';
import 'power_sync_service.dart';

class TaskService {
  static TaskService? _instance;
  static TaskService get instance => _instance ??= TaskService._();

  TaskService._();

  final PowerSyncService _powerSync = PowerSyncService.instance;
  final Uuid _uuid = const Uuid();

  /// Get all tasks
  Future<List<Task>> getAllTasks() async {
    try {
      final results = await _powerSync.query(
        'tasks',
        orderBy: 'created_at DESC',
      );

      final List<Task> tasks = [];
      for (final row in results) {
        final task = await _mapRowToTask(row);
        tasks.add(task);
      }

      return tasks;
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        where: 'status = ?',
        whereArgs: [status.value],
        orderBy: 'created_at DESC',
      );

      final List<Task> tasks = [];
      for (final row in results) {
        final task = await _mapRowToTask(row);
        tasks.add(task);
      }

      return tasks;
    } catch (e) {
      print('Error getting tasks by status: $e');
      return [];
    }
  }

  /// Get tasks by project
  Future<List<Task>> getTasksByProject(String projectId) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'created_at DESC',
      );

      final List<Task> tasks = [];
      for (final row in results) {
        final task = await _mapRowToTask(row);
        tasks.add(task);
      }

      return tasks;
    } catch (e) {
      print('Error getting tasks by project: $e');
      return [];
    }
  }

  /// Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return await _mapRowToTask(results.first);
    } catch (e) {
      print('Error getting task by ID: $e');
      return null;
    }
  }

  /// Create a new task
  Future<Task?> createTask({
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
      final taskId = _uuid.v4();
      final now = DateTime.now();

      // Get project name
      final projectResults = await _powerSync.query(
        'projects',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [projectId],
        limit: 1,
      );

      final projectName = projectResults.isNotEmpty
          ? projectResults.first['name'] as String
          : 'Unknown Project';

      final taskData = {
        'id': taskId,
        'title': title,
        'description': description,
        'quest_document': questDocument ?? '',
        'status': status.value,
        'priority': priority.value,
        'estimated_hours': estimatedHours,
        'actual_hours': null,
        'time_spent': 0.0,
        'project_id': projectId,
        'project_name': projectName,
        'goal_id': goalId,
        'parent_task_id': parentTaskId,
        'subtask_ids': jsonEncode(subtaskIds ?? []),
        'depends_on': jsonEncode(dependsOn ?? []),
        'blocks': jsonEncode(blocks ?? []),
        'attached_document_ids': jsonEncode(attachedDocumentIds ?? []),
        'chat_room_id': null,
        'knowledge_reward': knowledgeReward,
        'gratification_rating': null,
        'due_date': dueDate?.toIso8601String(),
        'start_date': startDate?.toIso8601String(),
        'completed_date': null,
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'last_activity': now.toIso8601String(),
        'is_drifting': 0,
        'is_blocked': 0,
      };

      await _powerSync.insert('tasks', taskData);

      return await getTaskById(taskId);
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  /// Update a task
  Future<Task?> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Handle JSON fields
      if (updateData.containsKey('subtaskIds')) {
        updateData['subtask_ids'] = jsonEncode(updateData['subtaskIds']);
        updateData.remove('subtaskIds');
      }
      if (updateData.containsKey('dependsOn')) {
        updateData['depends_on'] = jsonEncode(updateData['dependsOn']);
        updateData.remove('dependsOn');
      }
      if (updateData.containsKey('blocks')) {
        updateData['blocks'] = jsonEncode(updateData['blocks']);
        updateData.remove('blocks');
      }
      if (updateData.containsKey('attachedDocumentIds')) {
        updateData['attached_document_ids'] =
            jsonEncode(updateData['attachedDocumentIds']);
        updateData.remove('attachedDocumentIds');
      }

      // Handle enum fields
      if (updateData.containsKey('status') &&
          updateData['status'] is TaskStatus) {
        updateData['status'] = (updateData['status'] as TaskStatus).value;
      }
      if (updateData.containsKey('priority') &&
          updateData['priority'] is TaskPriority) {
        updateData['priority'] = (updateData['priority'] as TaskPriority).value;
      }

      // Handle DateTime fields
      if (updateData.containsKey('dueDate') &&
          updateData['dueDate'] is DateTime) {
        updateData['due_date'] =
            (updateData['dueDate'] as DateTime).toIso8601String();
        updateData.remove('dueDate');
      }
      if (updateData.containsKey('startDate') &&
          updateData['startDate'] is DateTime) {
        updateData['start_date'] =
            (updateData['startDate'] as DateTime).toIso8601String();
        updateData.remove('startDate');
      }
      if (updateData.containsKey('completedDate') &&
          updateData['completedDate'] is DateTime) {
        updateData['completed_date'] =
            (updateData['completedDate'] as DateTime).toIso8601String();
        updateData.remove('completedDate');
      }

      await _powerSync.update(
        'tasks',
        updateData,
        where: 'id = ?',
        whereArgs: [taskId],
      );

      return await getTaskById(taskId);
    } catch (e) {
      print('Error updating task: $e');
      return null;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      // Delete task assignments first
      await _powerSync.delete(
        'task_assignments',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );

      // Delete the task
      await _powerSync.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );

      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  /// Assign user to task
  Future<bool> assignUserToTask({
    required String taskId,
    required String userId,
    required String userName,
    required String userAvatar,
    required TeamRole role,
    required String assignedBy,
  }) async {
    try {
      final assignmentId = _uuid.v4();
      final now = DateTime.now();

      final assignmentData = {
        'id': assignmentId,
        'task_id': taskId,
        'user_id': userId,
        'user_name': userName,
        'user_avatar': userAvatar,
        'role': role.value,
        'assigned_at': now.toIso8601String(),
        'assigned_by': assignedBy,
      };

      await _powerSync.insert('task_assignments', assignmentData);
      return true;
    } catch (e) {
      print('Error assigning user to task: $e');
      return false;
    }
  }

  /// Remove user from task
  Future<bool> removeUserFromTask(String taskId, String userId) async {
    try {
      await _powerSync.delete(
        'task_assignments',
        where: 'task_id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );

      return true;
    } catch (e) {
      print('Error removing user from task: $e');
      return false;
    }
  }

  /// Get task assignments for a task
  Future<List<TaskAssignment>> getTaskAssignments(String taskId) async {
    try {
      final results = await _powerSync.query(
        'task_assignments',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'assigned_at ASC',
      );

      return results
          .map((row) => TaskAssignment(
                id: row['id'] as String,
                taskId: row['task_id'] as String,
                userId: row['user_id'] as String,
                userName: row['user_name'] as String,
                userAvatar: row['user_avatar'] as String,
                role: TeamRole.fromString(row['role'] as String),
                assignedAt: DateTime.parse(row['assigned_at'] as String),
                assignedBy: row['assigned_by'] as String,
              ))
          .toList();
    } catch (e) {
      print('Error getting task assignments: $e');
      return [];
    }
  }

  /// Update task time spent
  Future<bool> updateTaskTimeSpent(String taskId, double timeSpent) async {
    try {
      await _powerSync.update(
        'tasks',
        {
          'time_spent': timeSpent,
          'updated_at': DateTime.now().toIso8601String(),
          'last_activity': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );

      return true;
    } catch (e) {
      print('Error updating task time spent: $e');
      return false;
    }
  }

  /// Get task statistics
  Future<Map<String, int>> getTaskStatistics() async {
    try {
      final results = await _powerSync.execute('''
        SELECT 
          status,
          COUNT(*) as count
        FROM tasks 
        GROUP BY status
      ''');

      final Map<String, int> stats = {
        'backlog': 0,
        'todo': 0,
        'in_progress': 0,
        'done': 0,
        'cancelled': 0,
      };

      for (final row in results) {
        final status = row['status'] as String;
        final count = row['count'] as int;
        stats[status] = count;
      }

      return stats;
    } catch (e) {
      print('Error getting task statistics: $e');
      return {
        'backlog': 0,
        'todo': 0,
        'in_progress': 0,
        'done': 0,
        'cancelled': 0,
      };
    }
  }

  // ============================================================================
  // TASKCORE LIGHTWEIGHT QUERY METHODS
  // ============================================================================
  // These methods return TaskCore objects for optimized list view performance
  // Use these for list views, kanban boards, and other scenarios where you
  // don't need the full Task object with all relationships and computed fields

  /// Get all tasks as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getAllTasksCore() async {
    try {
      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        orderBy: 'created_at DESC',
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting all tasks core: $e');
      return [];
    }
  }

  /// Get tasks by status as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getTasksByStatusCore(TaskStatus status) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        where: 'status = ?',
        whereArgs: [status.value],
        orderBy: 'created_at DESC',
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting tasks by status core: $e');
      return [];
    }
  }

  /// Get tasks by project as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getTasksByProjectCore(String projectId) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'created_at DESC',
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting tasks by project core: $e');
      return [];
    }
  }

  /// Get tasks by priority as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getTasksByPriorityCore(TaskPriority priority) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        where: 'priority = ?',
        whereArgs: [priority.value],
        orderBy: 'created_at DESC',
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting tasks by priority core: $e');
      return [];
    }
  }

  /// Get overdue tasks as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getOverdueTasksCore() async {
    try {
      final now = DateTime.now().toIso8601String();
      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        where: 'due_date < ? AND status NOT IN (?, ?)',
        whereArgs: [now, TaskStatus.done.value, TaskStatus.cancelled.value],
        orderBy: 'due_date ASC',
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting overdue tasks core: $e');
      return [];
    }
  }

  /// Get tasks due today as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getTasksDueTodayCore() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        where: 'due_date >= ? AND due_date < ? AND status NOT IN (?, ?)',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
          TaskStatus.done.value,
          TaskStatus.cancelled.value
        ],
        orderBy: 'due_date ASC',
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting tasks due today core: $e');
      return [];
    }
  }

  /// Get recent tasks as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getRecentTasksCore({int limit = 20}) async {
    try {
      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        orderBy: 'updated_at DESC',
        limit: limit,
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting recent tasks core: $e');
      return [];
    }
  }

  /// Get tasks with filters as TaskCore objects (lightweight for list views)
  Future<List<TaskCore>> getFilteredTasksCore({
    List<TaskStatus>? statuses,
    List<TaskPriority>? priorities,
    List<String>? projectIds,
    bool? isOverdue,
    bool? isDrifting,
    bool? isBlocked,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      final List<String> whereConditions = [];
      final List<dynamic> whereArgs = [];

      // Status filter
      if (statuses != null && statuses.isNotEmpty) {
        final statusPlaceholders = statuses.map((_) => '?').join(', ');
        whereConditions.add('status IN ($statusPlaceholders)');
        whereArgs.addAll(statuses.map((s) => s.value));
      }

      // Priority filter
      if (priorities != null && priorities.isNotEmpty) {
        final priorityPlaceholders = priorities.map((_) => '?').join(', ');
        whereConditions.add('priority IN ($priorityPlaceholders)');
        whereArgs.addAll(priorities.map((p) => p.value));
      }

      // Project filter
      if (projectIds != null && projectIds.isNotEmpty) {
        final projectPlaceholders = projectIds.map((_) => '?').join(', ');
        whereConditions.add('project_id IN ($projectPlaceholders)');
        whereArgs.addAll(projectIds);
      }

      // Overdue filter
      if (isOverdue == true) {
        whereConditions.add('due_date < ? AND status NOT IN (?, ?)');
        whereArgs.addAll([
          DateTime.now().toIso8601String(),
          TaskStatus.done.value,
          TaskStatus.cancelled.value
        ]);
      }

      // Drifting filter
      if (isDrifting != null) {
        whereConditions.add('is_drifting = ?');
        whereArgs.add(isDrifting ? 1 : 0);
      }

      // Blocked filter
      if (isBlocked != null) {
        whereConditions.add('is_blocked = ?');
        whereArgs.add(isBlocked ? 1 : 0);
      }

      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereConditions.add('(title LIKE ? OR description LIKE ?)');
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern]);
      }

      final results = await _powerSync.query(
        'tasks',
        columns: [
          'id',
          'title',
          'status',
          'priority',
          'project_id',
          'project_name',
          'due_date',
          'created_at',
          'updated_at',
          'is_drifting',
          'is_blocked'
        ],
        where:
            whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'updated_at DESC',
        limit: limit,
      );

      return results.map((row) => _mapRowToTaskCore(row)).toList();
    } catch (e) {
      print('Error getting filtered tasks core: $e');
      return [];
    }
  }

  /// Convert TaskCore to full Task object when needed
  Future<Task?> expandTaskCore(TaskCore taskCore) async {
    return await getTaskById(taskCore.id);
  }

  /// Batch convert multiple TaskCore objects to full Task objects
  Future<List<Task>> expandTaskCores(List<TaskCore> taskCores) async {
    final List<Task> tasks = [];

    for (final taskCore in taskCores) {
      final task = await getTaskById(taskCore.id);
      if (task != null) {
        tasks.add(task);
      }
    }

    return tasks;
  }

  /// Map database row to Task object
  Future<Task> _mapRowToTask(Map<String, dynamic> row) async {
    // Get task assignments
    final assignments = await getTaskAssignments(row['id'] as String);

    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      questDocument: row['quest_document'] as String? ?? '',
      status: TaskStatus.fromString(row['status'] as String),
      priority: TaskPriority.fromString(row['priority'] as String),
      estimatedHours: (row['estimated_hours'] as num?)?.toDouble(),
      actualHours: (row['actual_hours'] as num?)?.toDouble(),
      timeSpent: (row['time_spent'] as num?)?.toDouble() ?? 0.0,
      questTeam: assignments,
      projectId: row['project_id'] as String,
      projectName: row['project_name'] as String,
      goalId: row['goal_id'] as String?,
      parentTaskId: row['parent_task_id'] as String?,
      subtaskIds: _parseJsonList(row['subtask_ids'] as String?),
      dependsOn: _parseJsonList(row['depends_on'] as String?),
      blocks: _parseJsonList(row['blocks'] as String?),
      attachedDocumentIds:
          _parseJsonList(row['attached_document_ids'] as String?),
      chatRoomId: row['chat_room_id'] as String?,
      knowledgeReward: row['knowledge_reward'] as int? ?? 10,
      gratificationRating: row['gratification_rating'] as int?,
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      startDate: row['start_date'] != null
          ? DateTime.parse(row['start_date'] as String)
          : null,
      completedDate: row['completed_date'] != null
          ? DateTime.parse(row['completed_date'] as String)
          : null,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      lastActivity: row['last_activity'] != null
          ? DateTime.parse(row['last_activity'] as String)
          : null,
      isDrifting: (row['is_drifting'] as int) == 1,
      isBlocked: (row['is_blocked'] as int) == 1,
    );
  }

  /// Parse JSON list from string
  List<String> _parseJsonList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<String>();
    } catch (e) {
      print('Error parsing JSON list: $e');
      return [];
    }
  }

  /// Map database row to TaskCore object (lightweight)
  TaskCore _mapRowToTaskCore(Map<String, dynamic> row) {
    return TaskCore(
      id: row['id'] as String,
      title: row['title'] as String,
      status: TaskStatus.fromString(row['status'] as String),
      priority: TaskPriority.fromString(row['priority'] as String),
      projectId: row['project_id'] as String,
      projectName: row['project_name'] as String,
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      isDrifting: (row['is_drifting'] as int) == 1,
      isBlocked: (row['is_blocked'] as int) == 1,
    );
  }
}
