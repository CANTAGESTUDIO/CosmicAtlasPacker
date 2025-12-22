import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/atlas_project.dart';

/// Result of a project operation
class ProjectResult<T> {
  final T? data;
  final String? error;
  final bool success;

  const ProjectResult.success(this.data)
      : error = null,
        success = true;

  const ProjectResult.failure(this.error)
      : data = null,
        success = false;
}

/// Service for saving and loading atlas projects
class ProjectService {
  /// Default file extension for project files
  static const String fileExtension = 'atlas';

  /// Save project to file
  Future<ProjectResult<String>> saveProject(
    AtlasProject project,
    String filePath,
  ) async {
    try {
      // Update metadata
      final now = DateTime.now();
      final updatedProject = project.copyWith(
        meta: project.meta.copyWith(
          createdAt: project.meta.createdAt ?? now,
          modifiedAt: now,
          lastSavedPath: filePath,
        ),
        // Convert sourceImagePath to sourceFiles if needed
        sourceFiles: _ensureSourceFiles(project, filePath),
      );

      // Serialize to JSON
      final json = updatedProject.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(json);

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return ProjectResult.success(filePath);
    } catch (e) {
      return ProjectResult.failure('저장 실패: $e');
    }
  }

  /// Load project from file
  Future<ProjectResult<AtlasProject>> loadProject(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return const ProjectResult.failure('파일을 찾을 수 없습니다');
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Use migration factory for version handling
      final project = AtlasProject.migrate(json);

      // Resolve source file paths relative to project file
      final resolvedProject = _resolveSourcePaths(project, filePath);

      // Validate source files exist
      final validation = await _validateSourceFiles(resolvedProject);
      if (!validation.success) {
        // Return project with warning, don't fail completely
        return ProjectResult.success(resolvedProject);
      }

      return ProjectResult.success(resolvedProject);
    } on FormatException catch (e) {
      return ProjectResult.failure('JSON 파싱 오류: $e');
    } catch (e) {
      return ProjectResult.failure('로드 실패: $e');
    }
  }

  /// Ensure sourceFiles list is populated from sourceImagePath if needed
  List<SourceFile> _ensureSourceFiles(AtlasProject project, String projectPath) {
    if (project.sourceFiles.isNotEmpty) {
      // Update relative paths based on new project location
      return project.sourceFiles.map((sf) {
        final relativePath = _calculateRelativePath(sf.absolutePath, projectPath);
        return sf.copyWith(relativePath: relativePath);
      }).toList();
    }

    // ignore: deprecated_member_use_from_same_package
    final legacyPath = project.sourceImagePath;
    if (legacyPath != null && legacyPath.isNotEmpty) {
      final relativePath = _calculateRelativePath(legacyPath, projectPath);
      return [
        SourceFile(
          absolutePath: legacyPath,
          relativePath: relativePath,
        ),
      ];
    }

    return [];
  }

  /// Calculate relative path from project file to source file
  String? _calculateRelativePath(String sourcePath, String projectPath) {
    try {
      final projectDir = p.dirname(projectPath);
      final relativePath = p.relative(sourcePath, from: projectDir);

      // Only use relative path if it doesn't go too far up
      if (!relativePath.startsWith('..${p.separator}..${p.separator}..')) {
        return relativePath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Resolve relative paths to absolute paths based on project file location
  AtlasProject _resolveSourcePaths(AtlasProject project, String projectPath) {
    if (project.sourceFiles.isEmpty) return project;

    final projectDir = p.dirname(projectPath);
    final resolvedFiles = project.sourceFiles.map((sf) {
      String absolutePath = sf.absolutePath;

      // Try relative path first
      if (sf.relativePath != null) {
        final resolvedPath = p.normalize(p.join(projectDir, sf.relativePath));
        if (File(resolvedPath).existsSync()) {
          absolutePath = resolvedPath;
        }
      }

      // Fallback: check if absolute path exists
      if (!File(absolutePath).existsSync()) {
        // Try relative path even if absolute doesn't exist
        if (sf.relativePath != null) {
          absolutePath = p.normalize(p.join(projectDir, sf.relativePath));
        }
      }

      return sf.copyWith(absolutePath: absolutePath);
    }).toList();

    return project.copyWith(
      sourceFiles: resolvedFiles,
      meta: project.meta.copyWith(lastSavedPath: projectPath),
    );
  }

  /// Validate that source files exist
  Future<ProjectResult<void>> _validateSourceFiles(AtlasProject project) async {
    final missingFiles = <String>[];

    for (final sf in project.sourceFiles) {
      if (!File(sf.absolutePath).existsSync()) {
        missingFiles.add(sf.fileName);
      }
    }

    if (missingFiles.isNotEmpty) {
      return ProjectResult.failure(
        '다음 소스 파일을 찾을 수 없습니다: ${missingFiles.join(', ')}',
      );
    }

    return const ProjectResult.success(null);
  }

  /// Check if a file path has valid project extension
  bool isValidProjectFile(String path) {
    return p.extension(path).toLowerCase() == '.$fileExtension';
  }

  /// Get missing source files from project
  List<SourceFile> getMissingSourceFiles(AtlasProject project) {
    return project.sourceFiles
        .where((sf) => !File(sf.absolutePath).existsSync())
        .toList();
  }
}
