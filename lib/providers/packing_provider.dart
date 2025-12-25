import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/atlas_settings.dart';
import '../models/sprite_region.dart';
import '../services/bin_packing_service.dart';
import '../services/export_service.dart';
import '../services/image_loader_service.dart';
import '../services/smart_packing_service.dart';
import 'multi_image_provider.dart';
import 'multi_sprite_provider.dart';

/// 패킹 모드 enum
enum PackingMode { standard, smart }

/// 스마트 패킹 모드 활성화 여부
final isSmartPackingModeProvider = StateProvider<bool>((ref) => false);

/// 개별 스케일 맵 (SmartMode에서만 사용)
final individualScalesProvider = StateProvider<Map<String, double>>((ref) => {});

/// Provider for atlas packing settings
final atlasSettingsProvider =
    StateNotifierProvider<AtlasSettingsNotifier, AtlasSettings>((ref) {
  return AtlasSettingsNotifier();
});

/// Notifier for managing atlas settings state
/// 옵션 변경 시 packingResultProvider가 자동으로 재계산됨 (캐시 무효화 불필요)
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

  void updateEdgeCrop(double value) {
    if (value >= 0 && value <= 64) {
      state = state.copyWith(edgeCrop: value);
    }
  }

  void toggleErosionAntiAlias() {
    state = state.copyWith(erosionAntiAlias: !state.erosionAntiAlias);
  }

  void toggleAllowRotation() {
    state = state.copyWith(allowRotation: !state.allowRotation);
  }

  void toggleTightPacking() {
    state = state.copyWith(tightPacking: !state.tightPacking);
  }
}

/// Provider for bin packing service
final binPackingServiceProvider = Provider<BinPackingService>((ref) {
  return BinPackingService();
});

/// Provider for smart packing service
final smartPackingServiceProvider = Provider<SmartPackingService>((ref) {
  return SmartPackingService();
});

/// Provider to determine if we're in merge mode (group or multi-select)
final isMergeModeProvider = Provider<bool>((ref) {
  final multiImageState = ref.watch(multiImageProvider);
  final selectedSources = multiImageState.selectedSources;

  // Merge mode when:
  // 1. Multiple sources selected (2+)
  // 2. Active source is in a group
  if (selectedSources.length > 1) return true;

  final activeSource = multiImageState.activeSource;
  if (activeSource != null && activeSource.groupId != null) {
    return true;
  }

  return false;
});

/// Provider for sources to include in atlas (based on merge mode)
final atlasSourcesProvider = Provider<List<LoadedSourceImage>>((ref) {
  final multiImageState = ref.watch(multiImageProvider);
  final selectedSources = multiImageState.selectedSources;

  // Multi-select mode
  if (selectedSources.length > 1) {
    return selectedSources;
  }

  // Check if active source is in a group
  final activeSource = multiImageState.activeSource;
  if (activeSource != null && activeSource.groupId != null) {
    // Return all sources in the same group
    return multiImageState.getSourcesInGroup(activeSource.groupId!);
  }

  // Single source mode
  if (activeSource != null) {
    return [activeSource];
  }

  return [];
});

/// Provider for sprites to include in atlas (merged from all atlas sources)
final atlasSpritesProvider = Provider<List<SpriteRegion>>((ref) {
  final atlasSources = ref.watch(atlasSourcesProvider);
  final multiSpriteState = ref.watch(multiSpriteProvider);

  final allSprites = <SpriteRegion>[];
  for (final source in atlasSources) {
    allSprites.addAll(multiSpriteState.getSpritesForSource(source.id));
  }

  return allSprites;
});


/// Provider for packing result - supports both SmartMode and StandardMode
/// SmartMode: 개별 스프라이트 스케일 조정으로 높은 efficiency
/// StandardMode: uniform outputScale로 일괄 스케일링
final packingResultProvider = Provider<PackingResult?>((ref) {
  final sprites = ref.watch(atlasSpritesProvider);
  final settings = ref.watch(atlasSettingsProvider);
  final isSmartMode = ref.watch(isSmartPackingModeProvider);

  if (sprites.isEmpty) {
    return null;
  }

  final effectivePadding = settings.tightPacking ? 0 : settings.padding;

  if (isSmartMode) {
    // SmartMode: SmartPackingService 사용 (개별 스케일 조정)
    final smartService = ref.watch(smartPackingServiceProvider);
    final smartResult = smartService.findOptimalPacking(
      sprites: sprites,
      canvasWidth: settings.maxWidth,
      canvasHeight: settings.maxHeight,
      padding: effectivePadding,
      allowRotation: settings.allowRotation,
    );

    // 개별 스케일 저장 (export에서 사용)
    // Note: Provider 내에서 다른 provider 수정 - WidgetsBinding.addPostFrameCallback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(individualScalesProvider.notifier).state = smartResult.individualScales;
    });

    print('[packingResultProvider] SmartMode: ${settings.maxWidth}x${settings.maxHeight}, '
        'efficiency=${(smartResult.efficiency * 100).toStringAsFixed(1)}%');

    return smartResult.packingResult;
  } else {
    // StandardMode: BinPackingService 사용 (uniform scale)
    final packingService = ref.watch(binPackingServiceProvider);

    print('[packingResultProvider] StandardMode: maxSize=${settings.maxWidth}x${settings.maxHeight}, '
        'outputScale=${settings.outputScale}, fixedSize=${settings.fixedSize}');

    final result = packingService.pack(
      sprites,
      maxWidth: settings.maxWidth,
      maxHeight: settings.maxHeight,
      padding: effectivePadding,
      powerOfTwo: settings.powerOfTwo,
      allowRotation: settings.allowRotation,
      outputScale: settings.outputScale,
      fixedSize: settings.fixedSize,
    );

    print('[packingResultProvider] result: ${result.atlasWidth}x${result.atlasHeight}, '
        'efficiency=${(result.efficiency * 100).toStringAsFixed(1)}%');

    return result;
  }
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
/// Automatically regenerates when atlas sources or sprites change
/// Uses ORIGINAL images for region mode (sprite extraction from source)
/// Uses PROCESSED images for separated mode (sprites have their own imageBytes)
/// Supports both single source and merge mode
/// Applies erosion based on edgeCrop setting
final atlasPreviewImageProvider = FutureProvider.autoDispose<ui.Image?>((ref) async {
  final atlasSources = ref.watch(atlasSourcesProvider);
  final settings = ref.watch(atlasSettingsProvider);

  // Reuse packingResultProvider instead of packing again
  // This ensures data consistency and avoids duplicate packing
  final packingResult = ref.watch(packingResultProvider);

  if (packingResult == null || packingResult.packedSprites.isEmpty || atlasSources.isEmpty) {
    return null;
  }

  // Build source images map
  // Use effectiveRawImage to respect background removal and other processing
  // - If background was removed, processedRawImage is used
  // - Otherwise, originalRawImage is used as fallback
  final sourceImages = <String, dynamic>{};
  for (final source in atlasSources) {
    // Use effectiveRawImage for atlas generation
    // - This respects background removal from AutoSlice dialog
    // - Region mode: sprites extracted from processed image using sourceRect
    // - Separated mode: sprites have imageBytes, so sourceImage is not used
    sourceImages[source.id] = source.effectiveRawImage;
  }

  // Generate atlas image using ExportService with erosion and outputScale applied
  final exportService = ref.read(_exportServiceProvider);
  final atlasImage = exportService.generateMultiSourceAtlasImage(
    sourceImages: sourceImages,
    packingResult: packingResult,
    erosionPixels: settings.edgeCrop,
    erosionAntiAlias: settings.erosionAntiAlias,
    outputScale: settings.outputScale,
  );

  // Convert img.Image to ui.Image for rendering
  final imageLoader = ImageLoaderService();
  return imageLoader.convertToUiImage(atlasImage);
});

/// Provider for active source sprites (backward compatibility)
final activeSourceSpritesProvider = Provider<List<SpriteRegion>>((ref) {
  final activeSource = ref.watch(activeSourceProvider);
  if (activeSource == null) return [];

  final multiSpriteState = ref.watch(multiSpriteProvider);
  return multiSpriteState.getSpritesForSource(activeSource.id);
});

