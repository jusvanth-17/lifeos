import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'secondary_sidebars/dashboard_secondary_sidebar.dart';
import 'secondary_sidebars/goals_secondary_sidebar.dart';
import 'secondary_sidebars/tasks_secondary_sidebar.dart';
import 'secondary_sidebars/chats_secondary_sidebar.dart';
import 'secondary_sidebars/documents_secondary_sidebar.dart';
import 'secondary_sidebars/ai_assistant_secondary_sidebar.dart';

class SecondarySidebar extends ConsumerWidget {
  final String activeFeature;
  final String? activeSubFeature;

  const SecondarySidebar({
    super.key,
    required this.activeFeature,
    this.activeSubFeature,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: _buildSecondarySidebarContent(context, theme, ref),
    );
  }

  Widget _buildSecondarySidebarContent(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    switch (activeFeature) {
      case AppConstants.navDashboard:
        return DashboardSecondarySidebar(
          activeSubFeature: activeSubFeature,
        );
      case AppConstants.navGoals:
        return const GoalsSecondarySidebar();
      case AppConstants.navTasks:
        return const TasksSecondarySidebar();
      case AppConstants.navChats:
        return const ChatsSecondarySidebar();
      case AppConstants.navDocuments:
        return const DocumentsSecondarySidebar();
      case AppConstants.navAIAssistant:
        return const AIAssistantSecondarySidebar();
      default:
        return _buildDefaultContent(theme);
    }
  }

  Widget _buildDefaultContent(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Select a feature',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
