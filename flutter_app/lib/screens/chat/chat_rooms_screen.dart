import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../providers/supabase_auth_provider.dart';
import 'create_chat_screen.dart';
import 'chat_detail_screen.dart';

class ChatRoomsScreen extends ConsumerStatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  ConsumerState<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends ConsumerState<ChatRoomsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access chats'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateChatScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_comment),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Chat',
      ),
    );
  }

  Widget _buildChatList() {
    final chatRoomsAsync = ref.watch(chatRoomsStreamProvider);
    final initialChatRooms = ref.watch(chatRoomsInitialProvider);

    return chatRoomsAsync.when(
      loading: () {
        // Show initial data if available while loading stream
        return initialChatRooms.when(
          data: (chatRooms) => _buildChatRoomsList(chatRooms),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
      error: (error, stack) {
        // Fallback to initial provider if stream fails
        return initialChatRooms.when(
          data: (chatRooms) => _buildChatRoomsList(chatRooms),
          loading: () => _buildLoadingState(),
          error: (fallbackError, fallbackStack) => _buildErrorState(error.toString()),
        );
      },
      data: (chatRooms) => _buildChatRoomsList(chatRooms),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppConstants.spacingM),
          Text('Loading chats...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Failed to load chats',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh both providers
              ref.invalidate(chatRoomsStreamProvider);
              ref.invalidate(chatRoomsInitialProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomsList(List<ChatRoom> chatRooms) {
    if (chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh both providers
        ref.invalidate(chatRoomsStreamProvider);
        ref.invalidate(chatRoomsInitialProvider);
        
        // Wait a bit for the refresh to complete
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
        itemCount: chatRooms.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final chatRoom = chatRooms[index];
          return _buildChatRoomTile(chatRoom);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No chats yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Start a conversation by creating a new chat',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateChatScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom chatRoom) {
    final theme = Theme.of(context);
    final isGroup = chatRoom.roomType == ChatRoomType.group;
    final participantCount = chatRoom.participantIds.length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      leading: _buildChatAvatar(chatRoom),
      title: Text(
        chatRoom.name ?? _getChatDisplayName(chatRoom),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chatRoom.description != null) ...[
            Text(
              chatRoom.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          Row(
            children: [
              if (isGroup) ...[
                Icon(
                  Icons.group,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$participantCount members',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                chatRoom.roomType == ChatRoomType.direct
                    ? Icons.person
                    : Icons.group,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _getChatTypeLabel(chatRoom.roomType),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chatRoom.lastMessageAt != null) ...[
            Text(
              _formatLastMessageTime(chatRoom.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (chatRoom.messageCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chatRoom.messageCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        // Navigate to chat detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatDetailScreen(),
          ),
        );
        
        // Select this chat
        ref.read(chatProvider.notifier).selectChat(chatRoom.id);
      },
    );
  }

  Widget _buildChatAvatar(ChatRoom chatRoom) {
    final theme = Theme.of(context);
    final isGroup = chatRoom.roomType == ChatRoomType.group;

    return CircleAvatar(
      backgroundColor: theme.colorScheme.primary,
      child: Icon(
        isGroup ? Icons.group : Icons.person,
        color: theme.colorScheme.onPrimary,
        size: 20,
      ),
    );
  }

  String _getChatDisplayName(ChatRoom chatRoom) {
    if (chatRoom.name != null && chatRoom.name!.isNotEmpty) {
      return chatRoom.name!;
    }

    switch (chatRoom.roomType) {
      case ChatRoomType.direct:
        return 'Direct Chat';
      case ChatRoomType.group:
        return 'Group Chat';
      case ChatRoomType.team:
        return 'Team Chat';
      case ChatRoomType.project:
        return 'Project Chat';
      case ChatRoomType.task:
        return 'Task Chat';
    }
  }

  String _getChatTypeLabel(ChatRoomType roomType) {
    switch (roomType) {
      case ChatRoomType.direct:
        return 'Direct';
      case ChatRoomType.group:
        return 'Group';
      case ChatRoomType.team:
        return 'Team';
      case ChatRoomType.project:
        return 'Project';
      case ChatRoomType.task:
        return 'Task';
    }
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
