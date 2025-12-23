import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../models/atlas_settings.dart';
import '../../providers/export_provider.dart';
import '../../providers/image_provider.dart';
import '../../providers/packing_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../services/bin_packing_service.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';

/// Export dialog settings state
class ExportDialogSettings {
  final String outputPath;
  final String fileName;
  final bool exportPng;
  final bool exportJson;
  final bool prettyPrintJson;
  final AtlasSettings atlasSettings;

  const ExportDialogSettings({
    this.outputPath = '',
    this.fileName = 'atlas',
    this.exportPng = true,
    this.exportJson = true,
    this.prettyPrintJson = true,
    required this.atlasSettings,
  });

  ExportDialogSettings copyWith({
    String? outputPath,
    String? fileName,
    bool? exportPng,
    bool? exportJson,
    bool? prettyPrintJson,
    AtlasSettings? atlasSettings,
  }) {
    return ExportDialogSettings(
      outputPath: outputPath ?? this.outputPath,
      fileName: fileName ?? this.fileName,
      exportPng: exportPng ?? this.exportPng,
      exportJson: exportJson ?? this.exportJson,
      prettyPrintJson: prettyPrintJson ?? this.prettyPrintJson,
      atlasSettings: atlasSettings ?? this.atlasSettings,
    );
  }

  String get pngPath => outputPath.isEmpty
      ? ''
      : '$outputPath${Platform.pathSeparator}$fileName.png';

  String get jsonPath => outputPath.isEmpty
      ? ''
      : '$outputPath${Platform.pathSeparator}$fileName.json';

  bool get isValid =>
      outputPath.isNotEmpty && fileName.isNotEmpty && (exportPng || exportJson);
}

/// Export dialog for atlas export with settings and preview
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  /// Show export dialog
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const ExportDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late ExportDialogSettings _settings;
  late TextEditingController _fileNameController;
  late TextEditingController _maxWidthController;
  late TextEditingController _maxHeightController;
  late TextEditingController _paddingController;

  bool _isExporting = false;
  String? _exportError;
  PackingResult? _previewPackingResult;

  @override
  void initState() {
    super.initState();
    final atlasSettings = ref.read(atlasSettingsProvider);
    final sourceImage = ref.read(sourceImageProvider);

    // Generate default filename from source
    String defaultName = 'atlas';
    if (sourceImage.fileName != null) {
      defaultName = sourceImage.fileName!
              .replaceAll(RegExp(r'\.[^.]+$'), '')
              .replaceAll(RegExp(r'[^\w\-]'), '_') +
          '_atlas';
    }

    _settings = ExportDialogSettings(
      fileName: defaultName,
      atlasSettings: atlasSettings,
    );

    _fileNameController = TextEditingController(text: _settings.fileName);
    _maxWidthController =
        TextEditingController(text: atlasSettings.maxWidth.toString());
    _maxHeightController =
        TextEditingController(text: atlasSettings.maxHeight.toString());
    _paddingController =
        TextEditingController(text: atlasSettings.padding.toString());

    // Generate initial preview
    _updatePreview();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _maxWidthController.dispose();
    _maxHeightController.dispose();
    _paddingController.dispose();
    super.dispose();
  }

  void _updateSettings(ExportDialogSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _exportError = null;
    });
    _updatePreview();
  }

  void _updatePreview() {
    final sprites = ref.read(spriteProvider).sprites;
    if (sprites.isEmpty) {
      setState(() => _previewPackingResult = null);
      return;
    }

    final packingService = ref.read(binPackingServiceProvider);
    final result = packingService.pack(
      sprites,
      maxWidth: _settings.atlasSettings.maxWidth,
      maxHeight: _settings.atlasSettings.maxHeight,
      padding: _settings.atlasSettings.padding,
      powerOfTwo: _settings.atlasSettings.powerOfTwo,
    );

    setState(() => _previewPackingResult = result);
  }

  Future<void> _selectOutputPath() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Directory',
    );

    if (path != null) {
      _updateSettings(_settings.copyWith(outputPath: path));
    }
  }

  Future<void> _performExport() async {
    if (!_settings.isValid) {
      setState(() => _exportError = 'Please configure all required settings');
      return;
    }

    setState(() {
      _isExporting = true;
      _exportError = null;
    });

    try {
      final sourceImageState = ref.read(sourceImageProvider);
      final exportService = ref.read(exportServiceProvider);

      if (sourceImageState.rawImage == null) {
        throw Exception('No source image loaded');
      }

      if (_previewPackingResult == null ||
          _previewPackingResult!.packedSprites.isEmpty) {
        throw Exception('No sprites to export');
      }

      // Export PNG if enabled
      if (_settings.exportPng) {
        final atlasImage = exportService.generateAtlasImage(
          sourceImage: sourceImageState.rawImage!,
          packingResult: _previewPackingResult!,
        );
        await exportService.exportPng(
          atlasImage: atlasImage,
          pngPath: _settings.pngPath,
        );
      }

      // Export JSON if enabled
      if (_settings.exportJson) {
        final metadata = exportService.generateMetadata(
          packingResult: _previewPackingResult!,
          atlasFileName: '${_settings.fileName}.png',
        );
        await exportService.exportJson(
          metadata: metadata,
          outputPath: _settings.jsonPath,
          prettyPrint: _settings.prettyPrintJson,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportError = 'Export failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableDialog(
      header: _buildHeader(),
      width: 600,
      height: 500,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Settings
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOutputSection(),
                    const SizedBox(height: 16),
                    _buildAtlasSettingsSection(),
                    const SizedBox(height: 16),
                    _buildExportOptionsSection(),
                    if (_exportError != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Right: Preview
          Expanded(
            flex: 2,
            child: _buildPreviewSection(),
          ),
        ],
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
          const Icon(Icons.file_download, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Export Atlas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.of(context).pop(false),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection() {
    return _Section(
      title: 'Output',
      icon: Icons.folder_open,
      children: [
        // Output path
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Directory',
                    style: TextStyle(
                      fontSize: 11,
                      color: EditorColors.iconDisabled,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: EditorColors.inputBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: EditorColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _settings.outputPath.isEmpty
                                ? 'Select output directory...'
                                : _settings.outputPath,
                            style: TextStyle(
                              fontSize: 12,
                              color: _settings.outputPath.isEmpty
                                  ? EditorColors.iconDisabled
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.folder_open, size: 16),
                          onPressed: _selectOutputPath,
                          tooltip: 'Browse...',
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // File name
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Name',
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'atlas',
                suffixText: '.png / .json',
                suffixStyle: TextStyle(
                  fontSize: 10,
                  color: EditorColors.iconDisabled,
                ),
              ),
              onChanged: (value) {
                _updateSettings(_settings.copyWith(fileName: value));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAtlasSettingsSection() {
    return _Section(
      title: 'Atlas Settings',
      icon: Icons.grid_on,
      children: [
        // Size inputs
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Max Width',
                controller: _maxWidthController,
                suffix: 'px',
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 2048;
                  _updateSettings(_settings.copyWith(
                    atlasSettings:
                        _settings.atlasSettings.copyWith(maxWidth: intValue),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Max Height',
                controller: _maxHeightController,
                suffix: 'px',
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 2048;
                  _updateSettings(_settings.copyWith(
                    atlasSettings:
                        _settings.atlasSettings.copyWith(maxHeight: intValue),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Padding',
                controller: _paddingController,
                suffix: 'px',
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 2;
                  _updateSettings(_settings.copyWith(
                    atlasSettings:
                        _settings.atlasSettings.copyWith(padding: intValue),
                  ));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Options
        Row(
          children: [
            Expanded(
              child: _OptionChip(
                label: 'Power of 2',
                value: _settings.atlasSettings.powerOfTwo,
                onChanged: (value) {
                  _updateSettings(_settings.copyWith(
                    atlasSettings:
                        _settings.atlasSettings.copyWith(powerOfTwo: value),
                  ));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OptionChip(
                label: 'Force Square',
                value: _settings.atlasSettings.forceSquare,
                onChanged: (value) {
                  _updateSettings(_settings.copyWith(
                    atlasSettings:
                        _settings.atlasSettings.copyWith(forceSquare: value),
                  ));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportOptionsSection() {
    return _Section(
      title: 'Export Options',
      icon: Icons.settings,
      children: [
        _OptionChip(
          label: 'Export PNG',
          value: _settings.exportPng,
          onChanged: (value) {
            _updateSettings(_settings.copyWith(exportPng: value));
          },
        ),
        const SizedBox(height: 8),
        _OptionChip(
          label: 'Export JSON Metadata',
          value: _settings.exportJson,
          onChanged: (value) {
            _updateSettings(_settings.copyWith(exportJson: value));
          },
        ),
        if (_settings.exportJson) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _OptionChip(
              label: 'Pretty Print JSON',
              value: _settings.prettyPrintJson,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(prettyPrintJson: value));
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EditorColors.surface,
              border: Border(
                bottom: BorderSide(color: EditorColors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, size: 14, color: EditorColors.iconDefault),
                const SizedBox(width: 6),
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Preview content
          Expanded(
            child: _buildPreviewContent(),
          ),
          // Info footer
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EditorColors.surface,
              border: Border(
                top: BorderSide(color: EditorColors.border),
              ),
            ),
            child: _buildPreviewInfo(),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isExporting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isExporting || !_settings.isValid ? null : _performExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download, size: 16),
                    label: Text(_isExporting ? 'Exporting...' : 'Export'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_previewPackingResult == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              'No sprites to preview',
              style: TextStyle(
                color: EditorColors.iconDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final result = _previewPackingResult!;
        final scale = _calculatePreviewScale(
          result.atlasWidth,
          result.atlasHeight,
          constraints.maxWidth - 16,
          constraints.maxHeight - 16,
        );

        return Center(
          child: Container(
            width: result.atlasWidth * scale,
            height: result.atlasHeight * scale,
            decoration: BoxDecoration(
              border: Border.all(color: EditorColors.border),
            ),
            child: CustomPaint(
              painter: _AtlasPreviewPainter(
                packingResult: result,
                scale: scale,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewInfo() {
    if (_previewPackingResult == null) {
      return const SizedBox.shrink();
    }

    final result = _previewPackingResult!;
    final spriteCount = result.packedSprites.length;
    final efficiency = (result.efficiency * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          label: 'Size',
          value: '${result.atlasWidth} × ${result.atlasHeight} px',
        ),
        const SizedBox(height: 4),
        _InfoRow(
          label: 'Sprites',
          value: '$spriteCount',
        ),
        const SizedBox(height: 4),
        _InfoRow(
          label: 'Efficiency',
          value: '$efficiency%',
          valueColor: _getEfficiencyColor(result.efficiency),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EditorColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: EditorColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _exportError!,
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculatePreviewScale(
    int atlasWidth,
    int atlasHeight,
    double maxWidth,
    double maxHeight,
  ) {
    final scaleX = maxWidth / atlasWidth;
    final scaleY = maxHeight / atlasHeight;
    return (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 1.0);
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 0.8) return EditorColors.secondary;
    if (efficiency >= 0.6) return EditorColors.warning;
    return EditorColors.error;
  }
}

/// Section widget with header
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: EditorColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EditorColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EditorColors.panelBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Number input field
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
            fontSize: 10,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix,
            suffixStyle: TextStyle(
              fontSize: 10,
              color: EditorColors.iconDisabled,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Option chip toggle
class _OptionChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionChip({
    required this.label,
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
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? EditorColors.primary : EditorColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: value ? EditorColors.primary : EditorColors.iconDefault,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: value ? EditorColors.primary : EditorColors.iconDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Info row for preview footer
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: valueColor ?? EditorColors.iconDefault,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for atlas preview
class _AtlasPreviewPainter extends CustomPainter {
  final PackingResult packingResult;
  final double scale;

  _AtlasPreviewPainter({
    required this.packingResult,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw checkerboard background
    _drawCheckerboard(canvas, size);

    // Draw sprites
    final spritePaint = Paint()
      ..color = EditorColors.spriteFill.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = EditorColors.spriteBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final packed in packingResult.packedSprites) {
      final rect = Rect.fromLTWH(
        packed.x * scale,
        packed.y * scale,
        packed.width * scale,
        packed.height * scale,
      );

      canvas.drawRect(rect, spritePaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    const checkSize = 8.0;
    final paint1 = Paint()..color = const Color(0xFF3A3A3A);
    final paint2 = Paint()..color = const Color(0xFF4A4A4A);

    for (double y = 0; y < size.height; y += checkSize) {
      for (double x = 0; x < size.width; x += checkSize) {
        final isEven = ((x ~/ checkSize) + (y ~/ checkSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtlasPreviewPainter oldDelegate) {
    return packingResult != oldDelegate.packingResult ||
        scale != oldDelegate.scale;
  }
}
