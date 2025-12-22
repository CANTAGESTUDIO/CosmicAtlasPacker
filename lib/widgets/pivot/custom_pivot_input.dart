import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/enums/pivot_preset.dart';
import '../../models/sprite_data.dart';
import '../../theme/editor_colors.dart';

/// Custom pivot coordinate input widget
class CustomPivotInput extends StatefulWidget {
  final PivotPoint pivot;
  final ValueChanged<PivotPoint> onPivotChanged;

  const CustomPivotInput({
    super.key,
    required this.pivot,
    required this.onPivotChanged,
  });

  @override
  State<CustomPivotInput> createState() => _CustomPivotInputState();
}

class _CustomPivotInputState extends State<CustomPivotInput> {
  late TextEditingController _xController;
  late TextEditingController _yController;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController(text: widget.pivot.x.toStringAsFixed(2));
    _yController = TextEditingController(text: widget.pivot.y.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(CustomPivotInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pivot != widget.pivot) {
      _xController.text = widget.pivot.x.toStringAsFixed(2);
      _yController.text = widget.pivot.y.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _onXChanged(String value) {
    final x = double.tryParse(value);
    if (x != null && x >= 0.0 && x <= 1.0) {
      widget.onPivotChanged(PivotPoint(
        x: x,
        y: widget.pivot.y,
        preset: PivotPreset.custom,
      ));
    }
  }

  void _onYChanged(String value) {
    final y = double.tryParse(value);
    if (y != null && y >= 0.0 && y <= 1.0) {
      widget.onPivotChanged(PivotPoint(
        x: widget.pivot.x,
        y: y,
        preset: PivotPreset.custom,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Custom',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDefault,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _CoordinateField(
              label: 'X',
              controller: _xController,
              onChanged: _onXChanged,
            ),
            const SizedBox(width: 8),
            _CoordinateField(
              label: 'Y',
              controller: _yController,
              onChanged: _onYChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _CoordinateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CoordinateField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: EditorColors.iconDisabled,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 24,
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDefault,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  filled: true,
                  fillColor: EditorColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(color: EditorColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(color: EditorColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: const BorderSide(color: EditorColors.primary),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onSubmitted: onChanged,
                onEditingComplete: () {
                  onChanged(controller.text);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Combined pivot editor with 3x3 selector and custom input
class PivotEditor extends StatelessWidget {
  final PivotPoint pivot;
  final ValueChanged<PivotPoint> onPivotChanged;

  const PivotEditor({
    super.key,
    required this.pivot,
    required this.onPivotChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Pivot',
          style: TextStyle(
            fontSize: 12,
            color: EditorColors.iconDefault,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _PivotSelectorGrid(
          selectedPreset: pivot.preset,
          onPresetSelected: (preset) {
            onPivotChanged(PivotPoint.fromPreset(preset));
          },
        ),
        const SizedBox(height: 8),
        CustomPivotInput(
          pivot: pivot,
          onPivotChanged: onPivotChanged,
        ),
      ],
    );
  }
}

/// 3x3 pivot selector grid with visual representation
class _PivotSelectorGrid extends StatelessWidget {
  final PivotPreset? selectedPreset;
  final ValueChanged<PivotPreset> onPresetSelected;

  const _PivotSelectorGrid({
    this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate size: border(2) + padding(4) + 3 buttons + 2 gaps(4)
    const borderWidth = 1.0;
    const padding = 2.0;
    const gap = 2.0;
    const buttonSize = 18.0;
    const innerSize = (buttonSize * 3) + (gap * 2); // 58px
    const size = innerSize + (padding * 2) + (borderWidth * 2); // 64px

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border, width: borderWidth),
      ),
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(
            [PivotPreset.topLeft, PivotPreset.topCenter, PivotPreset.topRight],
            buttonSize,
          ),
          const SizedBox(height: gap),
          _buildRow(
            [
              PivotPreset.centerLeft,
              PivotPreset.center,
              PivotPreset.centerRight,
            ],
            buttonSize,
          ),
          const SizedBox(height: gap),
          _buildRow(
            [
              PivotPreset.bottomLeft,
              PivotPreset.bottomCenter,
              PivotPreset.bottomRight,
            ],
            buttonSize,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<PivotPreset> presets, double buttonSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < presets.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          _PivotGridButton(
            preset: presets[i],
            isSelected: selectedPreset == presets[i],
            size: buttonSize,
            onTap: () => onPresetSelected(presets[i]),
          ),
        ],
      ],
    );
  }
}

class _PivotGridButton extends StatefulWidget {
  final PivotPreset preset;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;

  const _PivotGridButton({
    required this.preset,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  @override
  State<_PivotGridButton> createState() => _PivotGridButtonState();
}

class _PivotGridButtonState extends State<_PivotGridButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? EditorColors.primary.withValues(alpha: 0.3)
                : _isHovered
                    ? EditorColors.surface
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: widget.isSelected
                  ? EditorColors.primary
                  : _isHovered
                      ? EditorColors.iconDefault.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? EditorColors.primary
                    : _isHovered
                        ? EditorColors.iconDefault
                        : EditorColors.iconDisabled,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
