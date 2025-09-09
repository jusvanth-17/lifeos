import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../models/chat.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  // Global key for showing snackbars
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  /// Initialize the notification service with a scaffold messenger key
  static void initialize(GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) {
    _scaffoldMessengerKey = scaffoldMessengerKey;
  }

  /// Show a simple in-app notification using SnackBar
  void showInAppNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    try {
      if (_scaffoldMessengerKey?.currentState == null) {
        developer.log('ScaffoldMessenger not available for notification', name: 'NotificationService');
        return;
      }

      final context = _scaffoldMessengerKey!.currentState!.context;
      final theme = Theme.of(context);

      // Vibrate for important notifications
      if (type == NotificationType.message || type == NotificationType.call) {
        HapticFeedback.lightImpact();
      }

      final snackBar = SnackBar(
        content: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type, theme),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        backgroundColor: _getNotificationBackgroundColor(type, theme),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: onTap != null
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: onTap,
              )
            : null,
      );

      _scaffoldMessengerKey!.currentState!.showSnackBar(snackBar);

      developer.log('In-app notification shown: $title', name: 'NotificationService');
    } catch (e) {
      developer.log('Error showing in-app notification: $e', name: 'NotificationService');
    }
  }

  /// Show notification for new message
  void showNewMessageNotification({
    required String senderName,
    required String message,
    required String chatRoomName,
    VoidCallback? onTap,
  }) {
    showInAppNotification(
      title: '$senderName in $chatRoomName',
      message: message,
      type: NotificationType.message,
      onTap: onTap,
    );
  }

  /// Show notification for call invitation
  void showCallNotification({
    required String callerName,
    required CallType callType,
    required String chatRoomName,
    VoidCallback? onAnswer,
    VoidCallback? onDecline,
  }) {
    try {
      if (_scaffoldMessengerKey?.currentState == null) {
        developer.log('ScaffoldMessenger not available for call notification', name: 'NotificationService');
        return;
      }

      final context = _scaffoldMessengerKey!.currentState!.context;
      final theme = Theme.of(context);

      // Strong haptic feedback for calls
      HapticFeedback.heavyImpact();

      final callTypeText = callType == CallType.video ? 'Video call' : 'Voice call';

      final snackBar = SnackBar(
        content: Row(
          children: [
            Icon(
              callType == CallType.video ? Icons.videocam : Icons.call,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Incoming $callTypeText',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$callerName in $chatRoomName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (onDecline != null) ...[
              IconButton(
                onPressed: () {
                  _scaffoldMessengerKey!.currentState!.hideCurrentSnackBar();
                  onDecline();
                },
                icon: const Icon(Icons.call_end),
                color: Colors.red,
                tooltip: 'Decline',
              ),
            ],
            if (onAnswer != null) ...[
              IconButton(
                onPressed: () {
                  _scaffoldMessengerKey!.currentState!.hideCurrentSnackBar();
                  onAnswer();
                },
                icon: const Icon(Icons.call),
                color: Colors.green,
                tooltip: 'Answer',
              ),
            ],
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 10), // Longer duration for calls
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

      _scaffoldMessengerKey!.currentState!.showSnackBar(snackBar);

      developer.log('Call notification shown: $callerName ($callTypeText)', name: 'NotificationService');
    } catch (e) {
      developer.log('Error showing call notification: $e', name: 'NotificationService');
    }
  }

  /// Show notification for user joining/leaving chat
  void showParticipantNotification({
    required String userName,
    required String chatRoomName,
    required bool isJoining,
    VoidCallback? onTap,
  }) {
    final action = isJoining ? 'joined' : 'left';
    showInAppNotification(
      title: 'Chat Update',
      message: '$userName $action $chatRoomName',
      type: NotificationType.info,
      onTap: onTap,
    );
  }

  /// Show error notification
  void showErrorNotification({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    showInAppNotification(
      title: title,
      message: message,
      type: NotificationType.error,
      duration: const Duration(seconds: 6),
      onTap: onTap,
    );
  }

  /// Show success notification
  void showSuccessNotification({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    showInAppNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      duration: const Duration(seconds: 3),
      onTap: onTap,
    );
  }

  /// Clear all notifications
  void clearAllNotifications() {
    try {
      _scaffoldMessengerKey?.currentState?.clearSnackBars();
      developer.log('All notifications cleared', name: 'NotificationService');
    } catch (e) {
      developer.log('Error clearing notifications: $e', name: 'NotificationService');
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.call:
        return Icons.call;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.call:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getNotificationBackgroundColor(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue.shade700;
      case NotificationType.call:
        return Colors.green.shade700;
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.success:
        return Colors.green.shade700;
      case NotificationType.warning:
        return Colors.orange.shade700;
      case NotificationType.info:
      default:
        return theme.colorScheme.primary;
    }
  }
}

enum NotificationType {
  message,
  call,
  error,
  success,
  warning,
  info,
}
