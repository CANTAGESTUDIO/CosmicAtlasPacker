import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../models/sprite_region.dart';
import 'bin_packing_service.dart';

/// Service for resizing sprites and calculating optimal scale
class SpriteResizeService {
  const SpriteResizeService._();

  /// Find optimal scale that allows all sprites to fit in the given canvas size
  /// Uses binary search for efficiency
  static double findOptimalScale({
    required List<SpriteRegion> sprites,
    required int maxWidth,
    required int maxHeight,
    int padding = 0,
    bool allowRotation = false,
  }) {
    if (sprites.isEmpty) return 1.0;

    final packer = BinPackingService();
    double low = 0.1;
    double high = 1.0;

    // First check if original size fits
    final originalResult = packer.pack(
      sprites,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      padding: padding,
      allowRotation: allowRotation,
    );

    if (originalResult.isComplete) {
      return 1.0; // No scaling needed
    }

    // Binary search for optimal scale
    while (high - low > 0.01) {
      final mid = (low + high) / 2;
      final scaledSprites = _scaleSpritesForTest(sprites, mid);

      final result = packer.pack(
        scaledSprites,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        padding: padding,
        allowRotation: allowRotation,
      );

      if (result.isComplete) {
        low = mid; // Try larger scale
      } else {
        high = mid; // Need smaller scale
      }
    }

    return low;
  }

  /// Create scaled copies of sprites for packing test (without actual image resize)
  static List<SpriteRegion> _scaleSpritesForTest(
    List<SpriteRegion> sprites,
    double scale,
  ) {
    return sprites.map((sprite) {
      final scaledSourceRect = ui.Rect.fromLTWH(
        sprite.sourceRect.left * scale,
        sprite.sourceRect.top * scale,
        (sprite.sourceRect.width * scale).clamp(1, 8192),
        (sprite.sourceRect.height * scale).clamp(1, 8192),
      );

      // Scale trimmedRect if exists
      ui.Rect? scaledTrimmedRect;
      if (sprite.trimmedRect != null) {
        scaledTrimmedRect = ui.Rect.fromLTWH(
          sprite.trimmedRect!.left * scale,
          sprite.trimmedRect!.top * scale,
          (sprite.trimmedRect!.width * scale).clamp(1, 8192),
          (sprite.trimmedRect!.height * scale).clamp(1, 8192),
        );
      }

      return sprite.copyWith(
        sourceRect: scaledSourceRect,
        trimmedRect: scaledTrimmedRect,
      );
    }).toList();
  }

  /// Resize a sprite region including its image data
  static Future<SpriteRegion> resizeSprite(
    SpriteRegion sprite,
    double scale,
  ) async {
    // Scale sourceRect
    final newSourceRect = ui.Rect.fromLTWH(
      sprite.sourceRect.left * scale,
      sprite.sourceRect.top * scale,
      (sprite.sourceRect.width * scale).clamp(1, 8192),
      (sprite.sourceRect.height * scale).clamp(1, 8192),
    );

    // Scale trimmedRect if exists
    ui.Rect? newTrimmedRect;
    if (sprite.trimmedRect != null) {
      newTrimmedRect = ui.Rect.fromLTWH(
        sprite.trimmedRect!.left * scale,
        sprite.trimmedRect!.top * scale,
        (sprite.trimmedRect!.width * scale).clamp(1, 8192),
        (sprite.trimmedRect!.height * scale).clamp(1, 8192),
      );
    }

    // Resize image if available
    Uint8List? newImageBytes;
    ui.Image? newUiImage;

    if (sprite.imageBytes != null && sprite.imageBytes!.isNotEmpty) {
      // Decode imageBytes to img.Image
      final originalImage = img.decodeImage(sprite.imageBytes!);
      if (originalImage != null) {
        final newWidth = newTrimmedRect?.width.round() ??
            newSourceRect.width.round();
        final newHeight = newTrimmedRect?.height.round() ??
            newSourceRect.height.round();

        // Resize image
        final resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        // Encode back to bytes
        newImageBytes = Uint8List.fromList(img.encodePng(resizedImage));

        // Convert to ui.Image using instantiateImageCodec
        final codec = await ui.instantiateImageCodec(newImageBytes);
        final frame = await codec.getNextFrame();
        newUiImage = frame.image;
      }
    }

    return sprite.copyWith(
      sourceRect: newSourceRect,
      trimmedRect: newTrimmedRect,
      imageBytes: newImageBytes,
      uiImage: newUiImage,
    );
  }

  /// Resize multiple sprites with the same scale
  static Future<List<SpriteRegion>> resizeSprites(
    List<SpriteRegion> sprites,
    double scale,
  ) async {
    final results = <SpriteRegion>[];
    for (final sprite in sprites) {
      results.add(await resizeSprite(sprite, scale));
    }
    return results;
  }
}
