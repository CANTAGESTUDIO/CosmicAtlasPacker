import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../commands/editor_command.dart';
import '../../models/enums/pivot_preset.dart';
import '../../models/enums/tool_mode.dart';
import '../../models/sprite_data.dart';
import '../../models/sprite_region.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Overlay for manual slicing - handles drag selection and sprite visualization
class SlicingOverlay extends ConsumerStatefulWidget {
  final Size imageSize;
  final Matrix4 transform;

  const SlicingOverlay({
    super.key,
    required this.imageSize,
    required this.transform,
  });

  @override
  ConsumerState<SlicingOverlay> createState() => _SlicingOverlayState();
}

class _SlicingOverlayState extends ConsumerState<SlicingOverlay> {
  /// Current drag selection rectangle (while dragging)
  Rect? _dragRect;

  /// Start point of drag
  Offset? _dragStart;

  /// Whether currently dragging
  bool _isDragging = false;

  /// Whether currently doing selection drag (Select mode box selection)
  bool _isSelectionDrag = false;

  /// Sprite ID being pivot-dragged
  String? _pivotDragSpriteId;

  /// Whether currently dragging a pivot handle
  bool _isDraggingPivot = false;

  /// Hit radius for pivot handle (in pixels)
  static const double _pivotHitRadius = 8.0;

  /// Store original pivot when starting pivot drag (for undo)
  PivotPoint? _originalPivot;

  @override
  Widget build(BuildContext context) {
    final toolMode = ref.watch(toolModeProvider);
    final sprites = ref.watch(activeSourceSpritesProvider);
    final multiSpriteState = ref.watch(multiSpriteProvider);
    final isSpacePressed = ref.watch(isSpacePressedProvider);

    // When Space is pressed, only show visualization (don't capture gestures)
    // This allows InteractiveViewer to handle panning
    if (isSpacePressed) {
      return IgnorePointer(
        child: CustomPaint(
          size: widget.imageSize,
          painter: _SlicingPainter(
            sprites: sprites,
            selectedIds: multiSpriteState.selectedIds,
            dragRect: _dragRect,
            isDragging: _isDragging,
            isSelectionDrag: _isSelectionDrag,
            showPivots: true,
            isDraggingPivot: _isDraggingPivot,
            pivotDragSpriteId: _pivotDragSpriteId,
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: _getCursor(toolMode, isSpacePressed),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) => _handlePanStart(details, toolMode),
        onPanUpdate: (details) => _handlePanUpdate(details, toolMode),
        onPanEnd: (details) => _handlePanEnd(details, toolMode),
        onTapUp: (details) => _handleTap(details, toolMode),
        child: CustomPaint(
          size: widget.imageSize,
          painter: _SlicingPainter(
            sprites: sprites,
            selectedIds: multiSpriteState.selectedIds,
            dragRect: _dragRect,
            isDragging: _isDragging,
            isSelectionDrag: _isSelectionDrag,
            showPivots: true,
            isDraggingPivot: _isDraggingPivot,
            pivotDragSpriteId: _pivotDragSpriteId,
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursor(ToolMode mode, bool isSpacePressed) {
    // Space pressed = pan mode cursor
    if (isSpacePressed) {
      return SystemMouseCursors.grab;
    }
    switch (mode) {
      case ToolMode.select:
        return SystemMouseCursors.basic;
      case ToolMode.rectSlice:
        return SystemMouseCursors.precise;
    }
  }

  void _handlePanStart(DragStartDetails details, ToolMode mode) {
    // If Space is pressed, let InteractiveViewer handle panning
    final isSpacePressed = ref.read(isSpacePressedProvider);
    if (isSpacePressed) return;

    final localPos = details.localPosition;
    final activeSource = ref.read(activeSourceProvider);
    if (activeSource == null) return;

    // Check for pivot handle hit first (only in select mode)
    if (mode == ToolMode.select) {
      final hitSprite = _hitTestPivotHandle(localPos);
      if (hitSprite != null) {
        setState(() {
          _isDraggingPivot = true;
          _pivotDragSpriteId = hitSprite.id;
          _originalPivot = hitSprite.pivot; // Store for undo
        });
        return;
      }

      // Check if clicking on an existing sprite (don't start selection drag)
      final clickedSprite = ref.read(multiSpriteProvider.notifier).hitTest(activeSource.id, localPos);
      if (clickedSprite != null) {
        return; // Let tap handle this
      }

      // Start selection drag (box selection) on empty area
      final clampedPos = _clampToImageBounds(localPos);
      setState(() {
        _dragStart = clampedPos;
        _dragRect = Rect.fromPoints(clampedPos, clampedPos);
        _isDragging = true;
        _isSelectionDrag = true;
      });
      return;
    }

    if (mode != ToolMode.rectSlice) return;

    // Clamp to image bounds
    final clampedPos = _clampToImageBounds(localPos);

    setState(() {
      _dragStart = clampedPos;
      _dragRect = Rect.fromPoints(clampedPos, clampedPos);
      _isDragging = true;
      _isSelectionDrag = false;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, ToolMode mode) {
    // If Space is pressed, let InteractiveViewer handle panning
    final isSpacePressed = ref.read(isSpacePressedProvider);
    if (isSpacePressed) return;

    // Handle pivot drag
    if (_isDraggingPivot && _pivotDragSpriteId != null) {
      final localPos = details.localPosition;
      final sprite = ref.read(multiSpriteProvider.notifier).getSpriteById(_pivotDragSpriteId!);
      if (sprite != null) {
        final rect = sprite.sourceRect;
        // Calculate normalized pivot position (0.0 ~ 1.0)
        final pivotX = ((localPos.dx - rect.left) / rect.width).clamp(0.0, 1.0);
        final pivotY = ((localPos.dy - rect.top) / rect.height).clamp(0.0, 1.0);

        // Snap to preset positions (within 0.05 threshold)
        final (snappedX, snappedY, preset) = _snapToPreset(pivotX, pivotY);

        final newPivot = PivotPoint(x: snappedX, y: snappedY, preset: preset);
        ref.read(multiSpriteProvider.notifier).updateSpritePivot(_pivotDragSpriteId!, newPivot);
      }
      return;
    }

    // Handle selection drag (box selection in Select mode)
    if (_isSelectionDrag && _dragStart != null) {
      final localPos = details.localPosition;
      final clampedPos = _clampToImageBounds(localPos);
      setState(() {
        _dragRect = Rect.fromPoints(_dragStart!, clampedPos);
      });
      return;
    }

    if (mode != ToolMode.rectSlice || _dragStart == null) return;

    final localPos = details.localPosition;
    var clampedPos = _clampToImageBounds(localPos);

    // Shift key: constrain to square (1:1 aspect ratio)
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    if (isShiftPressed) {
      clampedPos = _constrainToSquare(_dragStart!, clampedPos);
    }

    setState(() {
      _dragRect = Rect.fromPoints(_dragStart!, clampedPos);
    });
  }

  /// Constrain the end point to create a square selection
  Offset _constrainToSquare(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    // Use the larger dimension to determine the square size
    final absDx = dx.abs();
    final absDy = dy.abs();
    final size = absDx > absDy ? absDx : absDy;

    // Preserve the direction (sign) of each axis
    final newDx = dx >= 0 ? size : -size;
    final newDy = dy >= 0 ? size : -size;

    var newEnd = Offset(start.dx + newDx, start.dy + newDy);

    // Clamp to image bounds
    newEnd = _clampToImageBounds(newEnd);

    return newEnd;
  }

  void _handlePanEnd(DragEndDetails details, ToolMode mode) {
    final activeSource = ref.read(activeSourceProvider);

    // Handle pivot drag end
    if (_isDraggingPivot && _pivotDragSpriteId != null) {
      final sprite = ref.read(multiSpriteProvider.notifier).getSpriteById(_pivotDragSpriteId!);
      final originalPivot = _originalPivot;

      // Create undo command if pivot actually changed
      if (sprite != null && originalPivot != null && sprite.pivot != originalPivot) {
        final command = UpdateSpritePivotCommand(
          spriteId: sprite.id,
          oldPivot: originalPivot,
          newPivot: sprite.pivot,
          onUpdate: (id, pivot) {
            ref.read(multiSpriteProvider.notifier).updateSpritePivot(id, pivot);
          },
        );
        // Execute with history (but don't re-execute since we already applied during drag)
        // We need to add to history without executing
        ref.read(historyProvider.notifier).execute(_NoOpWrapperCommand(
          originalCommand: command,
          alreadyExecuted: true,
        ));
      }

      setState(() {
        _isDraggingPivot = false;
        _pivotDragSpriteId = null;
        _originalPivot = null;
      });
      return;
    }

    // Handle selection drag end (box selection in Select mode)
    if (_isSelectionDrag && _dragRect != null) {
      final selectionRect = _normalizeRect(_dragRect!);

      // Find sprites that intersect with the selection rect
      final intersectingSprites = _findSpritesInRect(selectionRect);

      if (intersectingSprites.isNotEmpty) {
        // Select all intersecting sprites
        for (final sprite in intersectingSprites) {
          ref.read(multiSpriteProvider.notifier).selectSprite(sprite.id, addToSelection: true);
        }
      } else {
        // No sprites in selection area - clear selection
        ref.read(multiSpriteProvider.notifier).clearSelection();
      }

      // Clear selection drag state (no UI shown after release)
      setState(() {
        _dragStart = null;
        _dragRect = null;
        _isDragging = false;
        _isSelectionDrag = false;
      });
      return;
    }

    if (mode != ToolMode.rectSlice || _dragRect == null || activeSource == null) return;

    // Validate minimum size (at least 4x4 pixels for usability)
    final rect = _normalizeRect(_dragRect!);
    if (rect.width >= 4 && rect.height >= 4) {
      // Add sprite to active source
      ref.read(multiSpriteProvider.notifier).addSprite(activeSource.id, rect);
    }

    setState(() {
      _dragStart = null;
      _dragRect = null;
      _isDragging = false;
      _isSelectionDrag = false;
    });
  }

  /// Find all sprites that intersect with the given rect
  List<SpriteRegion> _findSpritesInRect(Rect selectionRect) {
    final sprites = ref.read(activeSourceSpritesProvider);
    return sprites.where((sprite) {
      return sprite.sourceRect.overlaps(selectionRect);
    }).toList();
  }

  void _handleTap(TapUpDetails details, ToolMode mode) {
    if (mode != ToolMode.select) return;

    final localPos = details.localPosition;
    final activeSource = ref.read(activeSourceProvider);
    if (activeSource == null) return;

    final sprite = ref.read(multiSpriteProvider.notifier).hitTest(activeSource.id, localPos);

    if (sprite != null) {
      final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      if (isMetaPressed || isControlPressed || isShiftPressed) {
        // Cmd/Ctrl/Shift + Click: toggle selection (add/remove)
        ref.read(multiSpriteProvider.notifier).selectSprite(sprite.id, toggle: true);
      } else {
        // Normal click: clear others and select only this one
        final selectedIds = ref.read(multiSpriteProvider).selectedIds;
        final isCurrentlySelected = selectedIds.contains(sprite.id);

        if (isCurrentlySelected && selectedIds.length == 1) {
          // If it's the only selected item, deselect it
          ref.read(multiSpriteProvider.notifier).clearSelection();
        } else {
          // Clear all and select only this sprite
          ref.read(multiSpriteProvider.notifier).clearSelection();
          ref.read(multiSpriteProvider.notifier).selectSprite(sprite.id);
        }
      }
    } else {
      // Clicked on empty area - clear selection
      ref.read(multiSpriteProvider.notifier).clearSelection();
    }
  }

  /// Clamp position to image bounds
  Offset _clampToImageBounds(Offset pos) {
    return Offset(
      pos.dx.clamp(0, widget.imageSize.width),
      pos.dy.clamp(0, widget.imageSize.height),
    );
  }

  /// Normalize rect to ensure positive width/height
  Rect _normalizeRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left < rect.right ? rect.right : rect.left,
      rect.top < rect.bottom ? rect.bottom : rect.top,
    );
  }

  /// Hit test for pivot handle on selected sprites
  SpriteRegion? _hitTestPivotHandle(Offset point) {
    final multiSpriteState = ref.read(multiSpriteProvider);

    // Only check selected sprites
    for (final sprite in multiSpriteState.selectedSprites) {
      final rect = sprite.sourceRect;
      final pivot = sprite.pivot;

      // Calculate pivot position in canvas coordinates
      final pivotX = rect.left + rect.width * pivot.x;
      final pivotY = rect.top + rect.height * pivot.y;

      // Check if point is within hit radius of pivot handle
      final distance = (Offset(pivotX, pivotY) - point).distance;
      if (distance <= _pivotHitRadius) {
        return sprite;
      }
    }
    return null;
  }

  /// Snap pivot to preset positions if within threshold
  (double, double, PivotPreset) _snapToPreset(double x, double y) {
    const threshold = 0.08;

    // Define preset positions
    const presets = [
      (0.0, 0.0, PivotPreset.topLeft),
      (0.5, 0.0, PivotPreset.topCenter),
      (1.0, 0.0, PivotPreset.topRight),
      (0.0, 0.5, PivotPreset.centerLeft),
      (0.5, 0.5, PivotPreset.center),
      (1.0, 0.5, PivotPreset.centerRight),
      (0.0, 1.0, PivotPreset.bottomLeft),
      (0.5, 1.0, PivotPreset.bottomCenter),
      (1.0, 1.0, PivotPreset.bottomRight),
    ];

    for (final (px, py, preset) in presets) {
      if ((x - px).abs() < threshold && (y - py).abs() < threshold) {
        return (px, py, preset);
      }
    }

    return (x, y, PivotPreset.custom);
  }
}

/// Custom painter for slicing overlay visualization
class _SlicingPainter extends CustomPainter {
  final List<SpriteRegion> sprites;
  final Set<String> selectedIds;
  final Rect? dragRect;
  final bool isDragging;
  final bool isSelectionDrag;
  final bool showPivots;
  final bool isDraggingPivot;
  final String? pivotDragSpriteId;

  _SlicingPainter({
    required this.sprites,
    required this.selectedIds,
    this.dragRect,
    this.isDragging = false,
    this.isSelectionDrag = false,
    this.showPivots = true,
    this.isDraggingPivot = false,
    this.pivotDragSpriteId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw registered sprites
    for (final sprite in sprites) {
      _drawSpriteRegion(canvas, sprite);
    }

    // Draw current drag selection (rect slicing mode only, not selection drag)
    if (isDragging && dragRect != null && !isSelectionDrag) {
      _drawDragSelection(canvas, dragRect!);
    }

    // Draw selection box for box selection in Select mode
    if (isSelectionDrag && dragRect != null) {
      _drawSelectionBox(canvas, dragRect!);
    }
  }

  /// Draw selection box for box selection (different style from rect slice)
  void _drawSelectionBox(Canvas canvas, Rect rect) {
    final normalizedRect = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left < rect.right ? rect.right : rect.left,
      rect.top < rect.bottom ? rect.bottom : rect.top,
    );

    // Semi-transparent blue fill
    final fillPaint = Paint()
      ..color = EditorColors.selectionFill.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Blue dashed border
    final borderPaint = Paint()
      ..color = EditorColors.selectionBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(normalizedRect, fillPaint);
    canvas.drawRect(normalizedRect, borderPaint);
  }

  void _drawSpriteRegion(Canvas canvas, SpriteRegion sprite) {
    final isSelected = selectedIds.contains(sprite.id);
    final rect = sprite.sourceRect;

    // Fill color (semi-transparent)
    final fillPaint = Paint()
      ..color = isSelected
          ? EditorColors.selectionFill.withValues(alpha: 0.3)
          : EditorColors.spriteFill.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Border color
    final borderPaint = Paint()
      ..color = isSelected ? EditorColors.selectionBorder : EditorColors.spriteBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);

    // Draw sprite ID label
    _drawLabel(canvas, sprite.id, rect);

    // Draw pivot handle for selected sprites
    if (showPivots && isSelected) {
      _drawPivotHandle(canvas, sprite, rect);
    }
  }

  void _drawPivotHandle(Canvas canvas, SpriteRegion sprite, Rect rect) {
    final pivot = sprite.pivot;
    final pivotX = rect.left + rect.width * pivot.x;
    final pivotY = rect.top + rect.height * pivot.y;
    final pivotPos = Offset(pivotX, pivotY);

    final isBeingDragged = isDraggingPivot && pivotDragSpriteId == sprite.id;
    final handleSize = isBeingDragged ? 8.0 : 6.0;

    // Draw crosshair lines
    final linePaint = Paint()
      ..color = EditorColors.warning.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal line
    canvas.drawLine(
      Offset(rect.left, pivotY),
      Offset(rect.right, pivotY),
      linePaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(pivotX, rect.top),
      Offset(pivotX, rect.bottom),
      linePaint,
    );

    // Draw outer circle (white for visibility)
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pivotPos, handleSize + 1, outerPaint);

    // Draw inner circle
    final innerPaint = Paint()
      ..color = isBeingDragged ? EditorColors.primary : EditorColors.warning
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pivotPos, handleSize, innerPaint);

    // Draw center dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pivotPos, 2, dotPaint);
  }

  void _drawLabel(Canvas canvas, String label, Rect rect) {
    // Only draw label if rect is large enough
    if (rect.width < 30 || rect.height < 20) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black87,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: rect.width - 4);

    // Position at top-left corner with padding
    final offset = Offset(rect.left + 2, rect.top + 2);
    textPainter.paint(canvas, offset);
  }

  void _drawDragSelection(Canvas canvas, Rect rect) {
    // Normalize rect
    final normalizedRect = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left < rect.right ? rect.right : rect.left,
      rect.top < rect.bottom ? rect.bottom : rect.top,
    );

    // Semi-transparent fill
    final fillPaint = Paint()
      ..color = EditorColors.dragSelectionFill.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Dashed border effect using solid line for simplicity
    final borderPaint = Paint()
      ..color = EditorColors.dragSelectionBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(normalizedRect, fillPaint);
    canvas.drawRect(normalizedRect, borderPaint);

    // Draw size indicator
    _drawSizeIndicator(canvas, normalizedRect);
  }

  void _drawSizeIndicator(Canvas canvas, Rect rect) {
    final width = rect.width.round();
    final height = rect.height.round();
    final sizeText = '${width}x$height';

    final textPainter = TextPainter(
      text: TextSpan(
        text: sizeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position at bottom-right corner
    final offset = Offset(
      rect.right - textPainter.width - 4,
      rect.bottom - textPainter.height - 4,
    );

    // Only draw if inside the rect
    if (offset.dx > rect.left + 4 && offset.dy > rect.top + 4) {
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _SlicingPainter oldDelegate) {
    return oldDelegate.sprites != sprites ||
        oldDelegate.selectedIds != selectedIds ||
        oldDelegate.dragRect != dragRect ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.isSelectionDrag != isSelectionDrag ||
        oldDelegate.showPivots != showPivots ||
        oldDelegate.isDraggingPivot != isDraggingPivot ||
        oldDelegate.pivotDragSpriteId != pivotDragSpriteId;
  }
}

/// Wrapper command that skips execute() when the action was already performed
/// Used for real-time drag operations where the change is applied during drag
class _NoOpWrapperCommand extends EditorCommand {
  final EditorCommand originalCommand;
  final bool alreadyExecuted;

  _NoOpWrapperCommand({
    required this.originalCommand,
    this.alreadyExecuted = false,
  });

  @override
  String get description => originalCommand.description;

  @override
  void execute() {
    // Skip if already executed during drag
    if (!alreadyExecuted) {
      originalCommand.execute();
    }
  }

  @override
  void undo() {
    originalCommand.undo();
  }
}
