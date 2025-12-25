import 'dart:ui';

import '../models/sprite_region.dart';

/// Sorting strategy for sprites before packing
enum SortStrategy {
  /// Sort by area (largest first)
  area,
  /// Sort by height (tallest first)
  height,
  /// Sort by width (widest first)
  width,
  /// Sort by max(width, height) (largest dimension first)
  maxSide,
  /// Sort by perimeter (largest first)
  perimeter,
}

/// Placement heuristic for MaxRects algorithm
enum PlacementHeuristic {
  /// Best Short Side Fit - minimize shorter leftover side
  bssf,
  /// Best Long Side Fit - minimize longer leftover side
  blsf,
  /// Best Area Fit - minimize leftover area
  baf,
  /// Bottom-Left rule - place at lowest y, then leftmost x
  bl,
  /// Contact Point rule - maximize touching edges
  cp,
}

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

/// MaxRects bin packing algorithm with multiple heuristics
///
/// Implements:
/// - MaxRects data structure for free rectangle management
/// - Multiple placement heuristics (BSSF, BLSF, BAF, BL, CP)
/// - Multiple sorting strategies (area, height, width, maxSide, perimeter)
/// - Automatic selection of best combination for optimal packing
/// - Guillotine split for free area subdivision
class BinPackingService {
  /// All sorting strategies to try
  static const _sortStrategies = SortStrategy.values;

  /// All placement heuristics to try
  static const _placementHeuristics = PlacementHeuristic.values;

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

    // Ensure minimum size can fit largest sprite
    final maxSpriteWidth = sprites.map((s) => s.width + padding * 2).reduce((a, b) => a > b ? a : b);
    final maxSpriteHeight = sprites.map((s) => s.height + padding * 2).reduce((a, b) => a > b ? a : b);

    // Start with smallest power-of-2 that fits largest sprite
    int atlasWidth = _nextPowerOfTwo(maxSpriteWidth);
    int atlasHeight = _nextPowerOfTwo(maxSpriteHeight);

    // Try packing, grow atlas if needed
    PackingResult? bestResult;

    while (atlasWidth <= maxWidth && atlasHeight <= maxHeight) {
      // Try all combinations of sort strategies and placement heuristics
      bestResult = _findBestPacking(
        sprites,
        atlasWidth,
        atlasHeight,
        padding,
        allowRotation,
      );

      if (bestResult.isComplete) {
        // Shrink atlas to minimum required size
        final shrunkResult = _shrinkAtlas(bestResult, powerOfTwo);
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
    return bestResult ?? const PackingResult(
      packedSprites: [],
      atlasWidth: 0,
      atlasHeight: 0,
      failedSprites: [],
    );
  }

  /// Find the best packing by trying all sort/heuristic combinations
  PackingResult _findBestPacking(
    List<SpriteRegion> sprites,
    int atlasWidth,
    int atlasHeight,
    int padding,
    bool allowRotation,
  ) {
    PackingResult? bestResult;
    double bestEfficiency = -1;

    for (final sortStrategy in _sortStrategies) {
      final sortedSprites = _sortSprites(sprites, sortStrategy);

      for (final heuristic in _placementHeuristics) {
        final result = _tryPack(
          sortedSprites,
          atlasWidth,
          atlasHeight,
          padding,
          allowRotation,
          heuristic,
        );

        if (result.isComplete) {
          // Calculate effective efficiency (smaller atlas = better)
          final usedArea = result.packedSprites.fold<int>(
            0,
            (sum, p) => sum + (p.width * p.height),
          );
          final maxX = result.packedSprites.fold<double>(
            0,
            (max, p) => p.packedRect.right > max ? p.packedRect.right : max,
          );
          final maxY = result.packedSprites.fold<double>(
            0,
            (max, p) => p.packedRect.bottom > max ? p.packedRect.bottom : max,
          );
          final actualArea = maxX * maxY;
          final efficiency = actualArea > 0 ? usedArea / actualArea : 0.0;

          if (efficiency > bestEfficiency) {
            bestEfficiency = efficiency;
            bestResult = result;
          }
        }
      }
    }

    // If no complete result found, return best partial
    if (bestResult == null) {
      // Just use area sort with BSSF as fallback
      final sorted = _sortSprites(sprites, SortStrategy.area);
      return _tryPack(sorted, atlasWidth, atlasHeight, padding, allowRotation, PlacementHeuristic.bssf);
    }

    return bestResult;
  }

  /// Sort sprites by given strategy in descending order
  List<SpriteRegion> _sortSprites(List<SpriteRegion> sprites, SortStrategy strategy) {
    final sorted = List<SpriteRegion>.from(sprites);

    switch (strategy) {
      case SortStrategy.area:
        sorted.sort((a, b) => b.area.compareTo(a.area));
        break;
      case SortStrategy.height:
        sorted.sort((a, b) => b.height.compareTo(a.height));
        break;
      case SortStrategy.width:
        sorted.sort((a, b) => b.width.compareTo(a.width));
        break;
      case SortStrategy.maxSide:
        sorted.sort((a, b) {
          final maxA = a.width > a.height ? a.width : a.height;
          final maxB = b.width > b.height ? b.width : b.height;
          return maxB.compareTo(maxA);
        });
        break;
      case SortStrategy.perimeter:
        sorted.sort((a, b) {
          final perimA = 2 * (a.width + a.height);
          final perimB = 2 * (b.width + b.height);
          return perimB.compareTo(perimA);
        });
        break;
    }

    return sorted;
  }

  /// Try to pack all sprites into given atlas dimensions
  PackingResult _tryPack(
    List<SpriteRegion> sprites,
    int atlasWidth,
    int atlasHeight,
    int padding,
    bool allowRotation,
    PlacementHeuristic heuristic,
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

      // Find best position using selected heuristic (with optional rotation)
      final placement = _findBestPositionWithRotation(
        freeRects,
        spriteWidth,
        spriteHeight,
        allowRotation,
        heuristic,
        packedSprites, // Needed for Contact Point heuristic
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
    PlacementHeuristic heuristic,
    List<PackedSprite> packedSprites,
  ) {
    _PlacementResult? bestResult;
    double bestScore = double.infinity;

    // Try original orientation
    final normalResult = _findBestPosition(
      freeRects, spriteWidth, spriteHeight, heuristic, packedSprites);
    if (normalResult != null) {
      final score = _calculateScore(
        normalResult, spriteWidth, spriteHeight, heuristic, packedSprites);

      bestResult = _PlacementResult(
        rect: Rect.fromLTWH(normalResult.left, normalResult.top,
            spriteWidth.toDouble(), spriteHeight.toDouble()),
        rotation: 0,
      );
      bestScore = score;
    }

    // Try 90 degree rotation if allowed and sprite is not square
    if (allowRotation && spriteWidth != spriteHeight) {
      final rotatedResult = _findBestPosition(
        freeRects, spriteHeight, spriteWidth, heuristic, packedSprites);
      if (rotatedResult != null) {
        final score = _calculateScore(
          rotatedResult, spriteHeight, spriteWidth, heuristic, packedSprites);

        // Use rotated if it's a better fit (lower score is better)
        if (score < bestScore) {
          bestResult = _PlacementResult(
            rect: Rect.fromLTWH(rotatedResult.left, rotatedResult.top,
                spriteHeight.toDouble(), spriteWidth.toDouble()),
            rotation: 90,
          );
        }
      }
    }

    return bestResult;
  }

  /// Calculate placement score based on heuristic (lower is better)
  double _calculateScore(
    Rect freeRect,
    int spriteWidth,
    int spriteHeight,
    PlacementHeuristic heuristic,
    List<PackedSprite> packedSprites,
  ) {
    final leftoverX = (freeRect.width - spriteWidth).toDouble();
    final leftoverY = (freeRect.height - spriteHeight).toDouble();

    switch (heuristic) {
      case PlacementHeuristic.bssf:
        // Best Short Side Fit - minimize shorter leftover
        final shortSide = leftoverX < leftoverY ? leftoverX : leftoverY;
        final longSide = leftoverX > leftoverY ? leftoverX : leftoverY;
        return shortSide * 10000 + longSide;

      case PlacementHeuristic.blsf:
        // Best Long Side Fit - minimize longer leftover
        final shortSide = leftoverX < leftoverY ? leftoverX : leftoverY;
        final longSide = leftoverX > leftoverY ? leftoverX : leftoverY;
        return longSide * 10000 + shortSide;

      case PlacementHeuristic.baf:
        // Best Area Fit - minimize leftover area
        return freeRect.width * freeRect.height - spriteWidth * spriteHeight;

      case PlacementHeuristic.bl:
        // Bottom-Left rule - minimize y, then x
        return freeRect.top * 10000 + freeRect.left;

      case PlacementHeuristic.cp:
        // Contact Point - maximize contact with placed sprites or edges
        final spriteRect = Rect.fromLTWH(
          freeRect.left, freeRect.top,
          spriteWidth.toDouble(), spriteHeight.toDouble(),
        );
        final contactLength = _calculateContactLength(spriteRect, packedSprites);
        // Negative because higher contact is better
        return -contactLength.toDouble();
    }
  }

  /// Calculate total contact length with edges and other sprites
  int _calculateContactLength(Rect spriteRect, List<PackedSprite> packedSprites) {
    int contactLength = 0;

    // Contact with left edge (x=0)
    if (spriteRect.left == 0) {
      contactLength += spriteRect.height.round();
    }

    // Contact with top edge (y=0)
    if (spriteRect.top == 0) {
      contactLength += spriteRect.width.round();
    }

    // Contact with other sprites
    for (final packed in packedSprites) {
      final other = packed.packedRect;

      // Check horizontal contact (left/right edges touching)
      if (spriteRect.right == other.left || spriteRect.left == other.right) {
        final overlapTop = spriteRect.top > other.top ? spriteRect.top : other.top;
        final overlapBottom = spriteRect.bottom < other.bottom ? spriteRect.bottom : other.bottom;
        if (overlapBottom > overlapTop) {
          contactLength += (overlapBottom - overlapTop).round();
        }
      }

      // Check vertical contact (top/bottom edges touching)
      if (spriteRect.bottom == other.top || spriteRect.top == other.bottom) {
        final overlapLeft = spriteRect.left > other.left ? spriteRect.left : other.left;
        final overlapRight = spriteRect.right < other.right ? spriteRect.right : other.right;
        if (overlapRight > overlapLeft) {
          contactLength += (overlapRight - overlapLeft).round();
        }
      }
    }

    return contactLength;
  }

  /// Find best position using selected heuristic
  /// Returns the free rect where sprite should be placed or null if no fit found
  Rect? _findBestPosition(
    List<Rect> freeRects,
    int spriteWidth,
    int spriteHeight,
    PlacementHeuristic heuristic,
    List<PackedSprite> packedSprites,
  ) {
    Rect? bestRect;
    double bestScore = double.infinity;

    for (final freeRect in freeRects) {
      // Check if sprite fits in this free rect
      if (spriteWidth <= freeRect.width && spriteHeight <= freeRect.height) {
        final score = _calculateScore(
          freeRect, spriteWidth, spriteHeight, heuristic, packedSprites);

        if (score < bestScore) {
          bestRect = freeRect;
          bestScore = score;
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
