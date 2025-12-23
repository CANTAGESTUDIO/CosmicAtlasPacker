import 'dart:math' as math;
import 'dart:ui';

import '../models/sprite_region.dart';

/// Result of packing a single sprite
class PackedSprite {
  final SpriteRegion sprite;
  final Rect packedRect;
  final int rotation; // 0, 90, 180, 270 degrees

  const PackedSprite({
    required this.sprite,
    required this.packedRect,
    this.rotation = 0,
  });

  int get x => packedRect.left.round();
  int get y => packedRect.top.round();
  int get width => packedRect.width.round();
  int get height => packedRect.height.round();

  /// Whether this sprite was rotated during packing
  bool get isRotated => rotation != 0;
}

/// Result of the bin packing operation
class PackingResult {
  final List<PackedSprite> packedSprites;
  final int atlasWidth;
  final int atlasHeight;
  final List<SpriteRegion> failedSprites;

  const PackingResult({
    required this.packedSprites,
    required this.atlasWidth,
    required this.atlasHeight,
    this.failedSprites = const [],
  });

  /// Calculate packing efficiency (0.0 ~ 1.0)
  double get efficiency {
    if (atlasWidth == 0 || atlasHeight == 0) return 0.0;

    final totalSpriteArea = packedSprites.fold<int>(
      0,
      (sum, packed) => sum + (packed.width * packed.height),
    );

    final atlasArea = atlasWidth * atlasHeight;
    return totalSpriteArea / atlasArea;
  }

  /// Check if all sprites were packed successfully
  /// Returns true only if there are packed sprites AND no failed sprites
  bool get isComplete => packedSprites.isNotEmpty && failedSprites.isEmpty;
}

/// MaxRects bin packing algorithm with Best Short Side Fit heuristic
///
/// Implements:
/// - MaxRects data structure for free rectangle management
/// - BSSF (Best Short Side Fit) heuristic for optimal placement
/// - Guillotine split for free area subdivision
/// - Area-based descending sort before packing
class BinPackingService {
  /// Pack sprites into an atlas using MaxRects algorithm
  ///
  /// [sprites] - List of sprite regions to pack
  /// [maxWidth] - Maximum atlas width (default 4096)
  /// [maxHeight] - Maximum atlas height (default 4096)
  /// [padding] - Padding between sprites (default 0)
  /// [powerOfTwo] - Ensure atlas dimensions are power of two
  /// [allowRotation] - Allow 90 degree rotation for better packing
  PackingResult pack(
    List<SpriteRegion> sprites, {
    int maxWidth = 4096,
    int maxHeight = 4096,
    int padding = 0,
    bool powerOfTwo = false,
    bool allowRotation = false,
  }) {
    if (sprites.isEmpty) {
      return const PackingResult(
        packedSprites: [],
        atlasWidth: 0,
        atlasHeight: 0,
      );
    }

    // Sort sprites by area (descending) for better packing
    final sortedSprites = _sortByAreaDescending(sprites);

    // Ensure minimum size can fit largest sprite
    final maxSpriteWidth = sortedSprites.map((s) => s.width + padding * 2).reduce((a, b) => a > b ? a : b);
    final maxSpriteHeight = sortedSprites.map((s) => s.height + padding * 2).reduce((a, b) => a > b ? a : b);

    // Start with smallest power-of-2 that fits largest sprite
    int atlasWidth = _nextPowerOfTwo(maxSpriteWidth);
    int atlasHeight = _nextPowerOfTwo(maxSpriteHeight);

    // Try packing, grow atlas if needed
    PackingResult? result;
    while (atlasWidth <= maxWidth && atlasHeight <= maxHeight) {
      result = _tryPack(sortedSprites, atlasWidth, atlasHeight, padding, allowRotation);

      if (result.isComplete) {
        // Shrink atlas to minimum required size
        final shrunkResult = _shrinkAtlas(result, powerOfTwo);
        return shrunkResult;
      }

      // Grow atlas
      if (atlasWidth <= atlasHeight) {
        atlasWidth = powerOfTwo ? atlasWidth * 2 : atlasWidth + 256;
      } else {
        atlasHeight = powerOfTwo ? atlasHeight * 2 : atlasHeight + 256;
      }
    }

    // Return partial result if we hit max size
    return result ?? const PackingResult(
      packedSprites: [],
      atlasWidth: 0,
      atlasHeight: 0,
      failedSprites: [],
    );
  }

  /// Sort sprites by area in descending order
  List<SpriteRegion> _sortByAreaDescending(List<SpriteRegion> sprites) {
    final sorted = List<SpriteRegion>.from(sprites);
    sorted.sort((a, b) => b.area.compareTo(a.area));
    return sorted;
  }

  /// Try to pack all sprites into given atlas dimensions
  PackingResult _tryPack(
    List<SpriteRegion> sprites,
    int atlasWidth,
    int atlasHeight,
    int padding,
    bool allowRotation,
  ) {
    // Initialize free rectangles with full atlas area
    final freeRects = <Rect>[
      Rect.fromLTWH(0, 0, atlasWidth.toDouble(), atlasHeight.toDouble()),
    ];

    final packedSprites = <PackedSprite>[];
    final failedSprites = <SpriteRegion>[];

    for (final sprite in sprites) {
      final spriteWidth = sprite.width + padding * 2;
      final spriteHeight = sprite.height + padding * 2;

      // Find best position using BSSF heuristic (with optional rotation)
      final placement = _findBestPositionWithRotation(
        freeRects,
        spriteWidth,
        spriteHeight,
        allowRotation,
      );

      if (placement != null) {
        final isRotated = placement.rotation == 90;
        final actualWidth = isRotated ? sprite.height : sprite.width;
        final actualHeight = isRotated ? sprite.width : sprite.height;

        // Calculate actual sprite position (accounting for padding)
        final packedRect = Rect.fromLTWH(
          placement.rect.left + padding,
          placement.rect.top + padding,
          actualWidth.toDouble(),
          actualHeight.toDouble(),
        );

        packedSprites.add(PackedSprite(
          sprite: sprite,
          packedRect: packedRect,
          rotation: placement.rotation,
        ));

        // Split free rectangles (Guillotine method)
        final usedWidth = isRotated ? spriteHeight : spriteWidth;
        final usedHeight = isRotated ? spriteWidth : spriteHeight;
        _splitFreeRects(freeRects, Rect.fromLTWH(
          placement.rect.left,
          placement.rect.top,
          usedWidth.toDouble(),
          usedHeight.toDouble(),
        ));

        // Prune overlapping free rectangles
        _pruneFreeRects(freeRects);
      } else {
        failedSprites.add(sprite);
      }
    }

    return PackingResult(
      packedSprites: packedSprites,
      atlasWidth: atlasWidth,
      atlasHeight: atlasHeight,
      failedSprites: failedSprites,
    );
  }

  /// Result of finding best position (includes rotation info)
  _PlacementResult? _findBestPositionWithRotation(
    List<Rect> freeRects,
    int spriteWidth,
    int spriteHeight,
    bool allowRotation,
  ) {
    _PlacementResult? bestResult;
    int bestShortSide = 0x7FFFFFFF;
    int bestLongSide = 0x7FFFFFFF;

    // Try original orientation
    final normalResult = _findBestPosition(freeRects, spriteWidth, spriteHeight);
    if (normalResult != null) {
      final leftoverX = (normalResult.width - spriteWidth).round();
      final leftoverY = (normalResult.height - spriteHeight).round();
      final shortSide = leftoverX < leftoverY ? leftoverX : leftoverY;
      final longSide = leftoverX > leftoverY ? leftoverX : leftoverY;

      bestResult = _PlacementResult(
        rect: Rect.fromLTWH(normalResult.left, normalResult.top, spriteWidth.toDouble(), spriteHeight.toDouble()),
        rotation: 0,
      );
      bestShortSide = shortSide;
      bestLongSide = longSide;
    }

    // Try 90 degree rotation if allowed and sprite is not square
    if (allowRotation && spriteWidth != spriteHeight) {
      final rotatedResult = _findBestPosition(freeRects, spriteHeight, spriteWidth);
      if (rotatedResult != null) {
        final leftoverX = (rotatedResult.width - spriteHeight).round();
        final leftoverY = (rotatedResult.height - spriteWidth).round();
        final shortSide = leftoverX < leftoverY ? leftoverX : leftoverY;
        final longSide = leftoverX > leftoverY ? leftoverX : leftoverY;

        // Use rotated if it's a better fit
        if (shortSide < bestShortSide ||
            (shortSide == bestShortSide && longSide < bestLongSide)) {
          bestResult = _PlacementResult(
            rect: Rect.fromLTWH(rotatedResult.left, rotatedResult.top, spriteHeight.toDouble(), spriteWidth.toDouble()),
            rotation: 90,
          );
        }
      }
    }

    return bestResult;
  }

  /// Find best position using Best Short Side Fit heuristic
  /// Returns the position rect or null if no fit found
  Rect? _findBestPosition(
    List<Rect> freeRects,
    int spriteWidth,
    int spriteHeight,
  ) {
    Rect? bestRect;
    int bestShortSide = 0x7FFFFFFF; // Max int
    int bestLongSide = 0x7FFFFFFF;

    for (final freeRect in freeRects) {
      // Check if sprite fits in this free rect
      if (spriteWidth <= freeRect.width && spriteHeight <= freeRect.height) {
        final leftoverX = (freeRect.width - spriteWidth).round();
        final leftoverY = (freeRect.height - spriteHeight).round();

        final shortSide = leftoverX < leftoverY ? leftoverX : leftoverY;
        final longSide = leftoverX > leftoverY ? leftoverX : leftoverY;

        // BSSF: minimize the shorter leftover side
        if (shortSide < bestShortSide ||
            (shortSide == bestShortSide && longSide < bestLongSide)) {
          bestRect = Rect.fromLTWH(
            freeRect.left,
            freeRect.top,
            spriteWidth.toDouble(),
            spriteHeight.toDouble(),
          );
          bestShortSide = shortSide;
          bestLongSide = longSide;
        }
      }
    }

    return bestRect;
  }

  /// Split free rectangles using Guillotine method
  /// Removes overlapping areas and creates new free rects
  void _splitFreeRects(List<Rect> freeRects, Rect usedRect) {
    final newFreeRects = <Rect>[];

    for (int i = freeRects.length - 1; i >= 0; i--) {
      final freeRect = freeRects[i];

      // Check if this free rect overlaps with used rect
      if (!_rectsOverlap(freeRect, usedRect)) {
        continue;
      }

      // Remove this rect and split it
      freeRects.removeAt(i);

      // Generate new free rects from the split
      // Left side
      if (usedRect.left > freeRect.left) {
        newFreeRects.add(Rect.fromLTRB(
          freeRect.left,
          freeRect.top,
          usedRect.left,
          freeRect.bottom,
        ));
      }

      // Right side
      if (usedRect.right < freeRect.right) {
        newFreeRects.add(Rect.fromLTRB(
          usedRect.right,
          freeRect.top,
          freeRect.right,
          freeRect.bottom,
        ));
      }

      // Top side
      if (usedRect.top > freeRect.top) {
        newFreeRects.add(Rect.fromLTRB(
          freeRect.left,
          freeRect.top,
          freeRect.right,
          usedRect.top,
        ));
      }

      // Bottom side
      if (usedRect.bottom < freeRect.bottom) {
        newFreeRects.add(Rect.fromLTRB(
          freeRect.left,
          usedRect.bottom,
          freeRect.right,
          freeRect.bottom,
        ));
      }
    }

    // Add new free rects
    freeRects.addAll(newFreeRects);
  }

  /// Remove redundant free rectangles (those fully contained in others)
  void _pruneFreeRects(List<Rect> freeRects) {
    for (int i = freeRects.length - 1; i >= 0; i--) {
      for (int j = freeRects.length - 1; j >= 0; j--) {
        if (i == j) continue;

        // Remove rect[i] if it's contained in rect[j]
        if (_rectContains(freeRects[j], freeRects[i])) {
          freeRects.removeAt(i);
          break;
        }
      }
    }
  }

  /// Check if two rectangles overlap
  bool _rectsOverlap(Rect a, Rect b) {
    return a.left < b.right &&
        a.right > b.left &&
        a.top < b.bottom &&
        a.bottom > b.top;
  }

  /// Check if rect a fully contains rect b
  bool _rectContains(Rect a, Rect b) {
    return a.left <= b.left &&
        a.top <= b.top &&
        a.right >= b.right &&
        a.bottom >= b.bottom;
  }

  /// Shrink atlas to minimum required size
  PackingResult _shrinkAtlas(PackingResult result, bool powerOfTwo) {
    if (result.packedSprites.isEmpty) return result;

    // Find actual bounds
    double maxX = 0;
    double maxY = 0;

    for (final packed in result.packedSprites) {
      final right = packed.packedRect.right;
      final bottom = packed.packedRect.bottom;

      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    int newWidth = maxX.ceil();
    int newHeight = maxY.ceil();

    if (powerOfTwo) {
      newWidth = _nextPowerOfTwo(newWidth);
      newHeight = _nextPowerOfTwo(newHeight);
    }

    return PackingResult(
      packedSprites: result.packedSprites,
      atlasWidth: newWidth,
      atlasHeight: newHeight,
      failedSprites: result.failedSprites,
    );
  }

  /// Calculate next power of two
  int _nextPowerOfTwo(int value) {
    if (value <= 0) return 1;
    value--;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return value + 1;
  }
}

/// Internal class for placement result with rotation info
class _PlacementResult {
  final Rect rect;
  final int rotation; // 0 or 90

  const _PlacementResult({
    required this.rect,
    required this.rotation,
  });
}
