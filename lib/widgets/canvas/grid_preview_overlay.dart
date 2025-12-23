import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/grid_preview_provider.dart';
import '../../theme/editor_colors.dart';
import 'source_image_viewer.dart' show TransformedOverlayScope;

/// Overlay widget for displaying grid preview in source panel
/// Shows grid lines and cell numbers based on GridSliceDialog settings
class GridPreviewOverlay extends ConsumerWidget {
  final Size imageSize;

  const GridPreviewOverlay({
    super.key,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(gridPreviewProvider);

    // Don't render if preview is not active
    if (!previewState.isActive) {
      return const SizedBox.shrink();
    }

    // Don't render if no valid grid
    if (previewState.columns <= 0 || previewState.rows <= 0) {
      return const SizedBox.shrink();
    }

    // Check if we're inside TransformedOverlayScope (full viewport mode)
    final scope = TransformedOverlayScope.of(context);

    return IgnorePointer(
      child: RepaintBoundary(
        child: scope != null
            // Full viewport mode - use Transform to position content
            ? SizedBox.expand(
                child: CustomPaint(
                  painter: _GridPreviewPainter(
                    state: previewState,
                    transform: scope.transform,
                    imageSize: scope.imageSize,
                  ),
                ),
              )
            // Legacy mode - fixed image size
            : CustomPaint(
                size: imageSize,
                painter: _GridPreviewPainter(
                  state: previewState,
                  imageSize: imageSize,
                ),
              ),
      ),
    );
  }
}

/// Custom painter for grid preview visualization
class _GridPreviewPainter extends CustomPainter {
  final GridPreviewState state;
  final Matrix4? transform;
  final Size imageSize;

  _GridPreviewPainter({
    required this.state,
    this.transform,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (state.columns <= 0 || state.rows <= 0) return;
    if (state.imageWidth <= 0 || state.imageHeight <= 0) return;

    // Apply transform if provided
    if (transform != null) {
      canvas.save();

      final matrix = transform!;
      final translateX = matrix.entry(0, 3);
      final translateY = matrix.entry(1, 3);
      final scaleX = matrix.entry(0, 0);
      final scaleY = matrix.entry(1, 1);

      canvas.translate(translateX, translateY);
      canvas.scale(scaleX, scaleY);
    }

    // Clip to image bounds
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
      0,
      0,
      state.imageWidth.toDouble(),
      state.imageHeight.toDouble(),
    ));

    // Draw image boundary (fixed frame at image edges)
    _drawImageBoundary(canvas);

    // Draw grid lines extending to image edges
    if (state.showGridLines) {
      _drawGridLines(canvas);
    }

    // Draw cell numbers
    if (state.showCellNumbers) {
      _drawCellNumbers(canvas);
    }

    canvas.restore();

    // Restore canvas if transform was applied
    if (transform != null) {
      canvas.restore();
    }
  }

  /// Draw image boundary frame (fixed at image edges)
  void _drawImageBoundary(Canvas canvas) {
    final boundaryPaint = Paint()
      ..color = EditorColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final boundaryRect = Rect.fromLTWH(
      0,
      0,
      state.imageWidth.toDouble(),
      state.imageHeight.toDouble(),
    );
    canvas.drawRect(boundaryRect, boundaryPaint);
  }

  void _drawGridLines(Canvas canvas) {
    final linePaint = Paint()
      ..color = EditorColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw vertical lines between columns (columns - 1 lines)
    // Lines extend from top to bottom of image for "infinite" feel
    for (int col = 1; col < state.columns; col++) {
      final x = (state.offsetX + col * state.cellWidth).toDouble();
      if (x > 0 && x < state.imageWidth) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, state.imageHeight.toDouble()),
          linePaint,
        );
      }
    }

    // Draw horizontal lines between rows (rows - 1 lines)
    // Lines extend from left to right of image for "infinite" feel
    for (int row = 1; row < state.rows; row++) {
      final y = (state.offsetY + row * state.cellHeight).toDouble();
      if (y > 0 && y < state.imageHeight) {
        canvas.drawLine(
          Offset(0, y),
          Offset(state.imageWidth.toDouble(), y),
          linePaint,
        );
      }
    }
  }

  void _drawCellNumbers(Canvas canvas) {
    int cellIndex = 0;

    for (int row = 0; row < state.rows; row++) {
      for (int col = 0; col < state.columns; col++) {
        final x = state.offsetX + col * state.cellWidth;
        final y = state.offsetY + row * state.cellHeight;

        // Skip cells that are completely outside image bounds
        if (x + state.cellWidth <= 0 ||
            y + state.cellHeight <= 0 ||
            x >= state.imageWidth ||
            y >= state.imageHeight) {
          cellIndex++;
          continue;
        }

        // Format the cell number
        final formattedNumber = _formatNumber(cellIndex);
        final label = '${state.idPrefix}_$formattedNumber';

        // Create text painter
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.white,
              fontSize: _calculateFontSize(),
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black87,
                ),
                Shadow(
                  offset: Offset(-1, -1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: state.cellWidth.toDouble() - 4);

        // Calculate position (center of cell)
        final textX = x + (state.cellWidth - textPainter.width) / 2;
        final textY = y + (state.cellHeight - textPainter.height) / 2;

        // Only draw if text fits reasonably in the cell and is inside image bounds
        if (textPainter.width <= state.cellWidth - 2 &&
            textPainter.height <= state.cellHeight - 2 &&
            textX >= 0 &&
            textY >= 0 &&
            textX + textPainter.width <= state.imageWidth &&
            textY + textPainter.height <= state.imageHeight) {
          textPainter.paint(canvas, Offset(textX, textY));
        }

        cellIndex++;
      }
    }
  }

  String _formatNumber(int number) {
    switch (state.numberFormat) {
      case '001':
        return number.toString().padLeft(3, '0');
      case '01':
        return number.toString().padLeft(2, '0');
      case '1':
      default:
        return number.toString();
    }
  }

  double _calculateFontSize() {
    // Adaptive font size based on cell dimensions
    final minDimension =
        state.cellWidth < state.cellHeight ? state.cellWidth : state.cellHeight;

    if (minDimension < 24) return 6;
    if (minDimension < 32) return 7;
    if (minDimension < 48) return 8;
    if (minDimension < 64) return 9;
    if (minDimension < 96) return 10;
    return 11;
  }

  @override
  bool shouldRepaint(covariant _GridPreviewPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.transform != transform ||
        oldDelegate.imageSize != imageSize;
  }
}
