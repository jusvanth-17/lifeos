import 'package:flutter/foundation.dart';

enum TaskStatus {
  backlog('backlog', 'Backlog'),
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  done('done', 'Done'),
  cancelled('cancelled', 'Cancelled');

  const TaskStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.backlog,
    );
  }
}

enum TaskPriority {
  urgent('urgent', 'Urgent'),
  high('high', 'High'),
  medium('medium', 'Medium'),
  low('low', 'Low'),
  none('none', 'None');

  const TaskPriority(this.value, this.displayName);
  final String value;
  final String displayName;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TeamRole {
  leader('leader', 'Leader'),
  designer('designer', 'Designer'),
  builder('builder', 'Builder');

  const TeamRole(this.value, this.displayName);
  final String value;
  final String displayName;

  static TeamRole fromString(String value) {
    return TeamRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => TeamRole.builder,
    );
  }
}

@immutable
class TaskAssignment {
  final String id;
  final String taskId;
  final String userId;
  final TeamRole role;
  final DateTime assignedAt;
  final String assignedBy;

  // User details - populated from join with users table
  String? userName;
  String? userAvatar;

  TaskAssignment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.role,
    required this.assignedAt,
    required this.assignedBy,
    this.userName,
    this.userAvatar,
  });

  TaskAssignment copyWith({
    String? id,
    String? taskId,
    String? userId,
    TeamRole? role,
    DateTime? assignedAt,
    String? assignedBy,
    String? userName,
    String? userAvatar,
  }) {
    return TaskAssignment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'role': role.value,
      'assignedAt': assignedAt.toIso8601String(),
      'assignedBy': assignedBy,
    };
  }

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      role: TeamRole.fromString(json['role'] as String),
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      assignedBy: json['assignedBy'] as String,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
    );
  }

  // Create from database row
  factory TaskAssignment.fromDatabaseRow(Map<String, dynamic> row) {
    return TaskAssignment(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      userId: row['user_id'] as String,
      role: TeamRole.fromString(row['role'] as String),
      assignedAt: DateTime.parse(row['assigned_at'] as String),
      assignedBy: row['assigned_by'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskAssignment &&
        other.id == id &&
        other.taskId == taskId &&
        other.userId == userId &&
        other.role == role &&
        other.assignedAt == assignedAt &&
        other.assignedBy == assignedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        taskId.hashCode ^
        userId.hashCode ^
        role.hashCode ^
        assignedAt.hashCode ^
        assignedBy.hashCode;
  }
}

@immutable
class Task {
  final String id;
  final String title;
  final String description;
  final String questDocument;
  final TaskStatus status;
  final TaskPriority priority;
  final double? estimatedHours;
  final double? actualHours;
  final double timeSpent;
  final List<TaskAssignment> questTeam;
  final String projectId;
  final String projectName;
  final String? goalId;
  final String? parentTaskId;
  final String? chatRoomId;
  final int knowledgeReward;
  final int? gratificationRating;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? completedDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivity;
  final bool isDrifting;
  final bool isBlocked;

  // Relationships - populated separately from junction tables
  final List<String> subtaskIds;
  final List<String> dependsOn;
  final List<String> blocks;
  final List<String> attachedDocumentIds;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.questDocument,
    required this.status,
    required this.priority,
    this.estimatedHours,
    this.actualHours,
    required this.timeSpent,
    required this.questTeam,
    required this.projectId,
    required this.projectName,
    this.goalId,
    this.parentTaskId,
    this.chatRoomId,
    required this.knowledgeReward,
    this.gratificationRating,
    this.dueDate,
    this.startDate,
    this.completedDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivity,
    required this.isDrifting,
    required this.isBlocked,
    this.subtaskIds = const [],
    this.dependsOn = const [],
    this.blocks = const [],
    this.attachedDocumentIds = const [],
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? questDocument,
    TaskStatus? status,
    TaskPriority? priority,
    double? estimatedHours,
    double? actualHours,
    double? timeSpent,
    List<TaskAssignment>? questTeam,
    String? projectId,
    String? projectName,
    String? goalId,
    String? parentTaskId,
    String? chatRoomId,
    int? knowledgeReward,
    int? gratificationRating,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? completedDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivity,
    bool? isDrifting,
    bool? isBlocked,
    List<String>? subtaskIds,
    List<String>? dependsOn,
    List<String>? blocks,
    List<String>? attachedDocumentIds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questDocument: questDocument ?? this.questDocument,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      timeSpent: timeSpent ?? this.timeSpent,
      questTeam: questTeam ?? this.questTeam,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      goalId: goalId ?? this.goalId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      knowledgeReward: knowledgeReward ?? this.knowledgeReward,
      gratificationRating: gratificationRating ?? this.gratificationRating,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isDrifting: isDrifting ?? this.isDrifting,
      isBlocked: isBlocked ?? this.isBlocked,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      dependsOn: dependsOn ?? this.dependsOn,
      blocks: blocks ?? this.blocks,
      attachedDocumentIds: attachedDocumentIds ?? this.attachedDocumentIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questDocument': questDocument,
      'status': status.value,
      'priority': priority.value,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'timeSpent': timeSpent,
      'questTeam': questTeam.map((assignment) => assignment.toJson()).toList(),
      'projectId': projectId,
      'projectName': projectName,
      'goalId': goalId,
      'parentTaskId': parentTaskId,
      'chatRoomId': chatRoomId,
      'knowledgeReward': knowledgeReward,
      'gratificationRating': gratificationRating,
      'dueDate': dueDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'isDrifting': isDrifting,
      'isBlocked': isBlocked,
      // Include relationships for serialization
      'subtaskIds': subtaskIds,
      'dependsOn': dependsOn,
      'blocks': blocks,
      'attachedDocumentIds': attachedDocumentIds,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      questDocument: json['questDocument'] as String? ?? '',
      status: TaskStatus.fromString(json['status'] as String),
      priority: TaskPriority.fromString(json['priority'] as String),
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      actualHours: (json['actualHours'] as num?)?.toDouble(),
      timeSpent: (json['timeSpent'] as num?)?.toDouble() ?? 0.0,
      questTeam: (json['questTeam'] as List<dynamic>?)
              ?.map((assignment) =>
                  TaskAssignment.fromJson(assignment as Map<String, dynamic>))
              .toList() ??
          [],
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      goalId: json['goalId'] as String?,
      parentTaskId: json['parentTaskId'] as String?,
      chatRoomId: json['chatRoomId'] as String?,
      knowledgeReward: json['knowledgeReward'] as int? ?? 10,
      gratificationRating: json['gratificationRating'] as int?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : null,
      isDrifting: json['isDrifting'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      subtaskIds: (json['subtaskIds'] as List<dynamic>?)?.cast<String>() ?? [],
      dependsOn: (json['dependsOn'] as List<dynamic>?)?.cast<String>() ?? [],
      blocks: (json['blocks'] as List<dynamic>?)?.cast<String>() ?? [],
      attachedDocumentIds:
          (json['attachedDocumentIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  // Create from database row
  factory Task.fromDatabaseRow(Map<String, dynamic> row) {
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
      questTeam: const [], // Populated separately
      projectId: row['project_id'] as String,
      projectName: row['project_name'] as String,
      goalId: row['goal_id'] as String?,
      parentTaskId: row['parent_task_id'] as String?,
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
      isDrifting: (row['is_drifting'] as int?) == 1 ? true : false,
      isBlocked: (row['is_blocked'] as int?) == 1 ? true : false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.questDocument == questDocument &&
        other.status == status &&
        other.priority == priority &&
        other.estimatedHours == estimatedHours &&
        other.actualHours == actualHours &&
        other.timeSpent == timeSpent &&
        listEquals(other.questTeam, questTeam) &&
        other.projectId == projectId &&
        other.projectName == projectName &&
        other.goalId == goalId &&
        other.parentTaskId == parentTaskId &&
        other.chatRoomId == chatRoomId &&
        other.knowledgeReward == knowledgeReward &&
        other.gratificationRating == gratificationRating &&
        other.dueDate == dueDate &&
        other.startDate == startDate &&
        other.completedDate == completedDate &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastActivity == lastActivity &&
        other.isDrifting == isDrifting &&
        other.isBlocked == isBlocked;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      title,
      description,
      questDocument,
      status,
      priority,
      estimatedHours,
      actualHours,
      timeSpent,
      questTeam,
      projectId,
      projectName,
      goalId,
      parentTaskId,
      chatRoomId,
      knowledgeReward,
      gratificationRating,
      dueDate,
      startDate,
      completedDate,
      createdBy,
      createdAt,
      updatedAt,
      lastActivity,
      isDrifting,
      isBlocked,
    ]);
  }
}
