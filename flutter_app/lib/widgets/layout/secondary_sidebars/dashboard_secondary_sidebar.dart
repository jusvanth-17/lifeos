import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/navigation_provider.dart';

class DashboardSecondarySidebar extends ConsumerWidget {
  final String? activeSubFeature;

  const DashboardSecondarySidebar({
    super.key,
    this.activeSubFeature,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Dashboard Submenus
        Expanded(
          child: _buildSubmenus(context, theme, ref),
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
            Icons.dashboard,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'Dashboard',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmenus(BuildContext context, ThemeData theme, WidgetRef ref) {
    final submenus = _getSubmenus();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
      children: [
        for (final submenu in submenus)
          _buildSubmenuItem(context, theme, submenu, ref),
      ],
    );
  }

  Widget _buildSubmenuItem(
    BuildContext context,
    ThemeData theme,
    DashboardSubmenu submenu,
    WidgetRef ref,
  ) {
    final isSelected = activeSubFeature == submenu.feature;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref
                .read(navigationProvider.notifier)
                .setActiveSubFeature(submenu.feature);
          },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      submenu.icon,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        submenu.title,
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
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  submenu.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DashboardSubmenu> _getSubmenus() {
    return [
      DashboardSubmenu(
        icon: Icons.explore,
        title: 'Explore',
        description: 'Overview, insights, and analytics',
        feature: AppConstants.dashboardExplore,
      ),
      DashboardSubmenu(
        icon: Icons.calendar_today,
        title: 'Plan',
        description: 'Calendar, planning tools, goal setting',
        feature: AppConstants.dashboardPlan,
      ),
      DashboardSubmenu(
        icon: Icons.play_arrow,
        title: 'Act',
        description: 'Focus sessions, active work, execution',
        feature: AppConstants.dashboardAct,
      ),
      DashboardSubmenu(
        icon: Icons.school,
        title: 'Learn & Reflect',
        description: 'Learning resources, reflection tools',
        feature: AppConstants.dashboardLearnReflect,
      ),
    ];
  }
}

class DashboardSubmenu {
  final IconData icon;
  final String title;
  final String description;
  final String feature;

  DashboardSubmenu({
    required this.icon,
    required this.title,
    required this.description,
    required this.feature,
  });
}
