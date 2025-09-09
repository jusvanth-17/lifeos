import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/chat.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showAvatar;
  final Function(String) onReaction;
  final VoidCallback onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.showAvatar,
    required this.onReaction,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showAvatar) ...[
            _buildAvatar(theme),
            const SizedBox(width: AppConstants.spacingS),
          ] else if (!isCurrentUser) ...[
            const SizedBox(width: 40), // Space for avatar alignment
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser && showAvatar) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppConstants.spacingS, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: AppConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppConstants.radiusL),
                        topRight: const Radius.circular(AppConstants.radiusL),
                        bottomLeft: Radius.circular(
                          isCurrentUser
                              ? AppConstants.radiusL
                              : AppConstants.radiusS,
                        ),
                        bottomRight: Radius.circular(
                          isCurrentUser
                              ? AppConstants.radiusS
                              : AppConstants.radiusL,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToId != null)
                          _buildReplyPreview(theme),
                        _buildMessageContent(theme),
                        const SizedBox(height: 4),
                        _buildMessageFooter(theme),
                      ],
                    ),
                  ),
                ),
                if (message.hasReactions) ...[
                  const SizedBox(height: 4),
                  _buildReactions(theme),
                ],
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppConstants.spacingS),
            _buildMessageStatus(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.secondary,
      child: Text(
        message.senderName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.onSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: (isCurrentUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.surface)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border(
          left: BorderSide(
            color: isCurrentUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Replying to message...', // TODO: Get actual replied message
        style: theme.textTheme.bodySmall?.copyWith(
          color: isCurrentUser
              ? theme.colorScheme.onPrimary.withOpacity(0.8)
              : theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme) {
    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isCurrentUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        );

      case MessageType.file:
        return _buildFileMessage(theme);

      case MessageType.image:
        return _buildImageMessage(theme);

      default:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isCurrentUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _buildFileMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: (isCurrentUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.surface)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 20,
            color: isCurrentUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCurrentUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(
                    _formatFileSize(message.fileSize!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: (isCurrentUser
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant)
                          .withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 200,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: message.fileUrl != null
            ? Image.network(
                message.fileUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Image failed to load',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : SizedBox(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Image',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMessageFooter(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: (isCurrentUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant)
                .withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        if (message.isEdited) ...[
          const SizedBox(width: 4),
          Text(
            '• edited',
            style: theme.textTheme.bodySmall?.copyWith(
              color: (isCurrentUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant)
                  .withOpacity(0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageStatus(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.done_all, // TODO: Implement proper read status
          size: 16,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildReactions(ThemeData theme) {
    return Wrap(
      spacing: 4,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final userIds = entry.value;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: userIds.contains('current_user')
                ? Border.all(color: theme.colorScheme.primary, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              if (userIds.length > 1) ...[
                const SizedBox(width: 2),
                Text(
                  userIds.length.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement delete
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reaction'),
        content: Wrap(
          spacing: 8,
          children: reactions.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onReaction(emoji);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
