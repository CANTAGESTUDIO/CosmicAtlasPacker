import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/image_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Vertical sidebar for managing multiple source images (like reference images in design tools)
class SourceSidebar extends ConsumerWidget {
  const SourceSidebar({super.key});

  /// Sync active source to sourceImageProvider for backward compatibility
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

    if (clearSprites) {
      ref.read(spriteProvider.notifier).clear();
    }
  }

  /// Handle source item tap with keyboard modifiers
  void _handleSourceTap(WidgetRef ref, String sourceId, bool isActive) {
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    if (isShiftPressed) {
      // Shift: 범위 선택
      final activeId = ref.read(multiImageProvider).activeSourceId;
      if (activeId != null) {
        ref.read(multiImageProvider.notifier).selectSourceRange(activeId, sourceId);
      }
    } else if (isMetaPressed || isControlPressed) {
      // Cmd/Ctrl: 토글 선택
      ref.read(multiImageProvider.notifier).toggleSourceSelection(sourceId);
    } else {
      // 일반 클릭: 단일 선택 + 활성화
      ref.read(multiImageProvider.notifier).selectSource(sourceId);
      Future.microtask(() => _syncActiveSource(ref, clearSprites: true));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiImageState = ref.watch(multiImageProvider);
    final multiSpriteState = ref.watch(multiSpriteProvider);
    final sources = multiImageState.sources;
    final activeId = multiImageState.activeSourceId;
    final selectedIds = multiImageState.selectedSourceIds;

    return Container(
      width: 238,
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          right: BorderSide(color: EditorColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: EditorColors.surface,
              border: Border(
                bottom: BorderSide(color: EditorColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  selectedIds.length > 1
                      ? 'Sources (${selectedIds.length})'
                      : 'Sources',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: EditorColors.iconDefault,
                  ),
                ),
                const Spacer(),
                // Add button in header
                _AddIconButton(
                  onTap: () async {
                    if (ref.read(multiImageProvider).isLoading) return;
                    await ref.read(multiImageProvider.notifier).pickAndLoadImages();
                    _syncActiveSource(ref);
                  },
                ),
              ],
            ),
          ),

          // Source image list (vertical)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                final isActive = source.id == activeId;
                final isSelected = selectedIds.contains(source.id);
                final spriteCount = multiSpriteState.countForSource(source.id);
                return _SourceItem(
                  image: source.uiImage,
                  fileName: source.fileName,
                  isActive: isActive,
                  isSelected: isSelected,
                  spriteCount: spriteCount,
                  onTap: () => _handleSourceTap(ref, source.id, isActive),
                  onClose: () {
                    ref.read(multiImageProvider.notifier).removeSource(source.id);
                    Future.microtask(() => _syncActiveSource(ref, clearSprites: true));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual source item with thumbnail, filename, sprite count, and close button
class _SourceItem extends StatefulWidget {
  final dynamic image; // ui.Image
  final String fileName;
  final bool isActive;
  final bool isSelected;
  final int spriteCount;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SourceItem({
    required this.image,
    required this.fileName,
    required this.isActive,
    required this.isSelected,
    required this.spriteCount,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_SourceItem> createState() => _SourceItemState();
}

class _SourceItemState extends State<_SourceItem> {
  bool _isHovered = false;

  Color _getBackgroundColor() {
    if (widget.isActive) {
      return EditorColors.panelBackground;
    } else if (widget.isSelected) {
      return EditorColors.primary.withValues(alpha: 0.15);
    } else if (_isHovered) {
      return EditorColors.surface.withValues(alpha: 0.8);
    }
    return Colors.transparent;
  }

  Color _getBorderColor() {
    if (widget.isActive) {
      return EditorColors.primary;
    } else if (widget.isSelected) {
      return EditorColors.primary.withValues(alpha: 0.5);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border(
              left: BorderSide(
                color: _getBorderColor(),
                width: 2,
              ),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Thumbnail image
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: EditorColors.divider,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: RawImage(
                    image: widget.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // File name and sprite count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // File name
                    Text(
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
                    const SizedBox(height: 2),
                    // Sprite count
                    Text(
                      widget.spriteCount > 0
                          ? '${widget.spriteCount} sprites'
                          : '0',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.spriteCount > 0
                            ? EditorColors.primary
                            : EditorColors.iconDisabled,
                      ),
                    ),
                  ],
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

/// Close button for thumbnail
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _isHovered
                ? EditorColors.error
                : EditorColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(
            Icons.close,
            size: 10,
            color: _isHovered ? Colors.white : EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }
}

/// Small add icon button for header
class _AddIconButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddIconButton({required this.onTap});

  @override
  State<_AddIconButton> createState() => _AddIconButtonState();
}

class _AddIconButtonState extends State<_AddIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _isHovered
                ? EditorColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.add,
            size: 14,
            color: _isHovered ? EditorColors.primary : EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }
}

/// Add button for adding new source images (unused, kept for reference)
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
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovered
                ? EditorColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: _isHovered ? EditorColors.primary : EditorColors.divider,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.add,
            size: 20,
            color: _isHovered ? EditorColors.primary : EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }
}
