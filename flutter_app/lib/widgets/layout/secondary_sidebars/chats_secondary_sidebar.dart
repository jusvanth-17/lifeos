import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../models/chat.dart';
import '../../../screens/chat/create_chat_screen.dart';

class ChatsSecondarySidebar extends ConsumerWidget {
  const ChatsSecondarySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Search
        _buildSearch(context, theme),

        // Chat List
        Expanded(
          child: _buildChatList(context, theme, ref),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'Chats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateChatScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'New Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ThemeData theme, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsStreamProvider);
    final selectedChat = ref.watch(selectedChatProvider);
    final navigationState = ref.watch(navigationProvider);

    return chatRoomsAsync.when(
      data: (chatRooms) {
        // Auto-select first chat if we're in chats section, have chats, but no chat selected
        if (chatRooms.isNotEmpty &&
            selectedChat == null &&
            navigationState.activeFeature == AppConstants.navChats) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(chatProvider.notifier).selectChat(chatRooms.first.id);
          });
        }

        if (chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'No conversations yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Start a new chat to get started',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            return _buildChatRoomItem(context, theme, chatRoom, ref);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Failed to load chats',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatRoomItem(
      BuildContext context, ThemeData theme, ChatRoom chatRoom, WidgetRef ref) {
    // Get display name for the chat room
    String displayName = chatRoom.name ?? 'Unknown Chat';
    if (chatRoom.roomType == ChatRoomType.direct && chatRoom.name == null) {
      // For direct chats without a name, we could show participant names
      displayName = 'Direct Chat';
    }

    // Format last activity time
    String timeAgo =
        _formatTimeAgo(chatRoom.lastMessageAt ?? chatRoom.createdAt);

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Online indicator for direct chats
          if (chatRoom.roomType == ChatRoomType.direct)
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
      ),
      title: Text(
        displayName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.normal, // TODO: Add unread logic
        ),
      ),
      subtitle: Text(
        chatRoom.description ?? 'No recent messages',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          if (chatRoom.messageCount > 0) ...[
            const SizedBox(height: AppConstants.spacingXS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chatRoom.messageCount.toString(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        ref.read(chatProvider.notifier).selectChat(chatRoom.id);
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}
