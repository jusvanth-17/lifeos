import '../chat.dart';

/// Extension methods for ChatMessage model to separate business logic from data
extension ChatMessageExtensions on ChatMessage {
  /// Check if this is a call message
  bool get isCallMessage => messageType == MessageType.call;

  /// Check if this is a system message
  bool get isSystemMessage => messageType == MessageType.system;

  /// Check if message has reactions
  bool get hasReactions => reactions.isNotEmpty;

  /// Check if message is a thread starter
  bool get isThreadStarter => threadCount > 0;

  /// Get formatted call duration
  String get formattedDuration {
    if (callDuration == null) return '';
    final minutes = callDuration!.inMinutes;
    final seconds = callDuration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if message is from AI
  bool get isFromAI => messageType == MessageType.aiResponse;

  /// Check if message has file attachment
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  /// Get file extension from filename
  String? get fileExtension {
    if (fileName == null) return null;
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : null;
  }

  /// Check if file is an image
  bool get isImageFile {
    final ext = fileExtension;
    return ext != null && ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// Check if file is a document
  bool get isDocumentFile {
    final ext = fileExtension;
    return ext != null && ['pdf', 'doc', 'docx', 'txt', 'md'].contains(ext);
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';
    final size = fileSize!;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Get total reaction count
  int get totalReactionCount {
    return reactions.values.fold(0, (sum, users) => sum + users.length);
  }

  /// Get most popular reaction
  String? get mostPopularReaction {
    if (reactions.isEmpty) return null;
    String? topReaction;
    int maxCount = 0;
    reactions.forEach((reaction, users) {
      if (users.length > maxCount) {
        maxCount = users.length;
        topReaction = reaction;
      }
    });
    return topReaction;
  }

  /// Check if user has reacted with specific emoji
  bool hasUserReacted(String userId, String reaction) {
    return reactions[reaction]?.contains(userId) ?? false;
  }

  /// Check if user has reacted to message at all
  bool hasUserReactedAny(String userId) {
    return reactions.values.any((users) => users.contains(userId));
  }

  /// Get call status display text
  String get callStatusText {
    if (callStatus == null) return '';
    switch (callStatus!) {
      case CallStatus.answered:
        return 'Call answered';
      case CallStatus.missed:
        return 'Missed call';
      case CallStatus.declined:
        return 'Call declined';
      case CallStatus.busy:
        return 'Busy';
    }
  }

  /// Get call type icon
  String get callTypeIcon {
    if (callType == null) return '📞';
    switch (callType!) {
      case CallType.voice:
        return '📞';
      case CallType.video:
        return '📹';
    }
  }

  /// Check if message mentions specific user
  bool mentionsUser(String userId) {
    return mentions.contains(userId);
  }

  /// Get message age in minutes
  int get ageInMinutes {
    return DateTime.now().difference(createdAt).inMinutes;
  }

  /// Check if message is recent (less than 5 minutes old)
  bool get isRecent => ageInMinutes < 5;

  /// Get formatted timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Check if message can be edited (within 15 minutes and not system/call)
  bool get canBeEdited {
    if (messageType == MessageType.system || messageType == MessageType.call) {
      return false;
    }
    return ageInMinutes <= 15;
  }

  /// Check if message can be deleted
  bool get canBeDeleted {
    return messageType != MessageType.system;
  }
}

/// Extension methods for ChatRoom model to separate business logic from data
extension ChatRoomExtensions on ChatRoom {
  /// Check if this is a direct chat
  bool get isDirectChat => roomType == ChatRoomType.direct;

  /// Check if this is a group chat
  bool get isGroupChat => roomType == ChatRoomType.group;

  /// Get participant count
  int get participantCount => participantIds.length;

  /// Check if room has recent activity (within 24 hours)
  bool get hasRecentActivity {
    if (lastMessageAt == null) return false;
    return DateTime.now().difference(lastMessageAt!).inHours < 24;
  }

  /// Check if room is active (has messages in last 7 days)
  bool get isActive {
    if (lastMessageAt == null) return false;
    return DateTime.now().difference(lastMessageAt!).inDays < 7;
  }

  /// Check if room is archived (no activity in 30 days)
  bool get isArchived {
    if (lastMessageAt == null) {
      return createdAt
          .isBefore(DateTime.now().subtract(const Duration(days: 30)));
    }
    return DateTime.now().difference(lastMessageAt!).inDays > 30;
  }

  /// Get room display name
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;

    switch (roomType) {
      case ChatRoomType.direct:
        return 'Direct Message';
      case ChatRoomType.group:
        return 'Group Chat';
      case ChatRoomType.team:
        return 'Team Chat';
      case ChatRoomType.project:
        return 'Project Chat';
      case ChatRoomType.task:
        return 'Task Discussion';
    }
  }

  /// Get room type icon
  String get typeIcon {
    switch (roomType) {
      case ChatRoomType.direct:
        return '💬';
      case ChatRoomType.group:
        return '👥';
      case ChatRoomType.team:
        return '🏢';
      case ChatRoomType.project:
        return '📁';
      case ChatRoomType.task:
        return '✅';
    }
  }

  /// Check if user is admin
  bool isUserAdmin(String userId) {
    return adminIds.contains(userId);
  }

  /// Check if user is participant
  bool isUserParticipant(String userId) {
    return participantIds.contains(userId);
  }

  /// Check if notifications are enabled for user
  bool areNotificationsEnabled(String userId) {
    // This would typically check user-specific settings
    return notificationSettings['all_messages'] == true &&
        notificationSettings['muted'] != true;
  }

  /// Check if only mentions are notified
  bool isMentionOnlyMode() {
    return notificationSettings['mentions_only'] == true;
  }

  /// Check if room is muted
  bool get isMuted => notificationSettings['muted'] == true;

  /// Get formatted last activity time
  String get formattedLastActivity {
    if (lastMessageAt == null) return 'No messages';

    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${lastMessageAt!.day}/${lastMessageAt!.month}/${lastMessageAt!.year}';
  }

  /// Get room age in days
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Check if room is new (created within 24 hours)
  bool get isNew => ageInDays == 0;

  /// Get activity level (0-3: inactive, low, medium, high)
  int get activityLevel {
    if (lastMessageAt == null) return 0;

    final daysSinceActivity = DateTime.now().difference(lastMessageAt!).inDays;
    final messagesPerDay = messageCount / (ageInDays + 1);

    if (daysSinceActivity > 7) return 0; // Inactive
    if (messagesPerDay < 1) return 1; // Low
    if (messagesPerDay < 10) return 2; // Medium
    return 3; // High
  }

  /// Get activity level text
  String get activityLevelText {
    switch (activityLevel) {
      case 0:
        return 'Inactive';
      case 1:
        return 'Low activity';
      case 2:
        return 'Medium activity';
      case 3:
        return 'High activity';
      default:
        return 'Unknown';
    }
  }
}

/// Extension methods for ChatParticipant model to separate business logic from data
extension ChatParticipantExtensions on ChatParticipant {
  /// Get formatted last seen time
  String get formattedLastSeen {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Last seen unknown';

    final now = DateTime.now();
    final diff = now.difference(lastSeen!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';

    return 'Last seen ${lastSeen!.day}/${lastSeen!.month}/${lastSeen!.year}';
  }

  /// Get online status indicator color
  String get statusColor {
    if (isOnline) return '#28A745'; // Green
    if (lastSeen == null) return '#6C757D'; // Gray

    final hoursSinceLastSeen = DateTime.now().difference(lastSeen!).inHours;
    if (hoursSinceLastSeen < 1) return '#FFC107'; // Yellow (recently online)
    return '#6C757D'; // Gray (offline)
  }

  /// Check if participant was recently online (within 1 hour)
  bool get wasRecentlyOnline {
    if (isOnline) return true;
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!).inHours < 1;
  }

  /// Get display name with typing indicator
  String get displayNameWithStatus {
    if (isTyping) return '$name (typing...)';
    return name;
  }

  /// Get initials for avatar fallback
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
