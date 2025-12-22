import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../services/image_loader_service.dart';

/// State for loaded source image
class SourceImageState {
  final ui.Image? uiImage;
  final img.Image? rawImage;
  final String? filePath;
  final String? fileName;
  final bool isLoading;
  final String? error;

  const SourceImageState({
    this.uiImage,
    this.rawImage,
    this.filePath,
    this.fileName,
    this.isLoading = false,
    this.error,
  });

  SourceImageState copyWith({
    ui.Image? uiImage,
    img.Image? rawImage,
    String? filePath,
    String? fileName,
    bool? isLoading,
    String? error,
  }) {
    return SourceImageState(
      uiImage: uiImage ?? this.uiImage,
      rawImage: rawImage ?? this.rawImage,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasImage => uiImage != null;

  int get width => rawImage?.width ?? 0;
  int get height => rawImage?.height ?? 0;

  String get sizeInfo => hasImage ? '${width}x$height' : 'No image';

  /// Alias for filePath
  String? get imagePath => filePath;
}

/// Notifier for source image state
class SourceImageNotifier extends StateNotifier<SourceImageState> {
  final ImageLoaderService _imageLoader;

  SourceImageNotifier(this._imageLoader) : super(const SourceImageState());

  /// Pick and load image from file picker
  Future<void> pickAndLoadImage() async {
    debugPrint('[SourceImageNotifier] pickAndLoadImage called');
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[SourceImageNotifier] Set isLoading=true');

    final result = await _imageLoader.pickAndLoadImage();
    debugPrint('[SourceImageNotifier] pickAndLoadImage result: isSuccess=${result.isSuccess}, isCancelled=${result.isCancelled}, error=${result.error}');

    if (result.isCancelled) {
      // User cancelled, restore previous state
      debugPrint('[SourceImageNotifier] User cancelled');
      state = state.copyWith(isLoading: false);
      return;
    }

    if (!result.isSuccess) {
      debugPrint('[SourceImageNotifier] Load failed: ${result.error}');
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return;
    }

    // Extract filename from path
    final fileName = result.filePath?.split('/').last ?? 'Unknown';
    debugPrint('[SourceImageNotifier] Success! fileName=$fileName');

    state = SourceImageState(
      uiImage: result.uiImage,
      rawImage: result.rawImage,
      filePath: result.filePath,
      fileName: fileName,
      isLoading: false,
    );
    debugPrint('[SourceImageNotifier] State updated, isLoading=${state.isLoading}');
  }

  /// Load image from specific path
  Future<void> loadImageFromPath(String path) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _imageLoader.loadImageFromPath(path);

    if (!result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return;
    }

    final fileName = path.split('/').last;

    state = SourceImageState(
      uiImage: result.uiImage,
      rawImage: result.rawImage,
      filePath: path,
      fileName: fileName,
      isLoading: false,
    );
  }

  /// Clear loaded image
  void clearImage() {
    state = const SourceImageState();
  }

  /// Clear (alias for clearImage)
  void clear() {
    clearImage();
  }

  /// Load from path (alias for loadImageFromPath)
  Future<void> loadFromPath(String path) async {
    await loadImageFromPath(path);
  }

  /// Get current image path
  String? get imagePath => state.filePath;

  /// Set state directly from external source (for multi-image sync)
  void setFromSource({
    required ui.Image uiImage,
    required img.Image rawImage,
    required String filePath,
    required String fileName,
  }) {
    state = SourceImageState(
      uiImage: uiImage,
      rawImage: rawImage,
      filePath: filePath,
      fileName: fileName,
      isLoading: false,
    );
  }

  /// Update raw image (e.g., after background removal) and regenerate ui.Image
  Future<void> updateRawImage(img.Image newRawImage) async {
    state = state.copyWith(isLoading: true);

    try {
      // Convert to ui.Image
      final uiImage = await _imageLoader.convertToUiImage(newRawImage);

      if (uiImage != null) {
        state = state.copyWith(
          rawImage: newRawImage,
          uiImage: uiImage,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to convert processed image',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating image: $e',
      );
    }
  }
}

/// Provider for image loader service
final imageLoaderServiceProvider = Provider<ImageLoaderService>((ref) {
  return ImageLoaderService();
});

/// Provider for source image state
final sourceImageProvider =
    StateNotifierProvider<SourceImageNotifier, SourceImageState>((ref) {
  final imageLoader = ref.watch(imageLoaderServiceProvider);
  return SourceImageNotifier(imageLoader);
});
