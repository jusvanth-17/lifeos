import '../task.dart';

/// Extension methods for TaskAssignment model to separate business logic from data
extension TaskAssignmentExtensions on TaskAssignment {
  /// Get role display color
  String get roleColor {
    switch (role) {
      case TeamRole.leader:
        return '#FF6B35'; // Orange
      case TeamRole.designer:
        return '#4ECDC4'; // Teal
      case TeamRole.builder:
        return '#45B7D1'; // Blue
    }
  }

  /// Get role icon
  String get roleIcon {
    switch (role) {
      case TeamRole.leader:
        return '👑';
      case TeamRole.designer:
        return '🎨';
      case TeamRole.builder:
        return '🔨';
    }
  }

  /// Check if assignment is recent (within 24 hours)
  bool get isRecentAssignment {
    return DateTime.now().difference(assignedAt).inHours < 24;
  }

  /// Get assignment age in days
  int get assignmentAgeInDays {
    return DateTime.now().difference(assignedAt).inDays;
  }

  /// Get formatted assignment time
  String get formattedAssignmentTime {
    final now = DateTime.now();
    final diff = now.difference(assignedAt);

    if (diff.inMinutes < 1) return 'Just assigned';
    if (diff.inMinutes < 60) return 'Assigned ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Assigned ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Assigned ${diff.inDays}d ago';

    return 'Assigned ${assignedAt.day}/${assignedAt.month}/${assignedAt.year}';
  }

  /// Get user initials for avatar fallback
  String get userInitials {
    if (userName == null || userName!.isEmpty) return '?';
    final parts = userName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName![0].toUpperCase();
  }

  /// Check if user has avatar
  bool get hasAvatar => userAvatar != null && userAvatar!.isNotEmpty;

  /// Get display name with role
  String get displayNameWithRole {
    final name = userName ?? 'Unknown User';
    return '$name (${role.displayName})';
  }

  /// Check if this is a leadership role
  bool get isLeadershipRole => role == TeamRole.leader;

  /// Check if this is a creative role
  bool get isCreativeRole => role == TeamRole.designer;

  /// Check if this is a technical role
  bool get isTechnicalRole => role == TeamRole.builder;

  /// Get role responsibility description
  String get roleDescription {
    switch (role) {
      case TeamRole.leader:
        return 'Leads the team, makes decisions, and coordinates work';
      case TeamRole.designer:
        return 'Creates designs, user experience, and visual elements';
      case TeamRole.builder:
        return 'Implements solutions, writes code, and builds features';
    }
  }

  /// Get role priority (higher number = higher priority)
  int get rolePriority {
    switch (role) {
      case TeamRole.leader:
        return 3;
      case TeamRole.designer:
        return 2;
      case TeamRole.builder:
        return 1;
    }
  }

  /// Check if assignment is long-term (more than 30 days)
  bool get isLongTermAssignment => assignmentAgeInDays > 30;

  /// Get assignment duration category
  String get assignmentDurationCategory {
    final days = assignmentAgeInDays;
    if (days == 0) return 'New';
    if (days <= 7) return 'Recent';
    if (days <= 30) return 'Active';
    return 'Long-term';
  }
}

/// Extension methods for List<TaskAssignment> to handle team operations
extension TaskAssignmentListExtensions on List<TaskAssignment> {
  /// Get assignments by role
  List<TaskAssignment> byRole(TeamRole role) {
    return where((assignment) => assignment.role == role).toList();
  }

  /// Get all leaders
  List<TaskAssignment> get leaders => byRole(TeamRole.leader);

  /// Get all designers
  List<TaskAssignment> get designers => byRole(TeamRole.designer);

  /// Get all builders
  List<TaskAssignment> get builders => byRole(TeamRole.builder);

  /// Get the primary leader (first assigned leader)
  TaskAssignment? get primaryLeader {
    final leaderList = leaders;
    if (leaderList.isEmpty) return null;
    leaderList.sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
    return leaderList.first;
  }

  /// Check if team has all required roles
  bool get hasAllRoles {
    return leaders.isNotEmpty && designers.isNotEmpty && builders.isNotEmpty;
  }

  /// Check if team is balanced (at least one of each role)
  bool get isBalanced => hasAllRoles;

  /// Get role distribution map
  Map<TeamRole, int> get roleDistribution {
    final Map<TeamRole, int> distribution = {
      TeamRole.leader: 0,
      TeamRole.designer: 0,
      TeamRole.builder: 0,
    };

    for (final assignment in this) {
      distribution[assignment.role] = (distribution[assignment.role] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get team size
  int get teamSize => length;

  /// Check if team is small (1-3 members)
  bool get isSmallTeam => teamSize <= 3;

  /// Check if team is medium (4-7 members)
  bool get isMediumTeam => teamSize >= 4 && teamSize <= 7;

  /// Check if team is large (8+ members)
  bool get isLargeTeam => teamSize >= 8;

  /// Get team size category
  String get teamSizeCategory {
    if (isSmallTeam) return 'Small';
    if (isMediumTeam) return 'Medium';
    return 'Large';
  }

  /// Get most recent assignment
  TaskAssignment? get mostRecentAssignment {
    if (isEmpty) return null;
    return reduce((a, b) => a.assignedAt.isAfter(b.assignedAt) ? a : b);
  }

  /// Get oldest assignment
  TaskAssignment? get oldestAssignment {
    if (isEmpty) return null;
    return reduce((a, b) => a.assignedAt.isBefore(b.assignedAt) ? a : b);
  }

  /// Get assignments sorted by role priority (leaders first)
  List<TaskAssignment> get sortedByRolePriority {
    final sorted = List<TaskAssignment>.from(this);
    sorted.sort((a, b) => b.rolePriority.compareTo(a.rolePriority));
    return sorted;
  }

  /// Get assignments sorted by assignment date (newest first)
  List<TaskAssignment> get sortedByDate {
    final sorted = List<TaskAssignment>.from(this);
    sorted.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    return sorted;
  }

  /// Get unique user IDs
  List<String> get uniqueUserIds {
    return map((assignment) => assignment.userId).toSet().toList();
  }

  /// Check if user is assigned to task
  bool containsUser(String userId) {
    return any((assignment) => assignment.userId == userId);
  }

  /// Get user's role in task
  TeamRole? getUserRole(String userId) {
    final assignment = firstWhere(
      (assignment) => assignment.userId == userId,
      orElse: () => throw StateError('User not found'),
    );
    return assignment.role;
  }

  /// Get assignments for specific user
  List<TaskAssignment> forUser(String userId) {
    return where((assignment) => assignment.userId == userId).toList();
  }

  /// Check if team has multiple people in same role
  bool get hasRoleOverlap {
    final distribution = roleDistribution;
    return distribution.values.any((count) => count > 1);
  }

  /// Get roles that have multiple assignees
  List<TeamRole> get overlappingRoles {
    final distribution = roleDistribution;
    return distribution.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get missing roles (roles with no assignees)
  List<TeamRole> get missingRoles {
    final distribution = roleDistribution;
    return distribution.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get team health score (0-100)
  int get teamHealthScore {
    int score = 0;

    // Base score for having team members
    if (isNotEmpty) score += 20;

    // Bonus for having all roles
    if (hasAllRoles) score += 40;

    // Bonus for balanced team size
    if (teamSize >= 3 && teamSize <= 6) score += 20;

    // Penalty for role overlap
    if (hasRoleOverlap) score -= 10;

    // Bonus for having a leader
    if (leaders.isNotEmpty) score += 20;

    return score.clamp(0, 100);
  }

  /// Get team health status
  String get teamHealthStatus {
    final score = teamHealthScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
}
