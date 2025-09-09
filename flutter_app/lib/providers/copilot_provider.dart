import 'package:flutter_riverpod/flutter_riverpod.dart';

// Copilot state class
class CopilotState {
  final bool isExpanded;
  final bool isVisible;

  const CopilotState({
    this.isExpanded = false,
    this.isVisible = true,
  });

  CopilotState copyWith({
    bool? isExpanded,
    bool? isVisible,
  }) {
    return CopilotState(
      isExpanded: isExpanded ?? this.isExpanded,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CopilotState &&
        other.isExpanded == isExpanded &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode {
    return isExpanded.hashCode ^ isVisible.hashCode;
  }
}

// Copilot state notifier
class CopilotNotifier extends StateNotifier<CopilotState> {
  CopilotNotifier() : super(const CopilotState());

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setExpanded(bool expanded) {
    state = state.copyWith(isExpanded: expanded);
  }

  void setVisible(bool visible) {
    state = state.copyWith(isVisible: visible);
  }

  void expand() {
    state = state.copyWith(isExpanded: true);
  }

  void collapse() {
    state = state.copyWith(isExpanded: false);
  }

  void show() {
    state = state.copyWith(isVisible: true);
  }

  void hide() {
    state = state.copyWith(isVisible: false);
  }
}

// Provider
final copilotProvider =
    StateNotifierProvider<CopilotNotifier, CopilotState>((ref) {
  return CopilotNotifier();
});

// Helper providers for easy access
final isCopilotExpandedProvider = Provider<bool>((ref) {
  return ref.watch(copilotProvider).isExpanded;
});

final isCopilotVisibleProvider = Provider<bool>((ref) {
  return ref.watch(copilotProvider).isVisible;
});
