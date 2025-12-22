import 'dart:ui';

import 'sprite_data.dart';

/// Simple sprite region data for POC (without freezed)
class SpriteRegion {
  final String id;
  final Rect sourceRect;
  final bool isSelected;
  final PivotPoint pivot;

  /// ID of the source file this sprite belongs to (for multi-image support)
  final String? sourceFileId;

  /// 9-slice border definition (optional)
  final NineSliceBorder? nineSlice;

  const SpriteRegion({
    required this.id,
    required this.sourceRect,
    this.isSelected = false,
    this.pivot = const PivotPoint(),
    this.sourceFileId,
    this.nineSlice,
  });

  SpriteRegion copyWith({
    String? id,
    Rect? sourceRect,
    bool? isSelected,
    PivotPoint? pivot,
    String? sourceFileId,
    NineSliceBorder? nineSlice,
    bool clearNineSlice = false,
  }) {
    return SpriteRegion(
      id: id ?? this.id,
      sourceRect: sourceRect ?? this.sourceRect,
      isSelected: isSelected ?? this.isSelected,
      pivot: pivot ?? this.pivot,
      sourceFileId: sourceFileId ?? this.sourceFileId,
      nineSlice: clearNineSlice ? null : (nineSlice ?? this.nineSlice),
    );
  }

  /// Check if 9-slice is enabled for this sprite
  bool get hasNineSlice => nineSlice != null && nineSlice!.isEnabled;

  /// Area in pixels
  int get area => (sourceRect.width * sourceRect.height).round();

  /// Width in pixels
  int get width => sourceRect.width.round();

  /// Height in pixels
  int get height => sourceRect.height.round();

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
