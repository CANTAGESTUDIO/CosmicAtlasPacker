import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sprite_data.dart';
import '../models/sprite_region.dart';
import '../services/auto_slicer_service.dart';
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
  void addFromAutoSlice(String sourceId, AutoSliceResult result) {
    int currentId = state.nextId;

    // Create sprites with source file ID
    final spritesWithSource = result.sprites.map((s) {
      final newSprite = s.copyWith(
        id: 'sprite_$currentId',
        sourceFileId: sourceId,
      );
      currentId++;
      return newSprite;
    }).toList();

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
