import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/editor_state_provider.dart';
import '../../providers/image_provider.dart';
import '../../theme/editor_colors.dart';
import '../canvas/slicing_overlay.dart';
import '../canvas/source_image_viewer.dart';

/// Source Panel - displays source image with slicing overlays
class SourcePanel extends ConsumerWidget {
  const SourcePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(sourceImageProvider);
    final showGrid = ref.watch(showGridProvider);
    final gridSize = ref.watch(gridSizeProvider);

    if (imageState.isLoading) {
      return _buildLoadingState(context);
    }

    if (imageState.error != null) {
      return _buildErrorState(context, ref, imageState.error!);
    }

    if (!imageState.hasImage) {
      return _buildEmptyState(context, ref);
    }

    final imageSize = Size(
      imageState.width.toDouble(),
      imageState.height.toDouble(),
    );

    return SourceImageViewer(
      image: imageState.uiImage,
      showGrid: showGrid,
      gridSize: gridSize,
      overlay: SlicingOverlay(
        imageSize: imageSize,
        transform: Matrix4.identity(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      color: EditorColors.canvasBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'Source Image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EditorColors.iconDisabled,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'File > Open Image or drag & drop',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EditorColors.iconDisabled.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openImage(ref),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Open Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      color: EditorColors.canvasBackground,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading image...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Container(
      color: EditorColors.canvasBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: EditorColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EditorColors.error,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EditorColors.iconDisabled,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openImage(ref),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _openImage(WidgetRef ref) {
    ref.read(sourceImageProvider.notifier).pickAndLoadImage();
  }
}
