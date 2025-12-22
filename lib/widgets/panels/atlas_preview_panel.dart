import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../providers/editor_state_provider.dart';
import '../../providers/packing_provider.dart';
import '../../services/bin_packing_service.dart';
import '../../theme/editor_colors.dart';

/// Atlas Preview Panel - displays packed atlas result with interactive zoom/pan
class AtlasPreviewPanel extends ConsumerStatefulWidget {
  const AtlasPreviewPanel({super.key});

  @override
  ConsumerState<AtlasPreviewPanel> createState() => _AtlasPreviewPanelState();
}

class _AtlasPreviewPanelState extends ConsumerState<AtlasPreviewPanel> {
  final TransformationController _transformController =
      TransformationController();
  String? _hoveredSpriteId;
  Size _lastViewportSize = Size.zero;
  (int, int)? _lastAtlasSize;
  bool _needsFitToView = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Reset zoom to fit atlas in viewport
  void _resetZoom(Size viewportSize, int atlasWidth, int atlasHeight) {
    if (atlasWidth == 0 || atlasHeight == 0) return;

    final scaleX = viewportSize.width / atlasWidth;
    final scaleY = viewportSize.height / atlasHeight;
    final rawScale = (scaleX < scaleY ? scaleX : scaleY) * 0.9;

    // Clamp to valid zoom range
    final minScale = ZoomPresets.min / 100;
    final maxScale = ZoomPresets.max / 100;
    final scale = rawScale.clamp(minScale, maxScale);

    final offsetX = (viewportSize.width - atlasWidth * scale) / 2;
    final offsetY = (viewportSize.height - atlasHeight * scale) / 2;

    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(0, 3, offsetX);
    matrix.setEntry(1, 3, offsetY);

    _transformController.value = matrix;

    // Sync UI with actual scale
    ref.read(zoomLevelProvider.notifier).state = (scale * 100).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final packingResult = ref.watch(packingResultProvider);
    final atlasSize = ref.watch(atlasSizeProvider);
    final efficiency = ref.watch(packingEfficiencyProvider);
    final atlasPreviewAsync = ref.watch(atlasPreviewImageProvider);

    // Show empty state when no packing result
    if (packingResult == null || packingResult.packedSprites.isEmpty) {
      _lastAtlasSize = null;
      return _buildEmptyState(context);
    }

    // Check if atlas size changed - need to fit to view
    if (_lastAtlasSize != atlasSize) {
      _lastAtlasSize = atlasSize;
      _needsFitToView = true;
    }

    return Container(
      color: EditorColors.canvasBackground,
      child: Column(
        children: [
          // Atlas info header
          _buildInfoHeader(atlasSize, efficiency, packingResult),
          // Divider
          Container(height: 1, color: EditorColors.divider),
          // Atlas preview canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _lastViewportSize = constraints.biggest;

                // Auto fit-to-view when atlas changes
                if (_needsFitToView) {
                  _needsFitToView = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _resetZoom(_lastViewportSize, atlasSize.$1, atlasSize.$2);
                    }
                  });
                }

                return Stack(
                  children: [
                    // Interactive canvas with zoom/pan
                    InteractiveViewer(
                      transformationController: _transformController,
                      constrained: false,
                      minScale: ZoomPresets.min / 100, // 1.0 (100%)
                      maxScale: ZoomPresets.max / 100, // 4.0 (400%)
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      onInteractionUpdate: (details) {
                        // Update UI when zooming via wheel or gesture
                        final scale = _transformController.value.getMaxScaleOnAxis();
                        final percent = (scale * 100).roundToDouble();
                        ref.read(zoomLevelProvider.notifier).state = percent;
                      },
                      child: MouseRegion(
                        onHover: (event) {
                          _handleHover(event.localPosition, packingResult);
                        },
                        onExit: (_) {
                          if (_hoveredSpriteId != null) {
                            setState(() => _hoveredSpriteId = null);
                          }
                        },
                        child: CustomPaint(
                          size: Size(
                            atlasSize.$1.toDouble(),
                            atlasSize.$2.toDouble(),
                          ),
                          painter: AtlasPreviewPainter(
                            packingResult: packingResult,
                            atlasImage: atlasPreviewAsync.valueOrNull,
                            hoveredSpriteId: _hoveredSpriteId,
                          ),
                        ),
                      ),
                    ),
                    // Loading indicator while generating atlas preview
                    if (atlasPreviewAsync.isLoading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: EditorColors.panelBackground.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: EditorColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Rendering...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: EditorColors.iconDefault,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Zoom controls
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _buildZoomControls(
                        constraints.biggest,
                        atlasSize.$1,
                        atlasSize.$2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: EditorColors.canvasBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 48,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'Atlas Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EditorColors.iconDisabled,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Slice sprites to see packing result',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EditorColors.iconDisabled.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoHeader(
    (int, int) atlasSize,
    double efficiency,
    PackingResult result,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: EditorColors.panelBackground,
      child: Row(
        children: [
          // Atlas size
          Icon(Icons.aspect_ratio, size: 16, color: EditorColors.iconDefault),
          const SizedBox(width: 6),
          Text(
            '${atlasSize.$1} × ${atlasSize.$2}',
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDefault,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          // Sprite count
          Icon(Icons.layers, size: 16, color: EditorColors.iconDefault),
          const SizedBox(width: 6),
          Text(
            '${result.packedSprites.length} sprites',
            style: TextStyle(fontSize: 12, color: EditorColors.iconDefault),
          ),
          const Spacer(),
          // Efficiency - text label instead of icon
          Text(
            'Efficiency ${efficiency.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: _getEfficiencyColor(efficiency),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return EditorColors.secondary;
    if (efficiency >= 60) return EditorColors.warning;
    return EditorColors.error;
  }

  Widget _buildZoomControls(Size viewportSize, int atlasWidth, int atlasHeight) {
    final zoomLevel = ref.watch(zoomLevelProvider);

    return Container(
      decoration: BoxDecoration(
        color: EditorColors.panelBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EditorColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom out
          IconButton(
            icon: Icon(Icons.remove, size: 18, color: EditorColors.iconDefault),
            onPressed: zoomLevel <= ZoomPresets.min ? null : () {
              final actualScale = _transformController.value.getMaxScaleOnAxis();
              final currentPercent = (actualScale * 100).roundToDouble();
              final target = ZoomPresets.zoomOut(currentPercent);
              if (_zoom(target / 100)) {
                ref.read(zoomLevelProvider.notifier).state = target;
              }
            },
            tooltip: 'Zoom Out',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Zoom level display
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '${zoomLevel.round()}%',
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDefault,
              ),
            ),
          ),
          // Zoom in
          IconButton(
            icon: Icon(Icons.add, size: 18, color: EditorColors.iconDefault),
            onPressed: zoomLevel >= ZoomPresets.max ? null : () {
              final actualScale = _transformController.value.getMaxScaleOnAxis();
              final currentPercent = (actualScale * 100).roundToDouble();
              final target = ZoomPresets.zoomIn(currentPercent);
              if (_zoom(target / 100)) {
                ref.read(zoomLevelProvider.notifier).state = target;
              }
            },
            tooltip: 'Zoom In',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Fit to view
          IconButton(
            icon: Icon(Icons.fit_screen, size: 18, color: EditorColors.iconDefault),
            onPressed: () => _resetZoom(viewportSize, atlasWidth, atlasHeight),
            tooltip: 'Fit to View',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  bool _zoom(double targetScale) {
    if (_lastViewportSize == Size.zero) return false;

    final currentMatrix = _transformController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    // Clamp scale using ZoomPresets
    final minScale = ZoomPresets.min / 100;
    final maxScale = ZoomPresets.max / 100;
    if (targetScale < minScale || targetScale > maxScale) return false;

    // Check if target scale is close to current scale
    if ((currentScale - targetScale).abs() < 0.01) return false;

    // Get current translation (pan offset)
    final currentTranslateX = currentMatrix.getTranslation().x;
    final currentTranslateY = currentMatrix.getTranslation().y;

    // Calculate viewport center
    final centerX = _lastViewportSize.width / 2;
    final centerY = _lastViewportSize.height / 2;

    // Calculate scale ratio
    final scaleRatio = targetScale / currentScale;

    // Adjust translation to zoom toward center
    final newTranslateX = centerX - (centerX - currentTranslateX) * scaleRatio;
    final newTranslateY = centerY - (centerY - currentTranslateY) * scaleRatio;

    // Create new matrix with absolute scale (not relative)
    final newMatrix = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(0, 3, newTranslateX)
      ..setEntry(1, 3, newTranslateY);

    _transformController.value = newMatrix;
    return true;
  }

  void _handleHover(Offset localPosition, PackingResult result) {
    // localPosition is already in atlas coordinates since MouseRegion
    // is inside InteractiveViewer and wraps the CustomPaint directly

    // Find sprite under cursor
    String? hoveredId;
    for (final packed in result.packedSprites.reversed) {
      if (packed.packedRect.contains(localPosition)) {
        hoveredId = packed.sprite.id;
        break;
      }
    }

    if (hoveredId != _hoveredSpriteId) {
      setState(() => _hoveredSpriteId = hoveredId);
    }
  }
}

/// CustomPainter for rendering atlas preview
/// Uses pre-generated atlas image (same as export) for accurate transparency display
class AtlasPreviewPainter extends CustomPainter {
  final PackingResult packingResult;
  final ui.Image? atlasImage;
  final String? hoveredSpriteId;

  AtlasPreviewPainter({
    required this.packingResult,
    this.atlasImage,
    this.hoveredSpriteId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final atlasRect = Rect.fromLTWH(
      0,
      0,
      packingResult.atlasWidth.toDouble(),
      packingResult.atlasHeight.toDouble(),
    );

    // Draw atlas background (checkerboard pattern for transparency)
    _drawCheckerboard(canvas, atlasRect);

    // Draw the pre-generated atlas image (shows exact export result)
    if (atlasImage != null) {
      canvas.drawImage(
        atlasImage!,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.none,
      );
    }

    // Draw atlas border
    final borderPaint = Paint()
      ..color = EditorColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(atlasRect, borderPaint);

    // Draw sprite overlays (borders and labels)
    for (final packed in packingResult.packedSprites) {
      _drawSpriteOverlay(canvas, packed);
    }
  }

  void _drawCheckerboard(Canvas canvas, Rect rect) {
    const checkerSize = 8.0;
    final lightPaint = Paint()..color = const Color(0xFF3A3A3A);
    final darkPaint = Paint()..color = const Color(0xFF2A2A2A);

    canvas.save();
    canvas.clipRect(rect);

    for (double y = rect.top; y < rect.bottom; y += checkerSize) {
      for (double x = rect.left; x < rect.right; x += checkerSize) {
        final isLight = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }

    canvas.restore();
  }

  /// Draw sprite overlay (border and label only, image is already in atlasImage)
  void _drawSpriteOverlay(Canvas canvas, PackedSprite packed) {
    final rect = packed.packedRect;
    final isHovered = packed.sprite.id == hoveredSpriteId;

    // Draw bounding box
    final borderPaint = Paint()
      ..color = isHovered ? EditorColors.selectedSprite : EditorColors.spriteOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.0 : 1.0;
    canvas.drawRect(rect, borderPaint);

    // Draw sprite ID label
    _drawSpriteLabel(canvas, packed, isHovered);
  }

  void _drawSpriteLabel(Canvas canvas, PackedSprite packed, bool isHovered) {
    final rect = packed.packedRect;
    const borderWidth = 2.0; // Account for border stroke width

    // Only show labels for larger sprites or when hovered
    if (rect.width < 24 || rect.height < 16) {
      if (!isHovered) return;
    }

    final textStyle = ui.TextStyle(
      color: isHovered ? EditorColors.selectedSprite : EditorColors.spriteOutline,
      fontSize: 10,
      fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
    );

    // Limit text width to fit within sprite bounds (inside border)
    final maxTextWidth = rect.width - borderWidth * 2 - 4; // border + padding
    if (maxTextWidth <= 0) return;

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: 10,
      ellipsis: '…',
      maxLines: 1,
    ))
      ..pushStyle(textStyle)
      ..addText(packed.sprite.id);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: maxTextWidth));

    // Position label inside sprite, below the top border
    final labelX = rect.left + borderWidth + 2;
    final labelY = rect.top + borderWidth + 2;

    // Check if label fits within sprite height (accounting for border)
    if (paragraph.height + borderWidth * 2 + 4 > rect.height) return;

    // Draw label background for readability (inside sprite bounds)
    final bgWidth = paragraph.width.clamp(0.0, maxTextWidth) + 4;
    final bgRect = Rect.fromLTWH(
      labelX - 1,
      labelY - 1,
      bgWidth,
      paragraph.height + 2,
    );
    canvas.drawRect(
      bgRect,
      Paint()..color = EditorColors.canvasBackground.withValues(alpha: 0.8),
    );

    canvas.drawParagraph(paragraph, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(covariant AtlasPreviewPainter oldDelegate) {
    return packingResult != oldDelegate.packingResult ||
        atlasImage != oldDelegate.atlasImage ||
        hoveredSpriteId != oldDelegate.hoveredSpriteId;
  }
}
