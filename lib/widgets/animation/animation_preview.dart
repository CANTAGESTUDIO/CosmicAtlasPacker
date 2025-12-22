import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Animation preview widget with playback controls
class AnimationPreview extends ConsumerStatefulWidget {
  final ui.Image? sourceImage;

  const AnimationPreview({
    super.key,
    this.sourceImage,
  });

  @override
  ConsumerState<AnimationPreview> createState() => _AnimationPreviewState();
}

class _AnimationPreviewState extends ConsumerState<AnimationPreview> {
  Timer? _playbackTimer;
  int _pingPongDirection = 1; // 1 = forward, -1 = backward

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationState = ref.watch(animationProvider);
    final selectedAnimation = animationState.selectedAnimation;

    // Handle playback state changes
    ref.listen<bool>(isPlayingProvider, (previous, isPlaying) {
      if (isPlaying) {
        _startPlayback();
      } else {
        _stopPlayback();
      }
    });

    if (selectedAnimation == null || selectedAnimation.isEmpty) {
      return _buildEmptyPreview();
    }

    return _buildPreview(selectedAnimation, animationState);
  }

  Widget _buildEmptyPreview() {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.canvasBackground,
        border: Border.all(color: EditorColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 48,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              'No Animation',
              style: TextStyle(
                color: EditorColors.iconDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(AnimationSequence animation, AnimationState state) {
    final currentFrame = animation.getFrameAt(state.currentPlaybackFrame);
    final spriteState = ref.watch(spriteProvider);

    // Find sprite for current frame
    final sprite = currentFrame != null
        ? spriteState.sprites
            .where((s) => s.id == currentFrame.spriteId)
            .firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: EditorColors.canvasBackground,
        border: Border.all(color: EditorColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Checkerboard background
          Positioned.fill(
            child: CustomPaint(
              painter: _CheckerboardPainter(),
            ),
          ),

          // Sprite preview
          if (sprite != null && widget.sourceImage != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Transform.flip(
                  flipX: currentFrame!.flipX,
                  flipY: currentFrame.flipY,
                  child: CustomPaint(
                    painter: _SpritePreviewPainter(
                      sourceImage: widget.sourceImage!,
                      sourceRect: sprite.sourceRect,
                    ),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 32,
                color: EditorColors.error.withValues(alpha: 0.5),
              ),
            ),

          // Frame info overlay
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'Frame ${state.currentPlaybackFrame + 1}/${animation.frameCount}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                ),
              ),
            ),
          ),

          // Playback indicator
          if (state.isPlaying)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: EditorColors.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'Playing',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _pingPongDirection = 1;

    final animation = ref.read(animationProvider).selectedAnimation;
    if (animation == null || animation.isEmpty) return;

    _scheduleNextFrame(animation);
  }

  void _scheduleNextFrame(AnimationSequence animation) {
    final state = ref.read(animationProvider);
    if (!state.isPlaying) return;

    final currentFrame = animation.getFrameAt(state.currentPlaybackFrame);
    if (currentFrame == null) return;

    // Calculate delay based on frame duration and animation speed
    final delay = Duration(
      milliseconds: (currentFrame.duration * 1000 / animation.speed).round(),
    );

    _playbackTimer = Timer(delay, () {
      if (!mounted) return;

      final currentState = ref.read(animationProvider);
      if (!currentState.isPlaying) return;

      final nextFrame = _calculateNextFrame(animation, currentState);

      if (nextFrame == null) {
        // Animation ended (once mode)
        ref.read(animationProvider.notifier).stop();
        return;
      }

      ref.read(animationProvider.notifier).setPlaybackFrame(nextFrame);

      // Schedule next frame
      final updatedAnimation = ref.read(animationProvider).selectedAnimation;
      if (updatedAnimation != null) {
        _scheduleNextFrame(updatedAnimation);
      }
    });
  }

  int? _calculateNextFrame(AnimationSequence animation, AnimationState state) {
    final currentFrame = state.currentPlaybackFrame;
    final frameCount = animation.frameCount;

    switch (animation.loopMode) {
      case AnimationLoopMode.once:
        if (currentFrame >= frameCount - 1) {
          return null; // End of animation
        }
        return currentFrame + 1;

      case AnimationLoopMode.loop:
        return (currentFrame + 1) % frameCount;

      case AnimationLoopMode.pingPong:
        int nextFrame = currentFrame + _pingPongDirection;

        if (nextFrame >= frameCount) {
          _pingPongDirection = -1;
          nextFrame = frameCount - 2;
          if (nextFrame < 0) nextFrame = 0;
        } else if (nextFrame < 0) {
          _pingPongDirection = 1;
          nextFrame = 1;
          if (nextFrame >= frameCount) nextFrame = 0;
        }

        return nextFrame;
    }
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }
}

/// Checkerboard background painter
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const checkSize = 8.0;
    final paint1 = Paint()..color = const Color(0xFF2A2A2A);
    final paint2 = Paint()..color = const Color(0xFF323232);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sprite preview painter
class _SpritePreviewPainter extends CustomPainter {
  final ui.Image sourceImage;
  final Rect sourceRect;

  _SpritePreviewPainter({
    required this.sourceImage,
    required this.sourceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale to fit sprite in preview area
    final spriteWidth = sourceRect.width;
    final spriteHeight = sourceRect.height;

    final scaleX = size.width / spriteWidth;
    final scaleY = size.height / spriteHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Limit scale to avoid too much enlargement
    final clampedScale = scale.clamp(0.5, 4.0);

    final destWidth = spriteWidth * clampedScale;
    final destHeight = spriteHeight * clampedScale;

    final destRect = Rect.fromLTWH(
      (size.width - destWidth) / 2,
      (size.height - destHeight) / 2,
      destWidth,
      destHeight,
    );

    // Draw the sprite
    canvas.drawImageRect(
      sourceImage,
      sourceRect,
      destRect,
      Paint()..filterQuality = FilterQuality.low, // Pixel-perfect for pixel art
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePreviewPainter oldDelegate) {
    return sourceImage != oldDelegate.sourceImage ||
        sourceRect != oldDelegate.sourceRect;
  }
}
