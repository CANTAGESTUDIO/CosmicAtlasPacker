import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/multi_sprite_provider.dart';
import '../../providers/packing_provider.dart';
import '../../services/bin_packing_service.dart';
import '../../services/sprite_resize_service.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';

/// Dialog for adjusting canvas size and sprite scaling
class CanvasSizeDialog extends ConsumerStatefulWidget {
  const CanvasSizeDialog({super.key});

  /// Show canvas size dialog
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const CanvasSizeDialog(),
    );
  }

  @override
  ConsumerState<CanvasSizeDialog> createState() => _CanvasSizeDialogState();
}

class _CanvasSizeDialogState extends ConsumerState<CanvasSizeDialog> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late FocusNode _widthFocus;
  late FocusNode _heightFocus;

  bool _lockAspectRatio = false;
  bool _powerOfTwo = true;
  bool _forceSquare = false;

  late int _originalWidth;
  late int _originalHeight;
  double _aspectRatio = 1.0;

  // Scale presets
  double _selectedScale = 1.0;
  static const _scalePresets = [1.0, 0.75, 0.5, 0.25];

  @override
  void initState() {
    super.initState();
    _widthFocus = FocusNode();
    _heightFocus = FocusNode();

    // Get current atlas size
    final atlasSize = ref.read(atlasSizeProvider);
    final settings = ref.read(atlasSettingsProvider);

    _originalWidth = atlasSize.$1;
    _originalHeight = atlasSize.$2;
    _aspectRatio = _originalWidth / _originalHeight;
    _powerOfTwo = settings.powerOfTwo;
    _forceSquare = settings.forceSquare;

    _widthController = TextEditingController(text: _originalWidth.toString());
    _heightController = TextEditingController(text: _originalHeight.toString());

    _widthFocus.addListener(_onWidthFocusChange);
    _heightFocus.addListener(_onHeightFocusChange);
  }

  @override
  void dispose() {
    _widthFocus.removeListener(_onWidthFocusChange);
    _heightFocus.removeListener(_onHeightFocusChange);
    _widthFocus.dispose();
    _heightFocus.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onWidthFocusChange() {
    if (!_widthFocus.hasFocus) {
      _validateAndUpdateWidth();
    }
  }

  void _onHeightFocusChange() {
    if (!_heightFocus.hasFocus) {
      _validateAndUpdateHeight();
    }
  }

  void _validateAndUpdateWidth() {
    final value = int.tryParse(_widthController.text) ?? _originalWidth;
    final clamped = value.clamp(64, 8192);
    _widthController.text = clamped.toString();

    if (_lockAspectRatio) {
      final newHeight = (clamped / _aspectRatio).round().clamp(64, 8192);
      _heightController.text = newHeight.toString();
    }

    if (_forceSquare) {
      _heightController.text = clamped.toString();
    }
  }

  void _validateAndUpdateHeight() {
    final value = int.tryParse(_heightController.text) ?? _originalHeight;
    final clamped = value.clamp(64, 8192);
    _heightController.text = clamped.toString();

    if (_lockAspectRatio) {
      final newWidth = (clamped * _aspectRatio).round().clamp(64, 8192);
      _widthController.text = newWidth.toString();
    }

    if (_forceSquare) {
      _widthController.text = clamped.toString();
    }
  }

  void _applyScalePreset(double scale) {
    setState(() {
      _selectedScale = scale;
      final newWidth = (_originalWidth * scale).round().clamp(64, 8192);
      final newHeight = (_originalHeight * scale).round().clamp(64, 8192);

      if (_powerOfTwo) {
        _widthController.text = _nextPowerOfTwo(newWidth).toString();
        _heightController.text = _nextPowerOfTwo(newHeight).toString();
      } else {
        _widthController.text = newWidth.toString();
        _heightController.text = newHeight.toString();
      }
    });
  }

  int _nextPowerOfTwo(int value) {
    if (value <= 0) return 1;
    value--;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return value + 1;
  }

  Future<void> _apply() async {
    final targetWidth = int.tryParse(_widthController.text) ?? _originalWidth;
    final targetHeight = int.tryParse(_heightController.text) ?? _originalHeight;

    // Get current sprites
    final sprites = ref.read(atlasSpritesProvider);
    if (sprites.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    // Try packing with new size
    final packer = BinPackingService();
    final settings = ref.read(atlasSettingsProvider);
    final effectivePadding = settings.tightPacking ? 0 : settings.padding;

    final testResult = packer.pack(
      sprites,
      maxWidth: targetWidth,
      maxHeight: targetHeight,
      padding: effectivePadding,
      powerOfTwo: _powerOfTwo,
      allowRotation: settings.allowRotation,
    );

    if (testResult.isComplete) {
      // All sprites fit, just update settings
      ref.read(atlasSettingsProvider.notifier).updateSettings(
        settings.copyWith(
          maxWidth: targetWidth,
          maxHeight: targetHeight,
          powerOfTwo: _powerOfTwo,
          forceSquare: _forceSquare,
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Sprites don't fit, ask user to confirm compression
      final confirmed = await _showCompressionConfirmDialog();
      if (confirmed == true) {
        await _applyWithCompression(targetWidth, targetHeight);
      }
    }
  }

  Future<bool?> _showCompressionConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: EditorColors.panelBackground,
        title: Text(
          '이미지 압축',
          style: TextStyle(
            color: EditorColors.iconDefault,
            fontSize: 16,
          ),
        ),
        content: Text(
          '이미지를 압축합니다.\n적용 하시겠습니까?',
          style: TextStyle(
            color: EditorColors.iconDisabled,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(color: EditorColors.iconDefault),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '적용',
              style: TextStyle(color: EditorColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyWithCompression(int targetWidth, int targetHeight) async {
    final sprites = ref.read(atlasSpritesProvider);
    final settings = ref.read(atlasSettingsProvider);
    final effectivePadding = settings.tightPacking ? 0 : settings.padding;

    // Calculate optimal scale using binary search
    final optimalScale = SpriteResizeService.findOptimalScale(
      sprites: sprites,
      maxWidth: targetWidth,
      maxHeight: targetHeight,
      padding: effectivePadding,
      allowRotation: settings.allowRotation,
    );

    if (optimalScale < 1.0) {
      // Resize all sprites
      await ref.read(multiSpriteProvider.notifier).resizeAllSprites(optimalScale);
    }

    // Update settings
    ref.read(atlasSettingsProvider.notifier).updateSettings(
      settings.copyWith(
        maxWidth: targetWidth,
        maxHeight: targetHeight,
        powerOfTwo: _powerOfTwo,
        forceSquare: _forceSquare,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableDialog(
      width: 320,
      header: _buildHeader(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Size inputs
                _buildSizeInputs(),
                const SizedBox(height: 16),
                // Options
                _buildOptions(),
                const SizedBox(height: 16),
                // Scale presets
                _buildScalePresets(),
              ],
            ),
          ),
          // Actions
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.aspect_ratio,
            size: 18,
            color: EditorColors.iconDefault,
          ),
          const SizedBox(width: 8),
          Text(
            '캔버스 사이즈',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: EditorColors.iconDefault,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeInputs() {
    return Row(
      children: [
        // Width
        Expanded(
          child: _buildNumberInput(
            label: '너비',
            controller: _widthController,
            focusNode: _widthFocus,
            suffix: 'px',
          ),
        ),
        const SizedBox(width: 12),
        // Lock aspect ratio button
        IconButton(
          icon: Icon(
            _lockAspectRatio ? Icons.link : Icons.link_off,
            size: 18,
            color: _lockAspectRatio
                ? EditorColors.primary
                : EditorColors.iconDisabled,
          ),
          onPressed: () {
            setState(() {
              _lockAspectRatio = !_lockAspectRatio;
              if (_lockAspectRatio) {
                final w = int.tryParse(_widthController.text) ?? _originalWidth;
                final h = int.tryParse(_heightController.text) ?? _originalHeight;
                _aspectRatio = w / h;
              }
            });
          },
          tooltip: '비율 고정',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 12),
        // Height
        Expanded(
          child: _buildNumberInput(
            label: '높이',
            controller: _heightController,
            focusNode: _heightFocus,
            suffix: 'px',
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String suffix,
  }) {
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
        Focus(
          skipTraversal: true,
          onKeyEvent: (node, event) {
            if (focusNode.hasFocus) {
              return KeyEventResult.skipRemainingHandlers;
            }
            return KeyEventResult.ignored;
          },
          child: SizedBox(
            height: 32,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: EditorColors.iconDefault,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled,
                ),
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
                filled: true,
                fillColor: EditorColors.inputBackground,
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onSubmitted: (_) {
                if (focusNode == _widthFocus) {
                  _validateAndUpdateWidth();
                } else {
                  _validateAndUpdateHeight();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        _buildOptionToggle(
          label: '2의 거듭제곱',
          isEnabled: _powerOfTwo,
          onTap: () {
            setState(() => _powerOfTwo = !_powerOfTwo);
          },
        ),
        const SizedBox(height: 8),
        _buildOptionToggle(
          label: '정사각형 강제',
          isEnabled: _forceSquare,
          onTap: () {
            setState(() {
              _forceSquare = !_forceSquare;
              if (_forceSquare) {
                final w = int.tryParse(_widthController.text) ?? _originalWidth;
                _heightController.text = w.toString();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildOptionToggle({
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: isEnabled ? EditorColors.primary : EditorColors.iconDefault,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? EditorColors.primary : EditorColors.iconDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScalePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '아틀라스 스케일',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: EditorColors.iconDefault,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _scalePresets.map((scale) {
            final isSelected = (_selectedScale - scale).abs() < 0.01;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: scale != _scalePresets.last ? 6 : 0,
                ),
                child: GestureDetector(
                  onTap: () => _applyScalePreset(scale),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? EditorColors.primary.withValues(alpha: 0.2)
                            : EditorColors.border,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected
                            ? Border.all(color: EditorColors.primary)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${(scale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? EditorColors.primary
                                : EditorColors.iconDefault,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                color: EditorColors.iconDefault,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: EditorColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text(
              '적용',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
