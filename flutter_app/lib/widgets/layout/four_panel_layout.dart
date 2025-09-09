import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/copilot_provider.dart';
import '../../providers/theme_provider.dart';
import 'collapsed_primary_sidebar.dart';
import 'secondary_sidebar.dart';
import 'copilot_panel.dart';

class FourPanelLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const FourPanelLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  ConsumerState<FourPanelLayout> createState() => _FourPanelLayoutState();
}

class _FourPanelLayoutState extends ConsumerState<FourPanelLayout>
    with TickerProviderStateMixin {
  late AnimationController _secondarySidebarController;
  late Animation<double> _secondarySidebarAnimation;

  @override
  void initState() {
    super.initState();
    _secondarySidebarController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );

    _secondarySidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondarySidebarController,
      curve: Curves.easeInOut,
    ));

    // Initialize secondary sidebar as expanded
    _secondarySidebarController.forward();
  }

  @override
  void dispose() {
    _secondarySidebarController.dispose();
    super.dispose();
  }

  void _toggleCopilot() {
    ref.read(copilotProvider.notifier).toggleExpanded();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationState = ref.watch(navigationProvider);
    final copilotState = ref.watch(copilotProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;
    final isTablet = screenWidth < AppConstants.tabletBreakpoint;

    // Listen to secondary sidebar visibility changes
    ref.listen<bool>(isSecondarySidebarVisibleProvider, (previous, next) {
      if (next) {
        _secondarySidebarController.forward();
      } else {
        _secondarySidebarController.reverse();
      }
    });

    // On mobile, use a different layout
    if (isMobile) {
      return _buildMobileLayout(theme, navigationState);
    }

    return Scaffold(
      floatingActionButton: Stack(
        children: [
          if (widget.floatingActionButton != null) widget.floatingActionButton!,
          // AI Copilot Floating Button
          if (!isTablet)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _toggleCopilot,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.smart_toy,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Collapsed Primary Sidebar (always visible)
          Container(
            width: AppConstants.primarySidebarCollapsedWidth,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: const CollapsedPrimarySidebar(),
          ),

          // Secondary Sidebar (contextual, stable width)
          if (navigationState.isSecondarySidebarVisible)
            Container(
              width: AppConstants.secondarySidebarWidth,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SecondarySidebar(
                activeFeature: navigationState.activeFeature,
                activeSubFeature: navigationState.activeSubFeature,
              ),
            ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // App Bar
                if (widget.title != null || widget.actions != null)
                  _buildAppBar(theme, navigationState),

                // Content
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),

          // Copilot Panel as Sidebar (pushes content instead of overlay)
          if (copilotState.isExpanded && !isTablet)
            Container(
              width: AppConstants.copilotPanelWidth,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: CopilotPanel(
                isExpanded: copilotState.isExpanded,
                onToggle: _toggleCopilot,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, NavigationState navigationState) {
    final copilotState = ref.watch(copilotProvider);
    return Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Secondary Sidebar Toggle
          IconButton(
            onPressed: () =>
                ref.read(navigationProvider.notifier).toggleSecondarySidebar(),
            icon: Icon(
              navigationState.isSecondarySidebarVisible
                  ? Icons.menu_open
                  : Icons.menu,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: navigationState.isSecondarySidebarVisible
                ? 'Hide Sidebar'
                : 'Show Sidebar',
          ),

          const SizedBox(width: AppConstants.spacingS),

          // Title
          if (widget.title != null)
            Expanded(
              child: Text(
                widget.title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Actions
          if (widget.actions != null) ...widget.actions!,

          // Copilot Toggle (on tablet)
          if (MediaQuery.of(context).size.width < AppConstants.tabletBreakpoint)
            IconButton(
              onPressed: _toggleCopilot,
              icon: Icon(
                copilotState.isExpanded ? Icons.close : Icons.smart_toy,
                color: theme.colorScheme.primary,
              ),
              tooltip:
                  copilotState.isExpanded ? 'Close Copilot' : 'Open Copilot',
            ),

          const SizedBox(width: AppConstants.spacingS),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme, NavigationState navigationState) {
    final copilotState = ref.watch(copilotProvider);
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: [
                ...?widget.actions,
                IconButton(
                  onPressed: _toggleCopilot,
                  icon: Icon(
                    copilotState.isExpanded ? Icons.close : Icons.smart_toy,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            )
          : null,
      drawer: SizedBox(
        width: AppConstants.primarySidebarWidth,
        child: Drawer(
          child: Column(
            children: [
              // Primary navigation in drawer
              const SizedBox(
                width: AppConstants.primarySidebarCollapsedWidth,
                child: CollapsedPrimarySidebar(),
              ),
              // Secondary sidebar content
              Expanded(
                child: SecondarySidebar(
                  activeFeature: navigationState.activeFeature,
                  activeSubFeature: navigationState.activeSubFeature,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          // Main Content
          Expanded(child: widget.child),

          // Copilot Panel as Sidebar (pushes content on mobile too)
          if (copilotState.isExpanded)
            Container(
              width: AppConstants.copilotPanelWidth,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: CopilotPanel(
                isExpanded: copilotState.isExpanded,
                onToggle: _toggleCopilot,
              ),
            ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
