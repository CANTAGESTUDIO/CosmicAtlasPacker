import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../models/enums/editor_mode.dart';
import '../../models/enums/tool_mode.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/export_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/editor_colors.dart';
import '../dialogs/export_dialog.dart';

/// Editor Toolbar - 2-row layout
/// Row 1: Traffic lights + Project name (title bar)
/// Row 2: Tool buttons
class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          bottom: BorderSide(color: EditorColors.divider, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Title bar (traffic lights + project name + export)
          _buildTitleBar(context, ref),
          // Row 2: Tool buttons
          _buildToolBar(context, ref),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: Container(
        height: 28,
        color: EditorColors.surface,
        child: Row(
          children: [
            // macOS traffic light buttons space
            if (Platform.isMacOS) const SizedBox(width: 70),
            if (!Platform.isMacOS) const SizedBox(width: 8),
            // Project name with dirty indicator
            _ProjectTitle(),
            const Spacer(),
            // Mode Shop button
            OutlinedButton.icon(
              onPressed: () => _showModeShop(context),
              icon: const Icon(Icons.store_outlined, size: 16),
              label: const Text('Mode Shop'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(100, 24),
                foregroundColor: EditorColors.primary,
                side: BorderSide(color: EditorColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Export button
            FilledButton.icon(
              onPressed: () => _exportAtlas(context, ref),
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(80, 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBar(BuildContext context, WidgetRef ref) {
    final editorMode = ref.watch(editorModeProvider);
    final currentTool = ref.watch(toolModeProvider);
    final showGrid = ref.watch(showGridProvider);
    final zoomLevel = ref.watch(zoomLevelProvider);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // App icon
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 20,
              height: 20,
            ),
          ),
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
                    final currentPercent = ref.read(zoomLevelProvider);
                    final target = ZoomPresets.zoomOut(currentPercent);
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
                    final currentPercent = ref.read(zoomLevelProvider);
                    final target = ZoomPresets.zoomIn(currentPercent);
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
        ],
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: EditorColors.divider,
    );
  }

  void _showModeShop(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EditorColors.surface,
        title: Row(
          children: [
            Icon(Icons.store_outlined, color: EditorColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('Mode Shop'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '추가 에디터 모드를 구입할 수 있습니다.',
                style: TextStyle(color: EditorColors.iconDefault),
              ),
              const SizedBox(height: 16),
              _buildModeShopItem(
                icon: Icons.text_fields,
                title: 'Sprite Font Editor',
                description: '비트맵 폰트를 제작하고 내보낼 수 있는 모드',
                price: 'Coming Soon',
                isAvailable: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeShopItem({
    required IconData icon,
    required String title,
    required String description,
    required String price,
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EditorColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: EditorColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.iconDefault,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: EditorColors.iconDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable
                  ? EditorColors.primary
                  : EditorColors.iconDisabled.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              price,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isAvailable ? Colors.black : EditorColors.iconDisabled,
              ),
            ),
          ),
        ],
      ),
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

/// Editor mode toggle button (Texture Packing / Sprite Animation)
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
      height: 30,
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.grid_view_rounded,
            label: 'Texture Packing',
            tooltip: EditorMode.texturePacker.tooltip,
            isActive: currentMode == EditorMode.texturePacker,
            onPressed: () => onModeChanged(EditorMode.texturePacker),
          ),
          _ModeButton(
            icon: Icons.animation,
            label: 'Sprite Animation',
            tooltip: EditorMode.animation.tooltip,
            isActive: currentMode == EditorMode.animation,
            onPressed: () => onModeChanged(EditorMode.animation),
          ),
          _ModeButton(
            icon: Icons.text_fields,
            label: 'Sprite Font',
            tooltip: 'Sprite Font Editor (Coming Soon)',
            isActive: false,
            isEnabled: false,
            onPressed: () {},
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
  final bool isEnabled;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isActive,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Color bgColor;

    if (!isEnabled) {
      textColor = EditorColors.iconDisabled.withValues(alpha: 0.4);
      bgColor = Colors.transparent;
    } else if (isActive) {
      textColor = const Color(0xFF0F0F0F);
      bgColor = EditorColors.primary;
    } else {
      textColor = EditorColors.iconDisabled;
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Project title widget that shows name and dirty indicator
class _ProjectTitle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectTitle = ref.watch(projectTitleProvider);
    final isDirty = ref.watch(projectDirtyProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          projectTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDirty ? EditorColors.iconDefault : EditorColors.iconDisabled,
          ),
        ),
      ],
    );
  }
}
