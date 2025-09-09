
enum ChatRoomType {
  direct,
  group,
  team,
  project,
  task,
}

enum MessageType {
  text,
  file,
  image,
  system,
  aiResponse,
  call,
}

enum CallType {
  voice,
  video,
}

enum CallStatus {
  answered,
  missed,
  declined,
  busy,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType messageType;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final String? replyToId;
  final int threadCount;
  final Map<String, List<String>> reactions;
  final List<String> mentions;
  final Map<String, dynamic>? aiContext;

  // Call-specific fields
  final CallType? callType;
  final CallStatus? callStatus;
  final Duration? callDuration;
  final List<String>? callParticipants;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.messageType,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.replyToId,
    this.threadCount = 0,
    this.reactions = const {},
    this.mentions = const [],
    this.aiContext,
    this.callType,
    this.callStatus,
    this.callDuration,
    this.callParticipants,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? messageType,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? replyToId,
    int? threadCount,
    Map<String, List<String>>? reactions,
    List<String>? mentions,
    Map<String, dynamic>? aiContext,
    CallType? callType,
    CallStatus? callStatus,
    Duration? callDuration,
    List<String>? callParticipants,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      replyToId: replyToId ?? this.replyToId,
      threadCount: threadCount ?? this.threadCount,
      reactions: reactions ?? this.reactions,
      mentions: mentions ?? this.mentions,
      aiContext: aiContext ?? this.aiContext,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      callDuration: callDuration ?? this.callDuration,
      callParticipants: callParticipants ?? this.callParticipants,
    );
  }

  bool get isCallMessage => messageType == MessageType.call;
  bool get isSystemMessage => messageType == MessageType.system;
  bool get hasReactions => reactions.isNotEmpty;
  bool get isThreadStarter => threadCount > 0;

  String get formattedDuration {
    if (callDuration == null) return '';
    final minutes = callDuration!.inMinutes;
    final seconds = callDuration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class ChatRoom {
  final String id;
  final String? name;
  final String? description;
  final ChatRoomType roomType;
  final bool isPrivate;
  final List<String> participantIds;
  final List<String> adminIds;
  final String? teamId;
  final String? projectId;
  final String? taskId;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final int messageCount;
  final bool allowAiAssistant;
  final Map<String, bool> notificationSettings;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom({
    required this.id,
    this.name,
    this.description,
    required this.roomType,
    this.isPrivate = true,
    this.participantIds = const [],
    this.adminIds = const [],
    this.teamId,
    this.projectId,
    this.taskId,
    this.lastMessageId,
    this.lastMessageAt,
    this.messageCount = 0,
    this.allowAiAssistant = true,
    this.notificationSettings = const {
      'all_messages': true,
      'mentions_only': false,
      'muted': false,
    },
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    ChatRoomType? roomType,
    bool? isPrivate,
    List<String>? participantIds,
    List<String>? adminIds,
    String? teamId,
    String? projectId,
    String? taskId,
    String? lastMessageId,
    DateTime? lastMessageAt,
    int? messageCount,
    bool? allowAiAssistant,
    Map<String, bool>? notificationSettings,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      roomType: roomType ?? this.roomType,
      isPrivate: isPrivate ?? this.isPrivate,
      participantIds: participantIds ?? this.participantIds,
      adminIds: adminIds ?? this.adminIds,
      teamId: teamId ?? this.teamId,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      allowAiAssistant: allowAiAssistant ?? this.allowAiAssistant,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDirectChat => roomType == ChatRoomType.direct;
  bool get isGroupChat => roomType == ChatRoomType.group;
  int get participantCount => participantIds.length;
}

class ChatParticipant {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
  });

  ChatParticipant copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
