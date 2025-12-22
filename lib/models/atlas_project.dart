import 'package:freezed_annotation/freezed_annotation.dart';

import 'animation_sequence.dart';
import 'atlas_settings.dart';
import 'sprite_data.dart';

part 'atlas_project.freezed.dart';
part 'atlas_project.g.dart';

/// Current project file format version
const int kProjectVersion = 2;

/// Complete atlas project data
@freezed
class AtlasProject with _$AtlasProject {
  const AtlasProject._();

  const factory AtlasProject({
    /// Project file format version (for migration)
    @Default(kProjectVersion) int version,

    /// Project name
    @Default('Untitled') String name,

    /// Source image file paths (supports multiple sources)
    @Default([]) List<SourceFile> sourceFiles,

    /// Legacy: Single source image file path (kept for backward compatibility)
    @Deprecated('Use sourceFiles instead')
    String? sourceImagePath,

    /// List of sprites extracted from source
    @Default([]) List<SpriteData> sprites,

    /// List of animation sequences
    @Default([]) List<AnimationSequence> animations,

    /// Atlas packing settings
    @Default(AtlasSettings()) AtlasSettings settings,

    /// Calculated atlas width (after packing)
    int? atlasWidth,

    /// Calculated atlas height (after packing)
    int? atlasHeight,

    /// Project metadata
    @Default(ProjectMeta()) ProjectMeta meta,
  }) = _AtlasProject;

  factory AtlasProject.fromJson(Map<String, dynamic> json) =>
      _$AtlasProjectFromJson(json);

  /// Migrate from old version to current version
  factory AtlasProject.migrate(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 0;

    // Version 0 -> 1: Convert sourceImagePath to sourceFiles
    if (version < 1) {
      final sourceImagePath = json['sourceImagePath'] as String?;
      if (sourceImagePath != null && sourceImagePath.isNotEmpty) {
        json['sourceFiles'] = [
          {
            'absolutePath': sourceImagePath,
            'relativePath': null,
          }
        ];
      }
      json['version'] = 1;
    }

    // Version 1 -> 2: Add animations field (already defaults to empty list)
    if (version < 2) {
      json['animations'] ??= [];
      json['version'] = 2;
    }

    return AtlasProject.fromJson(json);
  }

  /// Check if a sprite ID already exists
  bool hasId(String id) => sprites.any((s) => s.id == id);

  /// Get sprite by ID
  SpriteData? getSpriteById(String id) {
    try {
      return sprites.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Generate unique sprite ID
  String generateUniqueId() {
    int counter = sprites.length;
    String id;
    do {
      id = 'sprite_$counter';
      counter++;
    } while (hasId(id));
    return id;
  }

  /// Get the primary source file path (first source or legacy path)
  String? get primarySourcePath {
    if (sourceFiles.isNotEmpty) {
      return sourceFiles.first.resolvedPath;
    }
    // ignore: deprecated_member_use_from_same_package
    return sourceImagePath;
  }
}

/// Source file information with relative/absolute path support
@freezed
class SourceFile with _$SourceFile {
  const SourceFile._();

  const factory SourceFile({
    /// Absolute file path
    required String absolutePath,

    /// Relative path from project file (for portability)
    String? relativePath,
  }) = _SourceFile;

  factory SourceFile.fromJson(Map<String, dynamic> json) =>
      _$SourceFileFromJson(json);

  /// Get the best available path (relative preferred, fallback to absolute)
  String get resolvedPath => relativePath ?? absolutePath;

  /// Get just the filename
  String get fileName {
    final path = absolutePath;
    final lastSep = path.lastIndexOf('/');
    if (lastSep == -1) {
      final lastBackSep = path.lastIndexOf('\\');
      return lastBackSep == -1 ? path : path.substring(lastBackSep + 1);
    }
    return path.substring(lastSep + 1);
  }
}

/// Project metadata
@freezed
class ProjectMeta with _$ProjectMeta {
  const factory ProjectMeta({
    /// Project creation timestamp
    DateTime? createdAt,

    /// Last modification timestamp
    DateTime? modifiedAt,

    /// Last saved file path
    String? lastSavedPath,
  }) = _ProjectMeta;

  factory ProjectMeta.fromJson(Map<String, dynamic> json) =>
      _$ProjectMetaFromJson(json);

  /// Create meta with current timestamp
  factory ProjectMeta.now() => ProjectMeta(
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
}
