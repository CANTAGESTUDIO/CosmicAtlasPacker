import 'package:image/image.dart' as img;

/// Service for applying morphological erosion to images
///
/// Erosion removes pixels from the outer edges of opaque regions,
/// making the image "thinner" while preserving its shape.
class ImageErosionService {
  /// Apply erosion to an image
  ///
  /// [image] - Source image to erode
  /// [erosionPixels] - Number of pixels to erode from edges (0 = no change)
  ///                   Supports decimal values (e.g., 2.5 = 2 full + 50% alpha on edge)
  /// [alphaThreshold] - Minimum alpha value to consider a pixel opaque (default: 1)
  /// [antiAlias] - Apply anti-aliasing to smooth eroded edges (default: false)
  ///
  /// Returns a new image with erosion applied
  img.Image applyErosion(
    img.Image image,
    double erosionPixels, {
    int alphaThreshold = 1,
    bool antiAlias = false,
  }) {
    if (erosionPixels <= 0) return image;

    final w = image.width;
    final h = image.height;
    final result = img.Image.from(image); // Copy

    // Split into integer and fractional parts
    final fullIterations = erosionPixels.floor();
    final fractional = erosionPixels - fullIterations;

    // Create alpha mask: true = opaque (alpha >= threshold)
    List<List<bool>> mask = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) => image.getPixel(x, y).a >= alphaThreshold,
      ),
    );

    // Apply full erosion iterations (integer part)
    for (int iter = 0; iter < fullIterations; iter++) {
      // Create new mask for this iteration
      List<List<bool>> newMask = List.generate(
        h,
        (y) => List.from(mask[y]),
      );

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          // Skip if already transparent
          if (!mask[y][x]) continue;

          // Check if this is an edge pixel (adjacent to transparent pixel)
          // Using 4-connectivity (up, down, left, right)
          final bool isEdge = _isEdgePixel(mask, x, y, w, h);

          if (isEdge) {
            newMask[y][x] = false;
            result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          }
        }
      }

      mask = newMask;
    }

    // Apply fractional erosion (partial alpha reduction on edge pixels)
    if (fractional > 0) {
      _applyFractionalErosion(result, mask, w, h, fractional);
    }

    // Apply anti-aliasing if enabled
    if (antiAlias) {
      _applyAntiAliasing(result, mask, w, h);
    }

    return result;
  }

  /// Apply fractional erosion by reducing alpha of edge pixels
  ///
  /// [fractional] - Value between 0.0 and 1.0 representing partial erosion
  /// Example: 0.5 means 50% alpha reduction on current edge pixels
  void _applyFractionalErosion(
    img.Image image,
    List<List<bool>> mask,
    int w,
    int h,
    double fractional,
  ) {
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        // Skip if already transparent
        if (!mask[y][x]) continue;

        // Check if this is an edge pixel
        final bool isEdge = _isEdgePixel(mask, x, y, w, h);

        if (isEdge) {
          final pixel = image.getPixel(x, y);
          // Reduce alpha by fractional amount
          // fractional = 0.3 means reduce alpha by 30%
          final newAlpha = (pixel.a * (1.0 - fractional)).round().clamp(0, 255);
          image.setPixel(
            x,
            y,
            img.ColorRgba8(
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              newAlpha,
            ),
          );
        }
      }
    }
  }

  /// Apply anti-aliasing to smooth the eroded edges
  void _applyAntiAliasing(
      img.Image image, List<List<bool>> mask, int w, int h) {
    // Find edge pixels and apply alpha gradient
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (!mask[y][x]) continue; // Skip transparent pixels

        // Count transparent neighbors (8-connectivity for smoother result)
        int transparentNeighbors = 0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            if (!mask[y + dy][x + dx]) transparentNeighbors++;
          }
        }

        // If this pixel has transparent neighbors, it's on the edge
        if (transparentNeighbors > 0) {
          final pixel = image.getPixel(x, y);
          // Reduce alpha based on number of transparent neighbors
          // More transparent neighbors = more transparency
          final alphaFactor = 1.0 - (transparentNeighbors / 12.0);
          final newAlpha = (pixel.a * alphaFactor).round().clamp(0, 255);
          image.setPixel(
            x,
            y,
            img.ColorRgba8(
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              newAlpha,
            ),
          );
        }
      }
    }
  }

  /// Apply erosion to a rectangular region within an image
  ///
  /// [image] - Source image
  /// [x] - Left coordinate of region
  /// [y] - Top coordinate of region
  /// [width] - Width of region
  /// [height] - Height of region
  /// [erosionPixels] - Number of pixels to erode (supports decimal values)
  /// [alphaThreshold] - Minimum alpha for opaque pixels
  /// [antiAlias] - Apply anti-aliasing to smooth eroded edges
  ///
  /// Returns a new image of the specified size with erosion applied
  img.Image applyErosionToRegion(
    img.Image image, {
    required int x,
    required int y,
    required int width,
    required int height,
    required double erosionPixels,
    int alphaThreshold = 1,
    bool antiAlias = false,
  }) {
    // Extract the region
    final region = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // Apply erosion to the extracted region
    return applyErosion(
      region,
      erosionPixels,
      alphaThreshold: alphaThreshold,
      antiAlias: antiAlias,
    );
  }

  /// Check if a pixel is on the edge (adjacent to a transparent pixel)
  bool _isEdgePixel(List<List<bool>> mask, int x, int y, int w, int h) {
    // Image boundary is considered as edge
    if (x == 0 || x == w - 1 || y == 0 || y == h - 1) {
      return true;
    }

    // Check 4-connectivity neighbors
    // If any neighbor is transparent, this is an edge pixel
    return !mask[y][x - 1] || // left
        !mask[y][x + 1] || // right
        !mask[y - 1][x] || // up
        !mask[y + 1][x]; // down
  }
}
