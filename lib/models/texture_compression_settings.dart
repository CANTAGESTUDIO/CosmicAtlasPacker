import 'package:freezed_annotation/freezed_annotation.dart';

part 'texture_compression_settings.freezed.dart';
part 'texture_compression_settings.g.dart';

/// 텍스처 압축 포맷
/// Android: ETC2, ASTC 지원
/// iOS: ASTC 지원
@JsonEnum(valueField: 'value')
enum TextureCompressionFormat {
  // ETC2 (품질 낮은 순)
  etc2_4bit('ETC2 4-bit', 'etc2_4bit', true, false),
  etc2_8bit('ETC2 8-bit', 'etc2_8bit', true, false),
  // ASTC (품질 낮은 순)
  astc12x12('ASTC 12x12', 'astc_12x12', true, true),
  astc10x10('ASTC 10x10', 'astc_10x10', true, true),
  astc8x8('ASTC 8x8', 'astc_8x8', true, true),
  astc6x6('ASTC 6x6', 'astc_6x6', true, true),
  astc4x4('ASTC 4x4', 'astc_4x4', true, true);

  const TextureCompressionFormat(
    this.displayName,
    this.value,
    this.supportsAndroid,
    this.supportsIOS,
  );

  /// 사용자에게 표시되는 이름
  final String displayName;

  /// JSON 직렬화 값
  final String value;

  /// Android 지원 여부
  final bool supportsAndroid;

  /// iOS 지원 여부
  final bool supportsIOS;

  /// Android 지원 포맷 목록
  static List<TextureCompressionFormat> get androidFormats =>
      values.where((f) => f.supportsAndroid).toList();

  /// iOS 지원 포맷 목록
  static List<TextureCompressionFormat> get iosFormats =>
      values.where((f) => f.supportsIOS).toList();

  /// 압축률 설명 (낮을수록 파일 작음)
  String get compressionDescription {
    switch (this) {
      case TextureCompressionFormat.etc2_4bit:
        return '높은 압축률, 알파 제한';
      case TextureCompressionFormat.etc2_8bit:
        return '중간 압축률, 알파 지원';
      case TextureCompressionFormat.astc4x4:
        return '최고 품질, 낮은 압축률';
      case TextureCompressionFormat.astc6x6:
        return '높은 품질, 중간 압축률';
      case TextureCompressionFormat.astc8x8:
        return '중간 품질, 높은 압축률';
      case TextureCompressionFormat.astc10x10:
        return '낮은 품질, 매우 높은 압축률';
      case TextureCompressionFormat.astc12x12:
        return '최저 품질, 최고 압축률';
    }
  }

  /// 블록당 비트 수 (압축률 계산용)
  double get bitsPerPixel {
    switch (this) {
      case TextureCompressionFormat.etc2_4bit:
        return 4.0;
      case TextureCompressionFormat.etc2_8bit:
        return 8.0;
      case TextureCompressionFormat.astc4x4:
        return 8.0;
      case TextureCompressionFormat.astc6x6:
        return 3.56;
      case TextureCompressionFormat.astc8x8:
        return 2.0;
      case TextureCompressionFormat.astc10x10:
        return 1.28;
      case TextureCompressionFormat.astc12x12:
        return 0.89;
    }
  }

  /// 지원 플랫폼 문자열
  String get platformSupport {
    if (supportsAndroid && supportsIOS) {
      return 'Android / iOS';
    } else if (supportsAndroid) {
      return 'Android (OpenGL ES 3.0+)';
    } else {
      return 'iOS';
    }
  }

  /// 상세 설명 (helperText용)
  String get detailedDescription {
    switch (this) {
      case TextureCompressionFormat.etc2_4bit:
        return '${bitsPerPixel} bpp · $platformSupport\nRGB 전용, 알파 없음. 블러링/색 이동(흐려짐) 아티팩트 발생 가능';
      case TextureCompressionFormat.etc2_8bit:
        return '${bitsPerPixel} bpp · $platformSupport\nRGBA 지원. 블러링/색 이동(흐려짐) 아티팩트 발생 가능';
      case TextureCompressionFormat.astc4x4:
        return '${bitsPerPixel} bpp · $platformSupport\n최고 품질, UI/텍스트에 권장';
      case TextureCompressionFormat.astc6x6:
        return '${bitsPerPixel} bpp · $platformSupport\n품질/용량 균형, 범용 권장';
      case TextureCompressionFormat.astc8x8:
        return '${bitsPerPixel} bpp · $platformSupport\n높은 압축, 배경/환경에 적합';
      case TextureCompressionFormat.astc10x10:
        return '${bitsPerPixel} bpp · $platformSupport\n매우 높은 압축, 대형 텍스처용';
      case TextureCompressionFormat.astc12x12:
        return '${bitsPerPixel} bpp · $platformSupport\n최대 압축, 품질 손실 있음';
    }
  }

  /// 출력 파일 확장자 (ETC2: .ktx, ASTC: .astc)
  String get fileExtension {
    switch (this) {
      case TextureCompressionFormat.etc2_4bit:
      case TextureCompressionFormat.etc2_8bit:
        return 'ktx';
      case TextureCompressionFormat.astc4x4:
      case TextureCompressionFormat.astc6x6:
      case TextureCompressionFormat.astc8x8:
      case TextureCompressionFormat.astc10x10:
      case TextureCompressionFormat.astc12x12:
        return 'astc';
    }
  }

  /// ETC2 포맷 여부
  bool get isETC2 => this == etc2_4bit || this == etc2_8bit;

  /// ASTC 포맷 여부
  bool get isASTC => !isETC2;
}

/// ASTC 블록 크기 옵션
@JsonEnum(valueField: 'value')
enum ASTCBlockSize {
  block4x4('4x4', 'astc_4x4', 8.0),
  block6x6('6x6', 'astc_6x6', 3.56),
  block8x8('8x8', 'astc_8x8', 2.0),
  block10x10('10x10', 'astc_10x10', 1.28),
  block12x12('12x12', 'astc_12x12', 0.89);

  const ASTCBlockSize(this.displayName, this.value, this.bitsPerPixel);

  /// 표시 이름
  final String displayName;

  /// JSON 직렬화 값
  final String value;

  /// 블록당 비트 수
  final double bitsPerPixel;

  /// 품질 수준 (1~5, 5가 최고)
  int get qualityLevel {
    switch (this) {
      case ASTCBlockSize.block4x4:
        return 5;
      case ASTCBlockSize.block6x6:
        return 4;
      case ASTCBlockSize.block8x8:
        return 3;
      case ASTCBlockSize.block10x10:
        return 2;
      case ASTCBlockSize.block12x12:
        return 1;
    }
  }

  /// 압축 효율성 설명
  String get efficiencyDescription {
    switch (this) {
      case ASTCBlockSize.block4x4:
        return '최고 품질 - 낮은 압축률';
      case ASTCBlockSize.block6x6:
        return '권장 - 품질/크기 균형';
      case ASTCBlockSize.block8x8:
        return '높은 압축 - 적당한 품질';
      case ASTCBlockSize.block10x10:
        return '매우 높은 압축';
      case ASTCBlockSize.block12x12:
        return '최대 압축 - 낮은 품질';
    }
  }
}

/// 게임 타입 (프리셋용)
@JsonEnum(valueField: 'value')
enum GameType {
  casual2D('2D 캐주얼', 'casual_2d'),
  action2D('2D 액션', 'action_2d'),
  rpg3D('3D RPG', 'rpg_3d'),
  highEnd3D('하이엔드 3D', 'high_end_3d');

  const GameType(this.displayName, this.value);

  /// 표시 이름
  final String displayName;

  /// JSON 직렬화 값
  final String value;

  /// 게임 타입 설명
  String get description {
    switch (this) {
      case GameType.casual2D:
        return '퍼즐, 매치3, 캐주얼 게임에 적합';
      case GameType.action2D:
        return '플랫포머, 슈팅, 격투 게임에 적합';
      case GameType.rpg3D:
        return '3D RPG, 어드벤처 게임에 적합';
      case GameType.highEnd3D:
        return 'AAA급 고품질 3D 게임에 적합';
    }
  }

  /// 기본 Android 포맷
  TextureCompressionFormat get defaultAndroidFormat {
    switch (this) {
      case GameType.casual2D:
        return TextureCompressionFormat.etc2_8bit;
      case GameType.action2D:
        return TextureCompressionFormat.astc6x6;
      case GameType.rpg3D:
        return TextureCompressionFormat.astc6x6;
      case GameType.highEnd3D:
        return TextureCompressionFormat.astc4x4;
    }
  }

  /// 기본 iOS 포맷
  TextureCompressionFormat get defaultIOSFormat {
    switch (this) {
      case GameType.casual2D:
        return TextureCompressionFormat.astc6x6;
      case GameType.action2D:
        return TextureCompressionFormat.astc6x6;
      case GameType.rpg3D:
        return TextureCompressionFormat.astc6x6;
      case GameType.highEnd3D:
        return TextureCompressionFormat.astc4x4;
    }
  }

  /// 기본 ASTC 블록 크기
  ASTCBlockSize get defaultASTCBlockSize {
    switch (this) {
      case GameType.casual2D:
        return ASTCBlockSize.block6x6;
      case GameType.action2D:
        return ASTCBlockSize.block6x6;
      case GameType.rpg3D:
        return ASTCBlockSize.block6x6;
      case GameType.highEnd3D:
        return ASTCBlockSize.block4x4;
    }
  }

  /// 권장 메모리 예산 (MB)
  int get recommendedMemoryBudgetMB {
    switch (this) {
      case GameType.casual2D:
        return 50;
      case GameType.action2D:
        return 100;
      case GameType.rpg3D:
        return 200;
      case GameType.highEnd3D:
        return 400;
    }
  }
}

/// 내보내기 타입
@JsonEnum(valueField: 'value')
enum ExportType {
  sprite('스프라이트', 'sprite'),
  font('스프라이트 폰트', 'font');

  const ExportType(this.displayName, this.value);

  /// 표시 이름
  final String displayName;

  /// JSON 직렬화 값
  final String value;

  /// 설명
  String get description {
    switch (this) {
      case ExportType.sprite:
        return 'Flame SpriteComponent 호환 아틀라스';
      case ExportType.font:
        return 'Flame SpriteFont (PNG + FNT)';
    }
  }
}

/// 이미지 출력 포맷 (PNG, JPEG)
/// Note: WebP encoding is not supported by the image package (decode only)
@JsonEnum(valueField: 'value')
enum ImageOutputFormat {
  png('PNG', 'png', false),
  jpeg('JPEG', 'jpeg', true);

  const ImageOutputFormat(this.displayName, this.value, this.supportsQuality);

  /// 표시 이름
  final String displayName;

  /// JSON 직렬화 값 / 파일 확장자
  final String value;

  /// 품질 파라미터 지원 여부 (PNG는 무손실)
  final bool supportsQuality;

  /// 파일 확장자
  String get extension => value == 'jpeg' ? 'jpg' : value;

  /// 포맷 설명
  String get description {
    switch (this) {
      case ImageOutputFormat.png:
        return '무손실, 투명 지원';
      case ImageOutputFormat.jpeg:
        return '고압축, 투명 미지원';
    }
  }

  /// 압축률 추정 (PNG 대비)
  double get compressionRatio {
    switch (this) {
      case ImageOutputFormat.png:
        return 1.0;
      case ImageOutputFormat.jpeg:
        return 0.25; // PNG 대비 약 25% 크기
    }
  }

  /// 알파 채널 지원 여부
  bool get supportsAlpha {
    switch (this) {
      case ImageOutputFormat.png:
        return true;
      case ImageOutputFormat.jpeg:
        return false;
    }
  }

  /// 기본 품질 값 (1-100, PNG는 압축 레벨)
  int get defaultQuality {
    switch (this) {
      case ImageOutputFormat.png:
        return 6; // 압축 레벨 0-9
      case ImageOutputFormat.jpeg:
        return 85;
    }
  }

  /// 품질 라벨
  String get qualityLabel {
    switch (this) {
      case ImageOutputFormat.png:
        return '압축 레벨';
      case ImageOutputFormat.jpeg:
        return '품질';
    }
  }

  /// 품질 범위
  (int min, int max) get qualityRange {
    switch (this) {
      case ImageOutputFormat.png:
        return (0, 9);
      case ImageOutputFormat.jpeg:
        return (1, 100);
    }
  }
}

/// 텍스처 압축 설정 모델
@freezed
class TextureCompressionSettings with _$TextureCompressionSettings {
  const TextureCompressionSettings._();

  const factory TextureCompressionSettings({
    /// Android 압축 포맷
    @Default(TextureCompressionFormat.etc2_8bit)
    TextureCompressionFormat androidFormat,

    /// iOS 압축 포맷
    @Default(TextureCompressionFormat.astc6x6)
    TextureCompressionFormat iosFormat,

    /// ASTC 블록 크기 (ASTC 포맷 선택 시 적용)
    @Default(ASTCBlockSize.block6x6) ASTCBlockSize astcBlockSize,

    /// 게임 타입 (프리셋)
    @Default(GameType.casual2D) GameType gameType,

    /// 내보내기 타입 (스프라이트/폰트)
    @Default(ExportType.sprite) ExportType exportType,

    /// 폴백 포맷 (호환성 문제 시 사용)
    TextureCompressionFormat? fallbackFormat,

    /// 커스텀 프리셋 여부 (프리셋에서 변경됨)
    @Default(false) bool customPreset,

    /// 온보딩 완료 여부
    @Default(false) bool onboardingCompleted,

    /// 온보딩 현재 단계 (1~6)
    @Default(1) int onboardingStep,

    /// 타겟 Android API 레벨
    @Default(21) int targetAndroidApiLevel,

    /// 타겟 iOS 버전
    @Default(12) int targetIOSVersion,

    /// 타겟 기기 최소 RAM (GB)
    @Default(2) int targetMinRamGB,

    /// 전체 메모리 예산 (MB)
    @Default(100) int memoryBudgetMB,

    /// 텍스처 할당 비율 (10~80%)
    @Default(50) int textureAllocationPercent,
  }) = _TextureCompressionSettings;

  factory TextureCompressionSettings.fromJson(Map<String, dynamic> json) =>
      _$TextureCompressionSettingsFromJson(json);

  /// 기본 설정 팩토리
  factory TextureCompressionSettings.defaultSettings() =>
      const TextureCompressionSettings();

  /// 게임 타입 프리셋 적용
  factory TextureCompressionSettings.fromGameType(GameType gameType) {
    return TextureCompressionSettings(
      gameType: gameType,
      androidFormat: gameType.defaultAndroidFormat,
      iosFormat: gameType.defaultIOSFormat,
      astcBlockSize: gameType.defaultASTCBlockSize,
      memoryBudgetMB: gameType.recommendedMemoryBudgetMB,
      customPreset: false,
    );
  }

  /// 텍스처 메모리 예산 (MB)
  int get textureMemoryBudgetMB =>
      (memoryBudgetMB * textureAllocationPercent / 100).round();

  /// Android 포맷 호환성 체크
  bool get isAndroidFormatCompatible {
    // ETC2는 OpenGL ES 3.0 이상 필요 (API 18+)
    if (androidFormat == TextureCompressionFormat.etc2_4bit ||
        androidFormat == TextureCompressionFormat.etc2_8bit) {
      return targetAndroidApiLevel >= 18;
    }
    // ASTC는 더 높은 API 레벨 권장 (API 21+)
    return targetAndroidApiLevel >= 21;
  }

  /// iOS 포맷 호환성 체크
  bool get isIOSFormatCompatible {
    // ASTC는 iOS 8+ (A8 칩)부터 지원
    return targetIOSVersion >= 8;
  }

  /// 예상 빌드 크기 계산 (1024x1024 기준, KB)
  double calculateEstimatedSize(int width, int height) {
    // Android 기준 계산
    final androidBpp = androidFormat.bitsPerPixel;
    final iosBpp = iosFormat.bitsPerPixel;
    final avgBpp = (androidBpp + iosBpp) / 2;

    final pixels = width * height;
    final bits = pixels * avgBpp;
    final bytes = bits / 8;
    return bytes / 1024; // KB
  }

  /// 설정 유효성 검사
  String? validate() {
    if (!isAndroidFormatCompatible) {
      return 'Android API ${targetAndroidApiLevel}에서 ${androidFormat.displayName} 포맷이 지원되지 않을 수 있습니다.';
    }
    if (!isIOSFormatCompatible) {
      return 'iOS ${targetIOSVersion}에서 ${iosFormat.displayName} 포맷이 지원되지 않을 수 있습니다.';
    }
    if (memoryBudgetMB < 10) {
      return '메모리 예산이 너무 작습니다. 최소 10MB 이상 권장합니다.';
    }
    return null;
  }
}
