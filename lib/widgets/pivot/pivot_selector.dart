import 'package:flutter/material.dart';

import '../../models/enums/pivot_preset.dart';
import '../../theme/editor_colors.dart';

/// 3x3 grid pivot selector widget
class PivotSelector extends StatelessWidget {
  final PivotPreset? selectedPreset;
  final ValueChanged<PivotPreset> onPresetSelected;
  final double size;

  const PivotSelector({
    super.key,
    this.selectedPreset,
    required this.onPresetSelected,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = (size - 8) / 3; // 3x3 grid with 4px gaps

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(
            [PivotPreset.topLeft, PivotPreset.topCenter, PivotPreset.topRight],
            buttonSize,
          ),
          const SizedBox(height: 2),
          _buildRow(
            [
              PivotPreset.centerLeft,
              PivotPreset.center,
              PivotPreset.centerRight,
            ],
            buttonSize,
          ),
          const SizedBox(height: 2),
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
      children: presets.map((preset) {
        final isSelected = selectedPreset == preset;
        return Padding(
          padding: EdgeInsets.only(left: preset != presets.first ? 2 : 0),
          child: _PivotButton(
            preset: preset,
            isSelected: isSelected,
            size: buttonSize,
            onTap: () => onPresetSelected(preset),
          ),
        );
      }).toList(),
    );
  }
}

class _PivotButton extends StatefulWidget {
  final PivotPreset preset;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;

  const _PivotButton({
    required this.preset,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  @override
  State<_PivotButton> createState() => _PivotButtonState();
}

class _PivotButtonState extends State<_PivotButton> {
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

/// Compact pivot selector with label
class LabeledPivotSelector extends StatelessWidget {
  final String label;
  final PivotPreset? selectedPreset;
  final ValueChanged<PivotPreset> onPresetSelected;

  const LabeledPivotSelector({
    super.key,
    this.label = 'Pivot',
    this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: EditorColors.iconDefault,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        PivotSelector(
          selectedPreset: selectedPreset,
          onPresetSelected: onPresetSelected,
        ),
      ],
    );
  }
}
