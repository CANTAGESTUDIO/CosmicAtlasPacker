import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums/tool_mode.dart';

/// Current tool mode state
final toolModeProvider = StateProvider<ToolMode>((ref) => ToolMode.select);

/// Grid overlay visibility state
final showGridProvider = StateProvider<bool>((ref) => false);

/// Grid size in pixels
final gridSizeProvider = StateProvider<double>((ref) => 32.0);

/// Zoom level state (percentage)
final zoomLevelProvider = StateProvider<double>((ref) => 100.0);

/// Current transformation matrix from canvas
final canvasTransformProvider = StateProvider<Matrix4?>((ref) => null);

/// Zoom presets for quick access
class ZoomPresets {
  static const List<double> values = [25, 50, 100, 200, 400, 800];
  static const double min = 25;
  static const double max = 800;
  static const double step = 25;
  static const double defaultValue = 100;

  /// Snap zoom value to nearest step for consistency
  static double snapToStep(double value) {
    return (value / step).round() * step;
  }

  /// Get next zoom level (zoom in)
  static double zoomIn(double current) {
    final snapped = snapToStep(current);
    return (snapped + step).clamp(min, max);
  }

  /// Get previous zoom level (zoom out)
  static double zoomOut(double current) {
    final snapped = snapToStep(current);
    return (snapped - step).clamp(min, max);
  }
}

/// Provider for current zoom percentage display label
final zoomDisplayLabelProvider = Provider<String>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return '${zoom.round()}%';
});

/// Provider for fit to window callback (set by SourceImageViewer)
final fitToWindowCallbackProvider = StateProvider<VoidCallback?>((ref) => null);

/// Provider for reset zoom callback (set by SourceImageViewer)
final resetZoomCallbackProvider = StateProvider<VoidCallback?>((ref) => null);

/// Provider for set zoom callback (set by SourceImageViewer)
final setZoomCallbackProvider = StateProvider<void Function(double)?>(
  (ref) => null,
);

/// Space key pressed state (for pan mode)
final isSpacePressedProvider = StateProvider<bool>((ref) => false);

/// Provider for Auto Slice dialog callback (set by EditorScreen)
final showAutoSliceDialogProvider = StateProvider<VoidCallback?>((ref) => null);

/// Provider for Grid Slice dialog callback (set by EditorScreen)
final showGridSliceDialogProvider = StateProvider<VoidCallback?>((ref) => null);

/// Provider for Background Remove dialog callback (set by EditorScreen)
final showBackgroundRemoveDialogProvider = StateProvider<VoidCallback?>((ref) => null);

/// Sprite panel thumbnail zoom level (percentage)
/// Controls the size of sprite thumbnails in the bottom panel
final spriteThumbnailZoomProvider = StateProvider<double>((ref) => 100.0);

/// Sprite thumbnail zoom presets
class SpriteThumbnailZoomPresets {
  static const List<double> values = [50, 75, 100, 125, 150, 200];
  static const double min = 50;
  static const double max = 200;
  static const double step = 25;
  static const double defaultValue = 100;

  /// Get next zoom level (zoom in)
  static double zoomIn(double current) {
    final index = values.indexOf(current);
    if (index == -1) {
      // Find nearest higher value
      for (final value in values) {
        if (value > current) return value;
      }
      return max;
    }
    return index < values.length - 1 ? values[index + 1] : max;
  }

  /// Get previous zoom level (zoom out)
  static double zoomOut(double current) {
    final index = values.indexOf(current);
    if (index == -1) {
      // Find nearest lower value
      for (int i = values.length - 1; i >= 0; i--) {
        if (values[i] < current) return values[i];
      }
      return min;
    }
    return index > 0 ? values[index - 1] : min;
  }
}
