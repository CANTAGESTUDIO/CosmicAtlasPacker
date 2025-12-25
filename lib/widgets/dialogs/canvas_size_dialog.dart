import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../models/sprite_region.dart';
import '../../models/sprite_slice_mode.dart';
import '../../providers/multi_image_provider.dart';
import '../../providers/multi_sprite_provider.dart';
import '../../providers/packing_provider.dart';
import '../../services/auto_slicer_service.dart';
import '../../services/background_remover_service.dart';
import '../../services/bin_packing_service.dart' show PackingResult;
import '../../services/image_loader_service.dart';
import '../../services/smart_packing_service.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';

/// Smart Packing Dialog
/// - Auto-slices if no sprites exist
/// - Applies smart packing algorithm (small sprites first)
class CanvasSizeDialog extends ConsumerStatefulWidget {
  const CanvasSizeDialog({super.key});

  /// Show smart packing dialog
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const CanvasSizeDialog(),
    );
  }

  @override
  ConsumerState<CanvasSizeDialog> createState() => _CanvasSizeDialogState();
}

class _CanvasSizeDialogState extends ConsumerState<CanvasSizeDialog> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late FocusNode _widthFocus;
  late FocusNode _heightFocus;

  bool _lockAspectRatio = false;
  // 패킹 옵션은 atlasSettingsProvider에서 관리 (프리뷰 패널에서 설정)

  late int _originalWidth;
  late int _originalHeight;
  double _aspectRatio = 1.0;

  // Preview state
  double _previewEfficiency = 0.0;
  double _previewScale = 1.0;
  bool _previewComplete = false;
  bool _isCalculating = false;
  bool _isApplying = false;
  String? _applyingMessage;
  PackingResult? _cachedPackingResult;

  // Original SmartMode state for restore on cancel
  bool _originalSmartMode = false;

  // Check if sprites exist (모든 스프라이트 확인)
  bool get _hasSprites => ref.read(multiSpriteProvider).allSprites.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _widthFocus = FocusNode();
    _heightFocus = FocusNode();

    // Get current atlas size or default
    final atlasSize = ref.read(atlasSizeProvider);

    // If no sprites, use default 512x512
    _originalWidth = atlasSize.$1 > 0 ? atlasSize.$1 : 512;
    _originalHeight = atlasSize.$2 > 0 ? atlasSize.$2 : 512;
    _aspectRatio = _originalWidth / _originalHeight;

    _widthController = TextEditingController(text: _originalWidth.toString());
    _heightController = TextEditingController(text: _originalHeight.toString());

    _widthFocus.addListener(_onWidthFocusChange);
    _heightFocus.addListener(_onHeightFocusChange);

    // Save original SmartMode state for restore on cancel
    _originalSmartMode = ref.read(isSmartPackingModeProvider);

    // Initial preview calculation (only if sprites exist)
    // WidgetsBinding을 사용하여 빌드 완료 후 호출 (initState에서 provider 수정 불가)
    if (_hasSprites) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _calculatePreview();
      });
    }
  }

  @override
  void dispose() {
    _widthFocus.removeListener(_onWidthFocusChange);
    _heightFocus.removeListener(_onHeightFocusChange);
    _widthFocus.dispose();
    _heightFocus.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onWidthFocusChange() {
    if (!_widthFocus.hasFocus) {
      _validateAndUpdateWidth();
      if (_hasSprites) _calculatePreview();
    }
  }

  void _onHeightFocusChange() {
    if (!_heightFocus.hasFocus) {
      _validateAndUpdateHeight();
      if (_hasSprites) _calculatePreview();
    }
  }

  void _validateAndUpdateWidth() {
    final value = int.tryParse(_widthController.text) ?? _originalWidth;
    final clamped = value.clamp(64, 8192);
    _widthController.text = clamped.toString();

    if (_lockAspectRatio) {
      final newHeight = (clamped / _aspectRatio).round().clamp(64, 8192);
      _heightController.text = newHeight.toString();
    }

    // forceSquare 설정은 atlasSettingsProvider에서 읽기
    final settings = ref.read(atlasSettingsProvider);
    if (settings.forceSquare) {
      _heightController.text = clamped.toString();
    }
  }

  void _validateAndUpdateHeight() {
    final value = int.tryParse(_heightController.text) ?? _originalHeight;
    final clamped = value.clamp(64, 8192);
    _heightController.text = clamped.toString();

    if (_lockAspectRatio) {
      final newWidth = (clamped * _aspectRatio).round().clamp(64, 8192);
      _widthController.text = newWidth.toString();
    }

    // forceSquare 설정은 atlasSettingsProvider에서 읽기
    final settings = ref.read(atlasSettingsProvider);
    if (settings.forceSquare) {
      _widthController.text = clamped.toString();
    }
  }

  /// Calculate preview efficiency with current settings
  void _calculatePreview() {
    final targetWidth = int.tryParse(_widthController.text) ?? _originalWidth;
    final targetHeight = int.tryParse(_heightController.text) ?? _originalHeight;

    // DEBUG: 상세 진단 로그
    final atlasSources = ref.read(atlasSourcesProvider);
    final multiImageState = ref.read(multiImageProvider);
    final multiSpriteState = ref.read(multiSpriteProvider);

    print('[SmartPackingDialog] _calculatePreview DEBUG:');
    print('  - activeSourceId: ${multiImageState.activeSourceId}');
    print('  - atlasSources: ${atlasSources.length} (ids: ${atlasSources.map((s) => s.id).toList()})');
    print('  - multiSpriteState.allSprites: ${multiSpriteState.allSprites.length}');
    print('  - spritesBySource keys: ${multiSpriteState.spritesBySource.keys.toList()}');

    // 모든 스프라이트 사용 (소스 ID 불일치 문제 해결)
    // - 사용자가 같은 이미지를 다시 로드하면 새 소스 ID가 생성됨
    // - 하지만 스프라이트는 이전 소스 ID에 등록되어 있음
    // - 따라서 모든 스프라이트를 프리뷰에 포함
    final sprites = multiSpriteState.allSprites;

    print('  - allSprites: ${sprites.length}');

    if (sprites.isEmpty) {
      setState(() {
        _previewEfficiency = 0.0;
        _previewScale = 1.0;
        _previewComplete = true;
        _cachedPackingResult = null;
      });
      return;
    }

    setState(() => _isCalculating = true);

    // 패킹 옵션은 atlasSettingsProvider에서 읽기 (프리뷰 패널에서 설정)
    final settings = ref.read(atlasSettingsProvider);
    final effectivePadding = settings.tightPacking ? 0 : settings.padding;

    // Use SmartPackingService (small sprites first algorithm)
    final smartService = SmartPackingService();
    final smartResult = smartService.findOptimalPacking(
      sprites: sprites,
      canvasWidth: targetWidth,
      canvasHeight: targetHeight,
      padding: effectivePadding,
      allowRotation: settings.allowRotation,
    );

    // Calculate average scale for display
    double totalScale = 0;
    int scaledCount = 0;
    for (final sprite in smartResult.includedSprites) {
      final scale = smartResult.individualScales[sprite.id] ?? 1.0;
      totalScale += scale;
      if (scale < 1.0) scaledCount++;
    }
    final avgScale = smartResult.includedSprites.isEmpty
        ? 1.0
        : totalScale / smartResult.includedSprites.length;

    setState(() {
      _previewEfficiency = smartResult.efficiency;
      _previewScale = avgScale;
      _previewComplete = smartResult.excludedSprites.isEmpty && scaledCount == 0;
      _isCalculating = false;
      _cachedPackingResult = smartResult.packingResult;
    });
    // Note: 프리뷰는 로컬 상태로만 관리, 실제 적용 시 SmartMode 활성화
  }

  Future<void> _apply() async {
    final targetWidth = int.tryParse(_widthController.text) ?? _originalWidth;
    final targetHeight = int.tryParse(_heightController.text) ?? _originalHeight;

    setState(() {
      _isApplying = true;
      _applyingMessage = '처리 중...';
    });

    try {
      // Check if sprites exist
      var sprites = ref.read(atlasSpritesProvider);

      if (sprites.isEmpty) {
        // Run auto-slice first
        setState(() => _applyingMessage = '오토슬라이스 실행 중...');

        await _runAutoSlice();

        // Re-read sprites after auto-slice
        sprites = ref.read(atlasSpritesProvider);

        if (sprites.isEmpty) {
          // Still no sprites - show error and return
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('스프라이트를 감지하지 못했습니다'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          }
          return;
        }
      }

      // Apply smart packing
      setState(() => _applyingMessage = '스마트 패킹 적용 중...');

      // 패킹 옵션은 atlasSettingsProvider에서 읽기 (프리뷰 패널에서 설정)
      final settings = ref.read(atlasSettingsProvider);

      // SmartMode 활성화 - packingResultProvider가 자동으로 SmartPackingService 사용
      ref.read(isSmartPackingModeProvider.notifier).state = true;

      // 캔버스 크기만 업데이트 (SmartMode에서는 outputScale 불필요)
      ref.read(atlasSettingsProvider.notifier).updateSettings(
        settings.copyWith(
          maxWidth: targetWidth,
          maxHeight: targetHeight,
          fixedSize: true,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isApplying = false;
          _applyingMessage = null;
        });
      }
    }
  }

  /// Run auto-slice with background removal
  Future<void> _runAutoSlice() async {
    final atlasSources = ref.read(atlasSourcesProvider);
    if (atlasSources.isEmpty) return;

    const autoSlicer = AutoSlicerService();
    const bgRemover = BackgroundRemoverService();
    final imageLoader = ImageLoaderService();

    for (final source in atlasSources) {
      final rawImage = source.effectiveRawImage;
      if (rawImage == null) continue;

      // 1. 배경색 자동 감지
      final bgColor = bgRemover.detectBackgroundColor(rawImage);

      // 2. 배경 제거 (배경색이 감지된 경우만)
      img.Image imageToSlice = rawImage;
      if (bgColor != null) {
        final removeResult = await bgRemover.removeBackground(
          image: rawImage,
          config: BackgroundRemoveConfig(
            targetColor: bgColor,
            tolerance: 0,
            contiguousOnly: true,
            featherRadius: 2,
            antialias: true,
          ),
        );
        imageToSlice = removeResult.image;

        // processedImage 업데이트 (배경 제거된 이미지 저장)
        final processedUi = await imageLoader.convertToUiImage(imageToSlice);
        if (processedUi != null) {
          ref.read(multiImageProvider.notifier).updateProcessedImage(
            source.id,
            processedRaw: imageToSlice,
            processedUi: processedUi,
          );
        }
      }

      // 3. 슬라이스 설정
      const config = AutoSliceConfig(
        alphaThreshold: 1,
        minWidth: 1,
        minHeight: 1,
        idPrefix: 'sprite',
        use8Direction: false,
      );

      // 4. 배경 제거된 이미지로 슬라이스
      final result = await autoSlicer.autoSlice(
        image: imageToSlice,
        config: config,
      );

      // 5. 스프라이트 등록
      if (result.sprites.isNotEmpty) {
        await ref.read(multiSpriteProvider.notifier).addFromAutoSlice(
          source.id,
          result,
        );

        ref.read(multiImageProvider.notifier).setSliceMode(
          source.id,
          SpriteSliceMode.region,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSprites = _hasSprites;

    return DraggableDialog(
      width: 360,
      header: _buildHeader(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No sprites info box
                if (!hasSprites) ...[
                  _buildNoSpritesInfo(),
                  const SizedBox(height: 16),
                ],
                // Size inputs
                _buildSizeInputs(),
                const SizedBox(height: 16),
                // Preview info (only if sprites exist)
                // 패킹 옵션은 아틀라스 프리뷰 패널에서 설정
                if (hasSprites) _buildPreviewInfo(),
              ],
            ),
          ),
          // Actions
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_fix_high,
            size: 18,
            color: EditorColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '스마트 패킹',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: EditorColors.iconDefault,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSpritesInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EditorColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: EditorColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '적용 시 오토슬라이스가 먼저 실행됩니다',
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeInputs() {
    return Row(
      children: [
        // Width
        Expanded(
          child: _buildNumberInput(
            label: '너비',
            controller: _widthController,
            focusNode: _widthFocus,
            suffix: 'px',
          ),
        ),
        const SizedBox(width: 12),
        // Lock aspect ratio button
        IconButton(
          icon: Icon(
            _lockAspectRatio ? Icons.link : Icons.link_off,
            size: 18,
            color: _lockAspectRatio
                ? EditorColors.primary
                : EditorColors.iconDisabled,
          ),
          onPressed: () {
            setState(() {
              _lockAspectRatio = !_lockAspectRatio;
              if (_lockAspectRatio) {
                final w = int.tryParse(_widthController.text) ?? _originalWidth;
                final h = int.tryParse(_heightController.text) ?? _originalHeight;
                _aspectRatio = w / h;
              }
            });
          },
          tooltip: '비율 고정',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 12),
        // Height
        Expanded(
          child: _buildNumberInput(
            label: '높이',
            controller: _heightController,
            focusNode: _heightFocus,
            suffix: 'px',
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 4),
        Focus(
          skipTraversal: true,
          onKeyEvent: (node, event) {
            if (focusNode.hasFocus) {
              return KeyEventResult.skipRemainingHandlers;
            }
            return KeyEventResult.ignored;
          },
          child: SizedBox(
            height: 32,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: EditorColors.iconDefault,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  fontSize: 11,
                  color: EditorColors.iconDisabled,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: EditorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: EditorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: EditorColors.primary),
                ),
                filled: true,
                fillColor: EditorColors.inputBackground,
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onSubmitted: (_) {
                if (focusNode == _widthFocus) {
                  _validateAndUpdateWidth();
                } else {
                  _validateAndUpdateHeight();
                }
                if (_hasSprites) _calculatePreview();
              },
            ),
          ),
        ),
      ],
    );
  }

  // 패킹 옵션 UI는 아틀라스 프리뷰 패널에서 관리
  // _buildPaddingSlider(), _buildOptions(), _buildOptionToggle() 제거됨

  Widget _buildPreviewInfo() {
    final efficiencyPercent = (_previewEfficiency * 100).toStringAsFixed(1);
    final scalePercent = (_previewScale * 100).toStringAsFixed(0);

    // Determine efficiency color
    Color efficiencyColor;
    if (_previewEfficiency >= 0.8) {
      efficiencyColor = Colors.green;
    } else if (_previewEfficiency >= 0.6) {
      efficiencyColor = Colors.orange;
    } else {
      efficiencyColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.border),
      ),
      child: _isCalculating
          ? Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EditorColors.primary,
                ),
              ),
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '예상 효율',
                      style: TextStyle(
                        fontSize: 12,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: efficiencyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$efficiencyPercent%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: efficiencyColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '스프라이트 스케일',
                      style: TextStyle(
                        fontSize: 12,
                        color: EditorColors.iconDisabled,
                      ),
                    ),
                    Text(
                      _previewComplete ? '100% (원본)' : '$scalePercent%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _previewComplete
                            ? EditorColors.iconDefault
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (!_previewComplete) ...[
                  const SizedBox(height: 8),
                  Text(
                    '스프라이트가 축소됩니다',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildActions() {
    final hasSprites = _hasSprites;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EditorColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isApplying && _applyingMessage != null) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: EditorColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _applyingMessage!,
              style: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled,
              ),
            ),
            const Spacer(),
          ],
          TextButton(
            onPressed: _isApplying ? null : () {
              // Restore original SmartMode state on cancel
              ref.read(isSmartPackingModeProvider.notifier).state = _originalSmartMode;
              Navigator.of(context).pop();
            },
            child: Text(
              '취소',
              style: TextStyle(
                color: EditorColors.iconDefault,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isApplying ? null : _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: EditorColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              hasSprites ? '적용' : '슬라이스 & 적용',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
