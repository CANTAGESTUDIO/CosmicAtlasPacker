# Accessibility

> Guidelines for making the editor accessible.

## Overview

The application aims to be accessible via keyboard and screen readers, leveraging Flutter's built-in `Semantics` tree.

## Focus Management

- **Keyboard Navigation**: All interactive elements (Inputs, Buttons, Toggles) must be focusable.
- **Visual Feedback**: Focus states are visually distinct.
- **Shortcuts**: `EditorTextField` manages shortcut conflicts using `Focus` nodes.

## Semantics

Flutter automatically provides semantics for standard widgets (`Button`, `TextField`). For custom painters users `CustomPaint`, explicit `Semantics` widgets may be needed if they are interactive.

### Code Example

```dart
Semantics(
  label: 'Sprite Preview',
  hint: 'Double click to edit',
  button: true,
  child: CustomPaint(...),
)
```

## Shortcuts & Key Handling

The editor relies heavily on keyboard shortcuts.
- **Inputs**: Text fields must swallow key events (`KeyEventResult.skipRemainingHandlers`) to prevent triggering global shortcuts (like "Delete" to delete a sprite) while typing.
- **Global**: `FocusScope` is used to manage global shortcuts.

## Contrast

The **Dark Theme** (default) is designed with high contrast in mind:
- Text: `0xFFCABDB4` (Light Gray) on `0xFF262626` (Dark Gray) pass AA standards.
- Selection: Bright Orange/Amber (`0xFFFF781F`) ensures visibility.

## Checklist for New Components

- [ ] Is it reachable via Tab key?
- [ ] Does it have a tooltip?
- [ ] contrast ratio > 4.5:1 (AA)?
- [ ] If custom drawing, is wrapped in Semantics?