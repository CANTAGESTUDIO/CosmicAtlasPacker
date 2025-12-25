import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/texture_compression_settings.dart';

/// Result of texture compression operation
class TextureCompressionResult {
  final bool success;
  final String? outputPath;
  final String? errorMessage;
  final int? fileSizeBytes;
  final Duration? compressionTime;

  const TextureCompressionResult({
    required this.success,
    this.outputPath,
    this.errorMessage,
    this.fileSizeBytes,
    this.compressionTime,
  });

  factory TextureCompressionResult.success({
    required String outputPath,
    int? fileSizeBytes,
    Duration? compressionTime,
  }) {
    return TextureCompressionResult(
      success: true,
      outputPath: outputPath,
      fileSizeBytes: fileSizeBytes,
      compressionTime: compressionTime,
    );
  }

  factory TextureCompressionResult.failure(String errorMessage) {
    return TextureCompressionResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Service for compressing textures using external CLI tools (astcenc, etc2comp)
///
/// Supports:
/// - ASTC compression via ARM's astcenc
/// - ETC2 compression via Google's etc2comp
///
/// The binaries should be bundled in the app at:
/// - macOS: Contents/Resources/Tools/
class TextureCompressionService {
  /// Cached path to tools directory
  String? _toolsPath;

  /// Get the path to bundled tools directory
  Future<String> get toolsPath async {
    if (_toolsPath != null) return _toolsPath!;

    if (Platform.isMacOS) {
      // For macOS app bundle: Contents/Resources/Tools/
      final executablePath = Platform.resolvedExecutable;
      final contentsPath = path.dirname(path.dirname(executablePath));
      _toolsPath = path.join(contentsPath, 'Resources', 'Tools');
    } else if (Platform.isWindows) {
      // For Windows: same directory as executable
      final executablePath = Platform.resolvedExecutable;
      _toolsPath = path.join(path.dirname(executablePath), 'tools');
    } else {
      // Linux or other: /usr/local/bin or app directory
      final executablePath = Platform.resolvedExecutable;
      _toolsPath = path.join(path.dirname(executablePath), 'tools');
    }

    return _toolsPath!;
  }

  /// Get path to astcenc binary
  Future<String> get astcencPath async {
    final tools = await toolsPath;
    if (Platform.isMacOS) {
      return path.join(tools, 'astcenc-avx2'); // Universal binary
    } else if (Platform.isWindows) {
      return path.join(tools, 'astcenc-avx2.exe');
    } else {
      return path.join(tools, 'astcenc-avx2');
    }
  }

  /// Get path to etc2comp binary
  Future<String> get etc2compPath async {
    final tools = await toolsPath;
    if (Platform.isMacOS) {
      return path.join(tools, 'EtcTool');
    } else if (Platform.isWindows) {
      return path.join(tools, 'EtcTool.exe');
    } else {
      return path.join(tools, 'EtcTool');
    }
  }

  /// Check if astcenc is available
  Future<bool> isAstcencAvailable() async {
    try {
      final astcPath = await astcencPath;
      final file = File(astcPath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Check if etc2comp is available
  Future<bool> isEtc2compAvailable() async {
    try {
      final etcPath = await etc2compPath;
      final file = File(etcPath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Get ASTC block size string for astcenc CLI
  String _getAstcBlockSizeArg(TextureCompressionFormat format) {
    switch (format) {
      case TextureCompressionFormat.astc4x4:
        return '4x4';
      case TextureCompressionFormat.astc6x6:
        return '6x6';
      case TextureCompressionFormat.astc8x8:
        return '8x8';
      case TextureCompressionFormat.astc10x10:
        return '10x10';
      case TextureCompressionFormat.astc12x12:
        return '12x12';
      default:
        return '6x6'; // Default fallback
    }
  }

  /// Get ETC2 format string for etc2comp CLI
  String _getEtc2FormatArg(TextureCompressionFormat format) {
    switch (format) {
      case TextureCompressionFormat.etc2_4bit:
        return 'RGB8'; // ETC2 RGB (no alpha) - 4 bpp
      case TextureCompressionFormat.etc2_8bit:
        return 'RGBA8'; // ETC2 RGBA (with alpha) - 8 bpp
      default:
        return 'RGBA8'; // Default to RGBA
    }
  }

  /// Compress PNG to ASTC format using astcenc
  ///
  /// [inputPngPath] - Path to input PNG file
  /// [outputPath] - Path to output file (will add .astc extension if needed)
  /// [format] - ASTC format/block size to use
  /// [quality] - Compression quality: 'fastest', 'fast', 'medium', 'thorough', 'exhaustive'
  Future<TextureCompressionResult> compressToAstc({
    required String inputPngPath,
    required String outputPath,
    required TextureCompressionFormat format,
    String quality = 'medium',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Check if tool is available
      if (!await isAstcencAvailable()) {
        return TextureCompressionResult.failure(
          'astcenc tool not found. Please ensure it is bundled with the app.',
        );
      }

      // Ensure output has correct extension
      String finalOutputPath = outputPath;
      if (!finalOutputPath.endsWith('.astc')) {
        final lastDot = finalOutputPath.lastIndexOf('.');
        if (lastDot > 0) {
          finalOutputPath = '${finalOutputPath.substring(0, lastDot)}.astc';
        } else {
          finalOutputPath = '$finalOutputPath.astc';
        }
      }

      // Build command arguments
      final astcPath = await astcencPath;
      final blockSize = _getAstcBlockSizeArg(format);

      // astcenc -cl input.png output.astc 6x6 -medium
      final args = [
        '-cl', // Compress LDR (Low Dynamic Range)
        inputPngPath,
        finalOutputPath,
        blockSize,
        '-$quality',
      ];

      debugPrint('Running astcenc: $astcPath ${args.join(' ')}');

      final result = await Process.run(astcPath, args);

      stopwatch.stop();

      if (result.exitCode != 0) {
        return TextureCompressionResult.failure(
          'astcenc failed with exit code ${result.exitCode}: ${result.stderr}',
        );
      }

      // Get output file size
      final outputFile = File(finalOutputPath);
      final fileSize = outputFile.existsSync() ? outputFile.lengthSync() : null;

      return TextureCompressionResult.success(
        outputPath: finalOutputPath,
        fileSizeBytes: fileSize,
        compressionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TextureCompressionResult.failure('ASTC compression error: $e');
    }
  }

  /// Compress PNG to ETC2 format using etc2comp
  ///
  /// [inputPngPath] - Path to input PNG file
  /// [outputPath] - Path to output file (will add .ktx extension)
  /// [format] - ETC2 format to use
  /// [effort] - Compression effort (0-100, higher = slower but better quality)
  Future<TextureCompressionResult> compressToEtc2({
    required String inputPngPath,
    required String outputPath,
    required TextureCompressionFormat format,
    int effort = 60,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Check if tool is available
      if (!await isEtc2compAvailable()) {
        return TextureCompressionResult.failure(
          'etc2comp (EtcTool) not found. Please ensure it is bundled with the app.',
        );
      }

      // Ensure output has correct extension
      String finalOutputPath = outputPath;
      if (!finalOutputPath.endsWith('.ktx')) {
        final lastDot = finalOutputPath.lastIndexOf('.');
        if (lastDot > 0) {
          finalOutputPath = '${finalOutputPath.substring(0, lastDot)}.ktx';
        } else {
          finalOutputPath = '$finalOutputPath.ktx';
        }
      }

      // Build command arguments
      final etcPath = await etc2compPath;
      final etcFormat = _getEtc2FormatArg(format);

      // EtcTool input.png -format RGBA8 -output output.ktx -effort 60
      final args = [
        inputPngPath,
        '-format',
        etcFormat,
        '-output',
        finalOutputPath,
        '-effort',
        effort.toString(),
      ];

      debugPrint('Running etc2comp: $etcPath ${args.join(' ')}');

      final result = await Process.run(etcPath, args);

      stopwatch.stop();

      if (result.exitCode != 0) {
        return TextureCompressionResult.failure(
          'etc2comp failed with exit code ${result.exitCode}: ${result.stderr}',
        );
      }

      // Get output file size
      final outputFile = File(finalOutputPath);
      final fileSize = outputFile.existsSync() ? outputFile.lengthSync() : null;

      return TextureCompressionResult.success(
        outputPath: finalOutputPath,
        fileSizeBytes: fileSize,
        compressionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TextureCompressionResult.failure('ETC2 compression error: $e');
    }
  }

  /// Compress PNG to specified texture format
  ///
  /// Automatically selects the appropriate tool based on format.
  /// [inputPngPath] - Path to input PNG file
  /// [outputPath] - Path to output file (extension will be adjusted)
  /// [format] - Texture compression format
  /// [quality] - Quality level (0-100, maps to tool-specific options)
  Future<TextureCompressionResult> compress({
    required String inputPngPath,
    required String outputPath,
    required TextureCompressionFormat format,
    int quality = 70,
  }) async {
    if (format.isAstcFormat) {
      // Map quality (0-100) to astcenc quality levels
      String astcQuality;
      if (quality < 20) {
        astcQuality = 'fastest';
      } else if (quality < 40) {
        astcQuality = 'fast';
      } else if (quality < 60) {
        astcQuality = 'medium';
      } else if (quality < 80) {
        astcQuality = 'thorough';
      } else {
        astcQuality = 'exhaustive';
      }

      return compressToAstc(
        inputPngPath: inputPngPath,
        outputPath: outputPath,
        format: format,
        quality: astcQuality,
      );
    } else if (format.isEtc2Format) {
      return compressToEtc2(
        inputPngPath: inputPngPath,
        outputPath: outputPath,
        format: format,
        effort: quality,
      );
    } else {
      return TextureCompressionResult.failure(
        'Unsupported texture format: ${format.displayName}',
      );
    }
  }

  /// Convert ASTC file to KTX format for better compatibility
  ///
  /// Some game engines prefer KTX container format.
  /// This uses astcenc's built-in KTX output.
  Future<TextureCompressionResult> compressToAstcKtx({
    required String inputPngPath,
    required String outputPath,
    required TextureCompressionFormat format,
    String quality = 'medium',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (!await isAstcencAvailable()) {
        return TextureCompressionResult.failure(
          'astcenc tool not found. Please ensure it is bundled with the app.',
        );
      }

      // Ensure output has .ktx extension
      String finalOutputPath = outputPath;
      if (!finalOutputPath.endsWith('.ktx')) {
        final lastDot = finalOutputPath.lastIndexOf('.');
        if (lastDot > 0) {
          finalOutputPath = '${finalOutputPath.substring(0, lastDot)}.ktx';
        } else {
          finalOutputPath = '$finalOutputPath.ktx';
        }
      }

      final astcPath = await astcencPath;
      final blockSize = _getAstcBlockSizeArg(format);

      // astcenc automatically outputs KTX when output extension is .ktx
      final args = [
        '-cl',
        inputPngPath,
        finalOutputPath,
        blockSize,
        '-$quality',
      ];

      debugPrint('Running astcenc (KTX): $astcPath ${args.join(' ')}');

      final result = await Process.run(astcPath, args);

      stopwatch.stop();

      if (result.exitCode != 0) {
        return TextureCompressionResult.failure(
          'astcenc KTX failed: ${result.stderr}',
        );
      }

      final outputFile = File(finalOutputPath);
      final fileSize = outputFile.existsSync() ? outputFile.lengthSync() : null;

      return TextureCompressionResult.success(
        outputPath: finalOutputPath,
        fileSizeBytes: fileSize,
        compressionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TextureCompressionResult.failure('ASTC KTX compression error: $e');
    }
  }

  /// Get the output file extension for a given format
  String getOutputExtension(TextureCompressionFormat format) {
    if (format.isAstcFormat) {
      return '.ktx'; // Use KTX for better compatibility
    } else if (format.isEtc2Format) {
      return '.ktx';
    } else {
      return '.ktx'; // Default to KTX
    }
  }

  /// Check if compression tools are properly set up
  Future<Map<String, bool>> checkToolsAvailability() async {
    return {
      'astcenc': await isAstcencAvailable(),
      'etc2comp': await isEtc2compAvailable(),
    };
  }

  /// Get version info for available tools
  Future<Map<String, String?>> getToolVersions() async {
    final versions = <String, String?>{};

    // Try to get astcenc version
    try {
      if (await isAstcencAvailable()) {
        final astcPath = await astcencPath;
        final result = await Process.run(astcPath, ['-help']);
        // Parse version from output
        final output = result.stdout.toString();
        final versionMatch = RegExp(r'astcenc (\d+\.\d+)').firstMatch(output);
        versions['astcenc'] = versionMatch?.group(1) ?? 'unknown';
      }
    } catch (e) {
      versions['astcenc'] = null;
    }

    // Try to get etc2comp version
    try {
      if (await isEtc2compAvailable()) {
        // EtcTool doesn't have a version flag, so we just note it's available
        versions['etc2comp'] = 'available';
      }
    } catch (e) {
      versions['etc2comp'] = null;
    }

    return versions;
  }
}

/// Extension methods for TextureCompressionFormat
extension TextureCompressionFormatExtensions on TextureCompressionFormat {
  /// Check if this is an ASTC format
  bool get isAstcFormat {
    switch (this) {
      case TextureCompressionFormat.astc4x4:
      case TextureCompressionFormat.astc6x6:
      case TextureCompressionFormat.astc8x8:
      case TextureCompressionFormat.astc10x10:
      case TextureCompressionFormat.astc12x12:
        return true;
      default:
        return false;
    }
  }

  /// Check if this is an ETC2 format
  bool get isEtc2Format {
    switch (this) {
      case TextureCompressionFormat.etc2_4bit:
      case TextureCompressionFormat.etc2_8bit:
        return true;
      default:
        return false;
    }
  }
}
