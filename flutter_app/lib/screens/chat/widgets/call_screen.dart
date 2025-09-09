import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/chat.dart';
import '../../../providers/chat_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;
  final List<ChatParticipant> participants;
  final VoidCallback onMinimize;

  const CallScreen({
    super.key,
    required this.chatRoom,
    required this.participants,
    required this.onMinimize,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callState = ref.watch(callStateProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with minimize and call info
              _buildCallHeader(context, theme, callState),

              // Main call area
              Expanded(
                child: _buildCallContent(context, theme, callState),
              ),

              // Call controls
              _buildCallControls(context, theme, callState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallHeader(
      BuildContext context, ThemeData theme, CallState callState) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          // Minimize button
          IconButton(
            onPressed: widget.onMinimize,
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Minimize',
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  _getCallTitle(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _getCallStatus(callState),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCallContent(
      BuildContext context, ThemeData theme, CallState callState) {
    if (callState.screenState == CallScreenState.ringing) {
      return _buildRingingContent(context, theme);
    } else {
      return _buildConnectedContent(context, theme, callState);
    }
  }

  Widget _buildRingingContent(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large avatar or group icon
          _buildLargeAvatar(theme),
          const SizedBox(height: AppConstants.spacingXL),

          // Ringing animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.phone,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          Text(
            'Calling...',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedContent(
      BuildContext context, ThemeData theme, CallState callState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large avatar or video placeholder
          _buildLargeAvatar(theme),
          const SizedBox(height: AppConstants.spacingXL),

          // Call duration
          _CallDurationTimer(startTime: callState.startTime),
          const SizedBox(height: AppConstants.spacingL),

          // Call type indicator
          if (callState.callType != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  callState.callType == CallType.video
                      ? Icons.videocam
                      : Icons.phone,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  callState.callType == CallType.video
                      ? 'Video Call'
                      : 'Voice Call',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLargeAvatar(ThemeData theme) {
    if (widget.chatRoom.isDirectChat && widget.participants.isNotEmpty) {
      final participant = widget.participants.first;
      return CircleAvatar(
        radius: 80,
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          participant.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // Group call
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.secondary,
        ),
        child: Icon(
          Icons.group,
          size: 80,
          color: theme.colorScheme.onSecondary,
        ),
      );
    }
  }

  Widget _buildCallControls(
      BuildContext context, ThemeData theme, CallState callState) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            context,
            theme,
            icon: callState.isMuted ? Icons.mic_off : Icons.mic,
            isActive: callState.isMuted,
            onPressed: () => ref.read(chatProvider.notifier).toggleMute(),
            tooltip: callState.isMuted ? 'Unmute' : 'Mute',
          ),

          // Video toggle (only show if video call or can be enabled)
          if (callState.callType == CallType.video || callState.isVideoEnabled)
            _buildControlButton(
              context,
              theme,
              icon: callState.isVideoEnabled
                  ? Icons.videocam
                  : Icons.videocam_off,
              isActive: !callState.isVideoEnabled,
              onPressed: () => ref.read(chatProvider.notifier).toggleVideo(),
              tooltip:
                  callState.isVideoEnabled ? 'Turn off video' : 'Turn on video',
            ),

          // Screen share button
          // _buildControlButton(
          //   context,
          //   theme,
          //   icon: callState.isScreenSharing
          //       ? Icons.stop_screen_share
          //       : Icons.screen_share,
          //   isActive: callState.isScreenSharing,
          //   onPressed: () =>
          //       ref.read(chatProvider.notifier).toggleScreenShare(),
          //   tooltip:
          //       callState.isScreenSharing ? 'Stop sharing' : 'Share screen',
          // ),

          // End call button
          _buildControlButton(
            context,
            theme,
            icon: Icons.call_end,
            isDestructive: true,
            onPressed: () => ref.read(chatProvider.notifier).endCall(),
            tooltip: 'End call',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    Color backgroundColor;
    Color iconColor;

    if (isDestructive) {
      backgroundColor = Colors.red;
      iconColor = Colors.white;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.onPrimary;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  String _getCallTitle() {
    if (widget.chatRoom.isDirectChat && widget.participants.isNotEmpty) {
      return widget.participants.first.name;
    } else if (widget.chatRoom.name != null) {
      return widget.chatRoom.name!;
    } else {
      return 'Group Call';
    }
  }

  String _getCallStatus(CallState callState) {
    switch (callState.screenState) {
      case CallScreenState.ringing:
        return 'Ringing...';
      case CallScreenState.connected:
        return 'Connected';
      case CallScreenState.ended:
        return 'Call ended';
      default:
        return '';
    }
  }
}

class _CallDurationTimer extends ConsumerStatefulWidget {
  final DateTime? startTime;

  const _CallDurationTimer({this.startTime});

  @override
  ConsumerState<_CallDurationTimer> createState() => _CallDurationTimerState();
}

class _CallDurationTimerState extends ConsumerState<_CallDurationTimer> {
  late Stream<Duration> _durationStream;

  @override
  void initState() {
    super.initState();
    _durationStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => widget.startTime != null
          ? DateTime.now().difference(widget.startTime!)
          : Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Duration>(
      stream: _durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;

        return Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w300,
            color: theme.colorScheme.onSurface,
          ),
        );
      },
    );
  }
}
