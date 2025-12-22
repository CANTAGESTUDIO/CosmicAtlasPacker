import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/editor_state_provider.dart';
import '../../theme/editor_colors.dart';

/// Widget to display source image with zoom/pan support
///
/// Implements Best Practice Tree recommendations:
/// - Interactive Canvas: minScale/maxScale, wheel zoom sensitivity, boundary margin
/// - Custom Painter: shouldRepaint optimization, layering, isComplex hint
/// - Grid Overlay: viewport-only rendering, zoom-level adaptive spacing
class SourceImageViewer extends ConsumerStatefulWidget {
  final ui.Image? image;
  final bool showGrid;
  final double gridSize;
  final Widget? overlay;
  final void Function(Matrix4 transform)? onTransformChanged;

  const SourceImageViewer({
    super.key,
    this.image,
    this.showGrid = false,
    this.gridSize = 32.0,
    this.overlay,
    this.onTransformChanged,
  });

  @override
  ConsumerState<SourceImageViewer> createState() => SourceImageViewerState();
}

class SourceImageViewerState extends ConsumerState<SourceImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  // Animation for smooth zoom
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;
  Size _lastViewportSize = Size.zero;

  // Middle mouse button panning state
  bool _isMiddleButtonPanning = false;
  Offset? _lastMiddleButtonPosition;

  /// Current zoom scale extracted from transformation matrix
  double get currentScale {
    final matrix = _transformationController.value;
    return matrix.getMaxScaleOnAxis();
  }

  /// Current zoom percentage
  double get currentZoomPercent => currentScale * 100;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);

    // Initialize animation controller for smooth zooming
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Register callbacks after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerCallbacks();
    });
  }

  void _registerCallbacks() {
    ref.read(fitToWindowCallbackProvider.notifier).state = () {
      if (_lastViewportSize != Size.zero) {
        zoomToFit(_lastViewportSize);
      }
    };

    ref.read(resetZoomCallbackProvider.notifier).state = resetTransform;

    ref.read(setZoomCallbackProvider.notifier).state = (zoomPercent) {
      setZoom(zoomPercent / 100);
    };
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _animationController?.dispose();
    super.dispose();
  }


  /// Handle middle mouse button panning
  void _handlePointerDown(PointerDownEvent event) {
    // Middle mouse button (button 4 = middle button mask)
    if (event.buttons == 4) {
      setState(() {
        _isMiddleButtonPanning = true;
        _lastMiddleButtonPosition = event.position;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isMiddleButtonPanning && _lastMiddleButtonPosition != null) {
      final delta = event.position - _lastMiddleButtonPosition!;
      _lastMiddleButtonPosition = event.position;

      // Apply pan delta to transform matrix
      final matrix = _transformationController.value.clone();
      matrix.translate(delta.dx, delta.dy);
      _transformationController.value = matrix;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isMiddleButtonPanning) {
      setState(() {
        _isMiddleButtonPanning = false;
        _lastMiddleButtonPosition = null;
      });
    }
  }

  void _onTransformChanged() {
    widget.onTransformChanged?.call(_transformationController.value);

    // Note: Don't update zoomLevelProvider here because InteractiveViewer
    // may clamp the transform internally. Zoom level is updated in _animateToMatrix
    // and _handleWheelZoom instead.

    // Trigger rebuild for zoom-dependent grid rendering
    setState(() {});
  }

  /// Reset zoom and pan to default state
  void resetTransform() {
    _animateToMatrix(Matrix4.identity());
  }

  /// Set zoom to specific scale (centered on viewport)
  void setZoom(double scale) {
    if (_lastViewportSize == Size.zero) return;

    final clampedScale = scale.clamp(ZoomPresets.min / 100, ZoomPresets.max / 100);
    final currentMatrix = _transformationController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    if ((currentScale - clampedScale).abs() < 0.001) return;

    // Calculate center of viewport
    final center = Offset(
      _lastViewportSize.width / 2,
      _lastViewportSize.height / 2,
    );

    // Apply zoom centered on viewport center
    final scaleChange = clampedScale / currentScale;

    final translateToCenter = Matrix4.identity()
      ..setEntry(0, 3, center.dx)
      ..setEntry(1, 3, center.dy);

    final scaleMatrix = Matrix4.identity()
      ..setEntry(0, 0, scaleChange)
      ..setEntry(1, 1, scaleChange);

    final translateBack = Matrix4.identity()
      ..setEntry(0, 3, -center.dx)
      ..setEntry(1, 3, -center.dy);

    final newMatrix = translateToCenter * scaleMatrix * translateBack * currentMatrix;

    _animateToMatrix(newMatrix);
  }

  /// Zoom to fit the image in the viewport
  void zoomToFit(Size viewportSize) {
    if (widget.image == null) return;

    final imageWidth = widget.image!.width.toDouble();
    final imageHeight = widget.image!.height.toDouble();

    final scaleX = viewportSize.width / imageWidth;
    final scaleY = viewportSize.height / imageHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.9; // 90% to add margin

    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(0, 3, (viewportSize.width - imageWidth * scale) / 2);
    matrix.setEntry(1, 3, (viewportSize.height - imageHeight * scale) / 2);

    _animateToMatrix(matrix);
  }

  /// Animate transformation to target matrix
  void _animateToMatrix(Matrix4 targetMatrix) {
    _animationController?.stop();

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutCubic,
    ));

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
      // Note: zoomLevelProvider is updated by the caller (toolbar/wheel zoom)
      // Do NOT update here - InteractiveViewer may clamp the transform
    });

    _animationController!.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.image == null) {
      return _buildEmptyState(context);
    }

    // Watch Space key state for pan mode
    final isSpacePressed = ref.watch(isSpacePressedProvider);
    final isPanning = isSpacePressed || _isMiddleButtonPanning;

    return MouseRegion(
        cursor: isPanning ? SystemMouseCursors.grab : MouseCursor.defer,
        child: Container(
          color: EditorColors.canvasBackground,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _lastViewportSize = constraints.biggest;

              return Listener(
                // Custom wheel zoom with adjustable sensitivity
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _handleWheelZoom(event, constraints.biggest);
                  }
                },
                // Middle mouse button panning
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: ZoomPresets.min / 100, // 0.25 (25%)
                  maxScale: ZoomPresets.max / 100, // 8.0 (800%)
                  // Allow content smaller than viewport (don't force scale to 1.0)
                  constrained: false,
                  // Disable built-in pinch zoom - use custom wheel handler instead
                  // This allows child gestures (SlicingOverlay) to work properly
                  scaleEnabled: false,
                  // Enable pan when Space is pressed or middle button is down
                  panEnabled: isPanning,
                  // Allow panning beyond image bounds with margin
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  // Optimize clipping for better performance
                  clipBehavior: Clip.hardEdge,
                  child: _buildImageStack(),
                ),
              );
            },
          ),
        ),
    );
  }

  /// Handle mouse wheel zoom with custom sensitivity and smooth interpolation
  void _handleWheelZoom(PointerScrollEvent event, Size viewportSize) {
    // Stop any ongoing animation
    _animationController?.stop();

    const double zoomSensitivity = 0.002;

    // Calculate zoom delta based on scroll direction
    final double scrollDelta = event.scrollDelta.dy;
    final double scaleFactor = 1.0 - (scrollDelta * zoomSensitivity);

    // Get current scale from transform matrix
    final Matrix4 currentMatrix = _transformationController.value.clone();
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    // Calculate new scale with bounds
    double newScale = currentScale * scaleFactor;
    newScale = newScale.clamp(ZoomPresets.min / 100, ZoomPresets.max / 100);

    // Update zoom level provider for UI display
    ref.read(zoomLevelProvider.notifier).state = newScale * 100;

    // Calculate scale change ratio
    final double scaleChange = newScale / currentScale;

    // Get the focal point (mouse position) in local coordinates
    final Offset focalPoint = event.localPosition;

    // Apply zoom centered on focal point
    final Matrix4 translateToFocal = Matrix4.identity()
      ..setEntry(0, 3, focalPoint.dx)
      ..setEntry(1, 3, focalPoint.dy);

    final Matrix4 scaleMatrix = Matrix4.identity()
      ..setEntry(0, 0, scaleChange)
      ..setEntry(1, 1, scaleChange);

    final Matrix4 translateBack = Matrix4.identity()
      ..setEntry(0, 3, -focalPoint.dx)
      ..setEntry(1, 3, -focalPoint.dy);

    final Matrix4 newMatrix =
        translateToFocal * scaleMatrix * translateBack * currentMatrix;

    _transformationController.value = newMatrix;
  }

  Widget _buildImageStack() {
    final imageSize = Size(
      widget.image!.width.toDouble(),
      widget.image!.height.toDouble(),
    );

    return Stack(
      children: [
        // Image layer with checkerboard background
        RepaintBoundary(
          child: CustomPaint(
            size: imageSize,
            painter: _CheckerboardPainter(),
            isComplex: true,
            willChange: false,
          ),
        ),
        // Image layer
        RepaintBoundary(
          child: CustomPaint(
            size: imageSize,
            painter: _ImagePainter(image: widget.image!),
            isComplex: true,
            willChange: false,
          ),
        ),
        // Grid overlay layer (only when enabled)
        if (widget.showGrid)
          RepaintBoundary(
            child: CustomPaint(
              size: imageSize,
              painter: _GridPainter(
                gridSize: _calculateAdaptiveGridSize(),
                viewportScale: currentScale,
              ),
              isComplex: false,
              willChange: true,
            ),
          ),
        // User overlay layer (for selection, sprites, etc.)
        if (widget.overlay != null)
          SizedBox(
            width: imageSize.width,
            height: imageSize.height,
            child: widget.overlay,
          ),
      ],
    );
  }

  /// Calculate adaptive grid size based on zoom level
  /// Grid becomes denser when zoomed in, sparser when zoomed out
  double _calculateAdaptiveGridSize() {
    final baseSize = widget.gridSize;
    final scale = currentScale;

    // When zoomed out (scale < 1), use larger grid spacing
    // When zoomed in (scale > 1), use base grid spacing
    if (scale < 0.5) {
      return baseSize * 4; // Very zoomed out: 4x spacing
    } else if (scale < 1.0) {
      return baseSize * 2; // Zoomed out: 2x spacing
    } else if (scale > 4.0) {
      return baseSize / 2; // Very zoomed in: half spacing
    }
    return baseSize; // Normal zoom: base spacing
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: EditorColors.canvasBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No image loaded',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a PNG image to get started',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkerboard background painter for transparency visualization
class _CheckerboardPainter extends CustomPainter {
  static const double _checkerSize = 8.0;
  static final Paint _lightPaint = Paint()..color = const Color(0xFF3C3C3C);
  static final Paint _darkPaint = Paint()..color = const Color(0xFF2C2C2C);

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += _checkerSize) {
      for (double x = 0; x < size.width; x += _checkerSize) {
        final isLight = ((x ~/ _checkerSize) + (y ~/ _checkerSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, _checkerSize, _checkerSize),
          isLight ? _lightPaint : _darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}

/// Image painter - renders the actual image
class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

/// Grid overlay painter with viewport-aware rendering
class _GridPainter extends CustomPainter {
  final double gridSize;
  final double viewportScale;

  _GridPainter({
    required this.gridSize,
    required this.viewportScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Adjust line width based on zoom level for consistent appearance
    final strokeWidth = (1.0 / viewportScale).clamp(0.5, 2.0);

    final paint = Paint()
      ..color = EditorColors.gridLine
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.viewportScale != viewportScale;
  }
}
