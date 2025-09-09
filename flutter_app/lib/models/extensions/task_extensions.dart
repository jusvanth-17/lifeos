import '../task.dart';

/// Extension methods for Task model to separate business logic from data
extension TaskExtensions on Task {
  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.done) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if task has quest team members
  bool get hasQuestTeam => questTeam.isNotEmpty;

  /// Get assignments by role
  List<TaskAssignment> getAssignmentsByRole(TeamRole role) {
    return questTeam.where((assignment) => assignment.role == role).toList();
  }

  /// Get the task leader
  TaskAssignment? getLeader() {
    final leaders = getAssignmentsByRole(TeamRole.leader);
    return leaders.isNotEmpty ? leaders.first : null;
  }

  /// Calculate completion percentage based on status
  double get completionPercentage {
    switch (status) {
      case TaskStatus.backlog:
        return 0.0;
      case TaskStatus.todo:
        return 0.1;
      case TaskStatus.inProgress:
        return 0.5;
      case TaskStatus.done:
        return 1.0;
      case TaskStatus.cancelled:
        return 0.0;
    }
  }

  /// Check if task has subtasks
  bool get hasSubtasks => subtaskIds.isNotEmpty;

  /// Check if task has dependencies
  bool get hasDependencies => dependsOn.isNotEmpty || blocks.isNotEmpty;

  /// Check if task has attachments
  bool get hasAttachments => attachedDocumentIds.isNotEmpty;

  /// Get task priority color
  String get priorityColor {
    switch (priority) {
      case TaskPriority.urgent:
        return '#FF4444';
      case TaskPriority.high:
        return '#FF8800';
      case TaskPriority.medium:
        return '#FFBB33';
      case TaskPriority.low:
        return '#00C851';
      case TaskPriority.none:
        return '#6C757D';
    }
  }

  /// Get task status color
  String get statusColor {
    switch (status) {
      case TaskStatus.backlog:
        return '#6C757D';
      case TaskStatus.todo:
        return '#007BFF';
      case TaskStatus.inProgress:
        return '#FFC107';
      case TaskStatus.done:
        return '#28A745';
      case TaskStatus.cancelled:
        return '#DC3545';
    }
  }

  /// Check if task is in active development
  bool get isActive => status == TaskStatus.inProgress;

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.done;

  /// Check if task is cancelled
  bool get isCancelled => status == TaskStatus.cancelled;

  /// Get estimated vs actual hours variance
  double? get hoursVariance {
    if (estimatedHours == null || actualHours == null) return null;
    return actualHours! - estimatedHours!;
  }

  /// Check if task is over estimated hours
  bool get isOverEstimate {
    final variance = hoursVariance;
    return variance != null && variance > 0;
  }

  /// Get time efficiency ratio (estimated/actual)
  double? get timeEfficiency {
    if (estimatedHours == null || actualHours == null || actualHours == 0) {
      return null;
    }
    return estimatedHours! / actualHours!;
  }

  /// Get days until due date
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference;
  }

  /// Check if task is due soon (within 3 days)
  bool get isDueSoon {
    final days = daysUntilDue;
    return days != null && days <= 3 && days >= 0;
  }

  /// Get task age in days
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Check if task is stale (no activity in 7 days)
  bool get isStale {
    if (lastActivity == null) return ageInDays > 7;
    return DateTime.now().difference(lastActivity!).inDays > 7;
  }

  /// Get formatted time spent
  String get formattedTimeSpent {
    if (timeSpent == 0) return '0h';
    if (timeSpent < 1) {
      return '${(timeSpent * 60).round()}m';
    }
    final hours = timeSpent.floor();
    final minutes = ((timeSpent - hours) * 60).round();
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Get formatted estimated hours
  String get formattedEstimatedHours {
    if (estimatedHours == null) return 'Not estimated';
    if (estimatedHours! < 1) {
      return '${(estimatedHours! * 60).round()}m';
    }
    final hours = estimatedHours!.floor();
    final minutes = ((estimatedHours! - hours) * 60).round();
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Get team role distribution
  Map<TeamRole, int> get teamRoleDistribution {
    final Map<TeamRole, int> distribution = {
      TeamRole.leader: 0,
      TeamRole.designer: 0,
      TeamRole.builder: 0,
    };

    for (final assignment in questTeam) {
      distribution[assignment.role] = (distribution[assignment.role] ?? 0) + 1;
    }

    return distribution;
  }

  /// Check if task has balanced team (at least one of each role)
  bool get hasBalancedTeam {
    final distribution = teamRoleDistribution;
    return distribution[TeamRole.leader]! > 0 &&
        distribution[TeamRole.designer]! > 0 &&
        distribution[TeamRole.builder]! > 0;
  }

  /// Get task complexity score (0-10)
  int get complexityScore {
    int score = 0;

    // Base complexity from priority
    switch (priority) {
      case TaskPriority.urgent:
        score += 4;
        break;
      case TaskPriority.high:
        score += 3;
        break;
      case TaskPriority.medium:
        score += 2;
        break;
      case TaskPriority.low:
        score += 1;
        break;
      case TaskPriority.none:
        score += 0;
        break;
    }

    // Add complexity from relationships
    if (hasSubtasks) score += 2;
    if (hasDependencies) score += 2;
    if (hasAttachments) score += 1;

    // Add complexity from team size
    if (questTeam.length > 3) score += 1;

    return score.clamp(0, 10);
  }
}
