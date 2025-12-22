import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../commands/editor_command.dart';
import '../../models/sprite_data.dart';
import '../../models/sprite_region.dart';
import '../../providers/history_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../theme/editor_colors.dart';
import '../pivot/custom_pivot_input.dart';

/// Properties panel for editing selected sprite properties
class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spriteState = ref.watch(spriteProvider);
    final selectedSprites = spriteState.selectedSprites;

    if (selectedSprites.isEmpty) {
      return const _EmptyState();
    }

    if (selectedSprites.length == 1) {
      return _SingleSpriteProperties(sprite: selectedSprites.first);
    }

    return _MultiSpriteProperties(sprites: selectedSprites);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'No sprite selected',
          style: TextStyle(
            fontSize: 12,
            color: EditorColors.iconDisabled,
          ),
        ),
      ),
    );
  }
}

class _SingleSpriteProperties extends ConsumerStatefulWidget {
  final SpriteRegion sprite;

  const _SingleSpriteProperties({required this.sprite});

  @override
  ConsumerState<_SingleSpriteProperties> createState() =>
      _SingleSpritePropertiesState();
}

class _SingleSpritePropertiesState
    extends ConsumerState<_SingleSpriteProperties> {
  late TextEditingController _idController;
  late TextEditingController _xController;
  late TextEditingController _yController;
  late TextEditingController _wController;
  late TextEditingController _hController;
  bool _hasIdError = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.sprite.id);
    _xController = TextEditingController(text: widget.sprite.sourceRect.left.round().toString());
    _yController = TextEditingController(text: widget.sprite.sourceRect.top.round().toString());
    _wController = TextEditingController(text: widget.sprite.width.toString());
    _hController = TextEditingController(text: widget.sprite.height.toString());
  }

  @override
  void didUpdateWidget(_SingleSpriteProperties oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sprite.id != widget.sprite.id) {
      _idController.text = widget.sprite.id;
      _hasIdError = false;
    }
    if (oldWidget.sprite.sourceRect != widget.sprite.sourceRect) {
      _xController.text = widget.sprite.sourceRect.left.round().toString();
      _yController.text = widget.sprite.sourceRect.top.round().toString();
      _wController.text = widget.sprite.width.toString();
      _hController.text = widget.sprite.height.toString();
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _xController.dispose();
    _yController.dispose();
    _wController.dispose();
    _hController.dispose();
    super.dispose();
  }

  void _onIdChanged(String newId) {
    if (newId.isEmpty || newId == widget.sprite.id) {
      setState(() => _hasIdError = newId.isEmpty);
      return;
    }

    final sprites = ref.read(spriteProvider).sprites;
    final isDuplicate = sprites.any((s) => s.id == newId && s.id != widget.sprite.id);

    if (isDuplicate) {
      setState(() => _hasIdError = true);
      return;
    }

    setState(() => _hasIdError = false);

    // Create command for undo/redo
    final command = UpdateSpriteIdCommand(
      oldId: widget.sprite.id,
      newId: newId,
      onUpdate: (oldId, newId) {
        ref.read(spriteProvider.notifier).updateSpriteIdInternal(oldId, newId);
      },
    );

    ref.read(historyProvider.notifier).execute(command);
  }

  void _onPivotChanged(PivotPoint pivot) {
    // Create command for undo/redo
    final command = UpdateSpritePivotCommand(
      spriteId: widget.sprite.id,
      oldPivot: widget.sprite.pivot,
      newPivot: pivot,
      onUpdate: (id, pivot) {
        ref.read(spriteProvider.notifier).updateSpritePivotInternal(id, pivot);
      },
    );

    ref.read(historyProvider.notifier).execute(command);
  }

  void _onPositionChanged() {
    final x = double.tryParse(_xController.text);
    final y = double.tryParse(_yController.text);
    final w = int.tryParse(_wController.text);
    final h = int.tryParse(_hController.text);

    if (x != null && y != null && w != null && h != null && w > 0 && h > 0) {
      final newRect = Rect.fromLTWH(x, y, w.toDouble(), h.toDouble());

      // Create command for undo/redo
      final command = UpdateSpriteRectCommand(
        spriteId: widget.sprite.id,
        oldRect: widget.sprite.sourceRect,
        newRect: newRect,
        onUpdate: (id, rect) {
          ref.read(spriteProvider.notifier).updateSpriteRectInternal(id, rect);
        },
      );

      ref.read(historyProvider.notifier).execute(command);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sprite = widget.sprite;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID Section
          _SectionHeader(title: 'Sprite'),
          const SizedBox(height: 8),
          _PropertyRow(
            label: 'ID',
            child: TextField(
              controller: _idController,
              style: const TextStyle(
                fontSize: 11,
                color: EditorColors.iconDefault,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                filled: true,
                fillColor: EditorColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: _hasIdError ? EditorColors.error : EditorColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: _hasIdError ? EditorColors.error : EditorColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: _hasIdError ? EditorColors.error : EditorColors.primary,
                  ),
                ),
                errorText: _hasIdError ? 'ID must be unique' : null,
                errorStyle: const TextStyle(fontSize: 10),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              ],
              onSubmitted: _onIdChanged,
            ),
          ),
          const SizedBox(height: 16),

          // Position Section
          _SectionHeader(title: 'Source Position'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EditableNumberField(
                  label: 'X',
                  controller: _xController,
                  onChanged: _onPositionChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EditableNumberField(
                  label: 'Y',
                  controller: _yController,
                  onChanged: _onPositionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EditableNumberField(
                  label: 'W',
                  controller: _wController,
                  onChanged: _onPositionChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EditableNumberField(
                  label: 'H',
                  controller: _hController,
                  onChanged: _onPositionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pivot Section
          PivotEditor(
            pivot: sprite.pivot,
            onPivotChanged: _onPivotChanged,
          ),
        ],
      ),
    );
  }
}

class _MultiSpriteProperties extends ConsumerWidget {
  final List<SpriteRegion> sprites;

  const _MultiSpriteProperties({required this.sprites});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if all sprites have the same pivot
    final firstPivot = sprites.first.pivot;
    final allSamePivot = sprites.every((s) => s.pivot == firstPivot);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection Info
          _SectionHeader(title: 'Selection'),
          const SizedBox(height: 8),
          Text(
            '${sprites.length} sprites selected',
            style: const TextStyle(
              fontSize: 11,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(height: 16),

          // Batch Pivot Edit
          const _SectionHeader(title: 'Pivot (Batch Edit)'),
          const SizedBox(height: 8),
          PivotEditor(
            pivot: allSamePivot ? firstPivot : const PivotPoint(),
            onPivotChanged: (pivot) {
              // Store old pivots for undo
              final oldPivots = <String, PivotPoint>{};
              for (final sprite in sprites) {
                oldPivots[sprite.id] = sprite.pivot;
              }

              // Create command for undo/redo
              final command = UpdateSelectedPivotCommand(
                spriteIds: sprites.map((s) => s.id).toList(),
                oldPivots: oldPivots,
                newPivot: pivot,
                onUpdate: (id, pivot) {
                  ref.read(spriteProvider.notifier).updateSpritePivotInternal(id, pivot);
                },
              );

              ref.read(historyProvider.notifier).execute(command);
            },
          ),
          if (!allSamePivot) ...[
            const SizedBox(height: 4),
            const Text(
              'Mixed values - edit to apply to all',
              style: TextStyle(
                fontSize: 10,
                color: EditorColors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        color: EditorColors.iconDefault,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _PropertyRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _EditableNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _EditableNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SizedBox(
            height: 24,
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 11,
                color: EditorColors.iconDefault,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                filled: true,
                fillColor: EditorColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: EditorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: EditorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: EditorColors.primary),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              onSubmitted: (_) => onChanged(),
              onEditingComplete: () {
                onChanged();
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }
}
