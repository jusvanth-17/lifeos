import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat.dart';
import '../../../providers/chat_provider.dart';

class CallInvitationWidget extends ConsumerStatefulWidget {
  final ChatMessage message;

  const CallInvitationWidget({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<CallInvitationWidget> createState() => _CallInvitationWidgetState();
}

class _CallInvitationWidgetState extends ConsumerState<CallInvitationWidget> {
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final callState = chatState.callState;
    
    // Extract call invitation data from aiContext
    final aiContext = widget.message.aiContext;
    final sessionId = aiContext?['sessionId'] as String?;
    final callType = aiContext?['callType'] as String?;
    final initiatedByName = aiContext?['initiatedByName'] as String?;
    final participants = (aiContext?['participants'] as List<dynamic>?)?.cast<String>() ?? [];

    // Parse call type
    final isVideoCall = callType?.contains('video') == true;
    final callIcon = isVideoCall ? Icons.videocam : Icons.phone;
    final callTypeText = isVideoCall ? 'Video Call' : 'Voice Call';

    // Check if call is still active (this would need backend integration to be accurate)
    final isCallActive = callState.isCallActive && chatState.currentCallSessionId == sessionId;
    final canJoin = sessionId != null && !isCallActive && !_isJoining;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with call icon and type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isVideoCall 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      callIcon,
                      color: isVideoCall ? Colors.blue : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callTypeText,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (initiatedByName != null)
                          Text(
                            'Initiated by $initiatedByName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Participants info
              if (participants.isNotEmpty)
                Text(
                  'Participants: ${participants.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCallActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Call',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (canJoin) ...[
                    TextButton(
                      onPressed: () => _declineCall(),
                      child: Text(
                        'Decline',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isJoining ? null : () => _joinCall(sessionId!),
                      icon: _isJoining 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(callIcon),
                      label: Text(_isJoining ? 'Joining...' : 'Join Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVideoCall ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ]
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Call Ended',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _formatTime(widget.message.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinCall(String sessionId) async {
    setState(() {
      _isJoining = true;
    });

    try {
      // Extract call type from aiContext
      final aiContext = widget.message.aiContext;
      final callTypeString = aiContext?['callType'] as String?;
      final callType = callTypeString?.contains('video') == true ? CallType.video : CallType.voice;
      
      await ref.read(chatProvider.notifier).joinCall(
        sessionId, 
        context: context, 
        callType: callType,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joining call...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _declineCall() {
    // Show a simple snackbar for now - in a real app you'd send a decline signal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call declined'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
