import 'package:flutter/foundation.dart';
import 'task.dart';

/// Lightweight version of Task model optimized for list views and memory efficiency
/// Contains only essential fields needed for displaying tasks in lists
@immutable
class TaskCore {
  final String id;
  final String title;
  final TaskStatus status;
  final TaskPriority priority;
  final String projectId;
  final String projectName;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDrifting;
  final bool isBlocked;

  const TaskCore({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.projectId,
    required this.projectName,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isDrifting,
    required this.isBlocked,
  });

  /// Create TaskCore from full Task model
  factory TaskCore.fromTask(Task task) {
    return TaskCore(
      id: task.id,
      title: task.title,
      status: task.status,
      priority: task.priority,
      projectId: task.projectId,
      projectName: task.projectName,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      isDrifting: task.isDrifting,
      isBlocked: task.isBlocked,
    );
  }

  /// Create from JSON (for API responses)
  factory TaskCore.fromJson(Map<String, dynamic> json) {
    return TaskCore(
      id: json['id'] as String,
      title: json['title'] as String,
      status: TaskStatus.fromString(json['status'] as String),
      priority: TaskPriority.fromString(json['priority'] as String),
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDrifting: json['isDrifting'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }

  /// Create from database row (optimized query)
  factory TaskCore.fromDatabaseRow(Map<String, dynamic> row) {
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
      isDrifting: (row['is_drifting'] as int?) == 1,
      isBlocked: (row['is_blocked'] as int?) == 1,
    );
  }

  /// Convert to JSON (minimal payload)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status.value,
      'priority': priority.value,
      'projectId': projectId,
      'projectName': projectName,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDrifting': isDrifting,
      'isBlocked': isBlocked,
    };
  }

  TaskCore copyWith({
    String? id,
    String? title,
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    String? projectName,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDrifting,
    bool? isBlocked,
  }) {
    return TaskCore(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDrifting: isDrifting ?? this.isDrifting,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskCore &&
        other.id == id &&
        other.title == title &&
        other.status == status &&
        other.priority == priority &&
        other.projectId == projectId &&
        other.projectName == projectName &&
        other.dueDate == dueDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDrifting == isDrifting &&
        other.isBlocked == isBlocked;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      status,
      priority,
      projectId,
      projectName,
      dueDate,
      createdAt,
      updatedAt,
      isDrifting,
      isBlocked,
    );
  }

  @override
  String toString() {
    return 'TaskCore(id: $id, title: $title, status: ${status.displayName}, priority: ${priority.displayName})';
  }
}
