import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/atlas_settings.dart';
import '../../providers/packing_provider.dart';
import '../../theme/editor_colors.dart';

/// Dialog for configuring atlas packing settings
class AtlasSettingsDialog extends ConsumerStatefulWidget {
  const AtlasSettingsDialog({super.key});

  /// Show atlas settings dialog
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => const AtlasSettingsDialog(),
    );
  }

  @override
  ConsumerState<AtlasSettingsDialog> createState() =>
      _AtlasSettingsDialogState();
}

class _AtlasSettingsDialogState extends ConsumerState<AtlasSettingsDialog> {
  late TextEditingController _maxWidthController;
  late TextEditingController _maxHeightController;
  late TextEditingController _paddingController;
  late TextEditingController _extrudeController;
  late bool _powerOfTwo;
  late bool _trimTransparent;
  late bool _forceSquare;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(atlasSettingsProvider);
    _maxWidthController =
        TextEditingController(text: settings.maxWidth.toString());
    _maxHeightController =
        TextEditingController(text: settings.maxHeight.toString());
    _paddingController =
        TextEditingController(text: settings.padding.toString());
    _extrudeController =
        TextEditingController(text: settings.extrude.toString());
    _powerOfTwo = settings.powerOfTwo;
    _trimTransparent = settings.trimTransparent;
    _forceSquare = settings.forceSquare;
  }

  @override
  void dispose() {
    _maxWidthController.dispose();
    _maxHeightController.dispose();
    _paddingController.dispose();
    _extrudeController.dispose();
    super.dispose();
  }

  AtlasSettings _buildSettings() {
    return AtlasSettings(
      maxWidth: int.tryParse(_maxWidthController.text) ?? 2048,
      maxHeight: int.tryParse(_maxHeightController.text) ?? 2048,
      padding: int.tryParse(_paddingController.text) ?? 2,
      extrude: int.tryParse(_extrudeController.text) ?? 1,
      powerOfTwo: _powerOfTwo,
      trimTransparent: _trimTransparent,
      forceSquare: _forceSquare,
    );
  }

  void _validate() {
    final maxWidth = int.tryParse(_maxWidthController.text);
    final maxHeight = int.tryParse(_maxHeightController.text);
    final padding = int.tryParse(_paddingController.text);
    final extrude = int.tryParse(_extrudeController.text);

    setState(() {
      if (maxWidth == null || maxWidth < 64 || maxWidth > 8192) {
        _validationError = 'Max Width must be between 64 and 8192';
      } else if (maxHeight == null || maxHeight < 64 || maxHeight > 8192) {
        _validationError = 'Max Height must be between 64 and 8192';
      } else if (padding == null || padding < 0 || padding > 32) {
        _validationError = 'Padding must be between 0 and 32';
      } else if (extrude == null || extrude < 0 || extrude > 16) {
        _validationError = 'Extrude must be between 0 and 16';
      } else {
        _validationError = null;
      }
    });
  }

  void _applySettings() {
    if (_validationError != null) return;

    final settings = _buildSettings();
    ref.read(atlasSettingsProvider.notifier).updateSettings(settings);
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      _maxWidthController.text = '2048';
      _maxHeightController.text = '2048';
      _paddingController.text = '2';
      _extrudeController.text = '1';
      _powerOfTwo = true;
      _trimTransparent = true;
      _forceSquare = false;
      _validationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atlas Settings'),
      backgroundColor: EditorColors.surface,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Size settings
            _buildSectionHeader('Atlas Size'),
            const SizedBox(height: 8),
            _buildSizeInputs(),
            const SizedBox(height: 20),

            // Spacing settings
            _buildSectionHeader('Spacing'),
            const SizedBox(height: 8),
            _buildSpacingInputs(),
            const SizedBox(height: 20),

            // Options
            _buildSectionHeader('Options'),
            const SizedBox(height: 8),
            _buildOptionSwitches(),

            // Validation error
            if (_validationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EditorColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: EditorColors.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: EditorColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(
                          color: EditorColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetToDefaults,
          child: const Text('Reset'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _validationError == null ? _applySettings : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: EditorColors.primary,
      ),
    );
  }

  Widget _buildSizeInputs() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            label: 'Max Width',
            controller: _maxWidthController,
            suffix: 'px',
            hint: '64 - 8192',
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 16),
        const Text('×', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 16),
        Expanded(
          child: _NumberField(
            label: 'Max Height',
            controller: _maxHeightController,
            suffix: 'px',
            hint: '64 - 8192',
            onChanged: (_) => _validate(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpacingInputs() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            label: 'Padding',
            controller: _paddingController,
            suffix: 'px',
            hint: '0 - 32',
            tooltip: 'Space between sprites',
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _NumberField(
            label: 'Extrude',
            controller: _extrudeController,
            suffix: 'px',
            hint: '0 - 16',
            tooltip: 'Edge extrusion to prevent bleeding',
            onChanged: (_) => _validate(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionSwitches() {
    return Column(
      children: [
        _OptionSwitch(
          label: 'Power of Two',
          description: 'Force atlas size to be power of 2 (256, 512, 1024...)',
          value: _powerOfTwo,
          onChanged: (value) {
            setState(() => _powerOfTwo = value);
          },
        ),
        const SizedBox(height: 8),
        _OptionSwitch(
          label: 'Trim Transparent',
          description: 'Remove transparent pixels from sprite edges',
          value: _trimTransparent,
          onChanged: (value) {
            setState(() => _trimTransparent = value);
          },
        ),
        const SizedBox(height: 8),
        _OptionSwitch(
          label: 'Force Square',
          description: 'Force atlas to be square (width = height)',
          value: _forceSquare,
          onChanged: (value) {
            setState(() => _forceSquare = value);
          },
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? hint;
  final String? tooltip;
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    this.suffix,
    this.hint,
    this.tooltip,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip!,
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled.withValues(alpha: 0.5),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: onChanged,
        ),
      ],
    );

    return field;
  }
}

class _OptionSwitch extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionSwitch({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? EditorColors.primary.withValues(alpha: 0.1)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? EditorColors.primary : EditorColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          value ? EditorColors.primary : EditorColors.iconDefault,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: EditorColors.iconDisabled,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
