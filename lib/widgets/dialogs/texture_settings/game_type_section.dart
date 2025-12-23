import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/texture_compression_settings.dart';
import '../../../providers/texture_packing_settings_provider.dart';
import '../../../theme/editor_colors.dart';

/// 게임 타입 섹션 위젯
/// 게임 타입별 프리셋 선택 및 적용 기능 제공
class GameTypeSection extends ConsumerWidget {
  final ValueChanged<GameType>? onChanged;

  const GameTypeSection({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(texturePackingSettingsProvider);
    final currentGameType = settings.gameType;
    final isCustomPreset = settings.customPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              '게임 타입',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EditorColors.primary,
              ),
            ),
            const Spacer(),
            if (isCustomPreset)
              TextButton.icon(
                onPressed: () {
                  ref.read(texturePackingSettingsProvider.notifier).applyGameTypePreset();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('프리셋 복원'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Custom preset warning
        if (isCustomPreset)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EditorColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: EditorColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: EditorColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '커스텀 설정 적용됨 - 프리셋과 다른 설정이 있습니다',
                    style: TextStyle(
                      fontSize: 11,
                      color: EditorColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Game type dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: DropdownButton<GameType>(
            value: currentGameType,
            items: GameType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getGameTypeIcon(type),
                      size: 16,
                      color: EditorColors.iconDefault,
                    ),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(texturePackingSettingsProvider.notifier).updateGameType(value);
                onChanged?.call(value);
              }
            },
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: EditorColors.surface,
            style: TextStyle(
              fontSize: 13,
              color: EditorColors.iconDefault,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Game type description
        Text(
          currentGameType.description,
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 16),

        // Preset details card
        _PresetDetailsCard(gameType: currentGameType),
      ],
    );
  }

  IconData _getGameTypeIcon(GameType type) {
    switch (type) {
      case GameType.casual2D:
        return Icons.games;
      case GameType.action2D:
        return Icons.sports_esports;
      case GameType.rpg3D:
        return Icons.explore;
      case GameType.highEnd3D:
        return Icons.auto_awesome;
    }
  }
}

class _PresetDetailsCard extends StatelessWidget {
  final GameType gameType;

  const _PresetDetailsCard({required this.gameType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 14, color: EditorColors.primary),
              const SizedBox(width: 8),
              Text(
                '프리셋 설정',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EditorColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPresetRow('Android 포맷', gameType.defaultAndroidFormat.displayName),
          _buildPresetRow('iOS 포맷', gameType.defaultIOSFormat.displayName),
          _buildPresetRow('ASTC 블록', gameType.defaultASTCBlockSize.displayName),
          _buildPresetRow('메모리 예산', '${gameType.recommendedMemoryBudgetMB}MB'),
        ],
      ),
    );
  }

  Widget _buildPresetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트한 버전의 GameTypeSection
class GameTypeSectionCompact extends ConsumerWidget {
  final ValueChanged<GameType>? onChanged;

  const GameTypeSectionCompact({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(texturePackingSettingsProvider);
    final currentGameType = settings.gameType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '게임 타입',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: DropdownButton<GameType>(
            value: currentGameType,
            items: GameType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(texturePackingSettingsProvider.notifier).updateGameType(value);
                onChanged?.call(value);
              }
            },
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: EditorColors.surface,
            isDense: true,
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDefault,
            ),
          ),
        ),
      ],
    );
  }
}
