import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

// Navigation state class
class NavigationState {
  final String activeFeature;
  final String? activeSubFeature;
  final bool isSecondarySidebarVisible;

  const NavigationState({
    required this.activeFeature,
    this.activeSubFeature,
    this.isSecondarySidebarVisible = true,
  });

  NavigationState copyWith({
    String? activeFeature,
    String? activeSubFeature,
    bool? isSecondarySidebarVisible,
  }) {
    return NavigationState(
      activeFeature: activeFeature ?? this.activeFeature,
      activeSubFeature: activeSubFeature ?? this.activeSubFeature,
      isSecondarySidebarVisible:
          isSecondarySidebarVisible ?? this.isSecondarySidebarVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationState &&
        other.activeFeature == activeFeature &&
        other.activeSubFeature == activeSubFeature &&
        other.isSecondarySidebarVisible == isSecondarySidebarVisible;
  }

  @override
  int get hashCode {
    return activeFeature.hashCode ^
        activeSubFeature.hashCode ^
        isSecondarySidebarVisible.hashCode;
  }
}

// Navigation state notifier
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier()
      : super(const NavigationState(
          activeFeature: AppConstants.navDashboard,
          activeSubFeature: AppConstants.dashboardExplore,
        ));

  void setActiveFeature(String feature, {String? subFeature}) {
    state = state.copyWith(
      activeFeature: feature,
      activeSubFeature: subFeature,
    );
  }

  void setActiveSubFeature(String subFeature) {
    state = state.copyWith(activeSubFeature: subFeature);
  }

  void toggleSecondarySidebar() {
    state = state.copyWith(
      isSecondarySidebarVisible: !state.isSecondarySidebarVisible,
    );
  }

  void setSecondarySidebarVisible(bool visible) {
    state = state.copyWith(isSecondarySidebarVisible: visible);
  }

  // Helper methods to get default sub-features for each main feature
  String? getDefaultSubFeature(String feature) {
    switch (feature) {
      case AppConstants.navDashboard:
        return AppConstants.dashboardExplore;
      case AppConstants.navGoals:
      case AppConstants.navTasks:
      case AppConstants.navChats:
      case AppConstants.navDocuments:
      case AppConstants.navAIAssistant:
        return null; // These features don't have sub-features by default
      default:
        return null;
    }
  }
}

// Provider
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

// Helper providers for easy access
final activeFeatureProvider = Provider<String>((ref) {
  return ref.watch(navigationProvider).activeFeature;
});

final activeSubFeatureProvider = Provider<String?>((ref) {
  return ref.watch(navigationProvider).activeSubFeature;
});

final isSecondarySidebarVisibleProvider = Provider<bool>((ref) {
  return ref.watch(navigationProvider).isSecondarySidebarVisible;
});
