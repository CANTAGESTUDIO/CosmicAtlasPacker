import 'dart:typed_data';
import 'dart:ui' as ui;

import 'sprite_data.dart';

/// Simple sprite region data for POC (without freezed)
class SpriteRegion {
  final String id;
  final ui.Rect sourceRect;
  final bool isSelected;
  final PivotPoint pivot;

  /// ID of the source file this sprite belongs to (for multi-image support)
  final String? sourceFileId;

  /// 9-slice border definition (optional)
  final NineSliceBorder? nineSlice;

  /// Extracted sprite image data (RGBA bytes)
  /// Stored separately from source image for independent manipulation
  final Uint8List? imageBytes;

  /// Cached ui.Image for rendering (created from imageBytes)
  final ui.Image? uiImage;

  /// Original position before any movement (for undo/reference)
  final ui.Offset? originalPosition;

  const SpriteRegion({
    required this.id,
    required this.sourceRect,
    this.isSelected = false,
    this.pivot = const PivotPoint(),
    this.sourceFileId,
    this.nineSlice,
    this.imageBytes,
    this.uiImage,
    this.originalPosition,
  });

  SpriteRegion copyWith({
    String? id,
    ui.Rect? sourceRect,
    bool? isSelected,
    PivotPoint? pivot,
    String? sourceFileId,
    NineSliceBorder? nineSlice,
    bool clearNineSlice = false,
    Uint8List? imageBytes,
    bool clearImageBytes = false,
    ui.Image? uiImage,
    bool clearUiImage = false,
    ui.Offset? originalPosition,
    bool clearOriginalPosition = false,
  }) {
    return SpriteRegion(
      id: id ?? this.id,
      sourceRect: sourceRect ?? this.sourceRect,
      isSelected: isSelected ?? this.isSelected,
      pivot: pivot ?? this.pivot,
      sourceFileId: sourceFileId ?? this.sourceFileId,
      nineSlice: clearNineSlice ? null : (nineSlice ?? this.nineSlice),
      imageBytes: clearImageBytes ? null : (imageBytes ?? this.imageBytes),
      uiImage: clearUiImage ? null : (uiImage ?? this.uiImage),
      originalPosition: clearOriginalPosition ? null : (originalPosition ?? this.originalPosition),
    );
  }

  /// Check if this sprite has extracted image data
  bool get hasImageData => imageBytes != null && imageBytes!.isNotEmpty;

  /// Check if 9-slice is enabled for this sprite
  bool get hasNineSlice => nineSlice != null && nineSlice!.isEnabled;

  /// Area in pixels
  int get area => (sourceRect.width * sourceRect.height).round();

  /// Width in pixels
  int get width => sourceRect.width.round();

  /// Height in pixels
  int get height => sourceRect.height.round();

  /// Get pivot position in canvas coordinates
  ui.Offset get pivotPosition {
    final x = sourceRect.left + sourceRect.width * pivot.x;
    final y = sourceRect.top + sourceRect.height * pivot.y;
    return ui.Offset(x, y);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpriteRegion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceRect == other.sourceRect &&
          isSelected == other.isSelected &&
          pivot == other.pivot &&
          sourceFileId == other.sourceFileId &&
          nineSlice == other.nineSlice;

  @override
  int get hashCode => Object.hash(id, sourceRect, isSelected, pivot, sourceFileId, nineSlice);

  @override
  String toString() => 'SpriteRegion(id: $id, rect: $sourceRect)';
}
