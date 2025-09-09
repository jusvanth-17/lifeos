import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import 'widgets/chat_header.dart';
import 'widgets/message_list.dart';
import 'widgets/message_input.dart';
import 'widgets/agora_call.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  bool _isCallMinimized = false;
  bool _isNavigatingToCall = false;

  @override
  Widget build(BuildContext context) {
    final selectedChat = ref.watch(selectedChatProvider);
    final messages = ref.watch(chatMessagesProvider);
    final participants = ref.watch(chatParticipantsProvider);
    final callState = ref.watch(callStateProvider);
    final chatState = ref.watch(chatProvider);

    if (selectedChat == null) {
      return _buildEmptyState(context);
    }

    // Navigate to CallPage when call is initiated
    if (callState.isCallActive && 
        chatState.currentCallSessionId != null && 
        !_isNavigatingToCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNavigatingToCall) {
          setState(() {
            _isNavigatingToCall = true;
          });
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallPage(
                sessionId: chatState.currentCallSessionId!,
                chatRoom: selectedChat,
                participants: participants,
                callType: callState.callType ?? CallType.voice,
              ),
            ),
          ).then((_) {
            // Call ended, reset navigation state
            if (mounted) {
              setState(() {
                _isNavigatingToCall = false;
              });
              // Reset call state
              ref.read(chatProvider.notifier).endCall();
            }
          });
        }
      });
    }

    // Reset navigation flag when call becomes inactive
    if (!callState.isCallActive && _isNavigatingToCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isNavigatingToCall = false;
          });
        }
      });
    }

    return Column(
      children: [
        // Chat Header
        ChatHeader(
          chatRoom: selectedChat,
          participants: participants,
          onCallPressed: (callType) {
            ref.read(chatProvider.notifier).initiateCall(callType);
          },
        ),

        // Messages List
        Expanded(
          child: MessageList(
            messages: messages,
            participants: participants,
          ),
        ),

        // Message Input
        MessageInput(
          onSendMessage: (content, type) {
            ref.read(chatProvider.notifier).sendMessage(content, type);
          },
        ),
      ],
    );
  }

  Widget _buildFloatingCallIndicator(
    BuildContext context,
    ChatRoom chatRoom,
    List<ChatParticipant> participants,
    CallState callState,
  ) {
    final theme = Theme.of(context);

    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isCallMinimized = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                callState.callType == CallType.video
                    ? Icons.videocam
                    : Icons.phone,
                color: theme.colorScheme.onPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to return to call',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Select a conversation',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Choose a chat from the sidebar to start messaging',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
