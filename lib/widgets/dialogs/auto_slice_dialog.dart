import 'dart:ui' show Color;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../services/auto_slicer_service.dart';
import '../../services/background_remover_service.dart';
import '../../theme/editor_colors.dart';

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
      builder: (context) => AutoSliceDialog(image: image),
    );
  }

  @override
  State<AutoSliceDialog> createState() => _AutoSliceDialogState();
}

/// Preset configuration for quick settings
class _AutoSlicePreset {
  final String name;
  final int alphaThreshold;
  final int minWidth;
  final int minHeight;
  final bool use8Direction;

  const _AutoSlicePreset({
    required this.name,
    required this.alphaThreshold,
    required this.minWidth,
    required this.minHeight,
    required this.use8Direction,
  });
}

class _AutoSliceDialogState extends State<AutoSliceDialog> {
  final _thresholdController = TextEditingController(text: '1');
  final _minWidthController = TextEditingController(text: '4');
  final _minHeightController = TextEditingController(text: '4');
  final _prefixController = TextEditingController(text: 'sprite');
  final _toleranceController = TextEditingController(text: '0');

  bool _use8Direction = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressMessage = '';
  int? _previewCount;
  String? _validationError;

  // Background removal settings
  bool _removeBackground = false;
  int _bgColorIndex = 0;
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
      alphaThreshold: 1,
      minWidth: 1,
      minHeight: 1,
      use8Direction: false,
    ),
    const _AutoSlicePreset(
      name: 'Standard',
      alphaThreshold: 1,
      minWidth: 4,
      minHeight: 4,
      use8Direction: false,
    ),
    const _AutoSlicePreset(
      name: 'High Detail',
      alphaThreshold: 128,
      minWidth: 8,
      minHeight: 8,
      use8Direction: true,
    ),
  ];

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

  @override
  void dispose() {
    _thresholdController.dispose();
    _minWidthController.dispose();
    _minHeightController.dispose();
    _prefixController.dispose();
    _toleranceController.dispose();
    super.dispose();
  }

  AutoSliceConfig _buildConfig() {
    return AutoSliceConfig(
      alphaThreshold: int.tryParse(_thresholdController.text) ?? 1,
      minWidth: int.tryParse(_minWidthController.text) ?? 4,
      minHeight: int.tryParse(_minHeightController.text) ?? 4,
      idPrefix: _prefixController.text.isEmpty ? 'sprite' : _prefixController.text,
      use8Direction: _use8Direction,
    );
  }

  void _validate() {
    final threshold = int.tryParse(_thresholdController.text);
    final minWidth = int.tryParse(_minWidthController.text);
    final minHeight = int.tryParse(_minHeightController.text);

    setState(() {
      if (threshold == null || threshold < 0 || threshold > 255) {
        _validationError = 'Alpha threshold must be 0-255';
      } else if (minWidth == null || minWidth < 1) {
        _validationError = 'Minimum width must be at least 1';
      } else if (minHeight == null || minHeight < 1) {
        _validationError = 'Minimum height must be at least 1';
      } else {
        _validationError = null;
      }
    });
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
        tolerance: int.tryParse(_toleranceController.text) ?? 0,
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
    if (_validationError != null) return;

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

  void _applyPreset(_AutoSlicePreset preset) {
    setState(() {
      _thresholdController.text = preset.alphaThreshold.toString();
      _minWidthController.text = preset.minWidth.toString();
      _minHeightController.text = preset.minHeight.toString();
      _use8Direction = preset.use8Direction;
    });
    _validate();
    _updatePreview();
  }

  Future<void> _performSlicing() async {
    if (_validationError != null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _progressMessage = _removeBackground ? '배경 제거 중...' : 'Starting...';
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
              // Adjust progress to account for background removal phase
              _progress = 0.1 + progress * 0.9;
              _progressMessage = message;
            });
          }
        },
      );

      if (mounted) {
        final config = _buildConfig();
        final tolerance = int.tryParse(_toleranceController.text) ?? 0;
        Navigator.of(context).pop(AutoSliceDialogResult(
          sliceResult: result,
          config: config,
          processedImage: _removeBackground ? _processedImage : null,
          removeBackground: _removeBackground,
          bgColorTolerance: _removeBackground ? tolerance : null,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _validationError = 'Processing failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor: EditorColors.surface,
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick presets
                    _buildPresetsSection(),
                    const SizedBox(height: 16),

                    // Background removal option
                    _buildBackgroundRemovalSection(),
                    const SizedBox(height: 16),

                    // Alpha threshold
                    _buildThresholdSection(),
                    const SizedBox(height: 16),

                    // Minimum size
                    _buildMinSizeSection(),
                    const SizedBox(height: 16),

                    // Connectivity
                    _buildConnectivitySection(),
                    const SizedBox(height: 16),

                    // ID prefix
                    _buildPrefixSection(),
                    const SizedBox(height: 16),

                    // Preview
                    _buildPreviewSection(),

                    // Progress
                    if (_isProcessing) ...[
                      const SizedBox(height: 16),
                      _buildProgressSection(),
                    ],

                    // Validation error
                    if (_validationError != null && !_isProcessing) ...[
                      const SizedBox(height: 12),
                      Text(
                        _validationError!,
                        style: const TextStyle(
                          color: EditorColors.error,
                          fontSize: 11,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          const Text(
            'Auto Slice',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.image.width} × ${widget.image.height}',
            style: const TextStyle(
              fontSize: 11,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isProcessing || _validationError != null || _previewCount == 0
                ? null
                : _performSlicing,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_previewCount != null
                    ? 'Apply ($_previewCount sprites)'
                    : 'Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Quick Presets'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < _presets.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => _applyPreset(_presets[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: EditorColors.inputBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: EditorColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _presets[i].name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_presets[i].minWidth}×${_presets[i].minHeight}',
                          style: TextStyle(
                            fontSize: 11,
                            color: EditorColors.iconDisabled,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < _presets.length - 1) const SizedBox(width: 8),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundRemovalSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _removeBackground
            ? EditorColors.primary.withValues(alpha: 0.1)
            : EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _removeBackground ? EditorColors.primary : EditorColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _removeBackground,
                onChanged: (value) {
                  setState(() {
                    _removeBackground = value ?? false;
                    _invalidateProcessedImage();
                  });
                  _updatePreview();
                },
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  '배경색 자동 제거',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (_removeBackground) ...[
            const SizedBox(height: 8),
            Text(
              '배경색을 투명으로 변환한 후 스프라이트를 감지합니다',
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _cornerColors.length > 1 ? '배경색 선택: ' : '감지된 배경색: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
                // Show color selection only if multiple unique colors detected
                if (_cornerColors.length > 1)
                  for (int i = 0; i < _cornerColors.length; i++)
                    _ColorButton(
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
                if (_backgroundColor != null) ...[
                  // Show color swatch when only one color
                  if (_cornerColors.length == 1)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: EditorColors.border),
                      ),
                    ),
                  if (_cornerColors.length > 1) const SizedBox(width: 8),
                  Text(
                    'RGB(${_backgroundColor!.red.toInt()}, ${_backgroundColor!.green.toInt()}, ${_backgroundColor!.blue.toInt()})',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '허용 오차: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _toleranceController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {
                      _invalidateProcessedImage();
                      _updatePreview();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThresholdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Alpha Threshold'),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: _thresholdController,
                decoration: const InputDecoration(
                  isDense: true,
                  suffixText: '/ 255',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RangeTextInputFormatter(0, 255),
                ],
                onChanged: (_) {
                  _validate();
                  _updatePreview();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Slider(
                value: (int.tryParse(_thresholdController.text) ?? 1).toDouble().clamp(0, 255),
                min: 0,
                max: 255,
                divisions: 255,
                onChanged: (value) {
                  _thresholdController.text = value.round().toString();
                  _validate();
                  _updatePreview();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Minimum Sprite Size'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Width',
                controller: _minWidthController,
                suffix: 'px',
                onChanged: (_) {
                  _validate();
                  _updatePreview();
                },
              ),
            ),
            const SizedBox(width: 16),
            const Text('x'),
            const SizedBox(width: 16),
            Expanded(
              child: _NumberField(
                label: 'Height',
                controller: _minHeightController,
                suffix: 'px',
                onChanged: (_) {
                  _validate();
                  _updatePreview();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Pixel Connectivity'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ConnectivityButton(
                label: '4-Direction',
                description: 'Up, Down, Left, Right',
                isSelected: !_use8Direction,
                onTap: () {
                  setState(() => _use8Direction = false);
                  _updatePreview();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ConnectivityButton(
                label: '8-Direction',
                description: 'Including diagonals',
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

  Widget _buildPrefixSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'ID Prefix'),
        const SizedBox(height: 8),
        TextField(
          controller: _prefixController,
          decoration: const InputDecoration(
            hintText: 'sprite',
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 20,
            color: EditorColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detected Regions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _previewCount != null
                      ? _previewCount == 0
                          ? 'No regions detected'
                          : '$_previewCount sprites will be created'
                      : 'Calculating...',
                  style: TextStyle(
                    fontSize: 11,
                    color: _previewCount == 0 ? EditorColors.warning : EditorColors.iconDisabled,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_previewCount == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: EditorColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⚠ No regions',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: EditorColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: EditorColors.border,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(_progress * 100).round()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _progressMessage,
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? suffix;
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ConnectivityButton extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConnectivityButton({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? EditorColors.primary.withValues(alpha: 0.2)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? EditorColors.primary : EditorColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    fontWeight: FontWeight.w500,
                    color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? EditorColors.primary : EditorColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 14,
                color: _contrastColor(color),
              )
            : null,
      ),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Input formatter that limits values to a range
class _RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}

// ============================================================================
// Section Header Widget
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        color: EditorColors.iconDefault,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
