import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/atlas_settings.dart';
import '../models/project_settings.dart';

/// Provider for project settings
final projectSettingsProvider =
    StateNotifierProvider<ProjectSettingsNotifier, ProjectSettings>((ref) {
  return ProjectSettingsNotifier();
});

/// Provider for auto-save timer
final autoSaveTimerProvider = Provider<Timer?>((ref) {
  final settings = ref.watch(projectSettingsProvider);
  if (!settings.autoSaveEnabled) return null;

  // Note: Actual timer implementation should be handled by the EditorScreen
  // This provider just exposes the settings for the timer
  return null;
});

/// Notifier for managing project settings
class ProjectSettingsNotifier extends StateNotifier<ProjectSettings> {
  ProjectSettingsNotifier() : super(const ProjectSettings()) {
    _loadSettings();
  }

  static const _settingsFileName = 'cosmic_atlas_packer_settings.json';

  /// Load settings from disk
  Future<void> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        state = ProjectSettings.fromJson(json);
      }
    } catch (e) {
      // Use default settings if loading fails
      state = const ProjectSettings();
    }
  }

  /// Save settings to disk
  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();
      final json = jsonEncode(state.toJson());
      await file.writeAsString(json);
    } catch (e) {
      // Silently fail - settings will be lost on restart
    }
  }

  /// Get the settings file path
  Future<File> _getSettingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_settingsFileName');
  }

  /// Update default project name
  void updateDefaultProjectName(String name) {
    if (name.isNotEmpty && name.length <= 100) {
      state = state.copyWith(defaultProjectName: name);
      _saveSettings();
    }
  }

  /// Update default atlas settings
  void updateDefaultAtlasSettings(AtlasSettings settings) {
    state = state.copyWith(defaultAtlasSettings: settings);
    _saveSettings();
  }

  /// Update default max width
  void updateDefaultMaxWidth(int value) {
    if (value >= 64 && value <= 8192) {
      state = state.copyWith(
        defaultAtlasSettings: state.defaultAtlasSettings.copyWith(
          maxWidth: value,
        ),
      );
      _saveSettings();
    }
  }

  /// Update default max height
  void updateDefaultMaxHeight(int value) {
    if (value >= 64 && value <= 8192) {
      state = state.copyWith(
        defaultAtlasSettings: state.defaultAtlasSettings.copyWith(
          maxHeight: value,
        ),
      );
      _saveSettings();
    }
  }

  /// Update default padding
  void updateDefaultPadding(int value) {
    if (value >= 0 && value <= 32) {
      state = state.copyWith(
        defaultAtlasSettings: state.defaultAtlasSettings.copyWith(
          padding: value,
        ),
      );
      _saveSettings();
    }
  }

  /// Toggle default power of two
  void toggleDefaultPowerOfTwo() {
    state = state.copyWith(
      defaultAtlasSettings: state.defaultAtlasSettings.copyWith(
        powerOfTwo: !state.defaultAtlasSettings.powerOfTwo,
      ),
    );
    _saveSettings();
  }

  /// Toggle default trim transparent
  void toggleDefaultTrimTransparent() {
    state = state.copyWith(
      defaultAtlasSettings: state.defaultAtlasSettings.copyWith(
        trimTransparent: !state.defaultAtlasSettings.trimTransparent,
      ),
    );
    _saveSettings();
  }

  /// Toggle auto-save
  void toggleAutoSave() {
    state = state.copyWith(autoSaveEnabled: !state.autoSaveEnabled);
    _saveSettings();
  }

  /// Set auto-save enabled
  void setAutoSaveEnabled(bool enabled) {
    state = state.copyWith(autoSaveEnabled: enabled);
    _saveSettings();
  }

  /// Update auto-save interval
  void updateAutoSaveInterval(int seconds) {
    if (AutoSaveIntervals.values.contains(seconds)) {
      state = state.copyWith(autoSaveIntervalSeconds: seconds);
      _saveSettings();
    }
  }

  /// Toggle remember last project
  void toggleRememberLastProject() {
    state = state.copyWith(rememberLastProject: !state.rememberLastProject);
    _saveSettings();
  }

  /// Update last project path
  void updateLastProjectPath(String? path) {
    state = state.copyWith(lastProjectPath: path);
    _saveSettings();
  }

  /// Toggle show grid by default
  void toggleShowGridByDefault() {
    state = state.copyWith(showGridByDefault: !state.showGridByDefault);
    _saveSettings();
  }

  /// Update default zoom level
  void updateDefaultZoomLevel(int level) {
    if (level >= 25 && level <= 800) {
      state = state.copyWith(defaultZoomLevel: level);
      _saveSettings();
    }
  }

  /// Reset all settings to defaults
  void resetToDefaults() {
    state = const ProjectSettings();
    _saveSettings();
  }

  /// Apply settings from given settings object
  void applySettings(ProjectSettings settings) {
    state = settings;
    _saveSettings();
  }
}
