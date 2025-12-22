# 🔄 Flutter Desktop State Management Pattern

> Riverpod-based state management optimized for desktop applications

---

## Overview

State management pattern using Riverpod with desktop-specific considerations like window state, file state, and undo/redo.

---

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.8
```

---

## Implementation

### 1. Application State

```dart
// core/state/app_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_state.g.dart';
part 'app_state.freezed.dart';

@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default(false) bool isSidebarVisible,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default([]) List<String> recentFiles,
    WindowState? windowState,
  }) = _AppState;
}

@freezed
class WindowState with _$WindowState {
  const factory WindowState({
    required double width,
    required double height,
    required double x,
    required double y,
    @Default(false) bool isMaximized,
    @Default(false) bool isFullScreen,
  }) = _WindowState;

  factory WindowState.fromJson(Map<String, dynamic> json) =>
      _$WindowStateFromJson(json);
}

@riverpod
class AppStateNotifier extends _$AppStateNotifier {
  @override
  AppState build() => const AppState();

  void toggleSidebar() {
    state = state.copyWith(isSidebarVisible: !state.isSidebarVisible);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void addRecentFile(String path) {
    final recent = [...state.recentFiles];
    recent.remove(path);
    recent.insert(0, path);
    if (recent.length > 10) {
      recent.removeLast();
    }
    state = state.copyWith(recentFiles: recent);
  }

  void updateWindowState(WindowState windowState) {
    state = state.copyWith(windowState: windowState);
  }
}
```

### 2. Document State with Undo/Redo

```dart
// features/document/state/document_state.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'document_state.g.dart';

@freezed
class DocumentState with _$DocumentState {
  const factory DocumentState({
    String? filePath,
    @Default('') String content,
    @Default(false) bool isDirty,
    @Default([]) List<String> undoStack,
    @Default([]) List<String> redoStack,
  }) = _DocumentState;
}

@riverpod
class DocumentNotifier extends _$DocumentNotifier {
  static const int maxUndoStackSize = 100;

  @override
  DocumentState build() => const DocumentState();

  void updateContent(String newContent) {
    if (newContent == state.content) return;

    final undoStack = [...state.undoStack, state.content];
    if (undoStack.length > maxUndoStackSize) {
      undoStack.removeAt(0);
    }

    state = state.copyWith(
      content: newContent,
      isDirty: true,
      undoStack: undoStack,
      redoStack: [],
    );
  }

  void undo() {
    if (state.undoStack.isEmpty) return;

    final undoStack = [...state.undoStack];
    final previousContent = undoStack.removeLast();
    final redoStack = [...state.redoStack, state.content];

    state = state.copyWith(
      content: previousContent,
      undoStack: undoStack,
      redoStack: redoStack,
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final redoStack = [...state.redoStack];
    final nextContent = redoStack.removeLast();
    final undoStack = [...state.undoStack, state.content];

    state = state.copyWith(
      content: nextContent,
      undoStack: undoStack,
      redoStack: redoStack,
    );
  }

  bool get canUndo => state.undoStack.isNotEmpty;
  bool get canRedo => state.redoStack.isNotEmpty;

  Future<void> openFile(String path) async {
    final file = File(path);
    final content = await file.readAsString();

    state = DocumentState(
      filePath: path,
      content: content,
      isDirty: false,
    );
  }

  Future<void> save() async {
    if (state.filePath == null) return;

    final file = File(state.filePath!);
    await file.writeAsString(state.content);

    state = state.copyWith(isDirty: false);
  }

  Future<void> saveAs(String path) async {
    final file = File(path);
    await file.writeAsString(state.content);

    state = state.copyWith(
      filePath: path,
      isDirty: false,
    );
  }
}
```

### 3. Selection State

```dart
// core/state/selection_state.dart
@riverpod
class SelectionNotifier extends _$SelectionNotifier {
  @override
  Set<String> build() => {};

  void select(String id) {
    state = {...state, id};
  }

  void deselect(String id) {
    state = {...state}..remove(id);
  }

  void toggle(String id) {
    if (state.contains(id)) {
      deselect(id);
    } else {
      select(id);
    }
  }

  void selectAll(Iterable<String> ids) {
    state = {...ids};
  }

  void clear() {
    state = {};
  }

  bool isSelected(String id) => state.contains(id);
}
```

---

## Best Practices

1. **Undo/Redo Stack**: Limit stack size to prevent memory issues
2. **Dirty State**: Track unsaved changes
3. **State Persistence**: Save/restore state on app lifecycle
4. **Derived State**: Use computed providers for derived data
5. **Scoped Providers**: Use family providers for document instances

---

*Generated by Archon*