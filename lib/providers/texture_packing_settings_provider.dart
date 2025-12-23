import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/texture_compression_settings.dart';

/// Provider for texture packing settings
final texturePackingSettingsProvider =
    StateNotifierProvider<TexturePackingSettingsNotifier, TextureCompressionSettings>((ref) {
  return TexturePackingSettingsNotifier();
});

/// Provider for checking if onboarding is needed
final needsOnboardingProvider = Provider<bool>((ref) {
  final settings = ref.watch(texturePackingSettingsProvider);
  return !settings.onboardingCompleted;
});

/// Provider for current onboarding step
final currentOnboardingStepProvider = Provider<int>((ref) {
  final settings = ref.watch(texturePackingSettingsProvider);
  return settings.onboardingStep;
});

/// Provider for estimated build size (KB) based on current settings
final estimatedBuildSizeProvider = Provider.family<double, ({int width, int height})>((ref, size) {
  final settings = ref.watch(texturePackingSettingsProvider);
  return settings.calculateEstimatedSize(size.width, size.height);
});

/// Provider for settings validation message
final settingsValidationProvider = Provider<String?>((ref) {
  final settings = ref.watch(texturePackingSettingsProvider);
  return settings.validate();
});

/// Notifier for managing texture packing settings
class TexturePackingSettingsNotifier extends StateNotifier<TextureCompressionSettings> {
  TexturePackingSettingsNotifier() : super(const TextureCompressionSettings()) {
    _loadSettings();
  }

  static const _settingsFileName = 'texture_packing_settings.json';

  /// Load settings from disk
  Future<void> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        state = TextureCompressionSettings.fromJson(json);
      }
    } catch (e) {
      // Use default settings if loading fails
      state = const TextureCompressionSettings();
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

  // ========== Android Format Methods ==========

  /// Update Android compression format
  void updateAndroidFormat(TextureCompressionFormat format) {
    if (format.supportsAndroid) {
      state = state.copyWith(
        androidFormat: format,
        customPreset: true,
      );
      _saveSettings();
    }
  }

  // ========== iOS Format Methods ==========

  /// Update iOS compression format
  void updateIOSFormat(TextureCompressionFormat format) {
    if (format.supportsIOS) {
      state = state.copyWith(
        iosFormat: format,
        customPreset: true,
      );
      _saveSettings();
    }
  }

  // ========== ASTC Block Size Methods ==========

  /// Update ASTC block size
  void updateASTCBlockSize(ASTCBlockSize blockSize) {
    state = state.copyWith(
      astcBlockSize: blockSize,
      customPreset: true,
    );
    _saveSettings();
  }

  // ========== Game Type & Preset Methods ==========

  /// Update game type (applies preset)
  void updateGameType(GameType gameType) {
    state = state.copyWith(
      gameType: gameType,
      androidFormat: gameType.defaultAndroidFormat,
      iosFormat: gameType.defaultIOSFormat,
      astcBlockSize: gameType.defaultASTCBlockSize,
      memoryBudgetMB: gameType.recommendedMemoryBudgetMB,
      customPreset: false,
    );
    _saveSettings();
  }

  /// Apply game type preset without changing game type
  void applyGameTypePreset() {
    final gameType = state.gameType;
    state = state.copyWith(
      androidFormat: gameType.defaultAndroidFormat,
      iosFormat: gameType.defaultIOSFormat,
      astcBlockSize: gameType.defaultASTCBlockSize,
      memoryBudgetMB: gameType.recommendedMemoryBudgetMB,
      customPreset: false,
    );
    _saveSettings();
  }

  // ========== Export Type Methods ==========

  /// Update export type
  void updateExportType(ExportType exportType) {
    state = state.copyWith(exportType: exportType);
    _saveSettings();
  }

  // ========== Fallback Format Methods ==========

  /// Update fallback format
  void updateFallbackFormat(TextureCompressionFormat? format) {
    state = state.copyWith(
      fallbackFormat: format,
      customPreset: true,
    );
    _saveSettings();
  }

  /// Clear fallback format
  void clearFallbackFormat() {
    state = state.copyWith(
      fallbackFormat: null,
      customPreset: true,
    );
    _saveSettings();
  }

  // ========== Target Device Methods ==========

  /// Update target Android API level
  void updateTargetAndroidApiLevel(int apiLevel) {
    if (apiLevel >= 18 && apiLevel <= 35) {
      state = state.copyWith(targetAndroidApiLevel: apiLevel);
      _saveSettings();
    }
  }

  /// Update target iOS version
  void updateTargetIOSVersion(int version) {
    if (version >= 8 && version <= 18) {
      state = state.copyWith(targetIOSVersion: version);
      _saveSettings();
    }
  }

  /// Update target minimum RAM
  void updateTargetMinRamGB(int ramGB) {
    if (ramGB >= 1 && ramGB <= 8) {
      state = state.copyWith(targetMinRamGB: ramGB);
      _saveSettings();
    }
  }

  // ========== Memory Budget Methods ==========

  /// Update memory budget
  void updateMemoryBudgetMB(int budgetMB) {
    if (budgetMB >= 10 && budgetMB <= 1024) {
      state = state.copyWith(memoryBudgetMB: budgetMB);
      _saveSettings();
    }
  }

  /// Update texture allocation percent
  void updateTextureAllocationPercent(int percent) {
    if (percent >= 10 && percent <= 80) {
      state = state.copyWith(textureAllocationPercent: percent);
      _saveSettings();
    }
  }

  // ========== Onboarding Methods ==========

  /// Update onboarding step
  void updateOnboardingStep(int step) {
    if (step >= 1 && step <= 6) {
      state = state.copyWith(onboardingStep: step);
      _saveSettings();
    }
  }

  /// Advance to next onboarding step
  void advanceOnboardingStep() {
    if (state.onboardingStep < 6) {
      state = state.copyWith(onboardingStep: state.onboardingStep + 1);
      _saveSettings();
    }
  }

  /// Go back to previous onboarding step
  void previousOnboardingStep() {
    if (state.onboardingStep > 1) {
      state = state.copyWith(onboardingStep: state.onboardingStep - 1);
      _saveSettings();
    }
  }

  /// Complete onboarding
  void completeOnboarding() {
    state = state.copyWith(
      onboardingCompleted: true,
      onboardingStep: 6,
    );
    _saveSettings();
  }

  /// Reset onboarding (start fresh)
  void resetOnboarding() {
    state = state.copyWith(
      onboardingCompleted: false,
      onboardingStep: 1,
    );
    _saveSettings();
  }

  /// Skip onboarding with default settings
  void skipOnboarding() {
    state = state.copyWith(
      onboardingCompleted: true,
      onboardingStep: 6,
    );
    _saveSettings();
  }

  // ========== General Methods ==========

  /// Reset all settings to defaults
  void resetToDefaults() {
    state = const TextureCompressionSettings();
    _saveSettings();
  }

  /// Apply settings from given settings object
  void applySettings(TextureCompressionSettings settings) {
    state = settings;
    _saveSettings();
  }

  /// Export settings as JSON string
  String exportSettingsJson() {
    return const JsonEncoder.withIndent('  ').convert(state.toJson());
  }

  /// Import settings from JSON string
  bool importSettingsJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      state = TextureCompressionSettings.fromJson(json);
      _saveSettings();
      return true;
    } catch (e) {
      return false;
    }
  }
}
