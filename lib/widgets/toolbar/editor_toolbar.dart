import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums/tool_mode.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/export_provider.dart';
import '../../theme/editor_colors.dart';

/// Editor Toolbar - tool mode selection and zoom controls
class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(toolModeProvider);
    final showGrid = ref.watch(showGridProvider);
    final zoomLevel = ref.watch(zoomLevelProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          bottom: BorderSide(color: EditorColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Tool mode buttons
          _ToolButton(
            icon: Icons.near_me_outlined,
            tooltip: 'Select (V)',
            isActive: currentTool == ToolMode.select,
            onPressed: () =>
                ref.read(toolModeProvider.notifier).state = ToolMode.select,
          ),
          _ToolButton(
            icon: Icons.crop_square_outlined,
            tooltip: 'Rectangle Slice (R)',
            isActive: currentTool == ToolMode.rectSlice,
            onPressed: () =>
                ref.read(toolModeProvider.notifier).state = ToolMode.rectSlice,
          ),
          _ToolButton(
            icon: Icons.flash_on_outlined,
            tooltip: 'Auto Slice (A)',
            onPressed: () {
              ref.read(showAutoSliceDialogProvider)?.call();
            },
          ),
          _ToolButton(
            icon: Icons.grid_on_outlined,
            tooltip: 'Grid Slice (G)',
            onPressed: () {
              ref.read(showGridSliceDialogProvider)?.call();
            },
          ),
          _ToolButton(
            icon: Icons.format_color_reset,
            tooltip: '배경색 제거 (B)',
            onPressed: () {
              ref.read(showBackgroundRemoveDialogProvider)?.call();
            },
          ),

          // Divider
          _toolbarDivider(),

          // Zoom controls
          _ToolButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            onPressed: zoomLevel <= ZoomPresets.min
                ? null
                : () {
                    // Use zoomLevelProvider as the source of truth
                    final currentPercent = ref.read(zoomLevelProvider);
                    final target = ZoomPresets.zoomOut(currentPercent);
                    // Apply zoom via callback (SourceImageViewer will update provider)
                    final setZoom = ref.read(setZoomCallbackProvider);
                    setZoom?.call(target);
                  },
          ),
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '${zoomLevel.round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EditorColors.iconDefault,
                  ),
            ),
          ),
          _ToolButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            onPressed: zoomLevel >= ZoomPresets.max
                ? null
                : () {
                    // Use zoomLevelProvider as the source of truth
                    final currentPercent = ref.read(zoomLevelProvider);
                    final target = ZoomPresets.zoomIn(currentPercent);
                    // Apply zoom via callback (SourceImageViewer will update provider)
                    final setZoom = ref.read(setZoomCallbackProvider);
                    setZoom?.call(target);
                  },
          ),

          // Divider
          _toolbarDivider(),

          // Grid toggle
          _ToolButton(
            icon: showGrid ? Icons.grid_on : Icons.grid_off,
            tooltip: 'Toggle Grid',
            isActive: showGrid,
            onPressed: () =>
                ref.read(showGridProvider.notifier).state = !showGrid,
          ),

          const Spacer(),

          // Export button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: () => _exportAtlas(context, ref),
              icon: Transform.translate(
                offset: const Offset(0, -1),
                child: const Icon(Icons.file_download_outlined, size: 18),
              ),
              label: Transform.translate(
                offset: const Offset(-3, -1),
                child: const Text('Export'),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(100, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: EditorColors.divider,
    );
  }

  Future<void> _exportAtlas(BuildContext context, WidgetRef ref) async {
    final canExport = ref.read(canExportProvider);

    debugPrint('[Export] canExport: $canExport');

    if (!canExport) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please open an image and create sprites first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await ref.read(exportNotifierProvider.notifier).exportWithDialog();

    if (!context.mounted) return;

    final exportState = ref.read(exportNotifierProvider);

    if (success && exportState.lastPngPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported: ${exportState.lastPngPath!.split('/').last}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (exportState.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${exportState.lastError}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive
              ? EditorColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 18,
            color: isActive ? EditorColors.iconActive : EditorColors.iconDefault,
          ),
          padding: EdgeInsets.zero,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
