import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import '../models/animation_sequence.dart';
import '../models/sprite_data.dart';
import '../models/texture_compression_settings.dart';
import 'bin_packing_service.dart';
import 'image_erosion_service.dart';

/// Atlas metadata following PRD section 7.1 JSON schema
///
/// Output format:
/// ```json
/// {
///   "version": "1.0.0",
///   "generator": "CosmicAtlasPacker",
///   "atlas": { "file": "...", "width": ..., "height": ..., "format": "RGBA8888" },
///   "sprites": { "spriteId": { "frame": {...}, "pivot": {...}, "nineSlice": null } },
///   "animations": {},
///   "meta": { "createdAt": "...", "app": "...", "appVersion": "..." }
/// }
/// ```
class AtlasMetadata {
  final String version;
  final String generator;
  final AtlasInfo atlas;
  final Map<String, SpriteInfo> sprites;
  final Map<String, AnimationInfo> animations;
  final MetaInfo meta;

  const AtlasMetadata({
    required this.version,
    required this.generator,
    required this.atlas,
    required this.sprites,
    required this.animations,
    required this.meta,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'generator': generator,
    'atlas': atlas.toJson(),
    'sprites': sprites.map((key, value) => MapEntry(key, value.toJson())),
    'animations': animations.map((key, value) => MapEntry(key, value.toJson())),
    'meta': meta.toJson(),
  };

  String toJsonString({bool prettyPrint = true}) {
    final encoder = prettyPrint
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }
}

/// Atlas file information
class AtlasInfo {
  final String file;
  final int width;
  final int height;
  final String format;

  const AtlasInfo({
    required this.file,
    required this.width,
    required this.height,
    this.format = 'RGBA8888',
  });

  Map<String, dynamic> toJson() => {
    'file': file,
    'width': width,
    'height': height,
    'format': format,
  };
}

/// Individual sprite frame information
class SpriteInfo {
  final FrameInfo frame;
  final PivotInfo pivot;
  final NineSliceInfo? nineSlice;

  const SpriteInfo({
    required this.frame,
    required this.pivot,
    this.nineSlice,
  });

  Map<String, dynamic> toJson() => {
    'frame': frame.toJson(),
    'pivot': pivot.toJson(),
    'nineSlice': nineSlice?.toJson(),
  };
}

/// Frame rectangle in atlas (x, y, w, h)
class FrameInfo {
  final int x;
  final int y;
  final int w;
  final int h;

  const FrameInfo({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'w': w,
    'h': h,
  };
}

/// Pivot point (normalized 0.0 ~ 1.0)
class PivotInfo {
  final double x;
  final double y;

  const PivotInfo({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
  };
}

/// 9-slice border information
class NineSliceInfo {
  final int left;
  final int right;
  final int top;
  final int bottom;

  const NineSliceInfo({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  Map<String, dynamic> toJson() => {
    'left': left,
    'right': right,
    'top': top,
    'bottom': bottom,
  };
}

/// Animation sequence information
class AnimationInfo {
  final List<AnimationFrameInfo> frames;
  final bool loop;
  final bool pingPong;

  const AnimationInfo({
    required this.frames,
    this.loop = true,
    this.pingPong = false,
  });

  Map<String, dynamic> toJson() => {
    'frames': frames.map((f) => f.toJson()).toList(),
    'loop': loop,
    'pingPong': pingPong,
  };
}

/// Single animation frame reference
class AnimationFrameInfo {
  final String spriteId;
  final double duration;
  final bool flipX;
  final bool flipY;

  const AnimationFrameInfo({
    required this.spriteId,
    required this.duration,
    this.flipX = false,
    this.flipY = false,
  });

  Map<String, dynamic> toJson() => {
    'spriteId': spriteId,
    'duration': duration,
    'flipX': flipX,
    'flipY': flipY,
  };
}

/// Meta information
class MetaInfo {
  final String createdAt;
  final String app;
  final String appVersion;

  const MetaInfo({
    required this.createdAt,
    required this.app,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt,
    'app': app,
    'appVersion': appVersion,
  };
}

// ============================================
// Extension methods for model conversions
// ============================================

/// Extension to convert AnimationSequence to AnimationInfo for export
extension AnimationSequenceToInfo on AnimationSequence {
  /// Convert AnimationSequence to export-ready AnimationInfo
  AnimationInfo toAnimationInfo() {
    return AnimationInfo(
      frames: frames.map((frame) => frame.toAnimationFrameInfo()).toList(),
      loop: loopMode == AnimationLoopMode.loop || loopMode == AnimationLoopMode.pingPong,
      pingPong: loopMode == AnimationLoopMode.pingPong,
    );
  }
}

/// Extension to convert AnimationFrame to AnimationFrameInfo for export
extension AnimationFrameToInfo on AnimationFrame {
  /// Convert AnimationFrame to export-ready AnimationFrameInfo
  AnimationFrameInfo toAnimationFrameInfo() {
    return AnimationFrameInfo(
      spriteId: spriteId,
      duration: duration,
      flipX: flipX,
      flipY: flipY,
    );
  }
}

/// Extension to convert NineSliceBorder to NineSliceInfo for export
extension NineSliceBorderToInfo on NineSliceBorder {
  /// Convert NineSliceBorder to export-ready NineSliceInfo
  /// Returns null if 9-slice is not enabled (all borders are 0)
  NineSliceInfo? toNineSliceInfo() {
    if (!isEnabled) return null;
    return NineSliceInfo(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }
}

/// Service for exporting atlas metadata as JSON
///
/// Follows PRD section 7.1 JSON schema format for BatchRenderer compatibility
class ExportService {
  static const String appName = 'CosmicAtlasPacker';
  static const String appVersion = '1.0.0';
  static const String schemaVersion = '1.0.0';

  /// Generate atlas metadata from packing result
  ///
  /// [packingResult] - Result from bin packing service
  /// [atlasFileName] - Name of the atlas PNG file (e.g., "sprites_atlas.png")
  /// [pivotX] - Default pivot X (0.0 ~ 1.0), defaults to 0.5 (center)
  /// [pivotY] - Default pivot Y (0.0 ~ 1.0), defaults to 0.5 (center)
  /// [animations] - Optional list of animation sequences to include
  /// [includeAnimations] - Whether to include animation data (default: true)
  AtlasMetadata generateMetadata({
    required PackingResult packingResult,
    required String atlasFileName,
    double pivotX = 0.5,
    double pivotY = 0.5,
    List<AnimationSequence>? animations,
    bool includeAnimations = true,
  }) {
    // Generate sprite info map with 9-slice data
    final sprites = <String, SpriteInfo>{};

    for (final packed in packingResult.packedSprites) {
      final sprite = packed.sprite;

      // Extract 9-slice info if enabled
      NineSliceInfo? nineSliceInfo;
      if (sprite.nineSlice != null && sprite.nineSlice!.isEnabled) {
        nineSliceInfo = sprite.nineSlice!.toNineSliceInfo();
      }

      // Use sprite's pivot if available, otherwise use default
      final spritePivotX = sprite.pivot.x;
      final spritePivotY = sprite.pivot.y;

      sprites[sprite.id] = SpriteInfo(
        frame: FrameInfo(
          x: packed.x,
          y: packed.y,
          w: packed.width,
          h: packed.height,
        ),
        pivot: PivotInfo(
          x: spritePivotX,
          y: spritePivotY,
        ),
        nineSlice: nineSliceInfo,
      );
    }

    // Generate animation info map
    final animationMap = <String, AnimationInfo>{};
    if (includeAnimations && animations != null) {
      for (final anim in animations) {
        // Only include animations with valid frames
        if (anim.frames.isNotEmpty) {
          animationMap[anim.name] = anim.toAnimationInfo();
        }
      }
    }

    return AtlasMetadata(
      version: schemaVersion,
      generator: appName,
      atlas: AtlasInfo(
        file: atlasFileName,
        width: packingResult.atlasWidth,
        height: packingResult.atlasHeight,
        format: 'RGBA8888',
      ),
      sprites: sprites,
      animations: animationMap,
      meta: MetaInfo(
        createdAt: DateTime.now().toUtc().toIso8601String(),
        app: appName,
        appVersion: appVersion,
      ),
    );
  }

  /// Export metadata as JSON file
  ///
  /// [metadata] - Atlas metadata to export
  /// [outputPath] - Full path to output JSON file
  /// [prettyPrint] - Whether to format JSON with indentation (default: true)
  Future<void> exportJson({
    required AtlasMetadata metadata,
    required String outputPath,
    bool prettyPrint = true,
  }) async {
    final jsonString = metadata.toJsonString(prettyPrint: prettyPrint);
    final file = File(outputPath);
    await file.writeAsString(jsonString, encoding: utf8);
  }

  /// Generate JSON file path from PNG path
  ///
  /// [pngPath] - Path to PNG file (e.g., "/path/to/atlas.png")
  /// Returns JSON path with same name (e.g., "/path/to/atlas.json")
  String getJsonPathFromPngPath(String pngPath) {
    if (pngPath.toLowerCase().endsWith('.png')) {
      return '${pngPath.substring(0, pngPath.length - 4)}.json';
    }
    return '$pngPath.json';
  }

  /// Export both PNG atlas image and JSON metadata
  ///
  /// This is a convenience method that:
  /// 1. Generates metadata from packing result
  /// 2. Saves JSON to same directory as PNG with matching name
  ///
  /// [packingResult] - Result from bin packing service
  /// [pngPath] - Full path where PNG will be/was saved
  /// [pivotX] - Default pivot X (0.0 ~ 1.0)
  /// [pivotY] - Default pivot Y (0.0 ~ 1.0)
  Future<String> exportMetadataForAtlas({
    required PackingResult packingResult,
    required String pngPath,
    double pivotX = 0.5,
    double pivotY = 0.5,
  }) async {
    // Extract filename from path
    final atlasFileName = pngPath.split('/').last.split('\\').last;

    // Generate metadata
    final metadata = generateMetadata(
      packingResult: packingResult,
      atlasFileName: atlasFileName,
      pivotX: pivotX,
      pivotY: pivotY,
    );

    // Determine JSON output path
    final jsonPath = getJsonPathFromPngPath(pngPath);

    // Export JSON
    await exportJson(
      metadata: metadata,
      outputPath: jsonPath,
    );

    return jsonPath;
  }

  /// Generate atlas image from packing result and source image
  ///
  /// [sourceImage] - Original source image to extract sprites from
  /// [packingResult] - Result of bin packing algorithm
  /// Returns the composed atlas image
  img.Image generateAtlasImage({
    required img.Image sourceImage,
    required PackingResult packingResult,
  }) {
    // Create new RGBA image with atlas dimensions
    final atlasImage = img.Image(
      width: packingResult.atlasWidth,
      height: packingResult.atlasHeight,
      numChannels: 4,
    );

    // Fill with transparent background
    img.fill(atlasImage, color: img.ColorRgba8(0, 0, 0, 0));

    // Copy each sprite to its packed position
    for (final packed in packingResult.packedSprites) {
      final sprite = packed.sprite;
      // Use effectiveRect (trimmedRect if set, otherwise sourceRect)
      // This respects edge crop settings
      final effectiveRect = sprite.effectiveRect;

      // Extract sprite from source image and copy to atlas
      for (int y = 0; y < packed.height; y++) {
        for (int x = 0; x < packed.width; x++) {
          final srcX = effectiveRect.left.round() + x;
          final srcY = effectiveRect.top.round() + y;

          // Bounds check for source
          if (srcX >= 0 &&
              srcX < sourceImage.width &&
              srcY >= 0 &&
              srcY < sourceImage.height) {
            final pixel = sourceImage.getPixel(srcX, srcY);

            final dstX = packed.x + x;
            final dstY = packed.y + y;

            // Bounds check for destination
            if (dstX >= 0 &&
                dstX < atlasImage.width &&
                dstY >= 0 &&
                dstY < atlasImage.height) {
              atlasImage.setPixel(dstX, dstY, pixel);
            }
          }
        }
      }
    }

    return atlasImage;
  }

  /// Generate atlas image from packing result with multiple source images
  ///
  /// [sourceImages] - Map of source ID to source image (img.Image)
  /// [packingResult] - Result of bin packing algorithm
  /// [erosionPixels] - Number of pixels to erode from sprite edges (0 = no erosion, supports decimal)
  /// [erosionAntiAlias] - Apply anti-aliasing to smooth eroded edges
  /// [outputScale] - Scale factor for output sprites (0.1 ~ 1.0, default 1.0)
  /// Returns the composed atlas image
  img.Image generateMultiSourceAtlasImage({
    required Map<String, dynamic> sourceImages,
    required PackingResult packingResult,
    double erosionPixels = 0,
    bool erosionAntiAlias = false,
    double outputScale = 1.0,
  }) {
    final erosionService = ImageErosionService();

    // Create new RGBA image with atlas dimensions
    final atlasImage = img.Image(
      width: packingResult.atlasWidth,
      height: packingResult.atlasHeight,
      numChannels: 4,
    );

    // Fill with transparent background
    img.fill(atlasImage, color: img.ColorRgba8(0, 0, 0, 0));

    // Copy each sprite to its packed position
    for (final packed in packingResult.packedSprites) {
      final sprite = packed.sprite;
      final sourceId = sprite.sourceFileId;

      // If sprite has extracted image data, use it directly
      if (sprite.hasImageData && sprite.imageBytes != null) {
        final spriteWidth = sprite.sourceWidth;
        final spriteHeight = sprite.sourceHeight;
        final imageBytes = sprite.imageBytes!;

        // Create temporary image from bytes for erosion
        img.Image spriteImage = img.Image(
          width: spriteWidth,
          height: spriteHeight,
          numChannels: 4,
        );

        // Copy bytes to image
        for (int y = 0; y < spriteHeight; y++) {
          for (int x = 0; x < spriteWidth; x++) {
            final srcOffset = (y * spriteWidth + x) * 4;
            if (srcOffset + 3 < imageBytes.length) {
              final r = imageBytes[srcOffset];
              final g = imageBytes[srcOffset + 1];
              final b = imageBytes[srcOffset + 2];
              final a = imageBytes[srcOffset + 3];
              spriteImage.setPixel(x, y, img.ColorRgba8(r, g, b, a));
            }
          }
        }

        // Apply erosion if needed
        if (erosionPixels > 0) {
          spriteImage = erosionService.applyErosion(
            spriteImage,
            erosionPixels,
            antiAlias: erosionAntiAlias,
          );
        }

        // Apply rotation FIRST if sprite was rotated during packing
        // (packedRect size is already rotation-adjusted, so rotate before resize)
        if (packed.isRotated) {
          spriteImage = _rotateImage(spriteImage, packed.rotation);
        }

        // Apply scale to match packedRect size
        // SmartPacking may have individual scales per sprite
        final targetWidth = packed.width.round();
        final targetHeight = packed.height.round();

        if (spriteImage.width != targetWidth || spriteImage.height != targetHeight) {
          spriteImage = img.copyResize(
            spriteImage,
            width: targetWidth.clamp(1, 8192),
            height: targetHeight.clamp(1, 8192),
            interpolation: img.Interpolation.linear,
          );
        }

        // Copy to atlas
        for (int y = 0; y < spriteImage.height; y++) {
          for (int x = 0; x < spriteImage.width; x++) {
            final pixel = spriteImage.getPixel(x, y);
            final dstX = packed.x + x;
            final dstY = packed.y + y;

            if (dstX >= 0 &&
                dstX < atlasImage.width &&
                dstY >= 0 &&
                dstY < atlasImage.height) {
              atlasImage.setPixel(dstX, dstY, pixel);
            }
          }
        }
      } else {
        // Fallback: extract from source image (for sprites without extracted data)
        // Use 'default' key as fallback when sourceFileId is null (legacy single-image mode)
        final effectiveSourceId = sourceId ?? 'default';
        final sourceImage = sourceImages[effectiveSourceId] as img.Image?;
        if (sourceImage == null) continue;

        final effectiveRect = sprite.effectiveRect;

        // Extract sprite region from source image (using effectiveRect for trim support)
        img.Image spriteImage = img.copyCrop(
          sourceImage,
          x: effectiveRect.left.round(),
          y: effectiveRect.top.round(),
          width: effectiveRect.width.round(),
          height: effectiveRect.height.round(),
        );

        // Apply erosion if needed
        if (erosionPixels > 0) {
          spriteImage = erosionService.applyErosion(
            spriteImage,
            erosionPixels,
            antiAlias: erosionAntiAlias,
          );
        }

        // Apply rotation FIRST if sprite was rotated during packing
        // (packedRect size is already rotation-adjusted, so rotate before resize)
        if (packed.isRotated) {
          spriteImage = _rotateImage(spriteImage, packed.rotation);
        }

        // Apply scale to match packedRect size
        // SmartPacking may have individual scales per sprite
        final targetWidth = packed.width.round();
        final targetHeight = packed.height.round();

        if (spriteImage.width != targetWidth || spriteImage.height != targetHeight) {
          spriteImage = img.copyResize(
            spriteImage,
            width: targetWidth.clamp(1, 8192),
            height: targetHeight.clamp(1, 8192),
            interpolation: img.Interpolation.linear,
          );
        }

        // Copy rotated/eroded sprite to atlas
        for (int y = 0; y < spriteImage.height; y++) {
          for (int x = 0; x < spriteImage.width; x++) {
            final pixel = spriteImage.getPixel(x, y);
            final dstX = packed.x + x;
            final dstY = packed.y + y;

            if (dstX >= 0 &&
                dstX < atlasImage.width &&
                dstY >= 0 &&
                dstY < atlasImage.height) {
              atlasImage.setPixel(dstX, dstY, pixel);
            }
          }
        }
      }
    }

    return atlasImage;
  }

  /// Rotate image by specified degrees (90, 180, 270)
  img.Image _rotateImage(img.Image source, int degrees) {
    switch (degrees) {
      case 90:
        return img.copyRotate(source, angle: 90);
      case 180:
        return img.copyRotate(source, angle: 180);
      case 270:
        return img.copyRotate(source, angle: 270);
      default:
        return source;
    }
  }

  /// Export atlas PNG to specified path
  ///
  /// [atlasImage] - Generated atlas image
  /// [pngPath] - Full path to output PNG file
  Future<void> exportPng({
    required img.Image atlasImage,
    required String pngPath,
  }) async {
    final pngBytes = img.encodePng(atlasImage);
    final file = File(pngPath);
    await file.writeAsBytes(pngBytes);
  }

  /// Encode image to specified format
  ///
  /// [atlasImage] - Generated atlas image
  /// [format] - Output format (PNG, WebP, JPEG)
  /// [quality] - Quality parameter (PNG: compression level 0-9, WebP/JPEG: quality 1-100)
  /// Returns encoded bytes
  Uint8List encodeImage({
    required img.Image atlasImage,
    required ImageOutputFormat format,
    int? quality,
  }) {
    final effectiveQuality = quality ?? format.defaultQuality;

    switch (format) {
      case ImageOutputFormat.png:
        // PNG uses compression level (0-9)
        return Uint8List.fromList(
          img.encodePng(atlasImage, level: effectiveQuality.clamp(0, 9)),
        );

      case ImageOutputFormat.jpeg:
        // JPEG uses quality (1-100)
        // JPEG doesn't support alpha, so fill transparent pixels with white
        final rgbImage = _removeAlphaChannel(atlasImage);
        return Uint8List.fromList(
          img.encodeJpg(rgbImage, quality: effectiveQuality.clamp(1, 100)),
        );
    }
  }

  /// Remove alpha channel by compositing on white background
  img.Image _removeAlphaChannel(img.Image source) {
    final result = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 3, // RGB only
    );

    // Fill with white
    img.fill(result, color: img.ColorRgb8(255, 255, 255));

    // Composite source over white background
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final a = pixel.a / 255.0;

        if (a > 0) {
          final r = (pixel.r * a + 255 * (1 - a)).round();
          final g = (pixel.g * a + 255 * (1 - a)).round();
          final b = (pixel.b * a + 255 * (1 - a)).round();
          result.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
    }

    return result;
  }

  /// Export atlas image to specified path with format
  ///
  /// [atlasImage] - Generated atlas image
  /// [outputPath] - Full path to output file (extension will be added if needed)
  /// [format] - Output format (PNG, WebP, JPEG)
  /// [quality] - Quality parameter
  Future<void> exportImage({
    required img.Image atlasImage,
    required String outputPath,
    required ImageOutputFormat format,
    int? quality,
  }) async {
    final bytes = encodeImage(
      atlasImage: atlasImage,
      format: format,
      quality: quality,
    );

    // Ensure correct extension
    String finalPath = outputPath;
    final expectedExt = '.${format.extension}';
    if (!finalPath.toLowerCase().endsWith(expectedExt)) {
      // Remove any existing extension and add correct one
      final lastDot = finalPath.lastIndexOf('.');
      if (lastDot > finalPath.lastIndexOf(Platform.pathSeparator)) {
        finalPath = finalPath.substring(0, lastDot);
      }
      finalPath = '$finalPath$expectedExt';
    }

    final file = File(finalPath);
    await file.writeAsBytes(bytes);
  }

  /// Estimate file size for given format and quality
  ///
  /// [atlasWidth] - Atlas width in pixels
  /// [atlasHeight] - Atlas height in pixels
  /// [format] - Output format
  /// [quality] - Quality parameter (affects WebP/JPEG size)
  /// Returns estimated size in KB
  double estimateFileSize({
    required int atlasWidth,
    required int atlasHeight,
    required ImageOutputFormat format,
    int? quality,
  }) {
    // Base size: 4 bytes per pixel (RGBA)
    final baseBytes = atlasWidth * atlasHeight * 4;

    // Apply format-specific compression ratio
    double ratio = format.compressionRatio;

    // Adjust for quality (WebP/JPEG only)
    if (format.supportsQuality && quality != null) {
      // Lower quality = more compression
      final qualityFactor = quality / 100.0;
      ratio *= (0.5 + 0.5 * qualityFactor); // Scale between 50% and 100% of base ratio
    }

    // PNG compression is typically 50% of raw
    if (format == ImageOutputFormat.png) {
      ratio = 0.5;
    }

    return (baseBytes * ratio) / 1024.0; // Convert to KB
  }

  /// Show save dialog and export atlas (PNG + JSON)
  ///
  /// [sourceImage] - Original source image
  /// [packingResult] - Result of bin packing
  /// [suggestedFileName] - Suggested file name (without extension)
  /// Returns (pngPath, jsonPath) tuple on success, null on cancel
  Future<(String, String)?> exportWithDialog({
    required img.Image sourceImage,
    required PackingResult packingResult,
    String suggestedFileName = 'atlas',
  }) async {
    // Show save dialog for PNG
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Atlas',
      fileName: '$suggestedFileName.png',
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (savePath == null) {
      return null; // User cancelled
    }

    // Ensure .png extension
    String pngPath = savePath;
    if (!pngPath.toLowerCase().endsWith('.png')) {
      pngPath = '$pngPath.png';
    }

    // Generate and save PNG
    final atlasImage = generateAtlasImage(
      sourceImage: sourceImage,
      packingResult: packingResult,
    );
    await exportPng(atlasImage: atlasImage, pngPath: pngPath);

    // Generate and save JSON
    final jsonPath = await exportMetadataForAtlas(
      packingResult: packingResult,
      pngPath: pngPath,
    );

    return (pngPath, jsonPath);
  }

  /// Export atlas to specific path (without dialog)
  ///
  /// [sourceImage] - Original source image
  /// [packingResult] - Result of bin packing
  /// [pngPath] - Full path for PNG file
  /// Returns (pngPath, jsonPath) tuple
  Future<(String, String)> exportToPath({
    required img.Image sourceImage,
    required PackingResult packingResult,
    required String pngPath,
  }) async {
    // Generate and save PNG
    final atlasImage = generateAtlasImage(
      sourceImage: sourceImage,
      packingResult: packingResult,
    );
    await exportPng(atlasImage: atlasImage, pngPath: pngPath);

    // Generate and save JSON
    final jsonPath = await exportMetadataForAtlas(
      packingResult: packingResult,
      pngPath: pngPath,
    );

    return (pngPath, jsonPath);
  }

  // ============================================
  // BMFont Sprite Font Export
  // ============================================

  /// Generate BMFont .fnt file content
  ///
  /// BMFont text format specification:
  /// - info: font metadata
  /// - common: lineHeight, base, scaleW, scaleH
  /// - page: texture file reference
  /// - chars: character metrics (id, x, y, width, height, xoffset, yoffset, xadvance)
  ///
  /// [packingResult] - Result from bin packing
  /// [atlasFileName] - Name of the atlas PNG file
  /// [fontName] - Display name for the font
  /// [fontSize] - Base font size (defaults to max sprite height)
  String generateFontData({
    required PackingResult packingResult,
    required String atlasFileName,
    String fontName = 'SpriteFont',
    int? fontSize,
  }) {
    final buffer = StringBuffer();

    // Calculate font metrics
    int maxHeight = 0;
    for (final packed in packingResult.packedSprites) {
      if (packed.height > maxHeight) {
        maxHeight = packed.height;
      }
    }
    final effectiveFontSize = fontSize ?? maxHeight;
    final lineHeight = (maxHeight * 1.2).round(); // 20% line spacing

    // info line
    buffer.writeln(
      'info face="$fontName" size=$effectiveFontSize bold=0 italic=0 '
      'charset="" unicode=1 stretchH=100 smooth=1 aa=1 '
      'padding=0,0,0,0 spacing=1,1 outline=0',
    );

    // common line
    buffer.writeln(
      'common lineHeight=$lineHeight base=${(maxHeight * 0.8).round()} '
      'scaleW=${packingResult.atlasWidth} scaleH=${packingResult.atlasHeight} '
      'pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0',
    );

    // page line
    buffer.writeln('page id=0 file="$atlasFileName"');

    // chars count
    buffer.writeln('chars count=${packingResult.packedSprites.length}');

    // char lines - generate character metrics for each sprite
    for (final packed in packingResult.packedSprites) {
      final charId = _extractCharCodeFromSpriteId(packed.sprite.id);
      final xadvance = packed.width + 1; // width + 1px spacing

      buffer.writeln(
        'char id=$charId '
        'x=${packed.x} y=${packed.y} '
        'width=${packed.width} height=${packed.height} '
        'xoffset=0 yoffset=${maxHeight - packed.height} '
        'xadvance=$xadvance page=0 chnl=15',
      );
    }

    return buffer.toString();
  }

  /// Extract character code from sprite ID
  ///
  /// Attempts to parse sprite ID as a character:
  /// - Single character: returns Unicode code point
  /// - "char_X" format: returns X as code point
  /// - Numeric ID: returns the number
  /// - Fallback: uses hash-based ID
  int _extractCharCodeFromSpriteId(String spriteId) {
    // Try to extract from common naming patterns

    // Pattern 1: Single character (e.g., "A", "가", "1")
    if (spriteId.length == 1) {
      return spriteId.codeUnitAt(0);
    }

    // Pattern 2: "char_X" or "character_X" format
    final charPattern = RegExp(r'^(?:char(?:acter)?_)?(.+)$', caseSensitive: false);
    final match = charPattern.firstMatch(spriteId);
    if (match != null) {
      final value = match.group(1)!;
      // If value is a single character
      if (value.length == 1) {
        return value.codeUnitAt(0);
      }
      // If value is numeric
      final numValue = int.tryParse(value);
      if (numValue != null) {
        return numValue;
      }
    }

    // Pattern 3: Numeric sprite ID
    final numericId = int.tryParse(spriteId);
    if (numericId != null) {
      return numericId;
    }

    // Pattern 4: sprite_0, sprite_1, etc. - extract index and start from 'A'
    final indexPattern = RegExp(r'(?:sprite|char|glyph)[_-]?(\d+)', caseSensitive: false);
    final indexMatch = indexPattern.firstMatch(spriteId);
    if (indexMatch != null) {
      final index = int.tryParse(indexMatch.group(1)!) ?? 0;
      // Map to ASCII printable characters starting from '!' (33)
      return 33 + index;
    }

    // Fallback: Use hashCode modulo to get a unique ID in printable ASCII range
    return 33 + (spriteId.hashCode.abs() % 94); // 94 printable ASCII chars (33-126)
  }

  /// Export BMFont .fnt file to specified path
  ///
  /// [packingResult] - Result from bin packing
  /// [fntPath] - Full path to output .fnt file
  /// [atlasFileName] - Name of the atlas PNG file
  Future<void> exportFnt({
    required PackingResult packingResult,
    required String fntPath,
    required String atlasFileName,
    String fontName = 'SpriteFont',
  }) async {
    final fntContent = generateFontData(
      packingResult: packingResult,
      atlasFileName: atlasFileName,
      fontName: fontName,
    );
    final file = File(fntPath);
    await file.writeAsString(fntContent, encoding: utf8);
  }

  /// Get .fnt file path from PNG path
  String getFntPathFromPngPath(String pngPath) {
    if (pngPath.toLowerCase().endsWith('.png')) {
      return '${pngPath.substring(0, pngPath.length - 4)}.fnt';
    }
    return '$pngPath.fnt';
  }
}
