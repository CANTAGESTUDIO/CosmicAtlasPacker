import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/image_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../theme/editor_colors.dart';

/// Wrapper widget that provides drag & drop functionality for adding images
class DropZoneWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const DropZoneWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<DropZoneWrapper> createState() => _DropZoneWrapperState();
}

class _DropZoneWrapperState extends ConsumerState<DropZoneWrapper> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) async {
        setState(() => _isDragging = false);

        // Filter for PNG files only
        final pngPaths = details.files
            .where((file) => file.path.toLowerCase().endsWith('.png'))
            .map((file) => file.path)
            .toList();

        if (pngPaths.isNotEmpty) {
          await ref.read(multiImageProvider.notifier).addImagesFromPaths(pngPaths);

          // Sync active source to sourceImageProvider for backward compatibility
          final activeSource = ref.read(activeSourceProvider);
          if (activeSource != null) {
            ref.read(sourceImageProvider.notifier).setFromSource(
              uiImage: activeSource.uiImage,
              rawImage: activeSource.rawImage,
              filePath: activeSource.filePath,
              fileName: activeSource.fileName,
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${pngPaths.length} image(s)'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (details.files.isNotEmpty) {
          // Files were dropped but none were PNG
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only PNG files are supported'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Stack(
        children: [
          widget.child,

          // Drop overlay
          if (_isDragging)
            Positioned.fill(
              child: _DropOverlay(),
            ),
        ],
      ),
    );
  }
}

/// Visual overlay shown during drag with animation
class _DropOverlay extends StatefulWidget {
  @override
  State<_DropOverlay> createState() => _DropOverlayState();
}

class _DropOverlayState extends State<_DropOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: EditorColors.primary.withValues(alpha: _pulseAnimation.value * 0.3),
            border: Border.all(
              color: EditorColors.primary.withValues(alpha: _pulseAnimation.value + 0.4),
              width: 3,
            ),
          ),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                decoration: BoxDecoration(
                  color: EditorColors.panelBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: EditorColors.primary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EditorColors.primary.withValues(alpha: _pulseAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EditorColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 56,
                        color: EditorColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Drop PNG files here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: EditorColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add source images to the project',
                      style: TextStyle(
                        fontSize: 13,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
