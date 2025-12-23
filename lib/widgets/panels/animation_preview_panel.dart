import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../providers/packing_provider.dart';
import '../../services/bin_packing_service.dart';
import '../../theme/editor_colors.dart';

/// Animation preview zoom level state (separate from main editor zoom)
final animationPreviewZoomProvider = StateProvider<double>((ref) => 100.0);

/// Animation preview panel
/// Displays current frame sprite with zoom controls
class AnimationPreviewPanel extends ConsumerStatefulWidget {
  const AnimationPreviewPanel({super.key});

  @override
  ConsumerState<AnimationPreviewPanel> createState() =>
      _AnimationPreviewPanelState();
}

class _AnimationPreviewPanelState extends ConsumerState<AnimationPreviewPanel> {
  final TransformationController _transformController = TransformationController();
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = ref.watch(selectedAnimationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final currentFrame = ref.watch(currentPlaybackFrameProvider);
    final zoomLevel = ref.watch(animationPreviewZoomProvider);

    // Handle playback
    _handlePlayback(animation, isPlaying);

    // Get current frame's sprite
    final currentFrameData = animation?.getFrameAt(currentFrame);
    final sprite = currentFrameData != null
        ? ref.watch(multiSpriteProvider.notifier).getSpriteById(currentFrameData.spriteId)
        : null;

    return Container(
      color: EditorColors.panelBackground,
      child: Column(
        children: [
          // Info header with title
          _buildInfoHeader(animation, sprite, currentFrame),
          // Preview content
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildPreviewContent(animation, sprite, zoomLevel),
                ),
                // Zoom controls - right bottom aligned with atlas preview
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _buildZoomControls(zoomLevel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader(
    AnimationSequence? animation,
    dynamic sprite,
    int currentFrame,
  ) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          bottom: BorderSide(color: EditorColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            'Animation Preview',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          // Sprite size
          Icon(Icons.aspect_ratio, size: 12, color: EditorColors.iconDisabled),
          const SizedBox(width: 4),
          Text(
            sprite != null
                ? '${sprite.sourceRect.width.toInt()}x${sprite.sourceRect.height.toInt()}'
                : '-',
            style: TextStyle(
              fontSize: 10,
              color: EditorColors.iconDisabled,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          // Frame info
          Icon(Icons.movie_outlined, size: 12, color: EditorColors.iconDisabled),
          const SizedBox(width: 4),
          Text(
            animation != null && animation.frameCount > 0
                ? '${currentFrame + 1}/${animation.frameCount}'
                : '0',
            style: TextStyle(fontSize: 10, color: EditorColors.iconDisabled),
          ),
        ],
      ),
    );
  }

  void _handlePlayback(AnimationSequence? animation, bool isPlaying) {
    if (isPlaying && animation != null && animation.isValid) {
      if (_playbackTimer == null || !_playbackTimer!.isActive) {
        _scheduleNextFrame();
      }
    } else {
      _playbackTimer?.cancel();
      _playbackTimer = null;
    }
  }

  void _scheduleNextFrame() {
    _playbackTimer?.cancel();

    // Get current frame's duration from provider
    final durationMs = ref.read(animationProvider.notifier).getCurrentFrameDurationMs();

    _playbackTimer = Timer(Duration(milliseconds: durationMs), () {
      final shouldContinue = ref.read(animationProvider.notifier).advanceFrame();
      if (shouldContinue && ref.read(isPlayingProvider)) {
        _scheduleNextFrame();
      }
    });
  }

  Widget _buildPreviewContent(
    AnimationSequence? animation,
    dynamic sprite,
    double zoomLevel,
  ) {
    if (animation == null) {
      return _buildEmptyState('애니메이션을 선택하세요');
    }

    if (animation.isEmpty) {
      return _buildEmptyState('프레임이 없습니다');
    }

    if (sprite == null) {
      return _buildEmptyState('스프라이트를 찾을 수 없습니다');
    }

    // 아틀라스 이미지와 패킹 결과 가져오기
    final atlasImageAsync = ref.watch(atlasPreviewImageProvider);
    final packingResult = ref.watch(packingResultProvider);

    // 스프라이트의 패킹된 위치 찾기
    PackedSprite? packedSprite;
    if (packingResult != null) {
      for (final packed in packingResult.packedSprites) {
        if (packed.sprite.id == sprite.id) {
          packedSprite = packed;
          break;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.5,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(200),
            onInteractionEnd: (_) {
              // Update zoom level from transform
              final scale = _transformController.value.getMaxScaleOnAxis();
              ref.read(animationPreviewZoomProvider.notifier).state =
                  (scale * 100).roundToDouble();
            },
            child: Center(
              child: atlasImageAsync.when(
                data: (atlasImage) {
                  if (atlasImage != null && packedSprite != null) {
                    return CustomPaint(
                      size: Size(
                        packedSprite.packedRect.width,
                        packedSprite.packedRect.height,
                      ),
                      painter: _AnimationPreviewPainter(
                        atlasImage: atlasImage,
                        packedRect: packedSprite.packedRect,
                      ),
                    );
                  }
                  return _buildImagePlaceholder(sprite);
                },
                loading: () => _buildImagePlaceholder(sprite),
                error: (_, __) => _buildImagePlaceholder(sprite),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(dynamic sprite) {
    return Container(
      width: sprite.sourceRect.width,
      height: sprite.sourceRect.height,
      decoration: BoxDecoration(
        color: EditorColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 32,
          color: EditorColors.iconDisabled,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: EditorColors.iconDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: EditorColors.iconDefault,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(double zoomLevel) {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.panelBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EditorColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom out
          IconButton(
            icon: Icon(
              Icons.remove,
              size: 18,
              color: zoomLevel <= ZoomPresets.min
                  ? EditorColors.iconDisabled
                  : EditorColors.iconDefault,
            ),
            onPressed: zoomLevel <= ZoomPresets.min
                ? null
                : () {
                    final target = ZoomPresets.zoomOut(zoomLevel);
                    _setZoom(target / 100);
                    ref.read(animationPreviewZoomProvider.notifier).state = target;
                  },
            tooltip: 'Zoom Out',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Zoom level display
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '${zoomLevel.round()}%',
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDefault,
              ),
            ),
          ),

          // Zoom in
          IconButton(
            icon: Icon(
              Icons.add,
              size: 18,
              color: zoomLevel >= ZoomPresets.max
                  ? EditorColors.iconDisabled
                  : EditorColors.iconDefault,
            ),
            onPressed: zoomLevel >= ZoomPresets.max
                ? null
                : () {
                    final target = ZoomPresets.zoomIn(zoomLevel);
                    _setZoom(target / 100);
                    ref.read(animationPreviewZoomProvider.notifier).state = target;
                  },
            tooltip: 'Zoom In',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Fit to view
          IconButton(
            icon: Icon(Icons.fit_screen, size: 18, color: EditorColors.iconDefault),
            onPressed: _resetZoom,
            tooltip: 'Fit to View',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _setZoom(double scale) {
    final matrix = _transformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final scaleFactor = scale / currentScale;

    // Get viewport center
    final viewportCenter = Offset(
      context.size?.width ?? 0,
      context.size?.height ?? 0,
    ) / 2;

    // Scale around center
    matrix.translate(viewportCenter.dx, viewportCenter.dy);
    matrix.scale(scaleFactor, scaleFactor);
    matrix.translate(-viewportCenter.dx, -viewportCenter.dy);

    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    ref.read(animationPreviewZoomProvider.notifier).state = 100.0;
  }
}

/// Custom painter for animation preview (from atlas image)
class _AnimationPreviewPainter extends CustomPainter {
  final ui.Image atlasImage;
  final Rect packedRect;

  _AnimationPreviewPainter({
    required this.atlasImage,
    required this.packedRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (packedRect.isEmpty || packedRect.width <= 0 || packedRect.height <= 0) {
      return;
    }

    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw sprite from atlas image
    canvas.drawImageRect(
      atlasImage,
      packedRect,
      destRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimationPreviewPainter oldDelegate) {
    return atlasImage != oldDelegate.atlasImage ||
        packedRect != oldDelegate.packedRect;
  }
}

