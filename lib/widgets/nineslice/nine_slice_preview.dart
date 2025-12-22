import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/sprite_data.dart';
import '../../models/sprite_region.dart';
import '../../theme/editor_colors.dart';

/// Preview widget showing how a 9-slice sprite would stretch
class NineSlicePreview extends StatefulWidget {
  final SpriteRegion sprite;
  final ui.Image sourceImage;

  const NineSlicePreview({
    super.key,
    required this.sprite,
    required this.sourceImage,
  });

  @override
  State<NineSlicePreview> createState() => _NineSlicePreviewState();
}

class _NineSlicePreviewState extends State<NineSlicePreview> {
  double _previewScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final nineSlice = widget.sprite.nineSlice;
    if (nineSlice == null || !nineSlice.isEnabled) {
      return _buildDisabledState();
    }

    return Container(
      decoration: BoxDecoration(
        color: EditorColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with scale controls
          _buildHeader(),

          // Preview area
          Expanded(
            child: _buildPreviewArea(nineSlice),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledState() {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_3x3,
              size: 32,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              '9-Slice not enabled',
              style: TextStyle(
                color: EditorColors.iconDisabled,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          bottom: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.aspect_ratio, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),

          // Scale presets
          _ScaleButton(
            label: '1x',
            isActive: _previewScale == 1.0,
            onTap: () => setState(() => _previewScale = 1.0),
          ),
          const SizedBox(width: 4),
          _ScaleButton(
            label: '1.5x',
            isActive: _previewScale == 1.5,
            onTap: () => setState(() => _previewScale = 1.5),
          ),
          const SizedBox(width: 4),
          _ScaleButton(
            label: '2x',
            isActive: _previewScale == 2.0,
            onTap: () => setState(() => _previewScale = 2.0),
          ),
          const SizedBox(width: 4),
          _ScaleButton(
            label: '3x',
            isActive: _previewScale == 3.0,
            onTap: () => setState(() => _previewScale = 3.0),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(NineSliceBorder nineSlice) {
    final originalWidth = widget.sprite.width.toDouble();
    final originalHeight = widget.sprite.height.toDouble();

    final previewWidth = originalWidth * _previewScale;
    final previewHeight = originalHeight * _previewScale;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Size info
            Text(
              '${previewWidth.round()} x ${previewHeight.round()} px',
              style: TextStyle(
                fontSize: 10,
                color: EditorColors.iconDefault,
              ),
            ),
            const SizedBox(height: 8),

            // Preview
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: EditorColors.border,
                  width: 1,
                ),
              ),
              child: ClipRect(
                child: CustomPaint(
                  size: Size(previewWidth, previewHeight),
                  painter: _NineSlicePreviewPainter(
                    sourceImage: widget.sourceImage,
                    sourceRect: widget.sprite.sourceRect,
                    nineSlice: nineSlice,
                    targetSize: Size(previewWidth, previewHeight),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Original size for comparison
            Text(
              'Original: ${originalWidth.round()} x ${originalHeight.round()} px',
              style: TextStyle(
                fontSize: 9,
                color: EditorColors.iconDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scale preset button
class _ScaleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ScaleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? EditorColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? Colors.white : EditorColors.iconDefault,
          ),
        ),
      ),
    );
  }
}

/// Painter for 9-slice stretched preview
class _NineSlicePreviewPainter extends CustomPainter {
  final ui.Image sourceImage;
  final Rect sourceRect;
  final NineSliceBorder nineSlice;
  final Size targetSize;

  _NineSlicePreviewPainter({
    required this.sourceImage,
    required this.sourceRect,
    required this.nineSlice,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw checkerboard background
    _drawCheckerboard(canvas, size);

    // Source dimensions
    final srcLeft = sourceRect.left;
    final srcTop = sourceRect.top;
    final srcWidth = sourceRect.width;
    final srcHeight = sourceRect.height;

    // Border values
    final l = nineSlice.left.toDouble();
    final r = nineSlice.right.toDouble();
    final t = nineSlice.top.toDouble();
    final b = nineSlice.bottom.toDouble();

    // Target dimensions
    final dstWidth = size.width;
    final dstHeight = size.height;

    // Calculate center sizes
    final srcCenterW = srcWidth - l - r;
    final srcCenterH = srcHeight - t - b;
    final dstCenterW = dstWidth - l - r;
    final dstCenterH = dstHeight - t - b;

    final paint = Paint()..filterQuality = FilterQuality.low;

    // Draw 9 regions
    // Top-left corner (no stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft, srcTop, l, t),
      Rect.fromLTWH(0, 0, l, t),
    );

    // Top center (horizontal stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft + l, srcTop, srcCenterW, t),
      Rect.fromLTWH(l, 0, dstCenterW, t),
    );

    // Top-right corner (no stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft + srcWidth - r, srcTop, r, t),
      Rect.fromLTWH(dstWidth - r, 0, r, t),
    );

    // Middle-left (vertical stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft, srcTop + t, l, srcCenterH),
      Rect.fromLTWH(0, t, l, dstCenterH),
    );

    // Center (both stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft + l, srcTop + t, srcCenterW, srcCenterH),
      Rect.fromLTWH(l, t, dstCenterW, dstCenterH),
    );

    // Middle-right (vertical stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft + srcWidth - r, srcTop + t, r, srcCenterH),
      Rect.fromLTWH(dstWidth - r, t, r, dstCenterH),
    );

    // Bottom-left corner (no stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft, srcTop + srcHeight - b, l, b),
      Rect.fromLTWH(0, dstHeight - b, l, b),
    );

    // Bottom center (horizontal stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft + l, srcTop + srcHeight - b, srcCenterW, b),
      Rect.fromLTWH(l, dstHeight - b, dstCenterW, b),
    );

    // Bottom-right corner (no stretch)
    _drawRegion(
      canvas,
      paint,
      Rect.fromLTWH(srcLeft + srcWidth - r, srcTop + srcHeight - b, r, b),
      Rect.fromLTWH(dstWidth - r, dstHeight - b, r, b),
    );
  }

  void _drawRegion(Canvas canvas, Paint paint, Rect src, Rect dst) {
    // Skip if source or destination has zero or negative size
    if (src.width <= 0 || src.height <= 0 || dst.width <= 0 || dst.height <= 0) {
      return;
    }

    canvas.drawImageRect(sourceImage, src, dst, paint);
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    const checkSize = 6.0;
    final paint1 = Paint()..color = const Color(0xFF3A3A3A);
    final paint2 = Paint()..color = const Color(0xFF4A4A4A);

    for (double y = 0; y < size.height; y += checkSize) {
      for (double x = 0; x < size.width; x += checkSize) {
        final isEven = ((x ~/ checkSize) + (y ~/ checkSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NineSlicePreviewPainter oldDelegate) {
    return sourceImage != oldDelegate.sourceImage ||
        sourceRect != oldDelegate.sourceRect ||
        nineSlice != oldDelegate.nineSlice ||
        targetSize != oldDelegate.targetSize;
  }
}
