import 'package:flutter/widgets.dart';

/// Intent for creating a new project
class NewProjectIntent extends Intent {
  const NewProjectIntent();
}

/// Intent for opening a project
class OpenProjectIntent extends Intent {
  const OpenProjectIntent();
}

/// Intent for opening an image
class OpenImageIntent extends Intent {
  const OpenImageIntent();
}

/// Intent for saving a project
class SaveProjectIntent extends Intent {
  const SaveProjectIntent();
}

/// Intent for saving a project as (new file)
class SaveProjectAsIntent extends Intent {
  const SaveProjectAsIntent();
}

/// Intent for exporting atlas
class ExportAtlasIntent extends Intent {
  const ExportAtlasIntent();
}

/// Intent for undo
class UndoIntent extends Intent {
  const UndoIntent();
}

/// Intent for redo
class RedoIntent extends Intent {
  const RedoIntent();
}

/// Intent for selecting all sprites
class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

/// Intent for deleting selected sprites
class DeleteSelectedIntent extends Intent {
  const DeleteSelectedIntent();
}

/// Intent for deselecting all sprites
class DeselectAllIntent extends Intent {
  const DeselectAllIntent();
}

/// Intent for toggling grid visibility
class ToggleGridIntent extends Intent {
  const ToggleGridIntent();
}

/// Intent for zooming in
class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

/// Intent for zooming out
class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

/// Intent for resetting zoom to 100%
class ResetZoomIntent extends Intent {
  const ResetZoomIntent();
}

/// Intent for fit to window
class FitToWindowIntent extends Intent {
  const FitToWindowIntent();
}

/// Intent for switching to select tool
class SelectToolIntent extends Intent {
  const SelectToolIntent();
}

/// Intent for switching to rect slice tool
class RectSliceToolIntent extends Intent {
  const RectSliceToolIntent();
}

/// Intent for switching to auto slice tool
class AutoSliceToolIntent extends Intent {
  const AutoSliceToolIntent();
}

/// Intent for switching to grid slice tool
class GridSliceToolIntent extends Intent {
  const GridSliceToolIntent();
}

/// Intent for showing grid slice dialog
class ShowGridSliceDialogIntent extends Intent {
  const ShowGridSliceDialogIntent();
}

/// Intent for showing auto slice dialog
class ShowAutoSliceDialogIntent extends Intent {
  const ShowAutoSliceDialogIntent();
}

/// Intent for showing atlas settings dialog
class ShowAtlasSettingsIntent extends Intent {
  const ShowAtlasSettingsIntent();
}
