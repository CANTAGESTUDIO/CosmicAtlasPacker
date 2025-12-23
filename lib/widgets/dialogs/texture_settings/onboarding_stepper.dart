import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/texture_compression_settings.dart';
import '../../../providers/texture_packing_settings_provider.dart';
import '../../../theme/editor_colors.dart';

/// 6단계 온보딩 스테퍼 위젯
/// 텍스처 압축 설정을 위한 가이드 온보딩 제공
class OnboardingStepper extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const OnboardingStepper({
    super.key,
    this.onComplete,
    this.onSkip,
  });

  @override
  ConsumerState<OnboardingStepper> createState() => _OnboardingStepperState();
}

class _OnboardingStepperState extends ConsumerState<OnboardingStepper> {
  late PageController _pageController;

  // Step 1: 타겟 기기 정의
  int _targetAndroidApi = 21;
  int _targetIOSVersion = 12;
  int _targetMinRamGB = 2;

  // Step 2: 그래픽 품질 수준
  GameType _selectedGameType = GameType.casual2D;

  // Step 3: 메모리 예산
  int _memoryBudgetMB = 100;
  int _textureAllocationPercent = 50;

  // Step 4: 압축 전략
  TextureCompressionFormat _androidFormat = TextureCompressionFormat.etc2_8bit;
  TextureCompressionFormat _iosFormat = TextureCompressionFormat.astc6x6;
  ASTCBlockSize _astcBlockSize = ASTCBlockSize.block6x6;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(texturePackingSettingsProvider);
    _pageController = PageController(initialPage: settings.onboardingStep - 1);
    _loadSettingsState(settings);
  }

  void _loadSettingsState(TextureCompressionSettings settings) {
    _targetAndroidApi = settings.targetAndroidApiLevel;
    _targetIOSVersion = settings.targetIOSVersion;
    _targetMinRamGB = settings.targetMinRamGB;
    _selectedGameType = settings.gameType;
    _memoryBudgetMB = settings.memoryBudgetMB;
    _textureAllocationPercent = settings.textureAllocationPercent;
    _androidFormat = settings.androidFormat;
    _iosFormat = settings.iosFormat;
    _astcBlockSize = settings.astcBlockSize;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(texturePackingSettingsProvider.notifier).updateOnboardingStep(step);
  }

  void _nextStep() {
    final currentStep = ref.read(texturePackingSettingsProvider).onboardingStep;
    if (currentStep < 6) {
      _saveCurrentStepSettings();
      _goToStep(currentStep + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    final currentStep = ref.read(texturePackingSettingsProvider).onboardingStep;
    if (currentStep > 1) {
      _goToStep(currentStep - 1);
    }
  }

  void _saveCurrentStepSettings() {
    final notifier = ref.read(texturePackingSettingsProvider.notifier);
    final currentStep = ref.read(texturePackingSettingsProvider).onboardingStep;

    switch (currentStep) {
      case 1:
        notifier.updateTargetAndroidApiLevel(_targetAndroidApi);
        notifier.updateTargetIOSVersion(_targetIOSVersion);
        notifier.updateTargetMinRamGB(_targetMinRamGB);
        break;
      case 2:
        notifier.updateGameType(_selectedGameType);
        break;
      case 3:
        notifier.updateMemoryBudgetMB(_memoryBudgetMB);
        notifier.updateTextureAllocationPercent(_textureAllocationPercent);
        break;
      case 4:
        notifier.updateAndroidFormat(_androidFormat);
        notifier.updateIOSFormat(_iosFormat);
        notifier.updateASTCBlockSize(_astcBlockSize);
        break;
    }
  }

  void _completeOnboarding() {
    _saveCurrentStepSettings();
    ref.read(texturePackingSettingsProvider.notifier).completeOnboarding();
    widget.onComplete?.call();
  }

  void _skipOnboarding() {
    ref.read(texturePackingSettingsProvider.notifier).skipOnboarding();
    widget.onSkip?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(texturePackingSettingsProvider).onboardingStep;

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(currentStep),
        const SizedBox(height: 16),

        // Step content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1TargetDevice(),
              _buildStep2GraphicsQuality(),
              _buildStep3MemoryBudget(),
              _buildStep4CompressionStrategy(),
              _buildStep5BuildImpact(),
              _buildStep6QAPlan(),
            ],
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(currentStep),
      ],
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(6, (index) {
              final step = index + 1;
              final isActive = step == currentStep;
              final isCompleted = step < currentStep;

              return Expanded(
                child: GestureDetector(
                  onTap: step <= currentStep ? () => _goToStep(step) : null,
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 5 ? 4 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isCompleted
                          ? EditorColors.secondary
                          : isActive
                              ? EditorColors.primary
                              : EditorColors.border,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step $currentStep / 6',
            style: TextStyle(
              fontSize: 11,
              color: EditorColors.iconDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(int currentStep) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Skip button (except last step)
          if (currentStep < 6)
            TextButton(
              onPressed: _skipOnboarding,
              child: const Text('건너뛰기'),
            ),
          const Spacer(),
          // Previous button
          if (currentStep > 1)
            TextButton(
              onPressed: _previousStep,
              child: const Text('이전'),
            ),
          const SizedBox(width: 8),
          // Next/Complete button
          FilledButton(
            onPressed: _nextStep,
            child: Text(currentStep == 6 ? '완료' : '다음'),
          ),
        ],
      ),
    );
  }

  // ========== Step 1: 타겟 기기 정의 ==========
  Widget _buildStep1TargetDevice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('타겟 기기 정의'),
          _buildStepDescription('게임이 실행될 최소 사양 기기를 설정하세요.'),
          const SizedBox(height: 24),

          // Android API Level
          _buildSectionLabel('Android API Level'),
          const SizedBox(height: 8),
          _buildDropdown<int>(
            value: _targetAndroidApi,
            items: [18, 21, 24, 26, 28, 30, 31, 33].map((api) {
              final name = _getAndroidVersionName(api);
              return DropdownMenuItem(
                value: api,
                child: Text('API $api ($name)'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _targetAndroidApi = value!),
          ),
          _buildHintText('ETC2: API 18+, ASTC: API 21+ 권장'),
          const SizedBox(height: 20),

          // iOS Version
          _buildSectionLabel('iOS 버전'),
          const SizedBox(height: 8),
          _buildDropdown<int>(
            value: _targetIOSVersion,
            items: [10, 11, 12, 13, 14, 15, 16, 17].map((ver) {
              return DropdownMenuItem(
                value: ver,
                child: Text('iOS $ver+'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _targetIOSVersion = value!),
          ),
          _buildHintText('ASTC: iOS 8+ (A8 칩) 지원'),
          const SizedBox(height: 20),

          // Minimum RAM
          _buildSectionLabel('최소 RAM'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _targetMinRamGB.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '${_targetMinRamGB}GB',
                  onChanged: (value) => setState(() => _targetMinRamGB = value.round()),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${_targetMinRamGB}GB',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          _buildHintText('타겟 기기의 최소 RAM 용량'),
        ],
      ),
    );
  }

  String _getAndroidVersionName(int api) {
    const names = {
      18: '4.3 Jelly Bean',
      21: '5.0 Lollipop',
      24: '7.0 Nougat',
      26: '8.0 Oreo',
      28: '9.0 Pie',
      30: '11',
      31: '12',
      33: '13',
    };
    return names[api] ?? 'Unknown';
  }

  // ========== Step 2: 그래픽 품질 수준 ==========
  Widget _buildStep2GraphicsQuality() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('그래픽 품질 수준'),
          _buildStepDescription('게임 장르에 맞는 프리셋을 선택하세요.'),
          const SizedBox(height: 24),

          // Game Type Selection
          ...GameType.values.map((gameType) {
            final isSelected = _selectedGameType == gameType;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedGameType = gameType),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      Radio<GameType>(
                        value: gameType,
                        groupValue: _selectedGameType,
                        onChanged: (value) => setState(() => _selectedGameType = value!),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gameType.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? EditorColors.primary
                                    : EditorColors.iconDefault,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gameType.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: EditorColors.iconDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          // Preset info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EditorColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프리셋 정보',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPresetInfo('Android', _selectedGameType.defaultAndroidFormat.displayName),
                _buildPresetInfo('iOS', _selectedGameType.defaultIOSFormat.displayName),
                _buildPresetInfo('메모리 예산', '${_selectedGameType.recommendedMemoryBudgetMB}MB'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ========== Step 3: 메모리 예산 설정 ==========
  Widget _buildStep3MemoryBudget() {
    final textureMemory = (_memoryBudgetMB * _textureAllocationPercent / 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('메모리 예산 설정'),
          _buildStepDescription('텍스처에 할당할 메모리 예산을 설정하세요.'),
          const SizedBox(height: 24),

          // Total memory budget
          _buildSectionLabel('전체 메모리 한도'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _memoryBudgetMB.toDouble(),
                  min: 50,
                  max: 500,
                  divisions: 18,
                  label: '${_memoryBudgetMB}MB',
                  onChanged: (value) => setState(() => _memoryBudgetMB = value.round()),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '${_memoryBudgetMB}MB',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Texture allocation
          _buildSectionLabel('텍스처 할당 비율'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _textureAllocationPercent.toDouble(),
                  min: 10,
                  max: 80,
                  divisions: 14,
                  label: '$_textureAllocationPercent%',
                  onChanged: (value) =>
                      setState(() => _textureAllocationPercent = value.round()),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$_textureAllocationPercent%',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Memory visualization
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EditorColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '메모리 할당 시각화',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.iconDefault,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _textureAllocationPercent / 100,
                    minHeight: 24,
                    backgroundColor: EditorColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(EditorColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '텍스처: ${textureMemory}MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: EditorColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '기타: ${_memoryBudgetMB - textureMemory}MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== Step 4: 압축 전략 ==========
  Widget _buildStep4CompressionStrategy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('압축 전략'),
          _buildStepDescription('플랫폼별 텍스처 압축 포맷을 설정하세요.'),
          const SizedBox(height: 24),

          // Android format
          _buildSectionLabel('Android 포맷'),
          const SizedBox(height: 8),
          _buildDropdown<TextureCompressionFormat>(
            value: _androidFormat,
            items: TextureCompressionFormat.androidFormats.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.displayName),
              );
            }).toList(),
            onChanged: (value) => setState(() => _androidFormat = value!),
          ),
          _buildHintText(_androidFormat.compressionDescription),
          const SizedBox(height: 20),

          // iOS format
          _buildSectionLabel('iOS 포맷'),
          const SizedBox(height: 8),
          _buildDropdown<TextureCompressionFormat>(
            value: _iosFormat,
            items: TextureCompressionFormat.iosFormats.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.displayName),
              );
            }).toList(),
            onChanged: (value) => setState(() => _iosFormat = value!),
          ),
          _buildHintText(_iosFormat.compressionDescription),
          const SizedBox(height: 20),

          // ASTC block size
          _buildSectionLabel('ASTC 블록 크기'),
          const SizedBox(height: 8),
          _buildDropdown<ASTCBlockSize>(
            value: _astcBlockSize,
            items: ASTCBlockSize.values.map((size) {
              return DropdownMenuItem(
                value: size,
                child: Text('${size.displayName} - ${size.efficiencyDescription}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _astcBlockSize = value!),
          ),
          _buildHintText('${_astcBlockSize.bitsPerPixel} bpp'),
        ],
      ),
    );
  }

  // ========== Step 5: 빌드 시간 및 CI/CD 영향 ==========
  Widget _buildStep5BuildImpact() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('빌드 시간 분석'),
          _buildStepDescription('선택한 설정이 빌드에 미치는 영향을 확인하세요.'),
          const SizedBox(height: 24),

          // Build impact analysis
          _buildInfoCard(
            icon: Icons.schedule,
            title: '예상 압축 시간',
            content: _getBuildTimeEstimate(),
            color: EditorColors.primary,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.storage,
            title: '예상 파일 크기',
            content: _getFileSizeEstimate(),
            color: EditorColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.speed,
            title: '품질 대비 크기',
            content: _getQualitySizeTradeoff(),
            color: EditorColors.warning,
          ),
          const SizedBox(height: 24),

          // Recommendations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EditorColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EditorColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: EditorColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '권장 사항',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EditorColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 개발 중: 빠른 빌드를 위해 압축 비활성화 권장\n'
                  '• 테스트: 중간 품질 설정으로 빠른 확인\n'
                  '• 출시: 현재 설정으로 최적화된 빌드',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDefault,
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

  String _getBuildTimeEstimate() {
    // ASTC 압축은 ETC2보다 느림
    if (_androidFormat.name.startsWith('astc') || _iosFormat.name.startsWith('astc')) {
      return 'ASTC 압축 포함: 중간~긴 시간 소요';
    }
    return 'ETC2 압축: 상대적으로 빠름';
  }

  String _getFileSizeEstimate() {
    final avgBpp = (_androidFormat.bitsPerPixel + _iosFormat.bitsPerPixel) / 2;
    if (avgBpp <= 2) {
      return '매우 작음 (${avgBpp.toStringAsFixed(1)} bpp)';
    } else if (avgBpp <= 4) {
      return '작음 (${avgBpp.toStringAsFixed(1)} bpp)';
    } else {
      return '보통 (${avgBpp.toStringAsFixed(1)} bpp)';
    }
  }

  String _getQualitySizeTradeoff() {
    final qualityLevel = _astcBlockSize.qualityLevel;
    if (qualityLevel >= 4) {
      return '높은 품질 / 큰 파일 크기';
    } else if (qualityLevel >= 3) {
      return '균형 잡힌 품질 / 적당한 크기';
    } else {
      return '낮은 품질 / 작은 파일 크기';
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDisabled,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== Step 6: QA 테스트 계획 ==========
  Widget _buildStep6QAPlan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('QA 테스트 계획'),
          _buildStepDescription('설정 완료! 테스트 체크리스트를 확인하세요.'),
          const SizedBox(height: 24),

          // Test checklist
          _buildChecklistItem('저사양 기기에서 텍스처 로딩 테스트'),
          _buildChecklistItem('고해상도 디스플레이에서 품질 확인'),
          _buildChecklistItem('메모리 프로파일링 수행'),
          _buildChecklistItem('압축 아티팩트 시각적 검수'),
          _buildChecklistItem('다양한 기기에서 호환성 테스트'),
          const SizedBox(height: 24),

          // Export options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EditorColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EditorColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: EditorColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '설정 완료',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EditorColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '설정이 저장되었습니다. 언제든지 텍스처 설정 다이얼로그에서 수정할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary
          _buildSettingsSummary(),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 18,
            color: EditorColors.iconDisabled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설정 요약',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('게임 타입', _selectedGameType.displayName),
          _buildSummaryRow('Android 포맷', _androidFormat.displayName),
          _buildSummaryRow('iOS 포맷', _iosFormat.displayName),
          _buildSummaryRow('메모리 예산', '${_memoryBudgetMB}MB'),
          _buildSummaryRow('타겟 기기', 'API $_targetAndroidApi+ / iOS $_targetIOSVersion+'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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

  // ========== Helper Widgets ==========
  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStepDescription(String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 13,
          color: EditorColors.iconDisabled,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: EditorColors.iconDefault,
      ),
    );
  }

  Widget _buildHintText(String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        hint,
        style: TextStyle(
          fontSize: 11,
          color: EditorColors.iconDisabled,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: EditorColors.surface,
        style: TextStyle(
          fontSize: 13,
          color: EditorColors.iconDefault,
        ),
      ),
    );
  }
}
