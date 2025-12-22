import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/atlas_settings.dart';
import '../services/bin_packing_service.dart';
import '../services/export_service.dart';
import '../services/image_loader_service.dart';
import 'multi_image_provider.dart'; // activeSourceProvider
import 'multi_sprite_provider.dart'; // activeSourceSpritesProvider

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

/// Provider for packing result - automatically updates when active source sprites change
/// Uses activeSourceSpritesProvider for multi-tab support (1 tab = 1 atlas)
final packingResultProvider = Provider<PackingResult?>((ref) {
  final sprites = ref.watch(activeSourceSpritesProvider);
  final settings = ref.watch(atlasSettingsProvider);
  final packingService = ref.watch(binPackingServiceProvider);

  if (sprites.isEmpty) {
    return null;
  }

  return packingService.pack(
    sprites,
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
/// Automatically regenerates when active source sprites or source image changes
/// Uses ONLY the active tab's sprites for atlas generation (1 tab = 1 atlas)
/// Uses autoDispose to ensure fresh computation when dependencies change
final atlasPreviewImageProvider = FutureProvider.autoDispose<ui.Image?>((ref) async {
  final activeSprites = ref.watch(activeSourceSpritesProvider);
  final activeSource = ref.watch(activeSourceProvider);
  final settings = ref.watch(atlasSettingsProvider);
  final packingService = ref.watch(binPackingServiceProvider);

  // Only use active tab's sprites (1 tab = 1 atlas)
  if (activeSprites.isEmpty || activeSource == null) {
    return null;
  }

  // Pack only active source's sprites
  final packingResult = packingService.pack(
    activeSprites,
    maxWidth: settings.maxWidth,
    maxHeight: settings.maxHeight,
    padding: settings.padding,
    powerOfTwo: settings.powerOfTwo,
  );

  if (packingResult.packedSprites.isEmpty) {
    return null;
  }

  // Use only active source's image
  final sourceImages = <String, dynamic>{
    activeSource.id: activeSource.rawImage,
  };

  // Generate atlas image using ExportService
  final exportService = ref.read(_exportServiceProvider);
  final atlasImage = exportService.generateMultiSourceAtlasImage(
    sourceImages: sourceImages,
    packingResult: packingResult,
  );

  // Convert img.Image to ui.Image for rendering
  final imageLoader = ImageLoaderService();
  return imageLoader.convertToUiImage(atlasImage);
});
