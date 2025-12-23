/// Editor mode - determines the main workspace layout
enum EditorMode {
  /// Texture Packer mode - slice sprites and pack into atlas
  texturePacker,

  /// Animation mode - create and edit sprite animations
  animation;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case EditorMode.texturePacker:
        return '텍스처 패커';
      case EditorMode.animation:
        return '애니메이션';
    }
  }

  /// Get tooltip text
  String get tooltip {
    switch (this) {
      case EditorMode.texturePacker:
        return '스프라이트 슬라이싱 및 아틀라스 패킹';
      case EditorMode.animation:
        return '스프라이트 애니메이션 편집';
    }
  }
}
