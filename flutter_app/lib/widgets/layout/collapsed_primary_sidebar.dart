import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../providers/navigation_provider.dart';

class CollapsedPrimarySidebar extends ConsumerWidget {
  const CollapsedPrimarySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusMode = ref.watch(focusModeProvider);
    final authState = ref.watch(authProvider);
    final navigationState = ref.watch(navigationProvider);
    final user = authState.user;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header with logo
          _buildHeader(context, theme, ref),

          // Navigation Items
          Expanded(
            child: _buildNavigation(context, theme, navigationState, ref),
          ),

          // User Profile Section
          _buildUserProfile(context, theme, user),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.onPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(
    BuildContext context,
    ThemeData theme,
    NavigationState navigationState,
    WidgetRef ref,
  ) {
    final navigationItems = _getNavigationItems();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
      children: [
        for (final item in navigationItems)
          _buildNavigationItem(context, theme, item, navigationState, ref),
      ],
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    ThemeData theme,
    NavigationItem item,
    NavigationState navigationState,
    WidgetRef ref,
  ) {
    final isSelected = navigationState.activeFeature == item.feature;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      child: Tooltip(
        message: item.label,
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Update navigation state
              final defaultSubFeature = ref
                  .read(navigationProvider.notifier)
                  .getDefaultSubFeature(item.feature);
              ref.read(navigationProvider.notifier).setActiveFeature(
                    item.feature,
                    subFeature: defaultSubFeature,
                  );

              // Navigate to route
              context.go(item.route);
            },
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, ThemeData theme, user) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Tooltip(
        message: user?.displayName ?? 'User Profile',
        child: CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  List<NavigationItem> _getNavigationItems() {
    return [
      NavigationItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        feature: AppConstants.navDashboard,
        route: '/home',
      ),
      NavigationItem(
        icon: Icons.flag,
        label: 'OKR Goals',
        feature: AppConstants.navGoals,
        route: '/goals',
      ),
      NavigationItem(
        icon: Icons.task_alt,
        label: 'Tasks',
        feature: AppConstants.navTasks,
        route: '/tasks',
      ),
      NavigationItem(
        icon: Icons.chat,
        label: 'Chats',
        feature: AppConstants.navChats,
        route: '/chats',
      ),
      NavigationItem(
        icon: Icons.description,
        label: 'Documents',
        feature: AppConstants.navDocuments,
        route: '/documents',
      ),
      NavigationItem(
        icon: Icons.smart_toy,
        label: 'AI Assistant',
        feature: AppConstants.navAIAssistant,
        route: '/ai-assistant',
      ),
    ];
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String feature;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.feature,
    required this.route,
  });
}
