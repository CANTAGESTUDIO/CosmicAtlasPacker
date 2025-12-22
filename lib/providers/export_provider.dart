import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/export_service.dart';
import 'image_provider.dart';
import 'packing_provider.dart';

/// Provider for export service
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

/// Provider for generating atlas metadata
/// Automatically updates when packing result changes
final atlasMetadataProvider = Provider<AtlasMetadata?>((ref) {
  final packingResult = ref.watch(packingResultProvider);
  final exportService = ref.watch(exportServiceProvider);

  if (packingResult == null || packingResult.packedSprites.isEmpty) {
    return null;
  }

  return exportService.generateMetadata(
    packingResult: packingResult,
    atlasFileName: 'atlas.png',
  );
});

/// Provider for checking if export is possible
final canExportProvider = Provider<bool>((ref) {
  final sourceImage = ref.watch(sourceImageProvider);
  final packingResult = ref.watch(packingResultProvider);

  return sourceImage.hasImage &&
      sourceImage.rawImage != null &&
      packingResult != null &&
      packingResult.packedSprites.isNotEmpty;
});

/// Export state for tracking export operations
class ExportState {
  final bool isExporting;
  final String? lastPngPath;
  final String? lastJsonPath;
  final String? lastError;
  final bool? lastSuccess;

  const ExportState({
    this.isExporting = false,
    this.lastPngPath,
    this.lastJsonPath,
    this.lastError,
    this.lastSuccess,
  });

  ExportState copyWith({
    bool? isExporting,
    String? lastPngPath,
    String? lastJsonPath,
    String? lastError,
    bool? lastSuccess,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      lastPngPath: lastPngPath ?? this.lastPngPath,
      lastJsonPath: lastJsonPath ?? this.lastJsonPath,
      lastError: lastError,
      lastSuccess: lastSuccess,
    );
  }

  /// Whether the last export was cancelled by user
  bool get wasCancelled => lastSuccess == false && lastError == null;
}

/// Notifier for managing export operations
class ExportNotifier extends StateNotifier<ExportState> {
  final ExportService _exportService;
  final Ref _ref;

  ExportNotifier(this._exportService, this._ref) : super(const ExportState());

  /// Export atlas with save dialog (PNG + JSON)
  ///
  /// Returns true if export was successful, false otherwise
  Future<bool> exportWithDialog() async {
    final sourceImageState = _ref.read(sourceImageProvider);
    final packingResult = _ref.read(packingResultProvider);

    // Validate prerequisites
    if (sourceImageState.rawImage == null) {
      state = state.copyWith(
        isExporting: false,
        lastError: 'No source image loaded',
        lastSuccess: false,
      );
      return false;
    }

    if (packingResult == null || packingResult.packedSprites.isEmpty) {
      state = state.copyWith(
        isExporting: false,
        lastError: 'No sprites to export',
        lastSuccess: false,
      );
      return false;
    }

    state = state.copyWith(isExporting: true, lastError: null);

    try {
      // Get suggested filename from source file
      final suggestedName = sourceImageState.fileName
              ?.replaceAll(RegExp(r'\.[^.]+$'), '')
              .replaceAll(RegExp(r'[^\w\-]'), '_') ??
          'atlas';

      final result = await _exportService.exportWithDialog(
        sourceImage: sourceImageState.rawImage!,
        packingResult: packingResult,
        suggestedFileName: '${suggestedName}_atlas',
      );

      if (result == null) {
        // User cancelled
        state = state.copyWith(
          isExporting: false,
          lastSuccess: false,
        );
        return false;
      }

      state = ExportState(
        isExporting: false,
        lastPngPath: result.$1,
        lastJsonPath: result.$2,
        lastSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        lastError: 'Export failed: $e',
        lastSuccess: false,
      );
      return false;
    }
  }

  /// Export JSON metadata only to specified path
  ///
  /// [pngPath] - Path to the PNG file (JSON will be saved with same name)
  Future<bool> exportJson(String pngPath) async {
    final packingResult = _ref.read(packingResultProvider);

    if (packingResult == null || packingResult.packedSprites.isEmpty) {
      state = state.copyWith(
        isExporting: false,
        lastError: 'No sprites to export',
        lastSuccess: false,
      );
      return false;
    }

    state = state.copyWith(isExporting: true, lastError: null);

    try {
      final jsonPath = await _exportService.exportMetadataForAtlas(
        packingResult: packingResult,
        pngPath: pngPath,
      );

      state = state.copyWith(
        isExporting: false,
        lastJsonPath: jsonPath,
        lastSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        lastError: e.toString(),
        lastSuccess: false,
      );
      return false;
    }
  }

  /// Get JSON preview string (for debugging/display)
  String? getJsonPreview() {
    final metadata = _ref.read(atlasMetadataProvider);
    return metadata?.toJsonString();
  }

  /// Clear last export result
  void clearResult() {
    state = const ExportState();
  }
}

/// Provider for export state notifier
final exportNotifierProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final exportService = ref.watch(exportServiceProvider);
  return ExportNotifier(exportService, ref);
});
