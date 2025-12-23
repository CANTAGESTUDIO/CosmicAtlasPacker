import 'package:flutter/material.dart';

import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';

/// Dialog to confirm sprite separation from source image
///
/// Shown when user tries to drag a sprite in "region" state.
/// Warns that sprites will be extracted as independent images.
class SeparateConfirmDialog extends StatelessWidget {
  const SeparateConfirmDialog({super.key});

  /// Show separate confirm dialog and return true if user confirms
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => const SeparateConfirmDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableDialog(
      header: _buildHeader(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '스프라이트를 이동하면 이미지가 배경에서 분리됩니다.',
                    style: TextStyle(
                      color: EditorColors.iconDefault,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EditorColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: EditorColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          icon: Icons.content_cut,
                          text: '스프라이트가 독립적인 이미지로 추출됩니다',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.format_color_fill,
                          text: '원본 위치는 배경색으로 채워집니다',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.undo,
                          text: 'Cmd+Z로 되돌릴 수 있습니다',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    '취소',
                    style: TextStyle(color: EditorColors.iconDisabled),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EditorColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('분리'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: EditorColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '분리 확인',
            style: TextStyle(
              color: EditorColors.iconDefault,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: EditorColors.iconDefault,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: EditorColors.iconDisabled,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
