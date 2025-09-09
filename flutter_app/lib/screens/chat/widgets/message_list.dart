import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/chat.dart';
import 'message_bubble.dart';
import 'call_history_card.dart';

class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final List<ChatParticipant> participants;

  const MessageList({
    super.key,
    required this.messages,
    required this.participants,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppConstants.spacingM),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final message = widget.messages[index];
              final isLastMessage = index == widget.messages.length - 1;
              final showDateSeparator = _shouldShowDateSeparator(index);

              return Column(
                children: [
                  if (showDateSeparator)
                    _buildDateSeparator(context, message.createdAt),
                  _buildMessageWidget(context, message),
                  if (!isLastMessage)
                    const SizedBox(height: AppConstants.spacingS),
                ],
              );
            },
          ),
        ),
        _buildTypingIndicator(context),
      ],
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
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Start the conversation by sending a message',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(BuildContext context, ChatMessage message) {
    if (message.isCallMessage) {
      return CallHistoryCard(
        message: message,
        participants: widget.participants,
        onCallBack: () => _handleCallBack(message),
      );
    } else if (message.isSystemMessage) {
      return _buildSystemMessage(context, message);
    } else {
      return MessageBubble(
        message: message,
        isCurrentUser: message.senderId == 'current_user',
        showAvatar: _shouldShowAvatar(message),
        onReaction: (emoji) => _handleReaction(message, emoji),
        onReply: () => _handleReply(message),
      );
    }
  }

  Widget _buildSystemMessage(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final dateText = _formatDateSeparator(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Text(
            dateText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final typingParticipants =
        widget.participants.where((p) => p.isTyping).toList();

    if (typingParticipants.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    String typingText;

    if (typingParticipants.length == 1) {
      typingText = '${typingParticipants.first.name} is typing...';
    } else {
      typingText = '${typingParticipants.length} people are typing...';
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          const SizedBox(width: 48), // Avatar space
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingAnimation(theme),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  typingText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation(ThemeData theme) {
    return SizedBox(
      width: 24,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 600 + (index * 200)),
            curve: Curves.easeInOut,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;

    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];

    final currentDate = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );

    final previousDate = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );

    return currentDate != previousDate;
  }

  bool _shouldShowAvatar(ChatMessage message) {
    // Always show avatar for non-current user messages
    return message.senderId != 'current_user';
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleCallBack(ChatMessage callMessage) {
    // TODO: Implement call back functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call back functionality coming soon')),
    );
  }

  void _handleReaction(ChatMessage message, String emoji) {
    // TODO: Implement reaction functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $emoji reaction')),
    );
  }

  void _handleReply(ChatMessage message) {
    // TODO: Implement reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply functionality coming soon')),
    );
  }
}
