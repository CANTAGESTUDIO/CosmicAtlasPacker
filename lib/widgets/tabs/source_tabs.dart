import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/image_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Tab bar for managing multiple source images
class SourceTabs extends ConsumerWidget {
  const SourceTabs({super.key});

  /// Sync active source to sourceImageProvider for backward compatibility
  /// Also clears sprites when switching to a different source
  void _syncActiveSource(WidgetRef ref, {bool clearSprites = false}) {
    final activeSource = ref.read(activeSourceProvider);
    if (activeSource != null) {
      ref.read(sourceImageProvider.notifier).setFromSource(
        uiImage: activeSource.uiImage,
        rawImage: activeSource.rawImage,
        filePath: activeSource.filePath,
        fileName: activeSource.fileName,
      );
    } else {
      ref.read(sourceImageProvider.notifier).clear();
    }

    // Clear sprites when switching sources
    if (clearSprites) {
      ref.read(spriteProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiImageState = ref.watch(multiImageProvider);
    final sources = multiImageState.sources;
    final activeId = multiImageState.activeSourceId;

    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          bottom: BorderSide(color: EditorColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Scrollable tab list
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sources.map((source) {
                  final isActive = source.id == activeId;
                  return _SourceTab(
                    fileName: source.fileName,
                    isActive: isActive,
                    onTap: () {
                      // Only switch if not already active
                      if (!isActive) {
                        ref.read(multiImageProvider.notifier).setActiveSource(source.id);
                        // Sync to sourceImageProvider and clear sprites when switching sources
                        Future.microtask(() => _syncActiveSource(ref, clearSprites: true));
                      }
                    },
                    onClose: () {
                      ref.read(multiImageProvider.notifier).removeSource(source.id);
                      // Sync to sourceImageProvider and clear sprites after removing source
                      Future.microtask(() => _syncActiveSource(ref, clearSprites: true));
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          // Add button
          _AddButton(
            onTap: () async {
              // Prevent duplicate calls while loading
              if (ref.read(multiImageProvider).isLoading) return;

              await ref.read(multiImageProvider.notifier).pickAndLoadImages();
              // Sync to sourceImageProvider after adding images
              _syncActiveSource(ref);
            },
          ),
        ],
      ),
    );
  }
}

/// Individual source tab
class _SourceTab extends StatefulWidget {
  final String fileName;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SourceTab({
    required this.fileName,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_SourceTab> createState() => _SourceTabState();
}

class _SourceTabState extends State<_SourceTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? EditorColors.panelBackground
                : (_isHovered ? EditorColors.surface.withValues(alpha: 0.8) : Colors.transparent),
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? EditorColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File icon
              Icon(
                Icons.image_outlined,
                size: 14,
                color: widget.isActive
                    ? EditorColors.iconDefault
                    : EditorColors.iconDisabled,
              ),
              const SizedBox(width: 4),

              // File name (truncated)
              Flexible(
                child: Text(
                  widget.fileName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                    color: widget.isActive
                        ? EditorColors.iconDefault
                        : EditorColors.iconDisabled,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // Close button (visible on hover or when active)
              if (_isHovered || widget.isActive) ...[
                const SizedBox(width: 4),
                _CloseButton(onTap: widget.onClose),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Close button for tab
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _isHovered
                ? EditorColors.error.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(
            Icons.close,
            size: 12,
            color: _isHovered ? EditorColors.error : EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }
}

/// Add button for adding new source images
class _AddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _isHovered
                ? EditorColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.add,
            size: 18,
            color: _isHovered ? EditorColors.primary : EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }
}
