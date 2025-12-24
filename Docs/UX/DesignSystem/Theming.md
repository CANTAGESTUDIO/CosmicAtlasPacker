# Theming

> Defined in `lib/theme/app_theme.dart`.

## Theme Architecture

The application uses the standard Flutter `ThemeData` system, augmented by a custom `EditorThemeColors` class for editor-specific needs.

### Supported Modes

The `EditorThemeMode` enum defines the available modes:
1. **System**: Follows the OS setting (`EditorThemeMode.system`)
2. **Light**: Forces light theme (`EditorThemeMode.light`)
3. **Dark**: Forces dark theme (`EditorThemeMode.dark`)

## Implementation Details

### AppTheme Class

The `AppTheme` class provides static getters for `lightTheme` and `darkTheme`, which return fully configured `ThemeData` objects.

**Key configurations:**
- **Material 3**: Enabled (`useMaterial3: true`)
- **Scaffold**: Custom background colors per theme
- **Inputs**: `InputDecorationTheme` with filled backgrounds and specific border radii (4px)
- **Dialogs**: Custom background and title styles
- **Sliders**: Custom track and thumb colors
- **Tooltips**: Custom decoration and text styles

### EditorThemeColors

Since the standard `ThemeData` doesn't cover all complex editor needs (like canvas grid lines or sprite selection states), we use `EditorThemeColors`.

```dart
// Factory method to get colors based on current context brightness
factory EditorThemeColors.of(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  return EditorThemeColors(isDark: brightness == Brightness.dark);
}
```

This ensures that any component can adapt to the current theme without hardcoding "dark" or "light" logic everywhere.

## Accessing Theme Data

### Standard Material Components
Standard widgets (`Text`, `Card`, `AppBar`) automatically pick up the correct styles from the `ThemeData` provided at the root `MaterialApp`.

```dart
// Example: Using standard theme color
Text(
  'Label',
  style: TextStyle(color: Theme.of(context).colorScheme.primary),
)
```

### Custom Editor Components
For custom drawing or specific editor UI elements, use `EditorThemeColors`:

```dart
final editorColors = EditorThemeColors.of(context);

CustomPaint(
  painter: GridPainter(color: editorColors.gridLine),
)
```