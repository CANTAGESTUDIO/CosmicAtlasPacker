import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../theme/editor_colors.dart';
import '../common/editor_text_field.dart';

/// Animation settings panel
/// Contains FPS input, Loop checkbox, PingPong checkbox
class AnimationSettingsPanel extends ConsumerStatefulWidget {
  const AnimationSettingsPanel({super.key});

  @override
  ConsumerState<AnimationSettingsPanel> createState() =>
      _AnimationSettingsPanelState();
}

class _AnimationSettingsPanelState
    extends ConsumerState<AnimationSettingsPanel> {
  late TextEditingController _fpsController;
  String? _lastAnimationId;

  @override
  void initState() {
    super.initState();
    _fpsController = TextEditingController();
  }

  @override
  void dispose() {
    _fpsController.dispose();
    super.dispose();
  }

  void _updateFpsController(AnimationSequence? animation) {
    if (animation == null) {
      _fpsController.text = '';
      _lastAnimationId = null;
      return;
    }

    // Only update if animation changed or text doesn't match
    if (_lastAnimationId != animation.id ||
        _fpsController.text != animation.fps.toString()) {
      _fpsController.text = animation.fps.toString();
      _lastAnimationId = animation.id;
    }
  }

  void _onFpsEditingComplete() {
    final animation = ref.read(selectedAnimationProvider);
    if (animation == null) return;

    final fps = int.tryParse(_fpsController.text);
    if (fps == null || fps < 1) {
      _fpsController.text = '1';
      ref.read(animationProvider.notifier).setFps(animation.id, 1);
    } else if (fps > 60) {
      _fpsController.text = '60';
      ref.read(animationProvider.notifier).setFps(animation.id, 60);
    }
  }

  void _onLoopModeChanged(AnimationLoopMode mode) {
    final animation = ref.read(selectedAnimationProvider);
    if (animation == null) return;

    ref.read(animationProvider.notifier).setLoopMode(animation.id, mode);
  }

  @override
  Widget build(BuildContext context) {
    final animation = ref.watch(selectedAnimationProvider);

    // Update FPS controller when animation changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFpsController(animation);
    });

    return Container(
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          bottom: BorderSide(color: EditorColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: EditorColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 14,
                  color: EditorColors.iconDefault,
                ),
                const SizedBox(width: 6),
                Text(
                  '애니메이션 설정',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
          ),

          // Settings content
          Padding(
            padding: const EdgeInsets.all(12),
            child: animation == null
                ? _buildNoAnimationMessage()
                : _buildSettingsContent(animation),
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

  Widget _buildSettingsContent(AnimationSequence animation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FPS Input
        _buildSettingRow(
          label: 'FPS',
          child: ShortcutBlockingNumberField(
            controller: _fpsController,
            width: 80,
            height: 28,
            allowDecimal: false,
            allowNegative: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDefault,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              filled: true,
              fillColor: EditorColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.primary),
              ),
            ),
            onSubmitted: _onFpsEditingComplete,
          ),
        ),
        const SizedBox(height: 12),

        // Loop checkbox
        _buildCheckboxRow(
          label: 'Loop',
          value: animation.loopMode == AnimationLoopMode.loop,
          onChanged: (value) {
            if (value == true) {
              _onLoopModeChanged(AnimationLoopMode.loop);
            } else if (animation.loopMode == AnimationLoopMode.loop) {
              _onLoopModeChanged(AnimationLoopMode.once);
            }
          },
        ),
        const SizedBox(height: 8),

        // Ping Pong checkbox
        _buildCheckboxRow(
          label: 'Ping Pong',
          value: animation.loopMode == AnimationLoopMode.pingPong,
          onChanged: (value) {
            if (value == true) {
              _onLoopModeChanged(AnimationLoopMode.pingPong);
            } else if (animation.loopMode == AnimationLoopMode.pingPong) {
              _onLoopModeChanged(AnimationLoopMode.once);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSettingRow({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled,
            ),
          ),
        ),
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: EditorColors.primary,
            side: BorderSide(color: EditorColors.border),
          ),
        ),
      ],
    );
  }
}
