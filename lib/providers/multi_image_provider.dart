import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../models/image_group.dart';
import '../services/image_loader_service.dart';

/// Loaded source image with original and processed images separated
class LoadedSourceImage {
  final String id;
  final String filePath;
  final String fileName;
  // 원본 이미지 (소스 패널용 - 절대 변경 안됨)
  final ui.Image originalUiImage;
  final img.Image originalRawImage;
  // 처리된 이미지 (아틀라스용 - 배경 제거 등 적용)
  final ui.Image? processedUiImage;
  final img.Image? processedRawImage;
  // 그룹 ID (null = 그룹 없음)
  final String? groupId;

  const LoadedSourceImage({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.originalUiImage,
    required this.originalRawImage,
    this.processedUiImage,
    this.processedRawImage,
    this.groupId,
  });

  /// Get dimensions from original image
  int get width => originalRawImage.width;
  int get height => originalRawImage.height;
  String get sizeInfo => '${width}x$height';

  /// Backward compatibility: uiImage returns original
  ui.Image get uiImage => originalUiImage;

  /// Backward compatibility: rawImage returns original
  img.Image get rawImage => originalRawImage;

  /// Get the effective image for atlas (processed if available, otherwise original)
  ui.Image get effectiveUiImage => processedUiImage ?? originalUiImage;
  img.Image get effectiveRawImage => processedRawImage ?? originalRawImage;

  /// Check if this source has been processed
  bool get hasProcessedImage => processedUiImage != null && processedRawImage != null;

  LoadedSourceImage copyWith({
    String? id,
    String? filePath,
    String? fileName,
    ui.Image? originalUiImage,
    img.Image? originalRawImage,
    ui.Image? processedUiImage,
    img.Image? processedRawImage,
    String? groupId,
    bool clearProcessed = false,
    bool clearGroup = false,
  }) {
    return LoadedSourceImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      originalUiImage: originalUiImage ?? this.originalUiImage,
      originalRawImage: originalRawImage ?? this.originalRawImage,
      processedUiImage: clearProcessed ? null : (processedUiImage ?? this.processedUiImage),
      processedRawImage: clearProcessed ? null : (processedRawImage ?? this.processedRawImage),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
    );
  }
}

/// State for managing multiple source images with group support
class MultiImageState {
  final List<LoadedSourceImage> sources;
  final String? activeSourceId;
  final Set<String> selectedSourceIds; // 다중 선택 지원
  final Map<String, ImageGroup> groups; // groupId → ImageGroup
  final bool isLoading;
  final String? error;
  final int _nextId;
  final int _nextGroupId;

  const MultiImageState({
    this.sources = const [],
    this.activeSourceId,
    this.selectedSourceIds = const {},
    this.groups = const {},
    this.isLoading = false,
    this.error,
    int nextId = 0,
    int nextGroupId = 0,
  })  : _nextId = nextId,
        _nextGroupId = nextGroupId;

  MultiImageState copyWith({
    List<LoadedSourceImage>? sources,
    String? activeSourceId,
    Set<String>? selectedSourceIds,
    Map<String, ImageGroup>? groups,
    bool? isLoading,
    String? error,
    int? nextId,
    int? nextGroupId,
    bool clearActiveSource = false,
    bool clearError = false,
  }) {
    return MultiImageState(
      sources: sources ?? this.sources,
      activeSourceId:
          clearActiveSource ? null : (activeSourceId ?? this.activeSourceId),
      selectedSourceIds: selectedSourceIds ?? this.selectedSourceIds,
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      nextId: nextId ?? _nextId,
      nextGroupId: nextGroupId ?? _nextGroupId,
    );
  }

  /// Get selected sources in order
  List<LoadedSourceImage> get selectedSources {
    return sources.where((s) => selectedSourceIds.contains(s.id)).toList();
  }

  /// Check if a source is selected
  bool isSelected(String id) => selectedSourceIds.contains(id);

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

  /// Generate next unique group ID
  String get nextGroupIdStr => 'group_$_nextGroupId';

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

  /// Get all group IDs
  List<String> get groupIds => groups.keys.toList();

  /// Get sources that belong to a specific group
  List<LoadedSourceImage> getSourcesInGroup(String groupId) {
    final group = groups[groupId];
    if (group == null) return [];
    return sources.where((s) => group.sourceIds.contains(s.id)).toList();
  }

  /// Get ungrouped sources
  List<LoadedSourceImage> get ungroupedSources {
    final groupedIds = groups.values.expand((g) => g.sourceIds).toSet();
    return sources.where((s) => !groupedIds.contains(s.id)).toList();
  }

  /// Check if source is in a group
  bool isSourceGrouped(String sourceId) {
    return groups.values.any((g) => g.sourceIds.contains(sourceId));
  }

  /// Get group for source
  ImageGroup? getGroupForSource(String sourceId) {
    try {
      return groups.values.firstWhere((g) => g.sourceIds.contains(sourceId));
    } catch (_) {
      return null;
    }
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
            originalUiImage: result.uiImage!,
            originalRawImage: result.rawImage!,
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

      // Always set first new source as active (user expects to see loaded image)
      final newActiveId = newSources.first.id;

      state = MultiImageState(
        sources: updatedSources,
        activeSourceId: newActiveId,
        selectedSourceIds: {newActiveId},
        groups: state.groups,
        isLoading: false,
        nextId: currentId,
        nextGroupId: state._nextGroupId,
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
            originalUiImage: result.uiImage!,
            originalRawImage: result.rawImage!,
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
        selectedSourceIds: {newSources.first.id},
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
        originalUiImage: result.uiImage!,
        originalRawImage: result.rawImage!,
      );

      final updatedSources = [...state.sources, newSource];
      final newActiveId = state.activeSourceId ?? newSource.id;

      state = MultiImageState(
        sources: updatedSources,
        activeSourceId: newActiveId,
        selectedSourceIds: {newActiveId},
        groups: state.groups,
        isLoading: false,
        nextId: state._nextId + 1,
        nextGroupId: state._nextGroupId,
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
            originalUiImage: result.uiImage!,
            originalRawImage: result.rawImage!,
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
        selectedSourceIds: {newActiveId},
        groups: state.groups,
        isLoading: false,
        nextId: currentId,
        nextGroupId: state._nextGroupId,
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

  /// Select a single source (일반 클릭: 활성화 + 선택 초기화)
  void selectSource(String id) {
    if (state.sources.any((s) => s.id == id)) {
      state = state.copyWith(
        activeSourceId: id,
        selectedSourceIds: {id},
      );
    }
  }

  /// Toggle source selection (Cmd/Ctrl + 클릭)
  void toggleSourceSelection(String id) {
    if (!state.sources.any((s) => s.id == id)) return;

    final newSelection = Set<String>.from(state.selectedSourceIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
      // 선택 해제 시 최소 1개는 유지
      if (newSelection.isEmpty && state.sources.isNotEmpty) {
        newSelection.add(state.activeSourceId ?? state.sources.first.id);
      }
    } else {
      newSelection.add(id);
    }
    state = state.copyWith(selectedSourceIds: newSelection);
  }

  /// Select range of sources (Shift + 클릭)
  void selectSourceRange(String fromId, String toId) {
    final fromIndex = state.sources.indexWhere((s) => s.id == fromId);
    final toIndex = state.sources.indexWhere((s) => s.id == toId);

    if (fromIndex == -1 || toIndex == -1) return;

    final startIdx = min(fromIndex, toIndex);
    final endIdx = max(fromIndex, toIndex);

    final rangeIds =
        state.sources.sublist(startIdx, endIdx + 1).map((s) => s.id).toSet();

    state = state.copyWith(
      selectedSourceIds: {...state.selectedSourceIds, ...rangeIds},
    );
  }

  /// Clear selection (활성 소스만 선택된 상태로)
  void clearSelection() {
    final activeId = state.activeSourceId;
    state = state.copyWith(
      selectedSourceIds: activeId != null ? {activeId} : {},
    );
  }

  /// Remove a source by ID
  void removeSource(String id) {
    final updatedSources = state.sources.where((s) => s.id != id).toList();
    final updatedSelection = Set<String>.from(state.selectedSourceIds)
      ..remove(id);

    // Remove from groups
    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    for (final entry in updatedGroups.entries.toList()) {
      final group = entry.value;
      if (group.sourceIds.contains(id)) {
        final newSourceIds = group.sourceIds.where((sid) => sid != id).toList();
        if (newSourceIds.isEmpty) {
          // Remove empty group
          updatedGroups.remove(entry.key);
        } else {
          updatedGroups[entry.key] = group.copyWith(sourceIds: newSourceIds);
        }
      }
    }

    String? newActiveId = state.activeSourceId;
    if (state.activeSourceId == id) {
      // If removing active source, select next available
      newActiveId = updatedSources.isNotEmpty ? updatedSources.first.id : null;
    }

    // 선택이 비어있으면 활성 소스를 선택에 추가
    if (updatedSelection.isEmpty && newActiveId != null) {
      updatedSelection.add(newActiveId);
    }

    state = state.copyWith(
      sources: updatedSources,
      activeSourceId: newActiveId,
      selectedSourceIds: updatedSelection,
      groups: updatedGroups,
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

  /// Update processed image for a source (원본은 유지)
  /// Used after background removal or other image processing
  void updateProcessedImage(
    String sourceId, {
    required img.Image processedRaw,
    required ui.Image processedUi,
  }) {
    final updatedSources = state.sources.map((source) {
      if (source.id == sourceId) {
        return source.copyWith(
          processedRawImage: processedRaw,
          processedUiImage: processedUi,
        );
      }
      return source;
    }).toList();

    state = state.copyWith(sources: updatedSources);
    debugPrint('[MultiImageNotifier] Updated processed image for $sourceId');
  }

  /// Update the active source image with new raw and UI images (backward compatibility)
  /// Now updates processed images, keeping originals intact
  Future<void> updateActiveSourceImage({
    required img.Image rawImage,
    required ui.Image uiImage,
  }) async {
    final activeId = state.activeSourceId;
    if (activeId == null) return;

    updateProcessedImage(
      activeId,
      processedRaw: rawImage,
      processedUi: uiImage,
    );
  }

  /// Update a specific source image by ID
  Future<void> updateSourceImage({
    required String sourceId,
    required img.Image rawImage,
    required ui.Image uiImage,
  }) async {
    updateProcessedImage(
      sourceId,
      processedRaw: rawImage,
      processedUi: uiImage,
    );
  }

  /// Clear processed image for a source (revert to original)
  void clearProcessedImage(String sourceId) {
    final updatedSources = state.sources.map((source) {
      if (source.id == sourceId) {
        return source.copyWith(clearProcessed: true);
      }
      return source;
    }).toList();

    state = state.copyWith(sources: updatedSources);
  }

  /// Rename a source
  void renameSource(String sourceId, String newName) {
    final updatedSources = state.sources.map((source) {
      if (source.id == sourceId) {
        return source.copyWith(fileName: newName);
      }
      return source;
    }).toList();

    state = state.copyWith(sources: updatedSources);
    debugPrint('[MultiImageNotifier] Renamed source $sourceId to $newName');
  }

  // ==================== Group Management ====================

  /// Create a group from selected sources (Merge)
  String createGroup(List<String> sourceIds, {String? name}) {
    if (sourceIds.length < 2) {
      debugPrint('[MultiImageNotifier] Cannot create group with less than 2 sources');
      return '';
    }

    final groupId = state.nextGroupIdStr;
    final groupName = name ?? 'Group ${state._nextGroupId + 1}';

    final newGroup = ImageGroup(
      id: groupId,
      name: groupName,
      sourceIds: sourceIds,
      isExpanded: true,
      createdAt: DateTime.now(),
    );

    // Update sources with groupId
    final updatedSources = state.sources.map((source) {
      if (sourceIds.contains(source.id)) {
        return source.copyWith(groupId: groupId);
      }
      return source;
    }).toList();

    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups[groupId] = newGroup;

    state = state.copyWith(
      sources: updatedSources,
      groups: updatedGroups,
      nextGroupId: state._nextGroupId + 1,
    );

    debugPrint('[MultiImageNotifier] Created group $groupId with ${sourceIds.length} sources');
    return groupId;
  }

  /// Toggle group expansion (펼침/접힘)
  void toggleGroupExpansion(String groupId) {
    final group = state.groups[groupId];
    if (group == null) return;

    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups[groupId] = group.copyWith(isExpanded: !group.isExpanded);

    state = state.copyWith(groups: updatedGroups);
  }

  /// Expand group
  void expandGroup(String groupId) {
    final group = state.groups[groupId];
    if (group == null || group.isExpanded) return;

    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups[groupId] = group.copyWith(isExpanded: true);

    state = state.copyWith(groups: updatedGroups);
  }

  /// Collapse group
  void collapseGroup(String groupId) {
    final group = state.groups[groupId];
    if (group == null || !group.isExpanded) return;

    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups[groupId] = group.copyWith(isExpanded: false);

    state = state.copyWith(groups: updatedGroups);
  }

  /// Ungroup sources (해제)
  void ungroupSources(String groupId) {
    final group = state.groups[groupId];
    if (group == null) return;

    // Remove groupId from sources
    final updatedSources = state.sources.map((source) {
      if (group.sourceIds.contains(source.id)) {
        return source.copyWith(clearGroup: true);
      }
      return source;
    }).toList();

    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups.remove(groupId);

    state = state.copyWith(
      sources: updatedSources,
      groups: updatedGroups,
    );

    debugPrint('[MultiImageNotifier] Ungrouped $groupId');
  }

  /// Rename group
  void renameGroup(String groupId, String newName) {
    final group = state.groups[groupId];
    if (group == null) return;

    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups[groupId] = group.copyWith(name: newName);

    state = state.copyWith(groups: updatedGroups);
  }

  /// Select all sources in a group (multi-select)
  void selectGroupMembers(String groupId) {
    final group = state.groups[groupId];
    if (group == null || group.sourceIds.isEmpty) return;

    // Set first source as active if none selected
    final firstSourceId = group.sourceIds.first;
    final newActiveId = state.activeSourceId ?? firstSourceId;

    // Select all sources in the group
    final newSelectedIds = Set<String>.from(group.sourceIds);

    state = state.copyWith(
      activeSourceId: newActiveId,
      selectedSourceIds: newSelectedIds,
    );
  }

  /// Add source to existing group
  void addSourceToGroup(String sourceId, String groupId) {
    final group = state.groups[groupId];
    if (group == null) return;
    if (group.sourceIds.contains(sourceId)) return;

    // Update source
    final updatedSources = state.sources.map((source) {
      if (source.id == sourceId) {
        return source.copyWith(groupId: groupId);
      }
      return source;
    }).toList();

    // Update group
    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    updatedGroups[groupId] = group.copyWith(
      sourceIds: [...group.sourceIds, sourceId],
    );

    state = state.copyWith(
      sources: updatedSources,
      groups: updatedGroups,
    );
  }

  /// Remove source from group
  void removeSourceFromGroup(String sourceId, String groupId) {
    final group = state.groups[groupId];
    if (group == null) return;

    // Update source
    final updatedSources = state.sources.map((source) {
      if (source.id == sourceId) {
        return source.copyWith(clearGroup: true);
      }
      return source;
    }).toList();

    // Update or remove group
    final updatedGroups = Map<String, ImageGroup>.from(state.groups);
    final newSourceIds = group.sourceIds.where((id) => id != sourceId).toList();

    if (newSourceIds.length < 2) {
      // Group needs at least 2 sources, remove it
      updatedGroups.remove(groupId);
      // Clear groupId from remaining source
      final finalSources = updatedSources.map((source) {
        if (newSourceIds.contains(source.id)) {
          return source.copyWith(clearGroup: true);
        }
        return source;
      }).toList();
      state = state.copyWith(sources: finalSources, groups: updatedGroups);
    } else {
      updatedGroups[groupId] = group.copyWith(sourceIds: newSourceIds);
      state = state.copyWith(sources: updatedSources, groups: updatedGroups);
    }
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

/// Provider for selected sources (다중 선택된 소스 목록)
final selectedSourcesProvider = Provider<List<LoadedSourceImage>>((ref) {
  final state = ref.watch(multiImageProvider);
  return state.selectedSources;
});

/// Provider for groups
final imageGroupsProvider = Provider<Map<String, ImageGroup>>((ref) {
  return ref.watch(multiImageProvider).groups;
});

/// Provider for ungrouped sources
final ungroupedSourcesProvider = Provider<List<LoadedSourceImage>>((ref) {
  return ref.watch(multiImageProvider).ungroupedSources;
});
