import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sprite_data.dart';
import '../../models/sprite_region.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Handle type for 9-slice border dragging
enum NineSliceHandle {
  left,
  right,
  top,
  bottom,
}

/// Overlay widget for displaying and editing 9-slice borders on canvas
class NineSliceOverlay extends ConsumerStatefulWidget {
  final SpriteRegion sprite;
  final ui.Image sourceImage;
  final double scale;
  final Offset offset;
  final bool isEditing;

  const NineSliceOverlay({
    super.key,
    required this.sprite,
    required this.sourceImage,
    required this.scale,
    required this.offset,
    this.isEditing = false,
  });

  @override
  ConsumerState<NineSliceOverlay> createState() => _NineSliceOverlayState();
}

class _NineSliceOverlayState extends ConsumerState<NineSliceOverlay> {
  NineSliceHandle? _activeHandle;
  double _dragStartValue = 0;

  @override
  Widget build(BuildContext context) {
    final nineSlice = widget.sprite.nineSlice;
    if (nineSlice == null || !nineSlice.isEnabled) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _NineSliceOverlayPainter(
        sprite: widget.sprite,
        nineSlice: nineSlice,
        scale: widget.scale,
        offset: widget.offset,
        isEditing: widget.isEditing,
        activeHandle: _activeHandle,
      ),
      child: widget.isEditing ? _buildHandles(nineSlice) : null,
    );
  }

  Widget _buildHandles(NineSliceBorder nineSlice) {
    final rect = widget.sprite.sourceRect;
    final scale = widget.scale;
    final offset = widget.offset;

    // Convert sprite rect to screen coordinates
    final screenLeft = rect.left * scale + offset.dx;
    final screenTop = rect.top * scale + offset.dy;
    final screenWidth = rect.width * scale;
    final screenHeight = rect.height * scale;

    // Border positions in screen coordinates
    final leftBorder = nineSlice.left * scale;
    final rightBorder = nineSlice.right * scale;
    final topBorder = nineSlice.top * scale;
    final bottomBorder = nineSlice.bottom * scale;

    return Stack(
      children: [
        // Left handle
        _buildHandle(
          NineSliceHandle.left,
          Offset(screenLeft + leftBorder, screenTop + screenHeight / 2),
          true,
        ),
        // Right handle
        _buildHandle(
          NineSliceHandle.right,
          Offset(
            screenLeft + screenWidth - rightBorder,
            screenTop + screenHeight / 2,
          ),
          true,
        ),
        // Top handle
        _buildHandle(
          NineSliceHandle.top,
          Offset(screenLeft + screenWidth / 2, screenTop + topBorder),
          false,
        ),
        // Bottom handle
        _buildHandle(
          NineSliceHandle.bottom,
          Offset(
            screenLeft + screenWidth / 2,
            screenTop + screenHeight - bottomBorder,
          ),
          false,
        ),
      ],
    );
  }

  Widget _buildHandle(NineSliceHandle handle, Offset position, bool isVertical) {
    const handleSize = 12.0;
    final isActive = _activeHandle == handle;

    return Positioned(
      left: position.dx - handleSize / 2,
      top: position.dy - handleSize / 2,
      child: GestureDetector(
        onPanStart: (details) => _onDragStart(handle),
        onPanUpdate: (details) => _onDragUpdate(handle, details, isVertical),
        onPanEnd: (_) => _onDragEnd(),
        child: MouseRegion(
          cursor: isVertical
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: isActive
                  ? EditorColors.primary
                  : EditorColors.primary.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  void _onDragStart(NineSliceHandle handle) {
    final nineSlice = widget.sprite.nineSlice;
    if (nineSlice == null) return;

    setState(() {
      _activeHandle = handle;
      switch (handle) {
        case NineSliceHandle.left:
          _dragStartValue = nineSlice.left.toDouble();
          break;
        case NineSliceHandle.right:
          _dragStartValue = nineSlice.right.toDouble();
          break;
        case NineSliceHandle.top:
          _dragStartValue = nineSlice.top.toDouble();
          break;
        case NineSliceHandle.bottom:
          _dragStartValue = nineSlice.bottom.toDouble();
          break;
      }
    });
  }

  void _onDragUpdate(
    NineSliceHandle handle,
    DragUpdateDetails details,
    bool isVertical,
  ) {
    final nineSlice = widget.sprite.nineSlice;
    if (nineSlice == null) return;

    // Calculate delta in image pixels
    final delta = isVertical
        ? details.delta.dx / widget.scale
        : details.delta.dy / widget.scale;

    // Calculate new value based on handle
    int newValue;
    switch (handle) {
      case NineSliceHandle.left:
        newValue = (_dragStartValue + delta).round();
        _dragStartValue += delta;
        break;
      case NineSliceHandle.right:
        newValue = (_dragStartValue - delta).round();
        _dragStartValue -= delta;
        break;
      case NineSliceHandle.top:
        newValue = (_dragStartValue + delta).round();
        _dragStartValue += delta;
        break;
      case NineSliceHandle.bottom:
        newValue = (_dragStartValue - delta).round();
        _dragStartValue -= delta;
        break;
    }

    // Clamp to valid range
    final maxValue = isVertical
        ? (widget.sprite.width ~/ 2) - 1
        : (widget.sprite.height ~/ 2) - 1;
    newValue = newValue.clamp(0, maxValue);

    // Update 9-slice
    NineSliceBorder updated;
    switch (handle) {
      case NineSliceHandle.left:
        updated = nineSlice.copyWith(left: newValue);
        break;
      case NineSliceHandle.right:
        updated = nineSlice.copyWith(right: newValue);
        break;
      case NineSliceHandle.top:
        updated = nineSlice.copyWith(top: newValue);
        break;
      case NineSliceHandle.bottom:
        updated = nineSlice.copyWith(bottom: newValue);
        break;
    }

    ref.read(spriteProvider.notifier).updateSpriteNineSlice(
          widget.sprite.id,
          updated,
        );
  }

  void _onDragEnd() {
    setState(() {
      _activeHandle = null;
    });
  }
}

/// Painter for 9-slice overlay
class _NineSliceOverlayPainter extends CustomPainter {
  final SpriteRegion sprite;
  final NineSliceBorder nineSlice;
  final double scale;
  final Offset offset;
  final bool isEditing;
  final NineSliceHandle? activeHandle;

  _NineSliceOverlayPainter({
    required this.sprite,
    required this.nineSlice,
    required this.scale,
    required this.offset,
    required this.isEditing,
    this.activeHandle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = sprite.sourceRect;

    // Convert to screen coordinates
    final screenRect = Rect.fromLTWH(
      rect.left * scale + offset.dx,
      rect.top * scale + offset.dy,
      rect.width * scale,
      rect.height * scale,
    );

    // Border positions
    final leftLine = screenRect.left + nineSlice.left * scale;
    final rightLine = screenRect.right - nineSlice.right * scale;
    final topLine = screenRect.top + nineSlice.top * scale;
    final bottomLine = screenRect.bottom - nineSlice.bottom * scale;

    // Line paint
    final linePaint = Paint()
      ..color = EditorColors.warning.withValues(alpha: isEditing ? 0.9 : 0.6)
      ..strokeWidth = isEditing ? 2 : 1
      ..style = PaintingStyle.stroke;

    // Dashed line pattern
    const dashLength = 4.0;
    const gapLength = 4.0;

    // Draw vertical lines (left and right)
    _drawDashedLine(
      canvas,
      Offset(leftLine, screenRect.top),
      Offset(leftLine, screenRect.bottom),
      linePaint,
      dashLength,
      gapLength,
      isActive: activeHandle == NineSliceHandle.left,
    );
    _drawDashedLine(
      canvas,
      Offset(rightLine, screenRect.top),
      Offset(rightLine, screenRect.bottom),
      linePaint,
      dashLength,
      gapLength,
      isActive: activeHandle == NineSliceHandle.right,
    );

    // Draw horizontal lines (top and bottom)
    _drawDashedLine(
      canvas,
      Offset(screenRect.left, topLine),
      Offset(screenRect.right, topLine),
      linePaint,
      dashLength,
      gapLength,
      isActive: activeHandle == NineSliceHandle.top,
    );
    _drawDashedLine(
      canvas,
      Offset(screenRect.left, bottomLine),
      Offset(screenRect.right, bottomLine),
      linePaint,
      dashLength,
      gapLength,
      isActive: activeHandle == NineSliceHandle.bottom,
    );

    // Draw region labels if editing
    if (isEditing) {
      _drawRegionLabels(canvas, screenRect, leftLine, rightLine, topLine, bottomLine);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength, {
    bool isActive = false,
  }) {
    if (isActive) {
      // Solid line for active handle
      final activePaint = Paint()
        ..color = EditorColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, activePaint);
      return;
    }

    final distance = (end - start).distance;
    final direction = (end - start) / distance;
    var currentPos = 0.0;

    while (currentPos < distance) {
      final dashEnd = (currentPos + dashLength).clamp(0.0, distance);
      canvas.drawLine(
        start + direction * currentPos,
        start + direction * dashEnd,
        paint,
      );
      currentPos += dashLength + gapLength;
    }
  }

  void _drawRegionLabels(
    Canvas canvas,
    Rect screenRect,
    double leftLine,
    double rightLine,
    double topLine,
    double bottomLine,
  ) {
    final textStyle = ui.TextStyle(
      color: EditorColors.warning,
      fontSize: 8,
    );

    // Draw small labels for each region
    final regions = [
      ('TL', Offset((screenRect.left + leftLine) / 2, (screenRect.top + topLine) / 2)),
      ('T', Offset((leftLine + rightLine) / 2, (screenRect.top + topLine) / 2)),
      ('TR', Offset((rightLine + screenRect.right) / 2, (screenRect.top + topLine) / 2)),
      ('L', Offset((screenRect.left + leftLine) / 2, (topLine + bottomLine) / 2)),
      ('C', Offset((leftLine + rightLine) / 2, (topLine + bottomLine) / 2)),
      ('R', Offset((rightLine + screenRect.right) / 2, (topLine + bottomLine) / 2)),
      ('BL', Offset((screenRect.left + leftLine) / 2, (bottomLine + screenRect.bottom) / 2)),
      ('B', Offset((leftLine + rightLine) / 2, (bottomLine + screenRect.bottom) / 2)),
      ('BR', Offset((rightLine + screenRect.right) / 2, (bottomLine + screenRect.bottom) / 2)),
    ];

    for (final (label, pos) in regions) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ))
        ..pushStyle(textStyle)
        ..addText(label);

      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 20));

      canvas.drawParagraph(
        paragraph,
        Offset(pos.dx - 10, pos.dy - 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NineSliceOverlayPainter oldDelegate) {
    return sprite != oldDelegate.sprite ||
        nineSlice != oldDelegate.nineSlice ||
        scale != oldDelegate.scale ||
        offset != oldDelegate.offset ||
        isEditing != oldDelegate.isEditing ||
        activeHandle != oldDelegate.activeHandle;
  }
}
