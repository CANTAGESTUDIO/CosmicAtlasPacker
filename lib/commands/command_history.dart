import 'editor_command.dart';

/// Manages undo/redo stacks for editor commands
///
/// Provides history tracking with configurable size limit.
/// When new commands are executed after undo, the redo stack is cleared.
class CommandHistory {
  /// Maximum number of commands to keep in history
  static const int defaultMaxHistorySize = 50;

  final int maxHistorySize;

  /// Stack of executed commands (most recent at end)
  final List<EditorCommand> _undoStack = [];

  /// Stack of undone commands (most recent at end)
  final List<EditorCommand> _redoStack = [];

  /// Callback when history state changes
  void Function()? onHistoryChanged;

  CommandHistory({
    this.maxHistorySize = defaultMaxHistorySize,
    this.onHistoryChanged,
  });

  /// Whether undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of commands in undo stack
  int get undoCount => _undoStack.length;

  /// Number of commands in redo stack
  int get redoCount => _redoStack.length;

  /// Description of the command that would be undone
  String? get undoDescription => canUndo ? _undoStack.last.description : null;

  /// Description of the command that would be redone
  String? get redoDescription => canRedo ? _redoStack.last.description : null;

  /// Execute a command and add it to history
  void execute(EditorCommand command) {
    // Execute the command
    command.execute();

    // Add to undo stack
    _undoStack.add(command);

    // Clear redo stack (new action invalidates redo history)
    _redoStack.clear();

    // Enforce size limit
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _notifyChange();
  }

  /// Undo the last command
  void undo() {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    _notifyChange();
  }

  /// Redo the last undone command
  void redo() {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);

    _notifyChange();
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyChange();
  }

  /// Clear redo stack only (used when state changes externally)
  void clearRedoStack() {
    if (_redoStack.isNotEmpty) {
      _redoStack.clear();
      _notifyChange();
    }
  }

  void _notifyChange() {
    onHistoryChanged?.call();
  }

  /// Get undo stack for debugging
  List<String> get undoStackDescriptions =>
      _undoStack.map((c) => c.description).toList();

  /// Get redo stack for debugging
  List<String> get redoStackDescriptions =>
      _redoStack.map((c) => c.description).toList();
}
