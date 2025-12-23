import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/editor_colors.dart';

/// A mixin that provides shortcut-blocking Focus wrapper for TextFields.
///
/// This blocks editor shortcuts (G, V, R, etc.) while allowing:
/// - All text input (letters, numbers, symbols)
/// - Navigation keys (arrows, home, end)
/// - Editing keys (backspace, delete)
/// - Control keys (enter, escape, tab)
mixin ShortcutBlockingTextFieldMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _shortcutBlockerNode;

  FocusNode get shortcutBlockerNode {
    _shortcutBlockerNode ??= FocusNode(
      onKeyEvent: _handleKeyEvent,
      skipTraversal: true,
    );
    return _shortcutBlockerNode!;
  }

  /// Override this to customize which keys trigger submission
  void onEnterPressed() {}

  /// Override this to customize escape behavior
  void onEscapePressed() {}

  /// Whether this field only accepts numbers
  bool get isNumberOnly => false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // Handle Enter - submit
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) {
        onEnterPressed();
      }
      return KeyEventResult.handled;
    }

    // Handle Escape
    if (key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        onEscapePressed();
      }
      return KeyEventResult.handled;
    }

    // Always allow these keys to pass through
    if (_isAllowedKey(key)) {
      return KeyEventResult.ignored;
    }

    // For number-only fields, block letter keys
    if (isNumberOnly) {
      return KeyEventResult.handled;
    }

    // For text fields, allow all character input
    // Check if it's a printable character (not a shortcut)
    if (event.character != null && event.character!.isNotEmpty) {
      return KeyEventResult.ignored;
    }

    // Block everything else (potential shortcuts)
    return KeyEventResult.handled;
  }

  bool _isAllowedKey(LogicalKeyboardKey key) {
    // Navigation keys
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.home ||
        key == LogicalKeyboardKey.end) {
      return true;
    }

    // Editing keys
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      return true;
    }

    // Tab for focus traversal
    if (key == LogicalKeyboardKey.tab) {
      return true;
    }

    // Number keys (always allowed)
    if ((key.keyId >= LogicalKeyboardKey.digit0.keyId &&
            key.keyId <= LogicalKeyboardKey.digit9.keyId) ||
        (key.keyId >= LogicalKeyboardKey.numpad0.keyId &&
            key.keyId <= LogicalKeyboardKey.numpad9.keyId)) {
      return true;
    }

    // Period/decimal (for number fields with decimals)
    if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      return true;
    }

    // Minus for negative numbers
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _shortcutBlockerNode?.dispose();
    super.dispose();
  }
}

/// Text input field that blocks editor shortcuts while allowing all text input.
/// Use this for name fields, general text input, etc.
class ShortcutBlockingTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEscape;
  final VoidCallback? onTapOutside;

  const ShortcutBlockingTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.style,
    this.decoration,
    this.autofocus = false,
    this.onSubmitted,
    this.onEscape,
    this.onTapOutside,
  });

  @override
  State<ShortcutBlockingTextField> createState() =>
      _ShortcutBlockingTextFieldState();
}

class _ShortcutBlockingTextFieldState extends State<ShortcutBlockingTextField>
    with ShortcutBlockingTextFieldMixin {
  late FocusNode _textFieldFocusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _textFieldFocusNode = widget.focusNode!;
    } else {
      _textFieldFocusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _textFieldFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  void onEnterPressed() {
    widget.onSubmitted?.call(widget.controller.text);
    _textFieldFocusNode.unfocus();
  }

  @override
  void onEscapePressed() {
    widget.onEscape?.call();
    _textFieldFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: shortcutBlockerNode,
      child: TextField(
        controller: widget.controller,
        focusNode: _textFieldFocusNode,
        autofocus: widget.autofocus,
        style: widget.style ??
            TextStyle(
              fontSize: 12,
              color: EditorColors.iconDefault,
            ),
        decoration: widget.decoration ??
            InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.primary),
              ),
            ),
        onSubmitted: widget.onSubmitted,
        onTapOutside: widget.onTapOutside != null
            ? (_) => widget.onTapOutside!()
            : null,
      ),
    );
  }
}

/// Number input field that blocks editor shortcuts while allowing number input.
/// Use this for duration, size, position fields, etc.
class ShortcutBlockingNumberField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? suffixText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool autofocus;
  final bool allowDecimal;
  final bool allowNegative;
  final double? width;
  final double? height;
  final TextAlign textAlign;
  final VoidCallback? onSubmitted;
  final VoidCallback? onEscape;
  final VoidCallback? onTapOutside;

  const ShortcutBlockingNumberField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.suffixText,
    this.style,
    this.decoration,
    this.autofocus = false,
    this.allowDecimal = true,
    this.allowNegative = false,
    this.width,
    this.height,
    this.textAlign = TextAlign.center,
    this.onSubmitted,
    this.onEscape,
    this.onTapOutside,
  });

  @override
  State<ShortcutBlockingNumberField> createState() =>
      _ShortcutBlockingNumberFieldState();
}

class _ShortcutBlockingNumberFieldState
    extends State<ShortcutBlockingNumberField>
    with ShortcutBlockingTextFieldMixin {
  late FocusNode _textFieldFocusNode;
  bool _ownsFocusNode = false;

  @override
  bool get isNumberOnly => true;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _textFieldFocusNode = widget.focusNode!;
    } else {
      _textFieldFocusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _textFieldFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  void onEnterPressed() {
    widget.onSubmitted?.call();
    _textFieldFocusNode.unfocus();
  }

  @override
  void onEscapePressed() {
    widget.onEscape?.call();
    _textFieldFocusNode.unfocus();
  }

  List<TextInputFormatter> get _inputFormatters {
    if (widget.allowDecimal) {
      if (widget.allowNegative) {
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ];
      }
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ];
    } else {
      if (widget.allowNegative) {
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        ];
      }
      return [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field = Focus(
      focusNode: shortcutBlockerNode,
      child: TextField(
        controller: widget.controller,
        focusNode: _textFieldFocusNode,
        autofocus: widget.autofocus,
        textAlign: widget.textAlign,
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.allowDecimal,
          signed: widget.allowNegative,
        ),
        inputFormatters: _inputFormatters,
        style: widget.style ??
            TextStyle(
              fontSize: 12,
              color: EditorColors.iconDefault,
            ),
        decoration: widget.decoration ??
            InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              filled: true,
              fillColor: EditorColors.surface,
              hintText: widget.hintText,
              suffixText: widget.suffixText,
              suffixStyle: TextStyle(
                fontSize: 10,
                color: EditorColors.iconDisabled,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: EditorColors.primary),
              ),
            ),
        onSubmitted: (_) => widget.onSubmitted?.call(),
        onTapOutside: widget.onTapOutside != null
            ? (_) => widget.onTapOutside!()
            : null,
      ),
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: field,
      );
    }
    return field;
  }
}
