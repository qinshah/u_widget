import 'dart:async';
import 'dart:math' as math;

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

  EdgeInsets get _padding =>
      widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  double get _textWidth {
    double w = _viewportWidth - _padding.horizontal;
    if (widget.showLineNumbers) w -= widget.lineNumberWidth;
    return math.max(w, 1);
  }

  double get _contentHeight => _lineStarts.length * _lineHeightPx;

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  int get _cursorLine {
    final offset = _cntlr.selection.baseOffset;
    if (offset < 0) return 0;
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

  int get _cursorColumn {
    final offset = _cntlr.selection.baseOffset;
    if (offset <= 0) return 0;
    return offset - _lineStarts[_cursorLine];
  }

  String _getLineText(int i) {
    final text = _cntlr.text;
    final start = _lineStarts[i];
    final end = i < _lineStarts.length - 1 ? _lineStarts[i + 1] - 1 : text.length;
    if (start > end) return '';
    return text.substring(start, end);
  }

  int _getLineLength(int i) {
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

  TextEditingValue get _value => _cntlr.value;

  @override
  void initState() {
    super.initState();
    _cntlr = widget.cntlr ?? TextEditingController(text: widget.initialText);
    _focusNode = widget.focusNode ?? FocusNode();
    _repaintNotifier = Listenable.merge([_scrollController, _cursorBlinkNotifier]);
    _cntlr.addListener(_didChangeTextEditingValue);
    _focusNode.addListener(_handleFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialText.isNotEmpty) {
      _lineStarts = _buildLineStarts(widget.initialText);
      _lastRebuiltText = widget.initialText;
    }
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
    _cntlr.removeListener(_didChangeTextEditingValue);
    _focusNode.removeListener(_handleFocusChanged);
    _closeInputConnectionIfNeeded();
    _stopCursorTimer();
    _cursorBlinkNotifier.dispose();
    _scrollController.dispose();
    _clearPainterCache();
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

  void _beginBatchEdit() {
    _batchEditDepth += 1;
  }

  void _endBatchEdit() {
    _batchEditDepth -= 1;
    assert(_batchEditDepth >= 0, 'Unbalanced call to _endBatchEdit');
    _updateRemoteEditingValueIfNeeded();
  }

  void _didChangeTextEditingValue() {
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
    _startOrStopCursorTimerIfNeeded();
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
    final localValue = _value;
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

  void _updateRemoteEditingValueIfNeeded() {
    if (_batchEditDepth > 0 || !_hasInputConnection) return;
    final localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue) return;
    _textInputConnection?.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (!_hasFocus) {
      _cursorBlinkNotifier.value = false;
      _stopCursorTimer();
      return;
    }
    _startCursorBlink();
  }

  void _startCursorBlink() {
    _cursorBlinkNotifier.value = true;
    _stopCursorTimer();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) {
        if (!mounted) return;
        _cursorBlinkNotifier.value = !_cursorBlinkNotifier.value;
      },
    );
  }

  void _stopCursorTimer() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
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
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause? cause,
  ) {
    if (value == _value) return;
    _beginBatchEdit();
    _cntlr.value = value;
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    if (value == _value) return;
    _beginBatchEdit();
    _cntlr.value = value;
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
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
  void showToolbar() {}

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
    final text = _cntlr.text.substring(selection.start, selection.end);
    Clipboard.setData(ClipboardData(text: text));
    _handleDelete(true);
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _insertText(data!.text!);
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    if (_cntlr.text.isEmpty) return;
    _cntlr.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _cntlr.text.length,
    );
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    final selection = _cntlr.selection;
    if (selection.isCollapsed) return;
    final text = _cntlr.text.substring(selection.start, selection.end);
    Clipboard.setData(ClipboardData(text: text));
  }

  @override
  void hideToolbar([bool hideHandles = true]) {}

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

  // ===================== Actions 和快捷键处理 =====================

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
      intent.currentTextEditingValue.copyWith(selection: intent.newSelection),
      intent.cause,
    );
  }

  void _handleDeleteIntent(DeleteCharacterIntent intent) {
    final text = _cntlr.text;
    final selection = _cntlr.selection;

    int start;
    int end;

    if (selection.isCollapsed) {
      start = selection.baseOffset;
      end = selection.baseOffset;
    } else {
      start = selection.start;
      end = selection.end;
    }

    if (intent.forward) {
      if (end >= text.length) return;
      end += 1;
    } else {
      if (start <= 0) return;
      start -= 1;
    }

    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);

    final newText = '${text.substring(0, start)}${text.substring(end)}';
    final newOffset = start;
    userUpdateTextEditingValue(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleDirectionalFocus(DirectionalFocusIntent intent) {
    primaryFocus?.focusInDirection(intent.direction);
  }

  void _handleExtendSelectionByCharacter(ExtendSelectionByCharacterIntent intent) {
    final text = _cntlr.text;
    final selection = _cntlr.selection;
    if (!selection.isValid) return;

    int newOffset;
    if (intent.forward) {
      if (selection.baseOffset >= text.length) return;
      newOffset = selection.baseOffset + 1;
    } else {
      if (selection.baseOffset <= 0) return;
      newOffset = selection.baseOffset - 1;
    }

    if (intent.collapseSelection) {
      userUpdateTextEditingValue(
        _cntlr.value.copyWith(
          selection: TextSelection.collapsed(offset: newOffset),
        ),
        SelectionChangedCause.keyboard,
      );
    } else {
      userUpdateTextEditingValue(
        _cntlr.value.copyWith(
          selection: TextSelection(
            baseOffset: selection.baseOffset,
            extentOffset: newOffset,
          ),
        ),
        SelectionChangedCause.keyboard,
      );
    }
  }

  void _handleExtendSelectionVertically(
    ExtendSelectionVerticallyToAdjacentLineIntent intent,
  ) {
    final text = _cntlr.text;
    final cl = _cursorLine;
    final cc = _cursorColumn;
    int newOffset;

    if (intent.forward) {
      if (cl >= _lineStarts.length - 1) {
        newOffset = text.length;
      } else {
        final newCol = cc.clamp(0, _getLineLength(cl + 1));
        newOffset = _lineStarts[cl + 1] + newCol;
      }
    } else {
      if (cl <= 0) {
        newOffset = 0;
      } else {
        final newCol = cc.clamp(0, _getLineLength(cl - 1));
        newOffset = _lineStarts[cl - 1] + newCol;
      }
    }

    newOffset = newOffset.clamp(0, text.length);
    final currentOffset = _cntlr.selection.baseOffset;
    if (newOffset == currentOffset) return;

    if (intent.collapseSelection) {
      userUpdateTextEditingValue(
        _cntlr.value.copyWith(
          selection: TextSelection.collapsed(offset: newOffset),
        ),
        SelectionChangedCause.keyboard,
      );
    } else {
      userUpdateTextEditingValue(
        _cntlr.value.copyWith(
          selection: TextSelection(
            baseOffset: currentOffset,
            extentOffset: newOffset,
          ),
        ),
        SelectionChangedCause.keyboard,
      );
    }
    _ensureCursorVisible();
  }

  void _handleCopyIntent(CopySelectionTextIntent intent) async {
    final selection = _cntlr.selection;
    if (selection.isCollapsed) return;
    final text = _cntlr.text.substring(selection.start, selection.end);
    await Clipboard.setData(ClipboardData(text: text));
  }

  void _handlePasteIntent(PasteTextIntent intent) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final text = data!.text!;
    final sel = _cntlr.selection;
    final fullText = _cntlr.text;
    final newText =
        '${fullText.substring(0, sel.start)}$text${fullText.substring(sel.end)}';
    final newValue = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + text.length),
    );
    userUpdateTextEditingValue(newValue, intent.cause);
  }

  void _handleSelectAllIntent(SelectAllTextIntent intent) {
    if (_cntlr.text.isEmpty) return;
    userUpdateTextEditingValue(
      _cntlr.value.copyWith(
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: _cntlr.text.length,
        ),
      ),
      intent.cause,
    );
  }

  // ===================== 键盘事件处理 =====================

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final logical = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    final oldOffset = _cntlr.selection.baseOffset;
    final text = _cntlr.text;

    if (logical == LogicalKeyboardKey.arrowLeft) {
      int newOffset;
      if (isCtrl) {
        newOffset = _findWordLeft(oldOffset);
      } else {
        newOffset = math.max(0, oldOffset - 1);
      }
      if (isShift) {
        _cntlr.selection = _cntlr.selection.extendTo(
          TextPosition(offset: newOffset),
        );
      } else {
        _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      }
      _ensureCursorVisible();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowRight) {
      int newOffset;
      if (isCtrl) {
        newOffset = _findWordRight(oldOffset);
      } else {
        newOffset = math.min(text.length, oldOffset + 1);
      }
      if (isShift) {
        _cntlr.selection = _cntlr.selection.extendTo(
          TextPosition(offset: newOffset),
        );
      } else {
        _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      }
      _ensureCursorVisible();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowUp) {
      final line = _cursorLine;
      if (line > 0) {
        final col = _cursorColumn;
        final newOffset = _lineStarts[line - 1] +
            math.min<int>(col, _getLineLength(line - 1));
        if (isShift) {
          _cntlr.selection = _cntlr.selection.extendTo(
            TextPosition(offset: newOffset),
          );
        } else {
          _cntlr.selection = TextSelection.collapsed(offset: newOffset);
        }
      }
      _ensureCursorVisible();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowDown) {
      final line = _cursorLine;
      if (line < _lineStarts.length - 1) {
        final col = _cursorColumn;
        final newOffset = _lineStarts[line + 1] +
            math.min<int>(col, _getLineLength(line + 1));
        if (isShift) {
          _cntlr.selection = _cntlr.selection.extendTo(
            TextPosition(offset: newOffset),
          );
        } else {
          _cntlr.selection = TextSelection.collapsed(offset: newOffset);
        }
      }
      _ensureCursorVisible();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.home) {
      _cntlr.selection = TextSelection.collapsed(
        offset: oldOffset - _cursorColumn,
      );
      _ensureCursorVisible();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.end) {
      _cntlr.selection = TextSelection.collapsed(
        offset: oldOffset - _cursorColumn + _getLineLength(_cursorLine),
      );
      _ensureCursorVisible();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.backspace ||
        logical == LogicalKeyboardKey.delete) {
      _handleDelete(logical == LogicalKeyboardKey.delete);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.enter ||
        logical == LogicalKeyboardKey.numpadEnter) {
      _insertNewline();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.tab) {
      _insertText('  ');
      return KeyEventResult.handled;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyA) {
      selectAll(SelectionChangedCause.keyboard);
      return KeyEventResult.handled;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyC) {
      _copy();
      return KeyEventResult.handled;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyV) {
      _paste();
      return KeyEventResult.handled;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyX) {
      _copy();
      _handleDelete(true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleDelete(bool forward) {
    final text = _cntlr.text;
    final selection = _cntlr.selection;

    int start;
    int end;

    if (selection.isCollapsed) {
      start = selection.baseOffset;
      end = selection.baseOffset;
    } else {
      start = selection.start;
      end = selection.end;
    }

    if (forward) {
      if (end >= text.length) return;
      end += 1;
    } else {
      if (start <= 0) return;
      start -= 1;
    }

    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);

    final newText = '${text.substring(0, start)}${text.substring(end)}';
    final newOffset = start;
    _cntlr.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _insertNewline() {
    final text = _cntlr.text;
    final offset = _cntlr.selection.baseOffset;
    _cntlr.value = TextEditingValue(
      text: '${text.substring(0, offset)}\n${text.substring(offset)}',
      selection: TextSelection.collapsed(offset: offset + 1),
    );
    _ensureCursorVisible();
  }

  void _insertText(String insertText) {
    final text = _cntlr.text;
    final offset = _cntlr.selection.baseOffset;
    _cntlr.value = TextEditingValue(
      text: '${text.substring(0, offset)}$insertText${text.substring(offset)}',
      selection: TextSelection.collapsed(offset: offset + insertText.length),
    );
    _ensureCursorVisible();
  }

  int _findWordLeft(int offset) {
    if (offset <= 0) return 0;
    final text = _cntlr.text;
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

  void _copy() async {
    final selection = _cntlr.selection;
    if (selection.isCollapsed) return;
    final text = _cntlr.text.substring(selection.start, selection.end);
    await Clipboard.setData(ClipboardData(text: text));
  }

  void _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _insertText(data!.text!);
  }

  void _restartCursorBlink() {
    if (!_hasFocus) return;
    _cursorBlinkNotifier.value = true;
    _startCursorBlink();
  }

  // ===================== 手势 =====================

  void _onTapDown(TapDownDetails details) {
    requestKeyboard();
    final pos = _offsetToPosition(details.localPosition);
    _beginBatchEdit();
    _cntlr.selection = TextSelection.collapsed(
      offset: (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length),
    );
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    final offset = (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    _selectWordAtOffset(offset);
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    final offset = (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    if (_cntlr.selection.isCollapsed) {
      _beginBatchEdit();
      _cntlr.selection = TextSelection.collapsed(offset: offset);
      _endBatchEdit();
    }
    _showContextMenu();
  }

  void _onPanStart(DragStartDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    final offset = (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
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
    final offset = (_lineStarts[pos.$1] + pos.$2).clamp(0, _cntlr.text.length);
    final base = _cntlr.selection.baseOffset;
    _beginBatchEdit();
    _cntlr.selection = TextSelection(
      baseOffset: base,
      extentOffset: offset,
    );
    _endBatchEdit();
    _restartCursorBlink();
    _ensureCursorVisible();
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
    _cntlr.selection = TextSelection(baseOffset: start, extentOffset: end);
    _endBatchEdit();
  }

  bool _isWordChar(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        code == 95;
  }

  void _showContextMenu() {
    final sel = _cntlr.selection;
    final hasSelection = sel.isValid && !sel.isCollapsed;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  entry.remove();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: 8,
              top: math.max(0, _viewportHeight - 160),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSelection) ...[
                        _buildMenuButton('剪切', Icons.content_cut, () {
                          entry.remove();
                          cutSelection(SelectionChangedCause.toolbar);
                        }),
                        _buildMenuButton('复制', Icons.content_copy, () {
                          entry.remove();
                          copySelection(SelectionChangedCause.toolbar);
                        }),
                      ],
                      _buildMenuButton('粘贴', Icons.content_paste, () {
                        entry.remove();
                        pasteText(SelectionChangedCause.toolbar);
                      }),
                      if (hasSelection) const Divider(height: 1),
                      _buildMenuButton('全选', Icons.select_all, () {
                        entry.remove();
                        selectAll(SelectionChangedCause.toolbar);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(entry);
  }

  Widget _buildMenuButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  (int line, int column) _offsetToPosition(Offset offset) {
    double dx = offset.dx - _padding.left;
    if (widget.showLineNumbers) dx -= widget.lineNumberWidth;
    double dy = offset.dy - _padding.top + _scrollOffset;

    int line = (dy / _lineHeightPx).floor().clamp(0, _lineStarts.length - 1);

    final lineText = _getLineText(line);
    final painter = _getOrCreateLinePainter(line, lineText);
    if (painter == null) return (line, 0);

    final pos = painter.getPositionForOffset(Offset(dx, _lineHeightPx / 2));
    return (line, pos.offset.clamp(0, lineText.length));
  }

  TextPainter? _getOrCreateLinePainter(int lineIndex, String lineText) {
    if (_lastTextGeneration != _textGeneration || _lastTextWidth != _textWidth) {
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
    return Actions(
      actions: <Type, Action<Intent>>{
        DoNothingAndStopPropagationTextIntent:
            DoNothingAction(consumesKey: false),
        ReplaceTextIntent: CallbackAction<ReplaceTextIntent>(
          onInvoke: _handleReplaceText,
        ),
        UpdateSelectionIntent: CallbackAction<UpdateSelectionIntent>(
          onInvoke: _handleUpdateSelection,
        ),
        DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
          onInvoke: _handleDirectionalFocus,
        ),
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            _focusNode.unfocus();
            return null;
          },
        ),
        DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(
          onInvoke: _handleDeleteIntent,
        ),
        ExtendSelectionByCharacterIntent:
            CallbackAction<ExtendSelectionByCharacterIntent>(
          onInvoke: _handleExtendSelectionByCharacter,
        ),
        ExtendSelectionVerticallyToAdjacentLineIntent:
            CallbackAction<ExtendSelectionVerticallyToAdjacentLineIntent>(
          onInvoke: _handleExtendSelectionVertically,
        ),
        SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
          onInvoke: _handleSelectAllIntent,
        ),
        CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
          onInvoke: _handleCopyIntent,
        ),
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: _handlePasteIntent,
        ),
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
                            lineNumberCurrentColor: _lineNumberCurrentColor,
                            lineNumberColor: _lineNumberColor,
                            textWidth: _textWidth,
                            getOrCreateLinePainter: _getOrCreateLinePainter,
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
    );
  }

  Widget _buildStatusBar(UThemeData theme) {
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
            Text('行 ${_cursorLine + 1}, 列 ${_cursorColumn + 1}'),
            const Spacer(),
            Text('共 ${_lineStarts.length} 行'),
          ],
        ),
      ),
    );
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

    final highlightPaint = Paint()
      ..color = const Color(0x660000FF);

    int lineIdx = 0;
    int lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= start) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final startLine = lo;

    lo = 0;
    hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= end) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final endLine = lo;

    for (lineIdx = startLine; lineIdx <= endLine; lineIdx++) {
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