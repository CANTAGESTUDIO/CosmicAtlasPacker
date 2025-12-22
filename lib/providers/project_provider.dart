import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/atlas_project.dart';
import '../services/project_service.dart';

/// Project service provider
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

/// Current project state
final projectProvider = StateNotifierProvider<ProjectNotifier, AtlasProject>((ref) {
  return ProjectNotifier();
});

/// Project dirty state (has unsaved changes)
final projectDirtyProvider = StateProvider<bool>((ref) => false);

/// Last saved path provider
final lastSavedPathProvider = StateProvider<String?>((ref) => null);

/// Project state notifier
class ProjectNotifier extends StateNotifier<AtlasProject> {
  ProjectNotifier() : super(AtlasProject(meta: ProjectMeta.now()));

  /// Update project
  void update(AtlasProject project) {
    state = project;
  }

  /// Create new project
  void newProject() {
    state = AtlasProject(meta: ProjectMeta.now());
  }

  /// Update project name
  void setName(String name) {
    state = state.copyWith(name: name);
  }

  /// Update source files
  void setSourceFiles(List<SourceFile> files) {
    state = state.copyWith(sourceFiles: files);
  }

  /// Add source file
  void addSourceFile(SourceFile file) {
    state = state.copyWith(sourceFiles: [...state.sourceFiles, file]);
  }
}

/// Save project action provider
final saveProjectProvider = FutureProvider.family<ProjectResult<String>, String?>((ref, forcePath) async {
  final service = ref.read(projectServiceProvider);
  final project = ref.read(projectProvider);
  final lastPath = ref.read(lastSavedPathProvider);

  String? savePath = forcePath ?? lastPath;

  // If no path, show save dialog
  if (savePath == null) {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '프로젝트 저장',
      fileName: '${project.name}.${ProjectService.fileExtension}',
      type: FileType.custom,
      allowedExtensions: [ProjectService.fileExtension],
    );

    if (result == null) {
      return const ProjectResult.failure('저장 취소됨');
    }
    savePath = result;
  }

  // Ensure correct extension
  if (!savePath.endsWith('.${ProjectService.fileExtension}')) {
    savePath = '$savePath.${ProjectService.fileExtension}';
  }

  final saveResult = await service.saveProject(project, savePath);

  if (saveResult.success) {
    ref.read(lastSavedPathProvider.notifier).state = savePath;
    ref.read(projectDirtyProvider.notifier).state = false;
  }

  return saveResult;
});

/// Load project action provider
final loadProjectProvider = FutureProvider.autoDispose<ProjectResult<AtlasProject>>((ref) async {
  final service = ref.read(projectServiceProvider);

  // Show file picker dialog
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: '프로젝트 열기',
    type: FileType.custom,
    allowedExtensions: [ProjectService.fileExtension],
    allowMultiple: false,
  );

  if (result == null || result.files.isEmpty) {
    return const ProjectResult.failure('열기 취소됨');
  }

  final filePath = result.files.single.path;
  if (filePath == null) {
    return const ProjectResult.failure('파일 경로를 가져올 수 없습니다');
  }

  final loadResult = await service.loadProject(filePath);

  if (loadResult.success && loadResult.data != null) {
    ref.read(projectProvider.notifier).update(loadResult.data!);
    ref.read(lastSavedPathProvider.notifier).state = filePath;
    ref.read(projectDirtyProvider.notifier).state = false;
  }

  return loadResult;
});
