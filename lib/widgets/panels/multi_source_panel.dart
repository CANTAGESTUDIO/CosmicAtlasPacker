import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sprite_region.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../theme/editor_colors.dart';
import '../canvas/slicing_overlay.dart';
import '../canvas/source_image_viewer.dart';
import '../tabs/source_sidebar.dart';

/// Multi-source Panel - displays source images with vertical sidebar and slicing overlays
class MultiSourcePanel extends ConsumerWidget {
  const MultiSourcePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiImageState = ref.watch(multiImageProvider);
    final showGrid = ref.watch(showGridProvider);
    final gridSize = ref.watch(gridSizeProvider);

    return Row(
      children: [
        // Vertical sidebar for source images (like reference images in design tools)
        if (multiImageState.hasImages) const SourceSidebar(),

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

    // Check for multi-selection (2개 이상 선택시 그리드 모드)
    final selectedSources = ref.watch(selectedSourcesProvider);
    if (selectedSources.length > 1) {
      return _buildGridView(context, ref, selectedSources, showGrid, gridSize);
    }

    // Single selection: Get active source
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

  /// Calculate column count based on selected source count
  int _getColumnCount(int count) {
    if (count <= 1) return 1;
    if (count <= 4) return 2;
    return 3; // 5개 이상
  }

  /// Calculate scale to fit image in given constraints
  double _calculateFitScale(Size imageSize, Size containerSize) {
    if (imageSize.isEmpty || containerSize.isEmpty) return 1.0;
    final scaleX = containerSize.width / imageSize.width;
    final scaleY = containerSize.height / imageSize.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  /// Build grid view for multiple selected sources
  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    List<LoadedSourceImage> sources,
    bool showGrid,
    double gridSize,
  ) {
    final columnCount = _getColumnCount(sources.length);

    return Container(
      color: EditorColors.canvasBackground,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: sources.length,
        itemBuilder: (context, index) {
          final source = sources[index];
          return _buildGridCell(context, ref, source);
        },
      ),
    );
  }

  /// Build individual grid cell with image and slicing overlay
  Widget _buildGridCell(
    BuildContext context,
    WidgetRef ref,
    LoadedSourceImage source,
  ) {
    final isActive = ref.watch(multiImageProvider).activeSourceId == source.id;
    final multiSpriteState = ref.watch(multiSpriteProvider);
    final sprites = multiSpriteState.getSpritesForSource(source.id);

    return GestureDetector(
      onTap: () {
        ref.read(multiImageProvider.notifier).setActiveSource(source.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: EditorColors.panelBackground,
          border: Border.all(
            color: isActive ? EditorColors.primary : EditorColors.divider,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = Size(
                source.width.toDouble(),
                source.height.toDouble(),
              );
              final scale = _calculateFitScale(imageSize, constraints.biggest);

              return Stack(
                children: [
                  // Background
                  Positioned.fill(
                    child: Container(color: EditorColors.canvasBackground),
                  ),
                  // Image centered
                  Center(
                    child: SizedBox(
                      width: imageSize.width * scale,
                      height: imageSize.height * scale,
                      child: RawImage(
                        image: source.uiImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Slicing Overlay (스프라이트 영역 표시)
                  if (sprites.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridCellOverlayPainter(
                          sprites: sprites,
                          imageSize: imageSize,
                          containerSize: constraints.biggest,
                          scale: scale,
                        ),
                      ),
                    ),
                  // Filename label at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              source.fileName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (sprites.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: EditorColors.primary.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${sprites.length}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Active indicator
                  if (isActive)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: EditorColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: EditorColors.primary.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
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

/// Custom painter for grid cell sprite overlay
class _GridCellOverlayPainter extends CustomPainter {
  final List<SpriteRegion> sprites;
  final Size imageSize;
  final Size containerSize;
  final double scale;

  _GridCellOverlayPainter({
    required this.sprites,
    required this.imageSize,
    required this.containerSize,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = EditorColors.primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = EditorColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Calculate offset to center image in container
    final offsetX = (containerSize.width - imageSize.width * scale) / 2;
    final offsetY = (containerSize.height - imageSize.height * scale) / 2;

    for (final sprite in sprites) {
      final rect = Rect.fromLTWH(
        offsetX + sprite.sourceRect.left * scale,
        offsetY + sprite.sourceRect.top * scale,
        sprite.sourceRect.width * scale,
        sprite.sourceRect.height * scale,
      );
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridCellOverlayPainter oldDelegate) {
    return sprites != oldDelegate.sprites ||
        scale != oldDelegate.scale ||
        imageSize != oldDelegate.imageSize ||
        containerSize != oldDelegate.containerSize;
  }
}
