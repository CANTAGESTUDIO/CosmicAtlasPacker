# 🪟 Flutter Desktop Window Management Pattern

> Multi-window management and window control for desktop applications

---

## Overview

Native window management for Flutter desktop apps using window_manager and multi_window packages.

---

## Dependencies

```yaml
dependencies:
  window_manager: ^0.3.8
  desktop_multi_window: ^0.2.0
  screen_retriever: ^0.1.9
```

---

## Implementation

### 1. Window Manager Setup

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}
```

### 2. Window Controller

```dart
// core/window/window_controller.dart
import 'package:window_manager/window_manager.dart';

class WindowController with WindowListener {
  static final WindowController _instance = WindowController._internal();
  factory WindowController() => _instance;
  WindowController._internal();

  bool _isMaximized = false;
  bool _isFullScreen = false;

  Future<void> initialize() async {
    windowManager.addListener(this);
  }

  Future<void> minimize() async {
    await windowManager.minimize();
  }

  Future<void> maximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> close() async {
    await windowManager.close();
  }

  Future<void> toggleFullScreen() async {
    _isFullScreen = !_isFullScreen;
    await windowManager.setFullScreen(_isFullScreen);
  }

  Future<void> setTitle(String title) async {
    await windowManager.setTitle(title);
  }

  Future<void> setSize(Size size) async {
    await windowManager.setSize(size);
  }

  Future<void> center() async {
    await windowManager.center();
  }

  @override
  void onWindowMaximize() {
    _isMaximized = true;
  }

  @override
  void onWindowUnmaximize() {
    _isMaximized = false;
  }

  @override
  void onWindowClose() async {
    // Handle close event (e.g., show confirmation dialog)
    await windowManager.destroy();
  }

  void dispose() {
    windowManager.removeListener(this);
  }
}
```

### 3. Custom Title Bar

```dart
// widgets/custom_title_bar.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: 40,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            if (leading != null) leading!,
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (actions != null) ...actions!,
            _WindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          onPressed: () => windowManager.minimize(),
        ),
        IconButton(
          icon: const Icon(Icons.crop_square, size: 16),
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
```

### 4. Multi-Window Support

```dart
// core/window/multi_window_manager.dart
import 'package:desktop_multi_window/desktop_multi_window.dart';

class MultiWindowManager {
  static Future<WindowController> createWindow({
    required String title,
    required Size size,
    Map<String, dynamic>? arguments,
  }) async {
    final window = await DesktopMultiWindow.createWindow(
      jsonEncode(arguments ?? {}),
    );

    window
      ..setFrame(Offset.zero & size)
      ..center()
      ..setTitle(title)
      ..show();

    return window;
  }

  static void handleSecondaryWindow() {
    // In secondary window main()
    final windowId = int.tryParse(args.firstOrNull ?? '');
    if (windowId != null) {
      runApp(SecondaryWindowApp(windowId: windowId));
    }
  }
}
```

---

## Best Practices

1. **Custom Title Bar**: Use hidden title bar with custom implementation
2. **Window State Persistence**: Save/restore window position and size
3. **Multi-Monitor Support**: Handle window placement across monitors
4. **Graceful Close**: Show confirmation dialog before closing
5. **Window Focus**: Properly handle focus events

---

## Folder Structure

```
lib/
├── core/
│   └── window/
│       ├── window_controller.dart
│       └── multi_window_manager.dart
└── widgets/
    └── custom_title_bar.dart
```

---

*Generated by Archon*