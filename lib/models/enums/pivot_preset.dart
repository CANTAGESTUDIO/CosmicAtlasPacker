/// Pivot point presets (3x3 grid + custom)
enum PivotPreset {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  custom,
}

extension PivotPresetExtension on PivotPreset {
  /// Get normalized X coordinate (0.0 ~ 1.0)
  double get x {
    return switch (this) {
      PivotPreset.topLeft ||
      PivotPreset.centerLeft ||
      PivotPreset.bottomLeft =>
        0.0,
      PivotPreset.topCenter ||
      PivotPreset.center ||
      PivotPreset.bottomCenter =>
        0.5,
      PivotPreset.topRight ||
      PivotPreset.centerRight ||
      PivotPreset.bottomRight =>
        1.0,
      PivotPreset.custom => 0.5,
    };
  }

  /// Get normalized Y coordinate (0.0 ~ 1.0)
  double get y {
    return switch (this) {
      PivotPreset.topLeft ||
      PivotPreset.topCenter ||
      PivotPreset.topRight =>
        0.0,
      PivotPreset.centerLeft ||
      PivotPreset.center ||
      PivotPreset.centerRight =>
        0.5,
      PivotPreset.bottomLeft ||
      PivotPreset.bottomCenter ||
      PivotPreset.bottomRight =>
        1.0,
      PivotPreset.custom => 0.5,
    };
  }
}
