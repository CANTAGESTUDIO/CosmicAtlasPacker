import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/texture_compression_settings.dart';
import '../../../providers/texture_packing_settings_provider.dart';
import '../../../theme/editor_colors.dart';

/// 내보내기 타입 토글 위젯 (스프라이트/폰트)
/// SegmentedButton 패턴을 사용하여 모드 전환 제공
class ExportTypeToggle extends ConsumerWidget {
  final ValueChanged<ExportType>? onChanged;

  const ExportTypeToggle({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(texturePackingSettingsProvider);
    final currentType = settings.exportType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내보내기 타입',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: EditorColors.iconDefault,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ExportType>(
          segments: [
            ButtonSegment<ExportType>(
              value: ExportType.sprite,
              icon: const Icon(Icons.layers, size: 18),
              label: const Text('스프라이트'),
            ),
            ButtonSegment<ExportType>(
              value: ExportType.font,
              icon: const Icon(Icons.font_download, size: 18),
              label: const Text('스프라이트 폰트'),
            ),
          ],
          selected: {currentType},
          onSelectionChanged: (selection) {
            final newType = selection.first;
            ref.read(texturePackingSettingsProvider.notifier).updateExportType(newType);
            onChanged?.call(newType);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return EditorColors.primary.withValues(alpha: 0.15);
              }
              return EditorColors.inputBackground;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return EditorColors.primary;
              }
              return EditorColors.iconDefault;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(color: EditorColors.primary);
              }
              return BorderSide(color: EditorColors.border);
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Mode description
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _ExportTypeDescription(
            key: ValueKey(currentType),
            exportType: currentType,
          ),
        ),
      ],
    );
  }
}

class _ExportTypeDescription extends StatelessWidget {
  final ExportType exportType;

  const _ExportTypeDescription({
    super.key,
    required this.exportType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            exportType == ExportType.sprite ? Icons.info_outline : Icons.info_outline,
            size: 16,
            color: EditorColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exportType.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: EditorColors.iconDefault,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDetailDescription(exportType),
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDetailDescription(ExportType type) {
    switch (type) {
      case ExportType.sprite:
        return 'PNG 텍스처 아틀라스 + JSON 메타데이터\n9-Slice 보더 정보 포함';
      case ExportType.font:
        return 'PNG 텍스처 + FNT 파일 (BMFont 호환)\n글자 간격, 줄 간격 설정 가능';
    }
  }
}

/// 컴팩트한 버전의 ExportTypeToggle
class ExportTypeToggleCompact extends ConsumerWidget {
  final ValueChanged<ExportType>? onChanged;

  const ExportTypeToggleCompact({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(texturePackingSettingsProvider);
    final currentType = settings.exportType;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ExportType.values.map((type) {
        final isSelected = type == currentType;
        return Padding(
          padding: EdgeInsets.only(right: type != ExportType.values.last ? 8 : 0),
          child: InkWell(
            onTap: () {
              ref.read(texturePackingSettingsProvider.notifier).updateExportType(type);
              onChanged?.call(type);
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? EditorColors.primary.withValues(alpha: 0.15)
                    : EditorColors.inputBackground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? EditorColors.primary : EditorColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == ExportType.sprite ? Icons.layers : Icons.font_download,
                    size: 14,
                    color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
