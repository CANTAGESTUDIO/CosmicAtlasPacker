import 'dart:async';
import 'dart:typed_data';

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
  final _service = const BackgroundRemoverService();

  int _tolerance = 0;
  late List<Color> _cornerColors;
  Color? _selectedColor;
  bool _contiguousOnly = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // Edge options
  bool _antialias = false;
  int _featherRadius = 0;
  int _alphaThreshold = 10;

  @override
  void initState() {
    super.initState();
    _cornerColors = _service.getCornerColors(widget.image);
    // Auto-detect background color
    _selectedColor = _service.detectBackgroundColor(widget.image);
  }

  @override
  void dispose() {
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
          tolerance: _tolerance,
          contiguousOnly: _contiguousOnly,
          featherRadius: _featherRadius,
          antialias: _antialias,
          alphaThreshold: _alphaThreshold,
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

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().clamp(0, 255);
    final g = (color.g * 255).round().clamp(0, 255);
    final b = (color.b * 255).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
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
              if (!_isProcessing && _selectedColor != null) {
                _applyRemoval();
              }
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) => Navigator.of(context).pop(),
          ),
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          backgroundColor: EditorColors.surface,
          child: SizedBox(
            width: 380,
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
                        // Color selection with eyedropper button
                        _buildColorSection(),
                        const SizedBox(height: 16),

                        // Tolerance
                        _buildToleranceSection(),
                        const SizedBox(height: 16),

                        // Mode selection
                        _buildModeSection(),
                        const SizedBox(height: 16),

                        // Edge options
                        _buildEdgeOptionsSection(),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
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
            '배경색 제거',
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

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '감지된 코너 색상'),
        const SizedBox(height: 8),

        // Corner color buttons + eyedropper button + selected color info
        Row(
          children: [
            for (int i = 0; i < _cornerColors.length; i++) ...[
              _ColorButton(
                color: _cornerColors[i],
                isSelected: _selectedColor != null &&
                    _colorsEqual(_selectedColor!, _cornerColors[i]),
                onTap: () => setState(() => _selectedColor = _cornerColors[i]),
              ),
              if (i < _cornerColors.length - 1) const SizedBox(width: 6),
            ],
            const SizedBox(width: 8),
            // Eyedropper button
            _EyedropperButton(
              onTap: _showColorPickerDialog,
            ),
            const Spacer(),
            // Selected color info
            if (_selectedColor != null)
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: EditorColors.border),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _colorToHex(_selectedColor!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: EditorColors.iconDisabled,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ColorPickerDialog(
        image: widget.image,
        initialColor: _selectedColor,
        onColorPicked: (color) {
          setState(() => _selectedColor = color);
        },
      ),
    );
  }

  bool _colorsEqual(Color a, Color b) {
    final ar = (a.r * 255).round();
    final ag = (a.g * 255).round();
    final ab = (a.b * 255).round();
    final br = (b.r * 255).round();
    final bg = (b.g * 255).round();
    final bb = (b.b * 255).round();
    return ar == br && ag == bg && ab == bb;
  }

  Widget _buildToleranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionHeader(title: '허용 오차'),
            const Spacer(),
            Text(
              '$_tolerance',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: EditorColors.iconDefault,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: _sliderTheme(context),
          child: Slider(
            value: _tolerance.toDouble(),
            min: 0,
            max: 255,
            divisions: 51,
            onChanged: (value) => setState(() => _tolerance = value.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '제거 모드'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _OptionButton(
                label: '가장자리만',
                isSelected: _contiguousOnly,
                onTap: () => setState(() => _contiguousOnly = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OptionButton(
                label: '모든 일치 색상',
                isSelected: !_contiguousOnly,
                onTap: () => setState(() => _contiguousOnly = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEdgeOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '가장자리 옵션'),
        const SizedBox(height: 12),

        // Feather radius slider
        _SliderRow(
          label: '가장자리 흐림',
          value: _featherRadius,
          suffix: 'px',
          min: 0,
          max: 50,
          onChanged: (value) => setState(() => _featherRadius = value),
        ),
        const SizedBox(height: 12),

        // Alpha threshold slider
        _SliderRow(
          label: '투명도 임계값',
          value: _alphaThreshold,
          min: 0,
          max: 50,
          onChanged: (value) => setState(() => _alphaThreshold = value),
        ),
        const SizedBox(height: 12),

        // Antialias toggle
        _ToggleRow(
          label: '안티앨리어싱',
          value: _antialias,
          onChanged: (value) => setState(() => _antialias = value),
        ),
      ],
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
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isProcessing || _selectedColor == null ? null : _applyRemoval,
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
                : const Text('적용'),
          ),
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      trackHeight: 2,
      activeTrackColor: EditorColors.primary,
      inactiveTrackColor: EditorColors.border,
      thumbColor: EditorColors.primary,
    );
  }
}

// ============================================================================
// Compact Widgets (Design System Compliant)
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? EditorColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 14,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              )
            : null,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              size: 14,
              color: isSelected ? EditorColors.primary : EditorColors.iconDisabled,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: EditorColors.iconDefault),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
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
          width: 36,
          child: Text(
            suffix != null ? '$value$suffix' : '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
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
            style: const TextStyle(fontSize: 11, color: EditorColors.iconDefault),
          ),
        ),
        SizedBox(
          height: 20,
          child: Transform.scale(
            scale: 0.65,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: EditorColors.primary,
              activeTrackColor: EditorColors.primary.withValues(alpha: 0.5),
              inactiveThumbColor: EditorColors.iconDisabled,
              inactiveTrackColor: EditorColors.border,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 8.0;
    final lightPaint = Paint()..color = const Color(0xFF3A3A3A);
    final darkPaint = Paint()..color = const Color(0xFF2A2A2A);

    for (var y = 0.0; y < size.height; y += squareSize) {
      for (var x = 0.0; x < size.width; x += squareSize) {
        final isDark = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isDark ? darkPaint : lightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ApplyIntent extends Intent {
  const _ApplyIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}

/// Eyedropper button widget
class _EyedropperButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EyedropperButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '이미지에서 색상 선택',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(
            Icons.colorize,
            size: 16,
            color: EditorColors.iconDefault,
          ),
        ),
      ),
    );
  }
}

/// Color picker dialog that shows the image for eyedropper selection
class _ColorPickerDialog extends StatefulWidget {
  final img.Image image;
  final Color? initialColor;
  final ValueChanged<Color> onColorPicked;

  const _ColorPickerDialog({
    required this.image,
    this.initialColor,
    required this.onColorPicked,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  Color? _pickedColor;
  int? _hoverPixelX;
  int? _hoverPixelY;
  late final Uint8List _imageBytes; // Cache encoded image to avoid flicker

  static const int _magnifierRadius = 5; // 11x11 pixel grid
  static const double _magnifierPixelSize = 16.0; // Size of each pixel in magnifier

  @override
  void initState() {
    super.initState();
    _pickedColor = widget.initialColor;
    _imageBytes = img.encodePng(widget.image);
  }

  void _updateHoverPosition(Offset localPosition, Size widgetSize) {
    final scaleX = widget.image.width / widgetSize.width;
    final scaleY = widget.image.height / widgetSize.height;

    final pixelX = (localPosition.dx * scaleX).round().clamp(0, widget.image.width - 1);
    final pixelY = (localPosition.dy * scaleY).round().clamp(0, widget.image.height - 1);

    setState(() {
      _hoverPixelX = pixelX;
      _hoverPixelY = pixelY;
    });
  }

  void _pickColorAtCurrentPosition() {
    if (_hoverPixelX == null || _hoverPixelY == null) return;

    final pixel = widget.image.getPixel(_hoverPixelX!, _hoverPixelY!);
    // image package returns values in 0-255 range
    final color = Color.fromARGB(
      255,
      pixel.r.toInt().clamp(0, 255),
      pixel.g.toInt().clamp(0, 255),
      pixel.b.toInt().clamp(0, 255),
    );

    setState(() => _pickedColor = color);
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().clamp(0, 255);
    final g = (color.g * 255).round().clamp(0, 255);
    final b = (color.b * 255).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor: EditorColors.surface,
      child: SizedBox(
        width: 850, // 2.5x larger
        height: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),

            // Main content: Image + Magnifier
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview (left side)
                    Expanded(
                      child: _buildImagePreview(),
                    ),
                    const SizedBox(width: 16),
                    // Magnifier panel (right side)
                    _buildMagnifierPanel(),
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
          const Icon(
            Icons.colorize,
            size: 16,
            color: EditorColors.iconDefault,
          ),
          const SizedBox(width: 8),
          const Text(
            '이미지에서 색상 선택',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          if (_pickedColor != null)
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _pickedColor,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: EditorColors.border),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _colorToHex(_pickedColor!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = widget.image.width / widget.image.height;
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        double width, height;
        if (maxWidth / maxHeight > aspectRatio) {
          height = maxHeight;
          width = height * aspectRatio;
        } else {
          width = maxWidth;
          height = width / aspectRatio;
        }

        return Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            onHover: (event) {
              _updateHoverPosition(event.localPosition, Size(width, height));
            },
            onExit: (_) {
              setState(() {
                _hoverPixelX = null;
                _hoverPixelY = null;
              });
            },
            child: GestureDetector(
              onTapDown: (details) {
                _updateHoverPosition(details.localPosition, Size(width, height));
                _pickColorAtCurrentPosition();
              },
              onPanStart: (details) {
                _updateHoverPosition(details.localPosition, Size(width, height));
                _pickColorAtCurrentPosition();
              },
              onPanUpdate: (details) {
                _updateHoverPosition(details.localPosition, Size(width, height));
                _pickColorAtCurrentPosition();
              },
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: EditorColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Checkerboard background
                      CustomPaint(painter: _CheckerboardPainter()),
                      // Image (use cached bytes to avoid flicker)
                      Image.memory(
                        _imageBytes,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMagnifierPanel() {
    final magnifierSize = (_magnifierRadius * 2 + 1) * _magnifierPixelSize;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            '돋보기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(height: 12),

          // Magnifier grid
          Center(
            child: Container(
              width: magnifierSize,
              height: magnifierSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: EditorColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: _hoverPixelX != null && _hoverPixelY != null
                    ? CustomPaint(
                        size: Size(magnifierSize, magnifierSize),
                        painter: _MagnifierPainter(
                          image: widget.image,
                          centerX: _hoverPixelX!,
                          centerY: _hoverPixelY!,
                          radius: _magnifierRadius,
                          pixelSize: _magnifierPixelSize,
                        ),
                      )
                    : Container(
                        color: EditorColors.inputBackground,
                        child: const Center(
                          child: Text(
                            '이미지 위에\n마우스를 올려주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: EditorColors.iconDisabled,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pixel coordinates
          if (_hoverPixelX != null && _hoverPixelY != null) ...[
            _buildInfoRow('위치', '($_hoverPixelX, $_hoverPixelY)'),
            const SizedBox(height: 4),
            if (_hoverPixelX != null && _hoverPixelY != null)
              Builder(builder: (context) {
                final pixel = widget.image.getPixel(_hoverPixelX!, _hoverPixelY!);
                // image package returns values in 0-255 range
                final r = pixel.r.toInt().clamp(0, 255);
                final g = pixel.g.toInt().clamp(0, 255);
                final b = pixel.b.toInt().clamp(0, 255);
                final a = pixel.a.toInt().clamp(0, 255);
                final hexColor = '#${r.toRadixString(16).padLeft(2, '0')}'
                    '${g.toRadixString(16).padLeft(2, '0')}'
                    '${b.toRadixString(16).padLeft(2, '0')}'
                    .toUpperCase();
                return Column(
                  children: [
                    _buildInfoRow('색상', hexColor),
                    const SizedBox(height: 4),
                    _buildInfoRow('RGBA', '($r, $g, $b, $a)'),
                  ],
                );
              }),
          ] else ...[
            _buildInfoRow('위치', '--'),
            const SizedBox(height: 4),
            _buildInfoRow('색상', '--'),
            const SizedBox(height: 4),
            _buildInfoRow('RGBA', '--'),
          ],

          const Spacer(),

          // Hint
          const Text(
            '클릭하여 색상 선택',
            style: TextStyle(
              fontSize: 10,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: EditorColors.iconDisabled,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: EditorColors.iconDefault,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _pickedColor == null
                ? null
                : () {
                    widget.onColorPicked(_pickedColor!);
                    Navigator.of(context).pop();
                  },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for magnifier view showing pixels around the cursor
class _MagnifierPainter extends CustomPainter {
  final img.Image image;
  final int centerX;
  final int centerY;
  final int radius;
  final double pixelSize;

  _MagnifierPainter({
    required this.image,
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.pixelSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw checkerboard for transparency
    final lightPaint = Paint()..color = const Color(0xFF3A3A3A);
    final darkPaint = Paint()..color = const Color(0xFF2A2A2A);

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final px = centerX + dx;
        final py = centerY + dy;

        final rectX = (dx + radius) * pixelSize;
        final rectY = (dy + radius) * pixelSize;
        final rect = Rect.fromLTWH(rectX, rectY, pixelSize, pixelSize);

        // Draw checkerboard
        final isDark = ((dx + radius) + (dy + radius)) % 2 == 0;
        canvas.drawRect(rect, isDark ? darkPaint : lightPaint);

        // Draw pixel if within bounds
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          final pixel = image.getPixel(px, py);
          // image package returns values in 0-255 range (as num type)
          final a = pixel.a.toInt().clamp(0, 255);
          final r = pixel.r.toInt().clamp(0, 255);
          final g = pixel.g.toInt().clamp(0, 255);
          final b = pixel.b.toInt().clamp(0, 255);

          // Only draw if not fully transparent
          if (a > 0) {
            paint.color = Color.fromARGB(a, r, g, b);
            canvas.drawRect(rect, paint);
          }
        }
      }
    }

    // Draw center crosshair
    final centerRect = Rect.fromLTWH(
      radius * pixelSize,
      radius * pixelSize,
      pixelSize,
      pixelSize,
    );
    final borderPaint = Paint()
      ..color = EditorColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(centerRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MagnifierPainter oldDelegate) {
    return centerX != oldDelegate.centerX || centerY != oldDelegate.centerY;
  }
}
