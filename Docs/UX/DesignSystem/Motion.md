# Motion & Animation

> Animation guidelines for the editor.

## Principles

As a productivity tool, animations should be **subtle** and **swift**.
Avoid long transitions that delay user interaction.

## Durations

| Token | Duration | Usage |
|-------|----------|-------|
| `fast` | 100ms | Hover states, micro-interactions |
| `normal` | 200ms | Dialog open/close, panel sliding |
| `slow` | 300ms | Large structural changes |

## Easing

- `Curves.easeOut`: For entering elements (Dialogs).
- `Curves.easeIn`: For exiting elements.
- `Curves.easeInOut`: For moving elements.

## Common Patterns

### Dialog Entrance

Dialogs typically fade in and scale up slightly.

```dart
// Flutter's default dialog transition is usually sufficient.
// Custom implementation example:
ScaleTransition(
  scale: CurvedAnimation(
    parent: controller,
    curve: Curves.easeOut,
  ),
  child: Dialog(...),
)
```

### Hover Effects

Buttons often have `Hover` effects indicating interactivity.

```dart
InkWell(
  hoverColor: EditorColors.primary.withOpacity(0.1),
  onTap: () {},
  child: ...
)
```

### Canvas Zoom

Zooming on the canvas should be immediate or very snappy to track mouse scrolling precisely.