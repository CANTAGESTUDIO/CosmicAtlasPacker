import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../providers/packing_provider.dart';
import '../../services/bin_packing_service.dart';
import '../../theme/editor_colors.dart';
import '../common/editor_text_field.dart';

/// Animation timeline panel
/// Contains playback controls, frame list, and ID-order setup button
class AnimationTimelinePanel extends ConsumerStatefulWidget {
  const AnimationTimelinePanel({super.key});

  @override
  ConsumerState<AnimationTimelinePanel> createState() =>
      _AnimationTimelinePanelState();
}

class _AnimationTimelinePanelState extends ConsumerState<AnimationTimelinePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = ref.watch(selectedAnimationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final currentFrame = ref.watch(currentPlaybackFrameProvider);

    return Container(
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          top: BorderSide(color: EditorColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header with playback controls
          _buildHeader(animation, isPlaying, currentFrame),

          // Frame list - Fixed height (타일 126 + 패딩 16 + 스크롤바 8 = 150)
          SizedBox(
            height: 150,
            child: animation == null
                ? _buildNoAnimationMessage()
                : _buildFrameList(animation, currentFrame),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    AnimationSequence? animation,
    bool isPlaying,
    int currentFrame,
  ) {
    final frameCount = animation?.frameCount ?? 0;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EditorColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Animation name
          if (animation != null) ...[
            Icon(
              Icons.movie_outlined,
              size: 14,
              color: EditorColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              animation.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EditorColors.iconDefault,
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Playback controls
          _PlaybackButton(
            icon: Icons.skip_previous,
            tooltip: '처음 프레임',
            onPressed: animation == null
                ? null
                : () => ref.read(animationProvider.notifier).goToFirstFrame(),
          ),
          _PlaybackButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            tooltip: isPlaying ? '일시정지' : '재생',
            onPressed: animation == null || animation.isEmpty
                ? null
                : () => ref.read(animationProvider.notifier).togglePlayback(),
          ),
          _PlaybackButton(
            icon: Icons.skip_next,
            tooltip: '마지막 프레임',
            onPressed: animation == null
                ? null
                : () => ref.read(animationProvider.notifier).goToLastFrame(),
          ),

          const SizedBox(width: 12),

          // Frame counter
          Text(
            '$currentFrame / $frameCount frames',
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAnimationMessage() {
    return Center(
      child: Text(
        '애니메이션을 선택하세요',
        style: TextStyle(
          fontSize: 12,
          color: EditorColors.iconDisabled,
        ),
      ),
    );
  }

  Widget _buildFrameList(
    AnimationSequence animation,
    int currentFrame,
  ) {
    if (animation.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ID순 세팅 버튼
            FilledButton.icon(
              onPressed: () => _addSpritesByIdOrder(context, animation),
              icon: const Icon(Icons.sort, size: 16),
              label: const Text('ID순 세팅'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '스프라이트 ID 순서대로 프레임을 추가합니다',
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
          ],
        ),
      );
    }

    // Wrap with Listener for mouse wheel horizontal scroll
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final offset = _scrollController.offset + event.scrollDelta.dy;
          _scrollController.jumpTo(
            offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          );
        }
      },
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(EditorColors.inputBackground),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(6.0),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ReorderableListView.builder(
            scrollController: _scrollController,
            scrollDirection: Axis.horizontal,
            // 상단 4, 하단 12 (스크롤바 공간 확보)
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            proxyDecorator: (child, index, anim) {
              // 드래그 중인 아이템의 크기를 고정하여 overflow 방지
              return Material(
                color: Colors.transparent,
                elevation: 4,
                child: SizedBox(
                  width: 94,
                  height: 126,
                  child: child,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // ReorderableListView는 newIndex가 oldIndex보다 클 때 1을 더함
              if (newIndex > oldIndex) newIndex--;
              ref.read(animationProvider.notifier).reorderFrame(
                    animation.id,
                    oldIndex,
                    newIndex,
                  );
            },
            itemCount: animation.frameCount,
            itemBuilder: (context, index) {
              final frame = animation.frames[index];
              final isCurrentFrame = index == currentFrame;

              return _FrameTile(
                key: ValueKey('frame_${animation.id}_$index'),
                frame: frame,
                index: index,
                isCurrentFrame: isCurrentFrame,
                onTap: () {
                  ref.read(animationProvider.notifier).setPlaybackFrame(index);
                },
                onDurationChanged: (duration) {
                  ref.read(animationProvider.notifier).setFrameDuration(
                        animation.id,
                        index,
                        duration,
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _addSpritesByIdOrder(
    BuildContext context,
    AnimationSequence animation,
  ) {
    // Get all sprites
    final sprites = ref.read(multiSpriteProvider).allSprites;

    if (sprites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스프라이트가 없습니다. 먼저 스프라이트를 추가하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Sort by numeric suffix in ID
    final sorted = sprites.toList()
      ..sort((a, b) {
        final numA = _extractNumericSuffix(a.id);
        final numB = _extractNumericSuffix(b.id);
        if (numA != null && numB != null) return numA.compareTo(numB);
        return a.id.compareTo(b.id); // fallback: string comparison
      });

    // Clear existing frames and add new ones
    final spriteIds = sorted.map((s) => s.id).toList();

    // Clear existing frames first by updating with empty frames
    ref.read(animationProvider.notifier).updateAnimation(
          animation.id,
          animation.copyWith(frames: []),
        );

    // Add frames from sorted sprites
    ref.read(animationProvider.notifier).addFramesFromSprites(
          animation.id,
          spriteIds,
          duration: 1.0 / animation.fps,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${spriteIds.length}개의 프레임이 추가되었습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int? _extractNumericSuffix(String id) {
    final match = RegExp(r'_(\d+)$').firstMatch(id);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}

class _PlaybackButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _PlaybackButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: onPressed == null
              ? EditorColors.iconDisabled
              : EditorColors.iconDefault,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _FrameTile extends ConsumerStatefulWidget {
  final AnimationFrame frame;
  final int index;
  final bool isCurrentFrame;
  final VoidCallback onTap;
  final ValueChanged<double> onDurationChanged;

  const _FrameTile({
    super.key,
    required this.frame,
    required this.index,
    required this.isCurrentFrame,
    required this.onTap,
    required this.onDurationChanged,
  });

  @override
  ConsumerState<_FrameTile> createState() => _FrameTileState();
}

class _FrameTileState extends ConsumerState<_FrameTile> {
  late TextEditingController _durationController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.frame.duration.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(_FrameTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.duration != widget.frame.duration && !_focusNode.hasFocus) {
      _durationController.text = widget.frame.duration.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDurationSubmit() {
    final value = double.tryParse(_durationController.text);
    if (value != null && value > 0) {
      widget.onDurationChanged(value);
    } else {
      // Reset to current value if invalid
      _durationController.text = widget.frame.duration.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 아틀라스 이미지와 패킹 결과 가져오기
    final atlasImageAsync = ref.watch(atlasPreviewImageProvider);
    final packingResult = ref.watch(packingResultProvider);

    // 스프라이트의 패킹된 위치 찾기
    PackedSprite? packedSprite;
    if (packingResult != null) {
      for (final packed in packingResult.packedSprites) {
        if (packed.sprite.id == widget.frame.spriteId) {
          packedSprite = packed;
          break;
        }
      }
    }

    // 타일 고정 높이: 썸네일(64) + spacing(4) + text(14) + spacing(4) + input(24) + padding(16) = 126
    return ReorderableDragStartListener(
      index: widget.index,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 94,
          height: 126,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isCurrentFrame
                ? EditorColors.primary.withValues(alpha: 0.15)
                : EditorColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isCurrentFrame ? EditorColors.primary : EditorColors.border,
              width: widget.isCurrentFrame ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Frame thumbnail
              SizedBox(
                width: 64,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EditorColors.panelBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: atlasImageAsync.when(
                      data: (atlasImage) {
                        if (atlasImage != null && packedSprite != null) {
                          return CustomPaint(
                            size: const Size(64, 64),
                            painter: _FrameThumbnailPainter(
                              atlasImage: atlasImage,
                              packedRect: packedSprite.packedRect,
                            ),
                          );
                        }
                        return _buildPlaceholder();
                      },
                      loading: () => _buildPlaceholder(),
                      error: (_, __) => _buildPlaceholder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Frame index
              Text(
                '#${widget.index}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isCurrentFrame ? FontWeight.w600 : FontWeight.normal,
                  color: widget.isCurrentFrame
                      ? EditorColors.primary
                      : EditorColors.iconDisabled,
                ),
              ),
              const SizedBox(height: 4),

              // Duration input
              SizedBox(
                width: 64,
                height: 24,
                child: ShortcutBlockingNumberField(
                  controller: _durationController,
                  focusNode: _focusNode,
                  width: 64,
                  height: 24,
                  onSubmitted: _onDurationSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image,
        size: 32,
        color: EditorColors.iconDisabled,
      ),
    );
  }
}

/// Custom painter for frame thumbnail (from atlas image)
class _FrameThumbnailPainter extends CustomPainter {
  final ui.Image atlasImage;
  final Rect packedRect;

  _FrameThumbnailPainter({
    required this.atlasImage,
    required this.packedRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (packedRect.isEmpty || packedRect.width <= 0 || packedRect.height <= 0) {
      return;
    }

    // Calculate scale to fit sprite in thumbnail area
    final scaleX = size.width / packedRect.width;
    final scaleY = size.height / packedRect.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final destWidth = packedRect.width * scale;
    final destHeight = packedRect.height * scale;

    final destRect = Rect.fromLTWH(
      (size.width - destWidth) / 2,
      (size.height - destHeight) / 2,
      destWidth,
      destHeight,
    );

    // Draw sprite from atlas image
    canvas.drawImageRect(
      atlasImage,
      packedRect,
      destRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _FrameThumbnailPainter oldDelegate) {
    return atlasImage != oldDelegate.atlasImage ||
        packedRect != oldDelegate.packedRect;
  }
}

