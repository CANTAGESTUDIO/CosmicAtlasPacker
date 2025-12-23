import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../theme/editor_colors.dart';
import '../common/editor_text_field.dart';
import 'animation_list_panel.dart';
import 'animation_preview.dart';
import 'animation_timeline.dart';

/// Main animation editor panel combining all animation-related widgets
class AnimationEditorPanel extends ConsumerWidget {
  final ui.Image? sourceImage;

  const AnimationEditorPanel({
    super.key,
    this.sourceImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: EditorColors.panelBackground,
      child: Column(
        children: [
          // Top section: Animation list + Preview
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Animation list (left)
                SizedBox(
                  width: 180,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: EditorColors.border),
                      ),
                    ),
                    child: const AnimationListPanel(),
                  ),
                ),

                // Preview + Settings (right)
                Expanded(
                  child: Row(
                    children: [
                      // Preview
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: AnimationPreview(sourceImage: sourceImage),
                        ),
                      ),

                      // Settings panel
                      SizedBox(
                        width: 160,
                        child: _AnimationSettingsPanel(
                          sourceImage: sourceImage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: EditorColors.border),

          // Bottom section: Timeline
          AnimationTimeline(sourceImage: sourceImage),
        ],
      ),
    );
  }
}

/// Settings panel for the selected animation
class _AnimationSettingsPanel extends ConsumerWidget {
  final ui.Image? sourceImage;

  const _AnimationSettingsPanel({this.sourceImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(animationProvider);
    final selectedAnimation = animationState.selectedAnimation;

    if (selectedAnimation == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            'Select an animation',
            style: TextStyle(
              color: EditorColors.iconDisabled,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings header
          Text(
            'Settings',
            style: TextStyle(
              color: EditorColors.iconDefault,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Loop mode
          _SettingRow(
            label: 'Loop',
            child: DropdownButton<AnimationLoopMode>(
              value: selectedAnimation.loopMode,
              underline: const SizedBox.shrink(),
              isDense: true,
              isExpanded: true,
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
                  ref
                      .read(animationProvider.notifier)
                      .setLoopMode(selectedAnimation.id, mode);
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // Speed
          _SettingRow(
            label: 'Speed',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: selectedAnimation.speed,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    onChanged: (value) {
                      ref
                          .read(animationProvider.notifier)
                          .setSpeed(selectedAnimation.id, value);
                    },
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${selectedAnimation.speed.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 9,
                      color: EditorColors.iconDefault,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Uniform duration button
          _SettingRow(
            label: 'Duration',
            child: _UniformDurationButton(animation: selectedAnimation),
          ),

          const Spacer(),

          // Stats
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: EditorColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                _StatRow(
                  label: 'Frames',
                  value: '${selectedAnimation.frameCount}',
                ),
                _StatRow(
                  label: 'Duration',
                  value: '${selectedAnimation.totalDuration.toStringAsFixed(2)}s',
                ),
                _StatRow(
                  label: 'Sprites',
                  value: '${selectedAnimation.usedSpriteIds.length}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Setting row with label and child widget
class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 24,
          child: child,
        ),
      ],
    );
  }
}

/// Stat display row
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: EditorColors.iconDisabled,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: EditorColors.iconDefault,
            ),
          ),
        ],
      ),
    );
  }
}

/// Button to set uniform duration for all frames
class _UniformDurationButton extends ConsumerStatefulWidget {
  final AnimationSequence animation;

  const _UniformDurationButton({required this.animation});

  @override
  ConsumerState<_UniformDurationButton> createState() =>
      _UniformDurationButtonState();
}

class _UniformDurationButtonState
    extends ConsumerState<_UniformDurationButton> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller.text = '0.1';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: ShortcutBlockingNumberField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.start,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                border: OutlineInputBorder(),
                suffixText: 's',
              ),
              onSubmitted: () => _applyUniformDuration(_controller.text),
              onEscape: () => setState(() => _isEditing = false),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => setState(() => _isEditing = false),
            icon: const Icon(Icons.close, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => setState(() => _isEditing = true),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(color: EditorColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Set Uniform...',
          style: TextStyle(
            fontSize: 10,
            color: EditorColors.iconDefault,
          ),
        ),
      ),
    );
  }

  void _applyUniformDuration(String value) {
    final duration = double.tryParse(value);
    if (duration != null && duration > 0) {
      ref
          .read(animationProvider.notifier)
          .setUniformDuration(widget.animation.id, duration);
    }
    setState(() => _isEditing = false);
  }
}
