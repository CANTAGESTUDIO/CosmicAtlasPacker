# Color System

> Defined in `lib/theme/editor_colors.dart`.

## Overview

The application uses a dual-theme system (Dark/Light) with distinct color palettes for each mode.
The **Dark Theme** is the default and uses an **Orange/Amber** accent color scheme.
The **Light Theme** uses a **Blue/Green** accent color scheme.

## Color Palette

### Primary & Accent Colors

| Role | Dark Theme (Orange/Amber) | Light Theme (Blue/Green) | Usage |
|------|---------------------------|--------------------------|-------|
| **Primary** | `0xFFFF781F` (Orange) | `0xFF1976D2` (Blue) | Main brand color, active states |
| **Secondary** | `0xFFA64917` (Deep Orange) | `0xFF388E3C` (Green) | Accents, secondary actions |
| **Selection** | `0xFFF59E0B` (Amber) | `0xFF1976D2` (Blue) | Selected items |

### Status Colors

| Role | Dark Theme | Light Theme | Usage |
|------|------------|-------------|-------|
| **Error** | `0xFFEF4444` (Red) | `0xFFD32F2F` (Red) | Error states, destruction |
| **Warning** | `0xFFFB923C` (Light Orange) | `0xFFF57C00` (Orange) | Warnings, alerts |

### Background & Surface

| Role | Dark Theme | Light Theme | Usage |
|------|------------|-------------|-------|
| **Background** | `0xFF212121` | `0xFFF5F5F5` | Main scaffold background |
| **Surface** | `0xFF262626` | `0xFFFFFFFF` | Cards, dialogs, panels |
| **Panel Header** | `0xFF2E2E2E` | `0xFFFAFAFA` | Panel headers |
| **Input BG** | `0xFF1C1C1C` | `0xFFFFFFFF` | Input field background |
| **Canvas** | `0xFF1A1A1A` | `0xFFE8E8E8` | Infinite canvas background |

### UI Elements

| Role | Dark Theme | Light Theme | Usage |
|------|------------|-------------|-------|
| **Border** | `0xFF3A3A3A` | `0xFFE0E0E0` | Borders, dividers |
| **Divider** | `0xFF2E2E2E` | `0xFFBDBDBD` | List dividers |
| **Grid Line** | `0x40808080` | `0x40404040` | Canvas grid lines |

### Icons & Text

| Role | Dark Theme | Light Theme | Usage |
|------|------------|-------------|-------|
| **Icon Default** | `0xFFCABDB4` | `0xFF616161` | Default icons/text |
| **Icon Active** | `0xFFFF781F` | `0xFF1976D2` | Active/Selected icons |
| **Icon Disabled** | `0xFFA3A3A3` | `0xFFBDBDBD` | Disabled state |

### Editor Specific

| Role | Dark Theme | Light Theme | Usage |
|------|------------|-------------|-------|
| **Selection Fill** | `0xFFF59E0B` | `0xFF1976D2` | Selection box fill |
| **Sprite Outline** | `0xFFD97706` | `0xFF388E3C` | Sprite boundary line |
| **Drag Selection** | `0xFFF59E0B` | `0xFF1976D2` | Drag area fill |

## Usage in Code

To use colors in the code, use the `EditorThemeColors` helper or `AppTheme` references.

```dart
// Access via Theme context
final colors = EditorThemeColors.of(context);

Container(
  color: colors.surface,
  child: Icon(Icons.edit, color: colors.primary),
)
```

Direct access (discouraged unless necessary):
```dart
EditorColors.primaryDark
```