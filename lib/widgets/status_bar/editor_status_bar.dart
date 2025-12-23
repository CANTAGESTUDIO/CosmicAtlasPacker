import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums/tool_mode.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/packing_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Editor Status Bar - displays sprite count, atlas size, memory usage, current tool
class EditorStatusBar extends ConsumerWidget {
  const EditorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(toolModeProvider);
    final spriteCount = ref.watch(totalSpriteCountProvider);
    final selectedCount = ref.watch(selectedSpriteCountProvider);
    final atlasSize = ref.watch(atlasSizeProvider);
    final efficiency = ref.watch(packingEfficiencyProvider);
    final memoryUsage = ref.watch(memoryUsageDisplayProvider);

    final atlasSizeLabel = atlasSize.$1 > 0
        ? '${atlasSize.$1}x${atlasSize.$2}'
        : '--';

    final efficiencyLabel = efficiency > 0
        ? '${efficiency.toStringAsFixed(1)}%'
        : '--';

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          top: BorderSide(color: EditorColors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _StatusItem(
            icon: Icons.layers_outlined,
            label: selectedCount > 0
                ? '$selectedCount / $spriteCount sprites'
                : '$spriteCount sprites',
          ),
          _statusDivider(),
          _StatusItem(
            icon: Icons.aspect_ratio_outlined,
            label: 'Atlas: $atlasSizeLabel',
          ),
          _statusDivider(),
          _StatusItem(
            icon: Icons.pie_chart_outline,
            label: 'Efficiency: $efficiencyLabel',
          ),
          _statusDivider(),
          _StatusItem(
            icon: Icons.memory_outlined,
            label: 'Memory: $memoryUsage',
          ),
          const Spacer(),
          _StatusItem(
            icon: Icons.build_outlined,
            label: 'Tool: ${_toolName(currentTool)}',
          ),
        ],
      ),
    );
  }

  String _toolName(ToolMode mode) {
    switch (mode) {
      case ToolMode.select:
        return 'Select';
      case ToolMode.rectSlice:
        return 'Rect Slice';
    }
  }

  Widget _statusDivider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: EditorColors.divider,
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: EditorColors.iconDisabled,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EditorColors.iconDefault,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

/// Zoom indicator with dropdown for presets
class _ZoomIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomLabel = ref.watch(zoomDisplayLabelProvider);
    final setZoomCallback = ref.watch(setZoomCallbackProvider);
    final fitToWindowCallback = ref.watch(fitToWindowCallbackProvider);
    final resetZoomCallback = ref.watch(resetZoomCallbackProvider);

    return PopupMenuButton<double>(
      tooltip: 'Zoom level',
      offset: const Offset(0, -200),
      color: EditorColors.surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.zoom_in,
            size: 14,
            color: EditorColors.iconDisabled,
          ),
          const SizedBox(width: 4),
          Text(
            zoomLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EditorColors.iconDefault,
                  fontSize: 11,
                ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_up,
            size: 14,
            color: EditorColors.iconDisabled,
          ),
        ],
      ),
      itemBuilder: (context) => [
        // Fit to window option
        PopupMenuItem<double>(
          value: -1,
          enabled: fitToWindowCallback != null,
          child: Row(
            children: [
              const Icon(Icons.fit_screen, size: 16),
              const SizedBox(width: 8),
              const Text('Fit to Window'),
              const Spacer(),
              Text(
                'Cmd+1',
                style: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ],
          ),
        ),
        // Reset zoom option
        PopupMenuItem<double>(
          value: 0,
          enabled: resetZoomCallback != null,
          child: Row(
            children: [
              const Icon(Icons.restart_alt, size: 16),
              const SizedBox(width: 8),
              const Text('Reset Zoom'),
              const Spacer(),
              Text(
                'Cmd+0',
                style: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Preset zoom levels
        ...ZoomPresets.values.map((preset) => PopupMenuItem<double>(
              value: preset,
              enabled: setZoomCallback != null,
              child: Text('${preset.round()}%'),
            )),
      ],
      onSelected: (value) {
        if (value == -1) {
          // Fit to window
          fitToWindowCallback?.call();
        } else if (value == 0) {
          // Reset zoom
          resetZoomCallback?.call();
        } else {
          // Set to preset
          setZoomCallback?.call(value);
        }
      },
    );
  }
}
