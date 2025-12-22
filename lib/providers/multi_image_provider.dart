import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../services/image_loader_service.dart';

/// Loaded source image with its associated data
class LoadedSourceImage {
  final String id;
  final String filePath;
  final String fileName;
  final ui.Image uiImage;
  final img.Image rawImage;

  const LoadedSourceImage({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.uiImage,
    required this.rawImage,
  });

  int get width => rawImage.width;
  int get height => rawImage.height;
  String get sizeInfo => '${width}x$height';

  LoadedSourceImage copyWith({
    String? id,
    String? filePath,
    String? fileName,
    ui.Image? uiImage,
    img.Image? rawImage,
  }) {
    return LoadedSourceImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      uiImage: uiImage ?? this.uiImage,
      rawImage: rawImage ?? this.rawImage,
    );
  }
}

/// State for managing multiple source images
class MultiImageState {
  final List<LoadedSourceImage> sources;
  final String? activeSourceId;
  final bool isLoading;
  final String? error;
  final int _nextId;

  const MultiImageState({
    this.sources = const [],
    this.activeSourceId,
    this.isLoading = false,
    this.error,
    int nextId = 0,
  }) : _nextId = nextId;

  MultiImageState copyWith({
    List<LoadedSourceImage>? sources,
    String? activeSourceId,
    bool? isLoading,
    String? error,
    int? nextId,
    bool clearActiveSource = false,
    bool clearError = false,
  }) {
    return MultiImageState(
      sources: sources ?? this.sources,
      activeSourceId:
          clearActiveSource ? null : (activeSourceId ?? this.activeSourceId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      nextId: nextId ?? _nextId,
    );
  }

  /// Get the currently active source image
  LoadedSourceImage? get activeSource {
    if (activeSourceId == null) return null;
    try {
      return sources.firstWhere((s) => s.id == activeSourceId);
    } catch (_) {
      return sources.isNotEmpty ? sources.first : null;
    }
  }

  /// Check if there are any source images
  bool get hasImages => sources.isNotEmpty;

  /// Total count of loaded sources
  int get sourceCount => sources.length;

  /// Generate next unique ID
  String get nextSourceId => 'source_$_nextId';

  /// Get source by ID
  LoadedSourceImage? getSourceById(String id) {
    try {
      return sources.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get source index
  int getSourceIndex(String id) {
    return sources.indexWhere((s) => s.id == id);
  }
}

/// Notifier for managing multiple source images
class MultiImageNotifier extends StateNotifier<MultiImageState> {
  final ImageLoaderService _imageLoader;
  bool _isPickerOpen = false; // Prevent multiple file picker instances

  MultiImageNotifier(this._imageLoader) : super(const MultiImageState());

  /// Open file picker and load selected images (supports multiple selection)
  Future<void> pickAndLoadImages() async {
    // Prevent opening multiple file pickers simultaneously
    if (_isPickerOpen || state.isLoading) {
      debugPrint('[MultiImageNotifier] Picker already open or loading, ignoring');
      return;
    }

    debugPrint('[MultiImageNotifier] pickAndLoadImages called');
    _isPickerOpen = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await _imageLoader.pickAndLoadMultipleImages();
      debugPrint(
          '[MultiImageNotifier] Loaded ${results.length} images, cancelled=${results.isEmpty}');

      if (results.isEmpty) {
        // User cancelled or no files selected
        state = state.copyWith(isLoading: false);
        _isPickerOpen = false;
        return;
      }

      final newSources = <LoadedSourceImage>[];
      int currentId = state._nextId;

      for (final result in results) {
        if (result.isSuccess) {
          final fileName = result.filePath?.split('/').last ?? 'Unknown';
          newSources.add(LoadedSourceImage(
            id: 'source_$currentId',
            filePath: result.filePath!,
            fileName: fileName,
            uiImage: result.uiImage!,
            rawImage: result.rawImage!,
          ));
          currentId++;
        } else {
          debugPrint(
              '[MultiImageNotifier] Failed to load: ${result.filePath}, error=${result.error}');
        }
      }

      if (newSources.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load any images',
        );
        _isPickerOpen = false;
        return;
      }

      // Add new sources to existing list
      final updatedSources = [...state.sources, ...newSources];

      // Set first new source as active if no current active
      final newActiveId = state.activeSourceId ?? newSources.first.id;

      state = MultiImageState(
        sources: updatedSources,
        activeSourceId: newActiveId,
        isLoading: false,
        nextId: currentId,
      );

      debugPrint(
          '[MultiImageNotifier] Now have ${state.sourceCount} sources, active=$newActiveId');
    } catch (e) {
      debugPrint('[MultiImageNotifier] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load images: $e',
      );
    } finally {
      _isPickerOpen = false;
    }
  }

  /// Load images from specific paths (for project loading)
  Future<void> loadFromPaths(List<String> paths) async {
    if (paths.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final newSources = <LoadedSourceImage>[];
      int currentId = state._nextId;

      for (final path in paths) {
        final result = await _imageLoader.loadImageFromPath(path);
        if (result.isSuccess) {
          final fileName = path.split('/').last;
          newSources.add(LoadedSourceImage(
            id: 'source_$currentId',
            filePath: path,
            fileName: fileName,
            uiImage: result.uiImage!,
            rawImage: result.rawImage!,
          ));
          currentId++;
        }
      }

      if (newSources.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load any images from paths',
        );
        return;
      }

      state = MultiImageState(
        sources: newSources,
        activeSourceId: newSources.first.id,
        isLoading: false,
        nextId: currentId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load images: $e',
      );
    }
  }

  /// Add a single image from path
  Future<void> addImageFromPath(String path) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _imageLoader.loadImageFromPath(path);

      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Failed to load image',
        );
        return;
      }

      final fileName = path.split('/').last;
      final newSource = LoadedSourceImage(
        id: state.nextSourceId,
        filePath: path,
        fileName: fileName,
        uiImage: result.uiImage!,
        rawImage: result.rawImage!,
      );

      final updatedSources = [...state.sources, newSource];
      final newActiveId = state.activeSourceId ?? newSource.id;

      state = MultiImageState(
        sources: updatedSources,
        activeSourceId: newActiveId,
        isLoading: false,
        nextId: state._nextId + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load image: $e',
      );
    }
  }

  /// Add multiple images from paths (for drag & drop)
  Future<void> addImagesFromPaths(List<String> paths) async {
    if (paths.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final newSources = <LoadedSourceImage>[];
      int currentId = state._nextId;

      for (final path in paths) {
        // Only process PNG files
        if (!path.toLowerCase().endsWith('.png')) continue;

        final result = await _imageLoader.loadImageFromPath(path);
        if (result.isSuccess) {
          final fileName = path.split('/').last;
          newSources.add(LoadedSourceImage(
            id: 'source_$currentId',
            filePath: path,
            fileName: fileName,
            uiImage: result.uiImage!,
            rawImage: result.rawImage!,
          ));
          currentId++;
        }
      }

      if (newSources.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final updatedSources = [...state.sources, ...newSources];
      final newActiveId = state.activeSourceId ?? newSources.first.id;

      state = MultiImageState(
        sources: updatedSources,
        activeSourceId: newActiveId,
        isLoading: false,
        nextId: currentId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load images: $e',
      );
    }
  }

  /// Set the active source by ID
  void setActiveSource(String id) {
    if (state.sources.any((s) => s.id == id)) {
      state = state.copyWith(activeSourceId: id);
    }
  }

  /// Remove a source by ID
  void removeSource(String id) {
    final updatedSources = state.sources.where((s) => s.id != id).toList();

    String? newActiveId = state.activeSourceId;
    if (state.activeSourceId == id) {
      // If removing active source, select next available
      newActiveId = updatedSources.isNotEmpty ? updatedSources.first.id : null;
    }

    state = state.copyWith(
      sources: updatedSources,
      activeSourceId: newActiveId,
      clearActiveSource: newActiveId == null,
    );
  }

  /// Clear all sources
  void clearAll() {
    state = const MultiImageState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Update the active source image with new raw and UI images
  /// Used after background removal or other image processing
  Future<void> updateActiveSourceImage({
    required img.Image rawImage,
    required ui.Image uiImage,
  }) async {
    final activeId = state.activeSourceId;
    if (activeId == null) return;

    final updatedSources = state.sources.map((source) {
      if (source.id == activeId) {
        return source.copyWith(
          rawImage: rawImage,
          uiImage: uiImage,
        );
      }
      return source;
    }).toList();

    state = state.copyWith(sources: updatedSources);
  }
}

/// Provider for ImageLoaderService (reuse from image_provider if available)
final multiImageLoaderServiceProvider = Provider<ImageLoaderService>((ref) {
  return ImageLoaderService();
});

/// Provider for multi-image state
final multiImageProvider =
    StateNotifierProvider<MultiImageNotifier, MultiImageState>((ref) {
  final imageLoader = ref.watch(multiImageLoaderServiceProvider);
  return MultiImageNotifier(imageLoader);
});

/// Provider for currently active source image
final activeSourceProvider = Provider<LoadedSourceImage?>((ref) {
  return ref.watch(multiImageProvider).activeSource;
});

/// Provider for source count
final sourceCountProvider = Provider<int>((ref) {
  return ref.watch(multiImageProvider).sourceCount;
});

/// Provider to check if loading
final isLoadingSourcesProvider = Provider<bool>((ref) {
  return ref.watch(multiImageProvider).isLoading;
});
