import 'dart:ui';

import '../models/enums/slice_mode.dart';
import '../models/sprite_region.dart';

/// Grid slicing configuration
class GridSliceConfig {
  /// Slicing mode
  final SliceMode mode;

  /// Cell width (for cellSize mode) or column count (for cellCount mode)
  final int primaryValue;

  /// Cell height (for cellSize mode) or row count (for cellCount mode)
  final int secondaryValue;

  /// X offset from image origin
  final int offsetX;

  /// Y offset from image origin
  final int offsetY;

  /// ID prefix for generated sprites
  final String idPrefix;

  const GridSliceConfig({
    required this.mode,
    required this.primaryValue,
    required this.secondaryValue,
    this.offsetX = 0,
    this.offsetY = 0,
    this.idPrefix = 'sprite',
  });

  /// Cell width in pixels
  int cellWidth(int imageWidth) {
    return mode == SliceMode.cellSize
        ? primaryValue
        : (imageWidth - offsetX) ~/ primaryValue;
  }

  /// Cell height in pixels
  int cellHeight(int imageHeight) {
    return mode == SliceMode.cellSize
        ? secondaryValue
        : (imageHeight - offsetY) ~/ secondaryValue;
  }

  /// Number of columns
  int columns(int imageWidth) {
    return mode == SliceMode.cellCount
        ? primaryValue
        : (imageWidth - offsetX) ~/ primaryValue;
  }

  /// Number of rows
  int rows(int imageHeight) {
    return mode == SliceMode.cellCount
        ? secondaryValue
        : (imageHeight - offsetY) ~/ secondaryValue;
  }
}

/// Result of grid slicing operation
class GridSliceResult {
  /// Generated sprite regions
  final List<SpriteRegion> sprites;

  /// Number of columns
  final int columns;

  /// Number of rows
  final int rows;

  /// Cell width in pixels
  final int cellWidth;

  /// Cell height in pixels
  final int cellHeight;

  const GridSliceResult({
    required this.sprites,
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
  });

  /// Total sprite count
  int get totalCount => sprites.length;
}

/// Service for grid-based image slicing
class GridSlicerService {
  const GridSlicerService();

  /// Slice image into grid cells
  ///
  /// [imageWidth] - Source image width in pixels
  /// [imageHeight] - Source image height in pixels
  /// [config] - Grid slicing configuration
  GridSliceResult sliceGrid({
    required int imageWidth,
    required int imageHeight,
    required GridSliceConfig config,
  }) {
    final cellW = config.cellWidth(imageWidth);
    final cellH = config.cellHeight(imageHeight);
    final cols = config.columns(imageWidth);
    final rows = config.rows(imageHeight);

    if (cellW <= 0 || cellH <= 0 || cols <= 0 || rows <= 0) {
      return const GridSliceResult(
        sprites: [],
        columns: 0,
        rows: 0,
        cellWidth: 0,
        cellHeight: 0,
      );
    }

    final sprites = <SpriteRegion>[];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = config.offsetX + col * cellW;
        final y = config.offsetY + row * cellH;

        // Clip to image bounds
        final clippedWidth = (x + cellW > imageWidth)
            ? imageWidth - x
            : cellW;
        final clippedHeight = (y + cellH > imageHeight)
            ? imageHeight - y
            : cellH;

        if (clippedWidth <= 0 || clippedHeight <= 0) continue;

        final id = _generateId(config.idPrefix, row, col, config.mode);

        sprites.add(SpriteRegion(
          id: id,
          sourceRect: Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            clippedWidth.toDouble(),
            clippedHeight.toDouble(),
          ),
        ));
      }
    }

    return GridSliceResult(
      sprites: sprites,
      columns: cols,
      rows: rows,
      cellWidth: cellW,
      cellHeight: cellH,
    );
  }

  /// Generate sprite ID based on mode
  String _generateId(String prefix, int row, int col, SliceMode mode) {
    // row_col format for both modes
    return '${prefix}_${row}_$col';
  }

  /// Preview grid dimensions without creating sprites
  ///
  /// Returns (columns, rows, cellWidth, cellHeight) tuple
  ({int columns, int rows, int cellWidth, int cellHeight}) previewGrid({
    required int imageWidth,
    required int imageHeight,
    required GridSliceConfig config,
  }) {
    final cellW = config.cellWidth(imageWidth);
    final cellH = config.cellHeight(imageHeight);
    final cols = config.columns(imageWidth);
    final rows = config.rows(imageHeight);

    return (
      columns: cols > 0 ? cols : 0,
      rows: rows > 0 ? rows : 0,
      cellWidth: cellW > 0 ? cellW : 0,
      cellHeight: cellH > 0 ? cellH : 0,
    );
  }

  /// Validate configuration
  String? validateConfig({
    required int imageWidth,
    required int imageHeight,
    required GridSliceConfig config,
  }) {
    if (config.mode == SliceMode.cellSize) {
      if (config.primaryValue <= 0) {
        return 'Cell width must be greater than 0';
      }
      if (config.secondaryValue <= 0) {
        return 'Cell height must be greater than 0';
      }
      if (config.primaryValue > imageWidth) {
        return 'Cell width cannot exceed image width';
      }
      if (config.secondaryValue > imageHeight) {
        return 'Cell height cannot exceed image height';
      }
    } else {
      if (config.primaryValue <= 0) {
        return 'Column count must be greater than 0';
      }
      if (config.secondaryValue <= 0) {
        return 'Row count must be greater than 0';
      }
    }

    if (config.offsetX < 0 || config.offsetX >= imageWidth) {
      return 'X offset must be between 0 and image width';
    }
    if (config.offsetY < 0 || config.offsetY >= imageHeight) {
      return 'Y offset must be between 0 and image height';
    }

    return null;
  }
}
