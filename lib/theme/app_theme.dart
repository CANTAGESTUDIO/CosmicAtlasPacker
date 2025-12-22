import 'package:flutter/material.dart';

import 'editor_colors.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  /// Dark theme for the editor
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: EditorColors.primaryDark,
        secondary: EditorColors.secondaryDark,
        surface: EditorColors.surfaceDark,
        error: EditorColors.errorDark,
      ),
      scaffoldBackgroundColor: EditorColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: EditorColors.surfaceDark,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: EditorColors.dividerDark,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EditorColors.inputBackgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: EditorColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: EditorColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: EditorColors.primaryDark),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: EditorColors.iconDefaultDark,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: EditorColors.surfaceDark,
        textStyle: const TextStyle(color: EditorColors.iconDefaultDark),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: EditorColors.surfaceDark,
        titleTextStyle: TextStyle(
          color: EditorColors.iconDefaultDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: EditorColors.primaryDark,
        inactiveTrackColor: EditorColors.borderDark,
        thumbColor: EditorColors.primaryDark,
        overlayColor: EditorColors.primaryDark.withValues(alpha: 0.2),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: EditorColors.surfaceDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: EditorColors.borderDark),
        ),
        textStyle: const TextStyle(
          color: EditorColors.iconDefaultDark,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Light theme for the editor
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: EditorColors.primaryLight,
        secondary: EditorColors.secondaryLight,
        surface: EditorColors.surfaceLight,
        error: EditorColors.errorLight,
      ),
      scaffoldBackgroundColor: EditorColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: EditorColors.surfaceLight,
        elevation: 0,
        foregroundColor: EditorColors.iconDefaultLight,
      ),
      dividerTheme: const DividerThemeData(
        color: EditorColors.dividerLight,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EditorColors.inputBackgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: EditorColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: EditorColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: EditorColors.primaryLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: EditorColors.iconDefaultLight,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: EditorColors.surfaceLight,
        textStyle: const TextStyle(color: EditorColors.iconDefaultLight),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: EditorColors.surfaceLight,
        titleTextStyle: TextStyle(
          color: EditorColors.iconDefaultLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: EditorColors.primaryLight,
        inactiveTrackColor: EditorColors.borderLight,
        thumbColor: EditorColors.primaryLight,
        overlayColor: EditorColors.primaryLight.withValues(alpha: 0.2),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: EditorColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: EditorColors.borderLight),
        ),
        textStyle: const TextStyle(
          color: EditorColors.iconDefaultLight,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Get theme based on mode
  static ThemeData getTheme(EditorThemeMode mode, Brightness platformBrightness) {
    switch (mode) {
      case EditorThemeMode.light:
        return lightTheme;
      case EditorThemeMode.dark:
        return darkTheme;
      case EditorThemeMode.system:
        return platformBrightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }
}
