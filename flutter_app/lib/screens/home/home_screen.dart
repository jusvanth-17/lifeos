import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/layout/four_panel_layout.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/focus_mode_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final focusMode = ref.watch(focusModeProvider);
    final navigationState = ref.watch(navigationProvider);
    final selectedChat = ref.watch(selectedChatProvider);
    final user = authState.user;

    // Show chat detail screen when in chats section
    if (navigationState.activeFeature == AppConstants.navChats) {
      return FourPanelLayout(
        title: selectedChat?.name ?? 'Chats',
        actions: selectedChat != null
            ? [
                IconButton(
                  onPressed: () {
                    ref.read(chatProvider.notifier).clearSelectedChat();
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Close Chat',
                ),
              ]
            : null,
        child: const ChatDetailScreen(),
      );
    }

    return FourPanelLayout(
      title: 'Dashboard',
      actions: [
        // Focus Mode Indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: FocusModeTheme.getPrimaryColor(focusMode).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FocusModeTheme.getModeIcon(focusMode),
                size: 16,
                color: FocusModeTheme.getPrimaryColor(focusMode),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                FocusModeTheme.getModeName(focusMode),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusModeTheme.getPrimaryColor(focusMode),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),

        // Theme Toggle
        IconButton(
          onPressed: () => ref.read(themeProvider.notifier).toggleBrightness(),
          icon: Icon(
            Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          tooltip: 'Toggle Theme',
        ),
        const SizedBox(width: AppConstants.spacingS),

        // Logout Button
        IconButton(
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/auth');
            }
          },
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, user, focusMode),
            const SizedBox(height: AppConstants.spacingXL),

            // Focus Mode Description
            _buildFocusModeDescription(context, focusMode),
            const SizedBox(height: AppConstants.spacingXL),

            // Quick Actions
            _buildQuickActions(context, focusMode),
            const SizedBox(height: AppConstants.spacingXL),

            // Recent Activity
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, user, FocusMode focusMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: FocusModeTheme.getGradient(focusMode),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: FocusModeTheme.getElevationShadow(focusMode, 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${user?.displayName ?? 'User'}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            _getWelcomeMessage(focusMode),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeDescription(BuildContext context, FocusMode focusMode) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: FocusModeTheme.getPrimaryColor(focusMode).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Icon(
              FocusModeTheme.getModeIcon(focusMode),
              color: FocusModeTheme.getPrimaryColor(focusMode),
              size: 32,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${FocusModeTheme.getModeName(focusMode)} Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FocusModeTheme.getPrimaryColor(focusMode),
                      ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  FocusModeTheme.getModeDescription(focusMode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, FocusMode focusMode) {
    final quickActions = _getQuickActions(focusMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.spacingM,
            mainAxisSpacing: AppConstants.spacingM,
            childAspectRatio: 1.2,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _buildQuickActionCard(
              context,
              icon: action.icon,
              title: action.title,
              subtitle: action.subtitle,
              color: action.color,
              onTap: () => context.go(action.route),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Start by creating a task or project to see your activity here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWelcomeMessage(FocusMode focusMode) {
    switch (focusMode) {
      case FocusMode.me:
        return 'Ready to boost your personal productivity today?';
      case FocusMode.work:
        return 'Let\'s collaborate and get things done together!';
      case FocusMode.community:
        return 'Time to connect and contribute to the community!';
    }
  }

  List<QuickAction> _getQuickActions(FocusMode focusMode) {
    switch (focusMode) {
      case FocusMode.me:
        return [
          QuickAction(
            icon: Icons.flag,
            title: 'Goals',
            subtitle: 'Set & track goals',
            color: FocusModeTheme.getPrimaryColor(focusMode),
            route: '/goals',
          ),
          QuickAction(
            icon: Icons.task_alt,
            title: 'Tasks',
            subtitle: 'Manage tasks',
            color: FocusModeTheme.getAccentColor(focusMode),
            route: '/tasks',
          ),
          QuickAction(
            icon: Icons.calendar_today,
            title: 'Calendar',
            subtitle: 'Schedule time',
            color: Colors.blue,
            route: '/calendar',
          ),
          QuickAction(
            icon: Icons.insights,
            title: 'Insights',
            subtitle: 'View progress',
            color: Colors.green,
            route: '/insights',
          ),
        ];
      case FocusMode.work:
        return [
          QuickAction(
            icon: Icons.folder,
            title: 'Projects',
            subtitle: 'Manage projects',
            color: FocusModeTheme.getPrimaryColor(focusMode),
            route: '/projects',
          ),
          QuickAction(
            icon: Icons.people,
            title: 'Team',
            subtitle: 'Collaborate',
            color: FocusModeTheme.getAccentColor(focusMode),
            route: '/team',
          ),
          QuickAction(
            icon: Icons.chat,
            title: 'Chat',
            subtitle: 'Team communication',
            color: Colors.purple,
            route: '/chat',
          ),
          QuickAction(
            icon: Icons.description,
            title: 'Documents',
            subtitle: 'Shared docs',
            color: Colors.orange,
            route: '/documents',
          ),
        ];
      case FocusMode.community:
        return [
          QuickAction(
            icon: Icons.public,
            title: 'Community',
            subtitle: 'Explore community',
            color: FocusModeTheme.getPrimaryColor(focusMode),
            route: '/community',
          ),
          QuickAction(
            icon: Icons.campaign,
            title: 'Quests',
            subtitle: 'Join quests',
            color: FocusModeTheme.getAccentColor(focusMode),
            route: '/quests',
          ),
          QuickAction(
            icon: Icons.forum,
            title: 'Discussions',
            subtitle: 'Join conversations',
            color: Colors.indigo,
            route: '/discussions',
          ),
          QuickAction(
            icon: Icons.volunteer_activism,
            title: 'Contribute',
            subtitle: 'Help others',
            color: Colors.pink,
            route: '/contribute',
          ),
        ];
    }
  }
}

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}
