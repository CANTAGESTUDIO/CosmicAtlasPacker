import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums/pivot_preset.dart';
import '../models/sprite_data.dart';
import '../models/sprite_region.dart';
import '../services/auto_slicer_service.dart';
import '../services/grid_slicer_service.dart';
import '../services/id_validation_service.dart';

/// State for managing sprite regions
class SpriteState {
  final List<SpriteRegion> sprites;
  final Set<String> selectedIds;
  final int nextId;

  const SpriteState({
    this.sprites = const [],
    this.selectedIds = const {},
    this.nextId = 0,
  });

  SpriteState copyWith({
    List<SpriteRegion>? sprites,
    Set<String>? selectedIds,
    int? nextId,
  }) {
    return SpriteState(
      sprites: sprites ?? this.sprites,
      selectedIds: selectedIds ?? this.selectedIds,
      nextId: nextId ?? this.nextId,
    );
  }

  /// Get selected sprites
  List<SpriteRegion> get selectedSprites =>
      sprites.where((s) => selectedIds.contains(s.id)).toList();

  /// Check if any sprite is selected
  bool get hasSelection => selectedIds.isNotEmpty;

  /// Total sprite count
  int get count => sprites.length;
}

/// Notifier for sprite state management
class SpriteNotifier extends StateNotifier<SpriteState> {
  SpriteNotifier() : super(const SpriteState());

  /// Generate unique sprite ID
  String _generateId() {
    final id = 'sprite_${state.nextId}';
    state = state.copyWith(nextId: state.nextId + 1);
    return id;
  }

  /// Add a new sprite region from selected rectangle
  void addSprite(Rect rect) {
    // Validate minimum size (at least 1x1 pixel)
    if (rect.width < 1 || rect.height < 1) return;

    // Normalize rect (ensure positive width/height)
    final normalizedRect = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left < rect.right ? rect.right : rect.left,
      rect.top < rect.bottom ? rect.bottom : rect.top,
    );

    final sprite = SpriteRegion(
      id: _generateId(),
      sourceRect: normalizedRect,
    );

    state = state.copyWith(
      sprites: [...state.sprites, sprite],
    );
  }

  /// Remove sprite by ID
  void removeSprite(String id) {
    state = state.copyWith(
      sprites: state.sprites.where((s) => s.id != id).toList(),
      selectedIds: Set.from(state.selectedIds)..remove(id),
    );
  }

  /// Remove all selected sprites
  void removeSelected() {
    state = state.copyWith(
      sprites:
          state.sprites.where((s) => !state.selectedIds.contains(s.id)).toList(),
      selectedIds: {},
    );
  }

  /// Select a sprite (toggle or replace)
  void selectSprite(String id, {bool toggle = false, bool addToSelection = false}) {
    if (toggle) {
      // Toggle selection
      final newSelection = Set<String>.from(state.selectedIds);
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
      state = state.copyWith(selectedIds: newSelection);
    } else if (addToSelection) {
      // Add to existing selection
      state = state.copyWith(
        selectedIds: {...state.selectedIds, id},
      );
    } else {
      // Replace selection
      state = state.copyWith(selectedIds: {id});
    }
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Deselect a single sprite
  void deselectSprite(String id) {
    final newSelection = Set<String>.from(state.selectedIds);
    newSelection.remove(id);
    state = state.copyWith(selectedIds: newSelection);
  }

  /// Select all sprites
  void selectAll() {
    state = state.copyWith(
      selectedIds: state.sprites.map((s) => s.id).toSet(),
    );
  }

  /// Select multiple sprites at once (replaces current selection)
  void selectMultiple(Set<String> ids) {
    state = state.copyWith(selectedIds: ids);
  }

  /// Clear all sprites
  void clearAll() {
    state = const SpriteState();
  }

  /// Add sprites from grid slicing result (replaces existing sprites)
  void addFromGridSlice(GridSliceResult result) {
    // Find the next ID to continue from
    int maxId = state.nextId;

    // Replace all sprites with grid slice result
    state = SpriteState(
      sprites: result.sprites,
      nextId: maxId + result.sprites.length,
    );
  }

  /// Add sprites from auto slicing result (replaces existing sprites)
  void addFromAutoSlice(AutoSliceResult result) {
    // Find the next ID to continue from
    int maxId = state.nextId;

    // Replace all sprites with auto slice result
    state = SpriteState(
      sprites: result.sprites,
      nextId: maxId + result.sprites.length,
    );
  }

  /// Add sprites from grid slicing result (append to existing)
  void appendFromGridSlice(GridSliceResult result, int startIndex) {
    final newSprites = result.sprites.map((s) {
      // Rename to avoid conflicts with existing IDs
      final newId = 'sprite_${state.nextId + result.sprites.indexOf(s)}';
      return s.copyWith(id: newId);
    }).toList();

    state = state.copyWith(
      sprites: [...state.sprites, ...newSprites],
      nextId: state.nextId + newSprites.length,
    );
  }

  /// Check if a sprite at given point exists
  SpriteRegion? hitTest(Offset point) {
    // Search in reverse order (top-most first)
    for (final sprite in state.sprites.reversed) {
      if (sprite.sourceRect.contains(point)) {
        return sprite;
      }
    }
    return null;
  }

  /// Update sprite ID
  void updateSpriteId(String oldId, String newId) {
    if (oldId == newId) return;

    // Check for duplicate ID
    if (state.sprites.any((s) => s.id == newId)) return;

    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (s.id == oldId) {
          return s.copyWith(id: newId);
        }
        return s;
      }).toList(),
      selectedIds: state.selectedIds.map((id) {
        return id == oldId ? newId : id;
      }).toSet(),
    );
  }

  /// Update pivot for a sprite
  void updateSpritePivot(String id, PivotPoint pivot) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (s.id == id) {
          return s.copyWith(pivot: pivot);
        }
        return s;
      }).toList(),
    );
  }

  /// Update sprite source rect (position and size)
  void updateSpriteRect(String id, {double? x, double? y, int? width, int? height}) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
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
      }).toList(),
    );
  }

  /// Update pivot for selected sprites
  void updateSelectedPivot(PivotPoint pivot) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (state.selectedIds.contains(s.id)) {
          return s.copyWith(pivot: pivot);
        }
        return s;
      }).toList(),
    );
  }

  /// Update pivot from preset for selected sprites
  void updateSelectedPivotFromPreset(PivotPreset preset) {
    final pivot = PivotPoint.fromPreset(preset);
    updateSelectedPivot(pivot);
  }

  /// Get sprite by ID
  SpriteRegion? getSpriteById(String id) {
    try {
      return state.sprites.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear all sprites (alias for clearAll)
  void clear() {
    clearAll();
  }

  /// Load sprites from saved project
  void loadFromProject(List<SpriteData> spriteDataList) {
    if (spriteDataList.isEmpty) {
      clearAll();
      return;
    }

    // Convert SpriteData to SpriteRegion
    final sprites = spriteDataList.map((data) {
      return SpriteRegion(
        id: data.id,
        sourceRect: data.sourceRect.toRect(),
        pivot: data.pivot,
        nineSlice: data.nineSlice,
      );
    }).toList();

    // Find max ID number for nextId
    int maxIdNum = 0;
    for (final sprite in sprites) {
      final match = RegExp(r'sprite_(\d+)').firstMatch(sprite.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxIdNum) maxIdNum = num;
      }
    }

    state = SpriteState(
      sprites: sprites,
      nextId: maxIdNum + 1,
    );
  }

  // ============================================================
  // Internal methods for Command pattern (bypass history tracking)
  // ============================================================

  /// Internal: Add sprite without history (used by commands)
  void addSpriteInternal(SpriteRegion sprite) {
    state = state.copyWith(
      sprites: [...state.sprites, sprite],
    );
  }

  /// Internal: Remove sprite without history (used by commands)
  void removeSpriteInternal(String id) {
    state = state.copyWith(
      sprites: state.sprites.where((s) => s.id != id).toList(),
      selectedIds: Set.from(state.selectedIds)..remove(id),
    );
  }

  /// Internal: Remove multiple sprites without history (used by commands)
  void removeSpritesInternal(List<String> ids) {
    final idSet = ids.toSet();
    state = state.copyWith(
      sprites: state.sprites.where((s) => !idSet.contains(s.id)).toList(),
      selectedIds: state.selectedIds.difference(idSet),
    );
  }

  /// Internal: Add multiple sprites without history (used by commands)
  void addSpritesInternal(List<SpriteRegion> sprites) {
    state = state.copyWith(
      sprites: [...state.sprites, ...sprites],
    );
  }

  /// Internal: Replace all sprites without history (used by commands)
  void replaceAllSpritesInternal(List<SpriteRegion> sprites) {
    // Calculate new nextId
    int maxIdNum = state.nextId;
    for (final sprite in sprites) {
      final match = RegExp(r'sprite_(\d+)').firstMatch(sprite.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num >= maxIdNum) maxIdNum = num + 1;
      }
    }

    state = SpriteState(
      sprites: sprites,
      selectedIds: {},
      nextId: maxIdNum,
    );
  }

  /// Internal: Update sprite ID without history (used by commands)
  void updateSpriteIdInternal(String oldId, String newId) {
    if (oldId == newId) return;
    if (state.sprites.any((s) => s.id == newId)) return;

    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (s.id == oldId) {
          return s.copyWith(id: newId);
        }
        return s;
      }).toList(),
      selectedIds: state.selectedIds.map((id) {
        return id == oldId ? newId : id;
      }).toSet(),
    );
  }

  /// Internal: Update sprite pivot without history (used by commands)
  void updateSpritePivotInternal(String id, PivotPoint pivot) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (s.id == id) {
          return s.copyWith(pivot: pivot);
        }
        return s;
      }).toList(),
    );
  }

  /// Internal: Update sprite rect without history (used by commands)
  void updateSpriteRectInternal(String id, Rect rect) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (s.id == id) {
          return s.copyWith(sourceRect: rect);
        }
        return s;
      }).toList(),
    );
  }

  /// Generate a new unique ID (public for command creation)
  String generateNewId() {
    final id = 'sprite_${state.nextId}';
    state = state.copyWith(nextId: state.nextId + 1);
    return id;
  }

  /// Reorder sprites by moving item from oldIndex to newIndex
  void reorderSprites(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= state.sprites.length) return;
    if (newIndex < 0 || newIndex > state.sprites.length) return;

    final sprites = List<SpriteRegion>.from(state.sprites);
    final item = sprites.removeAt(oldIndex);

    // Adjust newIndex if needed (after removal)
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    sprites.insert(adjustedNewIndex, item);

    state = state.copyWith(sprites: sprites);
  }

  /// Internal: Reorder sprites without history (used by commands)
  void reorderSpritesInternal(int oldIndex, int newIndex) {
    reorderSprites(oldIndex, newIndex);
  }

  // ============================================================
  // 9-Slice Border methods
  // ============================================================

  /// Update 9-slice border for a sprite
  void updateSpriteNineSlice(String id, NineSliceBorder? nineSlice) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (s.id == id) {
          return s.copyWith(
            nineSlice: nineSlice,
            clearNineSlice: nineSlice == null,
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Update 9-slice border for selected sprites
  void updateSelectedNineSlice(NineSliceBorder? nineSlice) {
    state = state.copyWith(
      sprites: state.sprites.map((s) {
        if (state.selectedIds.contains(s.id)) {
          return s.copyWith(
            nineSlice: nineSlice,
            clearNineSlice: nineSlice == null,
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Clear 9-slice border for a sprite
  void clearSpriteNineSlice(String id) {
    updateSpriteNineSlice(id, null);
  }

  /// Clear 9-slice border for selected sprites
  void clearSelectedNineSlice() {
    updateSelectedNineSlice(null);
  }

  /// Internal: Update sprite 9-slice without history (used by commands)
  void updateSpriteNineSliceInternal(String id, NineSliceBorder? nineSlice) {
    updateSpriteNineSlice(id, nineSlice);
  }
}

/// Provider for sprite state
final spriteProvider = StateNotifierProvider<SpriteNotifier, SpriteState>((ref) {
  return SpriteNotifier();
});

/// Provider for selected sprite count
final selectedSpriteCountProvider = Provider<int>((ref) {
  return ref.watch(spriteProvider).selectedIds.length;
});

/// Provider for total sprite count
final totalSpriteCountProvider = Provider<int>((ref) {
  return ref.watch(spriteProvider).count;
});

/// Provider for ID validation service
final idValidationServiceProvider = Provider<IdValidationService>((ref) {
  return const IdValidationService();
});

/// Provider for all sprite IDs
final allSpriteIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(spriteProvider).sprites.map((s) => s.id).toList();
});

/// Provider for duplicate IDs check
final hasDuplicateIdsProvider = Provider<bool>((ref) {
  final ids = ref.watch(allSpriteIdsProvider);
  final service = ref.watch(idValidationServiceProvider);
  return service.hasDuplicates(ids);
});

/// Provider for duplicate ID details
final duplicateIdsProvider = Provider<Map<String, List<int>>>((ref) {
  final ids = ref.watch(allSpriteIdsProvider);
  final service = ref.watch(idValidationServiceProvider);
  return service.findDuplicates(ids);
});

/// Provider for first selected sprite (for Properties panel)
final firstSelectedSpriteProvider = Provider<SpriteRegion?>((ref) {
  final state = ref.watch(spriteProvider);
  if (state.selectedIds.isEmpty) return null;

  final firstSelectedId = state.selectedIds.first;
  try {
    return state.sprites.firstWhere((s) => s.id == firstSelectedId);
  } catch (_) {
    return null;
  }
});
