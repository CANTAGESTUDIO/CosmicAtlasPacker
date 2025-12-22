import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums/pivot_preset.dart';

part 'sprite_data.freezed.dart';
part 'sprite_data.g.dart';

/// Individual sprite information
@freezed
class SpriteData with _$SpriteData {
  const factory SpriteData({
    /// Unique sprite ID
    required String id,

    /// Source file path (original image)
    required String sourceFile,

    /// Rectangle in source image (x, y, width, height)
    required SpriteRect sourceRect,

    /// Rectangle in packed atlas (set after packing)
    SpriteRect? packedRect,

    /// Pivot point (normalized 0.0 ~ 1.0)
    @Default(PivotPoint()) PivotPoint pivot,

    /// 9-slice border (optional)
    NineSliceBorder? nineSlice,
  }) = _SpriteData;

  factory SpriteData.fromJson(Map<String, dynamic> json) =>
      _$SpriteDataFromJson(json);
}

/// Rectangle data for sprites
@freezed
class SpriteRect with _$SpriteRect {
  const SpriteRect._();

  const factory SpriteRect({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _SpriteRect;

  factory SpriteRect.fromJson(Map<String, dynamic> json) =>
      _$SpriteRectFromJson(json);

  /// Convert to dart:ui Rect
  Rect toRect() => Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      );

  /// Create from dart:ui Rect
  factory SpriteRect.fromRect(Rect rect) => SpriteRect(
        x: rect.left.round(),
        y: rect.top.round(),
        width: rect.width.round(),
        height: rect.height.round(),
      );

  /// Area in pixels
  int get area => width * height;
}

/// Pivot point with preset and custom values
@freezed
class PivotPoint with _$PivotPoint {
  const factory PivotPoint({
    @Default(0.5) double x,
    @Default(0.5) double y,
    @Default(PivotPreset.center) PivotPreset preset,
  }) = _PivotPoint;

  factory PivotPoint.fromJson(Map<String, dynamic> json) =>
      _$PivotPointFromJson(json);

  factory PivotPoint.fromPreset(PivotPreset preset) => PivotPoint(
        x: preset.x,
        y: preset.y,
        preset: preset,
      );
}

/// 9-slice border definition
@freezed
class NineSliceBorder with _$NineSliceBorder {
  const NineSliceBorder._();

  const factory NineSliceBorder({
    @Default(0) int left,
    @Default(0) int right,
    @Default(0) int top,
    @Default(0) int bottom,
  }) = _NineSliceBorder;

  factory NineSliceBorder.fromJson(Map<String, dynamic> json) =>
      _$NineSliceBorderFromJson(json);

  /// Check if 9-slice is enabled (any border > 0)
  bool get isEnabled => left > 0 || right > 0 || top > 0 || bottom > 0;

  /// Total horizontal border size
  int get horizontalBorder => left + right;

  /// Total vertical border size
  int get verticalBorder => top + bottom;

  /// Validate borders against sprite size
  bool isValidForSize(int width, int height) {
    if (left < 0 || right < 0 || top < 0 || bottom < 0) return false;
    if (horizontalBorder >= width) return false;
    if (verticalBorder >= height) return false;
    return true;
  }

  /// Get center region width (for a given sprite width)
  int centerWidth(int spriteWidth) => spriteWidth - horizontalBorder;

  /// Get center region height (for a given sprite height)
  int centerHeight(int spriteHeight) => spriteHeight - verticalBorder;

  /// Clamp borders to valid range for given size
  NineSliceBorder clampToSize(int width, int height) {
    final maxH = (width - 2).clamp(0, width); // Leave at least 2px center
    final maxV = (height - 2).clamp(0, height);

    return NineSliceBorder(
      left: left.clamp(0, maxH - right.clamp(0, maxH)),
      right: right.clamp(0, maxH - left.clamp(0, maxH)),
      top: top.clamp(0, maxV - bottom.clamp(0, maxV)),
      bottom: bottom.clamp(0, maxV - top.clamp(0, maxV)),
    );
  }
}
