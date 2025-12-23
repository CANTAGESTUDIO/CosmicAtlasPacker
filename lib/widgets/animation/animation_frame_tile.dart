import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/animation_sequence.dart';
import '../../models/sprite_region.dart';
import '../../theme/editor_colors.dart';

/// Individual frame tile in the animation timeline
class AnimationFrameTile extends StatefulWidget {
  final AnimationFrame frame;
  final int index;
  final SpriteRegion? sprite;
  final ui.Image? sourceImage;
  final bool isSelected;
  final bool isPlaybackFrame;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<double>? onDurationChanged;
  final VoidCallback? onFlipXToggle;
  final VoidCallback? onFlipYToggle;

  const AnimationFrameTile({
    super.key,
    required this.frame,
    required this.index,
    this.sprite,
    this.sourceImage,
    this.isSelected = false,
    this.isPlaybackFrame = false,
    this.onTap,
    this.onDelete,
    this.onDurationChanged,
    this.onFlipXToggle,
    this.onFlipYToggle,
  });

  @override
  State<AnimationFrameTile> createState() => _AnimationFrameTileState();
}

class _AnimationFrameTileState extends State<AnimationFrameTile> {
  bool _isHovered = false;
  bool _isEditingDuration = false;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.frame.duration.toStringAsFixed(3),
    );
  }

  @override
  void didUpdateWidget(AnimationFrameTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingDuration &&
        oldWidget.frame.duration != widget.frame.duration) {
      _durationController.text = widget.frame.duration.toStringAsFixed(3);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isPlaybackFrame
        ? EditorColors.warning
        : (widget.isSelected
            ? EditorColors.selection
            : EditorColors.border);

    final backgroundColor = widget.isSelected
        ? EditorColors.selection.withValues(alpha: 0.2)
        : EditorColors.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 72,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: (widget.isSelected || widget.isPlaybackFrame) ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Frame index and delete button
              _buildHeader(),

              // Sprite thumbnail
              Expanded(
                child: _buildThumbnail(),
              ),

              // Duration and flip controls
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          bottom: BorderSide(color: EditorColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Frame index
          Text(
            '${widget.index + 1}',
            style: TextStyle(
              fontSize: 9,
              color: EditorColors.iconDefault,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Delete button (visible on hover)
          if (_isHovered && widget.onDelete != null)
            GestureDetector(
              onTap: widget.onDelete,
              child: Icon(
                Icons.close,
                size: 12,
                color: EditorColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (widget.sprite == null || widget.sourceImage == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 20,
              color: EditorColors.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2),
            Text(
              'Missing',
              style: TextStyle(
                fontSize: 8,
                color: EditorColors.error.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Transform.flip(
            flipX: widget.frame.flipX,
            flipY: widget.frame.flipY,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _FrameThumbnailPainter(
                sourceImage: widget.sourceImage!,
                sourceRect: widget.sprite!.sourceRect,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          top: BorderSide(color: EditorColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Duration input
          Expanded(
            child: _buildDurationInput(),
          ),

          // Flip controls (visible on hover or if active)
          if (_isHovered || widget.frame.flipX || widget.frame.flipY) ...[
            _FlipButton(
              icon: Icons.flip,
              isActive: widget.frame.flipX,
              tooltip: 'Flip X',
              onTap: widget.onFlipXToggle,
            ),
            _FlipButton(
              icon: Icons.flip,
              isActive: widget.frame.flipY,
              tooltip: 'Flip Y',
              isVertical: true,
              onTap: widget.onFlipYToggle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationInput() {
    if (_isEditingDuration) {
      return SizedBox(
        height: 18,
        child: Focus(
          onKeyEvent: (node, event) {
            // Allow Enter key to pass through to TextField's onSubmitted
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              return KeyEventResult.ignored;
            }
            // Block all other keys to prevent shortcuts
            return KeyEventResult.skipRemainingHandlers;
          },
          child: TextField(
            controller: _durationController,
            autofocus: true,
            style: const TextStyle(fontSize: 10),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onSubmitted: (value) {
              _finishEditing();
            },
            onTapOutside: (_) {
              _finishEditing();
            },
          ),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isEditingDuration = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        child: Text(
          '${widget.frame.duration.toStringAsFixed(2)}s',
          style: TextStyle(
            fontSize: 9,
            color: EditorColors.iconDefault,
          ),
        ),
      ),
    );
  }

  void _finishEditing() {
    final value = double.tryParse(_durationController.text);
    if (value != null && value > 0) {
      widget.onDurationChanged?.call(value);
    } else {
      _durationController.text = widget.frame.duration.toStringAsFixed(3);
    }
    setState(() {
      _isEditingDuration = false;
    });
  }
}

/// Flip button widget
class _FlipButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String tooltip;
  final bool isVertical;
  final VoidCallback? onTap;

  const _FlipButton({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    this.isVertical = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: isVertical ? 1.5708 : 0, // 90 degrees in radians
            child: Icon(
              icon,
              size: 12,
              color: isActive
                  ? EditorColors.primary
                  : EditorColors.iconDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for frame thumbnail
class _FrameThumbnailPainter extends CustomPainter {
  final ui.Image sourceImage;
  final Rect sourceRect;

  _FrameThumbnailPainter({
    required this.sourceImage,
    required this.sourceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale to fit sprite in thumbnail area
    final spriteWidth = sourceRect.width;
    final spriteHeight = sourceRect.height;

    final scaleX = size.width / spriteWidth;
    final scaleY = size.height / spriteHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final destWidth = spriteWidth * scale;
    final destHeight = spriteHeight * scale;

    final destRect = Rect.fromLTWH(
      (size.width - destWidth) / 2,
      (size.height - destHeight) / 2,
      destWidth,
      destHeight,
    );

    // Draw checkerboard background
    _drawCheckerboard(canvas, destRect);

    // Draw the sprite
    canvas.drawImageRect(
      sourceImage,
      sourceRect,
      destRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _drawCheckerboard(Canvas canvas, Rect rect) {
    const checkSize = 3.0;
    final paint1 = Paint()..color = const Color(0xFF404040);
    final paint2 = Paint()..color = const Color(0xFF505050);

    canvas.save();
    canvas.clipRect(rect);

    for (double y = rect.top; y < rect.bottom; y += checkSize) {
      for (double x = rect.left; x < rect.right; x += checkSize) {
        final isEven = ((x - rect.left) ~/ checkSize +
                    (y - rect.top) ~/ checkSize) %
                2 ==
            0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FrameThumbnailPainter oldDelegate) {
    return sourceImage != oldDelegate.sourceImage ||
        sourceRect != oldDelegate.sourceRect;
  }
}
