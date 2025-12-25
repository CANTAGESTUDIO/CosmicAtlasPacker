import 'dart:ui';

import 'package:flutter/material.dart';

/// Theme mode for the editor
enum EditorThemeMode {
  system,
  light,
  dark,
}

/// Editor color palette with dark and light theme support
class EditorColors {
  EditorColors._();

  // ============================================================
  // Dark Theme Colors (Orange/Amber based)
  // ============================================================

  // Primary colors (dark)
  static const Color primaryDark = Color(0xFFFF781F); // --primary: rgb(255, 120, 31)
  static const Color secondaryDark = Color(0xFFA64917); // --accent: rgb(166, 73, 23)
  static const Color errorDark = Color(0xFFEF4444); // --destructive: rgb(239, 68, 68)
  static const Color warningDark = Color(0xFFFB923C); // --chart-1 variant
  static const Color successDark = Color(0xFF22C55E); // success: green-500

  // Background colors (dark)
  static const Color backgroundDark = Color(0xFF212121); // --background: rgb(33, 33, 33)
  static const Color surfaceDark = Color(0xFF262626); // --card: rgb(38, 38, 38)
  static const Color panelBackgroundDark = Color(0xFF2E2E2E); // lighter panel header

  // Border and divider (dark)
  static const Color borderDark = Color(0xFF3A3A3A); // slider track / button background
  static const Color dividerDark = Color(0xFF2E2E2E); // --border: rgb(46, 46, 46)

  // Input fields (dark)
  static const Color inputBackgroundDark = Color(0xFF1C1C1C); // between background and surface

  // Icons (dark)
  static const Color iconDefaultDark = Color(0xFFCABDB4); // --foreground: rgb(202, 189, 180)
  static const Color iconActiveDark = Color(0xFFFF781F); // --primary: rgb(255, 120, 31)
  static const Color iconDisabledDark = Color(0xFFA3A3A3); // --muted-foreground: rgb(163, 163, 163)

  // Canvas (dark)
  static const Color canvasBackgroundDark = Color(0xFF1A1A1A);
  static const Color gridLineDark = Color(0x40808080);

  // Selection (dark)
  static const Color selectionDark = Color(0xFFF59E0B); // --ring: rgb(245, 158, 11)
  static const Color selectionFillDark = Color(0xFFF59E0B); // --ring: rgb(245, 158, 11)
  static const Color selectionBorderDark = Color(0xFFFF9D2E); // --accent-foreground: rgb(255, 157, 46)

  // Sprite overlay (dark)
  static const Color spriteOutlineDark = Color(0xFFD97706); // --chart-2: rgb(217, 119, 6)
  static const Color spriteFillDark = Color(0xFFD97706); // --chart-2: rgb(217, 119, 6)
  static const Color spriteBorderDark = Color(0xFFD97706); // --chart-2: rgb(217, 119, 6)
  static const Color selectedSpriteDark = Color(0xFFFF9D2E); // --accent-foreground: rgb(255, 157, 46)

  // Drag selection (dark)
  static const Color dragSelectionFillDark = Color(0xFFF59E0B); // --ring: rgb(245, 158, 11)
  static const Color dragSelectionBorderDark = Color(0xFFFBBF24); // --chart-1: rgb(251, 191, 36)

  // ============================================================
  // Light Theme Colors
  // ============================================================

  // Primary colors (light)
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color secondaryLight = Color(0xFF388E3C);
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color warningLight = Color(0xFFF57C00);
  static const Color successLight = Color(0xFF16A34A); // success: green-600

  // Background colors (light)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color panelBackgroundLight = Color(0xFFFAFAFA);

  // Border and divider (light)
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color dividerLight = Color(0xFFBDBDBD);

  // Input fields (light)
  static const Color inputBackgroundLight = Color(0xFFFFFFFF);

  // Icons (light)
  static const Color iconDefaultLight = Color(0xFF616161);
  static const Color iconActiveLight = Color(0xFF1976D2);
  static const Color iconDisabledLight = Color(0xFFBDBDBD);

  // Canvas (light)
  static const Color canvasBackgroundLight = Color(0xFFE8E8E8);
  static const Color gridLineLight = Color(0x40404040);

  // Selection (light)
  static const Color selectionLight = Color(0xFF1976D2);
  static const Color selectionFillLight = Color(0xFF1976D2);
  static const Color selectionBorderLight = Color(0xFFF57C00);

  // Sprite overlay (light)
  static const Color spriteOutlineLight = Color(0xFF388E3C);
  static const Color spriteFillLight = Color(0xFF388E3C);
  static const Color spriteBorderLight = Color(0xFF388E3C);
  static const Color selectedSpriteLight = Color(0xFFF57C00);

  // Drag selection (light)
  static const Color dragSelectionFillLight = Color(0xFF1976D2);
  static const Color dragSelectionBorderLight = Color(0xFF42A5F5);

  // ============================================================
  // Static accessors (default to dark theme for backwards compatibility)
  // ============================================================

  static const Color primary = primaryDark;
  static const Color secondary = secondaryDark;
  static const Color error = errorDark;
  static const Color warning = warningDark;
  static const Color success = successDark;

  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color panelBackground = panelBackgroundDark;

  static const Color border = borderDark;
  static const Color divider = dividerDark;

  static const Color inputBackground = inputBackgroundDark;

  static const Color iconDefault = iconDefaultDark;
  static const Color iconActive = iconActiveDark;
  static const Color iconDisabled = iconDisabledDark;

  static const Color canvasBackground = canvasBackgroundDark;
  static const Color gridLine = gridLineDark;

  static const Color selection = selectionDark;
  static const Color selectionFill = selectionFillDark;
  static const Color selectionBorder = selectionBorderDark;

  static const Color spriteOutline = spriteOutlineDark;
  static const Color spriteFill = spriteFillDark;
  static const Color spriteBorder = spriteBorderDark;
  static const Color selectedSprite = selectedSpriteDark;

  static const Color dragSelectionFill = dragSelectionFillDark;
  static const Color dragSelectionBorder = dragSelectionBorderDark;
}

/// Theme-aware editor colors accessed via BuildContext
class EditorThemeColors {
  final bool isDark;

  const EditorThemeColors({required this.isDark});

  factory EditorThemeColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return EditorThemeColors(isDark: brightness == Brightness.dark);
  }

  // Primary colors
  Color get primary => isDark ? EditorColors.primaryDark : EditorColors.primaryLight;
  Color get secondary => isDark ? EditorColors.secondaryDark : EditorColors.secondaryLight;
  Color get error => isDark ? EditorColors.errorDark : EditorColors.errorLight;
  Color get warning => isDark ? EditorColors.warningDark : EditorColors.warningLight;
  Color get success => isDark ? EditorColors.successDark : EditorColors.successLight;

  // Background colors
  Color get background => isDark ? EditorColors.backgroundDark : EditorColors.backgroundLight;
  Color get surface => isDark ? EditorColors.surfaceDark : EditorColors.surfaceLight;
  Color get panelBackground => isDark ? EditorColors.panelBackgroundDark : EditorColors.panelBackgroundLight;

  // Border and divider
  Color get border => isDark ? EditorColors.borderDark : EditorColors.borderLight;
  Color get divider => isDark ? EditorColors.dividerDark : EditorColors.dividerLight;

  // Input fields
  Color get inputBackground => isDark ? EditorColors.inputBackgroundDark : EditorColors.inputBackgroundLight;

  // Icons
  Color get iconDefault => isDark ? EditorColors.iconDefaultDark : EditorColors.iconDefaultLight;
  Color get iconActive => isDark ? EditorColors.iconActiveDark : EditorColors.iconActiveLight;
  Color get iconDisabled => isDark ? EditorColors.iconDisabledDark : EditorColors.iconDisabledLight;

  // Canvas
  Color get canvasBackground => isDark ? EditorColors.canvasBackgroundDark : EditorColors.canvasBackgroundLight;
  Color get gridLine => isDark ? EditorColors.gridLineDark : EditorColors.gridLineLight;

  // Selection
  Color get selection => isDark ? EditorColors.selectionDark : EditorColors.selectionLight;
  Color get selectionFill => isDark ? EditorColors.selectionFillDark : EditorColors.selectionFillLight;
  Color get selectionBorder => isDark ? EditorColors.selectionBorderDark : EditorColors.selectionBorderLight;

  // Sprite overlay
  Color get spriteOutline => isDark ? EditorColors.spriteOutlineDark : EditorColors.spriteOutlineLight;
  Color get spriteFill => isDark ? EditorColors.spriteFillDark : EditorColors.spriteFillLight;
  Color get spriteBorder => isDark ? EditorColors.spriteBorderDark : EditorColors.spriteBorderLight;
  Color get selectedSprite => isDark ? EditorColors.selectedSpriteDark : EditorColors.selectedSpriteLight;

  // Drag selection
  Color get dragSelectionFill => isDark ? EditorColors.dragSelectionFillDark : EditorColors.dragSelectionFillLight;
  Color get dragSelectionBorder => isDark ? EditorColors.dragSelectionBorderDark : EditorColors.dragSelectionBorderLight;
}
