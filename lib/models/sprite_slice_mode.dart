/// Sprite slice mode - defines the state of sliced sprites
enum SpriteSliceMode {
  /// No slicing performed yet
  none,

  /// Region state - sprites are defined as regions on the source image
  /// The source image remains intact, sprites are just rectangular selections
  region,

  /// Separated state - sprites are extracted as independent images
  /// The source image becomes a background canvas with sprite areas filled
  separated,
}

/// Extension methods for SpriteSliceMode
extension SpriteSliceModeExtension on SpriteSliceMode {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case SpriteSliceMode.none:
        return 'None';
      case SpriteSliceMode.region:
        return 'Region';
      case SpriteSliceMode.separated:
        return 'Separated';
    }
  }

  /// Korean display name for UI
  String get displayNameKo {
    switch (this) {
      case SpriteSliceMode.none:
        return '없음';
      case SpriteSliceMode.region:
        return '영역';
      case SpriteSliceMode.separated:
        return '분리';
    }
  }

  /// Whether sprites can be freely moved
  bool get canMoveSprites => this == SpriteSliceMode.separated;

  /// Whether this is a sliced state (region or separated)
  bool get isSliced => this != SpriteSliceMode.none;
}
