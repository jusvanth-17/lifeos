import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/chat.dart';

class ChatHeader extends ConsumerWidget {
  final ChatRoom chatRoom;
  final List<ChatParticipant> participants;
  final Function(CallType) onCallPressed;

  const ChatHeader({
    super.key,
    required this.chatRoom,
    required this.participants,
    required this.onCallPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Chat Avatar/Icon
          _buildChatAvatar(context, theme),
          const SizedBox(width: AppConstants.spacingM),

          // Chat Info
          Expanded(
            child: _buildChatInfo(context, theme),
          ),

          // Action Buttons
          _buildActionButtons(context, theme),
        ],
      ),
    );
  }

  Widget _buildChatAvatar(BuildContext context, ThemeData theme) {
    if (chatRoom.isDirectChat && participants.isNotEmpty) {
      final participant = participants.first;
      return Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              participant.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (participant.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // Group chat avatar
      return CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.secondary,
        child: Icon(
          Icons.group,
          color: theme.colorScheme.onSecondary,
          size: 20,
        ),
      );
    }
  }

  Widget _buildChatInfo(BuildContext context, ThemeData theme) {
    final chatName = _getChatName();
    final statusText = _getStatusText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          chatName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (statusText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unified Call Button with Dropdown
        PopupMenuButton<CallType>(
          icon: const Icon(Icons.phone, size: 20),
          tooltip: 'Start Call',
          onSelected: (callType) => onCallPressed(callType),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: CallType.voice,
              child: Row(
                children: [
                  Icon(Icons.phone, size: 18),
                  SizedBox(width: 12),
                  Text('Voice Call'),
                ],
              ),
            ),
            // const PopupMenuItem(
            //   value: CallType.video,
            //   child: Row(
            //     children: [
            //       Icon(Icons.videocam, size: 18),
            //       SizedBox(width: 12),
            //       Text('Video Call'),
            //     ],
            //   ),
            // ),
          ],
        ),

        // More Options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'info':
                _showChatInfo(context);
                break;
              case 'search':
                _showSearchMessages(context);
                break;
              case 'mute':
                _toggleMute(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 12),
                  Text('Chat Info'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 18),
                  SizedBox(width: 12),
                  Text('Search Messages'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('Mute Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getChatName() {
    if (chatRoom.name != null) {
      return chatRoom.name!;
    }

    if (chatRoom.isDirectChat && participants.isNotEmpty) {
      return participants.last.name;
    }

    return 'Chat';
  }

  String _getStatusText() {
    if (chatRoom.isDirectChat && participants.isNotEmpty) {
      final participant = participants.first;
      if (participant.isTyping) {
        return 'typing...';
      } else if (participant.isOnline) {
        return 'online';
      } else if (participant.lastSeen != null) {
        return 'last seen ${_formatLastSeen(participant.lastSeen!)}';
      }
      return 'offline';
    } else {
      // Group chat status
      final onlineCount = participants.where((p) => p.isOnline).length;
      final typingParticipants = participants.where((p) => p.isTyping).toList();

      if (typingParticipants.isNotEmpty) {
        if (typingParticipants.length == 1) {
          return '${typingParticipants.first.name} is typing...';
        } else {
          return '${typingParticipants.length} people are typing...';
        }
      }

      return '$onlineCount of ${participants.length} online';
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showChatInfo(BuildContext context) {
    // TODO: Implement chat info dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat info coming soon')),
    );
  }

  void _showSearchMessages(BuildContext context) {
    // TODO: Implement message search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message search coming soon')),
    );
  }

  void _toggleMute(BuildContext context) {
    // TODO: Implement mute toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mute toggle coming soon')),
    );
  }
}
