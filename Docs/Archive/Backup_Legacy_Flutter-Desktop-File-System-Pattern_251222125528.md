# 📁 Flutter Desktop File System Pattern

> File operations, dialogs, and drag-and-drop

---

## Overview

File system operations for desktop apps including file dialogs, drag-and-drop, and file watching.

---

## Dependencies

```yaml
dependencies:
  file_picker: ^6.1.1
  path_provider: ^2.1.2
  path: ^1.8.3
  cross_file: ^0.0.1
  desktop_drop: ^0.4.4
  watcher: ^1.1.0
```

---

## Implementation

### 1. File Dialog Service

```dart
// core/file/file_dialog_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class FileDialogService {
  /// Pick single file
  static Future<File?> pickFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle ?? 'Select File',
      type: allowedExtensions != null
          ? FileType.custom
          : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.isNotEmpty) {
      return File(result.files.first.path!);
    }
    return null;
  }

  /// Pick multiple files
  static Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle ?? 'Select Files',
      allowMultiple: true,
      type: allowedExtensions != null
          ? FileType.custom
          : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      return result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
    }
    return [];
  }

  /// Pick directory
  static Future<Directory?> pickDirectory({
    String? dialogTitle,
  }) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'Select Folder',
    );

    if (result != null) {
      return Directory(result);
    }
    return null;
  }

  /// Save file dialog
  static Future<File?> saveFile({
    required String fileName,
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle ?? 'Save File',
      fileName: fileName,
      type: allowedExtensions != null
          ? FileType.custom
          : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      return File(result);
    }
    return null;
  }
}
```

### 2. Drag and Drop

```dart
// widgets/drop_zone.dart
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';

class DropZone extends StatefulWidget {
  final Widget child;
  final void Function(List<XFile> files) onFilesDropped;
  final List<String>? allowedExtensions;

  const DropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.allowedExtensions,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) {
        setState(() => _isDragging = false);

        final files = details.files.where((file) {
          if (widget.allowedExtensions == null) return true;
          final ext = path.extension(file.path).toLowerCase();
          return widget.allowedExtensions!.contains(ext);
        }).toList();

        if (files.isNotEmpty) {
          widget.onFilesDropped(files);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: widget.child,
      ),
    );
  }
}
```

### 3. File Watcher

```dart
// core/file/file_watcher_service.dart
import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';

class FileWatcherService {
  final Map<String, StreamSubscription> _watchers = {};

  void watchDirectory(
    String path, {
    required void Function(WatchEvent event) onEvent,
  }) {
    if (_watchers.containsKey(path)) {
      _watchers[path]?.cancel();
    }

    final watcher = DirectoryWatcher(path);
    _watchers[path] = watcher.events.listen(onEvent);
  }

  void watchFile(
    String path, {
    required void Function(WatchEvent event) onEvent,
  }) {
    if (_watchers.containsKey(path)) {
      _watchers[path]?.cancel();
    }

    final watcher = FileWatcher(path);
    _watchers[path] = watcher.events.listen(onEvent);
  }

  void stopWatching(String path) {
    _watchers[path]?.cancel();
    _watchers.remove(path);
  }

  void dispose() {
    for (final subscription in _watchers.values) {
      subscription.cancel();
    }
    _watchers.clear();
  }
}
```

---

## Best Practices

1. **Error Handling**: Handle file access permissions
2. **Progress Indication**: Show progress for large file operations
3. **Recent Files**: Track and display recent files
4. **Auto-save**: Implement periodic auto-save
5. **File Validation**: Validate file types and content

---

*Generated by Archon*