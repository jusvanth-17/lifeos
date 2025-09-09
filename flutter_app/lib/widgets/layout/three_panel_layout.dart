import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import 'primary_sidebar.dart';
import 'copilot_panel.dart';

class ThreePanelLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ThreePanelLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  ConsumerState<ThreePanelLayout> createState() => _ThreePanelLayoutState();
}

class _ThreePanelLayoutState extends ConsumerState<ThreePanelLayout>
    with TickerProviderStateMixin {
  late AnimationController _sidebarController;
  late AnimationController _copilotController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _copilotAnimation;

  bool _isSidebarExpanded = true;
  bool _isCopilotExpanded = false;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );
    _copilotController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );

    _sidebarAnimation = Tween<double>(
      begin: AppConstants.primarySidebarCollapsedWidth,
      end: AppConstants.primarySidebarWidth,
    ).animate(CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    ));

    _copilotAnimation = Tween<double>(
      begin: AppConstants.copilotPanelCollapsedWidth,
      end: AppConstants.copilotPanelWidth,
    ).animate(CurvedAnimation(
      parent: _copilotController,
      curve: Curves.easeInOut,
    ));

    // Initialize animations based on initial state
    if (_isSidebarExpanded) {
      _sidebarController.forward();
    }
    if (_isCopilotExpanded) {
      _copilotController.forward();
    }
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _copilotController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  void _toggleCopilot() {
    setState(() {
      _isCopilotExpanded = !_isCopilotExpanded;
      if (_isCopilotExpanded) {
        _copilotController.forward();
      } else {
        _copilotController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusMode = ref.watch(focusModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;
    final isTablet = screenWidth < AppConstants.tabletBreakpoint;

    // On mobile, use a different layout
    if (isMobile) {
      return _buildMobileLayout(theme);
    }

    return Scaffold(
      body: Row(
        children: [
          // Primary Sidebar
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Container(
                width: _sidebarAnimation.value,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: PrimarySidebar(
                  isExpanded: _isSidebarExpanded,
                  onToggle: _toggleSidebar,
                ),
              );
            },
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // App Bar
                if (widget.title != null || widget.actions != null)
                  _buildAppBar(theme),

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

          // Copilot Panel
          if (!isTablet)
            AnimatedBuilder(
              animation: _copilotAnimation,
              builder: (context, child) {
                return Container(
                  width: _copilotAnimation.value,
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
                    isExpanded: _isCopilotExpanded,
                    onToggle: _toggleCopilot,
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildAppBar(ThemeData theme) {
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
          const SizedBox(width: AppConstants.spacingM),

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
                _isCopilotExpanded ? Icons.close : Icons.smart_toy,
                color: theme.colorScheme.primary,
              ),
              tooltip: _isCopilotExpanded ? 'Close Copilot' : 'Open Copilot',
            ),

          const SizedBox(width: AppConstants.spacingS),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: [
                ...?widget.actions,
                IconButton(
                  onPressed: _toggleCopilot,
                  icon: Icon(
                    _isCopilotExpanded ? Icons.close : Icons.smart_toy,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            )
          : null,
      drawer: SizedBox(
        width: AppConstants.primarySidebarWidth,
        child: Drawer(
          child: PrimarySidebar(
            isExpanded: true,
            onToggle: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Content
          widget.child,

          // Copilot Panel Overlay
          if (_isCopilotExpanded)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: AppConstants.copilotPanelWidth,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: CopilotPanel(
                  isExpanded: _isCopilotExpanded,
                  onToggle: _toggleCopilot,
                ),
              ),
            ),

          // Backdrop for copilot panel
          if (_isCopilotExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleCopilot,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
