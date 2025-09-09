import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../services/user_service.dart';

class CreateChatScreen extends ConsumerStatefulWidget {
  const CreateChatScreen({super.key});

  @override
  ConsumerState<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends ConsumerState<CreateChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatNameController = TextEditingController();
  final List<User> _selectedUsers = [];
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isCreating = false;
  ChatRoomType _selectedChatType = ChatRoomType.group;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchUsers(_searchController.text);
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final userService = UserService.instance;
      final users = await userService.searchUsers(query);

      setState(() {
        _searchResults = users
            .where((user) =>
                !_selectedUsers.any((selected) => selected.id == user.id))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search users: $e')),
        );
      }
    }
  }

  void _addUser(User user) {
    setState(() {
      _selectedUsers.add(user);
      _searchResults.remove(user);
      _searchController.clear();
    });

    // Auto-set chat type based on number of participants
    if (_selectedUsers.length == 1) {
      setState(() {
        _selectedChatType = ChatRoomType.direct;
      });
    } else if (_selectedUsers.length > 1) {
      setState(() {
        _selectedChatType = ChatRoomType.group;
      });
    }
  }

  void _removeUser(User user) {
    setState(() {
      _selectedUsers.remove(user);
    });

    // Update chat type based on remaining participants
    if (_selectedUsers.length == 1) {
      setState(() {
        _selectedChatType = ChatRoomType.direct;
      });
    } else if (_selectedUsers.isEmpty) {
      setState(() {
        _selectedChatType = ChatRoomType.group;
      });
    }
  }

  Future<void> _createChat() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      String? chatName;
      if (_selectedChatType == ChatRoomType.group &&
          _chatNameController.text.isNotEmpty) {
        chatName = _chatNameController.text.trim();
      }

      final chatRoom = await ref.read(chatProvider.notifier).createChatRoom(
            name: chatName,
            roomType: _selectedChatType,
            participantIds: _selectedUsers.map((user) => user.id).toList(),
            description: _selectedChatType == ChatRoomType.direct
                ? null
                : 'Group chat with ${_selectedUsers.length} members',
          );

      if (mounted) {
        // Select the newly created chat
        ref.read(chatProvider.notifier).selectChat(chatRoom.id);
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        actions: [
          // Debug button for testing user sync
          IconButton(
            onPressed: () async {
              print('🔧 Manual sync debug triggered');

              // Show a snackbar to confirm button was pressed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔧 Debug triggered - check console logs'),
                  duration: Duration(seconds: 2),
                ),
              );

              try {
                await UserService.instance.debugUserSync();

                // Show results in a dialog
                if (mounted) {
                  final users = await UserService.instance.getAllUsers();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Debug Results'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Local users found: ${users.length}'),
                          const SizedBox(height: 8),
                          if (users.isNotEmpty) ...[
                            const Text('Users:'),
                            ...users.map((user) =>
                                Text('• ${user.displayName} (${user.email})')),
                          ] else
                            const Text('No users found locally'),
                          const SizedBox(height: 16),
                          const Text('Check console for detailed logs'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Debug failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug User Sync',
          ),
          TextButton(
            onPressed:
                _selectedUsers.isNotEmpty && !_isCreating ? _createChat : null,
            child: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Type Selection (for groups)
          if (_selectedUsers.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat Name (Optional)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  TextField(
                    controller: _chatNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter chat name...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Selected Users
          if (_selectedUsers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected (${_selectedUsers.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Wrap(
                    spacing: AppConstants.spacingS,
                    runSpacing: AppConstants.spacingS,
                    children: _selectedUsers.map((user) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            (user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : 'U'),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        label: Text(user.displayName.isNotEmpty ? user.displayName : 'Unknown User'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeUser(user),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Search Field
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
              ),
            ),
          ),

          // Search Results
          Expanded(
            child: _searchResults.isEmpty &&
                    _searchController.text.isNotEmpty &&
                    !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          'No users found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            (user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : 'U'),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user.displayName.isNotEmpty ? user.displayName : 'Unknown User'),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          onPressed: () => _addUser(user),
                          icon: const Icon(Icons.add),
                          tooltip: 'Add to chat',
                        ),
                        onTap: () => _addUser(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
