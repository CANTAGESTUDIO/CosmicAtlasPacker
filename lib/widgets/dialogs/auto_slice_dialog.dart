import 'dart:ui' show Color;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../services/auto_slicer_service.dart';
import '../../services/background_remover_service.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';

/// Result from auto slice dialog including processed image
class AutoSliceDialogResult {
  final AutoSliceResult sliceResult;
  final img.Image? processedImage; // null if no background removal
  final AutoSliceConfig config; // Config used for slicing
  final bool removeBackground; // Whether background was removed
  final int? bgColorTolerance; // Background color tolerance (if removed)

  const AutoSliceDialogResult({
    required this.sliceResult,
    required this.config,
    this.processedImage,
    this.removeBackground = false,
    this.bgColorTolerance,
  });
}

/// Dialog for configuring auto slicing
class AutoSliceDialog extends StatefulWidget {
  /// Source image for processing
  final img.Image image;

  const AutoSliceDialog({
    super.key,
    required this.image,
  });

  /// Show auto slice dialog and return result if confirmed
  static Future<AutoSliceDialogResult?> show(
    BuildContext context, {
    required img.Image image,
  }) async {
    return showDialog<AutoSliceDialogResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => AutoSliceDialog(image: image),
    );
  }

  @override
  State<AutoSliceDialog> createState() => _AutoSliceDialogState();
}

/// Preset configuration for quick settings
class _AutoSlicePreset {
  final String name;
  final String description;
  final int alphaThreshold;
  final int minWidth;
  final int minHeight;
  final bool use8Direction;

  const _AutoSlicePreset({
    required this.name,
    required this.description,
    required this.alphaThreshold,
    required this.minWidth,
    required this.minHeight,
    required this.use8Direction,
  });
}

class _AutoSliceDialogState extends State<AutoSliceDialog> {
  int _alphaThreshold = 1;
  int _minWidth = 4;
  int _minHeight = 4;
  String _idPrefix = 'sprite';
  bool _use8Direction = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressMessage = '';
  int? _previewCount;
  String? _errorMessage;

  // Background removal settings
  bool _removeBackground = true;
  int _bgColorIndex = 0;
  int _bgTolerance = 0;
  late List<Color> _cornerColors;
  final _bgRemoverService = const BackgroundRemoverService();

  Color? get _backgroundColor =>
      _cornerColors.isNotEmpty ? _cornerColors[_bgColorIndex] : null;

  final _slicerService = const AutoSlicerService();

  // Processed image cache (after background removal)
  img.Image? _processedImage;

  // Preset definitions
  static final List<_AutoSlicePreset> _presets = [
    const _AutoSlicePreset(
      name: 'Pixel Art',
      description: '1×1 최소 크기',
      alphaThreshold: 1,
      minWidth: 1,
      minHeight: 1,
      use8Direction: false,
    ),
    const _AutoSlicePreset(
      name: 'Standard',
      description: '4×4 최소 크기',
      alphaThreshold: 1,
      minWidth: 4,
      minHeight: 4,
      use8Direction: false,
    ),
    const _AutoSlicePreset(
      name: 'High Detail',
      description: '8×8 최소, 8방향',
      alphaThreshold: 128,
      minWidth: 8,
      minHeight: 8,
      use8Direction: true,
    ),
  ];

  int _selectedPresetIndex = 1; // Standard by default

  @override
  void initState() {
    super.initState();
    _cornerColors = _bgRemoverService.getCornerColors(widget.image);
    // Auto-detect background color and find its index
    final detected = _bgRemoverService.detectBackgroundColor(widget.image);
    if (detected != null && _cornerColors.isNotEmpty) {
      final index = _cornerColors.indexWhere((c) =>
          c.red == detected.red &&
          c.green == detected.green &&
          c.blue == detected.blue);
      if (index >= 0) {
        _bgColorIndex = index;
      }
    }
    _updatePreview();
  }

  AutoSliceConfig _buildConfig() {
    return AutoSliceConfig(
      alphaThreshold: _alphaThreshold,
      minWidth: _minWidth,
      minHeight: _minHeight,
      idPrefix: _idPrefix.isEmpty ? 'sprite' : _idPrefix,
      use8Direction: _use8Direction,
    );
  }

  Future<img.Image> _getProcessedImage() async {
    if (!_removeBackground || _backgroundColor == null) {
      return widget.image;
    }

    // Use cached processed image if available
    if (_processedImage != null) {
      return _processedImage!;
    }

    // Remove background
    final result = await _bgRemoverService.removeBackground(
      image: widget.image,
      config: BackgroundRemoveConfig(
        targetColor: _backgroundColor!,
        tolerance: _bgTolerance,
        contiguousOnly: true,
      ),
    );

    _processedImage = result.image;
    return result.image;
  }

  void _invalidateProcessedImage() {
    _processedImage = null;
  }

  Future<void> _updatePreview() async {
    final config = _buildConfig();
    try {
      final imageToUse = await _getProcessedImage();
      final count = await _slicerService.previewRegionCount(
        image: imageToUse,
        config: config,
      );
      if (mounted) {
        setState(() => _previewCount = count);
      }
    } catch (e) {
      // Ignore preview errors
    }
  }

  void _applyPreset(int index) {
    final preset = _presets[index];
    setState(() {
      _selectedPresetIndex = index;
      _alphaThreshold = preset.alphaThreshold;
      _minWidth = preset.minWidth;
      _minHeight = preset.minHeight;
      _use8Direction = preset.use8Direction;
    });
    _updatePreview();
  }

  Future<void> _performSlicing() async {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _progressMessage = _removeBackground ? '배경 제거 중...' : '시작 중...';
      _errorMessage = null;
    });

    try {
      final imageToUse = await _getProcessedImage();

      if (mounted) {
        setState(() {
          _progress = 0.1;
          _progressMessage = '스프라이트 감지 중...';
        });
      }

      final result = await _slicerService.autoSlice(
        image: imageToUse,
        config: _buildConfig(),
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _progress = 0.1 + progress * 0.9;
              _progressMessage = message;
            });
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(AutoSliceDialogResult(
          sliceResult: result,
          config: _buildConfig(),
          processedImage: _removeBackground ? _processedImage : null,
          removeBackground: _removeBackground,
          bgColorTolerance: _removeBackground ? _bgTolerance : null,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '처리 실패: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): _ApplyIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ApplyIntent: CallbackAction<_ApplyIntent>(
            onInvoke: (_) {
              if (!_isProcessing && _previewCount != null && _previewCount! > 0) {
                _performSlicing();
              }
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) => Navigator.of(context).pop(),
          ),
        },
        child: DraggableDialog(
          header: _buildHeader(),
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current settings display
                      _buildCurrentSettingsSection(),
                      const SizedBox(height: 20),

                      // Quick presets
                      _buildPresetsSection(),
                      const SizedBox(height: 20),

                      // Alpha threshold
                      _buildThresholdSection(),
                      const SizedBox(height: 20),

                      // Minimum size
                      _buildMinSizeSection(),
                      const SizedBox(height: 20),

                      // Connectivity mode
                      _buildConnectivitySection(),
                      const SizedBox(height: 20),

                      // Background removal
                      _buildBackgroundRemovalSection(),
                      const SizedBox(height: 20),

                      // Advanced options
                      _buildAdvancedOptionsSection(),

                      // Progress
                      if (_isProcessing) ...[
                        const SizedBox(height: 20),
                        _buildProgressSection(),
                      ],

                      // Error message
                      if (_errorMessage != null && !_isProcessing) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: EditorColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          const Text(
            '오토 슬라이스',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.image.width} × ${widget.image.height}',
            style: const TextStyle(
              fontSize: 13,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSettingsSection() {
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome,
          size: 16,
          color: EditorColors.primary,
        ),
        const SizedBox(width: 8),
        const Text(
          '예상 스프라이트 수',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: EditorColors.iconDefault,
          ),
        ),
        const Spacer(),
        if (_previewCount != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _previewCount == 0
                  ? EditorColors.warning.withValues(alpha: 0.15)
                  : EditorColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _previewCount == 0 ? '감지 안됨' : '$_previewCount 개',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: _previewCount == 0 ? EditorColors.warning : EditorColors.primary,
              ),
            ),
          )
        else
          const Text(
            '계산 중...',
            style: TextStyle(
              fontSize: 13,
              color: EditorColors.iconDisabled,
            ),
          ),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '빠른 프리셋'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < _presets.length; i++) ...[
              Expanded(
                child: _PresetButton(
                  name: _presets[i].name,
                  description: _presets[i].description,
                  isSelected: _selectedPresetIndex == i,
                  onTap: () => _applyPreset(i),
                ),
              ),
              if (i < _presets.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildThresholdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionHeader(title: '알파 임계값'),
            const Spacer(),
            Text(
              '$_alphaThreshold',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: EditorColors.iconDefault,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: _sliderTheme(context),
          child: Slider(
            value: _alphaThreshold.toDouble(),
            min: 0,
            max: 255,
            divisions: 51,
            onChanged: (value) {
              setState(() => _alphaThreshold = value.round());
              _updatePreview();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMinSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '최소 스프라이트 크기'),
        const SizedBox(height: 14),
        _SliderRow(
          label: '최소 너비',
          value: _minWidth,
          suffix: 'px',
          min: 1,
          max: 64,
          onChanged: (value) {
            setState(() => _minWidth = value);
            _updatePreview();
          },
        ),
        const SizedBox(height: 14),
        _SliderRow(
          label: '최소 높이',
          value: _minHeight,
          suffix: 'px',
          min: 1,
          max: 64,
          onChanged: (value) {
            setState(() => _minHeight = value);
            _updatePreview();
          },
        ),
      ],
    );
  }

  Widget _buildConnectivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '픽셀 연결 모드'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OptionButton(
                label: '4방향',
                isSelected: !_use8Direction,
                onTap: () {
                  setState(() => _use8Direction = false);
                  _updatePreview();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OptionButton(
                label: '8방향',
                isSelected: _use8Direction,
                onTap: () {
                  setState(() => _use8Direction = true);
                  _updatePreview();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundRemovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '배경색 제거'),
        const SizedBox(height: 14),
        _ToggleRow(
          label: '배경색 자동 제거',
          value: _removeBackground,
          onChanged: (value) {
            setState(() {
              _removeBackground = value;
              _invalidateProcessedImage();
            });
            _updatePreview();
          },
        ),
        if (_removeBackground) ...[
          const SizedBox(height: 14),
          // Color selection
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  '배경색',
                  style: TextStyle(fontSize: 13, color: EditorColors.iconDefault),
                ),
              ),
              for (int i = 0; i < _cornerColors.length; i++) ...[
                _ColorToggleButton(
                  color: _cornerColors[i],
                  isSelected: _bgColorIndex == i,
                  onTap: () {
                    setState(() {
                      _bgColorIndex = i;
                      _invalidateProcessedImage();
                    });
                    _updatePreview();
                  },
                ),
                if (i < _cornerColors.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Tolerance slider
          _SliderRow(
            label: '허용 오차',
            value: _bgTolerance,
            min: 0,
            max: 50,
            onChanged: (value) {
              setState(() {
                _bgTolerance = value;
                _invalidateProcessedImage();
              });
              _updatePreview();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'ID 접두사'),
        const SizedBox(height: 10),
        _EditorTextField(
          initialValue: _idPrefix,
          hintText: 'sprite',
          onChanged: (value) {
            _idPrefix = value;
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: EditorColors.border,
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${(_progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: EditorColors.iconDefault,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _progressMessage,
          style: const TextStyle(
            fontSize: 13,
            color: EditorColors.iconDisabled,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(0, 38),
              textStyle: const TextStyle(fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('취소'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _isProcessing || _previewCount == null || _previewCount == 0
                ? null
                : _performSlicing,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(0, 38),
              textStyle: const TextStyle(fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('적용'),
          ),
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      trackHeight: 2,
      activeTrackColor: EditorColors.primary,
      inactiveTrackColor: EditorColors.border,
      thumbColor: EditorColors.primary,
    );
  }
}

// ============================================================================
// Intent classes for keyboard shortcuts
// ============================================================================

class _ApplyIntent extends Intent {
  const _ApplyIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}

// ============================================================================
// Compact Widgets (Design System Compliant - matching background_remove_dialog)
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        color: EditorColors.iconDefault,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String name;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.name,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? EditorColors.primary.withValues(alpha: 0.15)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? EditorColors.primary : EditorColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? EditorColors.primary.withValues(alpha: 0.8)
                    : EditorColors.iconDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? EditorColors.primary.withValues(alpha: 0.15)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? EditorColors.primary : EditorColors.iconDisabled,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final String? suffix;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: EditorColors.iconDefault),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 2,
              activeTrackColor: EditorColors.primary,
              inactiveTrackColor: EditorColors.border,
              thumbColor: EditorColors.primary,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            suffix != null ? '$value$suffix' : '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: EditorColors.iconDisabled,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: EditorColors.iconDefault),
          ),
        ),
        SizedBox(
          width: 36,
          height: 24,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerRight,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: EditorColors.primary,
              activeTrackColor: EditorColors.primary.withValues(alpha: 0.5),
              inactiveThumbColor: EditorColors.iconDisabled,
              inactiveTrackColor: EditorColors.border,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashRadius: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorToggleButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorToggleButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? EditorColors.primary.withValues(alpha: 0.15)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isSelected ? EditorColors.primary : EditorColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Editor TextField - Design System Compliant
/// Prevents keyboard shortcut conflicts with Focus wrapper
class _EditorTextField extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final bool hasError;

  const _EditorTextField({
    this.initialValue,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.keyboardType,
    this.hasError = false,
  });

  @override
  State<_EditorTextField> createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends State<_EditorTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Prevent keyboard shortcuts from intercepting input
      onKeyEvent: (node, event) => KeyEventResult.skipRemainingHandlers,
      child: TextField(
        controller: _controller,
        style: const TextStyle(
          fontSize: 13,
          color: EditorColors.iconDefault,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          filled: true,
          fillColor: EditorColors.inputBackground,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: EditorColors.iconDisabled.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: widget.hasError ? EditorColors.error : EditorColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: widget.hasError ? EditorColors.error : EditorColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: widget.hasError ? EditorColors.error : EditorColors.primary,
            ),
          ),
        ),
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
