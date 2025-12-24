# Design System

> Central design system documentation for the **Cosmic Atlas Packer** (Flutter Application).

## Overview

This design system provides comprehensive guidelines for building consistent, accessible, and beautiful user interfaces for the Cosmic Atlas Packer tool.
It is implemented using **Flutter** and relies on a combination of standard `ThemeData` and a custom `EditorThemeColors` class.

## Core Principles

1. **Theme-Aware**: All components must support both Light and Dark modes.
2. **Editor-First**: Colors and layouts are optimized for a productivity tool (high contrast, distinct selection states).
3. **Consistency**: Use centralized definitions in `lib/theme/` and `lib/core/constants/`.

## Document Index

| Document | Description |
|----------|-------------|
| [ColorSystem.md](ColorSystem.md) | Palette, Semantic colors, and Editor-specific colors (`EditorColors`) |
| [Theming.md](Theming.md) | `AppTheme` configuration, Light/Dark mode logic (`EditorThemeMode`) |
| [Layout.md](Layout.md) | Panel sizes, Grid settings, and Atlas layout constants (`EditorConstants`) |
| [Components.md](Components.md) | (To be updated) Specific widget patterns |

## Quick Reference

### Code Locations

- **Theme Data**: `lib/theme/app_theme.dart`
- **Color Definitions**: `lib/theme/editor_colors.dart`
- **Constants**: `lib/core/constants/editor_constants.dart`

### Naming Convention in Code

Code uses CamelCase for Dart classes and properties.

```dart
// Class
class EditorColors { ... }

// Property
static const Color primaryDark = Color(0xFFFF781F);
```

### Tooling

- **Framework**: Flutter (Material 3)
- **Language**: Dart