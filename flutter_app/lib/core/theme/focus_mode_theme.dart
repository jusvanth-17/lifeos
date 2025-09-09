import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum FocusMode { me, work, community }

class FocusModeTheme {
  static const Map<FocusMode, Color> _primaryColors = {
    FocusMode.me: Color(0xFF6366F1), // Indigo - Personal focus
    FocusMode.work: Color(0xFF059669), // Emerald - Work/team focus
    FocusMode.community: Color(0xFFDC2626), // Red - Community focus
  };

  static const Map<FocusMode, Color> _accentColors = {
    FocusMode.me: Color(0xFF8B5CF6), // Purple
    FocusMode.work: Color(0xFF0891B2), // Cyan
    FocusMode.community: Color(0xFFEA580C), // Orange
  };

  static const Map<FocusMode, String> _modeNames = {
    FocusMode.me: 'Me',
    FocusMode.work: 'Work',
    FocusMode.community: 'Community',
  };

  static const Map<FocusMode, IconData> _modeIcons = {
    FocusMode.me: Icons.person,
    FocusMode.work: Icons.work,
    FocusMode.community: Icons.public,
  };

  static const Map<FocusMode, String> _modeDescriptions = {
    FocusMode.me: 'Personal productivity and self-improvement',
    FocusMode.work: 'Team collaboration and project management',
    FocusMode.community: 'Public engagement and knowledge sharing',
  };

  static Color getPrimaryColor(FocusMode mode) {
    return _primaryColors[mode] ?? _primaryColors[FocusMode.me]!;
  }

  static Color getAccentColor(FocusMode mode) {
    return _accentColors[mode] ?? _accentColors[FocusMode.me]!;
  }

  static String getModeName(FocusMode mode) {
    return _modeNames[mode] ?? _modeNames[FocusMode.me]!;
  }

  static IconData getModeIcon(FocusMode mode) {
    return _modeIcons[mode] ?? _modeIcons[FocusMode.me]!;
  }

  static String getModeDescription(FocusMode mode) {
    return _modeDescriptions[mode] ?? _modeDescriptions[FocusMode.me]!;
  }

  static ThemeData getThemeData(FocusMode mode, Brightness brightness) {
    final primaryColor = getPrimaryColor(mode);
    final accentColor = getAccentColor(mode);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      secondary: accentColor,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: brightness,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Navigation Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        color: colorScheme.surface,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          elevation: 2,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingM,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static List<BoxShadow> getElevationShadow(
    FocusMode mode,
    double elevation, {
    Brightness brightness = Brightness.light,
  }) {
    final primaryColor = getPrimaryColor(mode);
    final shadowColor = brightness == Brightness.light
        ? primaryColor.withOpacity(0.1)
        : Colors.black.withOpacity(0.3);

    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }

  static Gradient getGradient(FocusMode mode, {bool isVertical = true}) {
    final primaryColor = getPrimaryColor(mode);
    final accentColor = getAccentColor(mode);

    return LinearGradient(
      begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
      end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [
        primaryColor,
        accentColor,
      ],
    );
  }
}
