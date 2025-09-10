import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/power_sync_service.dart';
import '../services/agora_service.dart';
import '../providers/supabase_auth_provider.dart';

enum CallScreenState {
  none,
  ringing,
  connected,
  ended,
}

class CallState {
  final CallScreenState screenState;
  final CallType? callType;
  final DateTime? startTime;
  final Duration? duration;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final List<String> participants;

  const CallState({
    this.screenState = CallScreenState.none,
    this.callType,
    this.startTime,
    this.duration,
    this.isMuted = false,
    this.isVideoEnabled = false,
    this.isScreenSharing = false,
    this.participants = const [],
  });

  CallState copyWith({
    CallScreenState? screenState,
    CallType? callType,
    DateTime? startTime,
    Duration? duration,
    bool? isMuted,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    List<String>? participants,
  }) {
    return CallState(
      screenState: screenState ?? this.screenState,
      callType: callType ?? this.callType,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      participants: participants ?? this.participants,
    );
  }

  bool get isCallActive =>
      screenState == CallScreenState.connected ||
      screenState == CallScreenState.ringing;
}

class ChatState {
  final ChatRoom? selectedChat;
  final List<ChatMessage> messages;
  final List<ChatParticipant> participants;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final CallState callState;
  final String? currentCallSessionId;

  const ChatState({
    this.selectedChat,
    this.messages = const [],
    this.participants = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
    this.callState = const CallState(),
    this.currentCallSessionId,
  });

  ChatState copyWith({
    ChatRoom? selectedChat,
    List<ChatMessage>? messages,
    List<ChatParticipant>? participants,
    bool? isLoading,
    String? error,
    bool? isTyping,
    CallState? callState,
    String? currentCallSessionId,
  }) {
    return ChatState(
      selectedChat: selectedChat ?? this.selectedChat,
      messages: messages ?? this.messages,
      participants: participants ?? this.participants,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isTyping: isTyping ?? this.isTyping,
      callState: callState ?? this.callState,
      currentCallSessionId: currentCallSessionId ?? this.currentCallSessionId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState()) {
    _chatService = ChatService.instance;
    _initializeStreams();
  }

  final Ref _ref;
  late final ChatService _chatService;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<List<ChatParticipant>>? _participantsSubscription;

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _participantsSubscription?.cancel();
    super.dispose();
  }

  void _initializeStreams() {
    // Initialize real-time streams when a chat is selected
  }

  String _generateCallSessionId(ChatRoom chatRoom) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final roomId = chatRoom.id;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return "call_${roomId}_${timestamp}_$random";
  }

  Future<void> selectChat(String chatId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cancel existing subscriptions
      await _messagesSubscription?.cancel();
      await _participantsSubscription?.cancel();

      // Get chat room
      final chatRoom = await _chatService.getChatRoom(chatId);
      if (chatRoom == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Chat room not found',
        );
        return;
      }

      // Get initial messages and participants
      final messages = await _chatService.getMessages(chatId);
      final participants = await _chatService.getParticipants(chatId);

      state = state.copyWith(
        selectedChat: chatRoom,
        messages: messages,
        participants: participants,
        isLoading: false,
      );

      // Set up real-time subscriptions
      _messagesSubscription = _chatService.watchMessages(chatId).listen(
        (messages) {
          state = state.copyWith(messages: messages);
        },
        onError: (error) {
          print('Error watching messages: $error');
        },
      );

      _participantsSubscription = _chatService.watchParticipants(chatId).listen(
        (participants) {
          state = state.copyWith(participants: participants);
        },
        onError: (error) {
          print('Error watching participants: $error');
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chat: $e',
      );
    }
  }

  Future<void> sendMessage(String content, MessageType type) async {
    if (state.selectedChat == null) return;

    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      await _chatService.sendMessage(
        roomId: state.selectedChat!.id,
        content: content,
        messageType: type,
        senderId: user.id,
        senderName: user.displayName ?? user.email ?? 'Unknown User',
        senderAvatar: user.avatarUrl,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to send message: $e');
    }
  }

  Future<void> createDirectChat(
      String otherUserId, String otherUserName) async {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final chatRoom = await _chatService.createChatRoom(
        name: otherUserName,
        roomType: ChatRoomType.direct,
        participantIds: [user.id, otherUserId],
        createdBy: user.id,
      );

      await selectChat(chatRoom.id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create chat: $e',
      );
    }
  }

  Future<void> createGroupChat({
    required String name,
    String? description,
    required List<String> participantIds,
  }) async {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final chatRoom = await _chatService.createChatRoom(
        name: name,
        description: description,
        roomType: ChatRoomType.group,
        participantIds: [user.id, ...participantIds],
        createdBy: user.id,
      );

      await selectChat(chatRoom.id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create group chat: $e',
      );
    }
  }

  Future<ChatRoom> createChatRoom({
    String? name,
    String? description,
    required ChatRoomType roomType,
    required List<String> participantIds,
  }) async {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) throw Exception('User not authenticated');

    try {
      final chatRoom = await _chatService.createChatRoom(
        name: name,
        description: description,
        roomType: roomType,
        participantIds: [user.id, ...participantIds],
        createdBy: user.id,
      );

      return chatRoom;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> addReaction(String messageId, String reaction) async {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      await _chatService.addReaction(messageId, user.id, reaction);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add reaction: $e');
    }
  }

  Future<void> removeReaction(String messageId, String reaction) async {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      await _chatService.removeReaction(messageId, user.id, reaction);
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove reaction: $e');
    }
  }

  Future<void> updateTypingStatus(bool isTyping) async {
    if (state.selectedChat == null) return;

    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      await _chatService.updateParticipantStatus(
        state.selectedChat!.id,
        user.id,
        isTyping: isTyping,
      );
    } catch (e) {
      print('Failed to update typing status: $e');
    }
  }

  Future<void> initiateCall(CallType callType) async {
    if (state.selectedChat == null) return;

    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      // Set initial ringing state
      state = state.copyWith(
        callState: CallState(
          screenState: CallScreenState.ringing,
          callType: callType,
          startTime: DateTime.now(),
          isVideoEnabled: callType == CallType.video,
          participants: state.participants.map((p) => p.id).toList(),
        ),
      );

      // Authenticate with backend first
      print('🔐 Authenticating with backend for call...');
      final token = await AgoraService.instance.authenticateWithBackend(
        email: user.email,
        displayName: user.displayName ?? user.email,
      );

      if (token == null) {
        throw Exception('Failed to authenticate with backend');
      }

      print('✅ Authentication successful, starting call...');

      // Start call session with AgoraService
      final callSession = await AgoraService.instance.startCall(
        chatRoomId: state.selectedChat!.id,
        callType: callType == CallType.video ? 'video' : 'voice',
      );
      
      // Update state with successful call session
      state = state.copyWith(
        currentCallSessionId: callSession.sessionId,
        callState: state.callState.copyWith(
          screenState: CallScreenState.connected,
        ),
      );

      // Send call invitation message to all participants
      await _sendCallInvitation(callSession.sessionId, callType, callSession.participants);

      print('✅ Call initiated successfully: ${callSession.sessionId}');
      
    } catch (e) {
      print('❌ Error initiating call: $e');
      state = state.copyWith(
        error: 'Failed to initiate call: $e',
        callState: const CallState(),
      );
    }
  }

  Future<void> _sendCallInvitation(
    String sessionId, 
    CallType callType, 
    List<String> participants
  ) async {
    if (state.selectedChat == null) return;

    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    // Create call invitation metadata
    final callInvitationData = {
      'type': 'call_invitation',
      'sessionId': sessionId,
      'callType': callType.toString(),
      'chatRoomId': state.selectedChat!.id,
      'initiatedBy': user.id,
      'initiatedByName': user.displayName ?? user.email ?? 'Unknown User',
      'participants': participants,
    };

    try {
      // Send special call invitation message
      await _chatService.sendMessage(
        roomId: state.selectedChat!.id,
        content: 'Call invitation: ${callType.name} call',
        messageType: MessageType.call,
        senderId: user.id,
        senderName: user.displayName ?? user.email ?? 'Unknown User',
        senderAvatar: user.avatarUrl,
        callType: callType,
        callStatus: CallStatus.answered,
        callParticipants: participants,
        aiContext: callInvitationData,
      );
    } catch (e) {
      print('Failed to send call invitation: $e');
    }
  }

  void connectCall() {
    if (state.callState.screenState != CallScreenState.ringing) return;

    state = state.copyWith(
      callState: state.callState.copyWith(
        screenState: CallScreenState.connected,
        startTime: DateTime.now(),
      ),
    );
  }

  void endCall() {
    if (!state.callState.isCallActive) return;

    final callDuration = state.callState.startTime != null
        ? DateTime.now().difference(state.callState.startTime!)
        : const Duration();

    // Add call message to chat history
    final callMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Call ended',
      messageType: MessageType.call,
      senderId: 'current_user',
      senderName: 'You',
      createdAt: DateTime.now(),
      callType: state.callState.callType,
      callStatus: CallStatus.answered,
      callDuration: callDuration,
      callParticipants: state.callState.participants,
    );

    state = state.copyWith(
      messages: [...state.messages, callMessage],
      callState: const CallState(screenState: CallScreenState.ended),
    );

    // Reset call state after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(
        callState: const CallState(),
      );
    });
  }

  void toggleMute() {
    if (!state.callState.isCallActive) return;

    state = state.copyWith(
      callState: state.callState.copyWith(
        isMuted: !state.callState.isMuted,
      ),
    );
  }

  void toggleVideo() {
    if (!state.callState.isCallActive) return;

    state = state.copyWith(
      callState: state.callState.copyWith(
        isVideoEnabled: !state.callState.isVideoEnabled,
      ),
    );
  }

  void toggleScreenShare() {
    if (!state.callState.isCallActive) return;

    state = state.copyWith(
      callState: state.callState.copyWith(
        isScreenSharing: !state.callState.isScreenSharing,
      ),
    );
  }

  Future<void> joinCall(String sessionId) async {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      // Set initial ringing state
      state = state.copyWith(
        callState: CallState(
          screenState: CallScreenState.ringing,
          callType: CallType.voice, // Will be updated with actual call type
          startTime: DateTime.now(),
          participants: state.participants.map((p) => p.id).toList(),
        ),
      );

      // Authenticate with backend first
      print('🔐 Authenticating with backend to join call...');
      final token = await AgoraService.instance.authenticateWithBackend(
        email: user.email,
        displayName: user.displayName ?? user.email,
      );

      if (token == null) {
        throw Exception('Failed to authenticate with backend');
      }

      print('✅ Authentication successful, joining call...');

      // Join call session with AgoraService
      final joinResponse = await AgoraService.instance.joinCall(
        sessionId: sessionId,
      );
      
      // Update state with successful call join
      state = state.copyWith(
        currentCallSessionId: sessionId,
        callState: state.callState.copyWith(
          screenState: CallScreenState.connected,
        ),
      );

      print('✅ Successfully joined call: $sessionId');
      
    } catch (e) {
      print('❌ Error joining call: $e');
      state = state.copyWith(
        error: 'Failed to join call: $e',
        callState: const CallState(),
      );
    }
  }

  void clearSelectedChat() {
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

// Helper providers
final selectedChatProvider = Provider<ChatRoom?>((ref) {
  return ref.watch(chatProvider).selectedChat;
});

final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});

final chatParticipantsProvider = Provider<List<ChatParticipant>>((ref) {
  return ref.watch(chatProvider).participants;
});

final callStateProvider = Provider<CallState>((ref) {
  return ref.watch(chatProvider).callState;
});

// Chat rooms list provider
final chatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null) return [];

  final chatService = ChatService.instance;
  return await chatService.getChatRooms(user.id);
});

// Real-time chat rooms stream provider
final chatRoomsStreamProvider = StreamProvider<List<ChatRoom>>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null) return Stream.value([]);

  final chatService = ChatService.instance;
  
  // Initialize real-time subscriptions when user is available
  chatService.initializeRealTimeSubscriptions(user.id);
  
  return chatService.watchChatRooms(user.id);
});

// Provider for getting initial chat rooms (fallback)
final chatRoomsInitialProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null) return [];

  final chatService = ChatService.instance;
  
  // Ensure PowerSync is connected and synced
  final powerSync = PowerSyncService.instance;
  if (powerSync.isInitialized) {
    await powerSync.triggerPostAuthSync();
  }
  
  return await chatService.getChatRoomsWithMetadata(user.id);
});
