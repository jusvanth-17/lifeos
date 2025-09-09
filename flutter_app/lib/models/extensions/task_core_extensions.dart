import '../task_core.dart';
import '../task.dart';

/// Extension methods for TaskCore model to provide business logic functionality
/// These are the essential methods needed for list views and basic operations
extension TaskCoreExtensions on TaskCore {
  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.done) return false;
    return DateTime.now().isAfter(dueDate!);
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
    return DateTime.now().difference(updatedAt).inDays > 7;
  }

  /// Get task complexity score (simplified for core model)
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

    // Add complexity from flags
    if (isDrifting) score += 2;
    if (isBlocked) score += 2;

    return score.clamp(0, 10);
  }

  /// Get formatted due date
  String get formattedDueDate {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final diff = dueDate!.difference(now);

    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due tomorrow';
    if (diff.inDays == -1) return 'Due yesterday';
    if (diff.inDays < 0) return 'Overdue by ${-diff.inDays} days';
    if (diff.inDays <= 7) return 'Due in ${diff.inDays} days';

    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }

  /// Get status display text with emoji
  String get statusDisplayText {
    switch (status) {
      case TaskStatus.backlog:
        return '📋 ${status.displayName}';
      case TaskStatus.todo:
        return '📝 ${status.displayName}';
      case TaskStatus.inProgress:
        return '⚡ ${status.displayName}';
      case TaskStatus.done:
        return '✅ ${status.displayName}';
      case TaskStatus.cancelled:
        return '❌ ${status.displayName}';
    }
  }

  /// Get priority display text with emoji
  String get priorityDisplayText {
    switch (priority) {
      case TaskPriority.urgent:
        return '🔥 ${priority.displayName}';
      case TaskPriority.high:
        return '🔴 ${priority.displayName}';
      case TaskPriority.medium:
        return '🟡 ${priority.displayName}';
      case TaskPriority.low:
        return '🟢 ${priority.displayName}';
      case TaskPriority.none:
        return '⚪ ${priority.displayName}';
    }
  }

  /// Check if task needs attention (overdue, blocked, or drifting)
  bool get needsAttention {
    return isOverdue || isBlocked || isDrifting;
  }

  /// Get attention level (0-3: none, low, medium, high)
  int get attentionLevel {
    if (isOverdue) return 3; // High
    if (isBlocked) return 3; // High
    if (isDrifting) return 2; // Medium
    if (isDueSoon) return 1; // Low
    return 0; // None
  }

  /// Get attention level text
  String get attentionLevelText {
    switch (attentionLevel) {
      case 0:
        return 'Normal';
      case 1:
        return 'Due Soon';
      case 2:
        return 'Drifting';
      case 3:
        return 'Needs Attention';
      default:
        return 'Unknown';
    }
  }

  /// Get task health score (0-100)
  int get healthScore {
    int score = 100;

    // Penalties
    if (isOverdue) score -= 40;
    if (isBlocked) score -= 30;
    if (isDrifting) score -= 20;
    if (isStale) score -= 10;

    // Bonuses
    if (status == TaskStatus.done) score = 100;
    if (status == TaskStatus.inProgress) score += 10;

    return score.clamp(0, 100);
  }

  /// Get task health status
  String get healthStatus {
    final score = healthScore;
    if (score >= 80) return 'Healthy';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'At Risk';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
}

/// Extension methods for List<TaskCore> to handle collections
extension TaskCoreListExtensions on List<TaskCore> {
  /// Filter by status
  List<TaskCore> byStatus(TaskStatus status) {
    return where((task) => task.status == status).toList();
  }

  /// Filter by priority
  List<TaskCore> byPriority(TaskPriority priority) {
    return where((task) => task.priority == priority).toList();
  }

  /// Filter by project
  List<TaskCore> byProject(String projectId) {
    return where((task) => task.projectId == projectId).toList();
  }

  /// Get overdue tasks
  List<TaskCore> get overdue {
    return where((task) => task.isOverdue).toList();
  }

  /// Get tasks due soon
  List<TaskCore> get dueSoon {
    return where((task) => task.isDueSoon).toList();
  }

  /// Get blocked tasks
  List<TaskCore> get blocked {
    return where((task) => task.isBlocked).toList();
  }

  /// Get drifting tasks
  List<TaskCore> get drifting {
    return where((task) => task.isDrifting).toList();
  }

  /// Get tasks that need attention
  List<TaskCore> get needingAttention {
    return where((task) => task.needsAttention).toList();
  }

  /// Get completed tasks
  List<TaskCore> get completed {
    return where((task) => task.isCompleted).toList();
  }

  /// Get active tasks
  List<TaskCore> get active {
    return where((task) => task.isActive).toList();
  }

  /// Sort by due date (earliest first)
  List<TaskCore> get sortedByDueDate {
    final sorted = List<TaskCore>.from(this);
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }

  /// Sort by priority (urgent first)
  List<TaskCore> get sortedByPriority {
    final sorted = List<TaskCore>.from(this);
    sorted.sort((a, b) {
      final priorityOrder = {
        TaskPriority.urgent: 0,
        TaskPriority.high: 1,
        TaskPriority.medium: 2,
        TaskPriority.low: 3,
        TaskPriority.none: 4,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });
    return sorted;
  }

  /// Sort by status (in progress first)
  List<TaskCore> get sortedByStatus {
    final sorted = List<TaskCore>.from(this);
    sorted.sort((a, b) {
      final statusOrder = {
        TaskStatus.inProgress: 0,
        TaskStatus.todo: 1,
        TaskStatus.backlog: 2,
        TaskStatus.done: 3,
        TaskStatus.cancelled: 4,
      };
      return statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
    });
    return sorted;
  }

  /// Sort by creation date (newest first)
  List<TaskCore> get sortedByCreatedDate {
    final sorted = List<TaskCore>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Sort by update date (most recently updated first)
  List<TaskCore> get sortedByUpdatedDate {
    final sorted = List<TaskCore>.from(this);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  /// Get status distribution
  Map<TaskStatus, int> get statusDistribution {
    final Map<TaskStatus, int> distribution = {};
    for (final status in TaskStatus.values) {
      distribution[status] = where((task) => task.status == status).length;
    }
    return distribution;
  }

  /// Get priority distribution
  Map<TaskPriority, int> get priorityDistribution {
    final Map<TaskPriority, int> distribution = {};
    for (final priority in TaskPriority.values) {
      distribution[priority] =
          where((task) => task.priority == priority).length;
    }
    return distribution;
  }

  /// Get project distribution
  Map<String, int> get projectDistribution {
    final Map<String, int> distribution = {};
    for (final task in this) {
      distribution[task.projectId] = (distribution[task.projectId] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get overall health score
  double get overallHealthScore {
    if (isEmpty) return 100.0;
    final totalScore = fold<int>(0, (sum, task) => sum + task.healthScore);
    return totalScore / length;
  }

  /// Get completion percentage
  double get completionPercentage {
    if (isEmpty) return 0.0;
    final completedCount = where((task) => task.isCompleted).length;
    return (completedCount / length) * 100;
  }
}
