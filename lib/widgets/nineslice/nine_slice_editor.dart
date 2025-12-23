import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sprite_data.dart';
import '../../models/sprite_region.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';
import '../common/editor_text_field.dart';

/// Editor widget for 9-slice border settings
class NineSliceEditor extends ConsumerStatefulWidget {
  final SpriteRegion sprite;

  const NineSliceEditor({
    super.key,
    required this.sprite,
  });

  @override
  ConsumerState<NineSliceEditor> createState() => _NineSliceEditorState();
}

class _NineSliceEditorState extends ConsumerState<NineSliceEditor> {
  late TextEditingController _leftController;
  late TextEditingController _rightController;
  late TextEditingController _topController;
  late TextEditingController _bottomController;

  bool get _isEnabled => widget.sprite.nineSlice?.isEnabled ?? false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final ns = widget.sprite.nineSlice ?? const NineSliceBorder();
    _leftController = TextEditingController(text: ns.left.toString());
    _rightController = TextEditingController(text: ns.right.toString());
    _topController = TextEditingController(text: ns.top.toString());
    _bottomController = TextEditingController(text: ns.bottom.toString());
  }

  @override
  void didUpdateWidget(NineSliceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sprite.id != widget.sprite.id ||
        oldWidget.sprite.nineSlice != widget.sprite.nineSlice) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    final ns = widget.sprite.nineSlice ?? const NineSliceBorder();
    _leftController.text = ns.left.toString();
    _rightController.text = ns.right.toString();
    _topController.text = ns.top.toString();
    _bottomController.text = ns.bottom.toString();
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EditorColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with toggle
          _buildHeader(),
          const SizedBox(height: 8),

          // Border inputs
          _buildBorderInputs(),

          // Quick actions
          if (_isEnabled) ...[
            const SizedBox(height: 8),
            _buildQuickActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.grid_3x3,
          size: 14,
          color: _isEnabled ? EditorColors.primary : EditorColors.iconDisabled,
        ),
        const SizedBox(width: 4),
        Text(
          '9-Slice Border',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _isEnabled ? Colors.white : EditorColors.iconDisabled,
          ),
        ),
        const Spacer(),
        // Enable/Disable toggle
        SizedBox(
          height: 20,
          child: Switch(
            value: _isEnabled,
            onChanged: (enabled) {
              if (enabled) {
                // Enable with default values (10% of sprite size)
                final defaultBorder = _calculateDefaultBorder();
                _applyNineSlice(defaultBorder);
              } else {
                // Disable
                ref.read(spriteProvider.notifier).clearSpriteNineSlice(
                      widget.sprite.id,
                    );
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildBorderInputs() {
    return Opacity(
      opacity: _isEnabled ? 1.0 : 0.5,
      child: Column(
        children: [
          // Top
          _buildBorderRow('Top', _topController, (value) {
            _updateBorder(top: value);
          }),
          const SizedBox(height: 4),

          // Left / Right row
          Row(
            children: [
              Expanded(
                child: _buildBorderRow('Left', _leftController, (value) {
                  _updateBorder(left: value);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBorderRow('Right', _rightController, (value) {
                  _updateBorder(right: value);
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Bottom
          _buildBorderRow('Bottom', _bottomController, (value) {
            _updateBorder(bottom: value);
          }),
        ],
      ),
    );
  }

  Widget _buildBorderRow(
    String label,
    TextEditingController controller,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: EditorColors.iconDefault,
            ),
          ),
        ),
        Expanded(
          child: ShortcutBlockingNumberField(
            controller: controller,
            height: 24,
            allowDecimal: false,
            allowNegative: false,
            textAlign: TextAlign.start,
            style: const TextStyle(fontSize: 11),
            suffixText: 'px',
            onSubmitted: () {
              final intValue = int.tryParse(controller.text) ?? 0;
              onChanged(intValue);
            },
            onTapOutside: () {
              final intValue = int.tryParse(controller.text) ?? 0;
              onChanged(intValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        // Uniform button
        Expanded(
          child: _QuickActionButton(
            label: 'Uniform',
            icon: Icons.crop_square,
            onTap: _showUniformDialog,
          ),
        ),
        const SizedBox(width: 4),
        // Auto (10%) button
        Expanded(
          child: _QuickActionButton(
            label: 'Auto 10%',
            icon: Icons.auto_fix_high,
            onTap: () {
              _applyNineSlice(_calculateDefaultBorder());
            },
          ),
        ),
        const SizedBox(width: 4),
        // Clear button
        Expanded(
          child: _QuickActionButton(
            label: 'Clear',
            icon: Icons.clear,
            onTap: () {
              ref.read(spriteProvider.notifier).clearSpriteNineSlice(
                    widget.sprite.id,
                  );
            },
          ),
        ),
      ],
    );
  }

  NineSliceBorder _calculateDefaultBorder() {
    final width = widget.sprite.width;
    final height = widget.sprite.height;

    // 10% of each dimension, minimum 1px
    final horizontal = (width * 0.1).round().clamp(1, width ~/ 3);
    final vertical = (height * 0.1).round().clamp(1, height ~/ 3);

    return NineSliceBorder(
      left: horizontal,
      right: horizontal,
      top: vertical,
      bottom: vertical,
    );
  }

  void _updateBorder({int? left, int? right, int? top, int? bottom}) {
    final current = widget.sprite.nineSlice ?? const NineSliceBorder();
    final updated = NineSliceBorder(
      left: left ?? current.left,
      right: right ?? current.right,
      top: top ?? current.top,
      bottom: bottom ?? current.bottom,
    );

    // Validate and clamp
    final clamped = updated.clampToSize(
      widget.sprite.width,
      widget.sprite.height,
    );

    _applyNineSlice(clamped);
  }

  void _applyNineSlice(NineSliceBorder nineSlice) {
    ref.read(spriteProvider.notifier).updateSpriteNineSlice(
          widget.sprite.id,
          nineSlice,
        );
  }

  void _showUniformDialog() {
    final controller = TextEditingController(text: '8');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EditorColors.surface,
        title: const Text(
          'Uniform Border',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        content: SizedBox(
          width: 200,
          child: ShortcutBlockingNumberField(
            controller: controller,
            autofocus: true,
            allowDecimal: false,
            allowNegative: false,
            textAlign: TextAlign.start,
            hintText: 'Border size (px)',
            onSubmitted: () {
              final value = int.tryParse(controller.text) ?? 0;
              if (value > 0) {
                final uniform = NineSliceBorder(
                  left: value,
                  right: value,
                  top: value,
                  bottom: value,
                ).clampToSize(widget.sprite.width, widget.sprite.height);
                _applyNineSlice(uniform);
              }
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              if (value > 0) {
                final uniform = NineSliceBorder(
                  left: value,
                  right: value,
                  top: value,
                  bottom: value,
                ).clampToSize(widget.sprite.width, widget.sprite.height);
                _applyNineSlice(uniform);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

/// Quick action button
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: EditorColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: EditorColors.iconDefault),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: EditorColors.iconDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
