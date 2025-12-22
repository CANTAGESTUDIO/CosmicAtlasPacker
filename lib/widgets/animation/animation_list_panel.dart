import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation_sequence.dart';
import '../../providers/animation_provider.dart';
import '../../theme/editor_colors.dart';

/// Panel for managing animation sequences
class AnimationListPanel extends ConsumerStatefulWidget {
  const AnimationListPanel({super.key});

  @override
  ConsumerState<AnimationListPanel> createState() => _AnimationListPanelState();
}

class _AnimationListPanelState extends ConsumerState<AnimationListPanel> {
  String? _editingAnimationId;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationState = ref.watch(animationProvider);
    final sequences = animationState.sequences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(context),

        // Animation list
        Expanded(
          child: sequences.isEmpty
              ? _buildEmptyState()
              : _buildAnimationList(sequences, animationState),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: EditorColors.surface,
        border: Border(
          bottom: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.movie_outlined, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          const Text(
            'Animations',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Add animation button
          Tooltip(
            message: 'Create Animation',
            child: InkWell(
              onTap: () {
                ref.read(animationProvider.notifier).createAnimation();
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: EditorColors.iconDefault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 32,
            color: EditorColors.iconDisabled,
          ),
          const SizedBox(height: 8),
          Text(
            'No Animations',
            style: TextStyle(
              color: EditorColors.iconDisabled,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              ref.read(animationProvider.notifier).createAnimation();
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Create'),
            style: TextButton.styleFrom(
              foregroundColor: EditorColors.primary,
              textStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationList(
    List<AnimationSequence> sequences,
    AnimationState state,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: sequences.length,
      itemBuilder: (context, index) {
        final animation = sequences[index];
        final isSelected = state.selectedAnimationId == animation.id;
        final isEditing = _editingAnimationId == animation.id;

        return _AnimationListItem(
          animation: animation,
          isSelected: isSelected,
          isEditing: isEditing,
          nameController: _nameController,
          onTap: () {
            ref.read(animationProvider.notifier).selectAnimation(animation.id);
          },
          onDoubleTap: () {
            _startEditing(animation);
          },
          onDelete: () {
            _showDeleteConfirmation(context, animation);
          },
          onNameSubmitted: (name) {
            _finishEditing(animation.id, name);
          },
          onEditingCancelled: () {
            setState(() {
              _editingAnimationId = null;
            });
          },
        );
      },
    );
  }

  void _startEditing(AnimationSequence animation) {
    setState(() {
      _editingAnimationId = animation.id;
      _nameController.text = animation.name;
    });
  }

  void _finishEditing(String animationId, String name) {
    if (name.trim().isNotEmpty) {
      ref
          .read(animationProvider.notifier)
          .renameAnimation(animationId, name.trim());
    }
    setState(() {
      _editingAnimationId = null;
    });
  }

  void _showDeleteConfirmation(
      BuildContext context, AnimationSequence animation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EditorColors.surface,
        title: const Text(
          'Delete Animation',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        content: Text(
          'Are you sure you want to delete "${animation.name}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(animationProvider.notifier)
                  .deleteAnimation(animation.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: EditorColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Individual animation list item
class _AnimationListItem extends StatefulWidget {
  final AnimationSequence animation;
  final bool isSelected;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onNameSubmitted;
  final VoidCallback onEditingCancelled;

  const _AnimationListItem({
    required this.animation,
    required this.isSelected,
    required this.isEditing,
    required this.nameController,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDelete,
    required this.onNameSubmitted,
    required this.onEditingCancelled,
  });

  @override
  State<_AnimationListItem> createState() => _AnimationListItemState();
}

class _AnimationListItemState extends State<_AnimationListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? EditorColors.selection.withValues(alpha: 0.3)
                : (_isHovered ? EditorColors.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.isSelected
                  ? EditorColors.selection
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Animation icon
              Icon(
                Icons.movie_outlined,
                size: 14,
                color: widget.isSelected
                    ? EditorColors.selection
                    : EditorColors.iconDefault,
              ),
              const SizedBox(width: 8),

              // Name (editable or display)
              Expanded(
                child: widget.isEditing
                    ? _buildNameEditor()
                    : _buildNameDisplay(),
              ),

              // Frame count
              Text(
                '${widget.animation.frameCount}f',
                style: TextStyle(
                  fontSize: 9,
                  color: EditorColors.iconDisabled,
                ),
              ),

              // Delete button (visible on hover)
              if (_isHovered) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: EditorColors.error.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameEditor() {
    return TextField(
      controller: widget.nameController,
      autofocus: true,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
      onSubmitted: widget.onNameSubmitted,
      onTapOutside: (_) => widget.onEditingCancelled(),
    );
  }

  Widget _buildNameDisplay() {
    return Text(
      widget.animation.name,
      style: TextStyle(
        fontSize: 11,
        color: widget.isSelected ? Colors.white : Colors.white70,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
