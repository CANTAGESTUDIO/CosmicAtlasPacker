# Typography

> Font definitions and text styles.

## Font Family

The application relies on the default platform font family (San Francisco on macOS, Roboto on Android, Segoe UI on Windows) to ensure a native feel.
Detailed font configuration is handled by `ThemeData` usage of `TextTheme`.

## Type Scale

### Headings (Material Standard)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineSmall` | 24px | 400 | Modal titles |
| `titleLarge` | 22px | 500 | Section headers |
| `titleMedium` | 16px | 500 | Sub-section headers |

### Editor Specific

| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| **Input Text** | 11px | 400 | `iconDefault` | Text inside `EditorTextField` |
| **Input Hint** | 11px | 400 | `iconDisabled (0.7)` | Placeholder text |
| **Tooltip** | 12px | 400 | `iconDefault` | Tooltips |
| **Dialog Title**| 18px | 600 | `iconDefault` | Dialog headers |
| **Section** | 12px | 600 | `iconDefault` | Property panel sections |

## Usage Guidelines

### In Layouts
Use standard Material `Text` widgets. The `AppTheme` ensures high-level defaults are correct.
For specific editor components (like the properties panel), explicit styles are often used to ensure density (e.g., `fontSize: 11`).

### Code Example

```dart
// Standard text
Text(
  'File Name',
  style: Theme.of(context).textTheme.bodyMedium,
)

// Editor specific (often used in input fields)
Text(
  'sprite_01.png',
  style: TextStyle(
    fontSize: 11,
    color: EditorColors.iconDefault,
  ),
)
```