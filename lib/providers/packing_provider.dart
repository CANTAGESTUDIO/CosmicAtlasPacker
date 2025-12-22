import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/atlas_settings.dart';
import '../services/bin_packing_service.dart';
import '../services/export_service.dart';
import '../services/image_loader_service.dart';
import 'image_provider.dart';
import 'sprite_provider.dart';

/// Provider for atlas packing settings
final atlasSettingsProvider =
    StateNotifierProvider<AtlasSettingsNotifier, AtlasSettings>((ref) {
  return AtlasSettingsNotifier();
});

/// Notifier for managing atlas settings state
class AtlasSettingsNotifier extends StateNotifier<AtlasSettings> {
  AtlasSettingsNotifier() : super(const AtlasSettings());

  void updateMaxWidth(int value) {
    if (value >= 64 && value <= 8192) {
      state = state.copyWith(maxWidth: value);
    }
  }

  void updateMaxHeight(int value) {
    if (value >= 64 && value <= 8192) {
      state = state.copyWith(maxHeight: value);
    }
  }

  void updatePadding(int value) {
    if (value >= 0 && value <= 32) {
      state = state.copyWith(padding: value);
    }
  }

  void updateExtrude(int value) {
    if (value >= 0 && value <= 16) {
      state = state.copyWith(extrude: value);
    }
  }

  void togglePowerOfTwo() {
    state = state.copyWith(powerOfTwo: !state.powerOfTwo);
  }

  void toggleTrimTransparent() {
    state = state.copyWith(trimTransparent: !state.trimTransparent);
  }

  void toggleForceSquare() {
    state = state.copyWith(forceSquare: !state.forceSquare);
  }

  void updateSettings(AtlasSettings settings) {
    state = settings;
  }

  void resetToDefaults() {
    state = const AtlasSettings();
  }
}

/// Provider for bin packing service
final binPackingServiceProvider = Provider<BinPackingService>((ref) {
  return BinPackingService();
});

/// Provider for packing result - automatically updates when sprites change
final packingResultProvider = Provider<PackingResult?>((ref) {
  final spriteState = ref.watch(spriteProvider);
  final settings = ref.watch(atlasSettingsProvider);
  final packingService = ref.watch(binPackingServiceProvider);

  if (spriteState.sprites.isEmpty) {
    return null;
  }

  return packingService.pack(
    spriteState.sprites,
    maxWidth: settings.maxWidth,
    maxHeight: settings.maxHeight,
    padding: settings.padding,
    powerOfTwo: settings.powerOfTwo,
  );
});

/// Provider for atlas dimensions
final atlasSizeProvider = Provider<(int, int)>((ref) {
  final result = ref.watch(packingResultProvider);
  if (result == null) return (0, 0);
  return (result.atlasWidth, result.atlasHeight);
});

/// Provider for packing efficiency percentage
final packingEfficiencyProvider = Provider<double>((ref) {
  final result = ref.watch(packingResultProvider);
  if (result == null) return 0.0;
  return result.efficiency * 100; // Convert to percentage
});

/// Provider for estimated memory usage in bytes
/// Calculates memory based on atlas size (width × height × 4 bytes for RGBA)
final estimatedMemoryProvider = Provider<int>((ref) {
  final atlasSize = ref.watch(atlasSizeProvider);
  if (atlasSize.$1 == 0 || atlasSize.$2 == 0) return 0;
  // RGBA = 4 bytes per pixel
  return atlasSize.$1 * atlasSize.$2 * 4;
});

/// Provider for formatted memory usage string
final memoryUsageDisplayProvider = Provider<String>((ref) {
  final bytes = ref.watch(estimatedMemoryProvider);
  if (bytes == 0) return '--';

  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  } else {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
});

/// Provider for ExportService (used for atlas image generation)
final _exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

/// Provider for atlas preview image (ui.Image)
/// Automatically regenerates when packingResult or sourceImage changes
/// This renders the exact same result as Export (uses same sourceImageProvider)
/// Uses autoDispose to ensure fresh computation when dependencies change
final atlasPreviewImageProvider = FutureProvider.autoDispose<ui.Image?>((ref) async {
  final packingResult = ref.watch(packingResultProvider);
  // Use sourceImageProvider - same source as Export for consistency
  final sourceImageState = ref.watch(sourceImageProvider);

  if (packingResult == null ||
      packingResult.packedSprites.isEmpty ||
      sourceImageState.rawImage == null) {
    return null;
  }

  // Generate atlas image using ExportService (same as export)
  final exportService = ref.read(_exportServiceProvider);
  final atlasImage = exportService.generateAtlasImage(
    sourceImage: sourceImageState.rawImage!,
    packingResult: packingResult,
  );

  // Convert img.Image to ui.Image for rendering
  final imageLoader = ImageLoaderService();
  return imageLoader.convertToUiImage(atlasImage);
});
