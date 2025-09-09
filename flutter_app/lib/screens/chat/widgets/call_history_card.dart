import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/chat.dart';

class CallHistoryCard extends StatelessWidget {
  final ChatMessage message;
  final List<ChatParticipant> participants;
  final VoidCallback onCallBack;

  const CallHistoryCard({
    super.key,
    required this.message,
    required this.participants,
    required this.onCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentUser = message.senderId == 'current_user';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(theme),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: _getCardColor(theme),
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(
                  color: _getBorderColor(theme),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCallHeader(theme),
                  const SizedBox(height: AppConstants.spacingS),
                  _buildCallDetails(theme),
                  if (_shouldShowCallBackButton()) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    _buildCallBackButton(theme),
                  ],
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppConstants.spacingS),
            _buildAvatar(theme),
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

  Widget _buildCallHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          _getCallIcon(),
          size: 20,
          color: _getCallIconColor(theme),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Text(
            _getCallTitle(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          _formatTime(message.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCallDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatusIcon(),
              size: 16,
              color: _getStatusColor(theme),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              _getStatusText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _getStatusColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message.callDuration != null) ...[
              const SizedBox(width: AppConstants.spacingS),
              Text(
                '• ${message.formattedDuration}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (_shouldShowParticipants()) ...[
          const SizedBox(height: AppConstants.spacingS),
          _buildParticipantsList(theme),
        ],
      ],
    );
  }

  Widget _buildParticipantsList(ThemeData theme) {
    final callParticipants = message.callParticipants ?? [];
    final participantNames =
        callParticipants.where((id) => id != 'current_user').map((id) {
      final participant = participants.firstWhere(
        (p) => p.id == id,
        orElse: () => ChatParticipant(id: id, name: 'Unknown'),
      );
      return participant.name;
    }).toList();

    if (participantNames.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Text(
            participantNames.join(', '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCallBackButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onCallBack,
        icon: Icon(
          message.callType == CallType.video ? Icons.videocam : Icons.phone,
          size: 18,
        ),
        label: Text(
          message.callType == CallType.video ? 'Video Call Back' : 'Call Back',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
        ),
      ),
    );
  }

  Color _getCardColor(ThemeData theme) {
    switch (message.callStatus) {
      case CallStatus.missed:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case CallStatus.declined:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      default:
        return theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }
  }

  Color _getBorderColor(ThemeData theme) {
    switch (message.callStatus) {
      case CallStatus.missed:
        return theme.colorScheme.error.withOpacity(0.3);
      case CallStatus.declined:
        return theme.colorScheme.error.withOpacity(0.3);
      default:
        return theme.colorScheme.outline.withOpacity(0.3);
    }
  }

  IconData _getCallIcon() {
    return message.callType == CallType.video ? Icons.videocam : Icons.phone;
  }

  Color _getCallIconColor(ThemeData theme) {
    switch (message.callStatus) {
      case CallStatus.missed:
      case CallStatus.declined:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getStatusIcon() {
    switch (message.callStatus) {
      case CallStatus.answered:
        return Icons.call_received;
      case CallStatus.missed:
        return Icons.call_received;
      case CallStatus.declined:
        return Icons.call_end;
      case CallStatus.busy:
        return Icons.phone_disabled;
      default:
        return Icons.call;
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (message.callStatus) {
      case CallStatus.answered:
        return theme.colorScheme.primary;
      case CallStatus.missed:
        return theme.colorScheme.error;
      case CallStatus.declined:
        return theme.colorScheme.error;
      case CallStatus.busy:
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getCallTitle() {
    final callTypeText =
        message.callType == CallType.video ? 'Video Call' : 'Voice Call';
    final isCurrentUser = message.senderId == 'current_user';

    if (isCurrentUser) {
      return 'Outgoing $callTypeText';
    } else {
      return 'Incoming $callTypeText';
    }
  }

  String _getStatusText() {
    switch (message.callStatus) {
      case CallStatus.answered:
        return 'Answered';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.busy:
        return 'Busy';
      default:
        return 'Unknown';
    }
  }

  bool _shouldShowParticipants() {
    final callParticipants = message.callParticipants ?? [];
    return callParticipants.length > 2; // Show for group calls
  }

  bool _shouldShowCallBackButton() {
    // Show call back button for missed calls or if it's not the current user's call
    return message.callStatus == CallStatus.missed ||
        message.senderId != 'current_user';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
