import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/sprite_region.dart';
import 'auto_slicer_service.dart';

/// Result of sprite separation
class SeparationResult {
  /// Background canvas with sprite areas filled with background color
  final img.Image backgroundCanvas;

  /// Background canvas as ui.Image for display
  final ui.Image backgroundUiImage;

  /// Sprites with extracted imageBytes and uiImage
  final List<SpriteRegion> separatedSprites;

  /// Detected background color
  final ui.Color detectedBackgroundColor;

  const SeparationResult({
    required this.backgroundCanvas,
    required this.backgroundUiImage,
    required this.separatedSprites,
    required this.detectedBackgroundColor,
  });
}

/// Service for separating sprites from source image
/// Converts from "region" state to "separated" state
class SpriteSeparatorService {
  const SpriteSeparatorService();

  /// Separate sprites from source image
  ///
  /// This extracts sprite images and creates a background canvas
  /// with sprite areas filled with detected background color.
  Future<SeparationResult> separateSprites({
    required img.Image sourceImage,
    required List<SpriteRegion> sprites,
  }) async {
    if (sprites.isEmpty) {
      throw ArgumentError('No sprites to separate');
    }

    // Ensure image has 4 channels (RGBA)
    final rgbaImage = sourceImage.numChannels == 4
        ? sourceImage
        : sourceImage.convert(numChannels: 4);

    // Detect background color from image edges
    final backgroundColor = _detectBackgroundColor(rgbaImage);

    // Create background canvas filled with background color
    final backgroundCanvas = await compute(
      _createBackgroundCanvasInIsolate,
      _BackgroundCanvasInput(
        imageBytes: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
        width: rgbaImage.width,
        height: rgbaImage.height,
        sprites: sprites.map((s) => _SpriteRect.fromSpriteRegion(s)).toList(),
        backgroundColor: backgroundColor,
      ),
    );

    // Extract sprite images
    final separatedSprites = await compute(
      _extractSpritesInIsolate,
      _ExtractSpritesInput(
        imageBytes: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
        width: rgbaImage.width,
        height: rgbaImage.height,
        sprites: sprites.map((s) => _SpriteRect.fromSpriteRegion(s)).toList(),
      ),
    );

    // Convert background canvas bytes to img.Image
    final backgroundImage = img.Image.fromBytes(
      width: rgbaImage.width,
      height: rgbaImage.height,
      bytes: backgroundCanvas.buffer,
      order: img.ChannelOrder.rgba,
      numChannels: 4,
    );

    // Create ui.Image from background canvas
    final backgroundUiImage = await SpriteImageUtils.createUiImage(
      backgroundCanvas,
      rgbaImage.width,
      rgbaImage.height,
    );

    if (backgroundUiImage == null) {
      throw Exception('Failed to create background ui.Image');
    }

    // Create separated sprites with ui.Image
    final separatedSpriteRegions = <SpriteRegion>[];
    for (int i = 0; i < sprites.length; i++) {
      final originalSprite = sprites[i];
      final extractedData = separatedSprites[i];

      ui.Image? spriteUiImage;
      if (extractedData != null) {
        spriteUiImage = await SpriteImageUtils.createUiImage(
          extractedData,
          originalSprite.width,
          originalSprite.height,
        );
      }

      separatedSpriteRegions.add(originalSprite.copyWith(
        imageBytes: extractedData,
        uiImage: spriteUiImage,
      ));
    }

    return SeparationResult(
      backgroundCanvas: backgroundImage,
      backgroundUiImage: backgroundUiImage,
      separatedSprites: separatedSpriteRegions,
      detectedBackgroundColor: ui.Color.fromARGB(
        backgroundColor[3],
        backgroundColor[0],
        backgroundColor[1],
        backgroundColor[2],
      ),
    );
  }

  /// Detect background color from image edges
  List<int> _detectBackgroundColor(img.Image image) {
    final bytes = image.getBytes(order: img.ChannelOrder.rgba);
    final width = image.width;
    final height = image.height;

    // Sample pixels from edges
    final samples = <List<int>>[];

    // Top row
    for (int x = 0; x < width; x += width ~/ 10 + 1) {
      final idx = (0 * width + x) * 4;
      if (idx + 3 < bytes.length) {
        samples.add([bytes[idx], bytes[idx + 1], bytes[idx + 2], bytes[idx + 3]]);
      }
    }

    // Bottom row
    for (int x = 0; x < width; x += width ~/ 10 + 1) {
      final idx = ((height - 1) * width + x) * 4;
      if (idx + 3 < bytes.length) {
        samples.add([bytes[idx], bytes[idx + 1], bytes[idx + 2], bytes[idx + 3]]);
      }
    }

    // Left column
    for (int y = 0; y < height; y += height ~/ 10 + 1) {
      final idx = (y * width + 0) * 4;
      if (idx + 3 < bytes.length) {
        samples.add([bytes[idx], bytes[idx + 1], bytes[idx + 2], bytes[idx + 3]]);
      }
    }

    // Right column
    for (int y = 0; y < height; y += height ~/ 10 + 1) {
      final idx = (y * width + (width - 1)) * 4;
      if (idx + 3 < bytes.length) {
        samples.add([bytes[idx], bytes[idx + 1], bytes[idx + 2], bytes[idx + 3]]);
      }
    }

    if (samples.isEmpty) {
      return [0, 0, 0, 0]; // Transparent black as fallback
    }

    // Find most common color
    final colorCounts = <String, int>{};
    for (final sample in samples) {
      final key = '${sample[0]},${sample[1]},${sample[2]},${sample[3]}';
      colorCounts[key] = (colorCounts[key] ?? 0) + 1;
    }

    String mostCommon = colorCounts.keys.first;
    int maxCount = colorCounts[mostCommon]!;

    for (final entry in colorCounts.entries) {
      if (entry.value > maxCount) {
        mostCommon = entry.key;
        maxCount = entry.value;
      }
    }

    final parts = mostCommon.split(',').map(int.parse).toList();
    return parts;
  }
}

/// Input for background canvas creation isolate
class _BackgroundCanvasInput {
  final Uint8List imageBytes;
  final int width;
  final int height;
  final List<_SpriteRect> sprites;
  final List<int> backgroundColor;

  const _BackgroundCanvasInput({
    required this.imageBytes,
    required this.width,
    required this.height,
    required this.sprites,
    required this.backgroundColor,
  });
}

/// Input for sprite extraction isolate
class _ExtractSpritesInput {
  final Uint8List imageBytes;
  final int width;
  final int height;
  final List<_SpriteRect> sprites;

  const _ExtractSpritesInput({
    required this.imageBytes,
    required this.width,
    required this.height,
    required this.sprites,
  });
}

/// Simple sprite rectangle for isolate transfer
class _SpriteRect {
  final int left;
  final int top;
  final int width;
  final int height;

  const _SpriteRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory _SpriteRect.fromSpriteRegion(SpriteRegion sprite) {
    return _SpriteRect(
      left: sprite.sourceRect.left.round(),
      top: sprite.sourceRect.top.round(),
      width: sprite.sourceRect.width.round(),
      height: sprite.sourceRect.height.round(),
    );
  }
}

/// Create background canvas in isolate
Uint8List _createBackgroundCanvasInIsolate(_BackgroundCanvasInput input) {
  final bytes = input.imageBytes;
  final width = input.width;
  final height = input.height;
  final bgColor = input.backgroundColor;

  // Create background canvas filled with background color
  final backgroundCanvas = Uint8List(bytes.length);
  for (int i = 0; i < bytes.length; i += 4) {
    backgroundCanvas[i] = bgColor[0];     // R
    backgroundCanvas[i + 1] = bgColor[1]; // G
    backgroundCanvas[i + 2] = bgColor[2]; // B
    backgroundCanvas[i + 3] = bgColor[3]; // A
  }

  // Mark sprite areas in a set for fast lookup
  final spritePixels = <int>{};
  for (final sprite in input.sprites) {
    for (int y = sprite.top; y < sprite.top + sprite.height && y < height; y++) {
      for (int x = sprite.left; x < sprite.left + sprite.width && x < width; x++) {
        spritePixels.add(y * width + x);
      }
    }
  }

  // Copy non-sprite pixels from original image
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixelIndex = y * width + x;
      if (!spritePixels.contains(pixelIndex)) {
        final idx = pixelIndex * 4;
        backgroundCanvas[idx] = bytes[idx];
        backgroundCanvas[idx + 1] = bytes[idx + 1];
        backgroundCanvas[idx + 2] = bytes[idx + 2];
        backgroundCanvas[idx + 3] = bytes[idx + 3];
      }
    }
  }

  return backgroundCanvas;
}

/// Extract sprite images in isolate
List<Uint8List?> _extractSpritesInIsolate(_ExtractSpritesInput input) {
  final bytes = input.imageBytes;
  final width = input.width;

  final result = <Uint8List?>[];

  for (final sprite in input.sprites) {
    final spriteWidth = sprite.width;
    final spriteHeight = sprite.height;
    final spriteBytes = Uint8List(spriteWidth * spriteHeight * 4);

    for (int sy = 0; sy < spriteHeight; sy++) {
      final sourceY = sprite.top + sy;
      if (sourceY >= input.height) continue;

      for (int sx = 0; sx < spriteWidth; sx++) {
        final sourceX = sprite.left + sx;
        if (sourceX >= width) continue;

        final sourceIdx = (sourceY * width + sourceX) * 4;
        final destIdx = (sy * spriteWidth + sx) * 4;

        spriteBytes[destIdx] = bytes[sourceIdx];
        spriteBytes[destIdx + 1] = bytes[sourceIdx + 1];
        spriteBytes[destIdx + 2] = bytes[sourceIdx + 2];
        spriteBytes[destIdx + 3] = bytes[sourceIdx + 3];
      }
    }

    result.add(spriteBytes);
  }

  return result;
}
