import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    return AlertDialog(
      title: const Text('Grid Slice Settings'),
      backgroundColor: EditorColors.surface,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image info
            Text(
              'Image: ${widget.imageWidth} × ${widget.imageHeight} px',
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled,
              ),
            ),
            const SizedBox(height: 16),

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

            // Preview
            _buildPreview(preview),

            // Validation error
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationError!,
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _validationError == null && preview.total > 0
              ? () => Navigator.of(context).pop(_buildConfig())
              : null,
          child: Text('Apply (${preview.total} sprites)'),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Slice Mode',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
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
              child: _ModeButton(
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
        const Text(
          'Offset (Optional)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          _mode == SliceMode.cellSize
              ? '그리드 시작 위치를 조정합니다. 이미지 왼쪽 상단에서 X, Y 픽셀만큼 이동한 위치부터 슬라이스합니다.'
              : '그리드 시작 위치를 조정합니다. 이미지 왼쪽 상단에서 X, Y 픽셀만큼 이동한 위치부터 슬라이스합니다.',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
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
        const Text(
          'ID Prefix',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
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
          const Text(
            'Preview',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
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

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? EditorColors.primary.withValues(alpha: 0.2)
              : EditorColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? EditorColors.primary : EditorColors.border,
          ),
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
              ),
            ),
          ],
        ),
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
