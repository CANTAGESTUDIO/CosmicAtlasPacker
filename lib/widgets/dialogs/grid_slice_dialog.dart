import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import '../../models/enums/slice_mode.dart';
import '../../services/grid_slicer_service.dart';
import '../../theme/editor_colors.dart';

/// Dialog for configuring grid slicing
class GridSliceDialog extends StatefulWidget {
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
      builder: (context) => GridSliceDialog(
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      ),
    );
  }

  @override
  State<GridSliceDialog> createState() => _GridSliceDialogState();
}

class _GridSliceDialogState extends State<GridSliceDialog> {
  SliceMode _mode = SliceMode.cellSize;

  // Cell Size mode
  final _cellWidthController = TextEditingController(text: '64');
  final _cellHeightController = TextEditingController(text: '64');

  // Cell Count mode
  final _columnsController = TextEditingController(text: '4');
  final _rowsController = TextEditingController(text: '4');

  // Common
  final _offsetXController = TextEditingController(text: '0');
  final _offsetYController = TextEditingController(text: '0');
  final _prefixController = TextEditingController(text: 'sprite');

  // Advanced options
  int _paddingX = 0;
  int _paddingY = 0;
  bool _showGridLines = true;
  bool _showCellNumbers = false;
  String _numberFormat = '001'; // 001, 01, 1

  String? _validationError;

  @override
  void dispose() {
    _cellWidthController.dispose();
    _cellHeightController.dispose();
    _columnsController.dispose();
    _rowsController.dispose();
    _offsetXController.dispose();
    _offsetYController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  GridSliceConfig _buildConfig() {
    return GridSliceConfig(
      mode: _mode,
      primaryValue: _mode == SliceMode.cellSize
          ? int.tryParse(_cellWidthController.text) ?? 64
          : int.tryParse(_columnsController.text) ?? 4,
      secondaryValue: _mode == SliceMode.cellSize
          ? int.tryParse(_cellHeightController.text) ?? 64
          : int.tryParse(_rowsController.text) ?? 4,
      offsetX: int.tryParse(_offsetXController.text) ?? 0,
      offsetY: int.tryParse(_offsetYController.text) ?? 0,
      idPrefix: _prefixController.text.isEmpty ? 'sprite' : _prefixController.text,
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor: EditorColors.surface,
      child: SizedBox(
        width: 400,
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
                    // Mode selection
                    _buildModeSelector(),
                    const SizedBox(height: 16),

                    // Mode-specific inputs
                    if (_mode == SliceMode.cellSize) _buildCellSizeInputs(),
                    if (_mode == SliceMode.cellCount) _buildCellCountInputs(),
                    const SizedBox(height: 16),

                    // Offset inputs
                    _buildOffsetInputs(),
                    const SizedBox(height: 16),

                    // ID prefix
                    _buildPrefixInput(),
                    const SizedBox(height: 16),

                    // Advanced options
                    _buildAdvancedOptions(),
                    const SizedBox(height: 16),

                    // Preview
                    _buildPreview(preview),

                    // Validation error
                    if (_validationError != null) ...[
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
            'Grid Slice',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.imageWidth} × ${widget.imageHeight}',
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
    final preview = _getPreview();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _validationError == null && preview.total > 0
                ? () => Navigator.of(context).pop(_buildConfig())
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text('Apply (${preview.total} sprites)'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Slice Mode'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _OptionButton(
                label: 'Cell Size',
                isSelected: _mode == SliceMode.cellSize,
                onTap: () {
                  setState(() => _mode = SliceMode.cellSize);
                  _validate();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OptionButton(
                label: 'Cell Count',
                isSelected: _mode == SliceMode.cellCount,
                onTap: () {
                  setState(() => _mode = SliceMode.cellCount);
                  _validate();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCellSizeInputs() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            label: 'Cell Width',
            controller: _cellWidthController,
            suffix: 'px',
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 16),
        const Text('×'),
        const SizedBox(width: 16),
        Expanded(
          child: _NumberField(
            label: 'Cell Height',
            controller: _cellHeightController,
            suffix: 'px',
            onChanged: (_) => _validate(),
          ),
        ),
      ],
    );
  }

  Widget _buildCellCountInputs() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            label: 'Columns',
            controller: _columnsController,
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 16),
        const Text('×'),
        const SizedBox(width: 16),
        Expanded(
          child: _NumberField(
            label: 'Rows',
            controller: _rowsController,
            onChanged: (_) => _validate(),
          ),
        ),
      ],
    );
  }

  Widget _buildOffsetInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Offset (Optional)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'X',
                controller: _offsetXController,
                suffix: 'px',
                onChanged: (_) => _validate(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NumberField(
                label: 'Y',
                controller: _offsetYController,
                suffix: 'px',
                onChanged: (_) => _validate(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrefixInput() {
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

  Widget _buildAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Advanced Options'),
          const SizedBox(height: 12),

          // Cell Padding
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SliderRow(
                label: 'Padding X',
                value: _paddingX,
                suffix: 'px',
                min: 0,
                max: 32,
                onChanged: (value) => setState(() => _paddingX = value),
              ),
              const SizedBox(height: 12),
              _SliderRow(
                label: 'Padding Y',
                value: _paddingY,
                suffix: 'px',
                min: 0,
                max: 32,
                onChanged: (value) => setState(() => _paddingY = value),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Grid visualization options
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grid Visualization',
                style: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _showGridLines,
                          onChanged: (value) {
                            setState(() => _showGridLines = value ?? true);
                          },
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Show Grid Lines',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _showCellNumbers,
                          onChanged: (value) {
                            setState(() => _showCellNumbers = value ?? false);
                          },
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Show Cell Numbers',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Number format (only shown when cell numbers enabled)
          if (_showCellNumbers) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number Format',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final format in ['001', '01', '1'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _numberFormat = format);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _numberFormat == format
                                  ? EditorColors.primary.withValues(alpha: 0.2)
                                  : EditorColors.inputBackground,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _numberFormat == format
                                    ? EditorColors.primary
                                    : EditorColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                format,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _numberFormat == format
                                      ? EditorColors.primary
                                      : EditorColors.iconDefault,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ].expand((w) => [w, const SizedBox(width: 8)]).toList()
                    ..removeLast(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: sprite_${_getFormattedNumber(1)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: EditorColors.iconDisabled,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(
      ({int columns, int rows, int cellWidth, int cellHeight, int total}) preview) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Preview'),
          const SizedBox(height: 8),
          Row(
            children: [
              _PreviewItem(label: 'Grid', value: '${preview.columns} × ${preview.rows}'),
              const SizedBox(width: 16),
              _PreviewItem(
                  label: 'Cell Size', value: '${preview.cellWidth} × ${preview.cellHeight} px'),
              const SizedBox(width: 16),
              _PreviewItem(label: 'Total', value: '${preview.total} sprites'),
            ],
          ),
        ],
      ),
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

class _PreviewItem extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: EditorColors.iconDisabled,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
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

/// Grid preview overlay painter for visualizing grid lines
class _GridPreviewPainter extends CustomPainter {
  final int imageWidth;
  final int imageHeight;
  final int columns;
  final int rows;
  final int cellWidth;
  final int cellHeight;
  final int offsetX;
  final int offsetY;
  final int paddingX;
  final int paddingY;
  final bool showGridLines;
  final bool showCellNumbers;
  final String numberFormat;
  final String idPrefix;
  final int? hoveredCell;

  _GridPreviewPainter({
    required this.imageWidth,
    required this.imageHeight,
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.offsetX,
    required this.offsetY,
    required this.paddingX,
    required this.paddingY,
    required this.showGridLines,
    required this.showCellNumbers,
    required this.numberFormat,
    required this.idPrefix,
    this.hoveredCell,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGridLines && !showCellNumbers) return;

    final paint = ui.Paint()
      ..color = EditorColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw grid lines
    if (showGridLines) {
      // Vertical lines
      for (int col = 0; col <= columns; col++) {
        final x = offsetX + col * (cellWidth + paddingX * 2);
        if (x >= 0 && x <= imageWidth) {
          canvas.drawLine(
            Offset(x.toDouble(), 0),
            Offset(x.toDouble(), imageHeight.toDouble()),
            paint,
          );
        }
      }

      // Horizontal lines
      for (int row = 0; row <= rows; row++) {
        final y = offsetY + row * (cellHeight + paddingY * 2);
        if (y >= 0 && y <= imageHeight) {
          canvas.drawLine(
            Offset(0, y.toDouble()),
            Offset(imageWidth.toDouble(), y.toDouble()),
            paint,
          );
        }
      }
    }

    // Draw cell numbers
    if (showCellNumbers) {
      int cellNumber = 1;
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < columns; col++) {
          final cellX = offsetX + col * (cellWidth + paddingX * 2) + paddingX;
          final cellY = offsetY + row * (cellHeight + paddingY * 2) + paddingY;

          final formattedNumber = _formatNumber(cellNumber);
          final cellLabel = '$idPrefix\_$formattedNumber';

          textPaint.text = TextSpan(
            text: cellLabel,
            style: const TextStyle(
              color: ui.Color.fromARGB(200, 100, 200, 255),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          );
          textPaint.layout();

          if (cellX + textPaint.width < imageWidth &&
              cellY + textPaint.height < imageHeight) {
            textPaint.paint(
              canvas,
              Offset(cellX.toDouble() + 2, cellY.toDouble() + 2),
            );
          }

          cellNumber++;
        }
      }
    }
  }

  String _formatNumber(int number) {
    if (numberFormat == '001') {
      return number.toString().padLeft(3, '0');
    } else if (numberFormat == '01') {
      return number.toString().padLeft(2, '0');
    } else {
      return number.toString();
    }
  }

  @override
  bool shouldRepaint(_GridPreviewPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY ||
        oldDelegate.showGridLines != showGridLines ||
        oldDelegate.showCellNumbers != showCellNumbers ||
        oldDelegate.hoveredCell != hoveredCell;
  }
}
