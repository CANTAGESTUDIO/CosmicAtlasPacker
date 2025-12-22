import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/editor_colors.dart';

/// State for theme management
class ThemeState {
  final EditorThemeMode mode;
  final Brightness platformBrightness;

  const ThemeState({
    this.mode = EditorThemeMode.system,
    this.platformBrightness = Brightness.dark,
  });

  ThemeState copyWith({
    EditorThemeMode? mode,
    Brightness? platformBrightness,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      platformBrightness: platformBrightness ?? this.platformBrightness,
    );
  }

  /// Get effective brightness based on mode and platform
  Brightness get effectiveBrightness {
    switch (mode) {
      case EditorThemeMode.light:
        return Brightness.light;
      case EditorThemeMode.dark:
        return Brightness.dark;
      case EditorThemeMode.system:
        return platformBrightness;
    }
  }

  /// Check if current theme is dark
  bool get isDark => effectiveBrightness == Brightness.dark;
}

/// Notifier for theme state management
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _initPlatformBrightness();
  }

  void _initPlatformBrightness() {
    // Get initial platform brightness
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    state = state.copyWith(platformBrightness: brightness);
  }

  /// Update theme mode
  void setThemeMode(EditorThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// Set to light theme
  void setLightTheme() {
    state = state.copyWith(mode: EditorThemeMode.light);
  }

  /// Set to dark theme
  void setDarkTheme() {
    state = state.copyWith(mode: EditorThemeMode.dark);
  }

  /// Set to system theme
  void setSystemTheme() {
    state = state.copyWith(mode: EditorThemeMode.system);
  }

  /// Toggle between light and dark (if system mode, switch to opposite of current)
  void toggleTheme() {
    if (state.mode == EditorThemeMode.system) {
      // Switch to opposite of current platform brightness
      state = state.copyWith(
        mode: state.platformBrightness == Brightness.dark
            ? EditorThemeMode.light
            : EditorThemeMode.dark,
      );
    } else {
      state = state.copyWith(
        mode: state.mode == EditorThemeMode.dark
            ? EditorThemeMode.light
            : EditorThemeMode.dark,
      );
    }
  }

  /// Update platform brightness (called when system theme changes)
  void updatePlatformBrightness(Brightness brightness) {
    state = state.copyWith(platformBrightness: brightness);
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Provider for current theme mode
final themeModeProvider = Provider<EditorThemeMode>((ref) {
  return ref.watch(themeProvider).mode;
});

/// Provider for whether current theme is dark
final isDarkThemeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDark;
});

/// Provider for effective brightness
final effectiveBrightnessProvider = Provider<Brightness>((ref) {
  return ref.watch(themeProvider).effectiveBrightness;
});
