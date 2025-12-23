import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Configuration for background removal
class BackgroundRemoveConfig {
  /// The color to make transparent
  final Color targetColor;

  /// Tolerance for color matching (0-255)
  /// Higher values match more similar colors
  final int tolerance;

  /// Whether to only remove contiguous background (flood fill from edges)
  /// If false, removes all pixels matching the target color
  final bool contiguousOnly;

  /// Feather radius for soft edges (0-255 pixels)
  /// Higher values create softer transitions
  final int featherRadius;

  /// Enable antialiasing for edge smoothness
  final bool antialias;

  /// Alpha threshold for feathering (0-255)
  /// Pixels with alpha below this value are fully transparent
  final int alphaThreshold;

  const BackgroundRemoveConfig({
    required this.targetColor,
    this.tolerance = 0,
    this.contiguousOnly = true,
    this.featherRadius = 0,
    this.antialias = false,
    this.alphaThreshold = 10,
  });
}

/// Result of background removal
class BackgroundRemoveResult {
  /// The processed image with transparent background
  final img.Image image;

  /// Number of pixels made transparent
  final int pixelsRemoved;

  /// Processing time in milliseconds
  final int processingTimeMs;

  const BackgroundRemoveResult({
    required this.image,
    required this.pixelsRemoved,
    required this.processingTimeMs,
  });
}

/// Service for removing background colors from images
class BackgroundRemoverService {
  const BackgroundRemoverService();

  /// Remove background color and make it transparent
  Future<BackgroundRemoveResult> removeBackground({
    required img.Image image,
    required BackgroundRemoveConfig config,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Ensure RGBA format
    final rgbaImage = image.numChannels == 4
        ? img.Image.from(image) // Clone to avoid modifying original
        : image.convert(numChannels: 4);

    final result = await compute(
      _processInIsolate,
      _IsolateInput(
        imageBytes: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
        width: rgbaImage.width,
        height: rgbaImage.height,
        targetR: config.targetColor.red.toInt(),
        targetG: config.targetColor.green.toInt(),
        targetB: config.targetColor.blue.toInt(),
        tolerance: config.tolerance,
        contiguousOnly: config.contiguousOnly,
        featherRadius: config.featherRadius,
        alphaThreshold: config.alphaThreshold,
      ),
    );

    // Create new image from processed bytes
    final processedImage = img.Image.fromBytes(
      width: rgbaImage.width,
      height: rgbaImage.height,
      bytes: Uint8List.fromList(result.imageBytes).buffer,
      order: img.ChannelOrder.rgba,
      numChannels: 4,
    );

    stopwatch.stop();

    return BackgroundRemoveResult(
      image: processedImage,
      pixelsRemoved: result.pixelsRemoved,
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Sample color at a specific pixel position
  Color? sampleColorAt(img.Image image, int x, int y) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
      return null;
    }

    final pixel = image.getPixel(x, y);
    return Color.fromARGB(
      pixel.a.toInt(),
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  /// Get unique corner colors for quick background detection
  /// Returns deduplicated list of colors from image corners
  List<Color> getCornerColors(img.Image image) {
    final positions = [
      (0, 0), // Top-left
      (image.width - 1, 0), // Top-right
      (0, image.height - 1), // Bottom-left
      (image.width - 1, image.height - 1), // Bottom-right
    ];

    final uniqueColors = <Color>[];
    final seenColors = <int>{};

    for (final (x, y) in positions) {
      final color = sampleColorAt(image, x, y);
      if (color != null) {
        // Create unique key from RGB values
        final key = (color.red.toInt() << 16) |
            (color.green.toInt() << 8) |
            color.blue.toInt();
        if (!seenColors.contains(key)) {
          seenColors.add(key);
          uniqueColors.add(color);
        }
      }
    }

    return uniqueColors;
  }

  /// Detect most likely background color from corners
  Color? detectBackgroundColor(img.Image image) {
    final corners = getCornerColors(image);
    if (corners.isEmpty) return null;

    // Find the most common corner color
    final colorCounts = <int, int>{};
    for (final color in corners) {
      final key = (color.red << 16) | (color.green << 8) | color.blue;
      colorCounts[key] = (colorCounts[key] ?? 0) + 1;
    }

    int maxCount = 0;
    int? mostCommonKey;
    for (final entry in colorCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonKey = entry.key;
      }
    }

    if (mostCommonKey == null) return null;

    return Color.fromARGB(
      255,
      (mostCommonKey >> 16) & 0xFF,
      (mostCommonKey >> 8) & 0xFF,
      mostCommonKey & 0xFF,
    );
  }
}

/// Input for isolate processing
class _IsolateInput {
  final List<int> imageBytes;
  final int width;
  final int height;
  final int targetR;
  final int targetG;
  final int targetB;
  final int tolerance;
  final bool contiguousOnly;
  final int featherRadius;
  final int alphaThreshold;

  const _IsolateInput({
    required this.imageBytes,
    required this.width,
    required this.height,
    required this.targetR,
    required this.targetG,
    required this.targetB,
    required this.tolerance,
    required this.contiguousOnly,
    required this.featherRadius,
    required this.alphaThreshold,
  });
}

/// Output from isolate processing
class _IsolateOutput {
  final List<int> imageBytes;
  final int pixelsRemoved;

  const _IsolateOutput({
    required this.imageBytes,
    required this.pixelsRemoved,
  });
}

/// Process image in isolate
_IsolateOutput _processInIsolate(_IsolateInput input) {
  final bytes = List<int>.from(input.imageBytes);
  final width = input.width;
  final height = input.height;
  int pixelsRemoved = 0;

  bool colorMatches(int idx) {
    final r = bytes[idx];
    final g = bytes[idx + 1];
    final b = bytes[idx + 2];

    final dr = (r - input.targetR).abs();
    final dg = (g - input.targetG).abs();
    final db = (b - input.targetB).abs();

    return dr <= input.tolerance &&
        dg <= input.tolerance &&
        db <= input.tolerance;
  }

  void makeTransparent(int idx) {
    bytes[idx + 3] = 0; // Set alpha to 0
    pixelsRemoved++;
  }

  if (input.contiguousOnly) {
    // Flood fill from all edges
    final visited = List<bool>.filled(width * height, false);
    final queue = <int>[];

    // Add all edge pixels to queue
    for (int x = 0; x < width; x++) {
      queue.add(x); // Top edge
      queue.add((height - 1) * width + x); // Bottom edge
    }
    for (int y = 1; y < height - 1; y++) {
      queue.add(y * width); // Left edge
      queue.add(y * width + width - 1); // Right edge
    }

    // BFS flood fill
    while (queue.isNotEmpty) {
      final idx = queue.removeLast();
      if (idx < 0 || idx >= width * height) continue;
      if (visited[idx]) continue;
      visited[idx] = true;

      final pixelIdx = idx * 4;
      if (!colorMatches(pixelIdx)) continue;

      makeTransparent(pixelIdx);

      final x = idx % width;
      final y = idx ~/ width;

      // Add neighbors
      if (x > 0) queue.add(idx - 1);
      if (x < width - 1) queue.add(idx + 1);
      if (y > 0) queue.add(idx - width);
      if (y < height - 1) queue.add(idx + width);
    }
  } else {
    // Remove all matching pixels
    for (int i = 0; i < width * height; i++) {
      final pixelIdx = i * 4;
      if (colorMatches(pixelIdx)) {
        makeTransparent(pixelIdx);
      }
    }
  }

  // Apply alpha threshold
  if (input.alphaThreshold > 0) {
    for (int i = 0; i < width * height; i++) {
      final pixelIdx = i * 4;
      if (bytes[pixelIdx + 3] < input.alphaThreshold) {
        bytes[pixelIdx + 3] = 0;
        pixelsRemoved++;
      }
    }
  }

  // Apply feathering if requested
  if (input.featherRadius > 0) {
    final alphaBytes = List<int>.generate(width * height, (i) => bytes[i * 4 + 3]);
    final featheredAlpha = _applyFeathering(
      alphaBytes,
      width,
      height,
      input.featherRadius,
    );

    for (int i = 0; i < width * height; i++) {
      bytes[i * 4 + 3] = featheredAlpha[i];
    }
  }

  return _IsolateOutput(
    imageBytes: bytes,
    pixelsRemoved: pixelsRemoved,
  );
}

/// Apply feathering to alpha channel using Gaussian blur approximation
List<int> _applyFeathering(List<int> alphaBytes, int width, int height, int radius) {
  final result = List<int>.from(alphaBytes);
  final kernel = _gaussianKernel(radius);
  final kernelSize = kernel.length;
  final half = kernelSize ~/ 2;

  // Horizontal pass
  final horizontal = List<int>.filled(alphaBytes.length, 0);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      double sum = 0;
      double weightSum = 0;

      for (int k = -half; k <= half; k++) {
        final nx = x + k;
        if (nx >= 0 && nx < width) {
          final idx = y * width + nx;
          sum += alphaBytes[idx] * kernel[k + half];
          weightSum += kernel[k + half];
        }
      }

      horizontal[y * width + x] = (sum / weightSum).round();
    }
  }

  // Vertical pass
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      double sum = 0;
      double weightSum = 0;

      for (int k = -half; k <= half; k++) {
        final ny = y + k;
        if (ny >= 0 && ny < height) {
          final idx = ny * width + x;
          sum += horizontal[idx] * kernel[k + half];
          weightSum += kernel[k + half];
        }
      }

      result[y * width + x] = (sum / weightSum).round();
    }
  }

  return result;
}

/// Generate 1D Gaussian kernel
List<double> _gaussianKernel(int radius) {
  final size = radius * 2 + 1;
  final sigma = radius / 3.0;
  final kernel = List<double>.filled(size, 0);

  double sum = 0;
  for (int i = 0; i < size; i++) {
    final x = (i - radius).toDouble();
    kernel[i] = _gaussian(x, sigma);
    sum += kernel[i];
  }

  // Normalize
  for (int i = 0; i < size; i++) {
    kernel[i] /= sum;
  }

  return kernel;
}

/// Gaussian function
double _gaussian(double x, double sigma) {
  return (1.0 / (sigma * math.sqrt(2 * math.pi))) * math.exp(-(x * x) / (2 * sigma * sigma));
}
