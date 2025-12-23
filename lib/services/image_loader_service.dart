import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Result of image loading operation
class ImageLoadResult {
  final ui.Image? uiImage;
  final img.Image? rawImage;
  final String? filePath;
  final String? error;

  const ImageLoadResult({
    this.uiImage,
    this.rawImage,
    this.filePath,
    this.error,
  });

  bool get isSuccess => uiImage != null && rawImage != null && error == null;
  bool get isCancelled => filePath == null && error == null;
}

/// Service for loading and processing images
class ImageLoaderService {
  /// Open file picker dialog and load selected PNG image
  Future<ImageLoadResult> pickAndLoadImage() async {
    try {
      debugPrint('[ImageLoader] Opening file picker...');
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
        allowMultiple: false,
      );

      debugPrint('[ImageLoader] File picker result: ${result?.files.length ?? 0} files');

      // User cancelled
      if (result == null || result.files.isEmpty) {
        debugPrint('[ImageLoader] User cancelled or no files selected');
        return const ImageLoadResult();
      }

      final filePath = result.files.single.path;
      debugPrint('[ImageLoader] Selected file path: $filePath');
      if (filePath == null) {
        return const ImageLoadResult(error: 'Failed to get file path');
      }

      // Load the image
      return await loadImageFromPath(filePath);
    } catch (e, stackTrace) {
      debugPrint('[ImageLoader] Error picking file: $e');
      debugPrint('[ImageLoader] Stack trace: $stackTrace');
      return ImageLoadResult(error: 'Failed to pick file: $e');
    }
  }

  /// Open file picker dialog and load multiple PNG images
  Future<List<ImageLoadResult>> pickAndLoadMultipleImages() async {
    try {
      debugPrint('[ImageLoader] Opening file picker for multiple images...');
      // Open file picker with multiple selection
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
        allowMultiple: true,
      );

      debugPrint('[ImageLoader] File picker result: ${result?.files.length ?? 0} files');

      // User cancelled
      if (result == null || result.files.isEmpty) {
        debugPrint('[ImageLoader] User cancelled or no files selected');
        return [];
      }

      // Load all selected images in parallel
      final futures = <Future<ImageLoadResult>>[];
      for (final file in result.files) {
        if (file.path != null) {
          futures.add(loadImageFromPath(file.path!));
        }
      }

      final results = await Future.wait(futures);
      debugPrint('[ImageLoader] Loaded ${results.where((r) => r.isSuccess).length}/${results.length} images successfully');

      return results;
    } catch (e, stackTrace) {
      debugPrint('[ImageLoader] Error picking multiple files: $e');
      debugPrint('[ImageLoader] Stack trace: $stackTrace');
      return [ImageLoadResult(error: 'Failed to pick files: $e')];
    }
  }

  /// Load image from file path
  Future<ImageLoadResult> loadImageFromPath(String filePath) async {
    try {
      debugPrint('[ImageLoader] Loading image from path: $filePath');
      final file = File(filePath);

      // Check file exists
      if (!await file.exists()) {
        debugPrint('[ImageLoader] File not found');
        return ImageLoadResult(
          filePath: filePath,
          error: 'File not found: $filePath',
        );
      }

      // Read file bytes
      debugPrint('[ImageLoader] Reading file bytes...');
      final bytes = await file.readAsBytes();
      debugPrint('[ImageLoader] File size: ${bytes.length} bytes');

      // Decode image using compute for better performance
      debugPrint('[ImageLoader] Decoding image...');
      final decodedImage = await compute(_decodeImage, bytes);

      if (decodedImage == null) {
        debugPrint('[ImageLoader] Failed to decode image');
        return ImageLoadResult(
          filePath: filePath,
          error: 'Failed to decode image. Invalid PNG format.',
        );
      }
      debugPrint('[ImageLoader] Decoded: ${decodedImage.width}x${decodedImage.height}, channels: ${decodedImage.numChannels}');

      // Ensure RGBA format for consistent alpha channel handling
      final rawImage = decodedImage.numChannels == 4
          ? decodedImage
          : decodedImage.convert(numChannels: 4);
      debugPrint('[ImageLoader] Converted to RGBA: ${rawImage.numChannels} channels');

      // Convert to ui.Image
      debugPrint('[ImageLoader] Converting to ui.Image...');
      final uiImage = await convertToUiImage(rawImage);

      if (uiImage == null) {
        debugPrint('[ImageLoader] Failed to convert to ui.Image');
        return ImageLoadResult(
          filePath: filePath,
          rawImage: rawImage,
          error: 'Failed to convert image to Flutter format.',
        );
      }

      debugPrint('[ImageLoader] Image loaded successfully');
      return ImageLoadResult(
        uiImage: uiImage,
        rawImage: rawImage,
        filePath: filePath,
      );
    } catch (e, stackTrace) {
      debugPrint('[ImageLoader] Error loading image: $e');
      debugPrint('[ImageLoader] Stack trace: $stackTrace');
      return ImageLoadResult(
        filePath: filePath,
        error: 'Failed to load image: $e',
      );
    }
  }

  /// Decode image in isolate
  static img.Image? _decodeImage(Uint8List bytes) {
    try {
      return img.decodePng(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Convert img.Image to ui.Image
  /// Uses PNG encoding/decoding to ensure alpha channel is preserved
  Future<ui.Image?> convertToUiImage(img.Image image) async {
    try {
      // Encode to PNG (preserves alpha channel exactly like Export)
      final pngBytes = img.encodePng(image);

      // Decode PNG to ui.Image
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(pngBytes));
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error converting image: $e');
      return null;
    }
  }

  /// Get image dimensions
  static (int width, int height)? getImageSize(img.Image? image) {
    if (image == null) return null;
    return (image.width, image.height);
  }
}
