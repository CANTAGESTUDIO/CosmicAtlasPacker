import 'package:freezed_annotation/freezed_annotation.dart';

part 'atlas_settings.freezed.dart';
part 'atlas_settings.g.dart';

/// Atlas packing settings
@freezed
class AtlasSettings with _$AtlasSettings {
  const factory AtlasSettings({
    @Default(2048) int maxWidth,
    @Default(2048) int maxHeight,
    @Default(4) int padding, // 기본값 4
    @Default(1) int extrude,
    @Default(true) bool trimTransparent,
    @Default(true) bool powerOfTwo,
    @Default(false) bool forceSquare,
    @Default(0.0) double edgeCrop, // 가장자리 침식 - Erosion (0.0~64.0, 소수점 지원)
    @Default(false) bool erosionAntiAlias, // 침식 안티앨리어싱
    @Default(false) bool allowRotation, // Rotate 비활성화 기본값
    @Default(false) bool tightPacking, // Tight Packing 비활성화 기본값
  }) = _AtlasSettings;

  factory AtlasSettings.fromJson(Map<String, dynamic> json) =>
      _$AtlasSettingsFromJson(json);
}
