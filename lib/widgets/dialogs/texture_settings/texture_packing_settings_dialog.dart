import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/texture_packing_settings_provider.dart';
import '../../../theme/editor_colors.dart';
import '../../common/draggable_dialog.dart';
import 'compression_format_section.dart';
import 'export_type_toggle.dart';
import 'game_type_section.dart';
import 'memory_info_panel.dart';
import 'onboarding_stepper.dart';

/// 텍스처 패킹 설정 다이얼로그
/// 온보딩 또는 설정 탭 UI를 조건부로 렌더링
class TexturePackingSettingsDialog extends ConsumerStatefulWidget {
  final int? atlasWidth;
  final int? atlasHeight;

  const TexturePackingSettingsDialog({
    super.key,
    this.atlasWidth,
    this.atlasHeight,
  });

  /// Show texture packing settings dialog
  static Future<void> show(
    BuildContext context, {
    int? atlasWidth,
    int? atlasHeight,
  }) async {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => TexturePackingSettingsDialog(
        atlasWidth: atlasWidth,
        atlasHeight: atlasHeight,
      ),
    );
  }

  @override
  ConsumerState<TexturePackingSettingsDialog> createState() =>
      _TexturePackingSettingsDialogState();
}

class _TexturePackingSettingsDialogState
    extends ConsumerState<TexturePackingSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsOnboarding = ref.watch(needsOnboardingProvider);

    return DraggableDialog(
      header: _buildHeader(needsOnboarding),
      width: 600,
      height: needsOnboarding ? 580 : 650,
      child: needsOnboarding
          ? _buildOnboardingContent()
          : _buildSettingsContent(),
    );
  }

  Widget _buildHeader(bool isOnboarding) {
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
            isOnboarding ? Icons.school : Icons.tune,
            size: 18,
            color: EditorColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            isOnboarding ? '텍스처 설정 가이드' : '텍스처 패킹 설정',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          // Reset onboarding button (only in settings mode)
          if (!isOnboarding)
            IconButton(
              onPressed: () {
                ref.read(texturePackingSettingsProvider.notifier).resetOnboarding();
              },
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: '온보딩 다시 시작',
              color: EditorColors.iconDisabled,
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingContent() {
    return OnboardingStepper(
      onComplete: () {
        Navigator.of(context).pop();
      },
      onSkip: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      children: [
        // Tab bar
        Container(
          color: EditorColors.panelBackground,
          child: TabBar(
            controller: _tabController,
            labelColor: EditorColors.primary,
            unselectedLabelColor: EditorColors.iconDisabled,
            indicatorColor: EditorColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: EditorColors.border,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 16),
                    SizedBox(width: 6),
                    Text('일반'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compress, size: 16),
                    SizedBox(width: 6),
                    Text('압축'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 16),
                    SizedBox(width: 6),
                    Text('정보'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralTab(),
              _buildCompressionTab(),
              _buildInfoTab(),
            ],
          ),
        ),

        // Actions
        _buildActions(),
      ],
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export type toggle
          const ExportTypeToggle(),
          const SizedBox(height: 24),

          // Divider
          const Divider(height: 1),
          const SizedBox(height: 24),

          // Game type section
          const GameTypeSection(),
        ],
      ),
    );
  }

  Widget _buildCompressionTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: CompressionFormatSection(),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MemoryInfoPanel(
        atlasWidth: widget.atlasWidth,
        atlasHeight: widget.atlasHeight,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        border: Border(
          top: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Row(
        children: [
          // Export settings button
          OutlinedButton.icon(
            onPressed: _exportSettings,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('내보내기'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _importSettings,
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('가져오기'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    final json = ref.read(texturePackingSettingsProvider.notifier).exportSettingsJson();
    // Show JSON in a dialog for copying
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 내보내기'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('아래 JSON을 복사하여 저장하세요:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EditorColors.inputBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  json,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _importSettings() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 가져오기'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('설정 JSON을 붙여넣으세요:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '{"androidFormat": ...}',
                  hintStyle: TextStyle(color: EditorColors.iconDisabled),
                ),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final success = ref
                  .read(texturePackingSettingsProvider.notifier)
                  .importSettingsJson(controller.text);
              Navigator.of(context).pop();
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('잘못된 JSON 형식입니다'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('설정을 가져왔습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('가져오기'),
          ),
        ],
      ),
    );
  }
}
