import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../commands/command_history.dart';
import '../commands/editor_command.dart';

/// State for history tracking
class HistoryState {
  final bool canUndo;
  final bool canRedo;
  final String? undoDescription;
  final String? redoDescription;
  final int undoCount;
  final int redoCount;

  const HistoryState({
    this.canUndo = false,
    this.canRedo = false,
    this.undoDescription,
    this.redoDescription,
    this.undoCount = 0,
    this.redoCount = 0,
  });

  HistoryState copyWith({
    bool? canUndo,
    bool? canRedo,
    String? undoDescription,
    String? redoDescription,
    int? undoCount,
    int? redoCount,
  }) {
    return HistoryState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      undoDescription: undoDescription,
      redoDescription: redoDescription,
      undoCount: undoCount ?? this.undoCount,
      redoCount: redoCount ?? this.redoCount,
    );
  }
}

/// Notifier for managing command history
class HistoryNotifier extends StateNotifier<HistoryState> {
  final CommandHistory _history;

  HistoryNotifier()
      : _history = CommandHistory(),
        super(const HistoryState()) {
    _history.onHistoryChanged = _updateState;
  }

  /// Execute a command and add it to history
  void execute(EditorCommand command) {
    _history.execute(command);
  }

  /// Undo the last command
  void undo() {
    _history.undo();
  }

  /// Redo the last undone command
  void redo() {
    _history.redo();
  }

  /// Clear all history
  void clear() {
    _history.clear();
  }

  /// Clear redo stack only
  void clearRedoStack() {
    _history.clearRedoStack();
  }

  void _updateState() {
    state = HistoryState(
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      undoDescription: _history.undoDescription,
      redoDescription: _history.redoDescription,
      undoCount: _history.undoCount,
      redoCount: _history.redoCount,
    );
  }

  /// Get undo stack descriptions for debugging
  List<String> get undoStackDescriptions => _history.undoStackDescriptions;

  /// Get redo stack descriptions for debugging
  List<String> get redoStackDescriptions => _history.redoStackDescriptions;
}

/// Provider for history state management
final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});

/// Provider for checking if undo is available
final canUndoProvider = Provider<bool>((ref) {
  return ref.watch(historyProvider).canUndo;
});

/// Provider for checking if redo is available
final canRedoProvider = Provider<bool>((ref) {
  return ref.watch(historyProvider).canRedo;
});

/// Provider for undo description (for menu display)
final undoDescriptionProvider = Provider<String?>((ref) {
  return ref.watch(historyProvider).undoDescription;
});

/// Provider for redo description (for menu display)
final redoDescriptionProvider = Provider<String?>((ref) {
  return ref.watch(historyProvider).redoDescription;
});
