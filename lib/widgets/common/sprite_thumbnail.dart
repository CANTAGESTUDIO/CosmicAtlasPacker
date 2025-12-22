import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/sprite_region.dart';
import '../../theme/editor_colors.dart';

/// Thumbnail widget for displaying a cropped sprite from source image
/// If sprite has uiImage (extracted image), it will use that instead of cropping from sourceImage
class SpriteThumbnail extends StatelessWidget {
  final SpriteRegion sprite;
  final ui.Image sourceImage;
  final bool isSelected;
  final bool hasDuplicateId;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const SpriteThumbnail({
    super.key,
    required this.sprite,
    required this.sourceImage,
    this.isSelected = false,
    this.hasDuplicateId = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasDuplicateId
        ? EditorColors.error
        : (isSelected ? EditorColors.selection : EditorColors.border);
    final backgroundColor = hasDuplicateId
        ? EditorColors.error.withValues(alpha: 0.15)
        : (isSelected ? EditorColors.selection.withValues(alpha: 0.2) : EditorColors.surface);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: (isSelected || hasDuplicateId) ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Thumbnail image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        // Ensure valid size for painting
                        if (size.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return CustomPaint(
                          size: size,
                          painter: _SpriteThumbnailPainter(
                            sourceImage: sourceImage,
                            sourceRect: sprite.sourceRect,
                            spriteImage: sprite.uiImage,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Sprite ID label
                Container(
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  child: Text(
                    sprite.id,
                    style: TextStyle(
                      fontSize: 9,
                      color: hasDuplicateId
                          ? EditorColors.error
                          : (isSelected ? EditorColors.selection : EditorColors.iconDefault),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Duplicate warning icon
            if (hasDuplicateId)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: EditorColors.error,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for rendering cropped sprite thumbnail
class _SpriteThumbnailPainter extends CustomPainter {
  final ui.Image sourceImage;
  final Rect sourceRect;
  final ui.Image? spriteImage;

  _SpriteThumbnailPainter({
    required this.sourceImage,
    required this.sourceRect,
    this.spriteImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Validate source rect
    if (sourceRect.isEmpty || sourceRect.width <= 0 || sourceRect.height <= 0) {
      return;
    }

    // Calculate scale to fit sprite in thumbnail area while maintaining aspect ratio
    final spriteWidth = sourceRect.width;
    final spriteHeight = sourceRect.height;

    final scaleX = size.width / spriteWidth;
    final scaleY = size.height / spriteHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final destWidth = spriteWidth * scale;
    final destHeight = spriteHeight * scale;

    // Center the sprite in the thumbnail area
    final destRect = Rect.fromLTWH(
      (size.width - destWidth) / 2,
      (size.height - destHeight) / 2,
      destWidth,
      destHeight,
    );

    // Draw checkerboard background for transparency
    _drawCheckerboard(canvas, destRect);

    // If sprite has its own extracted image, use it directly
    if (spriteImage != null) {
      final spriteSourceRect = Rect.fromLTWH(
        0,
        0,
        spriteImage!.width.toDouble(),
        spriteImage!.height.toDouble(),
      );
      canvas.drawImageRect(
        spriteImage!,
        spriteSourceRect,
        destRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }

    // Fallback: crop from source image
    // Ensure source rect is within image bounds
    final clampedSourceRect = Rect.fromLTRB(
      sourceRect.left.clamp(0, sourceImage.width.toDouble()),
      sourceRect.top.clamp(0, sourceImage.height.toDouble()),
      sourceRect.right.clamp(0, sourceImage.width.toDouble()),
      sourceRect.bottom.clamp(0, sourceImage.height.toDouble()),
    );

    if (clampedSourceRect.isEmpty) return;

    // Draw the cropped sprite
    canvas.drawImageRect(
      sourceImage,
      clampedSourceRect,
      destRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _drawCheckerboard(Canvas canvas, Rect rect) {
    const checkSize = 4.0;
    final paint1 = Paint()..color = const Color(0xFF404040);
    final paint2 = Paint()..color = const Color(0xFF606060);

    canvas.save();
    canvas.clipRect(rect);

    for (double y = rect.top; y < rect.bottom; y += checkSize) {
      for (double x = rect.left; x < rect.right; x += checkSize) {
        final isEven = ((x - rect.left) ~/ checkSize + (y - rect.top) ~/ checkSize) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpriteThumbnailPainter oldDelegate) {
    return sourceImage != oldDelegate.sourceImage ||
        sourceRect != oldDelegate.sourceRect ||
        spriteImage != oldDelegate.spriteImage;
  }
}
