import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums/editor_mode.dart';
import '../../models/enums/tool_mode.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/export_provider.dart';
import '../../theme/editor_colors.dart';
import '../dialogs/export_dialog.dart';

/// Editor Toolbar - tool mode selection and zoom controls
class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorMode = ref.watch(editorModeProvider);
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
          // Editor mode toggle (Texture Packer / Animation)
          _EditorModeToggle(
            currentMode: editorMode,
            onModeChanged: (mode) {
              ref.read(editorModeProvider.notifier).state = mode;
            },
          ),

          // Divider
          _toolbarDivider(),

          // Tool mode buttons (disabled in animation mode)
          _ToolButton(
            icon: Icons.near_me_outlined,
            tooltip: 'Select (V)',
            isActive: currentTool == ToolMode.select,
            isEnabled: editorMode != EditorMode.animation,
            onPressed: editorMode == EditorMode.animation
                ? null
                : () =>
                    ref.read(toolModeProvider.notifier).state = ToolMode.select,
          ),
          _ToolButton(
            icon: Icons.crop_square_outlined,
            tooltip: 'Rectangle Slice (R)',
            isActive: currentTool == ToolMode.rectSlice,
            isEnabled: editorMode != EditorMode.animation,
            onPressed: editorMode == EditorMode.animation
                ? null
                : () =>
                    ref.read(toolModeProvider.notifier).state = ToolMode.rectSlice,
          ),
          _ToolButton(
            icon: Icons.flash_on_outlined,
            tooltip: 'Auto Slice (A)',
            isEnabled: editorMode != EditorMode.animation,
            onPressed: editorMode == EditorMode.animation
                ? null
                : () {
                    ref.read(showAutoSliceDialogProvider)?.call();
                  },
          ),
          _ToolButton(
            icon: Icons.grid_on_outlined,
            tooltip: 'Grid Slice (G)',
            isEnabled: editorMode != EditorMode.animation,
            onPressed: editorMode == EditorMode.animation
                ? null
                : () {
                    ref.read(showGridSliceDialogProvider)?.call();
                  },
          ),
          _ToolButton(
            icon: Icons.format_color_reset,
            tooltip: '배경색 제거 (B)',
            isEnabled: editorMode != EditorMode.animation,
            onPressed: editorMode == EditorMode.animation
                ? null
                : () {
                    ref.read(showBackgroundRemoveDialogProvider)?.call();
                  },
          ),

          // Divider
          _toolbarDivider(),

          // Zoom controls (disabled in animation mode)
          _ToolButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            isEnabled: editorMode != EditorMode.animation,
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
                    color: editorMode == EditorMode.animation
                        ? EditorColors.iconDisabled
                        : EditorColors.iconDefault,
                  ),
            ),
          ),
          _ToolButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            isEnabled: editorMode != EditorMode.animation,
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

          // Grid toggle (disabled in animation mode)
          _ToolButton(
            icon: showGrid ? Icons.grid_on : Icons.grid_off,
            tooltip: 'Toggle Grid',
            isActive: showGrid,
            isEnabled: editorMode != EditorMode.animation,
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

    // ExportDialog를 표시하고 결과를 받음
    final success = await ExportDialog.show(context);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내보내기 완료'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isEnabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isEnabled
        ? (isActive ? EditorColors.iconActive : EditorColors.iconDefault)
        : EditorColors.iconDisabled;

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
            color: iconColor,
          ),
          padding: EdgeInsets.zero,
          onPressed: isEnabled ? onPressed : null,
        ),
      ),
    );
  }
}

/// Editor mode toggle button (Texture Packer / Animation)
class _EditorModeToggle extends StatelessWidget {
  final EditorMode currentMode;
  final ValueChanged<EditorMode> onModeChanged;

  const _EditorModeToggle({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.grid_view_rounded,
            label: '패커',
            tooltip: EditorMode.texturePacker.tooltip,
            isActive: currentMode == EditorMode.texturePacker,
            onPressed: () => onModeChanged(EditorMode.texturePacker),
          ),
          Container(
            width: 1,
            height: 20,
            color: EditorColors.border,
          ),
          _ModeButton(
            icon: Icons.animation,
            label: '애니',
            tooltip: EditorMode.animation.tooltip,
            isActive: currentMode == EditorMode.animation,
            onPressed: () => onModeChanged(EditorMode.animation),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? EditorColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? EditorColors.primary : EditorColors.iconDefault,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? EditorColors.primary : EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
