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
  static const List<double> values = [100, 125, 150, 175, 200, 250, 300, 400];
  static const double min = 100;
  static const double max = 400;
  static const double step = 25;
  static const double defaultValue = 100;

  /// Snap zoom value to nearest step for consistency
  static double snapToStep(double value) {
    return (value / step).round() * step;
  }

  /// Get next zoom level (zoom in)
  /// Returns the next 25% step greater than current
  static double zoomIn(double current) {
    // 현재값보다 큰 첫번째 25% step 찾기
    for (double value = min; value <= max; value += step) {
      if (value > current + 0.5) return value; // 0.5 tolerance
    }
    return max;
  }

  /// Get previous zoom level (zoom out)
  /// Returns the previous 25% step less than current
  static double zoomOut(double current) {
    // 현재값보다 작은 마지막 25% step 찾기
    for (double value = max; value >= min; value -= step) {
      if (value < current - 0.5) return value; // 0.5 tolerance
    }
    return min;
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
