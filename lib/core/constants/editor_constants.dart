import 'dart:ui';

/// Editor-specific constants
class EditorConstants {
  EditorConstants._();

  // Zoom settings
  static const double minZoomScale = 0.1;
  static const double maxZoomScale = 10.0;
  static const double defaultZoomScale = 1.0;
  static const double zoomStep = 0.1;

  // Grid settings
  static const double defaultGridSize = 32.0;
  static const Color gridColor = Color(0x40808080);

  // Selection settings
  static const double minSelectionSize = 4.0;
  static const Color selectionColor = Color(0xFF2196F3);
  static const Color selectionFillColor = Color(0x402196F3);

  // Sprite overlay
  static const Color spriteOverlayColor = Color(0xFF4CAF50);
  static const Color spriteOverlayFillColor = Color(0x204CAF50);
  static const Color selectedSpriteColor = Color(0xFFFF9800);

  // Panel sizes
  static const double minPanelWidth = 200.0;
  static const double defaultPropertiesPanelWidth = 280.0;
  static const double defaultSpriteListHeight = 120.0;
}
