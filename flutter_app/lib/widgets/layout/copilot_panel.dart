import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';

class CopilotPanel extends ConsumerStatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const CopilotPanel({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  ConsumerState<CopilotPanel> createState() => _CopilotPanelState();
}

class _CopilotPanelState extends ConsumerState<CopilotPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      content: AppConstants.aiWelcomeMessage,
      isFromUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response (replace with actual AI service call)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: _generateAIResponse(message),
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  String _generateAIResponse(String userMessage) {
    // Simple mock responses - replace with actual AI service
    final responses = [
      "I understand you're asking about '$userMessage'. Let me help you with that.",
      "That's an interesting question about '$userMessage'. Here's what I think...",
      "I can help you with '$userMessage'. Would you like me to create a task or goal for this?",
      "Based on your message about '$userMessage', I suggest we break this down into actionable steps.",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppConstants.fastAnimationDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusMode = ref.watch(focusModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(theme),

          // AI Suggestions (when collapsed)
          if (!widget.isExpanded) _buildCollapsedSuggestions(theme),

          // Chat Messages (when expanded)
          if (widget.isExpanded) ...[
            Expanded(child: _buildChatMessages(theme)),
            _buildMessageInput(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
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
          // Chotu Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Icon(
              Icons.smart_toy,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),

          if (widget.isExpanded) ...[
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConstants.aiAssistantName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'AI Assistant',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Toggle Button
          IconButton(
            onPressed: widget.onToggle,
            icon: Icon(
              widget.isExpanded ? Icons.close : Icons.chat,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: widget.isExpanded ? 'Minimize Copilot' : 'Expand Copilot',
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSuggestions(ThemeData theme) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        children: [
          _buildSuggestionChip(
            theme,
            Icons.add_task,
            'Create Task',
            () => _quickAction('create task'),
          ),
          const SizedBox(height: AppConstants.spacingS),
          _buildSuggestionChip(
            theme,
            Icons.schedule,
            'Schedule',
            () => _quickAction('schedule meeting'),
          ),
          const SizedBox(height: AppConstants.spacingS),
          _buildSuggestionChip(
            theme,
            Icons.lightbulb,
            'Ideas',
            () => _quickAction('brainstorm ideas'),
          ),
          const SizedBox(height: AppConstants.spacingS),
          _buildSuggestionChip(
            theme,
            Icons.analytics,
            'Insights',
            () => _quickAction('show insights'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessages(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(theme, message);
      },
    );
  }

  Widget _buildMessageBubble(ThemeData theme, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            // AI Avatar
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.onPrimary,
                size: 14,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: message.isFromUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusL).copyWith(
                  bottomLeft: message.isFromUser
                      ? const Radius.circular(AppConstants.radiusL)
                      : const Radius.circular(AppConstants.radiusS),
                  bottomRight: message.isFromUser
                      ? const Radius.circular(AppConstants.radiusS)
                      : const Radius.circular(AppConstants.radiusL),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: message.isFromUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: AppConstants.spacingS),
            // User Avatar
            CircleAvatar(
              radius: 12,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onSecondary,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask ${AppConstants.aiAssistantName}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                isDense: true,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(
              Icons.send,
              color: theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _quickAction(String action) {
    // Expand the panel and send the quick action
    if (!widget.isExpanded) {
      widget.onToggle();
    }

    setState(() {
      _messages.add(ChatMessage(
        content: action,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: _generateAIResponse(action),
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }
}

class ChatMessage {
  final String content;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isFromUser,
    required this.timestamp,
  });
}
