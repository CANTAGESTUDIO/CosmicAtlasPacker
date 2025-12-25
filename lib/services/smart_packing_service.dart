import 'dart:ui';

import '../models/sprite_region.dart';
import 'bin_packing_service.dart' show PackingResult, PackedSprite;

/// Result of smart packing with individual scales
class SmartPackingResult {
  final PackingResult packingResult;
  final Map<String, double> individualScales;
  final List<SpriteRegion> includedSprites;
  final List<SpriteRegion> excludedSprites;
  final double efficiency;

  const SmartPackingResult({
    required this.packingResult,
    required this.individualScales,
    required this.includedSprites,
    required this.excludedSprites,
    required this.efficiency,
  });
}

/// Smart packing service with optimized sprite selection algorithm
///
/// COMPLETELY INDEPENDENT - Does NOT use BinPackingService internally
///
/// Algorithm:
/// 1. Pack all sprites at original size (large first for efficient packing)
/// 2. If doesn't fit, reduce LARGE sprites first (round-robin 10% reduction)
/// 3. Keep small sprites at original size as much as possible
class SmartPackingService {
  /// Find optimal packing using reduction on large sprites first
  SmartPackingResult findOptimalPacking({
    required List<SpriteRegion> sprites,
    required int canvasWidth,
    required int canvasHeight,
    int padding = 0,
    bool allowRotation = false,
    double minScale = 0.3,
    double reductionPercent = 0.1,
  }) {
    if (sprites.isEmpty) {
      return SmartPackingResult(
        packingResult: PackingResult(
          packedSprites: [],
          atlasWidth: canvasWidth,
          atlasHeight: canvasHeight,
        ),
        individualScales: {},
        includedSprites: [],
        excludedSprites: [],
        efficiency: 0.0,
      );
    }

    // Initialize scales (all 1.0)
    final scales = <String, double>{};
    for (final sprite in sprites) {
      scales[sprite.id] = 1.0;
    }

    // Sort by area descending (large first - for efficient bin packing)
    final sortedByAreaDesc = List<SpriteRegion>.from(sprites)
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));

    print('[SmartPacking] Canvas: ${canvasWidth}x$canvasHeight, Padding: $padding');
    print('[SmartPacking] Total sprites: ${sprites.length}');
    print('[SmartPacking] Packing order (large→small): ${sortedByAreaDesc.take(5).map((s) => '${s.id}(${s.width}x${s.height})').join(", ")}...');

    // ===== Phase 1: Try to pack all at original size =====
    bool allFit = _canPackAll(sortedByAreaDesc, scales, canvasWidth, canvasHeight, padding, allowRotation);

    if (allFit) {
      print('[SmartPacking] All sprites fit at 100% scale!');
    } else {
      // ===== Phase 2: Reduce large sprites until all fit =====
      print('[SmartPacking] Not all fit, starting reduction...');

      // Reduction order: LARGE sprites first (to preserve small ones)
      // Already sorted by area descending

      const maxRounds = 50;
      final reductionFactor = 1.0 - reductionPercent;

      for (int round = 0; round < maxRounds && !allFit; round++) {
        bool anyReduced = false;

        // Reduce each sprite by 10% (largest first)
        for (final sprite in sortedByAreaDesc) {
          final currentScale = scales[sprite.id]!;

          if (currentScale <= minScale) continue;

          // Reduce by 10%
          final newScale = (currentScale * reductionFactor).clamp(minScale, 1.0);
          scales[sprite.id] = newScale;
          anyReduced = true;

          // Check if all fit now
          allFit = _canPackAll(sortedByAreaDesc, scales, canvasWidth, canvasHeight, padding, allowRotation);

          if (allFit) {
            print('[SmartPacking] All fit after reducing ${sprite.id} to ${(newScale * 100).toInt()}%');
            break;
          }
        }

        if (!anyReduced) {
          print('[SmartPacking] All sprites at min scale, cannot reduce further');
          break;
        }
      }
    }

    // ===== Determine which sprites actually fit =====
    final included = <SpriteRegion>[];
    final excluded = <SpriteRegion>[];

    // Re-pack to get actual placements
    final freeRects = <_FreeRect>[
      _FreeRect(0, 0, canvasWidth, canvasHeight),
    ];

    for (final sprite in sortedByAreaDesc) {
      final scale = scales[sprite.id] ?? 1.0;
      final spriteW = (sprite.width * scale).round() + padding * 2;
      final spriteH = (sprite.height * scale).round() + padding * 2;

      final placement = _findPlacement(freeRects, spriteW, spriteH, allowRotation);
      if (placement != null) {
        included.add(sprite);
        _placeRect(freeRects, placement);
      } else {
        excluded.add(sprite);
      }
    }

    // ===== Generate final PackingResult =====
    final finalResult = _generatePackingResult(
      included, excluded, scales, canvasWidth, canvasHeight, padding, allowRotation,
    );

    // Log scale distribution
    final scaledSprites = scales.entries.where((e) => e.value < 1.0).toList();
    if (scaledSprites.isNotEmpty) {
      print('[SmartPacking] Scaled sprites: ${scaledSprites.map((e) => '${e.key}(${(e.value * 100).toInt()}%)').join(", ")}');
    }

    print('[SmartPacking] Final: ${included.length}/${sprites.length} sprites, '
        'efficiency=${(finalResult.efficiency * 100).toStringAsFixed(1)}%');

    if (excluded.isNotEmpty) {
      print('[SmartPacking] Could not fit: ${excluded.map((s) => s.id).join(", ")}');
    }

    return SmartPackingResult(
      packingResult: finalResult,
      individualScales: scales,
      includedSprites: included,
      excludedSprites: excluded,
      efficiency: finalResult.efficiency,
    );
  }

  /// Check if all sprites can be packed (returns true/false, no result)
  bool _canPackAll(
    List<SpriteRegion> sprites,
    Map<String, double> scales,
    int maxWidth,
    int maxHeight,
    int padding,
    bool allowRotation,
  ) {
    // Quick area check first
    int totalArea = 0;
    for (final sprite in sprites) {
      final scale = scales[sprite.id] ?? 1.0;
      final w = (sprite.width * scale).round() + padding * 2;
      final h = (sprite.height * scale).round() + padding * 2;
      totalArea += w * h;
    }
    if (totalArea > maxWidth * maxHeight) {
      return false; // Definitely won't fit
    }

    // Try actual packing
    final freeRects = <_FreeRect>[
      _FreeRect(0, 0, maxWidth, maxHeight),
    ];

    for (final sprite in sprites) {
      final scale = scales[sprite.id] ?? 1.0;
      final spriteW = (sprite.width * scale).round() + padding * 2;
      final spriteH = (sprite.height * scale).round() + padding * 2;

      final placement = _findPlacement(freeRects, spriteW, spriteH, allowRotation);
      if (placement == null) {
        return false; // Can't fit this sprite
      }

      // Place sprite and split free rects
      _placeRect(freeRects, placement);
    }

    return true;
  }

  /// Generate actual PackingResult with positions
  /// [includedSprites] - sprites that should be packed
  /// [excludedSprites] - sprites that were excluded earlier (will be added to failedSprites)
  PackingResult _generatePackingResult(
    List<SpriteRegion> includedSprites,
    List<SpriteRegion> excludedSprites,
    Map<String, double> scales,
    int maxWidth,
    int maxHeight,
    int padding,
    bool allowRotation,
  ) {
    final freeRects = <_FreeRect>[
      _FreeRect(0, 0, maxWidth, maxHeight),
    ];

    final packedSprites = <PackedSprite>[];
    final failedSprites = <SpriteRegion>[...excludedSprites]; // Start with excluded

    for (final sprite in includedSprites) {
      final scale = scales[sprite.id] ?? 1.0;
      final spriteW = (sprite.width * scale).round() + padding * 2;
      final spriteH = (sprite.height * scale).round() + padding * 2;

      final placement = _findPlacement(freeRects, spriteW, spriteH, allowRotation);
      if (placement != null) {
        final actualW = placement.rotated ? spriteH - padding * 2 : spriteW - padding * 2;
        final actualH = placement.rotated ? spriteW - padding * 2 : spriteH - padding * 2;

        packedSprites.add(PackedSprite(
          sprite: sprite,
          packedRect: Rect.fromLTWH(
            (placement.x + padding).toDouble(),
            (placement.y + padding).toDouble(),
            actualW.toDouble(),
            actualH.toDouble(),
          ),
          rotation: placement.rotated ? 90 : 0,
        ));

        _placeRect(freeRects, placement);
      } else {
        failedSprites.add(sprite);
      }
    }

    return PackingResult(
      packedSprites: packedSprites,
      atlasWidth: maxWidth,
      atlasHeight: maxHeight,
      failedSprites: failedSprites,
    );
  }

  /// Find best placement for a sprite (Bottom-Left heuristic)
  _Placement? _findPlacement(List<_FreeRect> freeRects, int width, int height, bool allowRotation) {
    _Placement? best;
    int bestScore = 0x7FFFFFFF;

    for (int i = 0; i < freeRects.length; i++) {
      final rect = freeRects[i];

      // Try normal orientation
      if (width <= rect.w && height <= rect.h) {
        final score = rect.y * 10000 + rect.x; // Bottom-Left: prefer lower y, then lower x
        if (score < bestScore) {
          bestScore = score;
          best = _Placement(rect.x, rect.y, width, height, false, i);
        }
      }

      // Try rotated (90 degrees)
      if (allowRotation && width != height) {
        if (height <= rect.w && width <= rect.h) {
          final score = rect.y * 10000 + rect.x;
          if (score < bestScore) {
            bestScore = score;
            best = _Placement(rect.x, rect.y, height, width, true, i);
          }
        }
      }
    }

    return best;
  }

  /// Place a rect and split free rects (Guillotine split)
  void _placeRect(List<_FreeRect> freeRects, _Placement placement) {
    final usedX = placement.x;
    final usedY = placement.y;
    final usedW = placement.w;
    final usedH = placement.h;

    final newRects = <_FreeRect>[];

    for (int i = freeRects.length - 1; i >= 0; i--) {
      final rect = freeRects[i];

      // Check overlap
      if (usedX >= rect.x + rect.w || usedX + usedW <= rect.x ||
          usedY >= rect.y + rect.h || usedY + usedH <= rect.y) {
        continue; // No overlap
      }

      freeRects.removeAt(i);

      // Left fragment
      if (usedX > rect.x) {
        newRects.add(_FreeRect(rect.x, rect.y, usedX - rect.x, rect.h));
      }
      // Right fragment
      if (usedX + usedW < rect.x + rect.w) {
        newRects.add(_FreeRect(usedX + usedW, rect.y, rect.x + rect.w - usedX - usedW, rect.h));
      }
      // Top fragment
      if (usedY > rect.y) {
        newRects.add(_FreeRect(rect.x, rect.y, rect.w, usedY - rect.y));
      }
      // Bottom fragment
      if (usedY + usedH < rect.y + rect.h) {
        newRects.add(_FreeRect(rect.x, usedY + usedH, rect.w, rect.y + rect.h - usedY - usedH));
      }
    }

    freeRects.addAll(newRects);
    _pruneRects(freeRects);
  }

  /// Remove rectangles that are contained within others
  void _pruneRects(List<_FreeRect> rects) {
    for (int i = rects.length - 1; i >= 0; i--) {
      for (int j = 0; j < rects.length; j++) {
        if (i == j || i >= rects.length) continue;
        if (_contains(rects[j], rects[i])) {
          rects.removeAt(i);
          break;
        }
      }
    }
  }

  bool _contains(_FreeRect a, _FreeRect b) {
    return a.x <= b.x && a.y <= b.y &&
           a.x + a.w >= b.x + b.w && a.y + a.h >= b.y + b.h;
  }
}

/// Internal free rectangle
class _FreeRect {
  final int x, y, w, h;
  const _FreeRect(this.x, this.y, this.w, this.h);
}

/// Internal placement result
class _Placement {
  final int x, y, w, h;
  final bool rotated;
  final int rectIndex;
  const _Placement(this.x, this.y, this.w, this.h, this.rotated, this.rectIndex);
}
