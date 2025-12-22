import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/image_group.dart';
import '../../models/sprite_region.dart';
import '../../providers/image_provider.dart';
import '../../providers/multi_image_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';

/// Vertical sidebar for managing multiple source images (like reference images in design tools)
/// Supports group hierarchy with Photoshop-style collapse/expand
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
    final groups = multiImageState.groups;

    // Build list items: groups first, then ungrouped sources
    final groupedSourceIds = groups.values.expand((g) => g.sourceIds).toSet();

    return Container(
      width: 238,
      color: EditorColors.surface,
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

          // Source image list (vertical) with groups
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 빈 공간 클릭 시 다중 선택 해제 (활성 소스만 남김)
                ref.read(multiImageProvider.notifier).clearSelection();
              },
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                // Groups first
                for (final group in groups.values)
                  _GroupItem(
                    group: group,
                    sources: sources.where((s) => group.sourceIds.contains(s.id)).toList(),
                    activeId: activeId,
                    selectedIds: selectedIds,
                    multiSpriteState: multiSpriteState,
                    onSourceTap: (sourceId, isActive) => _handleSourceTap(ref, sourceId, isActive),
                    onSourceClose: (sourceId) {
                      ref.read(multiImageProvider.notifier).removeSource(sourceId);
                      Future.microtask(() => _syncActiveSource(ref, clearSprites: true));
                    },
                    onSourceRename: (sourceId, newName) {
                      ref.read(multiImageProvider.notifier).renameSource(sourceId, newName);
                    },
                    onSpriteTap: (spriteId) {
                      ref.read(multiSpriteProvider.notifier).selectSprite(spriteId);
                    },
                    onToggleExpand: () {
                      ref.read(multiImageProvider.notifier).toggleGroupExpansion(group.id);
                    },
                    onUngroup: () {
                      ref.read(multiImageProvider.notifier).ungroupSources(group.id);
                    },
                    onGroupRename: (newName) {
                      ref.read(multiImageProvider.notifier).renameGroup(group.id, newName);
                    },
                    onSelectMembers: () {
                      // Select all sources in this group
                      ref.read(multiImageProvider.notifier).selectGroupMembers(group.id);
                    },
                  ),

                // Ungrouped sources
                for (final source in sources.where((s) => !groupedSourceIds.contains(s.id)))
                  _SourceItem(
                    image: source.originalUiImage,
                    sourceId: source.id,
                    fileName: source.fileName,
                    isActive: source.id == activeId,
                    isSelected: selectedIds.contains(source.id),
                    spriteCount: multiSpriteState.countForSource(source.id),
                    hasProcessed: source.hasProcessedImage,
                    sprites: multiSpriteState.getSpritesForSource(source.id),
                    selectedSpriteIds: multiSpriteState.selectedIds,
                    onTap: () => _handleSourceTap(ref, source.id, source.id == activeId),
                    onClose: () {
                      ref.read(multiImageProvider.notifier).removeSource(source.id);
                      Future.microtask(() => _syncActiveSource(ref, clearSprites: true));
                    },
                    onRename: (newName) {
                      ref.read(multiImageProvider.notifier).renameSource(source.id, newName);
                    },
                    onSpriteTap: (spriteId) {
                      ref.read(multiSpriteProvider.notifier).selectSprite(spriteId);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Group item with collapsible header and child sources (Photoshop layer group style)
class _GroupItem extends StatelessWidget {
  final ImageGroup group;
  final List<LoadedSourceImage> sources;
  final String? activeId;
  final Set<String> selectedIds;
  final MultiSpriteState multiSpriteState;
  final void Function(String sourceId, bool isActive) onSourceTap;
  final void Function(String sourceId) onSourceClose;
  final void Function(String sourceId, String newName) onSourceRename;
  final void Function(String spriteId) onSpriteTap;
  final VoidCallback onToggleExpand;
  final VoidCallback onUngroup;
  final void Function(String newName)? onGroupRename;
  final VoidCallback? onSelectMembers;

  const _GroupItem({
    required this.group,
    required this.sources,
    required this.activeId,
    required this.selectedIds,
    required this.multiSpriteState,
    required this.onSourceTap,
    required this.onSourceClose,
    required this.onSourceRename,
    required this.onSpriteTap,
    required this.onToggleExpand,
    required this.onUngroup,
    this.onGroupRename,
    this.onSelectMembers,
  });

  int get _totalSpriteCount {
    int count = 0;
    for (final source in sources) {
      count += multiSpriteState.countForSource(source.id);
    }
    return count;
  }

  /// Check if any member of this group is selected
  bool get _hasSelectedMember {
    for (final source in sources) {
      if (selectedIds.contains(source.id)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Group header
        _GroupHeader(
          name: group.name,
          sourceCount: sources.length,
          spriteCount: _totalSpriteCount,
          isExpanded: group.isExpanded,
          isSelected: _hasSelectedMember,
          onToggle: onToggleExpand,
          onUngroup: onUngroup,
          onRename: onGroupRename,
          onSelectMembers: onSelectMembers,
        ),

        // Child sources (when expanded)
        if (group.isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                for (final source in sources)
                  _SourceItem(
                    image: source.originalUiImage,
                    sourceId: source.id,
                    fileName: source.fileName,
                    isActive: source.id == activeId,
                    isSelected: selectedIds.contains(source.id),
                    spriteCount: multiSpriteState.countForSource(source.id),
                    hasProcessed: source.hasProcessedImage,
                    isGroupChild: true,
                    sprites: multiSpriteState.getSpritesForSource(source.id),
                    selectedSpriteIds: multiSpriteState.selectedIds,
                    onTap: () => onSourceTap(source.id, source.id == activeId),
                    onClose: () => onSourceClose(source.id),
                    onRename: (newName) => onSourceRename(source.id, newName),
                    onSpriteTap: onSpriteTap,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Group header with expand/collapse toggle (Photoshop-style)
/// Supports double-click to rename
class _GroupHeader extends StatefulWidget {
  final String name;
  final int sourceCount;
  final int spriteCount;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onUngroup;
  final void Function(String newName)? onRename;
  final VoidCallback? onSelectMembers;

  const _GroupHeader({
    required this.name,
    required this.sourceCount,
    required this.spriteCount,
    required this.isExpanded,
    this.isSelected = false,
    required this.onToggle,
    required this.onUngroup,
    this.onRename,
    this.onSelectMembers,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _isHovered = false;
  bool _isEditing = false;
  TextEditingController? _editController;
  FocusNode? _editFocusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.name);
    _editFocusNode = FocusNode();
    _editFocusNode!.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _editController?.dispose();
    _editFocusNode?.removeListener(_onFocusChange);
    _editFocusNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_GroupHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && !_isEditing) {
      _editController?.text = widget.name;
    }
  }

  void _onFocusChange() {
    if (_editFocusNode != null && !_editFocusNode!.hasFocus && _isEditing) {
      _finishEditing();
    }
  }

  void _startEditing() {
    if (widget.onRename == null || _editController == null) return;
    setState(() {
      _isEditing = true;
      _editController!.text = widget.name;
      _editController!.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.name.length,
      );
    });
    Future.microtask(() => _editFocusNode?.requestFocus());
  }

  void _finishEditing() {
    if (!_isEditing || _editController == null) return;
    final newName = _editController!.text.trim();
    setState(() => _isEditing = false);
    if (newName.isNotEmpty && newName != widget.name) {
      widget.onRename?.call(newName);
    }
  }

  Widget _buildEditField() {
    // Wrap with Focus to prevent keyboard shortcuts from intercepting keys
    return Focus(
      onKeyEvent: (node, event) {
        // Consume all key events to prevent shortcuts from intercepting
        return KeyEventResult.skipRemainingHandlers;
      },
      child: SizedBox(
        height: 16,
        child: TextField(
          controller: _editController,
          focusNode: _editFocusNode,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: EditorColors.iconDefault,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: BorderSide(color: EditorColors.warning),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: BorderSide(color: EditorColors.warning, width: 1.5),
            ),
            filled: true,
            fillColor: EditorColors.surface,
          ),
          onSubmitted: (_) => _finishEditing(),
          onEditingComplete: _finishEditing,
          textInputAction: TextInputAction.done,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        // Click on main area = select group members (disabled when editing)
        onTap: _isEditing ? null : widget.onSelectMembers,
        onDoubleTap: _isEditing ? null : _startEditing,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? EditorColors.warning.withValues(alpha: 0.2)
                : _isHovered
                    ? EditorColors.warning.withValues(alpha: 0.1)
                    : EditorColors.surface.withValues(alpha: 0.5),
            border: Border(
              left: BorderSide(
                color: EditorColors.warning,
                width: 3,
              ),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Expand/Collapse icon - only this icon toggles expand/collapse
              if (!_isEditing)
                GestureDetector(
                  onTap: widget.onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Icon(
                      widget.isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                      color: EditorColors.iconDefault,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Icon(
                    widget.isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: EditorColors.iconDefault,
                  ),
                ),
              // Folder icon
              Icon(
                widget.isExpanded ? Icons.folder_open : Icons.folder,
                size: 14,
                color: EditorColors.warning,
              ),
              const SizedBox(width: 6),
              // Group name (editable on double-click)
              Expanded(
                child: _isEditing
                    ? _buildEditField()
                    : Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: EditorColors.iconDefault,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              // Source count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: EditorColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${widget.sourceCount}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: EditorColors.warning,
                  ),
                ),
              ),
              // Sprite count (if any) - green color like sprite outline
              if (widget.spriteCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: EditorColors.spriteOutline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${widget.spriteCount}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: EditorColors.spriteOutline,
                    ),
                  ),
                ),
              ],
              // Ungroup button (on hover)
              if (_isHovered) ...[
                const SizedBox(width: 4),
                _UngroupButton(onTap: widget.onUngroup),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ungroup button
class _UngroupButton extends StatefulWidget {
  final VoidCallback onTap;

  const _UngroupButton({required this.onTap});

  @override
  State<_UngroupButton> createState() => _UngroupButtonState();
}

class _UngroupButtonState extends State<_UngroupButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: 'Ungroup',
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _isHovered
                  ? EditorColors.error.withValues(alpha: 0.8)
                  : EditorColors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              Icons.link_off,
              size: 10,
              color: _isHovered ? Colors.white : EditorColors.iconDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual source item with thumbnail, filename, sprite count, and close button
/// Supports double-click to rename and sprite list expansion
class _SourceItem extends StatefulWidget {
  final dynamic image; // ui.Image
  final String sourceId;
  final String fileName;
  final bool isActive;
  final bool isSelected;
  final int spriteCount;
  final bool hasProcessed;
  final bool isGroupChild;
  final List<SpriteRegion> sprites;
  final Set<String> selectedSpriteIds;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(String newName)? onRename;
  final void Function(String spriteId)? onSpriteTap;

  const _SourceItem({
    required this.image,
    required this.sourceId,
    required this.fileName,
    required this.isActive,
    required this.isSelected,
    required this.spriteCount,
    this.hasProcessed = false,
    this.isGroupChild = false,
    this.sprites = const [],
    this.selectedSpriteIds = const {},
    required this.onTap,
    required this.onClose,
    this.onRename,
    this.onSpriteTap,
  });

  @override
  State<_SourceItem> createState() => _SourceItemState();
}

class _SourceItemState extends State<_SourceItem> {
  bool _isHovered = false;
  bool _isEditing = false;
  bool _isSpritesExpanded = false;
  late TextEditingController _editController;
  late FocusNode _editFocusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.fileName);
    _editFocusNode = FocusNode();
    _editFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.removeListener(_onFocusChange);
    _editFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SourceItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName && !_isEditing) {
      _editController.text = widget.fileName;
    }
  }

  void _onFocusChange() {
    if (!_editFocusNode.hasFocus && _isEditing) {
      _finishEditing();
    }
  }

  void _startEditing() {
    if (widget.onRename == null) return;
    setState(() {
      _isEditing = true;
      _editController.text = widget.fileName;
      _editController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.fileName.length,
      );
    });
    Future.microtask(() => _editFocusNode.requestFocus());
  }

  void _finishEditing() {
    if (!_isEditing) return;
    final newName = _editController.text.trim();
    setState(() => _isEditing = false);
    if (newName.isNotEmpty && newName != widget.fileName) {
      widget.onRename?.call(newName);
    }
  }

  Color _getBackgroundColor() {
    // isSelected takes priority when multi-selecting (includes active item)
    if (widget.isSelected) {
      return EditorColors.primary.withValues(alpha: 0.15);
    } else if (widget.isActive) {
      return EditorColors.panelBackground;
    } else if (_isHovered) {
      return EditorColors.surface.withValues(alpha: 0.8);
    }
    return Colors.transparent;
  }

  Color _getBorderColor() {
    // isSelected takes priority when multi-selecting (includes active item)
    if (widget.isSelected) {
      return EditorColors.primary;
    } else if (widget.isActive) {
      return EditorColors.primary;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main source item row
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: _startEditing,
            child: Container(
              height: widget.isGroupChild ? 38 : 44,
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
                    width: widget.isGroupChild ? 26 : 32,
                    height: widget.isGroupChild ? 26 : 32,
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
                        // File name (editable on double-click)
                        Row(
                          children: [
                            Expanded(
                              child: _isEditing
                                  ? _buildEditField()
                                  : Text(
                                      widget.fileName,
                                      style: TextStyle(
                                        fontSize: widget.isGroupChild ? 10 : 11,
                                        fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                                        color: widget.isActive
                                            ? EditorColors.iconDefault
                                            : EditorColors.iconDisabled,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                            ),
                            // Processed indicator
                            if (widget.hasProcessed && !_isEditing)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.auto_fix_high,
                                  size: 10,
                                  color: EditorColors.secondary,
                                ),
                              ),
                          ],
                        ),
                        if (!widget.isGroupChild) ...[
                          const SizedBox(height: 2),
                          // Sprite count row with expand button
                          Row(
                            children: [
                              // Sprite count (green color like sprite outline)
                              Text(
                                widget.spriteCount > 0
                                    ? '${widget.spriteCount} sprites'
                                    : '0',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.spriteCount > 0
                                      ? EditorColors.spriteOutline
                                      : EditorColors.iconDisabled,
                                ),
                              ),
                              // Expand button (only if has sprites)
                              if (widget.spriteCount > 0 && !widget.isGroupChild) ...[
                                const SizedBox(width: 4),
                                _SpriteExpandButton(
                                  isExpanded: _isSpritesExpanded,
                                  onTap: () => setState(() => _isSpritesExpanded = !_isSpritesExpanded),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Close button (visible on hover or when active)
                  if ((_isHovered || widget.isActive) && !_isEditing) ...[
                    const SizedBox(width: 4),
                    _CloseButton(onTap: widget.onClose),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Expanded sprite list
        if (_isSpritesExpanded && widget.sprites.isNotEmpty)
          _buildSpriteList(),
      ],
    );
  }

  Widget _buildSpriteList() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 4, bottom: 4),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: EditorColors.spriteOutline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sprite items
          ...widget.sprites.map((sprite) => _SpriteListItem(
            sprite: sprite,
            sourceImage: widget.image as ui.Image,
            isSelected: widget.selectedSpriteIds.contains(sprite.id),
            onTap: () => widget.onSpriteTap?.call(sprite.id),
          )),
          // Collapse button at the bottom
          GestureDetector(
            onTap: () => setState(() => _isSpritesExpanded = false),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: EditorColors.surface.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 12,
                    color: EditorColors.iconDisabled,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '접기',
                    style: TextStyle(
                      fontSize: 9,
                      color: EditorColors.iconDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField() {
    return SizedBox(
      height: widget.isGroupChild ? 14 : 16,
      child: TextField(
        controller: _editController,
        focusNode: _editFocusNode,
        style: TextStyle(
          fontSize: widget.isGroupChild ? 10 : 11,
          fontWeight: FontWeight.w500,
          color: EditorColors.iconDefault,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(color: EditorColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(color: EditorColors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: EditorColors.surface,
        ),
        onSubmitted: (_) => _finishEditing(),
        onEditingComplete: _finishEditing,
        textInputAction: TextInputAction.done,
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

/// Sprite expand/collapse button
class _SpriteExpandButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _SpriteExpandButton({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_SpriteExpandButton> createState() => _SpriteExpandButtonState();
}

class _SpriteExpandButtonState extends State<_SpriteExpandButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 12,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _isHovered || widget.isExpanded
                ? EditorColors.spriteOutline.withValues(alpha: 0.3)
                : EditorColors.spriteOutline.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 10,
                color: EditorColors.spriteOutline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual sprite list item (75% height of source item)
class _SpriteListItem extends StatefulWidget {
  final SpriteRegion sprite;
  final ui.Image sourceImage;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SpriteListItem({
    required this.sprite,
    required this.sourceImage,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_SpriteListItem> createState() => _SpriteListItemState();
}

class _SpriteListItemState extends State<_SpriteListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 75% of source item height (44 * 0.75 = 33)
    const itemHeight = 33.0;
    const thumbnailSize = 24.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? EditorColors.spriteOutline.withValues(alpha: 0.2)
                : _isHovered
                    ? EditorColors.surface.withValues(alpha: 0.5)
                    : Colors.transparent,
            border: widget.isSelected
                ? Border(
                    left: BorderSide(
                      color: EditorColors.spriteOutline,
                      width: 2,
                    ),
                  )
                : null,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            children: [
              // Sprite thumbnail (cropped from source)
              Container(
                width: thumbnailSize,
                height: thumbnailSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: EditorColors.divider,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: CustomPaint(
                    size: Size(thumbnailSize, thumbnailSize),
                    painter: _SpriteThumbnailPainter(
                      sourceImage: widget.sourceImage,
                      sprite: widget.sprite,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Sprite ID
              Expanded(
                child: Text(
                  widget.sprite.id,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isSelected
                        ? EditorColors.iconDefault
                        : EditorColors.iconDisabled,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Size info
              Text(
                '${widget.sprite.width.toInt()}×${widget.sprite.height.toInt()}',
                style: TextStyle(
                  fontSize: 9,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for sprite thumbnail (crops sprite from source image)
class _SpriteThumbnailPainter extends CustomPainter {
  final ui.Image sourceImage;
  final SpriteRegion sprite;

  _SpriteThumbnailPainter({
    required this.sourceImage,
    required this.sprite,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = sprite.sourceRect;
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw checkerboard background for transparency
    _drawCheckerboard(canvas, dstRect);

    // Draw sprite portion of source image
    canvas.drawImageRect(
      sourceImage,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _drawCheckerboard(Canvas canvas, Rect rect) {
    const checkerSize = 4.0;
    final paint1 = Paint()..color = const Color(0xFF404040);
    final paint2 = Paint()..color = const Color(0xFF505050);

    for (double y = rect.top; y < rect.bottom; y += checkerSize) {
      for (double x = rect.left; x < rect.right; x += checkerSize) {
        final isEven = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpriteThumbnailPainter oldDelegate) {
    return oldDelegate.sourceImage != sourceImage ||
        oldDelegate.sprite != sprite;
  }
}
