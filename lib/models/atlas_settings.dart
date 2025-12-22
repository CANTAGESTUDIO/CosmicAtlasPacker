import 'package:freezed_annotation/freezed_annotation.dart';

part 'atlas_settings.freezed.dart';
part 'atlas_settings.g.dart';

/// Atlas packing settings
@freezed
class AtlasSettings with _$AtlasSettings {
  const factory AtlasSettings({
    @Default(2048) int maxWidth,
    @Default(2048) int maxHeight,
    @Default(2) int padding,
    @Default(1) int extrude,
    @Default(true) bool trimTransparent,
    @Default(true) bool powerOfTwo,
    @Default(false) bool forceSquare,
  }) = _AtlasSettings;

  factory AtlasSettings.fromJson(Map<String, dynamic> json) =>
      _$AtlasSettingsFromJson(json);
}
