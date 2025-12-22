# 📋 Flutter Desktop Menu Bar Pattern

> Native menu bar integration for macOS, Windows, and Linux

---

## Overview

Platform-native menu bar implementation using the native_menu_bar and menubar packages.

---

## Dependencies

```yaml
dependencies:
  # For macOS native menu
  macos_ui: ^2.0.6
  # Cross-platform menu
  menu_bar: ^0.5.3
```

---

## Implementation

### 1. Menu Bar Configuration

```dart
// core/menu/app_menu_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppMenuBar {
  static void setupMenuBar(BuildContext context) {
    // Using PlatformMenuBar for native menu on macOS
    PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'New',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                meta: true,
              ),
              onSelected: () => _handleNew(context),
            ),
            PlatformMenuItem(
              label: 'Open...',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyO,
                meta: true,
              ),
              onSelected: () => _handleOpen(context),
            ),
            PlatformMenuItem(
              label: 'Save',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: true,
              ),
              onSelected: () => _handleSave(context),
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Export...',
                  onSelected: null,
                ),
              ],
            ),
            PlatformMenuItem(
              label: 'Quit',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                meta: true,
              ),
              onSelected: () => _handleQuit(context),
            ),
          ],
        ),
        PlatformMenu(
          label: 'Edit',
          menus: [
            PlatformMenuItem(
              label: 'Undo',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyZ,
                meta: true,
              ),
              onSelected: () => _handleUndo(context),
            ),
            PlatformMenuItem(
              label: 'Redo',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyZ,
                meta: true,
                shift: true,
              ),
              onSelected: () => _handleRedo(context),
            ),
            const PlatformMenuItemGroup(
              members: [],
            ),
            PlatformMenuItem(
              label: 'Cut',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyX,
                meta: true,
              ),
              onSelected: () => _handleCut(context),
            ),
            PlatformMenuItem(
              label: 'Copy',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyC,
                meta: true,
              ),
              onSelected: () => _handleCopy(context),
            ),
            PlatformMenuItem(
              label: 'Paste',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyV,
                meta: true,
              ),
              onSelected: () => _handlePaste(context),
            ),
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItem(
              label: 'Toggle Sidebar',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: true,
                shift: true,
              ),
              onSelected: () => _handleToggleSidebar(context),
            ),
            PlatformMenuItem(
              label: 'Toggle Full Screen',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyF,
                meta: true,
                control: true,
              ),
              onSelected: () => _handleFullScreen(context),
            ),
          ],
        ),
        PlatformMenu(
          label: 'Help',
          menus: [
            PlatformMenuItem(
              label: 'Documentation',
              onSelected: () => _handleDocumentation(context),
            ),
            PlatformMenuItem(
              label: 'About',
              onSelected: () => _handleAbout(context),
            ),
          ],
        ),
      ],
    );
  }

  static void _handleNew(BuildContext context) {
    // Handle new file action
  }

  static void _handleOpen(BuildContext context) {
    // Handle open file action
  }

  static void _handleSave(BuildContext context) {
    // Handle save action
  }

  static void _handleQuit(BuildContext context) {
    // Handle quit action
    SystemNavigator.pop();
  }

  static void _handleUndo(BuildContext context) {
    // Handle undo action
  }

  static void _handleRedo(BuildContext context) {
    // Handle redo action
  }

  static void _handleCut(BuildContext context) {
    // Handle cut action
  }

  static void _handleCopy(BuildContext context) {
    // Handle copy action
  }

  static void _handlePaste(BuildContext context) {
    // Handle paste action
  }

  static void _handleToggleSidebar(BuildContext context) {
    // Handle toggle sidebar action
  }

  static void _handleFullScreen(BuildContext context) {
    // Handle full screen action
  }

  static void _handleDocumentation(BuildContext context) {
    // Handle documentation action
  }

  static void _handleAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'My App',
      applicationVersion: '1.0.0',
    );
  }
}
```

### 2. Context Menu

```dart
// widgets/context_menu.dart
import 'package:flutter/material.dart';

class AppContextMenu extends StatelessWidget {
  final Widget child;
  final List<PopupMenuEntry> menuItems;

  const AppContextMenu({
    super.key,
    required this.child,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: menuItems,
        );
      },
      child: child,
    );
  }
}

// Usage
AppContextMenu(
  menuItems: [
    PopupMenuItem(
      child: const Text('Cut'),
      onTap: () => handleCut(),
    ),
    PopupMenuItem(
      child: const Text('Copy'),
      onTap: () => handleCopy(),
    ),
    PopupMenuItem(
      child: const Text('Paste'),
      onTap: () => handlePaste(),
    ),
    const PopupMenuDivider(),
    PopupMenuItem(
      child: const Text('Delete'),
      onTap: () => handleDelete(),
    ),
  ],
  child: MyWidget(),
)
```

---

## Best Practices

1. **Platform Conventions**: Follow platform-specific menu conventions
2. **Keyboard Shortcuts**: Use standard shortcuts (Cmd/Ctrl+C, etc.)
3. **Menu Grouping**: Group related items with dividers
4. **State Sync**: Keep menu state in sync with app state
5. **Accessibility**: Ensure menus are accessible

---

*Generated by Archon*