import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/texture_compression_settings.dart';
import '../../providers/texture_packing_settings_provider.dart';
import '../../providers/export_provider.dart';
import '../../providers/packing_provider.dart';
import '../../providers/sprite_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../providers/image_provider.dart';
import '../../providers/animation_provider.dart';
import '../../services/bin_packing_service.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';
import '../common/editor_dropdown.dart';
import 'texture_settings/onboarding_stepper.dart';

/// 텍스처 아틀라스 내보내기 다이얼로그
/// (대폭 확장된 UI: 설정, 압축, 내보내기 옵션 통합)
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const ExportDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late TextEditingController _pathController;
  late TextEditingController _nameController;

  bool _exportPng = true;
  bool _exportJson = true;
  bool _prettyPrintJson = true;
  bool _exportAnimationInfo = true; // 애니메이션이 있으면 기본 체크
  bool _exportSpriteFont = false; // 스프라이트 폰트 내보내기

  // 텍스처 압축 설정
  bool _enableTextureCompression = false; // 텍스처 압축 토글 (OFF = 일반 이미지, ON = ASTC/ETC2)

  // 이미지 출력 포맷 설정 (텍스처 압축 OFF일 때 사용)
  ImageOutputFormat _imageFormat = ImageOutputFormat.png;
  int _imageQuality = 80; // WebP/JPEG 품질 (1-100)
  int _pngCompressionLevel = 6; // PNG 압축 레벨 (0-9)

  bool _isExporting = false;
  String? _exportError;
  PackingResult? _previewPackingResult;

  // 실제 이미지 프리뷰 관련 상태
  ui.Image? _previewUiImage;
  bool _isGeneratingPreview = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // Default path setup
    _pathController = TextEditingController(text: '/Users/Shared/AtlasExports');

    // Start with empty filename - user should provide their own
    _nameController = TextEditingController(text: '');

    // Initial Preview Generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePreview();
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    _nameController.dispose();
    _debounceTimer?.cancel();
    // _previewUiImage는 atlasPreviewImageProvider의 공유 리소스이므로 dispose하지 않음
    super.dispose();
  }

  void _updatePreview() {
    // 디바운스: 300ms 후에 프리뷰 생성
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _generatePreview();
    });
  }

  Future<void> _generatePreview() async {
    // 메인 화면과 동일한 패킹 결과 사용
    final result = ref.read(packingResultProvider);

    if (result == null || result.packedSprites.isEmpty) {
      setState(() {
        _previewPackingResult = null;
        _previewUiImage = null;
      });
      return;
    }

    setState(() {
      _previewPackingResult = result;
      _isGeneratingPreview = true;
    });

    // atlasPreviewImageProvider에서 이미 생성된 이미지 사용 (배경색 제거, erosion 등 모든 옵션 적용됨)
    final atlasPreviewImage = await ref.read(atlasPreviewImageProvider.future);

    if (!mounted) return;

    setState(() {
      // atlasPreviewImageProvider의 공유 리소스이므로 dispose하지 않음
      _previewUiImage = atlasPreviewImage;
      _isGeneratingPreview = false;
    });
  }

  Future<void> _selectOutputPath() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Directory',
    );

    if (path != null) {
      setState(() {
        _pathController.text = path;
      });
    }
  }
  
  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: OnboardingStepper(
              onComplete: () => Navigator.of(context).pop(),
              onSkip: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performExport() async {
     if (_pathController.text.isEmpty || _nameController.text.isEmpty) {
      return;
    }

    setState(() {
      _isExporting = true;
      _exportError = null;
    });

    try {
      final sourceImageState = ref.read(sourceImageProvider);
      final exportService = ref.read(exportServiceProvider);
      final animationState = ref.read(animationProvider);

      if (sourceImageState.rawImage == null) {
        throw Exception('No source image loaded');
      }

      if (_previewPackingResult == null ||
          _previewPackingResult!.packedSprites.isEmpty) {
        throw Exception('No sprites to export');
      }

      final outputPath = _pathController.text;
      final fileName = _nameController.text;
      final imageExt = _imageFormat.extension;
      final imagePath = '$outputPath${Platform.pathSeparator}$fileName.$imageExt';
      final jsonPath = '$outputPath${Platform.pathSeparator}$fileName.json';
      final fntPath = '$outputPath${Platform.pathSeparator}$fileName.fnt';

      // Export image (PNG/WebP/JPEG)
      if (_exportPng) {
        final atlasImage = exportService.generateAtlasImage(
          sourceImage: sourceImageState.rawImage!,
          packingResult: _previewPackingResult!,
        );

        // Get quality parameter based on format
        final quality = _imageFormat == ImageOutputFormat.png
            ? _pngCompressionLevel
            : _imageQuality;

        await exportService.exportImage(
          atlasImage: atlasImage,
          outputPath: imagePath,
          format: _imageFormat,
          quality: quality,
        );
      }

      // Export JSON with animation and 9-slice data
      if (_exportJson) {
        // Get animation sequences if export is enabled
        final animations = _exportAnimationInfo && animationState.sequences.isNotEmpty
            ? animationState.sequences
            : null;

        final metadata = exportService.generateMetadata(
          packingResult: _previewPackingResult!,
          atlasFileName: '$fileName.$imageExt',
          animations: animations,
          includeAnimations: _exportAnimationInfo,
        );
        await exportService.exportJson(
          metadata: metadata,
          outputPath: jsonPath,
          prettyPrint: _prettyPrintJson,
        );
      }

      // Export BMFont .fnt file if sprite font option is enabled
      if (_exportSpriteFont) {
        await exportService.exportFnt(
          packingResult: _previewPackingResult!,
          fntPath: fntPath,
          atlasFileName: '$fileName.$imageExt',
          fontName: fileName,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportError = 'Export failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableDialog(
      header: _buildHeader(),
      width: 1500,
      height: 880,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Settings (Output, Texture Compression, Options)
          SizedBox(
            width: 760,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOutputSection(),
                        const SizedBox(height: 28),
                        _buildTextureCompressionSection(),
                        const SizedBox(height: 28),
                        _buildExportOptionsSection(),
                        if (_exportError != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 16),
                             child: Text(_exportError!, style: const TextStyle(color: EditorColors.error)),
                           ),
                      ],
                    ),
                  ),
                ),
                // Actions bar at the bottom of left panel
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: EditorColors.border)),
                  ),
                  child: _buildExportActions(),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(width: 1, color: EditorColors.border),

          // Right: Preview (with margins)
          Expanded(
            child: _buildPreviewSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 24, right: 10),
      decoration: const BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: EditorColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.output, size: 20, color: EditorColors.primary),
          const SizedBox(width: 12),
          const Text(
            '아틀라스 내보내기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            color: EditorColors.iconDefault,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, [Widget? trailing]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: EditorColors.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  // --- 1. Output Section ---
  Widget _buildOutputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('출력 경로 및 이름', Icons.folder_open),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _TextField(
                label: '경로 (Directory)',
                controller: _pathController,
                hint: '/Path/To/Export',
                readOnly: true,
                hasButton: true,
                onButtonPressed: _selectOutputPath,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: _TextField(
                label: '파일 이름 (File Name)',
                controller: _nameController,
                hint: 'atlas_name',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. Texture Compression Settings Section ---
  Widget _buildTextureCompressionSection() {
    final settings = ref.watch(texturePackingSettingsProvider);
    final notifier = ref.read(texturePackingSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          '텍스처 압축 설정',
          Icons.compress,
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: TextButton(
              onPressed: _showOnboardingDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: EditorColors.inputBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 14, color: EditorColors.iconDisabled),
                  const SizedBox(width: 6),
                  Text(
                    '텍스처 포맷 가이드',
                    style: TextStyle(fontSize: 12, color: EditorColors.iconDisabled),
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Preset with recommendations (flex 4)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownColumn<GameType>(
                      label: '프리셋',
                      value: settings.gameType,
                      items: GameType.values,
                      onChanged: (v) {
                        notifier.updateGameType(v!);
                        _updatePreview(); // Trigger preview refresh on preset change
                      },
                      itemLabelBuilder: (i) => i.displayName,
                    ),
                    const SizedBox(height: 16),
                    // Recommendations
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EditorColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: EditorColors.border.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecommendationRow(
                            'Android',
                            settings.gameType.defaultAndroidFormat.displayName,
                            settings.gameType.defaultAndroidFormat.compressionDescription,
                          ),
                          const SizedBox(height: 8),
                          _buildRecommendationRow(
                            'iOS',
                            settings.gameType.defaultIOSFormat.displayName,
                            settings.gameType.defaultIOSFormat.compressionDescription,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right Column: Format Type (flex 6)
              Expanded(
                flex: 6,
                child: _buildDropdownColumn<TextureCompressionFormat>(
                  label: '포맷 타입',
                  value: settings.iosFormat,
                  items: TextureCompressionFormat.values,
                  onChanged: (v) {
                    notifier.updateIOSFormat(v!);
                    _updatePreview(); // Trigger preview refresh on format change
                  },
                  itemLabelBuilder: (i) => '${i.displayName}  -  ${i.compressionDescription}',
                  helperText: settings.iosFormat.detailedDescription,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationRow(String platform, String format, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$platform:',
            style: const TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: format,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EditorColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' - $description',
                  style: const TextStyle(
                    fontSize: 12,
                    color: EditorColors.iconDisabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Export Options Section ---
  Widget _buildExportOptionsSection() {
    final animationState = ref.watch(animationProvider);
    final hasAnimations = animationState.sequences.isNotEmpty;
    final animationCount = animationState.sequences.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('내보내기 옵션', Icons.settings_applications),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EditorColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border),
          ),
          child: Column(
            children: [
              // 이미지 내보내기 + 포맷 선택
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 체크박스
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _exportPng,
                      onChanged: (v) => setState(() => _exportPng = v ?? true),
                      activeColor: EditorColors.primary,
                      side: const BorderSide(color: EditorColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '이미지 내보내기',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _exportPng ? EditorColors.iconDefault : EditorColors.iconDisabled,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 포맷 선택 드롭다운
                            _buildFormatDropdown(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 품질/압축 슬라이더 (PNG가 아닌 경우만)
                        if (_exportPng) _buildQualitySlider(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCompactCheckbox(
                title: 'JSON 메타데이터',
                description: '스프라이트 좌표/크기 정보',
                value: _exportJson,
                onChanged: (v) => setState(() => _exportJson = v ?? true),
              ),
              // 메타데이터 하위 옵션 (트리구조)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _exportJson
                    ? Padding(
                        padding: const EdgeInsets.only(left: 30, top: 8),
                        child: Column(
                          children: [
                            // 애니메이션 정보 옵션
                            _buildTreeSubOption(
                              title: '애니메이션 정보',
                              description: hasAnimations
                                  ? '$animationCount개의 애니메이션 시퀀스'
                                  : '애니메이션 없음',
                              value: _exportAnimationInfo && hasAnimations,
                              enabled: hasAnimations,
                              onChanged: (v) => setState(() => _exportAnimationInfo = v ?? true),
                            ),
                            const SizedBox(height: 6),
                            // Pretty Print 옵션
                            _buildTreeSubOption(
                              title: 'Pretty Print',
                              description: '읽기 쉬운 JSON 포맷',
                              value: _prettyPrintJson,
                              enabled: true,
                              onChanged: (v) => setState(() => _prettyPrintJson = v ?? false),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              // 스프라이트 폰트 옵션
              _buildCompactCheckbox(
                title: '스프라이트 폰트',
                description: 'BMFont 호환 폰트 데이터 (.fnt)',
                value: _exportSpriteFont,
                onChanged: (v) => setState(() => _exportSpriteFont = v ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: EditorColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: DropdownButton<ImageOutputFormat>(
        value: _imageFormat,
        onChanged: _exportPng ? (v) {
          if (v != null) {
            setState(() {
              _imageFormat = v;
              // 포맷 변경 시 기본 품질로 리셋
              _imageQuality = v.defaultQuality;
              _pngCompressionLevel = 6;
            });
          }
        } : null,
        underline: const SizedBox(),
        isDense: true,
        dropdownColor: EditorColors.surface,
        style: const TextStyle(fontSize: 12, color: EditorColors.iconDefault),
        items: ImageOutputFormat.values.map((format) {
          return DropdownMenuItem(
            value: format,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  format == ImageOutputFormat.png ? Icons.image : Icons.photo,
                  size: 14,
                  color: EditorColors.iconDisabled,
                ),
                const SizedBox(width: 6),
                Text(format.displayName),
                const SizedBox(width: 8),
                Text(
                  format.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: EditorColors.iconDisabled.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQualitySlider() {
    final exportService = ref.read(exportServiceProvider);
    final estimatedSizeKB = _previewPackingResult != null
        ? exportService.estimateFileSize(
            atlasWidth: _previewPackingResult!.atlasWidth,
            atlasHeight: _previewPackingResult!.atlasHeight,
            format: _imageFormat,
            quality: _imageFormat == ImageOutputFormat.png
                ? _pngCompressionLevel
                : _imageQuality,
          )
        : 0.0;

    // 예상 크기 표시 문자열
    String sizeText;
    if (estimatedSizeKB >= 1024) {
      sizeText = '~${(estimatedSizeKB / 1024).toStringAsFixed(1)} MB';
    } else {
      sizeText = '~${estimatedSizeKB.toStringAsFixed(0)} KB';
    }

    // PNG는 압축 레벨 (0-9), WebP/JPEG는 품질 (1-100)
    final isPng = _imageFormat == ImageOutputFormat.png;
    final currentValue = isPng ? _pngCompressionLevel.toDouble() : _imageQuality.toDouble();
    final minValue = isPng ? 0.0 : 1.0;
    final maxValue = isPng ? 9.0 : 100.0;
    final divisions = isPng ? 9 : 99;

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            _imageFormat.qualityLabel,
            style: const TextStyle(fontSize: 11, color: EditorColors.iconDisabled),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: EditorColors.primary,
              inactiveTrackColor: EditorColors.border,
              thumbColor: EditorColors.primary,
              overlayColor: EditorColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentValue,
              min: minValue,
              max: maxValue,
              divisions: divisions,
              onChanged: (v) {
                setState(() {
                  if (isPng) {
                    _pngCompressionLevel = v.round();
                  } else {
                    _imageQuality = v.round();
                  }
                });
              },
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            isPng ? '$_pngCompressionLevel' : '$_imageQuality%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 16),
        // 예상 파일 크기
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: EditorColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: EditorColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_zip,
                size: 12,
                color: _imageFormat == ImageOutputFormat.jpeg
                    ? EditorColors.warning
                    : EditorColors.iconDisabled,
              ),
              const SizedBox(width: 4),
              Text(
                sizeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _imageFormat == ImageOutputFormat.jpeg
                      ? EditorColors.warning
                      : EditorColors.iconDisabled,
                ),
              ),
            ],
          ),
        ),
        // JPEG 알파 경고
        if (_imageFormat == ImageOutputFormat.jpeg) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'JPEG는 투명도를 지원하지 않습니다.\n투명 영역은 흰색으로 채워집니다.',
            child: Icon(
              Icons.warning_amber,
              size: 16,
              color: EditorColors.warning,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTreeSubOption({
    required String title,
    required String description,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?> onChanged,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Row(
            children: [
              // 트리 라인 표시
              Container(
                width: 12,
                height: 20,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 8,
                  height: 1,
                  color: EditorColors.border,
                ),
              ),
              SizedBox(
                height: 18,
                width: 18,
                child: Checkbox(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeColor: EditorColors.primary,
                  side: BorderSide(
                    color: enabled ? EditorColors.border : EditorColors.border.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? (value ? EditorColors.iconDefault : EditorColors.iconDisabled)
                      : EditorColors.iconDisabled.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled.withValues(alpha: enabled ? 0.4 : 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCheckbox({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: EditorColors.primary,
              side: const BorderSide(color: EditorColors.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value ? EditorColors.iconDefault : EditorColors.iconDisabled,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: EditorColors.iconDisabled.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownColumn<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabelBuilder,
    String? helperText,
  }) {
    return EditorDropdown<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      itemLabelBuilder: itemLabelBuilder,
      helperText: helperText,
    );
  }

  Widget _buildExportActions() {
    final hasSprites = _previewPackingResult != null &&
        _previewPackingResult!.packedSprites.isNotEmpty;
    final canExport = hasSprites &&
        !_isExporting &&
        _pathController.text.isNotEmpty &&
        _nameController.text.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 스프라이트 없을 때 경고 메시지
        if (!hasSprites)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber, size: 16, color: EditorColors.warning),
                const SizedBox(width: 6),
                Text(
                  '내보낼 스프라이트가 없습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: EditorColors.warning,
                  ),
                ),
              ],
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('취소'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: canExport ? _performExport : null,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('내보내기'),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final animationState = ref.watch(animationProvider);
    final multiSpriteState = ref.watch(multiSpriteProvider);
    final legacySpriteState = ref.watch(spriteProvider);

    // Use multiSpriteProvider first, fallback to legacy
    final allSprites = multiSpriteState.allSprites.isNotEmpty
        ? multiSpriteState.allSprites
        : legacySpriteState.sprites;

    // Count 9-slice enabled sprites
    final nineSliceCount = allSprites.where((s) => s.hasNineSlice).length;
    final animationCount = animationState.sequences.length;
    final spriteCount = _previewPackingResult?.packedSprites.length ?? 0;

    return Container(
      color: const Color(0xFF2A2A2A), // Dark gray background for contrast
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 24), // 오른쪽 여백 줄임
      child: Column(
        children: [
          // Header inside the preview panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: EditorColors.panelBackground, // Inner container header
              border: Border.all(color: EditorColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility, size: 18, color: EditorColors.iconDefault),
                const SizedBox(width: 8),
                const Text(
                  '최종 결과물 미리보기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.iconDefault,
                  ),
                ),
                const Spacer(),
                // Stats container - 텍스처 압축 포맷에 따른 예상 용량
                Builder(
                  builder: (context) {
                    final textureSettings = ref.watch(texturePackingSettingsProvider);
                    final bpp = textureSettings.iosFormat.bitsPerPixel;
                    final sizeBytes = _previewPackingResult != null
                        ? (_previewPackingResult!.atlasWidth * _previewPackingResult!.atlasHeight * bpp / 8)
                        : 0.0;
                    final sizeMB = sizeBytes / (1024 * 1024);
                    final sizeKB = sizeBytes / 1024;
                    final sizeText = sizeMB >= 1.0
                        ? '${sizeMB.toStringAsFixed(2)} MB'
                        : '${sizeKB.toStringAsFixed(0)} KB';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: EditorColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.memory, size: 16, color: EditorColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            sizeText,
                            style: const TextStyle(fontSize: 13, color: EditorColors.iconDefault, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // The actual preview area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E), // Slightly lighter than black, distinct from panel
                border: Border(
                  left: BorderSide(color: EditorColors.border),
                  right: BorderSide(color: EditorColors.border),
                  bottom: BorderSide(color: EditorColors.border),
                ),
              ),
              child: _buildPreviewContent(),
            ),
          ),

          // Export info stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: EditorColors.panelBackground,
              border: Border.all(color: EditorColors.border),
            ),
            child: Row(
              children: [
                // Sprite count
                _buildStatChip(
                  icon: Icons.grid_view,
                  label: '스프라이트',
                  value: _exportSpriteFont ? '$spriteCount자' : '$spriteCount개',
                  color: EditorColors.primary,
                ),
                const SizedBox(width: 12),
                // Animation count (if enabled)
                if (_exportAnimationInfo && animationCount > 0)
                  _buildStatChip(
                    icon: Icons.animation,
                    label: '애니메이션',
                    value: '$animationCount개',
                    color: EditorColors.secondary,
                  ),
                if (_exportAnimationInfo && animationCount > 0)
                  const SizedBox(width: 12),
                // 9-Slice count (if any)
                if (nineSliceCount > 0)
                  _buildStatChip(
                    icon: Icons.grid_on,
                    label: '9-Slice',
                    value: '$nineSliceCount개',
                    color: EditorColors.warning,
                  ),
                if (nineSliceCount > 0)
                  const SizedBox(width: 12),
                // Font mode indicator
                if (_exportSpriteFont)
                  _buildStatChip(
                    icon: Icons.font_download,
                    label: '폰트 모드',
                    value: 'BMFont',
                    color: EditorColors.success,
                  ),
                const Spacer(),
                // Atlas size
                if (_previewPackingResult != null)
                  Text(
                    '${_previewPackingResult!.atlasWidth} × ${_previewPackingResult!.atlasHeight}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: EditorColors.iconDisabled,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewContent() {
    if (_previewPackingResult == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.content_cut,
              size: 64,
              color: EditorColors.iconDisabled.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '내보낼 스프라이트가 없습니다',
              style: TextStyle(
                color: EditorColors.iconDisabled,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '먼저 이미지에서 스프라이트 영역을 정의하세요\n(Auto Slice, Grid Slice, 또는 수동 선택)',
              style: TextStyle(
                color: EditorColors.iconDisabled.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final result = _previewPackingResult!;
        final scale = _calculatePreviewScale(
          result.atlasWidth,
          result.atlasHeight,
          constraints.maxWidth - 32,
          constraints.maxHeight - 32,
        );

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 실제 이미지 프리뷰
              Container(
                width: result.atlasWidth * scale,
                height: result.atlasHeight * scale,
                decoration: BoxDecoration(
                  border: Border.all(color: EditorColors.primary.withOpacity(0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: CustomPaint(
                  painter: _AtlasPreviewPainter(
                    packingResult: result,
                    scale: scale,
                    previewImage: _previewUiImage,
                  ),
                ),
              ),
              // 로딩 인디케이터
              if (_isGeneratingPreview)
                Container(
                  width: result.atlasWidth * scale,
                  height: result.atlasHeight * scale,
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: EditorColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '프리뷰 생성 중...',
                          style: TextStyle(
                            fontSize: 12,
                            color: EditorColors.iconDefault.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _calculatePreviewScale(
    int atlasWidth,
    int atlasHeight,
    double maxWidth,
    double maxHeight,
  ) {
    if (atlasWidth == 0 || atlasHeight == 0) return 1.0;
    final scaleX = maxWidth / atlasWidth;
    final scaleY = maxHeight / atlasHeight;
    return (scaleX < scaleY ? scaleX : scaleY).clamp(0.01, 1.0);
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final bool hasButton;
  final VoidCallback? onButtonPressed;

  const _TextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.hasButton = false,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 14, color: EditorColors.iconDefault),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: EditorColors.iconDisabled),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: EditorColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: EditorColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: EditorColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: EditorColors.primary),
            ),
            suffixIcon: hasButton
                ? IconButton(
                    onPressed: onButtonPressed,
                    icon: const Icon(Icons.folder_open, size: 18),
                    color: EditorColors.iconDisabled,
                    splashRadius: 20,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _AtlasPreviewPainter extends CustomPainter {
  final PackingResult packingResult;
  final double scale;
  final ui.Image? previewImage;

  _AtlasPreviewPainter({
    required this.packingResult,
    required this.scale,
    this.previewImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale canvas
    canvas.scale(scale);

    final atlasRect = Rect.fromLTWH(
      0,
      0,
      packingResult.atlasWidth.toDouble(),
      packingResult.atlasHeight.toDouble(),
    );

    // Draw checkerboard background for transparency
    _drawCheckerboard(canvas, atlasRect);

    // Draw actual atlas image if available
    if (previewImage != null) {
      canvas.drawImage(
        previewImage!,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      // Fallback: draw rectangles if image not ready
      final rectPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1.0 / scale;

      for (final sprite in packingResult.packedSprites) {
        canvas.drawRect(sprite.packedRect, rectPaint);
      }
    }

    // Draw Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = EditorColors.primary
      ..strokeWidth = 2.0 / scale;
    canvas.drawRect(atlasRect, borderPaint);
  }

  /// 체커보드 패턴 그리기 (투명도 표현)
  void _drawCheckerboard(Canvas canvas, Rect rect) {
    const cellSize = 8.0;
    final lightPaint = Paint()..color = const Color(0xFF2A2A2A);
    final darkPaint = Paint()..color = const Color(0xFF1E1E1E);

    for (double y = rect.top; y < rect.bottom; y += cellSize) {
      for (double x = rect.left; x < rect.right; x += cellSize) {
        final isEvenRow = ((y / cellSize).floor() % 2) == 0;
        final isEvenCol = ((x / cellSize).floor() % 2) == 0;
        final paint = (isEvenRow == isEvenCol) ? lightPaint : darkPaint;

        final cellRect = Rect.fromLTWH(
          x,
          y,
          (x + cellSize > rect.right) ? rect.right - x : cellSize,
          (y + cellSize > rect.bottom) ? rect.bottom - y : cellSize,
        );
        canvas.drawRect(cellRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtlasPreviewPainter oldDelegate) {
    return oldDelegate.packingResult != packingResult ||
        oldDelegate.scale != scale ||
        oldDelegate.previewImage != previewImage;
  }
}
