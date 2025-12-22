import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import 'bin_packing_service.dart';

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
  AtlasMetadata generateMetadata({
    required PackingResult packingResult,
    required String atlasFileName,
    double pivotX = 0.5,
    double pivotY = 0.5,
  }) {
    // Generate sprite info map
    final sprites = <String, SpriteInfo>{};

    for (final packed in packingResult.packedSprites) {
      sprites[packed.sprite.id] = SpriteInfo(
        frame: FrameInfo(
          x: packed.x,
          y: packed.y,
          w: packed.width,
          h: packed.height,
        ),
        pivot: PivotInfo(
          x: pivotX,
          y: pivotY,
        ),
        nineSlice: null, // POC: 9-slice not implemented yet
      );
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
      animations: const {}, // POC: animations not implemented yet
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
      final sourceRect = sprite.sourceRect;

      // Extract sprite from source image and copy to atlas
      for (int y = 0; y < packed.height; y++) {
        for (int x = 0; x < packed.width; x++) {
          final srcX = sourceRect.left.round() + x;
          final srcY = sourceRect.top.round() + y;

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
  /// Returns the composed atlas image
  img.Image generateMultiSourceAtlasImage({
    required Map<String, dynamic> sourceImages,
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
      final sourceRect = sprite.sourceRect;
      final sourceId = sprite.sourceFileId;

      // If sprite has extracted image data, use it directly
      if (sprite.hasImageData && sprite.imageBytes != null) {
        final spriteWidth = sprite.width;
        final spriteHeight = sprite.height;
        final imageBytes = sprite.imageBytes!;

        // Copy from sprite's extracted image bytes (RGBA format)
        for (int y = 0; y < spriteHeight && y < packed.height; y++) {
          for (int x = 0; x < spriteWidth && x < packed.width; x++) {
            final srcOffset = (y * spriteWidth + x) * 4;
            if (srcOffset + 3 < imageBytes.length) {
              final r = imageBytes[srcOffset];
              final g = imageBytes[srcOffset + 1];
              final b = imageBytes[srcOffset + 2];
              final a = imageBytes[srcOffset + 3];

              final dstX = packed.x + x;
              final dstY = packed.y + y;

              // Bounds check for destination
              if (dstX >= 0 &&
                  dstX < atlasImage.width &&
                  dstY >= 0 &&
                  dstY < atlasImage.height) {
                atlasImage.setPixel(dstX, dstY, img.ColorRgba8(r, g, b, a));
              }
            }
          }
        }
      } else {
        // Fallback: extract from source image (for sprites without extracted data)
        final sourceImage = sourceImages[sourceId] as img.Image?;
        if (sourceImage == null) continue;

        // Extract sprite from source image and copy to atlas
        for (int y = 0; y < packed.height; y++) {
          for (int x = 0; x < packed.width; x++) {
            final srcX = sourceRect.left.round() + x;
            final srcY = sourceRect.top.round() + y;

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
    }

    return atlasImage;
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
}
