import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:u_design/u_design.dart';

class UTextEditor extends StatefulWidget {
  const UTextEditor({
    super.key,
    this.cntlr,
    this.focusNode,
    this.initialText = '',
    this.showLineNumbers = true,
    this.showStatusBar = true,
    this.lineNumberWidth = 48.0,
    this.fontSize = 14.0,
    this.lineHeight = 1.5,
    this.padding,
    this.onChanged,
  });

  final TextEditingController? cntlr;
  final FocusNode? focusNode;
  final String initialText;
  final bool showLineNumbers;
  final bool showStatusBar;
  final double lineNumberWidth;
  final double fontSize;
  final double lineHeight;
  final EdgeInsets? padding;
  final ValueChanged<String>? onChanged;

  @override
  State<UTextEditor> createState() => _UTextEditorState();
}

class _UTextEditorState extends State<UTextEditor>
    with WidgetsBindingObserver
    implements TextInputClient, TextSelectionDelegate {
  late final TextEditingController _cntlr;
  late final FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _cursorBlinkNotifier = ValueNotifier<bool>(true);
  final MagnifierController _magnifierController = MagnifierController();
  late final Listenable _repaintNotifier;

  TextInputConnection? _textInputConnection;
  Timer? _cursorTimer;
  bool _hasFocus = false;

  int _batchEditDepth = 0;
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  double _viewportHeight = 0;
  double _viewportWidth = 0;
  double _lineHeightPx = 0;
  double _lastTextWidth = -1;

  late TextStyle _textStyle;
  late TextStyle _lineNumberStyle;
  Color _textColor = Colors.black;
  Color _lineNumberColor = Colors.grey;
  Color _lineNumberCurrentColor = Colors.blue;

  List<int> _lineStarts = [0];
  String _lastRebuiltText = '';
  int _textGeneration = 0;

  final Map<int, TextPainter> _linePainterCache = {};
  int _lastTextGeneration = -1;

  OverlayEntry? _contextMenuEntry;
  ClipboardStatusNotifier? _clipboardStatus;

  // ===================== Undo Stack =====================

  final _UndoStack<TextEditingValue> _undoStack =
      _UndoStack<TextEditingValue>();
  Timer? _undoThrottleTimer;
  static const Duration _kUndoThrottleDuration = Duration(milliseconds: 500);

  // ===================== Helpers =====================

  EdgeInsets get _padding =>
      widget.padding ??
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  double get _textWidth {
    double w = _viewportWidth - _padding.horizontal;
    if (widget.showLineNumbers) w -= widget.lineNumberWidth;
    return math.max(w, 1);
  }

  double get _contentHeight => _lineStarts.length * _lineHeightPx;

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  int get _cursorLine =>
      _lineIndexAt(_cntlr.selection.baseOffset);

  int get _cursorColumn {
    final offset = _cntlr.selection.baseOffset;
    if (offset <= 0) return 0;
    return offset - _lineStarts[_cursorLine];
  }

  int _lineIndexAt(int offset) {
    if (offset < 0 || _lineStarts.isEmpty) return 0;
    int lo = 0, hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  String _lineText(int i) {
    final text = _cntlr.text;
    final start = _lineStarts[i];
    final end =
        i < _lineStarts.length - 1 ? _lineStarts[i + 1] - 1 : text.length;
    if (start > end) return '';
    return text.substring(start, end);
  }

  int _lineLength(int i) {
    if (i < _lineStarts.length - 1) {
      return _lineStarts[i + 1] - 1 - _lineStarts[i];
    }
    return _cntlr.text.length - _lineStarts[i];
  }

  static List<int> _buildLineStarts(String text) {
    if (text.isEmpty) return [0];
    final starts = <int>[0];
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '\n') {
        starts.add(i + 1);
      }
    }
    return starts;
  }

  bool get _hasInputConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  // ===================== Lifecycle =====================

  @override
  void initState() {
    super.initState();
    _cntlr = widget.cntlr ?? TextEditingController(text: widget.initialText);
    _focusNode = widget.focusNode ?? FocusNode();
    _repaintNotifier = Listenable.merge([
      _scrollController,
      _cursorBlinkNotifier,
    ]);
    _clipboardStatus =
        kIsWeb ? null : ClipboardStatusNotifier();
    _cntlr.addListener(_controllerListener);
    _focusNode.addListener(_handleFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialText.isNotEmpty) {
      _lineStarts = _buildLineStarts(widget.initialText);
      _lastRebuiltText = widget.initialText;
    }
    _pushUndo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = UTheme.of(context);
    _textColor = theme.onSurface;
    _lineNumberColor = theme.secondary;
    _lineNumberCurrentColor = theme.primary;
    _lineHeightPx = widget.fontSize * widget.lineHeight;
    _textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: _textColor,
    );
    _lineNumberStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: _lineNumberColor,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cntlr.removeListener(_controllerListener);
    _focusNode.removeListener(_handleFocusChanged);
    _closeInputConnectionIfNeeded();
    _stopCursorBlink();
    _cursorBlinkNotifier.dispose();
    _scrollController.dispose();
    _clearPainterCache();
    _undoThrottleTimer?.cancel();
    _dismissContextMenu();
    _clipboardStatus?.dispose();
    if (widget.cntlr == null) _cntlr.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _clearPainterCache() {
    for (final p in _linePainterCache.values) {
      p.dispose();
    }
    _linePainterCache.clear();
    _lastTextGeneration = -1;
  }

  // ===================== Batch Edit / IME Sync =====================

  void _beginBatchEdit() {
    _batchEditDepth += 1;
  }

  void _endBatchEdit() {
    _batchEditDepth -= 1;
    assert(_batchEditDepth >= 0, 'Unbalanced call to _endBatchEdit');
    _updateRemoteEditingValueIfNeeded();
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (_batchEditDepth > 0 || !_hasInputConnection) return;
    final localValue = _cntlr.value;
    if (localValue == _lastKnownRemoteTextEditingValue) return;
    _textInputConnection?.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  // ===================== Undo / Redo =====================

  void _pushUndo() {
    final value = _cntlr.value;
    if (value.text.isEmpty && _undoStack.currentValue == null) return;
    if (!value.composing.isCollapsed) return;
    _undoThrottleTimer?.cancel();
    _undoThrottleTimer = Timer(_kUndoThrottleDuration, () {
      _undoStack.push(value);
    });
  }

  void _handleUndo(UndoTextIntent intent) {
    final value = _undoStack.undo();
    if (value == null) return;
    _beginBatchEdit();
    final nextValue = _cntlr.value.copyWith(
      text: value.text,
      selection: value.selection,
      composing: TextRange.empty,
    );
    _cntlr.value = nextValue;
    _endBatchEdit();
    _ensureCursorVisible();
    _restartCursorBlink();
  }

  void _handleRedo(RedoTextIntent intent) {
    final value = _undoStack.redo();
    if (value == null) return;
    _beginBatchEdit();
    final nextValue = _cntlr.value.copyWith(
      text: value.text,
      selection: value.selection,
      composing: TextRange.empty,
    );
    _cntlr.value = nextValue;
    _endBatchEdit();
    _ensureCursorVisible();
    _restartCursorBlink();
  }

  // ===================== Controller Listener =====================

  void _controllerListener() {
    if (_lastRebuiltText != _cntlr.text) {
      _lineStarts = _buildLineStarts(_cntlr.text);
      _lastRebuiltText = _cntlr.text;
      _textGeneration++;
    }
    if (mounted) setState(() {});
    widget.onChanged?.call(_cntlr.text);
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() => _hasFocus = _focusNode.hasFocus);
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorBlinkIfNeeded();
    if (!_hasFocus) {
      _dismissContextMenu();
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && _focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      _cntlr.clearComposing();
    }
  }

  void _openInputConnection() {
    if (_hasInputConnection) {
      _textInputConnection!.updateConfig(
        const TextInputConfiguration(
          inputType: TextInputType.multiline,
          inputAction: TextInputAction.newline,
          enableSuggestions: false,
          autocorrect: false,
        ),
      );
      _textInputConnection!.show();
      return;
    }
    final localValue = _cntlr.value;
    _textInputConnection = TextInput.attach(
      this,
      const TextInputConfiguration(
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
        enableSuggestions: false,
        autocorrect: false,
      ),
    );
    _textInputConnection!
      ..setStyle(
        fontFamily: _textStyle.fontFamily,
        fontSize: _textStyle.fontSize,
        fontWeight: _textStyle.fontWeight,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.start,
      )
      ..setEditingState(localValue)
      ..show();
    _lastKnownRemoteTextEditingValue = localValue;
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _startOrStopCursorBlinkIfNeeded() {
    if (!_hasFocus) {
      _cursorBlinkNotifier.value = false;
      _stopCursorBlink();
      return;
    }
    _startCursorBlink();
  }

  static const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

  void _startCursorBlink() {
    _cursorBlinkNotifier.value = true;
    _stopCursorBlink();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, (_) {
      if (!mounted) return;
      _cursorBlinkNotifier.value = !_cursorBlinkNotifier.value;
    });
  }

  void _stopCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
  }

  void _restartCursorBlink() {
    if (!_hasFocus) return;
    _cursorBlinkNotifier.value = true;
    _startCursorBlink();
  }

  void _ensureCursorVisible() {
    if (!_scrollController.hasClients) return;
    final cursorY = _cursorLine * _lineHeightPx;
    final visibleTop = _scrollOffset;
    final visibleBottom = visibleTop + _viewportHeight;
    if (cursorY < visibleTop) {
      _scrollController.jumpTo(cursorY);
    } else if (cursorY + _lineHeightPx > visibleBottom) {
      _scrollController.jumpTo(
        cursorY + _lineHeightPx - _viewportHeight + _padding.vertical,
      );
    }
  }

  // ===================== TextInputClient =====================

  @override
  TextEditingValue? get currentTextEditingValue => _cntlr.value;

  @override
  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause? cause,
  ) {
    if (value == _cntlr.value) return;

    final textChanged = _cntlr.value.text != value.text;
    final selectionChanged = _cntlr.value.selection != value.selection;
    final textCommitted =
        !_cntlr.value.composing.isCollapsed && value.composing.isCollapsed;

    _beginBatchEdit();
    _cntlr.value = value;
    _endBatchEdit();

    if (selectionChanged) {
      _restartCursorBlink();
      _ensureCursorVisible();
    }

    if (textChanged || textCommitted) {
      _pushUndo();
    }
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // Only text changes from IME
    if (value.text == _cntlr.value.text &&
        value.composing == _cntlr.value.composing) {
      // selection-only change from IME (e.g., keyboard selection)
      _beginBatchEdit();
      _cntlr.selection = value.selection;
      _endBatchEdit();
      _restartCursorBlink();
      _ensureCursorVisible();
      if (_hasInputConnection) {
        _lastKnownRemoteTextEditingValue = value;
      }
      return;
    }

    _beginBatchEdit();
    _cntlr.value = value;
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();

    if (value.composing.isCollapsed) {
      _pushUndo();
    }

    if (_hasInputConnection) {
      _lastKnownRemoteTextEditingValue = value;
    }
  }

  @override
  void performAction(TextInputAction action) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection?.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _focusNode.unfocus();
    }
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {
    if (_cntlr.selection.isCollapsed) return;
    _showContextMenu();
  }

  @override
  void didChangeInputControl(TextInputControl? old, TextInputControl? now) {
    if (_hasFocus && _hasInputConnection) {
      old?.hide();
      now?.show();
    }
  }

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void performSelector(String selectorName) {}

  // ===================== TextSelectionDelegate =====================

  @override
  TextEditingValue get textEditingValue => _cntlr.value;

  @override
  void cutSelection(SelectionChangedCause cause) {
    final selection = _cntlr.selection;
    if (selection.isCollapsed) return;
    final text = _cntlr.text;
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    _beginBatchEdit();
    _cntlr.value = TextEditingValue(
      text:
          text.substring(0, selection.start) + text.substring(selection.end),
      selection: TextSelection.collapsed(offset: selection.start),
    );
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
    _pushUndo();
    HapticFeedback.lightImpact();
    _clipboardStatus?.update();
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final text = data!.text!;
    final sel = _cntlr.selection;
    final fullText = _cntlr.text;
    final start = sel.start.clamp(0, fullText.length);
    final end = sel.end.clamp(0, fullText.length);
    final newText = '${fullText.substring(0, start)}$text${fullText.substring(end)}';
    _beginBatchEdit();
    _cntlr.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
    _pushUndo();
    HapticFeedback.lightImpact();
    _clipboardStatus?.update();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    if (_cntlr.text.isEmpty) return;
    _beginBatchEdit();
    _cntlr.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _cntlr.text.length,
    );
    _endBatchEdit();
    _restartCursorBlink();
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    final selection = _cntlr.selection;
    if (selection.isCollapsed) return;
    final text = _cntlr.text;
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    HapticFeedback.lightImpact();
    _clipboardStatus?.update();
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    _dismissContextMenu();
  }

  @override
  void bringIntoView(TextPosition position) {
    _ensureCursorVisible();
  }

  @override
  bool get cutEnabled => true;

  @override
  bool get copyEnabled => true;

  @override
  bool get pasteEnabled => true;

  @override
  bool get selectAllEnabled => true;

  @override
  bool get lookUpEnabled => true;

  @override
  bool get searchWebEnabled => true;

  @override
  bool get shareEnabled => true;

  @override
  bool get liveTextInputEnabled => false;

  // ===================== Actions =====================

  void _handleReplaceText(ReplaceTextIntent intent) {
    final newValue = intent.currentTextEditingValue.replaced(
      intent.replacementRange,
      intent.replacementText,
    );
    userUpdateTextEditingValue(newValue, intent.cause);
  }

  void _handleUpdateSelection(UpdateSelectionIntent intent) {
    if (intent.newSelection == _cntlr.selection) return;
    userUpdateTextEditingValue(
      _cntlr.value.copyWith(selection: intent.newSelection),
      intent.cause,
    );
  }

  void _handleCopySelection(CopySelectionTextIntent intent) {
    if (intent.collapseSelection) {
      cutSelection(intent.cause);
    } else {
      copySelection(intent.cause);
    }
  }

  void _handlePaste(PasteTextIntent intent) {
    pasteText(intent.cause);
  }

  void _handleSelectAll(SelectAllTextIntent intent) {
    selectAll(intent.cause);
  }

  // ===================== Keyboard (Focus onKeyEvent) =====================
  //
  // 官方 EditableText 通过 Shortcuts → Actions 系统处理键盘，但 PC 端
  // HardwareKeyboard 事件分发在某些场景下与 DefaultTextEditingShortcuts
  // 不兼容。这里直接在 Focus.onKeyEvent 中处理所有导航/编辑键，
  // Ctrl/Alt 组合键委托给 DefaultTextEditingShortcuts + Actions 系统。

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final logical = event.logicalKey;

    if (logical == LogicalKeyboardKey.control ||
        logical == LogicalKeyboardKey.meta ||
        logical == LogicalKeyboardKey.alt ||
        logical == LogicalKeyboardKey.shift ||
        logical == LogicalKeyboardKey.capsLock ||
        logical == LogicalKeyboardKey.numLock) {
      return KeyEventResult.ignored;
    }

    final shift = HardwareKeyboard.instance.isShiftPressed;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;

    // --- Ctrl/Alt modified keys → let Shortcuts system handle ---
    if (ctrl || alt) {
      return KeyEventResult.ignored;
    }

    // --- Tab → insert 2 spaces ---
    if (logical == LogicalKeyboardKey.tab) {
      _insertTab();
      return KeyEventResult.handled;
    }

    // --- Enter → insert newline ---
    if (logical == LogicalKeyboardKey.enter ||
        logical == LogicalKeyboardKey.numpadEnter) {
      _insertNewline();
      return KeyEventResult.handled;
    }

    // --- Home / End ---
    if (logical == LogicalKeyboardKey.home) {
      _moveToLineBoundary(false, shift);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.end) {
      _moveToLineBoundary(true, shift);
      return KeyEventResult.handled;
    }

    // --- Backspace ---
    if (logical == LogicalKeyboardKey.backspace) {
      _handleDelete(DeleteCharacterIntent(forward: false));
      return KeyEventResult.handled;
    }

    // --- Delete ---
    if (logical == LogicalKeyboardKey.delete) {
      _handleDelete(DeleteCharacterIntent(forward: true));
      return KeyEventResult.handled;
    }

    // --- Arrow keys ---
    if (logical == LogicalKeyboardKey.arrowLeft) {
      _moveByCharacter(false, shift);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowRight) {
      _moveByCharacter(true, shift);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowUp) {
      _moveVertical(false, shift);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowDown) {
      _moveVertical(true, shift);
      return KeyEventResult.handled;
    }

    // --- PageUp / PageDown ---
    if (logical == LogicalKeyboardKey.pageUp) {
      _moveByPage(false, shift);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.pageDown) {
      _moveByPage(true, shift);
      return KeyEventResult.handled;
    }

    // --- Escape → unfocus ---
    if (logical == LogicalKeyboardKey.escape) {
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _insertTab() {
    final text = _cntlr.text;
    final sel = _cntlr.selection;
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    userUpdateTextEditingValue(
      TextEditingValue(
        text: '${text.substring(0, start)}  ${text.substring(end)}',
        selection: TextSelection.collapsed(offset: start + 2),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _insertNewline() {
    final text = _cntlr.text;
    final sel = _cntlr.selection;
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    userUpdateTextEditingValue(
      TextEditingValue(
        text: '${text.substring(0, start)}\n${text.substring(end)}',
        selection: TextSelection.collapsed(offset: start + 1),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _moveByCharacter(bool forward, bool extend) {
    final sel = _cntlr.selection;
    final text = _cntlr.text;
    if (!sel.isValid) return;

    if (!extend && !sel.isCollapsed) {
      final newOffset = forward ? sel.end : sel.start;
      _beginBatchEdit();
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      _endBatchEdit();
    } else if (extend && sel.isCollapsed) {
      // Start extending from base
      final newOffset = forward
          ? (sel.baseOffset + 1).clamp(0, text.length)
          : (sel.baseOffset - 1).clamp(0, text.length);
      _beginBatchEdit();
      _cntlr.selection = TextSelection(
        baseOffset: sel.baseOffset,
        extentOffset: newOffset,
      );
      _endBatchEdit();
    } else if (extend) {
      // Already extending
      final newOffset = forward
          ? (sel.extentOffset + 1).clamp(0, text.length)
          : (sel.extentOffset - 1).clamp(0, text.length);
      _beginBatchEdit();
      _cntlr.selection = sel.extendTo(TextPosition(offset: newOffset));
      _endBatchEdit();
    } else {
      // Collapsed cursor, move one character
      final newOffset = forward
          ? (sel.baseOffset + 1).clamp(0, text.length)
          : (sel.baseOffset - 1).clamp(0, text.length);
      _beginBatchEdit();
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      _endBatchEdit();
    }
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _moveVertical(bool forward, bool extend) {
    final sel = _cntlr.selection;
    final text = _cntlr.text;
    if (!sel.isValid) return;

    final extentOffset = extend && !sel.isCollapsed
        ? sel.extentOffset
        : (extend ? sel.baseOffset : sel.baseOffset);

    final currentLine = _lineIndexAt(extentOffset);
    final currentCol =
        (extentOffset - _lineStarts[currentLine]).clamp(0, _lineLength(currentLine));

    int newOffset;
    if (forward) {
      if (currentLine >= _lineStarts.length - 1) {
        newOffset = text.length;
      } else {
        final newCol = math.min<int>(currentCol, _lineLength(currentLine + 1));
        newOffset = _lineStarts[currentLine + 1] + newCol;
      }
    } else {
      if (currentLine <= 0) {
        newOffset = 0;
      } else {
        final newCol = math.min<int>(currentCol, _lineLength(currentLine - 1));
        newOffset = _lineStarts[currentLine - 1] + newCol;
      }
    }
    newOffset = newOffset.clamp(0, text.length);

    _beginBatchEdit();
    if (extend) {
      _cntlr.selection = sel.extendTo(TextPosition(offset: newOffset));
    } else {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _moveToLineBoundary(bool forward, bool extend) {
    final sel = _cntlr.selection;
    final text = _cntlr.text;
    if (!sel.isValid) return;

    final extentOffset = extend ? sel.extentOffset : sel.baseOffset;
    final cl = _lineIndexAt(extentOffset);

    final newOffset = forward
        ? (_lineStarts[cl] + _lineLength(cl)).clamp(0, text.length)
        : _lineStarts[cl].clamp(0, text.length);

    _beginBatchEdit();
    if (extend) {
      _cntlr.selection = sel.extendTo(TextPosition(offset: newOffset));
    } else {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _moveByPage(bool forward, bool extend) {
    final sel = _cntlr.selection;
    final text = _cntlr.text;
    if (!sel.isValid) return;

    final extentOffset = extend ? sel.extentOffset : sel.baseOffset;
    final currentLine = _lineIndexAt(extentOffset);
    final currentCol =
        (extentOffset - _lineStarts[currentLine]).clamp(0, _lineLength(currentLine));

    final pageSize = math.max(1, (_viewportHeight / _lineHeightPx).floor() - 2);

    final newLine = forward
        ? math.min(currentLine + pageSize, _lineStarts.length - 1)
        : math.max(currentLine - pageSize, 0);
    final newCol = math.min<int>(currentCol, _lineLength(newLine));
    final newOffset = (_lineStarts[newLine] + newCol).clamp(0, text.length);

    _beginBatchEdit();
    if (extend) {
      _cntlr.selection = sel.extendTo(TextPosition(offset: newOffset));
    } else {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  // ===================== Gestures =====================

  void _onTapDown(TapDownDetails details) {
    requestKeyboard();
    _dismissContextMenu();
    final pos = _offsetToPosition(details.localPosition);
    final offset =
        (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    _beginBatchEdit();
    _cntlr.selection = TextSelection.collapsed(offset: offset);
    _endBatchEdit();
    _restartCursorBlink();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    requestKeyboard();
    _dismissContextMenu();
    final pos = _offsetToPosition(details.localPosition);
    final offset =
        (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    _selectWordAtOffset(offset);
    _restartCursorBlink();
    _ensureCursorVisible();
    HapticFeedback.lightImpact();
    _showContextMenu();
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    final offset =
        (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    if (_cntlr.selection.isCollapsed ||
        !_cntlr.selection.isValid) {
      _beginBatchEdit();
      _cntlr.selection = TextSelection.collapsed(offset: offset);
      _endBatchEdit();
    }
    _showContextMenu();
  }

  void _onPanStart(DragStartDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    final offset =
        (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    _beginBatchEdit();
    _cntlr.selection = TextSelection(
      baseOffset: offset,
      extentOffset: offset,
    );
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    final offset =
        (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    _beginBatchEdit();
    _cntlr.selection =
        _cntlr.selection.copyWith(extentOffset: offset);
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
    _showOrUpdateMagnifier(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _hideMagnifier();
  }

  void _selectWordAtOffset(int offset) {
    final text = _cntlr.text;
    if (text.isEmpty) return;
    int start = offset.clamp(0, text.length - 1);
    while (start > 0 && _isWordChar(text[start - 1])) {
      start--;
    }
    int end = offset.clamp(0, text.length);
    while (end < text.length && _isWordChar(text[end])) {
      end++;
    }
    if (start == end) return;
    _beginBatchEdit();
    _cntlr.selection = TextSelection(
      baseOffset: start,
      extentOffset: end,
    );
    _endBatchEdit();
  }

  bool _isWordChar(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        code == 95;
  }

  // ===================== Context Menu =====================

  void _showContextMenu() {
    _dismissContextMenu();

    final hasSelection =
        _cntlr.selection.isValid && !_cntlr.selection.isCollapsed;

    if (_contextMenuEntry != null) return;

    _contextMenuEntry = OverlayEntry(
      builder: (ctx) {
        if (_contextMenuEntry == null) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismissContextMenu,
          child: _EditorContextMenu(
            editorKey: GlobalKey(),
            hasSelection: hasSelection,
            onCut: hasSelection
                ? () {
                    _dismissContextMenu();
                    cutSelection(SelectionChangedCause.toolbar);
                  }
                : null,
            onCopy: hasSelection
                ? () {
                    _dismissContextMenu();
                    copySelection(SelectionChangedCause.toolbar);
                  }
                : null,
            onPaste: () {
              _dismissContextMenu();
              pasteText(SelectionChangedCause.toolbar);
            },
            onSelectAll: () {
              _dismissContextMenu();
              selectAll(SelectionChangedCause.toolbar);
            },
          ),
        );
      },
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_contextMenuEntry!);
  }

  void _dismissContextMenu() {
    _contextMenuEntry?.remove();
    _contextMenuEntry = null;
  }

  // ===================== Magnifier =====================

  void _showOrUpdateMagnifier(Offset localPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalPosition = renderBox.localToGlobal(localPosition);
    _magnifierController.show(
      context: context,
      builder: (ctx) {
        return Stack(
          children: [
            Positioned(
              left: globalPosition.dx - 50,
              top: globalPosition.dy - 130,
              child: RawMagnifier(
                size: const Size(100, 100),
                magnificationScale: 1.5,
                focalPointOffset: const Offset(50, 75),
              ),
            ),
          ],
        );
      },
    );
  }

  void _hideMagnifier() {
    _magnifierController.hide();
  }

  // ===================== 坐标转换 =====================

  (int line, int column) _offsetToPosition(Offset offset) {
    double dx = offset.dx - _padding.left;
    if (widget.showLineNumbers) dx -= widget.lineNumberWidth;
    double dy = offset.dy - _padding.top + _scrollOffset;

    int line =
        (dy / _lineHeightPx).floor().clamp(0, _lineStarts.length - 1);

    final lineText = _lineText(line);
    final painter = _getOrCreateLinePainter(line, lineText);
    if (painter == null) return (line, 0);

    final pos = painter.getPositionForOffset(Offset(dx, _lineHeightPx / 2));
    return (line, pos.offset.clamp(0, lineText.length));
  }

  TextPainter? _getOrCreateLinePainter(int lineIndex, String lineText) {
    if (_lastTextGeneration != _textGeneration ||
        _lastTextWidth != _textWidth) {
      _clearPainterCache();
      _lastTextGeneration = _textGeneration;
      _lastTextWidth = _textWidth;
    }
    if (_linePainterCache.containsKey(lineIndex)) {
      return _linePainterCache[lineIndex]!;
    }
    final painter = TextPainter(
      text: TextSpan(text: lineText, style: _textStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: _textWidth);
    _linePainterCache[lineIndex] = painter;
    return painter;
  }

  // ===================== Build =====================

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);

    final shortcutsWidget = DefaultTextEditingShortcuts(
      child: Actions(
        actions: <Type, Action<Intent>>{
          DoNothingAndStopPropagationTextIntent:
              DoNothingAction(consumesKey: false),
          ReplaceTextIntent:
              CallbackAction<ReplaceTextIntent>(onInvoke: _handleReplaceText),
          UpdateSelectionIntent:
              CallbackAction<UpdateSelectionIntent>(
                  onInvoke: _handleUpdateSelection),
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (intent) {
              primaryFocus?.focusInDirection(intent.direction);
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _focusNode.unfocus();
              return null;
            },
          ),
          UndoTextIntent:
              CallbackAction<UndoTextIntent>(onInvoke: _handleUndo),
          RedoTextIntent:
              CallbackAction<RedoTextIntent>(onInvoke: _handleRedo),
          CopySelectionTextIntent:
              CallbackAction<CopySelectionTextIntent>(
                  onInvoke: _handleCopySelection),
          PasteTextIntent:
              CallbackAction<PasteTextIntent>(onInvoke: _handlePaste),
          SelectAllTextIntent:
              CallbackAction<SelectAllTextIntent>(
                  onInvoke: _handleSelectAll),
          DeleteCharacterIntent:
              CallbackAction<DeleteCharacterIntent>(onInvoke: _handleDelete),
          ExtendSelectionByCharacterIntent:
              CallbackAction<ExtendSelectionByCharacterIntent>(
                  onInvoke: _handleExtendByCharacter),
          ExtendSelectionVerticallyToAdjacentLineIntent:
              CallbackAction<ExtendSelectionVerticallyToAdjacentLineIntent>(
                  onInvoke: _handleExtendVertically),
          ExtendSelectionToNextWordBoundaryIntent:
              CallbackAction<ExtendSelectionToNextWordBoundaryIntent>(
                  onInvoke: _handleExtendToWordBoundary),
          ExtendSelectionToLineBreakIntent:
              CallbackAction<ExtendSelectionToLineBreakIntent>(
                  onInvoke: _handleExtendToLineBreak),
          ExtendSelectionToDocumentBoundaryIntent:
              CallbackAction<ExtendSelectionToDocumentBoundaryIntent>(
                  onInvoke: _handleExtendToDocumentBoundary),
          ExtendSelectionToNextParagraphBoundaryIntent:
              CallbackAction<ExtendSelectionToNextParagraphBoundaryIntent>(
                  onInvoke: _handleExtendToDocumentBoundary),
          ExtendSelectionVerticallyToAdjacentPageIntent:
              CallbackAction<ExtendSelectionVerticallyToAdjacentPageIntent>(
                  onInvoke: _handleExtendVerticallyByPage),
          DeleteToNextWordBoundaryIntent:
              CallbackAction<DeleteToNextWordBoundaryIntent>(
                  onInvoke: _handleDeleteToWordBoundary),
          DeleteToLineBreakIntent:
              CallbackAction<DeleteToLineBreakIntent>(
                  onInvoke: _handleDeleteToLineBreak),
          ExpandSelectionToLineBreakIntent:
              CallbackAction<ExpandSelectionToLineBreakIntent>(
                  onInvoke: _handleExpandToLineBreak),
          ExpandSelectionToDocumentBoundaryIntent:
              CallbackAction<ExpandSelectionToDocumentBoundaryIntent>(
                  onInvoke: _handleExpandToDocumentBoundary),
        },
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKeyEvent,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: _onTapDown,
            onDoubleTapDown: _onDoubleTapDown,
            onSecondaryTapDown: _onSecondaryTapDown,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _viewportHeight = constraints.maxHeight;
                      _viewportWidth = constraints.maxWidth;
                      return SingleChildScrollView(
                        controller: _scrollController,
                        child: SizedBox(
                          height: math.max(
                            _contentHeight + _padding.vertical,
                            _viewportHeight,
                          ),
                          width: double.infinity,
                          child: CustomPaint(
                            size: Size(
                              _viewportWidth,
                              math.max(
                                _contentHeight + _padding.vertical,
                                _viewportHeight,
                              ),
                            ),
                            painter: _EditorPainter(
                              controller: _cntlr,
                              lineStarts: _lineStarts,
                              scrollController: _scrollController,
                              cursorBlinkNotifier: _cursorBlinkNotifier,
                              hasFocus: _hasFocus,
                              textStyle: _textStyle,
                              lineHeight: _lineHeightPx,
                              padding: _padding,
                              viewportHeight: _viewportHeight,
                              textColor: _textColor,
                              showLineNumbers: widget.showLineNumbers,
                              lineNumberWidth: widget.lineNumberWidth,
                              lineNumberStyle: _lineNumberStyle,
                              lineNumberCurrentColor:
                                  _lineNumberCurrentColor,
                              lineNumberColor: _lineNumberColor,
                              textWidth: _textWidth,
                              getOrCreateLinePainter:
                                  _getOrCreateLinePainter,
                              repaint: _repaintNotifier,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.showStatusBar) _buildStatusBar(theme),
              ],
            ),
          ),
        ),
      ),
    );

    if (_contextMenuEntry == null) {
      return shortcutsWidget;
    }

    return shortcutsWidget;
  }

  // ===================== Delete Handlers =====================

  void _handleDelete(DeleteCharacterIntent intent) {
    final text = _cntlr.text;
    final selection = _cntlr.selection;
    final composing = _cntlr.value.composing;

    if (composing.isValid && !composing.isCollapsed && !intent.forward) {
      return;
    }

    if (!intent.forward &&
        composing.isValid &&
        !composing.isCollapsed) {
      return;
    }

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      if (intent.forward) {
        if (offset >= text.length) return;
        final newText =
            '${text.substring(0, offset)}${text.substring(offset + 1)}';
        userUpdateTextEditingValue(
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: offset),
          ),
          SelectionChangedCause.keyboard,
        );
      } else {
        if (offset <= 0) return;
        final newText =
            '${text.substring(0, offset - 1)}${text.substring(offset)}';
        userUpdateTextEditingValue(
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: offset - 1),
          ),
          SelectionChangedCause.keyboard,
        );
      }
    } else {
      final start = selection.start.clamp(0, text.length);
      final end = selection.end.clamp(0, text.length);
      final newText =
          '${text.substring(0, start)}${text.substring(end)}';
      userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start),
        ),
        SelectionChangedCause.keyboard,
      );
    }
    HapticFeedback.lightImpact();
    _pushUndo();
  }

  void _handleDeleteToWordBoundary(DeleteToNextWordBoundaryIntent intent) {
    final text = _cntlr.text;
    final selection = _cntlr.selection;

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      int targetOffset;

      if (intent.forward) {
        targetOffset = _findWordRight(offset);
      } else {
        targetOffset = _findWordLeft(offset);
      }

      final start = math.min(offset, targetOffset);
      final end = math.max(offset, targetOffset);
      if (start == end) return;

      final newText =
          '${text.substring(0, start)}${text.substring(end)}';
      userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start),
        ),
        SelectionChangedCause.keyboard,
      );
    } else {
      _handleDelete(DeleteCharacterIntent(forward: intent.forward));
    }
    HapticFeedback.lightImpact();
    _pushUndo();
  }

  void _handleDeleteToLineBreak(DeleteToLineBreakIntent intent) {
    final text = _cntlr.text;
    final selection = _cntlr.selection;

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      int targetOffset;

      if (intent.forward) {
        targetOffset = _lineStarts[_cursorLine] + _lineLength(_cursorLine);
      } else {
        targetOffset = _lineStarts[_cursorLine];
      }

      final start = math.min(offset, targetOffset);
      final end = math.max(offset, targetOffset);
      if (start == end) return;

      final newText =
          '${text.substring(0, start)}${text.substring(end)}';
      userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start),
        ),
        SelectionChangedCause.keyboard,
      );
    } else {
      _handleDelete(DeleteCharacterIntent(forward: intent.forward));
    }
    HapticFeedback.lightImpact();
    _pushUndo();
  }

  int _findWordLeft(int offset) {
    final text = _cntlr.text;
    if (offset <= 0) return 0;
    int pos = offset;
    while (pos > 0 && text[pos - 1] == ' ') {
      pos--;
    }
    while (pos > 0 && text[pos - 1] != ' ') {
      pos--;
    }
    return pos;
  }

  int _findWordRight(int offset) {
    final text = _cntlr.text;
    if (offset >= text.length) return text.length;
    int pos = offset;
    while (pos < text.length && text[pos] != ' ') {
      pos++;
    }
    while (pos < text.length && text[pos] == ' ') {
      pos++;
    }
    return pos;
  }

  // ===================== Extend Selection Handlers =====================

  void _handleExtendByCharacter(ExtendSelectionByCharacterIntent intent) {
    final selection = _cntlr.selection;
    final text = _cntlr.text;

    if (!selection.isValid) return;

    if (!selection.isCollapsed && intent.collapseSelection) {
      final newOffset = intent.forward ? selection.end : selection.start;
      _beginBatchEdit();
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      _endBatchEdit();
      _restartCursorBlink();
      _ensureCursorVisible();
      return;
    }

    final extent = intent.collapseSelection
        ? selection.baseOffset
        : (intent.collapseSelection ? selection.baseOffset : selection.extentOffset);

    int newOffset;
    if (intent.forward) {
      newOffset = math.min(extent + 1, text.length);
    } else {
      newOffset = math.max(extent - 1, 0);
    }

    if (intent.collapseSelection) {
      _beginBatchEdit();
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      _endBatchEdit();
    } else {
      _beginBatchEdit();
      _cntlr.selection =
          selection.extendTo(TextPosition(offset: newOffset));
      _endBatchEdit();
    }
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExtendVertically(
    ExtendSelectionVerticallyToAdjacentLineIntent intent,
  ) {
    final selection = _cntlr.selection;
    final text = _cntlr.text;

    if (!selection.isValid) return;

    final currentOffset =
        intent.collapseSelection || selection.isCollapsed
            ? selection.baseOffset
            : selection.extentOffset;

    final currentLine = _lineIndexAt(currentOffset);
    final currentCol = (currentOffset - _lineStarts[currentLine])
        .clamp(0, _lineLength(currentLine));

    int newOffset;

    if (intent.forward) {
      if (currentLine >= _lineStarts.length - 1) {
        newOffset = text.length;
      } else {
        final newCol =
            math.min<int>(currentCol, _lineLength(currentLine + 1));
        newOffset = _lineStarts[currentLine + 1] + newCol;
      }
    } else {
      if (currentLine <= 0) {
        newOffset = 0;
      } else {
        final newCol =
            math.min<int>(currentCol, _lineLength(currentLine - 1));
        newOffset = _lineStarts[currentLine - 1] + newCol;
      }
    }

    newOffset = newOffset.clamp(0, text.length);

    _beginBatchEdit();
    if (intent.collapseSelection) {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    } else {
      _cntlr.selection = selection.extendTo(
        TextPosition(offset: newOffset),
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExtendVerticallyByPage(
    ExtendSelectionVerticallyToAdjacentPageIntent intent,
  ) {
    final selection = _cntlr.selection;
    final text = _cntlr.text;

    if (!selection.isValid) return;

    final currentOffset =
        intent.collapseSelection || selection.isCollapsed
            ? selection.baseOffset
            : selection.extentOffset;

    final currentLine = _lineIndexAt(currentOffset);
    final currentCol = (currentOffset - _lineStarts[currentLine])
        .clamp(0, _lineLength(currentLine));

    final pageSize = math.max(1, (_viewportHeight / _lineHeightPx).floor() - 2);

    int newOffset;

    if (intent.forward) {
      final newLine =
          math.min(currentLine + pageSize, _lineStarts.length - 1);
      final newCol =
          math.min<int>(currentCol, _lineLength(newLine));
      newOffset = _lineStarts[newLine] + newCol;
    } else {
      final newLine = math.max(currentLine - pageSize, 0);
      final newCol =
          math.min<int>(currentCol, _lineLength(newLine));
      newOffset = _lineStarts[newLine] + newCol;
    }

    newOffset = newOffset.clamp(0, text.length);

    _beginBatchEdit();
    if (intent.collapseSelection) {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    } else {
      _cntlr.selection = selection.extendTo(
        TextPosition(offset: newOffset),
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExtendToWordBoundary(
    ExtendSelectionToNextWordBoundaryIntent intent,
  ) {
    final selection = _cntlr.selection;
    if (!selection.isValid) return;

    final currentOffset =
        selection.isCollapsed || intent.collapseSelection
            ? selection.baseOffset
            : selection.extentOffset;

    final newOffset = intent.forward
        ? _findWordRight(currentOffset)
        : _findWordLeft(currentOffset);

    _beginBatchEdit();
    if (intent.collapseSelection) {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    } else {
      _cntlr.selection = selection.extendTo(
        TextPosition(offset: newOffset),
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExtendToLineBreak(
    ExtendSelectionToLineBreakIntent intent,
  ) {
    final selection = _cntlr.selection;
    if (!selection.isValid) return;

    final currentOffset =
        selection.isCollapsed || intent.collapseSelection
            ? selection.baseOffset
            : selection.extentOffset;
    final cl = _lineIndexAt(currentOffset);

    final newOffset = intent.forward
        ? _lineStarts[cl] + _lineLength(cl)
        : _lineStarts[cl];

    _beginBatchEdit();
    if (intent.collapseSelection) {
      _cntlr.selection =
          TextSelection.collapsed(offset: newOffset);
    } else {
      _cntlr.selection = selection.extendTo(
        TextPosition(offset: newOffset),
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExtendToDocumentBoundary(
    DirectionalCaretMovementIntent intent,
  ) {
    final selection = _cntlr.selection;
    final text = _cntlr.text;
    if (!selection.isValid) return;

    final newOffset = intent.forward ? text.length : 0;

    _beginBatchEdit();
    if (intent.collapseSelection) {
      _cntlr.selection = TextSelection.collapsed(offset: newOffset);
    } else {
      _cntlr.selection = selection.extendTo(
        TextPosition(offset: newOffset),
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExpandToLineBreak(
    ExpandSelectionToLineBreakIntent intent,
  ) {
    final selection = _cntlr.selection;
    if (!selection.isValid) return;

    final cl = _cursorLine;
    final lineStart = _lineStarts[cl];
    final lineEnd = lineStart + _lineLength(cl);

    _beginBatchEdit();
    if (intent.forward) {
      _cntlr.selection = selection.expandTo(
        TextPosition(offset: lineEnd),
        selection.isCollapsed,
      );
    } else {
      _cntlr.selection = selection.expandTo(
        TextPosition(offset: lineStart),
        selection.isCollapsed,
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _handleExpandToDocumentBoundary(
    ExpandSelectionToDocumentBoundaryIntent intent,
  ) {
    final selection = _cntlr.selection;
    final text = _cntlr.text;
    if (!selection.isValid) return;

    _beginBatchEdit();
    if (intent.forward) {
      _cntlr.selection = selection.expandTo(
        TextPosition(offset: text.length),
        selection.isCollapsed,
      );
    } else {
      _cntlr.selection = selection.expandTo(
        const TextPosition(offset: 0),
        selection.isCollapsed,
      );
    }
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  // ===================== Status Bar =====================

  Widget _buildStatusBar(UThemeData theme) {
    final sel = _cntlr.selection;
    final selLen = sel.isCollapsed ? 0 : sel.end - sel.start;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.secondary.withValues(alpha: 0.2)),
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: theme.secondary,
        ),
        child: Row(
          children: [
            Text('Line ${_cursorLine + 1}, Col ${_cursorColumn + 1}'),
            if (selLen > 0) Text('  Selected $selLen'),
            const Spacer(),
            Text('${_lineStarts.length} lines'),
          ],
        ),
      ),
    );
  }

  }

// ===================== Editor Context Menu Overlay =====================

class _EditorContextMenu extends StatelessWidget {
  const _EditorContextMenu({
    required this.editorKey,
    required this.hasSelection,
    this.onCut,
    this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
  });

  final GlobalKey editorKey;
  final bool hasSelection;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback onPaste;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 8,
          bottom: 8,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection) ...[
                    if (onCut != null)
                      _menuItem(context, 'Cut', Icons.content_cut,
                          onCut!),
                    if (onCopy != null)
                      _menuItem(context, 'Copy', Icons.content_copy,
                          onCopy!),
                  ],
                  _menuItem(
                      context, 'Paste', Icons.content_paste, onPaste),
                  const Divider(height: 1),
                  _menuItem(context, 'Select All', Icons.select_all,
                      onSelectAll),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ===================== Undo Stack =====================

class _UndoStack<T> {
  final List<T> _list = <T>[];
  int _index = -1;

  T? get currentValue =>
      _list.isEmpty ? null : (_index >= 0 && _index < _list.length ? _list[_index] : null);

  void push(T value) {
    if (_list.isEmpty) {
      _list.add(value);
      _index = 0;
      return;
    }

    assert(_index < _list.length && _index >= 0);

    if (value == currentValue) {
      return;
    }

    if (_index != _list.length - 1) {
      _list.removeRange(_index + 1, _list.length);
    }
    _list.add(value);
    _index = _list.length - 1;
  }

  T? undo() {
    if (_list.isEmpty) return null;
    assert(_index < _list.length && _index >= 0);
    if (_index != 0) {
      _index = _index - 1;
    }
    return currentValue;
  }

  T? redo() {
    if (_list.isEmpty) return null;
    assert(_index < _list.length && _index >= 0);
    if (_index < _list.length - 1) {
      _index = _index + 1;
    }
    return currentValue;
  }

  void clear() {
    _list.clear();
    _index = -1;
  }
}

// ===================== Editor Painter =====================

class _EditorPainter extends CustomPainter {
  final TextEditingController controller;
  final List<int> lineStarts;
  final ScrollController scrollController;
  final ValueNotifier<bool> cursorBlinkNotifier;
  final bool hasFocus;
  final TextStyle textStyle;
  final double lineHeight;
  final EdgeInsets padding;
  final double viewportHeight;
  final Color textColor;
  final bool showLineNumbers;
  final double lineNumberWidth;
  final TextStyle lineNumberStyle;
  final Color lineNumberCurrentColor;
  final Color lineNumberColor;
  final double textWidth;
  final TextPainter? Function(int lineIndex, String lineText)
      getOrCreateLinePainter;
  final Listenable repaint;

  final Map<int, TextPainter> _lineNumberCache = {};
  int _lastCursorLine = -1;
  int _lastTotalLines = -1;

  _EditorPainter({
    required this.controller,
    required this.lineStarts,
    required this.scrollController,
    required this.cursorBlinkNotifier,
    required this.hasFocus,
    required this.textStyle,
    required this.lineHeight,
    required this.padding,
    required this.viewportHeight,
    required this.textColor,
    required this.showLineNumbers,
    required this.lineNumberWidth,
    required this.lineNumberStyle,
    required this.lineNumberCurrentColor,
    required this.lineNumberColor,
    required this.textWidth,
    required this.getOrCreateLinePainter,
    required this.repaint,
  }) : super(repaint: repaint);

  bool get _cursorVisible => hasFocus && cursorBlinkNotifier.value;

  double get _scrollOffset =>
      scrollController.hasClients ? scrollController.offset : 0.0;

  int get _cursorLine {
    final offset = controller.selection.baseOffset;
    if (offset < 0 || lineStarts.isEmpty) return 0;
    int lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  int get _cursorColumn {
    final offset = controller.selection.baseOffset;
    if (offset <= 0 || lineStarts.isEmpty) return 0;
    return offset - lineStarts[_cursorLine];
  }

  String _lineText(int i) {
    final text = controller.text;
    final start = lineStarts[i];
    final end =
        i < lineStarts.length - 1 ? lineStarts[i + 1] - 1 : text.length;
    if (start > end) return '';
    return text.substring(start, end);
  }

  int _lineIndexAt(int offset) {
    if (offset < 0 || lineStarts.isEmpty) return 0;
    int lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final so = _scrollOffset;
    final startLine = math.max(0, (so / lineHeight).floor() - 2);
    final endLine = math.min(
      lineStarts.length,
      ((so + viewportHeight) / lineHeight).ceil() + 2,
    );

    final textStartX =
        padding.left + (showLineNumbers ? lineNumberWidth : 0);

    if (showLineNumbers) {
      _paintLineNumbers(canvas, startLine, endLine);
    }

    _paintSelection(canvas, textStartX);

    for (int i = startLine; i < endLine; i++) {
      final y = padding.top + i * lineHeight;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(textStartX, y, textWidth, lineHeight + 1),
      );
      final lineText = _lineText(i);
      final painter = getOrCreateLinePainter(i, lineText);
      if (painter != null) {
        painter.paint(canvas, Offset(textStartX, y));
      }
      canvas.restore();
    }

    _paintComposingHighlight(canvas, textStartX);

    if (_cursorVisible) {
      _paintCursor(canvas, textStartX);
    }
  }

  void _paintSelection(Canvas canvas, double textStartX) {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = controller.text;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (start == end) return;

    final highlightPaint = Paint()..color = const Color(0x660000FF);

    final startLine = _lineIndexAt(start);
    final endLine = _lineIndexAt(end);

    for (int lineIdx = startLine; lineIdx <= endLine; lineIdx++) {
      final lineText = _lineText(lineIdx);
      final painter = getOrCreateLinePainter(lineIdx, lineText);
      if (painter == null) continue;

      int selStart = 0;
      int selEnd = lineText.length;

      if (lineIdx == startLine) {
        selStart = start - lineStarts[lineIdx];
      }
      if (lineIdx == endLine) {
        selEnd = end - lineStarts[lineIdx];
      }
      selStart = selStart.clamp(0, lineText.length);
      selEnd = selEnd.clamp(0, lineText.length);
      if (selStart >= selEnd) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: selStart, extentOffset: selEnd),
      );
      for (final box in boxes) {
        canvas.drawRect(
          Rect.fromLTRB(
            textStartX + box.left,
            padding.top + lineIdx * lineHeight + box.top,
            textStartX + box.right,
            padding.top + lineIdx * lineHeight + box.bottom,
          ),
          highlightPaint,
        );
      }
    }
  }

  void _paintComposingHighlight(Canvas canvas, double textStartX) {
    final composing = controller.value.composing;
    if (!composing.isValid || composing.isCollapsed) return;

    final text = controller.text;
    final start = composing.start.clamp(0, text.length);
    final end = composing.end.clamp(0, text.length);
    if (start == end) return;

    final paint = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final startLine = _lineIndexAt(start);
    final endLine = _lineIndexAt(end);

    for (int lineIdx = startLine; lineIdx <= endLine; lineIdx++) {
      final lineText = _lineText(lineIdx);
      final painter = getOrCreateLinePainter(lineIdx, lineText);
      if (painter == null) continue;

      int compStart = 0;
      int compEnd = lineText.length;
      if (lineIdx == startLine) compStart = start - lineStarts[lineIdx];
      if (lineIdx == endLine) compEnd = end - lineStarts[lineIdx];
      compStart = compStart.clamp(0, lineText.length);
      compEnd = compEnd.clamp(0, lineText.length);
      if (compStart >= compEnd) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: compStart, extentOffset: compEnd),
      );
      for (final box in boxes) {
        final rect = Rect.fromLTRB(
          textStartX + box.left,
          padding.top + lineIdx * lineHeight + box.bottom - 2,
          textStartX + box.right,
          padding.top + lineIdx * lineHeight + box.bottom,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _paintCursor(Canvas canvas, double textStartX) {
    final cl = _cursorLine;
    if (cl >= lineStarts.length) return;

    final lineText = _lineText(cl);
    final painter = getOrCreateLinePainter(cl, lineText);
    if (painter == null) return;

    final caretPrototype = Rect.fromLTWH(0, 0, 1.5, lineHeight);
    final caretOffset = painter.getOffsetForCaret(
      TextPosition(offset: _cursorColumn),
      caretPrototype,
    );

    final cursorX = textStartX + caretOffset.dx;
    final cursorY = padding.top + cl * lineHeight;

    final paint = Paint()
      ..color = textColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cursorX, cursorY + 1),
      Offset(cursorX, cursorY + lineHeight - 1),
      paint,
    );
  }

  void _paintLineNumbers(Canvas canvas, int startLine, int endLine) {
    final cl = _cursorLine;
    final total = lineStarts.length;
    if (cl != _lastCursorLine || total != _lastTotalLines) {
      for (final p in _lineNumberCache.values) {
        p.dispose();
      }
      _lineNumberCache.clear();
      _lastCursorLine = cl;
      _lastTotalLines = total;
    }

    for (int i = startLine; i < endLine && i < total; i++) {
      final y = padding.top + i * lineHeight;
      if (y + lineHeight < _scrollOffset - lineHeight ||
          y > _scrollOffset + viewportHeight + lineHeight) {
        continue;
      }

      final isCurrent = i == cl;
      if (isCurrent) {
        final bgPaint = Paint()
          ..color = lineNumberCurrentColor.withValues(alpha: 0.1);
        canvas.drawRect(
          Rect.fromLTWH(0, y, lineNumberWidth, lineHeight),
          bgPaint,
        );
      }

      TextPainter? numPainter = _lineNumberCache[i];
      if (numPainter == null) {
        numPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: lineNumberStyle.copyWith(
              color: isCurrent ? lineNumberCurrentColor : lineNumberColor,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
        );
        numPainter.layout(
          minWidth: lineNumberWidth - 8,
          maxWidth: lineNumberWidth - 8,
        );
        _lineNumberCache[i] = numPainter;
      }
      numPainter.paint(canvas, Offset(0, y));
    }
  }

  @override
  bool shouldRepaint(covariant _EditorPainter old) => true;
}