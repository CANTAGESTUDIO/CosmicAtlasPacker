import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Grid preview state for real-time visualization in source panel
@immutable
class GridPreviewState {
  /// Whether the grid preview is active (dialog is open)
  final bool isActive;

  /// Source image width (boundary constraint)
  final int imageWidth;

  /// Source image height (boundary constraint)
  final int imageHeight;

  /// Number of columns in the grid
  final int columns;

  /// Number of rows in the grid
  final int rows;

  /// Width of each cell in pixels
  final int cellWidth;

  /// Height of each cell in pixels
  final int cellHeight;

  /// X offset from the left edge
  final int offsetX;

  /// Y offset from the top edge
  final int offsetY;

  /// Whether to show grid lines
  final bool showGridLines;

  /// Whether to show cell numbers
  final bool showCellNumbers;

  /// Number format for cell labels ('001', '01', '1')
  final String numberFormat;

  /// ID prefix for cell labels
  final String idPrefix;

  const GridPreviewState({
    this.isActive = false,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.columns = 0,
    this.rows = 0,
    this.cellWidth = 64,
    this.cellHeight = 64,
    this.offsetX = 0,
    this.offsetY = 0,
    this.showGridLines = true,
    this.showCellNumbers = false,
    this.numberFormat = '001',
    this.idPrefix = 'sprite',
  });

  GridPreviewState copyWith({
    bool? isActive,
    int? imageWidth,
    int? imageHeight,
    int? columns,
    int? rows,
    int? cellWidth,
    int? cellHeight,
    int? offsetX,
    int? offsetY,
    bool? showGridLines,
    bool? showCellNumbers,
    String? numberFormat,
    String? idPrefix,
  }) {
    return GridPreviewState(
      isActive: isActive ?? this.isActive,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      cellWidth: cellWidth ?? this.cellWidth,
      cellHeight: cellHeight ?? this.cellHeight,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      showGridLines: showGridLines ?? this.showGridLines,
      showCellNumbers: showCellNumbers ?? this.showCellNumbers,
      numberFormat: numberFormat ?? this.numberFormat,
      idPrefix: idPrefix ?? this.idPrefix,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridPreviewState &&
        other.isActive == isActive &&
        other.imageWidth == imageWidth &&
        other.imageHeight == imageHeight &&
        other.columns == columns &&
        other.rows == rows &&
        other.cellWidth == cellWidth &&
        other.cellHeight == cellHeight &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.showGridLines == showGridLines &&
        other.showCellNumbers == showCellNumbers &&
        other.numberFormat == numberFormat &&
        other.idPrefix == idPrefix;
  }

  @override
  int get hashCode {
    return Object.hash(
      isActive,
      imageWidth,
      imageHeight,
      columns,
      rows,
      cellWidth,
      cellHeight,
      offsetX,
      offsetY,
      showGridLines,
      showCellNumbers,
      numberFormat,
      idPrefix,
    );
  }
}

/// Provider for grid preview state
/// Used by GridSliceDialog to update preview and GridPreviewOverlay to display it
final gridPreviewProvider = StateProvider<GridPreviewState>(
  (ref) => const GridPreviewState(),
);
