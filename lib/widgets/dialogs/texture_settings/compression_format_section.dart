import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/texture_compression_settings.dart';
import '../../../providers/texture_packing_settings_provider.dart';
import '../../../theme/editor_colors.dart';

/// 압축 포맷 섹션 위젯
/// 플랫폼별 텍스처 압축 포맷 설정 UI 제공
class CompressionFormatSection extends ConsumerStatefulWidget {
  const CompressionFormatSection({super.key});

  @override
  ConsumerState<CompressionFormatSection> createState() => _CompressionFormatSectionState();
}

class _CompressionFormatSectionState extends ConsumerState<CompressionFormatSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(texturePackingSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          '압축 포맷',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EditorColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        // Platform tabs
        Container(
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: EditorColors.primary,
            unselectedLabelColor: EditorColors.iconDisabled,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: EditorColors.primary,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.android, size: 16),
                    SizedBox(width: 6),
                    Text('Android'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apple, size: 16),
                    SizedBox(width: 6),
                    Text('iOS'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab content
        SizedBox(
          height: 280,
          child: TabBarView(
            controller: _tabController,
            children: [
              _AndroidFormatTab(settings: settings),
              _IOSFormatTab(settings: settings),
            ],
          ),
        ),

        // ASTC Block Size (common)
        const Divider(height: 32),
        _ASTCBlockSizeSection(settings: settings),

        // Fallback format
        const SizedBox(height: 16),
        _FallbackFormatSection(settings: settings),
      ],
    );
  }
}

class _AndroidFormatTab extends ConsumerWidget {
  final TextureCompressionSettings settings;

  const _AndroidFormatTab({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Android 압축 포맷',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(height: 8),
          ...TextureCompressionFormat.androidFormats.map((format) {
            final isSelected = settings.androidFormat == format;
            return _FormatOptionTile(
              format: format,
              isSelected: isSelected,
              onTap: () {
                ref.read(texturePackingSettingsProvider.notifier).updateAndroidFormat(format);
              },
            );
          }),

          const SizedBox(height: 16),

          // Compatibility info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EditorColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: EditorColors.iconDisabled),
                    const SizedBox(width: 8),
                    Text(
                      '호환성 정보',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• ETC2: OpenGL ES 3.0+ (API 18+) 필요\n'
                  '• ASTC: 최신 기기 권장 (API 21+)\n'
                  '• 타겟 API: ${settings.targetAndroidApiLevel}',
                  style: TextStyle(
                    fontSize: 10,
                    color: EditorColors.iconDisabled,
                    height: 1.5,
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

class _IOSFormatTab extends ConsumerWidget {
  final TextureCompressionSettings settings;

  const _IOSFormatTab({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'iOS 압축 포맷',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(height: 8),
          ...TextureCompressionFormat.iosFormats.map((format) {
            final isSelected = settings.iosFormat == format;
            return _FormatOptionTile(
              format: format,
              isSelected: isSelected,
              onTap: () {
                ref.read(texturePackingSettingsProvider.notifier).updateIOSFormat(format);
              },
            );
          }),

          const SizedBox(height: 16),

          // Compatibility info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EditorColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: EditorColors.iconDisabled),
                    const SizedBox(width: 8),
                    Text(
                      '호환성 정보',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• ASTC: iOS 8+ (A8 칩, iPhone 6+) 지원\n'
                  '• Apple Silicon 최적화 지원\n'
                  '• 타겟 iOS: ${settings.targetIOSVersion}+',
                  style: TextStyle(
                    fontSize: 10,
                    color: EditorColors.iconDisabled,
                    height: 1.5,
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

class _FormatOptionTile extends StatelessWidget {
  final TextureCompressionFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOptionTile({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? EditorColors.primary.withValues(alpha: 0.1)
                : EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? EditorColors.primary : EditorColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? EditorColors.primary : EditorColors.iconDefault,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      format.compressionDescription,
                      style: TextStyle(
                        fontSize: 10,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              // BPP indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBppColor(format.bitsPerPixel).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${format.bitsPerPixel} bpp',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getBppColor(format.bitsPerPixel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBppColor(double bpp) {
    if (bpp <= 2) return EditorColors.secondary;
    if (bpp <= 4) return EditorColors.primary;
    return EditorColors.warning;
  }
}

class _ASTCBlockSizeSection extends ConsumerWidget {
  final TextureCompressionSettings settings;

  const _ASTCBlockSizeSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASTC 블록 크기',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: EditorColors.iconDefault,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: DropdownButton<ASTCBlockSize>(
            value: settings.astcBlockSize,
            items: ASTCBlockSize.values.map((size) {
              return DropdownMenuItem(
                value: size,
                child: Row(
                  children: [
                    Text(size.displayName),
                    const SizedBox(width: 8),
                    Text(
                      '(${size.bitsPerPixel} bpp)',
                      style: TextStyle(
                        fontSize: 11,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(texturePackingSettingsProvider.notifier).updateASTCBlockSize(value);
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
        const SizedBox(height: 4),
        Text(
          settings.astcBlockSize.efficiencyDescription,
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
      ],
    );
  }
}

class _FallbackFormatSection extends ConsumerWidget {
  final TextureCompressionSettings settings;

  const _FallbackFormatSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '폴백 포맷',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: EditorColors.iconDefault,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '기본 포맷이 지원되지 않는 기기에서 사용할 대체 포맷',
              child: Icon(
                Icons.help_outline,
                size: 14,
                color: EditorColors.iconDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: DropdownButton<TextureCompressionFormat?>(
            value: settings.fallbackFormat,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('없음 (폴백 비활성화)'),
              ),
              ...TextureCompressionFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format.displayName),
                );
              }),
            ],
            onChanged: (value) {
              ref.read(texturePackingSettingsProvider.notifier).updateFallbackFormat(value);
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
      ],
    );
  }
}
