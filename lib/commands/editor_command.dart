import 'dart:ui';

import '../models/sprite_data.dart';
import '../models/sprite_region.dart';

/// Abstract base class for undoable editor commands
///
/// All editable operations in the editor should be implemented as commands
/// to support undo/redo functionality.
abstract class EditorCommand {
  /// Human-readable description for UI display
  /// Example: "Add Sprite", "Delete 3 Sprites", "Change ID"
  String get description;

  /// Execute the command
  void execute();

  /// Undo the command (reverse the operation)
  void undo();
}

/// Command for adding a single sprite
class AddSpriteCommand extends EditorCommand {
  final SpriteRegion sprite;
  final void Function(SpriteRegion) onAdd;
  final void Function(String) onRemove;

  AddSpriteCommand({
    required this.sprite,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  String get description => 'Add Sprite "${sprite.id}"';

  @override
  void execute() => onAdd(sprite);

  @override
  void undo() => onRemove(sprite.id);
}

/// Command for deleting a single sprite
class DeleteSpriteCommand extends EditorCommand {
  final SpriteRegion sprite;
  final void Function(SpriteRegion) onAdd;
  final void Function(String) onRemove;

  DeleteSpriteCommand({
    required this.sprite,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  String get description => 'Delete Sprite "${sprite.id}"';

  @override
  void execute() => onRemove(sprite.id);

  @override
  void undo() => onAdd(sprite);
}

/// Command for deleting multiple sprites
class DeleteMultipleSpritesCommand extends EditorCommand {
  final List<SpriteRegion> sprites;
  final void Function(List<SpriteRegion>) onAddMultiple;
  final void Function(List<String>) onRemoveMultiple;

  DeleteMultipleSpritesCommand({
    required this.sprites,
    required this.onAddMultiple,
    required this.onRemoveMultiple,
  });

  @override
  String get description => 'Delete ${sprites.length} Sprites';

  @override
  void execute() => onRemoveMultiple(sprites.map((s) => s.id).toList());

  @override
  void undo() => onAddMultiple(sprites);
}

/// Command for updating sprite ID
class UpdateSpriteIdCommand extends EditorCommand {
  final String oldId;
  final String newId;
  final void Function(String oldId, String newId) onUpdate;

  UpdateSpriteIdCommand({
    required this.oldId,
    required this.newId,
    required this.onUpdate,
  });

  @override
  String get description => 'Rename "$oldId" to "$newId"';

  @override
  void execute() => onUpdate(oldId, newId);

  @override
  void undo() => onUpdate(newId, oldId);
}

/// Command for updating sprite pivot
class UpdateSpritePivotCommand extends EditorCommand {
  final String spriteId;
  final PivotPoint oldPivot;
  final PivotPoint newPivot;
  final void Function(String id, PivotPoint pivot) onUpdate;

  UpdateSpritePivotCommand({
    required this.spriteId,
    required this.oldPivot,
    required this.newPivot,
    required this.onUpdate,
  });

  @override
  String get description => 'Change Pivot';

  @override
  void execute() => onUpdate(spriteId, newPivot);

  @override
  void undo() => onUpdate(spriteId, oldPivot);
}

/// Command for updating sprite rect (position/size)
class UpdateSpriteRectCommand extends EditorCommand {
  final String spriteId;
  final Rect oldRect;
  final Rect newRect;
  final void Function(String id, Rect rect) onUpdate;

  UpdateSpriteRectCommand({
    required this.spriteId,
    required this.oldRect,
    required this.newRect,
    required this.onUpdate,
  });

  @override
  String get description => 'Move/Resize Sprite';

  @override
  void execute() => onUpdate(spriteId, newRect);

  @override
  void undo() => onUpdate(spriteId, oldRect);
}

/// Command for grid slice operation (replaces all sprites)
class GridSliceCommand extends EditorCommand {
  final List<SpriteRegion> previousSprites;
  final List<SpriteRegion> newSprites;
  final int columns;
  final int rows;
  final void Function(List<SpriteRegion>) onReplace;

  GridSliceCommand({
    required this.previousSprites,
    required this.newSprites,
    required this.columns,
    required this.rows,
    required this.onReplace,
  });

  @override
  String get description => 'Grid Slice (${columns}x$rows)';

  @override
  void execute() => onReplace(newSprites);

  @override
  void undo() => onReplace(previousSprites);
}

/// Command for auto slice operation (replaces all sprites)
class AutoSliceCommand extends EditorCommand {
  final List<SpriteRegion> previousSprites;
  final List<SpriteRegion> newSprites;
  final void Function(List<SpriteRegion>) onReplace;

  AutoSliceCommand({
    required this.previousSprites,
    required this.newSprites,
    required this.onReplace,
  });

  @override
  String get description => 'Auto Slice (${newSprites.length} sprites)';

  @override
  void execute() => onReplace(newSprites);

  @override
  void undo() => onReplace(previousSprites);
}

/// Command for clearing all sprites
class ClearAllSpritesCommand extends EditorCommand {
  final List<SpriteRegion> previousSprites;
  final void Function(List<SpriteRegion>) onReplace;

  ClearAllSpritesCommand({
    required this.previousSprites,
    required this.onReplace,
  });

  @override
  String get description => 'Clear All Sprites';

  @override
  void execute() => onReplace([]);

  @override
  void undo() => onReplace(previousSprites);
}

/// Command for updating pivot on multiple selected sprites
class UpdateSelectedPivotCommand extends EditorCommand {
  final List<String> spriteIds;
  final Map<String, PivotPoint> oldPivots;
  final PivotPoint newPivot;
  final void Function(String id, PivotPoint pivot) onUpdate;

  UpdateSelectedPivotCommand({
    required this.spriteIds,
    required this.oldPivots,
    required this.newPivot,
    required this.onUpdate,
  });

  @override
  String get description => 'Change Pivot (${spriteIds.length} sprites)';

  @override
  void execute() {
    for (final id in spriteIds) {
      onUpdate(id, newPivot);
    }
  }

  @override
  void undo() {
    for (final id in spriteIds) {
      final oldPivot = oldPivots[id];
      if (oldPivot != null) {
        onUpdate(id, oldPivot);
      }
    }
  }
}

/// Batch command for combining multiple commands into one undo step
class BatchCommand extends EditorCommand {
  final List<EditorCommand> commands;
  final String _description;

  BatchCommand({
    required this.commands,
    required String description,
  }) : _description = description;

  @override
  String get description => _description;

  @override
  void execute() {
    for (final command in commands) {
      command.execute();
    }
  }

  @override
  void undo() {
    // Undo in reverse order
    for (final command in commands.reversed) {
      command.undo();
    }
  }
}
