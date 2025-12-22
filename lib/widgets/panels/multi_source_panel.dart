import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/editor_state_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../theme/editor_colors.dart';
import '../canvas/slicing_overlay.dart';
import '../canvas/source_image_viewer.dart';
import '../tabs/source_tabs.dart';

/// Multi-source Panel - displays source images with tabs and slicing overlays
class MultiSourcePanel extends ConsumerWidget {
  const MultiSourcePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiImageState = ref.watch(multiImageProvider);
    final showGrid = ref.watch(showGridProvider);
    final gridSize = ref.watch(gridSizeProvider);

    return Column(
      children: [
        // Tab bar (only show when there are sources)
        if (multiImageState.hasImages) const SourceTabs(),

        // Content area
        Expanded(
          child: _buildContent(context, ref, multiImageState, showGrid, gridSize),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MultiImageState multiImageState,
    bool showGrid,
    double gridSize,
  ) {
    if (multiImageState.isLoading) {
      return _buildLoadingState(context);
    }

    if (multiImageState.error != null) {
      return _buildErrorState(context, ref, multiImageState.error!);
    }

    if (!multiImageState.hasImages) {
      return _buildEmptyState(context, ref);
    }

    // Get active source
    final activeSource = multiImageState.activeSource;
    if (activeSource == null) {
      return _buildEmptyState(context, ref);
    }

    final imageSize = Size(
      activeSource.width.toDouble(),
      activeSource.height.toDouble(),
    );

    return SourceImageViewer(
      image: activeSource.uiImage,
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
              'Source Images',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EditorColors.iconDisabled,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'File > Open Images or drag & drop',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EditorColors.iconDisabled.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openImages(ref),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Open Images'),
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
            Text('Loading images...'),
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
              'Error loading images',
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
              onPressed: () {
                ref.read(multiImageProvider.notifier).clearError();
                _openImages(ref);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _openImages(WidgetRef ref) {
    // Prevent duplicate calls while loading
    if (ref.read(multiImageProvider).isLoading) return;

    ref.read(multiImageProvider.notifier).pickAndLoadImages();
  }
}
