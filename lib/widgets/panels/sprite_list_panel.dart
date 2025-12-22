import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../providers/multi_image_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';
import '../common/sprite_thumbnail.dart';

/// Panel displaying a horizontal scrollable list of sprite thumbnails
class SpriteListPanel extends ConsumerStatefulWidget {
  const SpriteListPanel({super.key});

  @override
  ConsumerState<SpriteListPanel> createState() => _SpriteListPanelState();
}

class _SpriteListPanelState extends ConsumerState<SpriteListPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spriteState = ref.watch(spriteProvider);
    final activeSource = ref.watch(activeSourceProvider);
    final duplicateIds = ref.watch(duplicateIdsProvider);
    final hasDuplicates = ref.watch(hasDuplicateIdsProvider);

    // No source image loaded
    if (activeSource == null) {
      return _buildEmptyState('Load an image to see sprites');
    }

    // No sprites created
    if (spriteState.sprites.isEmpty) {
      return _buildEmptyState('No sprites created yet');
    }

    return Container(
      color: EditorColors.panelBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with sprite count
          _buildHeader(spriteState, hasDuplicates, duplicateIds.length),
          // Sprite list
          Expanded(
            child: _buildSpriteList(spriteState, activeSource, duplicateIds),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SpriteState spriteState, bool hasDuplicates, int duplicateCount) {
    final selectedCount = spriteState.selectedIds.length;
    final totalCount = spriteState.count;

    return Container(
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
            'Sprites ($totalCount)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: EditorColors.iconDefault,
            ),
          ),
          if (selectedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: EditorColors.selection.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(
                  fontSize: 10,
                  color: EditorColors.selection,
                ),
              ),
            ),
          ],
          // Duplicate ID warning
          if (hasDuplicates) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: '$duplicateCount duplicate ID(s) found - fix before export',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: EditorColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      size: 10,
                      color: EditorColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$duplicateCount duplicates',
                      style: const TextStyle(
                        fontSize: 10,
                        color: EditorColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          // Actions
          _buildActionButton(
            icon: Icons.select_all,
            tooltip: 'Select All (⌘A)',
            onPressed: spriteState.sprites.isNotEmpty
                ? () => ref.read(spriteProvider.notifier).selectAll()
                : null,
          ),
          _buildActionButton(
            icon: Icons.deselect,
            tooltip: 'Clear Selection',
            onPressed: selectedCount > 0
                ? () => ref.read(spriteProvider.notifier).clearSelection()
                : null,
          ),
          _buildActionButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete Selected (⌫)',
            onPressed: selectedCount > 0
                ? () => ref.read(spriteProvider.notifier).removeSelected()
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 14,
            color: onPressed != null
                ? EditorColors.iconDefault
                : EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }

  Widget _buildSpriteList(
    SpriteState spriteState,
    LoadedSourceImage activeSource,
    Map<String, List<int>> duplicateIds,
  ) {
    const itemSize = 72.0;
    const spacing = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate columns based on available width
        final availableWidth = constraints.maxWidth - 16; // padding
        final crossAxisCount = (availableWidth / (itemSize + spacing)).floor().clamp(1, 10);

        return ReorderableGridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.0,
          ),
          itemCount: spriteState.sprites.length,
          onReorder: (oldIndex, newIndex) {
            ref.read(spriteProvider.notifier).reorderSprites(oldIndex, newIndex);
          },
          dragWidgetBuilder: (index, child) {
            // Show a semi-transparent version while dragging
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Opacity(
                opacity: 0.8,
                child: child,
              ),
            );
          },
          placeholderBuilder: (dropIndex, dropInddex, dragWidget) {
            // Show placeholder where item will be dropped
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: EditorColors.selection,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(4),
                color: EditorColors.selection.withValues(alpha: 0.1),
              ),
            );
          },
          itemBuilder: (context, index) {
            final sprite = spriteState.sprites[index];
            final isSelected = spriteState.selectedIds.contains(sprite.id);
            final hasDuplicateId = duplicateIds.containsKey(sprite.id);

            return SpriteThumbnail(
              key: ValueKey(sprite.id),
              sprite: sprite,
              sourceImage: activeSource.uiImage,
              isSelected: isSelected,
              hasDuplicateId: hasDuplicateId,
              onTap: () => _handleSpriteTap(sprite.id, isSelected),
              onDoubleTap: () => _handleSpriteDoubleTap(sprite.id),
            );
          },
        );
      },
    );
  }

  void _handleSpriteTap(String spriteId, bool isCurrentlySelected) {
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isMetaPressed || isControlPressed) {
      // Toggle selection with Cmd/Ctrl (add/remove from selection)
      ref.read(spriteProvider.notifier).selectSprite(spriteId, toggle: true);
    } else if (isShiftPressed) {
      // Range selection with Shift
      _handleRangeSelection(spriteId);
    } else {
      // Normal click: clear others and select this one only
      // If already selected and it's the only selection, deselect it
      final selectedIds = ref.read(spriteProvider).selectedIds;
      if (isCurrentlySelected && selectedIds.length == 1) {
        ref.read(spriteProvider.notifier).clearSelection();
      } else {
        // Clear all and select only this sprite
        ref.read(spriteProvider.notifier).clearSelection();
        ref.read(spriteProvider.notifier).selectSprite(spriteId);
      }
    }
  }

  void _handleRangeSelection(String targetId) {
    final spriteState = ref.read(spriteProvider);
    final sprites = spriteState.sprites;
    final selectedIds = spriteState.selectedIds;

    if (selectedIds.isEmpty) {
      // No previous selection, just select the target
      ref.read(spriteProvider.notifier).selectSprite(targetId);
      return;
    }

    // Find the last selected sprite index
    int lastSelectedIndex = -1;
    for (int i = sprites.length - 1; i >= 0; i--) {
      if (selectedIds.contains(sprites[i].id)) {
        lastSelectedIndex = i;
        break;
      }
    }

    if (lastSelectedIndex == -1) {
      ref.read(spriteProvider.notifier).selectSprite(targetId);
      return;
    }

    // Find target index
    final targetIndex = sprites.indexWhere((s) => s.id == targetId);
    if (targetIndex == -1) return;

    // Select range
    final startIndex = lastSelectedIndex < targetIndex ? lastSelectedIndex : targetIndex;
    final endIndex = lastSelectedIndex < targetIndex ? targetIndex : lastSelectedIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      ref.read(spriteProvider.notifier).selectSprite(
        sprites[i].id,
        addToSelection: true,
      );
    }
  }

  void _handleSpriteDoubleTap(String spriteId) {
    // Double-tap to enter rename mode (will be handled by Properties panel)
    ref.read(spriteProvider.notifier).selectSprite(spriteId);
    // TODO: Focus on ID field in Properties panel
  }

  Widget _buildEmptyState(String message) {
    return Container(
      color: EditorColors.panelBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 32,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
