import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../models/sprite_region.dart';
import '../models/sprite_slice_mode.dart';
import 'editor_command.dart';

/// Snapshot of source image state for undo/redo
class SourceImageSnapshot {
  final ui.Image uiImage;
  final img.Image rawImage;
  final SpriteSliceMode sliceMode;

  const SourceImageSnapshot({
    required this.uiImage,
    required this.rawImage,
    required this.sliceMode,
  });
}

/// Command for separating sprites from source image
///
/// This command transitions from "region" state to "separated" state.
/// It stores all necessary data to fully restore the previous state on undo.
class SeparateSpritesCommand extends EditorCommand {
  final String sourceId;

  /// Previous state (region mode)
  final SourceImageSnapshot previousSourceState;
  final List<SpriteRegion> previousSprites;

  /// New state (separated mode)
  final SourceImageSnapshot newSourceState;
  final List<SpriteRegion> newSprites;

  /// Callbacks for state changes
  final void Function(String sourceId, ui.Image uiImage, img.Image rawImage)
      onUpdateProcessedImage;
  final void Function(String sourceId, SpriteSliceMode mode) onSetSliceMode;
  final void Function(String sourceId, List<SpriteRegion> sprites)
      onReplaceSprites;

  SeparateSpritesCommand({
    required this.sourceId,
    required this.previousSourceState,
    required this.previousSprites,
    required this.newSourceState,
    required this.newSprites,
    required this.onUpdateProcessedImage,
    required this.onSetSliceMode,
    required this.onReplaceSprites,
  });

  @override
  String get description => 'Separate Sprites';

  @override
  void execute() {
    // Update source image to background canvas
    onUpdateProcessedImage(
      sourceId,
      newSourceState.uiImage,
      newSourceState.rawImage,
    );

    // Update slice mode to separated
    onSetSliceMode(sourceId, SpriteSliceMode.separated);

    // Replace sprites with separated versions (with imageBytes and uiImage)
    onReplaceSprites(sourceId, newSprites);
  }

  @override
  void undo() {
    // Restore original source image
    onUpdateProcessedImage(
      sourceId,
      previousSourceState.uiImage,
      previousSourceState.rawImage,
    );

    // Restore slice mode to region
    onSetSliceMode(sourceId, SpriteSliceMode.region);

    // Restore original sprites (without imageBytes)
    onReplaceSprites(sourceId, previousSprites);
  }
}

/// Command for clearing processed image and reverting to region mode
///
/// Used when user wants to revert from separated back to region without undo
class RevertToRegionCommand extends EditorCommand {
  final String sourceId;
  final SourceImageSnapshot currentState;
  final List<SpriteRegion> currentSprites;
  final List<SpriteRegion> regionSprites;

  final void Function(String sourceId) onClearProcessedImage;
  final void Function(String sourceId, SpriteSliceMode mode) onSetSliceMode;
  final void Function(String sourceId, List<SpriteRegion> sprites)
      onReplaceSprites;

  RevertToRegionCommand({
    required this.sourceId,
    required this.currentState,
    required this.currentSprites,
    required this.regionSprites,
    required this.onClearProcessedImage,
    required this.onSetSliceMode,
    required this.onReplaceSprites,
  });

  @override
  String get description => 'Revert to Region';

  @override
  void execute() {
    // Clear processed image (show original)
    onClearProcessedImage(sourceId);

    // Set mode to region
    onSetSliceMode(sourceId, SpriteSliceMode.region);

    // Replace sprites with region versions (no imageBytes)
    onReplaceSprites(sourceId, regionSprites);
  }

  @override
  void undo() {
    // This command is typically not undoable via the command itself
    // as it's a destructive operation. The separated state would need
    // to be re-created via another separation operation.
  }
}
