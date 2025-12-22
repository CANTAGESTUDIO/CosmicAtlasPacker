# ⌨️ Flutter Desktop Keyboard Shortcuts Pattern

> Global and local keyboard shortcut management

---

## Overview

Comprehensive keyboard shortcut system for desktop applications using Flutter's built-in shortcuts system.

---

## Dependencies

```yaml
dependencies:
  # For global hotkeys
  hotkey_manager: ^0.2.0
```

---

## Implementation

### 1. Shortcuts Configuration

```dart
// core/shortcuts/app_shortcuts.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcuts {
  // Define all app shortcuts as static constants
  static const newFile = SingleActivator(
    LogicalKeyboardKey.keyN,
    meta: true,
  );

  static const openFile = SingleActivator(
    LogicalKeyboardKey.keyO,
    meta: true,
  );

  static const save = SingleActivator(
    LogicalKeyboardKey.keyS,
    meta: true,
  );

  static const saveAs = SingleActivator(
    LogicalKeyboardKey.keyS,
    meta: true,
    shift: true,
  );

  static const undo = SingleActivator(
    LogicalKeyboardKey.keyZ,
    meta: true,
  );

  static const redo = SingleActivator(
    LogicalKeyboardKey.keyZ,
    meta: true,
    shift: true,
  );

  static const find = SingleActivator(
    LogicalKeyboardKey.keyF,
    meta: true,
  );

  static const replace = SingleActivator(
    LogicalKeyboardKey.keyH,
    meta: true,
  );

  static const preferences = SingleActivator(
    LogicalKeyboardKey.comma,
    meta: true,
  );

  static const quit = SingleActivator(
    LogicalKeyboardKey.keyQ,
    meta: true,
  );
}
```

### 2. Shortcuts Widget Wrapper

```dart
// core/shortcuts/app_shortcuts_wrapper.dart
import 'package:flutter/material.dart';

class AppShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const AppShortcutsWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        AppShortcuts.newFile: const NewFileIntent(),
        AppShortcuts.openFile: const OpenFileIntent(),
        AppShortcuts.save: const SaveIntent(),
        AppShortcuts.saveAs: const SaveAsIntent(),
        AppShortcuts.undo: const UndoIntent(),
        AppShortcuts.redo: const RedoIntent(),
        AppShortcuts.find: const FindIntent(),
        AppShortcuts.replace: const ReplaceIntent(),
        AppShortcuts.preferences: const PreferencesIntent(),
        AppShortcuts.quit: const QuitIntent(),
      },
      child: Actions(
        actions: {
          NewFileIntent: NewFileAction(),
          OpenFileIntent: OpenFileAction(),
          SaveIntent: SaveAction(),
          SaveAsIntent: SaveAsAction(),
          UndoIntent: UndoAction(),
          RedoIntent: RedoAction(),
          FindIntent: FindAction(),
          ReplaceIntent: ReplaceAction(),
          PreferencesIntent: PreferencesAction(),
          QuitIntent: QuitAction(),
        },
        child: child,
      ),
    );
  }
}
```

### 3. Intent and Action Definitions

```dart
// core/shortcuts/intents.dart
import 'package:flutter/material.dart';

class NewFileIntent extends Intent {
  const NewFileIntent();
}

class OpenFileIntent extends Intent {
  const OpenFileIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class FindIntent extends Intent {
  const FindIntent();
}

class ReplaceIntent extends Intent {
  const ReplaceIntent();
}

class PreferencesIntent extends Intent {
  const PreferencesIntent();
}

class QuitIntent extends Intent {
  const QuitIntent();
}
```

```dart
// core/shortcuts/actions.dart
import 'package:flutter/material.dart';

class NewFileAction extends Action<NewFileIntent> {
  @override
  Object? invoke(NewFileIntent intent) {
    // Handle new file
    return null;
  }
}

class OpenFileAction extends Action<OpenFileIntent> {
  @override
  Object? invoke(OpenFileIntent intent) {
    // Handle open file
    return null;
  }
}

class SaveAction extends Action<SaveIntent> {
  @override
  Object? invoke(SaveIntent intent) {
    // Handle save
    return null;
  }
}

// ... other actions
```

### 4. Global Hotkeys

```dart
// core/shortcuts/global_hotkey_manager.dart
import 'package:hotkey_manager/hotkey_manager.dart';

class GlobalHotkeyManager {
  static final GlobalHotkeyManager _instance = GlobalHotkeyManager._internal();
  factory GlobalHotkeyManager() => _instance;
  GlobalHotkeyManager._internal();

  Future<void> register() async {
    // Register global hotkey (works even when app is not focused)
    await hotKeyManager.register(
      HotKey(
        KeyCode.space,
        modifiers: [KeyModifier.control, KeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (hotKey) {
        // Show quick access panel
        _showQuickAccessPanel();
      },
    );
  }

  void _showQuickAccessPanel() {
    // Show quick access UI
  }

  Future<void> unregisterAll() async {
    await hotKeyManager.unregisterAll();
  }
}
```

---

## Best Practices

1. **Platform Conventions**: Use Cmd on macOS, Ctrl on Windows/Linux
2. **Discoverable**: Show shortcuts in menus and tooltips
3. **Configurable**: Allow users to customize shortcuts
4. **Conflict Detection**: Check for shortcut conflicts
5. **Focus Context**: Use appropriate shortcuts based on focus

---

*Generated by Archon*