import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../theme/editor_colors.dart';
import '../common/editor_text_field.dart';

/// Animation list sidebar
/// Displays list of animations with add/delete/select functionality
class AnimationListSidebar extends ConsumerWidget {
  const AnimationListSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animState = ref.watch(animationProvider);
    final selectedId = animState.selectedAnimationId;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          right: BorderSide(color: EditorColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context, ref),

          // Animation list
          Expanded(
            child: animState.sequences.isEmpty
                ? _buildEmptyState()
                : _buildAnimationList(context, ref, animState.sequences, selectedId),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final animState = ref.watch(animationProvider);
    final count = animState.sequences.length;

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
            count > 0 ? 'Animations ($count)' : 'Animations',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          // Add animation button
          _AddIconButton(
            onTap: () => _createAnimation(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              size: 48,
              color: EditorColors.iconDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              '애니메이션이 없습니다',
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러\n새 애니메이션을 만드세요',
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationList(
    BuildContext context,
    WidgetRef ref,
    List<AnimationSequence> animations,
    String? selectedId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: animations.length,
      itemBuilder: (context, index) {
        final animation = animations[index];
        final isSelected = animation.id == selectedId;

        return _AnimationListItem(
          animation: animation,
          isSelected: isSelected,
          onTap: () {
            ref.read(animationProvider.notifier).selectAnimation(animation.id);
          },
          onRename: (newName) {
            ref.read(animationProvider.notifier).renameAnimation(
              animation.id,
              newName,
            );
          },
          onDelete: () => _deleteAnimation(context, ref, animation),
        );
      },
    );
  }

  void _createAnimation(BuildContext context, WidgetRef ref) {
    final animation = ref.read(animationProvider.notifier).createAnimation();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'${animation.name}' 애니메이션이 생성되었습니다"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteAnimation(BuildContext context, WidgetRef ref, AnimationSequence animation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('애니메이션 삭제'),
        content: Text("'${animation.name}'을(를) 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(animationProvider.notifier).deleteAnimation(animation.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("'${animation.name}'이(가) 삭제되었습니다"),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: EditorColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

}

class _AnimationListItem extends StatefulWidget {
  final AnimationSequence animation;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;

  const _AnimationListItem({
    required this.animation,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_AnimationListItem> createState() => _AnimationListItemState();
}

class _AnimationListItemState extends State<_AnimationListItem> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.animation.name);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _submitRename();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation.name != widget.animation.name && !_isEditing) {
      _controller.text = widget.animation.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.animation.name;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _submitRename() {
    final name = _controller.text.trim();
    if (name.isNotEmpty && name != widget.animation.name) {
      widget.onRename(name);
    } else {
      _controller.text = widget.animation.name;
    }
    setState(() => _isEditing = false);
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.animation.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: widget.isSelected
            ? EditorColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: _startEditing,
          onSecondaryTap: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Animation icon
                Icon(
                  Icons.movie_outlined,
                  size: 14,
                  color: widget.isSelected
                      ? EditorColors.primary
                      : EditorColors.iconDefault,
                ),
                const SizedBox(width: 8),

                // Animation name (editable)
                Expanded(
                  child: _isEditing
                      ? ShortcutBlockingTextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: EditorColors.primary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(3),
                              borderSide: BorderSide(color: EditorColors.primary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(3),
                              borderSide: BorderSide(color: EditorColors.primary),
                            ),
                          ),
                          onSubmitted: (_) => _submitRename(),
                          onEscape: _cancelEditing,
                        )
                      : Text(
                          widget.animation.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: widget.isSelected
                                ? EditorColors.primary
                                : EditorColors.iconDefault,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),

                // Frame count badge
                if (!_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: EditorColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.animation.frameCount}',
                      style: TextStyle(
                        fontSize: 10,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + button.size.width,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          onTap: _startEditing,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('이름 변경'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: widget.onDelete,
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: EditorColors.error),
              const SizedBox(width: 8),
              Text('삭제', style: TextStyle(color: EditorColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Add icon button with hover effect (matches source_sidebar.dart)
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
