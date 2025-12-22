import 'package:freezed_annotation/freezed_annotation.dart';

import 'atlas_settings.dart';

part 'project_settings.freezed.dart';
part 'project_settings.g.dart';

/// Auto-save interval presets in seconds
class AutoSaveIntervals {
  static const int thirtySeconds = 30;
  static const int oneMinute = 60;
  static const int twoMinutes = 120;
  static const int fiveMinutes = 300;

  static const List<int> values = [
    thirtySeconds,
    oneMinute,
    twoMinutes,
    fiveMinutes,
  ];

  static String label(int seconds) {
    if (seconds < 60) {
      return '$seconds초';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes분';
    }
  }
}

/// Project-wide settings (persisted separately from project file)
@freezed
class ProjectSettings with _$ProjectSettings {
  const ProjectSettings._();

  const factory ProjectSettings({
    /// Default project name for new projects
    @Default('Untitled') String defaultProjectName,

    /// Default atlas settings for new projects
    @Default(AtlasSettings()) AtlasSettings defaultAtlasSettings,

    /// Whether auto-save is enabled
    @Default(false) bool autoSaveEnabled,

    /// Auto-save interval in seconds
    @Default(60) int autoSaveIntervalSeconds,

    /// Remember last opened project path
    @Default(true) bool rememberLastProject,

    /// Last opened project path
    String? lastProjectPath,

    /// Show grid by default
    @Default(true) bool showGridByDefault,

    /// Default zoom level (percentage)
    @Default(100) int defaultZoomLevel,
  }) = _ProjectSettings;

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);

  /// Get auto-save interval as Duration
  Duration get autoSaveInterval => Duration(seconds: autoSaveIntervalSeconds);
}
