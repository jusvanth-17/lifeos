import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/focus_mode_theme.dart';

class ThemeState {
  final FocusMode focusMode;
  final Brightness brightness;
  final bool isSystemBrightness;

  const ThemeState({
    required this.focusMode,
    required this.brightness,
    this.isSystemBrightness = true,
  });

  ThemeState copyWith({
    FocusMode? focusMode,
    Brightness? brightness,
    bool? isSystemBrightness,
  }) {
    return ThemeState(
      focusMode: focusMode ?? this.focusMode,
      brightness: brightness ?? this.brightness,
      isSystemBrightness: isSystemBrightness ?? this.isSystemBrightness,
    );
  }

  ThemeData get themeData => FocusModeTheme.getThemeData(focusMode, brightness);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.focusMode == focusMode &&
        other.brightness == brightness &&
        other.isSystemBrightness == isSystemBrightness;
  }

  @override
  int get hashCode {
    return focusMode.hashCode ^
        brightness.hashCode ^
        isSystemBrightness.hashCode;
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(const ThemeState(
          focusMode: FocusMode.me,
          brightness: Brightness.light,
          isSystemBrightness: true,
        ));

  void setFocusMode(FocusMode mode) {
    state = state.copyWith(focusMode: mode);
  }

  void setBrightness(Brightness brightness) {
    state = state.copyWith(
      brightness: brightness,
      isSystemBrightness: false,
    );
  }

  void setSystemBrightness(Brightness brightness) {
    if (state.isSystemBrightness) {
      state = state.copyWith(brightness: brightness);
    }
  }

  void toggleBrightness() {
    final newBrightness = state.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    setBrightness(newBrightness);
  }

  void enableSystemBrightness() {
    state = state.copyWith(isSystemBrightness: true);
  }

  void cycleFocusMode() {
    const modes = FocusMode.values;
    final currentIndex = modes.indexOf(state.focusMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    setFocusMode(modes[nextIndex]);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// Convenience providers for specific theme properties
final focusModeProvider = Provider<FocusMode>((ref) {
  return ref.watch(themeProvider).focusMode;
});

final brightnessProvider = Provider<Brightness>((ref) {
  return ref.watch(themeProvider).brightness;
});

final themeDataProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider).themeData;
});

final primaryColorProvider = Provider<Color>((ref) {
  final focusMode = ref.watch(focusModeProvider);
  return FocusModeTheme.getPrimaryColor(focusMode);
});

final accentColorProvider = Provider<Color>((ref) {
  final focusMode = ref.watch(focusModeProvider);
  return FocusModeTheme.getAccentColor(focusMode);
});
