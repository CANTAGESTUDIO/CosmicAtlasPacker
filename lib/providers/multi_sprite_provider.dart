import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sprite_data.dart';
import '../models/sprite_region.dart';
import '../services/auto_slicer_service.dart' show AutoSliceResult, SpriteImageUtils;
import '../services/grid_slicer_service.dart';
import 'multi_image_provider.dart';

/// State for managing sprites across multiple source images
class MultiSpriteState {
  /// All sprites mapped by source file ID
  final Map<String, List<SpriteRegion>> spritesBySource;

  /// Currently selected sprite IDs
  final Set<String> selectedIds;

  /// Next ID counter
  final int nextId;

  const MultiSpriteState({
    this.spritesBySource = const {},
    this.selectedIds = const {},
    this.nextId = 0,
  });

  MultiSpriteState copyWith({
    Map<String, List<SpriteRegion>>? spritesBySource,
    Set<String>? selectedIds,
    int? nextId,
  }) {
    return MultiSpriteState(
      spritesBySource: spritesBySource ?? this.spritesBySource,
      selectedIds: selectedIds ?? this.selectedIds,
      nextId: nextId ?? this.nextId,
    );
  }

  /// Get sprites for a specific source
  List<SpriteRegion> getSpritesForSource(String sourceId) {
    return spritesBySource[sourceId] ?? [];
  }

  /// Get all sprites across all sources
  List<SpriteRegion> get allSprites {
    return spritesBySource.values.expand((list) => list).toList();
  }

  /// Get selected sprites
  List<SpriteRegion> get selectedSprites {
    return allSprites.where((s) => selectedIds.contains(s.id)).toList();
  }

  /// Check if any sprite is selected
  bool get hasSelection => selectedIds.isNotEmpty;

  /// Total sprite count across all sources
  int get totalCount => allSprites.length;

  /// Sprite count for a specific source
  int countForSource(String sourceId) => getSpritesForSource(sourceId).length;
}

/// Notifier for managing sprites across multiple source images
class MultiSpriteNotifier extends StateNotifier<MultiSpriteState> {
  MultiSpriteNotifier() : super(const MultiSpriteState());

  /// Generate unique sprite ID
  String _generateId() {
    final id = 'sprite_${state.nextId}';
    state = state.copyWith(nextId: state.nextId + 1);
    return id;
  }

  /// Add a new sprite region for a specific source
  void addSprite(String sourceId, Rect rect) {
    // Validate minimum size
    if (rect.width < 1 || rect.height < 1) return;

    // Normalize rect
    final normalizedRect = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left < rect.right ? rect.right : rect.left,
      rect.top < rect.bottom ? rect.bottom : rect.top,
    );

    final sprite = SpriteRegion(
      id: _generateId(),
      sourceRect: normalizedRect,
      sourceFileId: sourceId,
    );

    final currentSprites = state.getSpritesForSource(sourceId);
    final updatedSprites = Map<String, List<SpriteRegion>>.from(state.spritesBySource);
    updatedSprites[sourceId] = [...currentSprites, sprite];

    state = state.copyWith(spritesBySource: updatedSprites);
  }

  /// Remove sprite by ID
  void removeSprite(String id) {
    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      final filtered = entry.value.where((s) => s.id != id).toList();
      if (filtered.isNotEmpty) {
        updatedSprites[entry.key] = filtered;
      }
    }

    state = state.copyWith(
      spritesBySource: updatedSprites,
      selectedIds: Set.from(state.selectedIds)..remove(id),
    );
  }

  /// Remove all selected sprites
  void removeSelected() {
    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      final filtered =
          entry.value.where((s) => !state.selectedIds.contains(s.id)).toList();
      if (filtered.isNotEmpty) {
        updatedSprites[entry.key] = filtered;
      }
    }

    state = state.copyWith(
      spritesBySource: updatedSprites,
      selectedIds: {},
    );
  }

  /// Remove all sprites for a specific source
  void removeSpritesForSource(String sourceId) {
    final updatedSprites = Map<String, List<SpriteRegion>>.from(state.spritesBySource);
    final removedSprites = updatedSprites.remove(sourceId) ?? [];

    // Remove from selection
    final removedIds = removedSprites.map((s) => s.id).toSet();
    final updatedSelection = state.selectedIds.difference(removedIds);

    state = state.copyWith(
      spritesBySource: updatedSprites,
      selectedIds: updatedSelection,
    );
  }

  /// Select a sprite
  void selectSprite(String id, {bool toggle = false, bool addToSelection = false}) {
    if (toggle) {
      final newSelection = Set<String>.from(state.selectedIds);
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
      state = state.copyWith(selectedIds: newSelection);
    } else if (addToSelection) {
      state = state.copyWith(selectedIds: {...state.selectedIds, id});
    } else {
      state = state.copyWith(selectedIds: {id});
    }
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Select all sprites in a specific source
  void selectAllInSource(String sourceId) {
    final sprites = state.getSpritesForSource(sourceId);
    state = state.copyWith(
      selectedIds: sprites.map((s) => s.id).toSet(),
    );
  }

  /// Clear all sprites
  void clearAll() {
    state = const MultiSpriteState();
  }

  /// Clear sprites for a specific source
  void clearSource(String sourceId) {
    final updatedSprites = Map<String, List<SpriteRegion>>.from(state.spritesBySource);
    updatedSprites.remove(sourceId);
    state = state.copyWith(spritesBySource: updatedSprites);
  }

  /// Replace all sprites for a specific source
  /// Used for undo/redo operations
  void replaceSpritesForSource(String sourceId, List<SpriteRegion> sprites) {
    final updatedSprites = Map<String, List<SpriteRegion>>.from(state.spritesBySource);

    if (sprites.isEmpty) {
      updatedSprites.remove(sourceId);
    } else {
      updatedSprites[sourceId] = sprites;
    }

    // Update selection to only include sprites that still exist
    final existingIds = sprites.map((s) => s.id).toSet();
    final updatedSelection = state.selectedIds.where(existingIds.contains).toSet();

    state = state.copyWith(
      spritesBySource: updatedSprites,
      selectedIds: updatedSelection,
    );
  }

  /// Add sprites from grid slicing result for a specific source
  void addFromGridSlice(String sourceId, GridSliceResult result) {
    int currentId = state.nextId;

    // Create sprites with source file ID
    final spritesWithSource = result.sprites.map((s) {
      return s.copyWith(
        id: 'sprite_$currentId',
        sourceFileId: sourceId,
      );
    }).toList();

    currentId += spritesWithSource.length;

    final updatedSprites = Map<String, List<SpriteRegion>>.from(state.spritesBySource);
    updatedSprites[sourceId] = spritesWithSource;

    state = state.copyWith(
      spritesBySource: updatedSprites,
      nextId: currentId,
    );
  }

  /// Add sprites from auto slicing result for a specific source
  ///
  /// This method creates ui.Image for each sprite from imageBytes for canvas rendering.
  Future<void> addFromAutoSlice(String sourceId, AutoSliceResult result) async {
    int currentId = state.nextId;

    // Create sprites with source file ID and ui.Image
    final spritesWithSource = <SpriteRegion>[];

    for (final s in result.sprites) {
      final newSprite = s.copyWith(
        id: 'sprite_$currentId',
        sourceFileId: sourceId,
      );
      currentId++;

      // Create ui.Image from imageBytes for canvas rendering
      if (newSprite.hasImageData) {
        final uiImage = await SpriteImageUtils.createUiImage(
          newSprite.imageBytes!,
          newSprite.width,
          newSprite.height,
        );
        spritesWithSource.add(newSprite.copyWith(uiImage: uiImage));
      } else {
        spritesWithSource.add(newSprite);
      }
    }

    final updatedSprites = Map<String, List<SpriteRegion>>.from(state.spritesBySource);
    updatedSprites[sourceId] = spritesWithSource;

    state = state.copyWith(
      spritesBySource: updatedSprites,
      nextId: currentId,
    );
  }

  /// Hit test for sprites in a specific source
  SpriteRegion? hitTest(String sourceId, Offset point) {
    final sprites = state.getSpritesForSource(sourceId);
    for (final sprite in sprites.reversed) {
      if (sprite.sourceRect.contains(point)) {
        return sprite;
      }
    }
    return null;
  }

  /// Update sprite ID
  void updateSpriteId(String oldId, String newId) {
    if (oldId == newId) return;
    if (state.allSprites.any((s) => s.id == newId)) return;

    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      updatedSprites[entry.key] = entry.value.map((s) {
        if (s.id == oldId) {
          return s.copyWith(id: newId);
        }
        return s;
      }).toList();
    }

    state = state.copyWith(
      spritesBySource: updatedSprites,
      selectedIds: state.selectedIds.map((id) {
        return id == oldId ? newId : id;
      }).toSet(),
    );
  }

  /// Update pivot for a sprite
  void updateSpritePivot(String id, PivotPoint pivot) {
    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      updatedSprites[entry.key] = entry.value.map((s) {
        if (s.id == id) {
          return s.copyWith(pivot: pivot);
        }
        return s;
      }).toList();
    }

    state = state.copyWith(spritesBySource: updatedSprites);
  }

  /// Update sprite rect
  void updateSpriteRect(String id, {double? x, double? y, int? width, int? height}) {
    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      updatedSprites[entry.key] = entry.value.map((s) {
        if (s.id == id) {
          final currentRect = s.sourceRect;
          final newRect = Rect.fromLTWH(
            x ?? currentRect.left,
            y ?? currentRect.top,
            (width ?? currentRect.width.toInt()).toDouble(),
            (height ?? currentRect.height.toInt()).toDouble(),
          );
          return s.copyWith(sourceRect: newRect);
        }
        return s;
      }).toList();
    }

    state = state.copyWith(spritesBySource: updatedSprites);
  }

  /// Move sprite by delta offset
  void moveSprite(String id, Offset delta) {
    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      updatedSprites[entry.key] = entry.value.map((s) {
        if (s.id == id) {
          final currentRect = s.sourceRect;
          return s.copyWith(
            sourceRect: currentRect.translate(delta.dx, delta.dy),
          );
        }
        return s;
      }).toList();
    }

    state = state.copyWith(spritesBySource: updatedSprites);
  }

  /// Move multiple selected sprites by delta offset
  void moveSelectedSprites(Offset delta) {
    if (!state.hasSelection) return;

    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      updatedSprites[entry.key] = entry.value.map((s) {
        if (state.selectedIds.contains(s.id)) {
          final currentRect = s.sourceRect;
          return s.copyWith(
            sourceRect: currentRect.translate(delta.dx, delta.dy),
          );
        }
        return s;
      }).toList();
    }

    state = state.copyWith(spritesBySource: updatedSprites);
  }

  /// Hit test with pivot priority (sprites with pivots closer to point are prioritized)
  SpriteRegion? hitTestWithPivotPriority(String sourceId, Offset point) {
    final sprites = state.getSpritesForSource(sourceId);
    if (sprites.isEmpty) return null;

    SpriteRegion? bestMatch;
    double bestPivotDistance = double.infinity;
    bool bestHasPivotHit = false;

    for (final sprite in sprites.reversed) {
      if (!sprite.sourceRect.contains(point)) continue;

      // Calculate pivot position
      final pivotPos = sprite.pivotPosition;
      final pivotDistance = (pivotPos - point).distance;

      // Check if point is near pivot (within 8 pixels)
      const pivotHitRadius = 8.0;
      final hasPivotHit = pivotDistance <= pivotHitRadius;

      // Prioritize: 1) pivot hit, 2) closest pivot
      if (hasPivotHit && !bestHasPivotHit) {
        // This sprite has pivot hit, previous best doesn't
        bestMatch = sprite;
        bestPivotDistance = pivotDistance;
        bestHasPivotHit = true;
      } else if (hasPivotHit && bestHasPivotHit) {
        // Both have pivot hit, choose closest
        if (pivotDistance < bestPivotDistance) {
          bestMatch = sprite;
          bestPivotDistance = pivotDistance;
        }
      } else if (!bestHasPivotHit) {
        // Neither has pivot hit, choose first match (top-most)
        if (bestMatch == null) {
          bestMatch = sprite;
          bestPivotDistance = pivotDistance;
        }
      }
    }

    return bestMatch;
  }

  /// Get sprite by ID
  SpriteRegion? getSpriteById(String id) {
    for (final sprites in state.spritesBySource.values) {
      for (final sprite in sprites) {
        if (sprite.id == id) return sprite;
      }
    }
    return null;
  }

  /// Load sprites from saved project
  void loadFromProject(List<SpriteData> spriteDataList, String defaultSourceId) {
    if (spriteDataList.isEmpty) {
      clearAll();
      return;
    }

    // Group sprites by source file
    final spritesBySource = <String, List<SpriteRegion>>{};
    int maxIdNum = 0;

    for (final data in spriteDataList) {
      final sourceId = data.sourceFile.isNotEmpty ? data.sourceFile : defaultSourceId;

      final sprite = SpriteRegion(
        id: data.id,
        sourceRect: data.sourceRect.toRect(),
        pivot: data.pivot,
        sourceFileId: sourceId,
      );

      spritesBySource.putIfAbsent(sourceId, () => []);
      spritesBySource[sourceId]!.add(sprite);

      // Track max ID number
      final match = RegExp(r'sprite_(\d+)').firstMatch(data.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxIdNum) maxIdNum = num;
      }
    }

    state = MultiSpriteState(
      spritesBySource: spritesBySource,
      nextId: maxIdNum + 1,
    );
  }

  /// Resize all sprites by a scale factor
  Future<void> resizeAllSprites(double scale) async {
    if (scale == 1.0) return;

    // Import dynamically to avoid circular dependency
    final service = await _importResizeService();

    final updatedSprites = <String, List<SpriteRegion>>{};

    for (final entry in state.spritesBySource.entries) {
      final resizedSprites = <SpriteRegion>[];
      for (final sprite in entry.value) {
        final resized = await service.resizeSprite(sprite, scale);
        resizedSprites.add(resized);
      }
      updatedSprites[entry.key] = resizedSprites;
    }

    state = state.copyWith(spritesBySource: updatedSprites);
  }

  Future<_ResizeHelper> _importResizeService() async {
    return const _ResizeHelper();
  }
}

/// Helper class to access SpriteResizeService
class _ResizeHelper {
  const _ResizeHelper();

  Future<SpriteRegion> resizeSprite(SpriteRegion sprite, double scale) async {
    // Scale sourceRect
    final newSourceRect = Rect.fromLTWH(
      sprite.sourceRect.left * scale,
      sprite.sourceRect.top * scale,
      (sprite.sourceRect.width * scale).clamp(1, 8192),
      (sprite.sourceRect.height * scale).clamp(1, 8192),
    );

    // Scale trimmedRect if exists
    Rect? newTrimmedRect;
    if (sprite.trimmedRect != null) {
      newTrimmedRect = Rect.fromLTWH(
        sprite.trimmedRect!.left * scale,
        sprite.trimmedRect!.top * scale,
        (sprite.trimmedRect!.width * scale).clamp(1, 8192),
        (sprite.trimmedRect!.height * scale).clamp(1, 8192),
      );
    }

    // For now, just update the rect without resizing imageBytes
    // Full image resize would require async image processing
    return sprite.copyWith(
      sourceRect: newSourceRect,
      trimmedRect: newTrimmedRect,
      // Note: imageBytes and uiImage would need to be resized separately
      // for now we clear them to force re-extraction from source
      clearImageBytes: sprite.imageBytes != null,
      clearUiImage: sprite.uiImage != null,
    );
  }
}

/// Provider for multi-sprite state
final multiSpriteProvider =
    StateNotifierProvider<MultiSpriteNotifier, MultiSpriteState>((ref) {
  return MultiSpriteNotifier();
});

/// Provider for sprites of currently active source
final activeSourceSpritesProvider = Provider<List<SpriteRegion>>((ref) {
  final multiSpriteState = ref.watch(multiSpriteProvider);
  final activeSource = ref.watch(activeSourceProvider);

  if (activeSource == null) return [];
  return multiSpriteState.getSpritesForSource(activeSource.id);
});

/// Provider for total sprite count
final totalMultiSpriteCountProvider = Provider<int>((ref) {
  return ref.watch(multiSpriteProvider).totalCount;
});

/// Provider for selected sprite count
final selectedMultiSpriteCountProvider = Provider<int>((ref) {
  return ref.watch(multiSpriteProvider).selectedIds.length;
});

/// Provider for first selected sprite
final firstSelectedMultiSpriteProvider = Provider<SpriteRegion?>((ref) {
  final state = ref.watch(multiSpriteProvider);
  if (state.selectedIds.isEmpty) return null;

  final firstId = state.selectedIds.first;
  return state.allSprites.cast<SpriteRegion?>().firstWhere(
        (s) => s?.id == firstId,
        orElse: () => null,
      );
});
