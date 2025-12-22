import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../services/background_remover_service.dart';
import '../../theme/editor_colors.dart';

/// Dialog for configuring background removal
class BackgroundRemoveDialog extends StatefulWidget {
  /// Source image for processing
  final img.Image image;

  const BackgroundRemoveDialog({
    super.key,
    required this.image,
  });

  /// Show background removal dialog and return processed image if confirmed
  static Future<img.Image?> show(
    BuildContext context, {
    required img.Image image,
  }) async {
    return showDialog<img.Image>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackgroundRemoveDialog(image: image),
    );
  }

  @override
  State<BackgroundRemoveDialog> createState() => _BackgroundRemoveDialogState();
}

class _BackgroundRemoveDialogState extends State<BackgroundRemoveDialog> {
  final _toleranceController = TextEditingController(text: '0');
  final _service = const BackgroundRemoverService();

  int _selectedColorIndex = 0; // Index-based selection
  late List<Color> _cornerColors;
  bool _contiguousOnly = true;
  bool _isProcessing = false;
  String? _errorMessage;

  Color? get _selectedColor =>
      _cornerColors.isNotEmpty ? _cornerColors[_selectedColorIndex] : null;

  @override
  void initState() {
    super.initState();
    _cornerColors = _service.getCornerColors(widget.image);
    // Auto-detect background color and find its index
    final detected = _service.detectBackgroundColor(widget.image);
    if (detected != null) {
      final index = _cornerColors.indexWhere((c) => _colorsEqual(c, detected));
      if (index >= 0) {
        _selectedColorIndex = index;
      }
    }
  }

  bool _colorsEqual(Color a, Color b) {
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
  }

  @override
  void dispose() {
    _toleranceController.dispose();
    super.dispose();
  }

  Future<void> _applyRemoval() async {
    if (_selectedColor == null) {
      setState(() => _errorMessage = '배경색을 선택해주세요');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.removeBackground(
        image: widget.image,
        config: BackgroundRemoveConfig(
          targetColor: _selectedColor!,
          tolerance: int.tryParse(_toleranceController.text) ?? 0,
          contiguousOnly: _contiguousOnly,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(result.image);
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
    return AlertDialog(
      title: const Text('배경색 제거'),
      backgroundColor: EditorColors.surface,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image info
            Text(
              'Image: ${widget.image.width} × ${widget.image.height} px',
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled,
              ),
            ),
            const SizedBox(height: 16),

            // Color selection
            _buildColorSection(),
            const SizedBox(height: 16),

            // Tolerance
            _buildToleranceSection(),
            const SizedBox(height: 16),

            // Mode selection
            _buildModeSection(),
            const SizedBox(height: 16),

            // Preview
            _buildPreviewSection(),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: EditorColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isProcessing || _selectedColor == null ? null : _applyRemoval,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('적용'),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    final hasMultipleColors = _cornerColors.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasMultipleColors ? '배경색 선택' : '감지된 배경색',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          hasMultipleColors
              ? '제거할 배경색을 선택하세요. 이미지 코너에서 감지된 색상입니다.'
              : '이미지 코너에서 배경색이 자동 감지되었습니다.',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Show color selection only if multiple unique colors detected
            if (hasMultipleColors)
              for (int i = 0; i < _cornerColors.length; i++)
                _ColorButton(
                  color: _cornerColors[i],
                  isSelected: _selectedColorIndex == i,
                  onTap: () => setState(() => _selectedColorIndex = i),
                ),
            if (hasMultipleColors) const SizedBox(width: 8),
            // Selected color display
            if (_selectedColor != null) ...[
              if (hasMultipleColors)
                Container(
                  width: 1,
                  height: 32,
                  color: EditorColors.divider,
                ),
              if (hasMultipleColors) const SizedBox(width: 8),
              _ColorDisplay(color: _selectedColor!),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildToleranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '허용 오차 (Tolerance)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          '비슷한 색상도 함께 제거합니다. 0 = 정확히 일치하는 색상만 제거',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: _toleranceController,
                decoration: const InputDecoration(
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RangeInputFormatter(0, 255),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Slider(
                value: (int.tryParse(_toleranceController.text) ?? 0)
                    .toDouble()
                    .clamp(0, 255),
                min: 0,
                max: 255,
                divisions: 51,
                onChanged: (value) {
                  _toleranceController.text = value.round().toString();
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '제거 모드',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: '가장자리만',
                description: '이미지 가장자리에서 연결된 배경만 제거',
                isSelected: _contiguousOnly,
                onTap: () => setState(() => _contiguousOnly = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeButton(
                label: '모든 일치 색상',
                description: '이미지 전체에서 일치하는 모든 색상 제거',
                isSelected: !_contiguousOnly,
                onTap: () => setState(() => _contiguousOnly = false),
              ),
            ),
          ],
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
            Icons.format_color_reset,
            size: 20,
            color: EditorColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '배경 제거 미리보기',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedColor != null
                      ? 'RGB(${_selectedColor!.red.toInt()}, ${_selectedColor!.green.toInt()}, ${_selectedColor!.blue.toInt()}) 색상이 투명하게 변환됩니다'
                      : '배경색을 선택해주세요',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? EditorColors.primary : EditorColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EditorColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 16,
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

class _ColorDisplay extends StatelessWidget {
  final Color color;

  const _ColorDisplay({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: EditorColors.border),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'RGB(${color.red.toInt()}, ${color.green.toInt()}, ${color.blue.toInt()})',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
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
        padding: const EdgeInsets.all(10),
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
                  size: 14,
                  color: isSelected ? EditorColors.primary : EditorColors.iconDisabled,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 10,
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

class _RangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value < min || value > max) {
      return oldValue;
    }
    return newValue;
  }
}
