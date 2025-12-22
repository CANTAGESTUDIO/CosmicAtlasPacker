import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';
import 'animation_frame_tile.dart';

/// Horizontal timeline widget for animation frames
class AnimationTimeline extends ConsumerWidget {
  final ui.Image? sourceImage;

  const AnimationTimeline({
    super.key,
    this.sourceImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(animationProvider);
    final selectedAnimation = animationState.selectedAnimation;

    if (selectedAnimation == null) {
      return _buildEmptyState(context, ref);
    }

    if (selectedAnimation.isEmpty) {
      return _buildNoFramesState(context, ref, selectedAnimation);
    }

    return _buildTimeline(context, ref, selectedAnimation, animationState);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      height: 120,
      color: EditorColors.panelBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 32,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              'No Animation Selected',
              style: TextStyle(
                color: EditorColors.iconDisabled,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                ref.read(animationProvider.notifier).createAnimation();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Animation'),
              style: TextButton.styleFrom(
                foregroundColor: EditorColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFramesState(
    BuildContext context,
    WidgetRef ref,
    AnimationSequence animation,
  ) {
    return Container(
      height: 120,
      color: EditorColors.panelBackground,
      child: Column(
        children: [
          _buildTimelineHeader(context, ref, animation),
          Expanded(
            child: Center(
              child: Text(
                'Drag sprites here to add frames',
                style: TextStyle(
                  color: EditorColors.iconDisabled,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    WidgetRef ref,
    AnimationSequence animation,
    AnimationState state,
  ) {
    return Container(
      height: 120,
      color: EditorColors.panelBackground,
      child: Column(
        children: [
          _buildTimelineHeader(context, ref, animation),
          Expanded(
            child: _buildFrameList(context, ref, animation, state),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader(
    BuildContext context,
    WidgetRef ref,
    AnimationSequence animation,
  ) {
    final animState = ref.watch(animationProvider);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          bottom: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Row(
        children: [
          // Animation name
          Expanded(
            child: Text(
              animation.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Frame count
          Text(
            '${animation.frameCount} frames',
            style: TextStyle(
              fontSize: 10,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(width: 8),

          // Total duration
          Text(
            '${animation.totalDuration.toStringAsFixed(2)}s',
            style: TextStyle(
              fontSize: 10,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(width: 12),

          // Playback controls
          _PlaybackButton(
            icon: Icons.skip_previous,
            onPressed: animState.isPlaying
                ? null
                : () => ref.read(animationProvider.notifier).goToFirstFrame(),
            tooltip: 'First Frame',
          ),
          _PlaybackButton(
            icon: Icons.chevron_left,
            onPressed: animState.isPlaying
                ? null
                : () => ref.read(animationProvider.notifier).previousFrame(),
            tooltip: 'Previous Frame',
          ),
          _PlaybackButton(
            icon: animState.isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: () =>
                ref.read(animationProvider.notifier).togglePlayback(),
            tooltip: animState.isPlaying ? 'Pause' : 'Play',
            isActive: animState.isPlaying,
          ),
          _PlaybackButton(
            icon: Icons.stop,
            onPressed: animState.isPlaying
                ? () => ref.read(animationProvider.notifier).stop()
                : null,
            tooltip: 'Stop',
          ),
          _PlaybackButton(
            icon: Icons.chevron_right,
            onPressed: animState.isPlaying
                ? null
                : () => ref.read(animationProvider.notifier).nextFrame(),
            tooltip: 'Next Frame',
          ),
          _PlaybackButton(
            icon: Icons.skip_next,
            onPressed: animState.isPlaying
                ? null
                : () => ref.read(animationProvider.notifier).goToLastFrame(),
            tooltip: 'Last Frame',
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: EditorColors.border),
          const SizedBox(width: 8),

          // Loop mode dropdown
          _LoopModeDropdown(animation: animation),
        ],
      ),
    );
  }

  Widget _buildFrameList(
    BuildContext context,
    WidgetRef ref,
    AnimationSequence animation,
    AnimationState state,
  ) {
    final spriteState = ref.watch(spriteProvider);

    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(4),
      itemCount: animation.frameCount,
      onReorder: (oldIndex, newIndex) {
        ref.read(animationProvider.notifier).reorderFrame(
              animation.id,
              oldIndex,
              newIndex,
            );
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final frame = animation.frames[index];
        final isSelected = state.selectedFrameIndex == index;
        final isPlaybackFrame = state.currentPlaybackFrame == index;

        // Find sprite for this frame
        final sprite = spriteState.sprites
            .where((s) => s.id == frame.spriteId)
            .firstOrNull;

        return AnimationFrameTile(
          key: ValueKey('frame_$index'),
          frame: frame,
          index: index,
          sprite: sprite,
          sourceImage: sourceImage,
          isSelected: isSelected,
          isPlaybackFrame: isPlaybackFrame,
          onTap: () {
            ref.read(animationProvider.notifier).selectFrame(index);
          },
          onDelete: () {
            ref.read(animationProvider.notifier).removeFrameAt(
                  animation.id,
                  index,
                );
          },
          onDurationChanged: (duration) {
            ref.read(animationProvider.notifier).setFrameDuration(
                  animation.id,
                  index,
                  duration,
                );
          },
          onFlipXToggle: () {
            ref.read(animationProvider.notifier).toggleFrameFlipX(
                  animation.id,
                  index,
                );
          },
          onFlipYToggle: () {
            ref.read(animationProvider.notifier).toggleFrameFlipY(
                  animation.id,
                  index,
                );
          },
        );
      },
    );
  }
}

/// Playback control button
class _PlaybackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isActive;

  const _PlaybackButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: onPressed == null
                ? EditorColors.iconDisabled
                : (isActive ? EditorColors.primary : EditorColors.iconDefault),
          ),
        ),
      ),
    );
  }
}

/// Loop mode dropdown
class _LoopModeDropdown extends ConsumerWidget {
  final AnimationSequence animation;

  const _LoopModeDropdown({required this.animation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<AnimationLoopMode>(
      value: animation.loopMode,
      underline: const SizedBox.shrink(),
      isDense: true,
      dropdownColor: EditorColors.surface,
      style: TextStyle(
        fontSize: 10,
        color: EditorColors.iconDefault,
      ),
      items: const [
        DropdownMenuItem(
          value: AnimationLoopMode.once,
          child: Text('Once'),
        ),
        DropdownMenuItem(
          value: AnimationLoopMode.loop,
          child: Text('Loop'),
        ),
        DropdownMenuItem(
          value: AnimationLoopMode.pingPong,
          child: Text('Ping-Pong'),
        ),
      ],
      onChanged: (mode) {
        if (mode != null) {
          ref.read(animationProvider.notifier).setLoopMode(animation.id, mode);
        }
      },
    );
  }
}
