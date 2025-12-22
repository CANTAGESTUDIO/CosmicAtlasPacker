import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/sprite_region.dart';

/// Configuration for auto slicing
class AutoSliceConfig {
  /// Alpha threshold (0-255). Pixels with alpha >= threshold are considered opaque.
  final int alphaThreshold;

  /// Minimum sprite width in pixels
  final int minWidth;

  /// Minimum sprite height in pixels
  final int minHeight;

  /// ID prefix for generated sprites
  final String idPrefix;

  /// Use 8-direction connectivity (true) or 4-direction (false)
  final bool use8Direction;

  const AutoSliceConfig({
    this.alphaThreshold = 1,
    this.minWidth = 1,
    this.minHeight = 1,
    this.idPrefix = 'sprite',
    this.use8Direction = false,
  });

  AutoSliceConfig copyWith({
    int? alphaThreshold,
    int? minWidth,
    int? minHeight,
    String? idPrefix,
    bool? use8Direction,
  }) {
    return AutoSliceConfig(
      alphaThreshold: alphaThreshold ?? this.alphaThreshold,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      idPrefix: idPrefix ?? this.idPrefix,
      use8Direction: use8Direction ?? this.use8Direction,
    );
  }
}

/// Result of auto slicing operation
class AutoSliceResult {
  /// Generated sprite regions (with extracted image bytes)
  final List<SpriteRegion> sprites;

  /// Total regions found (before filtering)
  final int totalRegionsFound;

  /// Regions filtered out by minimum size
  final int filteredCount;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Detected background color (RGBA)
  final Color? detectedBackgroundColor;

  /// Background canvas image (source with sprites erased, filled with bg color)
  final img.Image? backgroundCanvas;

  const AutoSliceResult({
    required this.sprites,
    required this.totalRegionsFound,
    required this.filteredCount,
    required this.processingTimeMs,
    this.detectedBackgroundColor,
    this.backgroundCanvas,
  });

  /// Sprite count after filtering
  int get spriteCount => sprites.length;

  /// Check if sprites were extracted with image data
  /// In region mode, this returns false (image extraction happens during separation)
  bool get hasExtractedImages => sprites.isNotEmpty && sprites.first.hasImageData;
}

/// Progress callback for auto slicing
typedef AutoSliceProgressCallback = void Function(double progress, String message);

/// Service for automatic sprite slicing based on alpha channel
class AutoSlicerService {
  const AutoSlicerService();

  /// Auto-slice image using flood fill algorithm
  ///
  /// This runs in an isolate to prevent UI blocking.
  /// Returns sprites with extracted image data and a background canvas.
  Future<AutoSliceResult> autoSlice({
    required img.Image image,
    required AutoSliceConfig config,
    AutoSliceProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    onProgress?.call(0.0, 'Extracting alpha channel...');

    // Ensure image has 4 channels (RGBA) for alpha detection
    final rgbaImage = image.numChannels == 4 ? image : image.convert(numChannels: 4);

    // Run heavy processing in isolate
    final isolateResult = await compute(
      _processImageInIsolate,
      _IsolateInput(
        imageBytes: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
        width: rgbaImage.width,
        height: rgbaImage.height,
        config: config,
      ),
    );

    onProgress?.call(0.9, 'Building sprite regions...');

    // Convert bounding boxes to SpriteRegions (region mode - no image data)
    final sprites = <SpriteRegion>[];
    for (int i = 0; i < isolateResult.boundingBoxes.length; i++) {
      final box = isolateResult.boundingBoxes[i];

      sprites.add(SpriteRegion(
        id: '${config.idPrefix}_$i',
        sourceRect: Rect.fromLTWH(
          box.left.toDouble(),
          box.top.toDouble(),
          box.width.toDouble(),
          box.height.toDouble(),
        ),
        // No imageBytes in region mode - separation happens later
        originalPosition: Offset(box.left.toDouble(), box.top.toDouble()),
      ));
    }

    // Sort sprites by position (top-left to bottom-right)
    // Keep track of original indices for image data mapping
    final indexedSprites = sprites.asMap().entries.toList();
    indexedSprites.sort((a, b) {
      final yDiff = a.value.sourceRect.top.compareTo(b.value.sourceRect.top);
      if (yDiff != 0) return yDiff;
      return a.value.sourceRect.left.compareTo(b.value.sourceRect.left);
    });

    // Re-assign IDs after sorting
    final sortedSprites = <SpriteRegion>[];
    for (int i = 0; i < indexedSprites.length; i++) {
      sortedSprites.add(indexedSprites[i].value.copyWith(
        id: '${config.idPrefix}_$i',
      ));
    }

    // Convert background color (stored for later separation)
    Color? bgColor;
    if (isolateResult.backgroundColor != null) {
      final bg = isolateResult.backgroundColor!;
      bgColor = Color.fromARGB(bg[3], bg[0], bg[1], bg[2]);
    }

    stopwatch.stop();
    onProgress?.call(1.0, 'Complete!');

    // Region mode: no backgroundCanvas - separation happens when user drags
    return AutoSliceResult(
      sprites: sortedSprites,
      totalRegionsFound: isolateResult.totalFound,
      filteredCount: isolateResult.filteredCount,
      processingTimeMs: stopwatch.elapsedMilliseconds,
      detectedBackgroundColor: bgColor,
      backgroundCanvas: null,
    );
  }

  /// Preview detected regions without creating sprites
  Future<int> previewRegionCount({
    required img.Image image,
    required AutoSliceConfig config,
  }) async {
    // Ensure image has 4 channels (RGBA) for alpha detection
    final rgbaImage = image.numChannels == 4 ? image : image.convert(numChannels: 4);

    final result = await compute(
      _processImageInIsolate,
      _IsolateInput(
        imageBytes: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
        width: rgbaImage.width,
        height: rgbaImage.height,
        config: config,
      ),
    );
    return result.boundingBoxes.length;
  }
}

/// Input data for isolate processing
class _IsolateInput {
  final List<int> imageBytes;
  final int width;
  final int height;
  final AutoSliceConfig config;

  const _IsolateInput({
    required this.imageBytes,
    required this.width,
    required this.height,
    required this.config,
  });
}

/// Output data from isolate processing
class _IsolateOutput {
  final List<_BoundingBox> boundingBoxes;
  final int totalFound;
  final int filteredCount;

  /// Detected background color (RGBA as int list [r,g,b,a])
  final List<int>? backgroundColor;

  const _IsolateOutput({
    required this.boundingBoxes,
    required this.totalFound,
    required this.filteredCount,
    this.backgroundColor,
  });
}

/// Simple bounding box for isolate communication
class _BoundingBox {
  final int left;
  final int top;
  final int width;
  final int height;

  const _BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// Process image in isolate (static function required for compute)
/// Region mode: Only detect bounding boxes, no image extraction
_IsolateOutput _processImageInIsolate(_IsolateInput input) {
  final width = input.width;
  final height = input.height;
  final bytes = input.imageBytes;
  final config = input.config;

  // Step 1: Detect background color (stored for later separation)
  final backgroundColor = _detectBackgroundColor(bytes, width, height, config.alphaThreshold);

  // Step 2: Extract alpha channel and binarize
  final binaryMask = _createBinaryMask(
    bytes,
    width,
    height,
    config.alphaThreshold,
  );

  // Step 3: Find connected components using flood fill
  final visited = List<bool>.filled(width * height, false);
  final boundingBoxes = <_BoundingBox>[];
  int totalFound = 0;

  // 4-direction neighbors (up, down, left, right)
  final dx4 = [0, 0, -1, 1];
  final dy4 = [-1, 1, 0, 0];

  // 8-direction neighbors
  final dx8 = [0, 0, -1, 1, -1, 1, -1, 1];
  final dy8 = [-1, 1, 0, 0, -1, -1, 1, 1];

  final dx = config.use8Direction ? dx8 : dx4;
  final dy = config.use8Direction ? dy8 : dy4;
  final directionCount = config.use8Direction ? 8 : 4;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = y * width + x;

      // Skip if already visited or transparent
      if (visited[idx] || !binaryMask[idx]) continue;

      // Found a new region - perform BFS flood fill
      totalFound++;

      int minX = x, maxX = x;
      int minY = y, maxY = y;

      final queue = Queue<int>();
      queue.add(idx);
      visited[idx] = true;

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        final cx = current % width;
        final cy = current ~/ width;

        // Update bounding box
        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;

        // Check neighbors
        for (int d = 0; d < directionCount; d++) {
          final nx = cx + dx[d];
          final ny = cy + dy[d];

          // Bounds check
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

          final nidx = ny * width + nx;

          // Skip if visited or transparent
          if (visited[nidx] || !binaryMask[nidx]) continue;

          visited[nidx] = true;
          queue.add(nidx);
        }
      }

      // Calculate bounding box dimensions
      final boxWidth = maxX - minX + 1;
      final boxHeight = maxY - minY + 1;

      // Filter by minimum size
      if (boxWidth >= config.minWidth && boxHeight >= config.minHeight) {
        boundingBoxes.add(_BoundingBox(
          left: minX,
          top: minY,
          width: boxWidth,
          height: boxHeight,
        ));
      }
    }
  }

  // Region mode: No sprite image extraction, no background canvas creation
  // Separation happens later when user drags a sprite

  return _IsolateOutput(
    boundingBoxes: boundingBoxes,
    totalFound: totalFound,
    filteredCount: totalFound - boundingBoxes.length,
    backgroundColor: backgroundColor,
  );
}

/// Detect background color from image edges and transparent areas
List<int> _detectBackgroundColor(
  List<int> bytes,
  int width,
  int height,
  int alphaThreshold,
) {
  // Count color occurrences in background areas (transparent pixels)
  final colorCounts = <int, int>{};

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      final alpha = bytes[idx + 3];

      // Consider transparent pixels as background
      if (alpha < alphaThreshold) {
        // Pack RGB into single int for counting (ignore alpha variations)
        final colorKey = (bytes[idx] << 16) | (bytes[idx + 1] << 8) | bytes[idx + 2];
        colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      }
    }
  }

  // Also sample edges (first/last row and column)
  for (int x = 0; x < width; x++) {
    // Top row
    final topIdx = x * 4;
    final topKey = (bytes[topIdx] << 16) | (bytes[topIdx + 1] << 8) | bytes[topIdx + 2];
    colorCounts[topKey] = (colorCounts[topKey] ?? 0) + 1;

    // Bottom row
    final bottomIdx = ((height - 1) * width + x) * 4;
    final bottomKey = (bytes[bottomIdx] << 16) | (bytes[bottomIdx + 1] << 8) | bytes[bottomIdx + 2];
    colorCounts[bottomKey] = (colorCounts[bottomKey] ?? 0) + 1;
  }

  for (int y = 0; y < height; y++) {
    // Left column
    final leftIdx = (y * width) * 4;
    final leftKey = (bytes[leftIdx] << 16) | (bytes[leftIdx + 1] << 8) | bytes[leftIdx + 2];
    colorCounts[leftKey] = (colorCounts[leftKey] ?? 0) + 1;

    // Right column
    final rightIdx = (y * width + width - 1) * 4;
    final rightKey = (bytes[rightIdx] << 16) | (bytes[rightIdx + 1] << 8) | bytes[rightIdx + 2];
    colorCounts[rightKey] = (colorCounts[rightKey] ?? 0) + 1;
  }

  // Find most common color
  int maxCount = 0;
  int mostCommonColor = 0;

  for (final entry in colorCounts.entries) {
    if (entry.value > maxCount) {
      maxCount = entry.value;
      mostCommonColor = entry.key;
    }
  }

  // Unpack to RGBA (with full alpha for solid background)
  return [
    (mostCommonColor >> 16) & 0xFF,       // R
    (mostCommonColor >> 8) & 0xFF,        // G
    mostCommonColor & 0xFF,                // B
    255,                                   // A (fully opaque)
  ];
}

/// Create binary mask from alpha channel
List<bool> _createBinaryMask(
  List<int> bytes,
  int width,
  int height,
  int threshold,
) {
  final mask = List<bool>.filled(width * height, false);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // RGBA format: alpha is at offset 3
      final alphaIdx = (y * width + x) * 4 + 3;
      final alpha = bytes[alphaIdx];
      mask[y * width + x] = alpha >= threshold;
    }
  }

  return mask;
}

/// Utility class for sprite image operations
class SpriteImageUtils {
  /// Create ui.Image from RGBA bytes
  ///
  /// [imageBytes] - RGBA pixel data
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  static Future<Image?> createUiImage(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    if (imageBytes.isEmpty || width <= 0 || height <= 0) {
      return null;
    }

    final expectedLength = width * height * 4;
    if (imageBytes.length < expectedLength) {
      return null;
    }

    final codec = await instantiateImageCodec(
      await _encodeRgbaToPng(imageBytes, width, height),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Encode RGBA bytes to PNG format for ui.Image creation
  static Future<Uint8List> _encodeRgbaToPng(
    Uint8List rgbaBytes,
    int width,
    int height,
  ) async {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbaBytes.buffer,
      order: img.ChannelOrder.rgba,
      numChannels: 4,
    );
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Create ui.Image for all sprites in list
  ///
  /// Returns a new list with uiImage populated
  static Future<List<SpriteRegion>> createUiImagesForSprites(
    List<SpriteRegion> sprites,
  ) async {
    final result = <SpriteRegion>[];

    for (final sprite in sprites) {
      if (sprite.hasImageData) {
        final uiImage = await createUiImage(
          sprite.imageBytes!,
          sprite.width,
          sprite.height,
        );
        result.add(sprite.copyWith(uiImage: uiImage));
      } else {
        result.add(sprite);
      }
    }

    return result;
  }
}
