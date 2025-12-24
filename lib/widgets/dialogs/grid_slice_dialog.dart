import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums/slice_mode.dart';
import '../../providers/grid_preview_provider.dart';
import '../../services/grid_slicer_service.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';
import '../common/editor_text_field.dart';

/// Dialog for configuring grid slicing
class GridSliceDialog extends ConsumerStatefulWidget {
  /// Source image width
  final int imageWidth;

  /// Source image height
  final int imageHeight;

  const GridSliceDialog({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Show grid slice dialog and return config if confirmed
  static Future<GridSliceConfig?> show(
    BuildContext context, {
    required int imageWidth,
    required int imageHeight,
  }) async {
    return showDialog<GridSliceConfig>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => GridSliceDialog(
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      ),
    );
  }

  @override
  ConsumerState<GridSliceDialog> createState() => _GridSliceDialogState();
}

class _GridSliceDialogState extends ConsumerState<GridSliceDialog> {
  SliceMode _mode = SliceMode.cellCount;

  // Cell Size mode
  int _cellWidth = 64;
  int _cellHeight = 64;

  // Cell Count mode
  int _columns = 4;
  int _rows = 4;

  // Common
  int _offsetX = 0;
  int _offsetY = 0;
  String _idPrefix = 'sprite';

  // Advanced options
  bool _showGridLines = true;
  bool _showCellNumbers = false;
  String _numberFormat = '001'; // 001, 01, 1

  String? _validationError;

  @override
  void initState() {
    super.initState();
    // Activate grid preview when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGridPreview();
    });
  }

  /// Clear grid preview and close dialog
  void _closeDialog([GridSliceConfig? result]) {
    // Deactivate grid preview before closing
    ref.read(gridPreviewProvider.notifier).state = const GridPreviewState();
    Navigator.of(context).pop(result);
  }

  /// Update grid preview state for real-time visualization
  void _updateGridPreview() {
    final preview = _getPreview();
    ref.read(gridPreviewProvider.notifier).state = GridPreviewState(
      isActive: true,
      imageWidth: widget.imageWidth,
      imageHeight: widget.imageHeight,
      columns: preview.columns,
      rows: preview.rows,
      cellWidth: preview.cellWidth,
      cellHeight: preview.cellHeight,
      offsetX: _offsetX,
      offsetY: _offsetY,
      showGridLines: _showGridLines,
      showCellNumbers: _showCellNumbers,
      numberFormat: _numberFormat,
      idPrefix: _idPrefix.isEmpty ? 'sprite' : _idPrefix,
    );
  }

  GridSliceConfig _buildConfig() {
    return GridSliceConfig(
      mode: _mode,
      primaryValue: _mode == SliceMode.cellSize ? _cellWidth : _columns,
      secondaryValue: _mode == SliceMode.cellSize ? _cellHeight : _rows,
      offsetX: _offsetX,
      offsetY: _offsetY,
      idPrefix: _idPrefix.isEmpty ? 'sprite' : _idPrefix,
    );
  }

  void _validate() {
    final config = _buildConfig();
    const service = GridSlicerService();
    setState(() {
      _validationError = service.validateConfig(
        imageWidth: widget.imageWidth,
        imageHeight: widget.imageHeight,
        config: config,
      );
    });
    // Update grid preview for real-time visualization
    _updateGridPreview();
  }

  String _getFormattedNumber(int number) {
    if (_numberFormat == '001') {
      return number.toString().padLeft(3, '0');
    } else if (_numberFormat == '01') {
      return number.toString().padLeft(2, '0');
    } else {
      return number.toString();
    }
  }

  ({int columns, int rows, int cellWidth, int cellHeight, int total}) _getPreview() {
    final config = _buildConfig();
    const service = GridSlicerService();
    final preview = service.previewGrid(
      imageWidth: widget.imageWidth,
      imageHeight: widget.imageHeight,
      config: config,
    );
    return (
      columns: preview.columns,
      rows: preview.rows,
      cellWidth: preview.cellWidth,
      cellHeight: preview.cellHeight,
      total: preview.columns * preview.rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _getPreview();

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): _ApplyIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ApplyIntent: CallbackAction<_ApplyIntent>(
            onInvoke: (_) {
              if (_validationError == null && preview.total > 0) {
                _closeDialog(_buildConfig());
              }
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) => _closeDialog(),
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
                      // Preview info display
                      _buildPreviewInfoSection(preview),
                      const SizedBox(height: 20),

                      // Mode selection
                      _buildModeSection(),
                      const SizedBox(height: 20),

                      // Mode-specific inputs
                      if (_mode == SliceMode.cellSize)
                        _buildCellSizeSection()
                      else
                        _buildCellCountSection(),
                      const SizedBox(height: 20),

                      // Offset
                      _buildOffsetSection(),
                      const SizedBox(height: 20),

                      // Advanced options
                      _buildAdvancedOptionsSection(),
                      const SizedBox(height: 20),

                      // ID Prefix
                      _buildPrefixSection(),

                      // Validation error
                      if (_validationError != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _validationError!,
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
              _buildActions(preview),
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
            '그리드 슬라이스',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.imageWidth} × ${widget.imageHeight}',
            style: const TextStyle(
              fontSize: 13,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewInfoSection(
      ({int columns, int rows, int cellWidth, int cellHeight, int total}) preview) {
    return Row(
      children: [
        const Icon(
          Icons.grid_on,
          size: 16,
          color: EditorColors.primary,
        ),
        const SizedBox(width: 8),
        const Text(
          '그리드 결과',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: EditorColors.iconDefault,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: preview.total == 0
                ? EditorColors.warning.withValues(alpha: 0.15)
                : EditorColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${preview.columns}×${preview.rows}',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: preview.total == 0 ? EditorColors.warning : EditorColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${preview.total}개',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: preview.total == 0
                      ? EditorColors.warning.withValues(alpha: 0.8)
                      : EditorColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '슬라이스 모드'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OptionButton(
                label: '셀 개수 지정',
                isSelected: _mode == SliceMode.cellCount,
                onTap: () {
                  setState(() => _mode = SliceMode.cellCount);
                  _validate();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OptionButton(
                label: '셀 크기 지정',
                isSelected: _mode == SliceMode.cellSize,
                onTap: () {
                  setState(() => _mode = SliceMode.cellSize);
                  _validate();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCellSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '셀 크기'),
        const SizedBox(height: 14),
        _SliderRow(
          label: '셀 너비',
          value: _cellWidth,
          suffix: 'px',
          min: 1,
          max: widget.imageWidth,
          onChanged: (value) {
            setState(() => _cellWidth = value);
            _validate();
          },
        ),
        const SizedBox(height: 14),
        _SliderRow(
          label: '셀 높이',
          value: _cellHeight,
          suffix: 'px',
          min: 1,
          max: widget.imageHeight,
          onChanged: (value) {
            setState(() => _cellHeight = value);
            _validate();
          },
        ),
      ],
    );
  }

  Widget _buildCellCountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '셀 개수'),
        const SizedBox(height: 14),
        _SliderRow(
          label: '열 개수',
          value: _columns,
          min: 1,
          max: 32,
          onChanged: (value) {
            setState(() => _columns = value);
            _validate();
          },
        ),
        const SizedBox(height: 14),
        _SliderRow(
          label: '행 개수',
          value: _rows,
          min: 1,
          max: 32,
          onChanged: (value) {
            setState(() => _rows = value);
            _validate();
          },
        ),
      ],
    );
  }

  Widget _buildOffsetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '오프셋'),
        const SizedBox(height: 14),
        _SliderRow(
          label: 'X 오프셋',
          value: _offsetX,
          suffix: 'px',
          min: 0,
          max: 64,
          onChanged: (value) {
            setState(() => _offsetX = value);
            _validate();
          },
        ),
        const SizedBox(height: 14),
        _SliderRow(
          label: 'Y 오프셋',
          value: _offsetY,
          suffix: 'px',
          min: 0,
          max: 64,
          onChanged: (value) {
            setState(() => _offsetY = value);
            _validate();
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '고급 옵션'),
        const SizedBox(height: 14),

        // Grid visualization toggles
        _ToggleRow(
          label: '그리드 라인 표시',
          value: _showGridLines,
          onChanged: (value) {
            setState(() => _showGridLines = value);
            _updateGridPreview();
          },
        ),
        const SizedBox(height: 14),
        _ToggleRow(
          label: '셀 번호 표시',
          value: _showCellNumbers,
          onChanged: (value) {
            setState(() => _showCellNumbers = value);
            _updateGridPreview();
          },
        ),

        // Number format (only shown when cell numbers enabled)
        if (_showCellNumbers) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  '번호 형식',
                  style: TextStyle(fontSize: 13, color: EditorColors.iconDefault),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (final format in ['001', '01', '1']) ...[
                      Expanded(
                        child: _FormatButton(
                          format: format,
                          isSelected: _numberFormat == format,
                          onTap: () {
                            setState(() => _numberFormat = format);
                            _updateGridPreview();
                          },
                        ),
                      ),
                      if (format != '1') const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 120),
            child: Text(
              '예: ${_idPrefix}_${_getFormattedNumber(1)}',
              style: const TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrefixSection() {
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
            setState(() {});
            _updateGridPreview();
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(
      ({int columns, int rows, int cellWidth, int cellHeight, int total}) preview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _closeDialog(),
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
            onPressed: _validationError == null && preview.total > 0
                ? () => _closeDialog(_buildConfig())
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(0, 38),
              textStyle: const TextStyle(fontSize: 13),
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
              : EditorColors.border,
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
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
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

class _FormatButton extends StatelessWidget {
  final String format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? EditorColors.primary.withValues(alpha: 0.15)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? EditorColors.primary : EditorColors.border,
          ),
        ),
        child: Center(
          child: Text(
            format,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
            ),
          ),
        ),
      ),
    );
  }
}

/// Editor TextField wrapper using common ShortcutBlockingTextField
class _EditorTextField extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;

  const _EditorTextField({
    this.initialValue,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
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
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return ShortcutBlockingTextField(
      controller: _controller,
      style: const TextStyle(
        fontSize: 13,
        color: EditorColors.iconDefault,
      ),
      hintText: widget.hintText,
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
      onSubmitted: widget.onSubmitted,
    );
  }
}
