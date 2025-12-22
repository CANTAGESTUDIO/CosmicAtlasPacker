import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'editor_intents.dart';

/// Defines all keyboard shortcuts for the editor
class EditorShortcuts {
  EditorShortcuts._();

  /// All editor shortcuts mapped to their intents
  static Map<ShortcutActivator, Intent> get shortcuts => {
        // File operations
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            const NewProjectIntent(),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
            const OpenImageIntent(),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true):
            const OpenProjectIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            const SaveProjectIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true):
            const SaveProjectAsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true):
            const ExportAtlasIntent(),

        // Edit operations
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            const UndoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            const RedoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            const SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const DeselectAllIntent(),

        // View operations
        const SingleActivator(LogicalKeyboardKey.keyG, meta: true):
            const ToggleGridIntent(),
        const SingleActivator(LogicalKeyboardKey.equal, meta: true):
            const ZoomInIntent(),
        const SingleActivator(LogicalKeyboardKey.minus, meta: true):
            const ZoomOutIntent(),
        const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
            const ResetZoomIntent(),
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
            const FitToWindowIntent(),

        // Tool shortcuts (single key, no modifier)
        const SingleActivator(LogicalKeyboardKey.keyV):
            const SelectToolIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR):
            const RectSliceToolIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA):
            const AutoSliceToolIntent(),
        const SingleActivator(LogicalKeyboardKey.keyG):
            const GridSliceToolIntent(),

        // Dialog shortcuts
        const SingleActivator(LogicalKeyboardKey.keyG, shift: true):
            const ShowGridSliceDialogIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, shift: true):
            const ShowAutoSliceDialogIntent(),
        const SingleActivator(LogicalKeyboardKey.comma, meta: true):
            const ShowAtlasSettingsIntent(),
      };
}
