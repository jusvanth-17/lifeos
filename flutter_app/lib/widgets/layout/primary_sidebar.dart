import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/focus_mode_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/supabase_auth_provider.dart';

class PrimarySidebar extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const PrimarySidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusMode = ref.watch(focusModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header with logo and toggle
          _buildHeader(context, theme, ref),

          // Focus Mode Selector
          if (isExpanded) _buildFocusModeSelector(context, theme, ref),

          // Navigation Sections
          Expanded(
            child: _buildNavigation(context, theme, focusMode),
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
          // Logo/App Icon
          Container(
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

          if (isExpanded) ...[
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                AppConstants.appName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],

          // Toggle Button
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              isExpanded ? Icons.menu_open : Icons.menu,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: isExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeSelector(
      BuildContext context, ThemeData theme, WidgetRef ref) {
    final currentMode = ref.watch(focusModeProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Mode',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Column(
              children: FocusMode.values.map((mode) {
                final isSelected = mode == currentMode;
                return _buildFocusModeItem(
                  context,
                  theme,
                  ref,
                  mode,
                  isSelected,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeItem(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    FocusMode mode,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeProvider.notifier).setFocusMode(mode),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? FocusModeTheme.getPrimaryColor(mode).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Row(
            children: [
              Icon(
                FocusModeTheme.getModeIcon(mode),
                size: 20,
                color: isSelected
                    ? FocusModeTheme.getPrimaryColor(mode)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  FocusModeTheme.getModeName(mode),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? FocusModeTheme.getPrimaryColor(mode)
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(
      BuildContext context, ThemeData theme, FocusMode focusMode) {
    final navigationItems = _getNavigationItems(focusMode);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
      children: [
        for (final section in navigationItems) ...[
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              child: Text(
                section.title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          for (final item in section.items)
            _buildNavigationItem(context, theme, item),
          const SizedBox(height: AppConstants.spacingM),
        ],
      ],
    );
  }

  Widget _buildNavigationItem(
      BuildContext context, ThemeData theme, NavigationItem item) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSelected = currentLocation.startsWith(item.route);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, ThemeData theme, user) {
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
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<NavigationSection> _getNavigationItems(FocusMode focusMode) {
    switch (focusMode) {
      case FocusMode.me:
        return [
          NavigationSection(
            title: 'EXPLORE',
            items: [
              NavigationItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                route: '/home',
              ),
              NavigationItem(
                icon: Icons.flag,
                label: 'Goals',
                route: '/goals',
              ),
              NavigationItem(
                icon: Icons.insights,
                label: 'Insights',
                route: '/insights',
              ),
            ],
          ),
          NavigationSection(
            title: 'PLAN',
            items: [
              NavigationItem(
                icon: Icons.calendar_today,
                label: 'Calendar',
                route: '/calendar',
              ),
              NavigationItem(
                icon: Icons.task_alt,
                label: 'Tasks',
                route: '/tasks',
              ),
              NavigationItem(
                icon: Icons.note,
                label: 'Notes',
                route: '/notes',
              ),
            ],
          ),
          NavigationSection(
            title: 'ACT',
            items: [
              NavigationItem(
                icon: Icons.play_arrow,
                label: 'Focus Session',
                route: '/focus',
              ),
              NavigationItem(
                icon: Icons.timer,
                label: 'Time Tracking',
                route: '/time',
              ),
            ],
          ),
          NavigationSection(
            title: 'LEARN & REFLECT',
            items: [
              NavigationItem(
                icon: Icons.school,
                label: 'Learning',
                route: '/learning',
              ),
              NavigationItem(
                icon: Icons.psychology,
                label: 'Reflection',
                route: '/reflection',
              ),
            ],
          ),
          NavigationSection(
            title: 'DEBUG',
            items: [
              NavigationItem(
                icon: Icons.bug_report,
                label: 'Debug & Sync',
                route: '/debug',
              ),
            ],
          ),
        ];

      case FocusMode.work:
        return [
          NavigationSection(
            title: 'EXPLORE',
            items: [
              NavigationItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                route: '/home',
              ),
              NavigationItem(
                icon: Icons.folder,
                label: 'Projects',
                route: '/projects',
              ),
              NavigationItem(
                icon: Icons.people,
                label: 'Team',
                route: '/team',
              ),
            ],
          ),
          NavigationSection(
            title: 'PLAN',
            items: [
              NavigationItem(
                icon: Icons.task_alt,
                label: 'Tasks',
                route: '/tasks',
              ),
              NavigationItem(
                icon: Icons.calendar_today,
                label: 'Calendar',
                route: '/calendar',
              ),
              NavigationItem(
                icon: Icons.description,
                label: 'Documents',
                route: '/documents',
              ),
            ],
          ),
          NavigationSection(
            title: 'ACT',
            items: [
              NavigationItem(
                icon: Icons.chat,
                label: 'Chat',
                route: '/chat',
              ),
              NavigationItem(
                icon: Icons.video_call,
                label: 'Meetings',
                route: '/meetings',
              ),
            ],
          ),
          NavigationSection(
            title: 'LEARN & REFLECT',
            items: [
              NavigationItem(
                icon: Icons.analytics,
                label: 'Analytics',
                route: '/analytics',
              ),
              NavigationItem(
                icon: Icons.feedback,
                label: 'Feedback',
                route: '/feedback',
              ),
            ],
          ),
          NavigationSection(
            title: 'DEBUG',
            items: [
              NavigationItem(
                icon: Icons.bug_report,
                label: 'Debug & Sync',
                route: '/debug',
              ),
            ],
          ),
        ];

      case FocusMode.community:
        return [
          NavigationSection(
            title: 'EXPLORE',
            items: [
              NavigationItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                route: '/home',
              ),
              NavigationItem(
                icon: Icons.public,
                label: 'Community',
                route: '/community',
              ),
              NavigationItem(
                icon: Icons.explore,
                label: 'Discover',
                route: '/discover',
              ),
            ],
          ),
          NavigationSection(
            title: 'PLAN',
            items: [
              NavigationItem(
                icon: Icons.campaign,
                label: 'Quests',
                route: '/quests',
              ),
              NavigationItem(
                icon: Icons.event,
                label: 'Events',
                route: '/events',
              ),
            ],
          ),
          NavigationSection(
            title: 'ACT',
            items: [
              NavigationItem(
                icon: Icons.forum,
                label: 'Discussions',
                route: '/discussions',
              ),
              NavigationItem(
                icon: Icons.volunteer_activism,
                label: 'Contribute',
                route: '/contribute',
              ),
            ],
          ),
          NavigationSection(
            title: 'LEARN & REFLECT',
            items: [
              NavigationItem(
                icon: Icons.library_books,
                label: 'Knowledge Base',
                route: '/knowledge',
              ),
              NavigationItem(
                icon: Icons.share,
                label: 'Share',
                route: '/share',
              ),
            ],
          ),
          NavigationSection(
            title: 'DEBUG',
            items: [
              NavigationItem(
                icon: Icons.bug_report,
                label: 'Debug & Sync',
                route: '/debug',
              ),
            ],
          ),
        ];
    }
  }
}

class NavigationSection {
  final String title;
  final List<NavigationItem> items;

  NavigationSection({
    required this.title,
    required this.items,
  });
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
