import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/editor_colors.dart';

/// Draggable dialog wrapper that allows dragging by header
///
/// Usage:
/// ```dart
/// return DraggableDialog(
///   header: _buildHeader(),
///   child: YourDialogContent(),
/// );
/// ```
class DraggableDialog extends StatefulWidget {
  final Widget header;
  final Widget child;
  final double? width;
  final double? height;

  const DraggableDialog({
    super.key,
    required this.header,
    required this.child,
    this.width,
    this.height,
  });

  @override
  State<DraggableDialog> createState() => DraggableDialogState();
}

class DraggableDialogState extends State<DraggableDialog> {
  Offset _offset = Offset.zero;
  Offset? _dragStartOffset;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = widget.width ?? 500;

    // Calculate initial center position
    final centerX = (screenSize.width - dialogWidth) / 2;
    final centerY = widget.height != null
        ? (screenSize.height - widget.height!) / 2
        : screenSize.height * 0.1;
    final basePosition = Offset(centerX, centerY);
    final currentPosition = basePosition + _offset;

    return Stack(
      children: [
        Positioned(
          left: currentPosition.dx,
          top: currentPosition.dy,
          child: _DialogContent(
            width: dialogWidth,
            height: widget.height,
            screenSize: screenSize,
            onDragStart: (globalPosition) {
              _dragStartOffset = globalPosition - currentPosition;
            },
            onDragUpdate: (globalPosition) {
              if (_dragStartOffset != null) {
                setState(() {
                  final newPosition = globalPosition - _dragStartOffset!;
                  _offset = newPosition - basePosition;
                });
              }
            },
            onDragEnd: () {
              _dragStartOffset = null;
            },
            header: widget.header,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _DialogContent extends StatelessWidget {
  final double width;
  final double? height;
  final Size screenSize;
  final ValueChanged<Offset> onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final Widget header;
  final Widget child;

  const _DialogContent({
    required this.width,
    this.height,
    required this.screenSize,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.header,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: width,
            constraints: height != null
                ? BoxConstraints.tightFor(height: height)
                : BoxConstraints(maxHeight: screenSize.height * 0.85),
            decoration: BoxDecoration(
              color: EditorColors.surface,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (draggable area)
                GestureDetector(
                  onPanStart: (details) => onDragStart(details.globalPosition),
                  onPanUpdate: (details) => onDragUpdate(details.globalPosition),
                  onPanEnd: (_) => onDragEnd(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.move,
                    child: header,
                  ),
                ),

                // Content
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show draggable dialog
Future<T?> showDraggableDialog<T>({
  required BuildContext context,
  required Widget header,
  required Widget child,
  double? width,
  double? height,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return DraggableDialog(
        header: header,
        child: child,
        width: width,
        height: height,
      );
    },
  );
}
