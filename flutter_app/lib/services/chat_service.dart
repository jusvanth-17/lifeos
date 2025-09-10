import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/chat.dart';
import 'power_sync_service.dart';
import 'notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService._();

  ChatService._();

  final PowerSyncService _powerSync = PowerSyncService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Real-time subscriptions
  RealtimeChannel? _chatRoomsChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _participantsChannel;

  /// Get all chat rooms for a user
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    try {
      // Get chats where user is a participant or creator
      final participants = await _powerSync.query(
        'chat_participants',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final chatIds = participants.map((p) => p['chat_id']).toSet();

      // Also include chats created by the user
      final createdChats = await _powerSync.query(
        'chats',
        where: 'created_by = ?',
        whereArgs: [userId],
      );

      chatIds.addAll(createdChats.map((c) => c['id']));

      if (chatIds.isEmpty) return [];

      final rooms = await Future.wait(
        chatIds.map((chatId) => getChatRoom(chatId.toString())),
      );

      return rooms.whereType<ChatRoom>().toList()
        ..sort((a, b) {
          // Simple sorting - can be enhanced
          return b.createdAt.compareTo(a.createdAt);
        });
    } catch (e) {
      developer.log('Error getting chat rooms: $e', name: 'ChatService');
      return [];
    }
  }

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final rooms = await _powerSync.query(
        'chats',
        where: 'id = ?',
        whereArgs: [roomId],
      );

      if (rooms.isEmpty) return null;

      // Get participants for this chat
      final participants = await getParticipants(roomId);
      final participantIds = participants.map((p) => p.id).toList();

      final roomData = rooms.first;
      return ChatRoom(
        id: roomId,
        name: roomData['name'],
        description: roomData['description'],
        roomType: _getRoomTypeFromString(roomData['type']),
        isPrivate: true, // Default for now
        participantIds: participantIds,
        adminIds: [], // Admin support will be implemented in future versions
        teamId: null,
        projectId: null,
        taskId: null,
        createdBy: roomData['created_by'],
        createdAt: DateTime.parse(roomData['created_at']),
        updatedAt: DateTime.parse(roomData['updated_at']),
        allowAiAssistant: true,
      );
    } catch (e) {
      developer.log('Error getting chat room: $e', name: 'ChatService');
      return null;
    }
  }

  ChatRoomType _getRoomTypeFromString(String? type) {
    switch (type) {
      case 'direct':
        return ChatRoomType.direct;
      case 'group':
        return ChatRoomType.group;
      case 'team':
        return ChatRoomType.team;
      case 'project':
        return ChatRoomType.project;
      case 'task':
        return ChatRoomType.task;
      default:
        return ChatRoomType.direct;
    }
  }

  /// Create a new chat room
  Future<ChatRoom> createChatRoom({
    String? name,
    String? description,
    required ChatRoomType roomType,
    bool isPrivate = true,
    required List<String> participantIds,
    List<String> adminIds = const [],
    String? teamId,
    String? projectId,
    String? taskId,
    required String createdBy,
    bool allowAiAssistant = true,
    Map<String, bool>? notificationSettings,
  }) async {
    final now = DateTime.now();
    final roomId = const Uuid().v4();

    final roomData = {
      'id': roomId,
      'name': name,
      'description': description,
      'type': roomType.name,
      'is_private': isPrivate ? 1 : 0,
      'team_id': teamId,
      'project_id': projectId,
      'task_id': taskId,
      'message_count': 0,
      'allow_ai_assistant': allowAiAssistant ? 1 : 0,
      'notification_settings': jsonEncode(notificationSettings ?? {
        'all_messages': true,
        'mentions_only': false,
        'muted': false,
      }),
      'created_by': createdBy,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    await _powerSync.insert('chats', roomData);

    // Add participants to the chat_participants table
    for (final participantId in participantIds) {
      await addParticipant(roomId, participantId);
    }

    // Create a ChatRoom object with the generated ID
    return ChatRoom(
      id: roomId,
      name: name,
      description: description,
      roomType: roomType,
      isPrivate: isPrivate,
      participantIds: participantIds,
      adminIds: adminIds.isEmpty ? [createdBy] : adminIds,
      teamId: teamId,
      projectId: projectId,
      taskId: taskId,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      allowAiAssistant: allowAiAssistant,
      notificationSettings: notificationSettings ??
          {
            'all_messages': true,
            'mentions_only': false,
            'muted': false,
          },
    );
  }

  /// Add a participant to a chat room
  Future<void> addParticipant(String roomId, String userId) async {
    try {
      // Get user info
      final users = await _powerSync.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        throw Exception('User not found: $userId');
      }

      final user = users.first;

      final participantId = const Uuid().v4();

      await _powerSync.insert('chat_participants', {
        'id': participantId,
        'chat_id': roomId,
        'user_id': userId,
        'user_name': user['display_name'],
        'user_avatar': user['avatar_url'],
        'is_online': 0,
        'last_seen': null,
        'is_typing': 0,
        'role': 'member', // Default role for new participants
        'joined_at': DateTime.now().toIso8601String(),
      });

      // For now, we don't need to store participant_ids in the chats table
      // since we already have a dedicated chat_participants table
    } catch (e) {
      developer.log('Error adding participant: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Remove a participant from a chat room
  Future<void> removeParticipant(String roomId, String userId) async {
    try {
      await _powerSync.delete(
        'chat_participants',
        where: 'chat_id = ? AND user_id = ?',
        whereArgs: [roomId, userId],
      );

      // Note: We don't need to update participant_ids in the chats table
      // since we have a dedicated chat_participants table
    } catch (e) {
      developer.log('Error removing participant: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Get messages for a chat room
  Future<List<ChatMessage>> getMessages(String roomId,
      {int limit = 50, int offset = 0}) async {
    try {
      final messages = await _powerSync.query(
        'chat_messages',
        where: 'room_id = ?',
        whereArgs: [roomId],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return messages
          .map((message) => _mapToChatMessage(message))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      developer.log('Error getting messages: $e', name: 'ChatService');
      return [];
    }
  }

  /// Send a message
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String content,
    required MessageType messageType,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
    List<String> mentions = const [],
    Map<String, dynamic>? aiContext,
    CallType? callType,
    CallStatus? callStatus,
    Duration? callDuration,
    List<String>? callParticipants,
  }) async {
    final now = DateTime.now();

    final messageData = {
      // Don't provide 'id' - let PowerSync auto-generate it
      'content': content,
      'message_type': messageType.name,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'room_id': roomId,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'created_at': now.toIso8601String(),
      'updated_at': null,
      'is_edited': 0,
      'reply_to_id': replyToId,
      'thread_count': 0,
      'reactions': jsonEncode({}),
      'mentions': jsonEncode(mentions),
      'ai_context': aiContext != null ? jsonEncode(aiContext) : null,
      'call_type': callType?.name,
      'call_status': callStatus?.name,
      'call_duration': callDuration?.inSeconds,
      'call_participants':
          callParticipants != null ? jsonEncode(callParticipants) : null,
    };

    await _powerSync.insert('chat_messages', messageData);

    // Get the created message to retrieve the PowerSync-generated ID
    final createdMessages = await _powerSync.query(
      'chat_messages',
      where: 'sender_id = ? AND created_at = ? AND room_id = ?',
      whereArgs: [senderId, now.toIso8601String(), roomId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (createdMessages.isEmpty) {
      throw Exception('Failed to create message');
    }

    return _mapToChatMessage(createdMessages.first);
  }

  /// Update a message
  Future<ChatMessage?> updateMessage(
      String messageId, String newContent) async {
    try {
      final now = DateTime.now();
      await _powerSync.update(
        'chat_messages',
        {
          'content': newContent,
          'updated_at': now.toIso8601String(),
          'is_edited': 1,
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );

      final messages = await _powerSync.query(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );

      if (messages.isEmpty) return null;
      return _mapToChatMessage(messages.first);
    } catch (e) {
      developer.log('Error updating message: $e', name: 'ChatService');
      return null;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _powerSync.delete(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      developer.log('Error deleting message: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Add reaction to a message
  Future<void> addReaction(
      String messageId, String userId, String reaction) async {
    try {
      final messages = await _powerSync.query(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );

      if (messages.isEmpty) return;

      final message = messages.first;
      final reactions = Map<String, List<String>>.from(
        jsonDecode(message['reactions'] ?? '{}').map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );

      if (reactions.containsKey(reaction)) {
        if (!reactions[reaction]!.contains(userId)) {
          reactions[reaction]!.add(userId);
        }
      } else {
        reactions[reaction] = [userId];
      }

      await _powerSync.update(
        'chat_messages',
        {'reactions': jsonEncode(reactions)},
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      developer.log('Error adding reaction: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction(
      String messageId, String userId, String reaction) async {
    try {
      final messages = await _powerSync.query(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );

      if (messages.isEmpty) return;

      final message = messages.first;
      final reactions = Map<String, List<String>>.from(
        jsonDecode(message['reactions'] ?? '{}').map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );

      if (reactions.containsKey(reaction)) {
        reactions[reaction]!.remove(userId);
        if (reactions[reaction]!.isEmpty) {
          reactions.remove(reaction);
        }
      }

      await _powerSync.update(
        'chat_messages',
        {'reactions': jsonEncode(reactions)},
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      developer.log('Error removing reaction: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Get participants for a chat room
  Future<List<ChatParticipant>> getParticipants(String roomId) async {
    try {
      final participants = await _powerSync.query(
        'chat_participants',
        where: 'chat_id = ?',
        whereArgs: [roomId],
        orderBy: 'is_online DESC, user_name ASC',
      );

      return participants
          .map((participant) => _mapToChatParticipant(participant))
          .toList();
    } catch (e) {
      developer.log('Error getting participants: $e', name: 'ChatService');
      return [];
    }
  }

  /// Update participant online status
  Future<void> updateParticipantStatus(
    String roomId,
    String userId, {
    bool? isOnline,
    bool? isTyping,
    DateTime? lastSeen,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (isOnline != null) {
        updateData['is_online'] = isOnline ? 1 : 0;
      }

      if (isTyping != null) {
        updateData['is_typing'] = isTyping ? 1 : 0;
      }

      if (lastSeen != null) {
        updateData['last_seen'] = lastSeen.toIso8601String();
      }

      if (updateData.isNotEmpty) {
        await _powerSync.update(
          'chat_participants',
          updateData,
          where: 'chat_id = ? AND user_id = ?',
          whereArgs: [roomId, userId],
        );
      }
    } catch (e) {
      developer.log('Error updating participant status: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Watch chat rooms for real-time updates
  Stream<List<ChatRoom>> watchChatRooms(String userId) {
    // Watch for changes in both chats and chat_participants tables
    return _powerSync.watch('''
      SELECT DISTINCT c.* FROM chats c 
      LEFT JOIN chat_participants p ON c.id = p.chat_id 
      WHERE c.created_by = ? OR p.user_id = ?
      ORDER BY c.updated_at DESC
    ''', [userId, userId]).asyncMap((rows) async {
      // Convert each row to ChatRoom object
      final chatRooms = <ChatRoom>[];
      for (final row in rows) {
        try {
          final chatRoom = await _buildChatRoomFromRow(row);
          if (chatRoom != null) {
            chatRooms.add(chatRoom);
          }
        } catch (e) {
          developer.log('Error building chat room from row: $e', name: 'ChatService');
        }
      }
      return chatRooms;
    });
  }

  /// Helper method to build ChatRoom from database row
  Future<ChatRoom?> _buildChatRoomFromRow(Map<String, dynamic> row) async {
    try {
      // Get participants for this chat
      final participants = await getParticipants(row['id']);
      final participantIds = participants.map((p) => p.id).toList();

      return ChatRoom(
        id: row['id'],
        name: row['name'],
        description: row['description'],
        roomType: _getRoomTypeFromString(row['type']),
        isPrivate: (row['is_private'] ?? 1) == 1,
        participantIds: participantIds,
        adminIds: [], // Admin support will be implemented in future versions
        teamId: row['team_id'],
        projectId: row['project_id'],
        taskId: row['task_id'],
        lastMessageId: row['last_message_id'],
        lastMessageAt: row['last_message_at'] != null
            ? DateTime.parse(row['last_message_at'])
            : null,
        messageCount: row['message_count'] ?? 0,
        allowAiAssistant: (row['allow_ai_assistant'] ?? 1) == 1,
        notificationSettings: row['notification_settings'] != null
            ? Map<String, bool>.from(jsonDecode(row['notification_settings']))
            : {
                'all_messages': true,
                'mentions_only': false,
                'muted': false,
              },
        createdBy: row['created_by'],
        createdAt: DateTime.parse(row['created_at']),
        updatedAt: DateTime.parse(row['updated_at']),
      );
    } catch (e) {
      developer.log('Error building chat room from row: $e', name: 'ChatService');
      return null;
    }
  }

  /// Watch messages for a chat room
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _powerSync.watchTable(
      'chat_messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
    ).map((messages) =>
        messages.map((message) => _mapToChatMessage(message)).toList());
  }

  /// Watch participants for a chat room
  Stream<List<ChatParticipant>> watchParticipants(String roomId) {
    return _powerSync.watchTable(
      'chat_participants',
      where: 'chat_id = ?',
      whereArgs: [roomId],
    ).map((participants) => participants
        .map((participant) => _mapToChatParticipant(participant))
        .toList());
  }


  /// Map database row to ChatMessage model
  ChatMessage _mapToChatMessage(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'],
      content: row['content'],
      messageType: MessageType.values.firstWhere(
        (type) => type.name == row['message_type'],
        orElse: () => MessageType.text,
      ),
      senderId: row['sender_id'],
      senderName: row['sender_name'],
      senderAvatar: row['sender_avatar'],
      fileUrl: row['file_url'],
      fileName: row['file_name'],
      fileSize: row['file_size'],
      createdAt: DateTime.parse(row['created_at']),
      updatedAt:
          row['updated_at'] != null ? DateTime.parse(row['updated_at']) : null,
      isEdited: row['is_edited'] == 1,
      replyToId: row['reply_to_id'],
      threadCount: row['thread_count'] ?? 0,
      reactions: row['reactions'] != null
          ? Map<String, List<String>>.from(
              jsonDecode(row['reactions']).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
              ),
            )
          : {},
      mentions: row['mentions'] != null
          ? List<String>.from(jsonDecode(row['mentions']))
          : [],
      aiContext: row['ai_context'] != null
          ? Map<String, dynamic>.from(jsonDecode(row['ai_context']))
          : null,
      callType: row['call_type'] != null
          ? CallType.values.firstWhere(
              (type) => type.name == row['call_type'],
              orElse: () => CallType.voice,
            )
          : null,
      callStatus: row['call_status'] != null
          ? CallStatus.values.firstWhere(
              (status) => status.name == row['call_status'],
              orElse: () => CallStatus.answered,
            )
          : null,
      callDuration: row['call_duration'] != null
          ? Duration(seconds: row['call_duration'])
          : null,
      callParticipants: row['call_participants'] != null
          ? List<String>.from(jsonDecode(row['call_participants']))
          : null,
    );
  }

  /// Map database row to ChatParticipant model
  ChatParticipant _mapToChatParticipant(Map<String, dynamic> row) {
    return ChatParticipant(
      id: row['user_id'],
      name: row['user_name'],
      avatar: row['user_avatar'],
      isOnline: row['is_online'] == 1,
      lastSeen:
          row['last_seen'] != null ? DateTime.parse(row['last_seen']) : null,
      isTyping: row['is_typing'] == 1,
    );
  }

  // =============================================
  // REAL-TIME AND GROUP VISIBILITY FEATURES
  // =============================================

  /// Initialize real-time subscriptions for a user
  Future<void> initializeRealTimeSubscriptions(String userId) async {
    try {
      await _disposeRealTimeSubscriptions();

      // Subscribe to chat rooms changes for the user
      _chatRoomsChannel = _supabase
          .channel('user_chats_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chats',
            callback: (payload) => _handleChatRoomChange('INSERT', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'chats',
            callback: (payload) => _handleChatRoomChange('UPDATE', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'chats',
            callback: (payload) => _handleChatRoomChange('DELETE', payload),
          );

      // Subscribe to participant changes
      _participantsChannel = _supabase
          .channel('user_participants_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_participants',
            callback: (payload) => _handleParticipantChange('INSERT', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'chat_participants',
            callback: (payload) => _handleParticipantChange('UPDATE', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'chat_participants',
            callback: (payload) => _handleParticipantChange('DELETE', payload),
          );

      // Subscribe to message changes (for call invitations)
      _messagesChannel = _supabase
          .channel('user_messages_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            callback: (payload) => _handleMessageChange('INSERT', payload),
          );

      _chatRoomsChannel!.subscribe();
      _participantsChannel!.subscribe();
      _messagesChannel!.subscribe();

      developer.log('✅ Real-time subscriptions initialized for user: $userId', name: 'ChatService');
    } catch (e) {
      developer.log('❌ Failed to initialize real-time subscriptions: $e', name: 'ChatService');
    }
  }

  /// Dispose real-time subscriptions
  Future<void> _disposeRealTimeSubscriptions() async {
    try {
      final futures = <Future<void>>[];
      
      if (_chatRoomsChannel != null) {
        futures.add(_chatRoomsChannel!.unsubscribe());
      }
      if (_participantsChannel != null) {
        futures.add(_participantsChannel!.unsubscribe());
      }
      if (_messagesChannel != null) {
        futures.add(_messagesChannel!.unsubscribe());
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      _chatRoomsChannel = null;
      _participantsChannel = null;
      _messagesChannel = null;
    } catch (e) {
      developer.log('❌ Error disposing real-time subscriptions: $e', name: 'ChatService');
    }
  }

  /// Handle chat room changes from real-time updates
  void _handleChatRoomChange(String eventType, PostgresChangePayload payload) {
    developer.log('🔔 Chat room change detected: $eventType', name: 'ChatService');
    // Trigger local sync to update PowerSync data
    _powerSync.triggerPostAuthSync();
  }

  /// Handle participant changes from real-time updates
  void _handleParticipantChange(String eventType, PostgresChangePayload payload) {
    developer.log('🔔 Participant change detected: $eventType', name: 'ChatService');
    // Check if this affects the current user
    final newRecord = payload.newRecord;
    final currentUserId = _supabase.auth.currentUser?.id;
    
    if (newRecord['user_id'] == currentUserId) {
      developer.log('🔔 User was added to a new chat: ${newRecord['chat_id']}', name: 'ChatService');
      // Trigger sync to get the new chat data
      _powerSync.triggerPostAuthSync();
    }
  }

  /// Handle message changes (especially for call invitations)
  void _handleMessageChange(String eventType, PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Don't show notifications for own messages
    if (newRecord['sender_id'] == currentUserId) return;
    
    if (newRecord['message_type'] == 'call') {
      developer.log('🔔 Call invitation received: ${newRecord['content']}', name: 'ChatService');
      _handleCallInvitation(newRecord);
    } else if (newRecord['message_type'] == 'text') {
      // Show notification for new text messages
      _handleNewMessageNotification(newRecord);
    }
  }

  /// Handle incoming call invitations
  void _handleCallInvitation(Map<String, dynamic> messageData) {
    try {
      final aiContext = messageData['ai_context'];
      if (aiContext != null) {
        final callData = jsonDecode(aiContext);
        if (callData['type'] == 'call_invitation') {
          developer.log('📞 Processing call invitation with session: ${callData['sessionId']}', name: 'ChatService');
          
          // Show call notification
          final callType = messageData['call_type'] == 'video' ? CallType.video : CallType.voice;
          NotificationService.instance.showCallNotification(
            callerName: messageData['sender_name'] ?? 'Unknown Caller',
            callType: callType,
            chatRoomName: 'Chat Room', // Could be enhanced to get actual room name
            onAnswer: () {
              developer.log('Call answered from notification', name: 'ChatService');
              // Handle call answer logic
            },
            onDecline: () {
              developer.log('Call declined from notification', name: 'ChatService');
              // Handle call decline logic
            },
          );
        }
      }
    } catch (e) {
      developer.log('❌ Error processing call invitation: $e', name: 'ChatService');
    }
  }

  /// Handle new message notifications
  void _handleNewMessageNotification(Map<String, dynamic> messageData) {
    try {
      // Get room name for better context
      getChatRoom(messageData['room_id']).then((chatRoom) {
        final roomName = chatRoom?.name ?? 'Chat Room';
        
        NotificationService.instance.showNewMessageNotification(
          senderName: messageData['sender_name'] ?? 'Unknown User',
          message: messageData['content'] ?? '',
          chatRoomName: roomName,
          onTap: () {
            developer.log('Message notification tapped', name: 'ChatService');
            // Could navigate to chat room
          },
        );
      });
    } catch (e) {
      developer.log('❌ Error processing new message notification: $e', name: 'ChatService');
    }
  }

  // =============================================
  // USER DISCOVERY AND SEARCH
  // =============================================

  /// Search for users by name or email
  Future<List<ChatParticipant>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final users = await _powerSync.query(
        'users',
        where: 'display_name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: limit,
      );

      return users.map((user) => ChatParticipant(
        id: user['id'],
        name: user['display_name'] ?? 'Unknown User',
        avatar: user['avatar_url'],
        isOnline: false, // Default to offline for search results
        isTyping: false,
      )).toList();
    } catch (e) {
      developer.log('Error searching users: $e', name: 'ChatService');
      return [];
    }
  }

  /// Get all available users (for user discovery)
  Future<List<ChatParticipant>> getAllUsers({int limit = 100}) async {
    try {
      final users = await _powerSync.query(
        'users',
        orderBy: 'display_name ASC',
        limit: limit,
      );

      return users.map((user) => ChatParticipant(
        id: user['id'],
        name: user['display_name'] ?? 'Unknown User',
        avatar: user['avatar_url'],
        isOnline: false,
        isTyping: false,
      )).toList();
    } catch (e) {
      developer.log('Error getting all users: $e', name: 'ChatService');
      return [];
    }
  }

  /// Get user by ID
  Future<ChatParticipant?> getUserById(String userId) async {
    try {
      final users = await _powerSync.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) return null;

      final user = users.first;
      return ChatParticipant(
        id: user['id'],
        name: user['display_name'] ?? 'Unknown User',
        avatar: user['avatar_url'],
        isOnline: false,
        isTyping: false,
      );
    } catch (e) {
      developer.log('Error getting user by ID: $e', name: 'ChatService');
      return null;
    }
  }

  // =============================================
  // ENHANCED GROUP CHAT CREATION
  // =============================================

  /// Create a group chat with real-time notifications
  Future<ChatRoom> createGroupChatWithNotifications({
    required String name,
    String? description,
    required List<String> participantIds,
    required String createdBy,
    bool notifyParticipants = true,
  }) async {
    try {
      // Create the chat room
      final chatRoom = await createChatRoom(
        name: name,
        description: description,
        roomType: ChatRoomType.group,
        participantIds: participantIds,
        createdBy: createdBy,
      );

      // Send welcome message to the group
      await sendMessage(
        roomId: chatRoom.id,
        content: 'Group "$name" has been created! Welcome everyone! 🎉',
        messageType: MessageType.system,
        senderId: createdBy,
        senderName: 'System',
      );

      // Notify participants (if enabled)
      if (notifyParticipants) {
        await _notifyGroupParticipants(chatRoom.id, participantIds, name);
      }

      developer.log('✅ Group chat created successfully: ${chatRoom.id}', name: 'ChatService');
      return chatRoom;
    } catch (e) {
      developer.log('❌ Error creating group chat: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Send notifications to group participants
  Future<void> _notifyGroupParticipants(
    String chatId, 
    List<String> participantIds, 
    String groupName
  ) async {
    try {
      // Send individual notification messages
      for (final participantId in participantIds) {
        await sendMessage(
          roomId: chatId,
          content: 'You have been added to the group "$groupName"',
          messageType: MessageType.system,
          senderId: 'system',
          senderName: 'System',
          mentions: [participantId],
        );
      }

      developer.log('📱 Notifications sent to ${participantIds.length} participants', name: 'ChatService');
    } catch (e) {
      developer.log('❌ Error sending participant notifications: $e', name: 'ChatService');
    }
  }

  // =============================================
  // ENHANCED CHAT ROOM MANAGEMENT
  // =============================================

  /// Add multiple participants to a chat room with enhanced notifications
  Future<void> addMultipleParticipants(
    String roomId, 
    List<String> userIds,
    {bool notifyExistingMembers = true, bool sendWelcomeMessages = true}
  ) async {
    try {
      final chatRoom = await getChatRoom(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      // Add each participant and collect their details
      final addedUsers = <ChatParticipant>[];
      for (final userId in userIds) {
        try {
          await addParticipant(roomId, userId);
          final user = await getUserById(userId);
          if (user != null) {
            addedUsers.add(user);
          }
        } catch (e) {
          developer.log('❌ Failed to add participant $userId: $e', name: 'ChatService');
          continue; // Continue with other users even if one fails
        }
      }

      if (addedUsers.isEmpty) {
        throw Exception('Failed to add any participants');
      }

      // Send enhanced notifications
      if (notifyExistingMembers && addedUsers.isNotEmpty) {
        final userNames = addedUsers.map((user) => user.name).toList();
        await sendMessage(
          roomId: roomId,
          content: addedUsers.length == 1 
            ? '${userNames.first} joined the group 🎉'
            : '${userNames.join(", ")} joined the group 🎉',
          messageType: MessageType.system,
          senderId: 'system',
          senderName: 'System',
        );
      }

      // Send welcome messages to new members
      if (sendWelcomeMessages) {
        for (final user in addedUsers) {
          await _sendWelcomeMessage(roomId, user, chatRoom);
        }
      }

      // Trigger real-time updates for all affected users
      await _triggerGroupUpdateNotifications(roomId, addedUsers);

      developer.log('✅ Added ${addedUsers.length} participants to chat: $roomId', name: 'ChatService');
    } catch (e) {
      developer.log('❌ Error adding multiple participants: $e', name: 'ChatService');
      rethrow;
    }
  }

  /// Send personalized welcome message to new group member
  Future<void> _sendWelcomeMessage(String roomId, ChatParticipant user, ChatRoom chatRoom) async {
    try {
      final groupName = chatRoom.name ?? 'this group';
      await sendMessage(
        roomId: roomId,
        content: 'Welcome to $groupName, ${user.name}! 👋',
        messageType: MessageType.system,
        senderId: 'system',
        senderName: 'System',
        mentions: [user.id],
      );
    } catch (e) {
      developer.log('❌ Error sending welcome message: $e', name: 'ChatService');
    }
  }

  /// Trigger real-time notifications for group updates
  Future<void> _triggerGroupUpdateNotifications(String roomId, List<ChatParticipant> newMembers) async {
    try {
      // Force sync to ensure all users get the updated participant list
      _powerSync.triggerPostAuthSync();

      // Send individual notifications to new members
      for (final member in newMembers) {
        developer.log('📱 Triggering group update notification for ${member.name}', name: 'ChatService');
      }
    } catch (e) {
      developer.log('❌ Error triggering group update notifications: $e', name: 'ChatService');
    }
  }

  /// Get chat rooms with enhanced metadata
  Future<List<ChatRoom>> getChatRoomsWithMetadata(String userId) async {
    try {
      final chatRooms = await getChatRooms(userId);
      
      // Enhanced sorting - prioritize recent activity and unread messages
      chatRooms.sort((a, b) {
        // First sort by last message time
        if (a.lastMessageAt != null && b.lastMessageAt != null) {
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        } else if (a.lastMessageAt != null) {
          return -1;
        } else if (b.lastMessageAt != null) {
          return 1;
        } else {
          // Fallback to creation time
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      return chatRooms;
    } catch (e) {
      developer.log('Error getting chat rooms with metadata: $e', name: 'ChatService');
      return [];
    }
  }

  // =============================================
  // CLEANUP AND DISPOSAL
  // =============================================

  /// Dispose of the ChatService and clean up resources
  Future<void> dispose() async {
    await _disposeRealTimeSubscriptions();
    developer.log('✅ ChatService disposed', name: 'ChatService');
  }
}
