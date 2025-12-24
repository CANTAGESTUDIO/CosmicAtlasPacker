import 'package:flutter/material.dart';

import '../../theme/editor_colors.dart';

/// 에디터 전용 드롭다운 - 항상 아래로 펼쳐짐
class EditorDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;
  final String? label;
  final String? helperText;
  final double height;

  const EditorDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.label,
    this.helperText,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: EditorColors.iconDisabled,
            ),
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Container(
                    height: height,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: EditorColors.inputBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: EditorColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemLabelBuilder(value),
                            style: const TextStyle(
                              fontSize: 14,
                              color: EditorColors.iconDefault,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: EditorColors.iconDefault,
                        ),
                      ],
                    ),
                  ),
                );
              },
              alignmentOffset: const Offset(0, 4),
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(EditorColors.surface),
                elevation: const WidgetStatePropertyAll(8),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: EditorColors.border),
                  ),
                ),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
              ),
              menuChildren: items.map((item) {
                final isSelected = item == value;
                return MenuItemButton(
                  onPressed: () => onChanged(item),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      isSelected
                          ? EditorColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth - 32,
                    child: Text(
                      itemLabelBuilder(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? EditorColors.primary
                            : EditorColors.iconDefault,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            helperText!,
            style: const TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ],
    );
  }
}
