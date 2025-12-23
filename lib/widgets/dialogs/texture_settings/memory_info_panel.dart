import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/texture_packing_settings_provider.dart';
import '../../../theme/editor_colors.dart';

/// 메모리 정보 패널 위젯
/// 메모리 예산, 빌드 크기 추정, 시각적 피드백 제공
class MemoryInfoPanel extends ConsumerWidget {
  final int? atlasWidth;
  final int? atlasHeight;

  const MemoryInfoPanel({
    super.key,
    this.atlasWidth,
    this.atlasHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(texturePackingSettingsProvider);
    final textureMemoryBudget = settings.textureMemoryBudgetMB;
    final totalBudget = settings.memoryBudgetMB;

    // Calculate estimated size if atlas dimensions provided
    final estimatedSizeKB = atlasWidth != null && atlasHeight != null
        ? settings.calculateEstimatedSize(atlasWidth!, atlasHeight!)
        : null;

    final estimatedSizeMB = estimatedSizeKB != null ? estimatedSizeKB / 1024 : null;
    final usagePercent = estimatedSizeMB != null && textureMemoryBudget > 0
        ? (estimatedSizeMB / textureMemoryBudget * 100).clamp(0, 100)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          '메모리 정보',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EditorColors.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Memory budget card
        _MemoryBudgetCard(
          totalBudget: totalBudget,
          textureBudget: textureMemoryBudget,
          allocationPercent: settings.textureAllocationPercent,
        ),
        const SizedBox(height: 16),

        // Build size estimation (if atlas dimensions available)
        if (estimatedSizeKB != null) ...[
          _BuildSizeCard(
            estimatedSizeKB: estimatedSizeKB,
            usagePercent: usagePercent!.toDouble(),
            textureBudgetMB: textureMemoryBudget,
          ),
          const SizedBox(height: 16),
        ],

        // Format comparison
        _FormatComparisonCard(
          androidFormat: settings.androidFormat.displayName,
          androidBpp: settings.androidFormat.bitsPerPixel,
          iosFormat: settings.iosFormat.displayName,
          iosBpp: settings.iosFormat.bitsPerPixel,
        ),

        // Validation warning
        if (settings.validate() != null) ...[
          const SizedBox(height: 16),
          _ValidationWarning(message: settings.validate()!),
        ],
      ],
    );
  }
}

class _MemoryBudgetCard extends StatelessWidget {
  final int totalBudget;
  final int textureBudget;
  final int allocationPercent;

  const _MemoryBudgetCard({
    required this.totalBudget,
    required this.textureBudget,
    required this.allocationPercent,
  });

  @override
  Widget build(BuildContext context) {
    final otherBudget = totalBudget - textureBudget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, size: 16, color: EditorColors.primary),
              const SizedBox(width: 8),
              Text(
                '메모리 예산',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EditorColors.iconDefault,
                ),
              ),
              const Spacer(),
              Text(
                '${totalBudget}MB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: EditorColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar visualization
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 20,
              child: Stack(
                children: [
                  // Background
                  Container(color: EditorColors.border),
                  // Texture allocation
                  FractionallySizedBox(
                    widthFactor: allocationPercent / 100,
                    child: Container(color: EditorColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(
                color: EditorColors.primary,
                label: '텍스처',
                value: '${textureBudget}MB ($allocationPercent%)',
              ),
              _LegendItem(
                color: EditorColors.border,
                label: '기타',
                value: '${otherBudget}MB (${100 - allocationPercent}%)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
      ],
    );
  }
}

class _BuildSizeCard extends StatelessWidget {
  final double estimatedSizeKB;
  final double usagePercent;
  final int textureBudgetMB;

  const _BuildSizeCard({
    required this.estimatedSizeKB,
    required this.usagePercent,
    required this.textureBudgetMB,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = usagePercent > 100;
    final isWarning = usagePercent > 80;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isOverBudget) {
      statusColor = EditorColors.error;
      statusIcon = Icons.error;
      statusText = '예산 초과!';
    } else if (isWarning) {
      statusColor = EditorColors.warning;
      statusIcon = Icons.warning;
      statusText = '주의';
    } else {
      statusColor = EditorColors.secondary;
      statusIcon = Icons.check_circle;
      statusText = '정상';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                '예상 빌드 크기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EditorColors.iconDefault,
                ),
              ),
              const Spacer(),
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Size display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatSize(estimatedSizeKB),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${textureBudgetMB}MB',
                style: TextStyle(
                  fontSize: 14,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Usage progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (usagePercent / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: EditorColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${usagePercent.toStringAsFixed(1)}% 사용',
            style: TextStyle(
              fontSize: 11,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(double sizeKB) {
    if (sizeKB >= 1024) {
      return '${(sizeKB / 1024).toStringAsFixed(2)}MB';
    }
    return '${sizeKB.toStringAsFixed(1)}KB';
  }
}

class _FormatComparisonCard extends StatelessWidget {
  final String androidFormat;
  final double androidBpp;
  final String iosFormat;
  final double iosBpp;

  const _FormatComparisonCard({
    required this.androidFormat,
    required this.androidBpp,
    required this.iosFormat,
    required this.iosBpp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, size: 16, color: EditorColors.iconDisabled),
              const SizedBox(width: 8),
              Text(
                '포맷 비교',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EditorColors.iconDefault,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Android
          _FormatComparisonRow(
            icon: Icons.android,
            platform: 'Android',
            format: androidFormat,
            bpp: androidBpp,
          ),
          const SizedBox(height: 8),

          // iOS
          _FormatComparisonRow(
            icon: Icons.apple,
            platform: 'iOS',
            format: iosFormat,
            bpp: iosBpp,
          ),
          const SizedBox(height: 12),

          // Average
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EditorColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  '평균 압축률:',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
                const Spacer(),
                Text(
                  '${((androidBpp + iosBpp) / 2).toStringAsFixed(2)} bpp',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatComparisonRow extends StatelessWidget {
  final IconData icon;
  final String platform;
  final String format;
  final double bpp;

  const _FormatComparisonRow({
    required this.icon,
    required this.platform,
    required this.format,
    required this.bpp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: EditorColors.iconDisabled),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            platform,
            style: TextStyle(
              fontSize: 11,
              color: EditorColors.iconDisabled,
            ),
          ),
        ),
        Expanded(
          child: Text(
            format,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getBppColor(bpp).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$bpp bpp',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _getBppColor(bpp),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBppColor(double bpp) {
    if (bpp <= 2) return EditorColors.secondary;
    if (bpp <= 4) return EditorColors.primary;
    return EditorColors.warning;
  }
}

class _ValidationWarning extends StatelessWidget {
  final String message;

  const _ValidationWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: EditorColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
