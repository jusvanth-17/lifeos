import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

class AIAssistantSecondarySidebar extends ConsumerWidget {
  const AIAssistantSecondarySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // AI Tools and Templates
        Expanded(
          child: _buildAITools(context, theme),
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
            Icons.smart_toy,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'AI Assistant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: New conversation
            },
            icon: Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'New Conversation',
          ),
        ],
      ),
    );
  }

  Widget _buildAITools(BuildContext context, ThemeData theme) {
    return ListView(
      children: [
        // Quick Actions
        _buildQuickActions(context, theme),

        const Divider(),

        // Chat History
        _buildChatHistory(context, theme),

        const Divider(),

        // AI Templates
        _buildAITemplates(context, theme),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final actions = [
      {
        'icon': Icons.lightbulb_outline,
        'label': 'Brainstorm Ideas',
        'color': Colors.orange
      },
      {'icon': Icons.edit, 'label': 'Write Content', 'color': Colors.blue},
      {'icon': Icons.code, 'label': 'Code Review', 'color': Colors.green},
      {
        'icon': Icons.analytics,
        'label': 'Analyze Data',
        'color': Colors.purple
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final action in actions)
          ListTile(
            dense: true,
            leading: Icon(
              action['icon'] as IconData,
              size: 20,
              color: action['color'] as Color,
            ),
            title: Text(
              action['label'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () {
              // TODO: Start AI conversation with template
            },
          ),
      ],
    );
  }

  Widget _buildChatHistory(BuildContext context, ThemeData theme) {
    final conversations = _getMockConversations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Text(
            'Recent Conversations',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final conversation in conversations)
          _buildConversationItem(context, theme, conversation),
      ],
    );
  }

  Widget _buildConversationItem(
      BuildContext context, ThemeData theme, MockConversation conversation) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.chat_bubble_outline,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        conversation.title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.preview,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        conversation.timestamp,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      onTap: () {
        // TODO: Open conversation
      },
    );
  }

  Widget _buildAITemplates(BuildContext context, ThemeData theme) {
    final templates = [
      {
        'icon': Icons.task_alt,
        'label': 'Task Planning',
        'description': 'Break down complex tasks'
      },
      {
        'icon': Icons.email,
        'label': 'Email Draft',
        'description': 'Professional email writing'
      },
      {
        'icon': Icons.article,
        'label': 'Meeting Summary',
        'description': 'Summarize meeting notes'
      },
      {
        'icon': Icons.bug_report,
        'label': 'Bug Analysis',
        'description': 'Debug code issues'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Text(
            'AI Templates',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final template in templates)
          ListTile(
            dense: true,
            leading: Icon(
              template['icon'] as IconData,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
            title: Text(
              template['label'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              template['description'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            onTap: () {
              // TODO: Use template
            },
          ),
      ],
    );
  }

  List<MockConversation> _getMockConversations() {
    return [
      MockConversation(
        title: 'Flutter Navigation Help',
        preview: 'How to implement nested routing...',
        timestamp: '2h ago',
      ),
      MockConversation(
        title: 'Project Planning',
        preview: 'Break down the lifeOS features...',
        timestamp: '1d ago',
      ),
      MockConversation(
        title: 'Code Review',
        preview: 'Review my authentication logic...',
        timestamp: '3d ago',
      ),
      MockConversation(
        title: 'UI Design Ideas',
        preview: 'Suggest improvements for dashboard...',
        timestamp: '1w ago',
      ),
    ];
  }
}

class MockConversation {
  final String title;
  final String preview;
  final String timestamp;

  MockConversation({
    required this.title,
    required this.preview,
    required this.timestamp,
  });
}
